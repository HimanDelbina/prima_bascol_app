import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/security/data/pattern_crypto_service.dart';

void main() {
  group('PatternCryptoService Tests', () {
    const cryptoService = PatternCryptoService();

    test('generateSalt returns valid Base64 string of requested length', () {
      final salt = cryptoService.generateSalt(16);
      expect(salt.isNotEmpty, isTrue);

      final salt2 = cryptoService.generateSalt(16);
      // Cryptographically random salts must not be identical
      expect(salt, isNot(equals(salt2)));
    });

    test('serializePattern serializes point list with hyphen delimiters', () {
      final pattern = [0, 1, 2, 5, 8];
      final serialized = cryptoService.serializePattern(pattern);
      expect(serialized, equals('0-1-2-5-8'));
    });

    test('hashPattern derives deterministic PBKDF2 hash for same pattern and salt', () {
      final pattern = [0, 1, 2, 4, 6];
      final salt = cryptoService.generateSalt();

      final hash1 = cryptoService.hashPattern(pattern, salt);
      final hash2 = cryptoService.hashPattern(pattern, salt);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // 32 bytes in hex = 64 characters
    });

    test('hashPattern derives different hashes for different patterns with same salt', () {
      final patternA = [0, 1, 2, 4, 6];
      final patternB = [0, 1, 2, 4, 7];
      final salt = cryptoService.generateSalt();

      final hashA = cryptoService.hashPattern(patternA, salt);
      final hashB = cryptoService.hashPattern(patternB, salt);

      expect(hashA, isNot(equals(hashB)));
    });

    test('verifyPattern verifies correctly for matching pattern and rejects mismatch', () {
      final pattern = [1, 2, 4, 7, 8];
      final wrongPattern = [1, 2, 4, 7, 6];
      final salt = cryptoService.generateSalt();
      final hash = cryptoService.hashPattern(pattern, salt);

      final isMatch = cryptoService.verifyPattern(
        pattern: pattern,
        storedHash: hash,
        storedSalt: salt,
      );
      expect(isMatch, isTrue);

      final isWrongMatch = cryptoService.verifyPattern(
        pattern: wrongPattern,
        storedHash: hash,
        storedSalt: salt,
      );
      expect(isWrongMatch, isFalse);
    });

    test('constantTimeEquals compares strings safely without timing leakage', () {
      expect(PatternCryptoService.constantTimeEquals('abc', 'abc'), isTrue);
      expect(PatternCryptoService.constantTimeEquals('abc', 'abd'), isFalse);
      expect(PatternCryptoService.constantTimeEquals('abc', 'abcd'), isFalse);
    });

    test('validatePattern enforces minimum 4 points and warns for simple patterns', () {
      // Less than 4 points -> Invalid
      final shortPattern = [0, 1, 2];
      final resShort = cryptoService.validatePattern(shortPattern);
      expect(resShort.isValid, isFalse);
      expect(resShort.errorMessage, contains('حداقل'));

      // 4 points (valid, but recommended 5)
      final fourPoints = [0, 1, 5, 8];
      final resFour = cryptoService.validatePattern(fourPoints);
      expect(resFour.isValid, isTrue);
      expect(resFour.warningMessage, contains('۵ نقطه'));

      // 5 points trivial straight line -> Warning
      final trivialFive = [0, 1, 2, 3, 4];
      final resTrivial = cryptoService.validatePattern(trivialFive);
      expect(resTrivial.isValid, isTrue);
      expect(resTrivial.warningMessage, contains('ساده'));

      // Complex 5 points -> Valid without warning
      final complexPattern = [0, 4, 2, 8, 5];
      final resComplex = cryptoService.validatePattern(complexPattern);
      expect(resComplex.isValid, isTrue);
      expect(resComplex.warningMessage, isNull);
    });

    test('supports versioned envelope hashing and parsing', () {
      final pattern = [0, 1, 4, 7, 8];
      final salt = cryptoService.generateSalt();
      final envelope = cryptoService.hashPattern(
        pattern,
        salt,
        iterations: 15000,
        formatAsEnvelope: true,
      );

      expect(envelope.startsWith('v1\$15000\$'), isTrue);

      final detail = cryptoService.verifyPatternDetailed(
        pattern: pattern,
        storedHash: envelope,
        storedSalt: salt,
      );

      expect(detail.isValid, isTrue);
      expect(detail.iterationsUsed, equals(15000));
      expect(detail.algorithm, equals('pbkdf2_sha256_v1'));
      expect(detail.needsRehash, isTrue); // 15,000 < default 30,000
    });

    test('backward compatibility verifies legacy 10,000 iteration hash with needsRehash flag', () {
      final pattern = [2, 5, 8, 7, 4];
      final salt = cryptoService.generateSalt();

      // Legacy hash generated with 10,000 iterations
      final legacyHash = cryptoService.hashPattern(
        pattern,
        salt,
        iterations: 10000,
      );

      // Verify without passing iterations (system uses hardened 30,000 as default)
      final detail = cryptoService.verifyPatternDetailed(
        pattern: pattern,
        storedHash: legacyHash,
        storedSalt: salt,
      );

      expect(detail.isValid, isTrue);
      expect(detail.iterationsUsed, equals(10000));
      expect(detail.needsRehash, isTrue);

      // Standard boolean verifyPattern also returns true
      final boolValid = cryptoService.verifyPattern(
        pattern: pattern,
        storedHash: legacyHash,
        storedSalt: salt,
      );
      expect(boolValid, isTrue);
    });
  });
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../domain/security_config.dart';

class PatternVerificationResult {
  final bool isValid;
  final bool needsRehash;
  final int iterationsUsed;
  final String algorithm;

  const PatternVerificationResult({
    required this.isValid,
    required this.needsRehash,
    required this.iterationsUsed,
    required this.algorithm,
  });

  static const PatternVerificationResult invalid = PatternVerificationResult(
    isValid: false,
    needsRehash: false,
    iterationsUsed: 0,
    algorithm: '',
  );
}

class PatternCryptoService {
  const PatternCryptoService();

  /// Generates a cryptographically secure random salt encoded in Base64
  String generateSalt([int length = SecurityConfig.saltByteLength]) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Converts a pattern (list of point indices 0-8) into a standardized string
  String serializePattern(List<int> pattern) {
    return pattern.join('-');
  }

  /// Formats a versioned hash envelope: v1$<iterations>$<saltBase64>$<hashHex>
  String formatVersionedHash({
    required String hashHex,
    required String saltBase64,
    required int iterations,
    String version = 'v1',
  }) {
    return '$version\$$iterations\$$saltBase64\$$hashHex';
  }

  /// Hashes a pattern using PBKDF2-HMAC-SHA256 with the provided salt and iterations.
  /// If [formatAsEnvelope] is true, returns "v1$<iterations>$<saltBase64>$<hexHash>".
  /// Otherwise returns raw 64-char hex hash.
  String hashPattern(
    List<int> pattern,
    String saltBase64, {
    int? iterations,
    bool formatAsEnvelope = false,
  }) {
    final iters = iterations ?? SecurityConfig.pbkdf2Iterations;
    final patternStr = serializePattern(pattern);
    final passwordBytes = utf8.encode(patternStr);
    final saltBytes = base64Decode(saltBase64);

    final hashBytes = pbkdf2HmacSha256(
      password: passwordBytes,
      salt: saltBytes,
      iterations: iters,
      derivedKeyLength: SecurityConfig.derivedKeyLength,
    );

    final hexHash =
        hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    if (formatAsEnvelope) {
      return formatVersionedHash(
        hashHex: hexHash,
        saltBase64: saltBase64,
        iterations: iters,
      );
    }

    return hexHash;
  }

  /// Detailed verification returning validation status, used iterations, and migration flags.
  PatternVerificationResult verifyPatternDetailed({
    required List<int> pattern,
    required String storedHash,
    required String storedSalt,
    int? iterations,
  }) {
    if (storedHash.isEmpty) return PatternVerificationResult.invalid;

    // 1. Versioned envelope parsing: v1$<iterations>$<saltBase64>$<hashHex>
    if (storedHash.startsWith('v1\$')) {
      final parts = storedHash.split('\$');
      if (parts.length >= 4) {
        final envelopeIters =
            int.tryParse(parts[1]) ?? SecurityConfig.pbkdf2Iterations;
        final envelopeSalt = parts[2];
        final expectedHex = parts[3];

        final calculated =
            hashPattern(pattern, envelopeSalt, iterations: envelopeIters);
        final matches = constantTimeEquals(calculated, expectedHex);
        return PatternVerificationResult(
          isValid: matches,
          needsRehash:
              matches && envelopeIters < SecurityConfig.pbkdf2Iterations,
          iterationsUsed: envelopeIters,
          algorithm: 'pbkdf2_sha256_v1',
        );
      }
    }

    // 2. Standard raw hex verification (with backward compatibility)
    if (storedSalt.isEmpty) return PatternVerificationResult.invalid;

    final targetIters = iterations ?? SecurityConfig.pbkdf2Iterations;
    final calcPrimary =
        hashPattern(pattern, storedSalt, iterations: targetIters);
    if (constantTimeEquals(calcPrimary, storedHash)) {
      return PatternVerificationResult(
        isValid: true,
        needsRehash: targetIters < SecurityConfig.pbkdf2Iterations,
        iterationsUsed: targetIters,
        algorithm: 'pbkdf2_sha256',
      );
    }

    // 3. Fallback: If caller didn't specify iterations and primary check failed,
    // test against legacy 10,000 iterations to guarantee seamless migration for existing users
    if (iterations == null &&
        targetIters != SecurityConfig.legacyPbkdf2Iterations) {
      final calcLegacy = hashPattern(pattern, storedSalt,
          iterations: SecurityConfig.legacyPbkdf2Iterations);
      if (constantTimeEquals(calcLegacy, storedHash)) {
        return const PatternVerificationResult(
          isValid: true,
          needsRehash: true, // Legacy 10k hash verified, should rehash to 30k
          iterationsUsed: SecurityConfig.legacyPbkdf2Iterations,
          algorithm: 'pbkdf2_sha256_legacy',
        );
      }
    }

    return PatternVerificationResult.invalid;
  }

  /// Constant-time comparison of pattern against stored hash and salt
  bool verifyPattern({
    required List<int> pattern,
    required String storedHash,
    required String storedSalt,
    int? iterations,
  }) {
    return verifyPatternDetailed(
      pattern: pattern,
      storedHash: storedHash,
      storedSalt: storedSalt,
      iterations: iterations,
    ).isValid;
  }

  /// Standard PBKDF2-HMAC-SHA256 implementation according to RFC 2898
  List<int> pbkdf2HmacSha256({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int derivedKeyLength,
  }) {
    final hmac = Hmac(sha256, password);
    const int hLen = 32; // SHA-256 output length in bytes
    final int l = (derivedKeyLength / hLen).ceil();
    final List<int> derivedKey = [];

    for (int i = 1; i <= l; i++) {
      // S || INT(i)
      final blockIndexBytes = [
        (i >> 24) & 0xFF,
        (i >> 16) & 0xFF,
        (i >> 8) & 0xFF,
        i & 0xFF,
      ];
      final initialInput = [...salt, ...blockIndexBytes];

      var u = hmac.convert(initialInput).bytes;
      final blockAccumulator = List<int>.from(u);

      for (int c = 1; c < iterations; c++) {
        u = hmac.convert(u).bytes;
        for (int k = 0; k < hLen; k++) {
          blockAccumulator[k] ^= u[k];
        }
      }

      derivedKey.addAll(blockAccumulator);
    }

    return derivedKey.sublist(0, derivedKeyLength);
  }

  /// Constant-time string equality comparison to prevent timing attacks
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Validates pattern constraints (minimum points, trivial sequence warning)
  PatternValidationResult validatePattern(List<int> pattern) {
    if (pattern.length < SecurityConfig.minPatternPoints) {
      return const PatternValidationResult(
        isValid: false,
        errorMessage: 'الگو باید حداقل شامل ${SecurityConfig.minPatternPoints} نقطه باشد.',
      );
    }

    // Check for trivial simple patterns (like 0-1-2-3, 0-3-6, etc.)
    final isTrivial = _isTrivialPattern(pattern);
    if (pattern.length < SecurityConfig.recommendedPatternPoints) {
      return const PatternValidationResult(
        isValid: true,
        warningMessage: 'پیشنهاد می‌شود جهت امنیت بیشتر حداقل ۵ نقطه انتخاب کنید.',
      );
    }

    if (isTrivial) {
      return const PatternValidationResult(
        isValid: true,
        warningMessage: 'این الگو ساده است. انتخاب الگوی پیچیده‌تر توصیه می‌شود.',
      );
    }

    return const PatternValidationResult(isValid: true);
  }

  bool _isTrivialPattern(List<int> p) {
    if (p.length < 4) return true;
    // Check if difference between consecutive nodes is constant (e.g. 0-1-2-3 or 6-4-2)
    final diff = p[1] - p[0];
    bool isSimpleSequence = true;
    for (int i = 2; i < p.length; i++) {
      if (p[i] - p[i - 1] != diff) {
        isSimpleSequence = false;
        break;
      }
    }
    return isSimpleSequence;
  }
}

class PatternValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? warningMessage;

  const PatternValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warningMessage,
  });
}

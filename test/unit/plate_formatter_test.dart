import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/utils/plate_formatter.dart';

void main() {
  group('PlateFormatter Tests', () {
    test('parses standard Iranian plate correctly', () {
      final parsed = PlateFormatter.parse('12ع34572');
      expect(parsed.part1, '12');
      expect(parsed.letter, 'ع');
      expect(parsed.part2, '345');
      expect(parsed.iranCode, '72');
    });

    test('formats parsed plate to standard string', () {
      final formatted = PlateFormatter.format('12', 'ع', '345', '72');
      expect(formatted, '12ع34572');
    });
  });
}

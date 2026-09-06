import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter & Weight Tests', () {
    test('formats weights with Persian digits and Kg suffix', () {
      expect(CurrencyFormatter.formatWeight(15400), '۱۵٬۴۰۰ کیلوگرم');
      expect(CurrencyFormatter.formatWeight(0), '۰ کیلوگرم');
      expect(CurrencyFormatter.formatWeight(1250), '۱٬۲۵۰ کیلوگرم');
    });

    test('formats numbers with Persian digits and commas', () {
      expect(CurrencyFormatter.formatNumber(1000000), '۱٬۰۰۰٬۰۰۰');
      expect(CurrencyFormatter.formatNumber(450), '۴۵۰');
    });
  });
}
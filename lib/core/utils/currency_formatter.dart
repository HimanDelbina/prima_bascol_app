import 'package:intl/intl.dart';

class WeightFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'fa_IR');
  static final NumberFormat _formatterEn = NumberFormat('#,##0', 'en_US');

  /// Formats weight value into separated digits with unit: e.g. 18780 -> "18,780 کیلوگرم" or "18,780 Kg"
  static String formatKg(dynamic weight, {bool isPersianDigits = true, String unit = "کیلوگرم"}) {
    if (weight == null) return "۰ $unit";
    final numVal = num.tryParse(weight.toString()) ?? 0;
    final formatted = isPersianDigits ? _formatter.format(numVal) : _formatterEn.format(numVal);
    return "$formatted $unit";
  }

  /// Formats weight to tonnage with decimal: e.g. 18780 -> "18.78 تن"
  static String formatTon(dynamic weight, {int decimals = 2, bool isPersianDigits = true}) {
    if (weight == null) return "۰ تن";
    final numVal = (num.tryParse(weight.toString()) ?? 0) / 1000.0;
    final formatStr = '#,##0.${'0' * decimals}';
    final formatter = isPersianDigits ? NumberFormat(formatStr, 'fa_IR') : NumberFormat(formatStr, 'en_US');
    return "${formatter.format(numVal)} تن";
  }

  /// Formats number with thousand separator
  static String formatNumber(dynamic number, {bool isPersianDigits = true}) {
    if (number == null) return "۰";
    final numVal = num.tryParse(number.toString()) ?? 0;
    return isPersianDigits ? _formatter.format(numVal) : _formatterEn.format(numVal);
  }
}


class CurrencyFormatter {
  static String formatWeight(dynamic weight) => WeightFormatter.formatKg(weight);
  static String formatNumber(dynamic number) => WeightFormatter.formatNumber(number);
  static String formatTon(dynamic weight) => WeightFormatter.formatTon(weight);
}

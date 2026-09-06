class IranianPlateModel {
  final String part1; // 2 digits (e.g. "12")
  final String letter; // Persian letter (e.g. "ع" or "الف")
  final String part2; // 3 digits (e.g. "345")
  final String iranCode; // 2 digits (e.g. "72")

  IranianPlateModel({
    required this.part1,
    required this.letter,
    required this.part2,
    required this.iranCode,
  });

  String get formattedDisplay => "$part1 $letter $part2 - ایران $iranCode";

  bool get isValid =>
      part1.length == 2 &&
      letter.isNotEmpty &&
      part2.length == 3 &&
      iranCode.length == 2;
}

class PlateFormatter {
  static const List<String> plateLetters = [
    'الف', 'ب', 'پ', 'ت', 'ث', 'ج', 'د', 'ز', 'س', 'ش', 'ص', 'ط', 'ع', 'ف', 'ق', 'ک', 'گ', 'ل', 'م', 'ن', 'و', 'ه', 'ی', 'معلولین'
  ];

  /// Parses display plate string like "12 ع 345 - 72" or "12ع345-72"
  static IranianPlateModel parse(String? plate) => parsePlate(plate) ?? IranianPlateModel(part1: '', letter: '', part2: '', iranCode: '');
  static String format(String p1, String l, String p2, String iran) => '$p1$l$p2$iran';

  static IranianPlateModel? parsePlate(String? plate) {
    if (plate == null || plate.trim().isEmpty) return null;
    final clean = plate.replaceAll('ایران', '').trim();
    // Match pattern: 2 digits, letters, 3 digits, separator, 2 digits
    final regex = RegExp(r'^(\d{2})\s*([^\d\s-]+)\s*(\d{3})\s*[-]?\s*(\d{2})$');
    final match = regex.firstMatch(clean);
    if (match != null) {
      return IranianPlateModel(
        part1: match.group(1)!,
        letter: match.group(2)!,
        part2: match.group(3)!,
        iranCode: match.group(4)!,
      );
    }
    return null;
  }
}

import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

class JalaliDateFormatter {
  /// Converts Gregorian ISO string (e.g. 2026-09-02 or 2026-09-02T14:30:00Z) to Jalali string: "1405/06/11"
  static String toJalaliDate(dynamic dateInput, {String separator = '/'}) {
    if (dateInput == null || dateInput.toString().isEmpty) return '-';
    try {
      DateTime dt;
      if (dateInput is DateTime) {
        dt = dateInput;
      } else {
        dt = DateTime.parse(dateInput.toString());
      }
      final j = Jalali.fromDateTime(dt);
      final y = j.year.toString();
      final m = j.month.toString().padLeft(2, '0');
      final d = j.day.toString().padLeft(2, '0');
      return "$y$separator$m$separator$d";
    } catch (e) {
      return dateInput.toString();
    }
  }

  /// Converts ISO string to Jalali Date and Time: "1405/06/11 - 14:30"
  static String toJalaliDateTime(dynamic dateInput) {
    if (dateInput == null || dateInput.toString().isEmpty) return '-';
    try {
      DateTime dt;
      if (dateInput is DateTime) {
        dt = dateInput;
      } else {
        dt = DateTime.parse(dateInput.toString());
      }
      // Apply Tehran offset if UTC
      final local = dt.toLocal();
      final j = Jalali.fromDateTime(local);
      final y = j.year.toString();
      final m = j.month.toString().padLeft(2, '0');
      final d = j.day.toString().padLeft(2, '0');
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return "$y/$m/$d - $hh:$mm";
    } catch (e) {
      return dateInput.toString();
    }
  }

  /// Converts Jalali string "1405/06/11" to Gregorian ISO Date string "2026-09-02" for Backend API
  static String? jalaliToGregorianIso(String? jalaliStr) {
    if (jalaliStr == null || jalaliStr.trim().isEmpty) return null;
    try {
      final parts = jalaliStr.replaceAll('-', '/').split('/');
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      final j = Jalali(y, m, d);
      final g = j.toGregorian();
      return "${g.year.toString().padLeft(4, '0')}-${g.month.toString().padLeft(2, '0')}-${g.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return null;
    }
  }

  /// Format waiting duration (minutes) to Persian text: e.g. 84 -> "۱ ساعت و ۲۴ دقیقه"
  static String formatDurationMinutes(int? minutes) {
    if (minutes == null || minutes <= 0) return "کمتر از ۱ دقیقه";
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) {
      return "$h ساعت و $m دقیقه";
    } else if (h > 0) {
      return "$h ساعت";
    } else {
      return "$m دقیقه";
    }
  }
}

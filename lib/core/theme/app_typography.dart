import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTypography {
  static TextStyle get vazirFont => GoogleFonts.vazirmatn();

  static TextTheme createTextTheme(Color primaryTextColor, Color secondaryTextColor) {
    return TextTheme(
      displayLarge: GoogleFonts.vazirmatn(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
        height: 1.4,
      ),
      displayMedium: GoogleFonts.vazirmatn(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
        height: 1.4,
      ),
      displaySmall: GoogleFonts.vazirmatn(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        height: 1.4,
      ),
      headlineMedium: GoogleFonts.vazirmatn(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        height: 1.4,
      ),
      headlineSmall: GoogleFonts.vazirmatn(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.vazirmatn(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.vazirmatn(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.vazirmatn(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.vazirmatn(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primaryTextColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.vazirmatn(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.vazirmatn(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.vazirmatn(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.vazirmatn(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        height: 1.3,
      ),
    );
  }
}

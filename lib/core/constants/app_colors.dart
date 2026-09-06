import 'package:flutter/material.dart';

class AppColors {
  // Primary Industrial Palette (Navy / Slate Blue)
  static const Color primary = Color(0xFF1E3A8A); // Slate Blue / Industrial Primary
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  
  // Secondary / Accent
  static const Color secondary = Color(0xFF0F766E); // Deep Teal
  static const Color secondaryLight = Color(0xFF14B8A6);
  static const Color accent = Color(0xFFF59E0B); // Amber Accent

  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF1F5F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFCBD5E1);
  static const Color dividerLight = Color(0xFFCBD5E1);

  // Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Status Colors
  static const Color statusDraft = Color(0xFF64748B);
  static const Color statusWaitingFirst = Color(0xFFD97706); // Amber
  static const Color statusWaitingSecond = Color(0xFF2563EB); // Blue
  static const Color statusCompleted = Color(0xFF16A34A); // Green
  static const Color statusCancelled = Color(0xFFDC2626); // Red

  // Risk / Alert Severities
  static const Color severityLow = Color(0xFF3B82F6);
  static const Color severityMedium = Color(0xFFF59E0B);
  static const Color severityHigh = Color(0xFFEA580C);
  static const Color severityCritical = Color(0xFFDC2626);

  static const Color riskLow = severityLow;
  static const Color riskMedium = severityMedium;
  static const Color riskHigh = severityHigh;
  static const Color riskCritical = severityCritical;

  // Functional Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
}

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1D26);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderLightAlt = Color(0xFFF0F0F0);
  static const Color scaffoldBgLight = Color(0xFFF5F7FA);
  static const Color fieldBgLight = Color(0xFFF5F7FA);
  static const Color chipBgLight = Color(0xFFF5F7FA);

  static const Color bgDark = Color(0xFF0F1118);
  static const Color surfaceDark = Color(0xFF1A1D28);
  static const Color textPrimaryDark = Color(0xFFF1F1F6);
  static const Color textSecondaryDark = Color(0xFFA0A4B0);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  static const Color borderDark = Color(0xFF2A2D3A);
  static const Color fieldBgDark = Color(0xFF242736);
  static const Color chipBgDark = Color(0xFF242736);

  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color successText = Color(0xFF065F46);
  static const Color successDark = Color(0xFF34D399);
  static const Color successBgDark = Color(0xFF064E3B);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color dangerText = Color(0xFF991B1B);
  static const Color dangerDark = Color(0xFFF87171);
  static const Color dangerBgDark = Color(0xFF7F1D1D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFF92400E);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningBgDark = Color(0xFF78350F);

  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFEEF2FF);
  static const Color infoBgDark = Color(0xFF1E3A5F);

  static Color of(BuildContext context, {required Color light, required Color dark}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  static Color bg(BuildContext context) =>
      of(context, light: bgLight, dark: bgDark);
  static Color surface(BuildContext context) =>
      of(context, light: surfaceLight, dark: surfaceDark);
  static Color textPrimary(BuildContext context) =>
      of(context, light: textPrimaryLight, dark: textPrimaryDark);
  static Color textSecondary(BuildContext context) =>
      of(context, light: textSecondaryLight, dark: textSecondaryDark);
  static Color textTertiary(BuildContext context) =>
      of(context, light: textTertiaryLight, dark: textTertiaryDark);
  static Color border(BuildContext context) =>
      of(context, light: borderLight, dark: borderDark);
  static Color fieldBg(BuildContext context) =>
      of(context, light: fieldBgLight, dark: fieldBgDark);
  static Color chipBg(BuildContext context) =>
      of(context, light: chipBgLight, dark: chipBgDark);

  static Color successOf(BuildContext context, {bool bg = false, bool text = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (bg) return isDark ? successBgDark : successBg;
    if (text) return isDark ? successDark : successText;
    return isDark ? successDark : success;
  }

  static Color dangerOf(BuildContext context, {bool bg = false, bool text = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (bg) return isDark ? dangerBgDark : dangerBg;
    if (text) return isDark ? dangerDark : dangerText;
    return isDark ? dangerDark : danger;
  }

  static Color warningOf(BuildContext context, {bool bg = false, bool text = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (bg) return isDark ? warningBgDark : warningBg;
    if (text) return isDark ? warningDark : warningText;
    return isDark ? warningDark : warning;
  }

  static Color infoOf(BuildContext context, {bool bg = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (bg) return isDark ? infoBgDark : infoBg;
    return primary;
  }

  static Color statusBg(String status, BuildContext context) {
    switch (status) {
      case 'Issued':
        return infoOf(context, bg: true);
      case 'Cleared':
        return successOf(context, bg: true);
      case 'Stale':
        return warningOf(context, bg: true);
      case 'Void':
        return dangerOf(context, bg: true);
      default:
        return chipBg(context);
    }
  }

  static Color statusText(String status, BuildContext context) {
    switch (status) {
      case 'Issued':
        return infoOf(context);
      case 'Cleared':
        return successOf(context, text: false);
      case 'Stale':
        return warningOf(context, text: false);
      case 'Void':
        return dangerOf(context, text: false);
      default:
        return textSecondary(context);
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'Issued':
        return Icons.schedule_rounded;
      case 'Cleared':
        return Icons.check_circle_rounded;
      case 'Stale':
        return Icons.warning_rounded;
      case 'Void':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

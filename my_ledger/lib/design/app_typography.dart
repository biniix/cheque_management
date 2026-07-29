import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers that use Plus Jakarta Sans consistently across the app.
/// Falls back to system sans-serif if Google Fonts can't load.
class AppText {
  AppText._();

  static TextStyle _tryFont({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );
    }
  }

  // ── Headings ──
  static TextStyle h1(BuildContext context) => _tryFont(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: _textPrimary(context),
        letterSpacing: -0.8,
      );

  static TextStyle h2(BuildContext context) => _tryFont(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _textPrimary(context),
        letterSpacing: -0.5,
      );

  static TextStyle h3(BuildContext context) => _tryFont(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _textPrimary(context),
      );

  static TextStyle h4(BuildContext context) => _tryFont(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _textPrimary(context),
      );

  static TextStyle h5(BuildContext context) => _tryFont(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _textPrimary(context),
      );

  // ── Body ──
  static TextStyle body1(BuildContext context) => _tryFont(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _textSecondary(context),
      );

  static TextStyle body2(BuildContext context) => _tryFont(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _textSecondary(context),
      );

  static TextStyle body3(BuildContext context) => _tryFont(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: _textSecondary(context),
      );

  static TextStyle caption(BuildContext context) => _tryFont(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _textTertiary(context),
      );

  static TextStyle overline(BuildContext context) => _tryFont(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _textTertiary(context),
        letterSpacing: 0.5,
      );

  // ── Labels ──
  static TextStyle label(BuildContext context) => _tryFont(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textPrimary(context),
      );

  static TextStyle smallLabel(BuildContext context) => _tryFont(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _textPrimary(context),
      );

  // ── Numeric / Mono ──
  static TextStyle mono(BuildContext context, {double size = 14, FontWeight weight = FontWeight.w600}) {
    try {
      return GoogleFonts.inconsolata(
        fontSize: size,
        fontWeight: weight,
        color: _textPrimary(context),
      );
    } catch (_) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: _textPrimary(context),
      );
    }
  }

  // ── Button ──
  static TextStyle button(BuildContext context) => _tryFont(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // ── Internal helpers ──
  static Color _textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFF1F1F6) : const Color(0xFF1A1D26);
  }

  static Color _textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFA0A4B0) : const Color(0xFF6B7280);
  }

  static Color _textTertiary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  }
}

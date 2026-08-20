import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design/app_colors.dart';
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final Color bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final Color surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final Color textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final Color textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final Color border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final Color fieldBg = isDark ? AppColors.fieldBgDark : AppColors.fieldBgLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: border,
      shadowColor: isDark ? Colors.black26 : const Color.fromRGBO(0, 0, 0, 0.06),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: surface,
        brightness: brightness,
      ),
      textTheme: _buildTextTheme(isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _tryFont(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: _tryFont(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: isDark ? 8 : 4,
        shape: const CircleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: _tryFont(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        hintStyle: _tryFont(fontSize: 14, fontWeight: FontWeight.w400, color: textTertiary),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fieldBg,
        selectedColor: AppColors.primary,
        labelStyle: _tryFont(fontSize: 12, fontWeight: FontWeight.w400, color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: BorderSide.none,
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final Color textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final Color textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return GoogleFonts.interTextTheme(
      TextTheme(
        headlineLarge: _tryFont(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.8),
        headlineMedium: _tryFont(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.5),
        titleLarge: _tryFont(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: _tryFont(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: _tryFont(fontSize: 16, fontWeight: FontWeight.w400, color: textSecondary),
        bodyMedium: _tryFont(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: _tryFont(fontSize: 12, fontWeight: FontWeight.w400, color: textTertiary),
        labelLarge: _tryFont(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelSmall: _tryFont(fontSize: 11, fontWeight: FontWeight.w600, color: textTertiary),
      ),
    );
  }
  static TextStyle _tryFont({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
  }) {
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
  }
}
final ThemeData lightTheme = AppTheme.light;

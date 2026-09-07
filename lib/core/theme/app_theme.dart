import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system Calisthenics Tracker — match UI mockup.
/// Accent orange, radius 14-18, Inter font.
class AppColors {
  // Light
  static const bgLight = Color(0xFFF7F8FA);
  static const surfaceLight = Colors.white;
  static const surface2Light = Color(0xFFF0F2F5);
  static const inkLight = Color(0xFF1A1D21);
  static const inkMutedLight = Color(0xFF6B7280);
  static const borderLight = Color(0xFFE5E7EB);
  // Dark
  static const bgDark = Color(0xFF121417);
  static const surfaceDark = Color(0xFF1C1F23);
  static const surface2Dark = Color(0xFF26292E);
  static const inkDark = Color(0xFFF2F3F5);
  static const inkMutedDark = Color(0xFF9CA3AF);
  static const borderDark = Color(0xFF2E3238);
  // Brand
  static const accent = Color(0xFFE8542F);
  static const accentDark = Color(0xFFFF6B42);
  static const accentSoftLight = Color(0xFFFDEDE8);
  static const accentSoftDark = Color(0xFF331F18);
  static const success = Color(0xFF16A34A);
  static const successDark = Color(0xFF22C55E);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.accent,
        surface: AppColors.surfaceLight,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
    );
    return _apply(base, isDark: false);
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentDark,
        brightness: Brightness.dark,
        primary: AppColors.accentDark,
        surface: AppColors.surfaceDark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
    );
    return _apply(base, isDark: true);
  }

  static ThemeData _apply(ThemeData base, {required bool isDark}) {
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3,
          color: isDark ? AppColors.inkDark : AppColors.inkLight,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.inkDark : AppColors.inkLight,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accentDark : AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.inkDark : AppColors.inkLight,
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
    );
  }
}

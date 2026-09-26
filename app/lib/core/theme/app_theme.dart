import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Duolingo-inspired design system: chunky rounded shapes, bold weights,
/// generous tap targets, minimal shadows (depth comes from flat color
/// borders / "3D press" buttons instead of blur).
class AppTheme {
  AppTheme._();

  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusXl = 28.0;
  static const radiusPill = 999.0;

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;

  static TextTheme _textTheme(Color color) {
    final base = GoogleFonts.nunitoTextTheme();
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 34,
            height: 1.15,
            letterSpacing: -0.5,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            height: 1.2,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            height: 1.2,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.4,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.4,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        )
        .apply(bodyColor: color, displayColor: color);
  }

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.mastered,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.weak,
    ),
    textTheme: _textTheme(AppColors.ink),
    fontFamily: GoogleFonts.nunito().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dividerColor: AppColors.border,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.mastered,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.inkDark,
      error: AppColors.weak,
    ),
    textTheme: _textTheme(AppColors.inkDark),
    fontFamily: GoogleFonts.nunito().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dividerColor: AppColors.borderDark,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

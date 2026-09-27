import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// "Field Notes" (light) / "Arcade Gym" (dark): warm, chunky, notebook-ish
/// design system. Fraunces is the one display face in both themes — only
/// color changes with theme, never type — paired with DM Sans for body/UI
/// text. Depth still comes from flat "3D press" buttons, not blur shadows.
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
    final display = GoogleFonts.frauncesTextTheme();
    final body = GoogleFonts.dmSansTextTheme();
    return body
        .copyWith(
          displayLarge: display.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 34,
            height: 1.15,
            letterSpacing: -0.5,
          ),
          headlineLarge: display.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 26,
            height: 1.2,
          ),
          headlineMedium: display.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            height: 1.2,
          ),
          titleLarge: display.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          titleMedium: body.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          bodyLarge: body.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.4,
          ),
          bodyMedium: body.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.4,
          ),
          labelLarge: body.labelLarge?.copyWith(
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
    scaffoldBackgroundColor: AppColors.light.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.light.accent,
      onPrimary: AppColors.light.accentInk,
      secondary: AppColors.light.mastered,
      surface: AppColors.light.surface,
      onSurface: AppColors.light.ink,
      error: AppColors.light.weak,
    ),
    textTheme: _textTheme(AppColors.light.ink),
    fontFamily: GoogleFonts.dmSans().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.light.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dividerColor: AppColors.light.border,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: const [AppColors.light],
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.dark.background,
    colorScheme: ColorScheme.dark(
      primary: AppColors.dark.accent,
      onPrimary: AppColors.dark.accentInk,
      secondary: AppColors.dark.mastered,
      surface: AppColors.dark.surface,
      onSurface: AppColors.dark.ink,
      error: AppColors.dark.weak,
    ),
    textTheme: _textTheme(AppColors.dark.ink),
    fontFamily: GoogleFonts.dmSans().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.dark.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dividerColor: AppColors.dark.border,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: const [AppColors.dark],
  );
}

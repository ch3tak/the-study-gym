import 'package:flutter/material.dart';

/// Study Gym palette — "Field Notes" (light) / "Arcade Gym" (dark): one
/// component system on shared tokens, only color redefines per theme. A
/// `ThemeExtension` (not static constants) so every color actually follows
/// `Theme.of(context)` and light/dark both render correctly — read via
/// `context.colors.foo`, never `AppColors.foo` directly.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.accentShadow,
    required this.mastered,
    required this.masteredLight,
    required this.masteredDark,
    required this.learning,
    required this.learningLight,
    required this.learningDark,
    required this.weak,
    required this.weakLight,
    required this.weakDark,
    required this.notStarted,
    required this.notStartedLight,
    required this.mathsAccent,
    required this.scienceAccent,
    required this.streak,
    required this.xp,
  });

  // Surfaces
  final Color background;
  final Color surface;
  final Color surfaceAlt;

  // Neutrals
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color border;
  final Color borderStrong;

  // Brand accent (terracotta in light / neon-lime in dark)
  final Color accent;
  final Color accentInk; // text/icon color that sits on top of `accent`
  final Color accentSoft;
  final Color accentShadow; // ChunkyButton "3D" slab under the accent face

  // Mastery states — never rely on color alone (icons/labels always pair with these)
  final Color mastered;
  final Color masteredLight;
  final Color masteredDark;
  final Color learning;
  final Color learningLight;
  final Color learningDark;
  final Color weak;
  final Color weakLight;
  final Color weakDark;
  final Color notStarted;
  final Color notStartedLight;

  // Subject accents
  final Color mathsAccent;
  final Color scienceAccent;

  // Semantic
  final Color streak;
  final Color xp;

  Color get correct => mastered;
  Color get incorrect => weak;
  Color get brand => accent;
  Color get brandLight => accentSoft;
  Color get brandDark => accentShadow;

  static const light = AppColors(
    background: Color(0xFFF7F2E7),
    surface: Color(0xFFFFFDF7),
    surfaceAlt: Color(0xFFF3EAD9),
    ink: Color(0xFF2B241A),
    inkSoft: Color(0xFF7D7362),
    inkFaint: Color(0xFF9B9182),
    border: Color(0xFFE4D9C2),
    borderStrong: Color(0xFFD2C3A3),
    accent: Color(0xFFB5541F),
    accentInk: Colors.white,
    accentSoft: Color(0xFFF3DFC9),
    accentShadow: Color(0xFF7C3F14),
    mastered: Color(0xFF3F6B3F),
    masteredLight: Color(0xFFE2ECDD),
    masteredDark: Color(0xFF2C4E2C),
    learning: Color(0xFFC98A1F),
    learningLight: Color(0xFFF6E6C8),
    learningDark: Color(0xFF9C6B15),
    weak: Color(0xFFC0392B),
    weakLight: Color(0xFFF7DFDA),
    weakDark: Color(0xFF902A20),
    notStarted: Color(0xFFB2A793),
    notStartedLight: Color(0xFFEFE7D8),
    mathsAccent: Color(0xFFB5541F),
    scienceAccent: Color(0xFF3F6B7A),
    streak: Color(0xFFE07A1F),
    xp: Color(0xFFD1A017),
  );

  static const dark = AppColors(
    background: Color(0xFF121210),
    surface: Color(0xFF1C1C17),
    surfaceAlt: Color(0xFF242420),
    ink: Color(0xFFF4F3EC),
    inkSoft: Color(0xFF948F80),
    inkFaint: Color(0xFF6E6A5D),
    border: Color(0xFF33322A),
    borderStrong: Color(0xFF454337),
    accent: Color(0xFFC8FF4D),
    accentInk: Color(0xFF12120F),
    accentSoft: Color(0xFF2B3418),
    accentShadow: Color(0xFF83A52C),
    mastered: Color(0xFF7EE787),
    masteredLight: Color(0xFF1C3320),
    masteredDark: Color(0xFFA9F2AF),
    learning: Color(0xFFFFB454),
    learningLight: Color(0xFF3A2C12),
    learningDark: Color(0xFFFFCB8A),
    weak: Color(0xFFFF6B6B),
    weakLight: Color(0xFF3A1E1C),
    weakDark: Color(0xFFFF9A9A),
    notStarted: Color(0xFF5A5850),
    notStartedLight: Color(0xFF242420),
    mathsAccent: Color(0xFFC8FF4D),
    scienceAccent: Color(0xFF5EE7FF),
    streak: Color(0xFFFFB454),
    xp: Color(0xFFFFE066),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? border,
    Color? borderStrong,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? accentShadow,
    Color? mastered,
    Color? masteredLight,
    Color? masteredDark,
    Color? learning,
    Color? learningLight,
    Color? learningDark,
    Color? weak,
    Color? weakLight,
    Color? weakDark,
    Color? notStarted,
    Color? notStartedLight,
    Color? mathsAccent,
    Color? scienceAccent,
    Color? streak,
    Color? xp,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      accentShadow: accentShadow ?? this.accentShadow,
      mastered: mastered ?? this.mastered,
      masteredLight: masteredLight ?? this.masteredLight,
      masteredDark: masteredDark ?? this.masteredDark,
      learning: learning ?? this.learning,
      learningLight: learningLight ?? this.learningLight,
      learningDark: learningDark ?? this.learningDark,
      weak: weak ?? this.weak,
      weakLight: weakLight ?? this.weakLight,
      weakDark: weakDark ?? this.weakDark,
      notStarted: notStarted ?? this.notStarted,
      notStartedLight: notStartedLight ?? this.notStartedLight,
      mathsAccent: mathsAccent ?? this.mathsAccent,
      scienceAccent: scienceAccent ?? this.scienceAccent,
      streak: streak ?? this.streak,
      xp: xp ?? this.xp,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      inkFaint: c(inkFaint, other.inkFaint),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      accent: c(accent, other.accent),
      accentInk: c(accentInk, other.accentInk),
      accentSoft: c(accentSoft, other.accentSoft),
      accentShadow: c(accentShadow, other.accentShadow),
      mastered: c(mastered, other.mastered),
      masteredLight: c(masteredLight, other.masteredLight),
      masteredDark: c(masteredDark, other.masteredDark),
      learning: c(learning, other.learning),
      learningLight: c(learningLight, other.learningLight),
      learningDark: c(learningDark, other.learningDark),
      weak: c(weak, other.weak),
      weakLight: c(weakLight, other.weakLight),
      weakDark: c(weakDark, other.weakDark),
      notStarted: c(notStarted, other.notStarted),
      notStartedLight: c(notStartedLight, other.notStartedLight),
      mathsAccent: c(mathsAccent, other.mathsAccent),
      scienceAccent: c(scienceAccent, other.scienceAccent),
      streak: c(streak, other.streak),
      xp: c(xp, other.xp),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

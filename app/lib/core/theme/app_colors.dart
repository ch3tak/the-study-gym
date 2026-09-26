import 'package:flutter/material.dart';

/// Study Gym palette. Bold, high-contrast, Duolingo-adjacent — but our own
/// brand color (indigo) instead of green, since green is reserved for
/// "mastered" state everywhere in this app.
class AppColors {
  AppColors._();

  // Brand
  static const brand = Color(0xFF5B5BD6);
  static const brandDark = Color(0xFF4640B5);
  static const brandLight = Color(0xFFEEEEFC);

  // Mastery states — never rely on color alone (icons/labels always pair with these)
  static const mastered = Color(0xFF12A150);
  static const masteredDark = Color(0xFF0E8A44);
  static const masteredLight = Color(0xFFE3F8EA);

  static const learning = Color(0xFFF5A524);
  static const learningDark = Color(0xFFD1890F);
  static const learningLight = Color(0xFFFEF3E0);

  static const weak = Color(0xFFE5484D);
  static const weakDark = Color(0xFFC53A3F);
  static const weakLight = Color(0xFFFDECEC);

  static const notStarted = Color(0xFF9B9BA8);
  static const notStartedLight = Color(0xFFF0F0F3);

  // Subject accents
  static const mathsAccent = Color(0xFF5B5BD6);
  static const scienceAccent = Color(0xFF12A594);

  // Semantic
  static const correct = mastered;
  static const incorrect = weak;
  static const streak = Color(0xFFFF9500);
  static const xp = Color(0xFFFFC531);

  // Neutrals
  static const ink = Color(0xFF1A1A2E);
  static const inkSoft = Color(0xFF5B5B6B);
  static const inkFaint = Color(0xFF9B9BA8);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F7FB);
  static const border = Color(0xFFE3E3EC);
  static const borderStrong = Color(0xFFD0D0DE);

  // Dark mode neutrals
  static const inkDark = Color(0xFFF2F2F7);
  static const surfaceDark = Color(0xFF1E1E2E);
  static const backgroundDark = Color(0xFF13131F);
  static const borderDark = Color(0xFF2E2E42);
}

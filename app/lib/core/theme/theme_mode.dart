import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The student's System / Light / Dark choice. A per-device display
/// preference, so it lives in shared_preferences, not Supabase.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const prefsKey = 'theme_mode';

  /// Set by `main()` from [loadSaved] before `runApp`, so the first frame
  /// already uses the saved theme.
  static ThemeMode initial = ThemeMode.system;

  /// The saved choice, or System if there's none or it can't be read.
  static Future<ThemeMode> loadSaved() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(prefsKey);
      return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    } catch (e) {
      debugPrint('Could not load theme mode: $e');
      return ThemeMode.system;
    }
  }

  @override
  ThemeMode build() => initial;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(prefsKey, mode.name);
    } catch (e) {
      debugPrint('Could not save theme mode: $e');
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

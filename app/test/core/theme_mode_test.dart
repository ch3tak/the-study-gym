import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_gym/core/theme/theme_mode.dart';

void main() {
  setUp(() => ThemeModeNotifier.initial = ThemeMode.system);

  test('defaults to System when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ThemeModeNotifier.loadSaved(), ThemeMode.system);
  });

  test('a saved value loads', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    expect(await ThemeModeNotifier.loadSaved(), ThemeMode.dark);
  });

  test('an unrecognised saved value falls back to System', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    expect(await ThemeModeNotifier.loadSaved(), ThemeMode.system);
  });

  test('the provider starts from the loaded value', () {
    ThemeModeNotifier.initial = ThemeMode.light;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  test('changing it updates state and saves it', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(c.read(themeModeProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });
}

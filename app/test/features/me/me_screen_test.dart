import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/core/theme/theme_mode.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/features/me/me_screen.dart';

import '../../helpers/pump.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeModeNotifier.initial = ThemeMode.system;
  });

  Future<ProviderContainer> pumpMe(WidgetTester tester, {bool dark = false}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light, home: const MeScreen()),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows the Appearance choice and the coming-soon line', (tester) async {
    await pumpMe(tester);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Profile and streak history are coming soon.'), findsOneWidget);
  });

  testWidgets('choosing Dark then Light updates themeModeProvider', (tester) async {
    final c = await pumpMe(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(c.read(themeModeProvider), ThemeMode.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('renders in dark theme', (tester) async {
    await pumpMe(tester, dark: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Pro demo switch lives in Me', (tester) async {
    final container = await pumpScreen(tester, const MeScreen());
    expect(container.read(studentProvider).isPro, isFalse);
    await tester.tap(find.byKey(const ValueKey('pro_demo_switch')));
    await tester.pumpAndSettle();
    expect(container.read(studentProvider).isPro, isTrue);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_gym/core/theme/theme_mode.dart';
import 'package:study_gym/main.dart';

import 'fixtures/slice1_content.dart';

/// End-to-end smoke test of the POC's golden path:
/// Welcome -> Home, then every tab (Home · Learn · History · Me).
/// There is no Quick Setup step and no diagnostic (deliberately dropped —
/// see welcome_screen.dart): every path from Welcome lands straight on the
/// main dashboard, and mastery fills in as the student works through real
/// workouts instead of a separate up-front quiz. This is the same check the
/// `run` skill calls for: drive the app to where a user would actually see
/// something, on every screen in scope.
void main() {
  setUp(() {
    StudyGymApp.contentLoader = () async => slice1Snapshot();
    SharedPreferences.setMockInitialValues({});
    ThemeModeNotifier.initial = ThemeMode.system;
  });

  testWidgets('choosing Dark on the Me tab switches the whole app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(Theme.of(tester.element(find.text('Appearance'))).brightness, Brightness.dark);
  });

  testWidgets('welcome -> home, then every tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text('Sequences and Progressions'), findsWidgets);

    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    expect(find.text('History'), findsWidgets);

    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('"I already have an account" also lands directly on the dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('custom test builder is reachable and shows a Pro lock for free users', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Create a custom test'), 300);
    // scrollUntilVisible stops once the card is built, which can leave it
    // under the bottom tabs; bring it fully on screen before tapping.
    await tester.ensureVisible(find.text('Create a custom test'));
    await tester.pumpAndSettle();

    expect(find.text('Create a custom test'), findsOneWidget);
    expect(find.text('PRO'), findsWidgets); // free by default -> lock badges visible

    await tester.tap(find.text('Create a custom test'));
    await tester.pumpAndSettle();
    expect(find.text('Custom test'), findsOneWidget);
    expect(find.text('Maths'), findsNothing);
    expect(find.text('Science'), findsNothing);
    expect(find.text('Sequences and Progressions'), findsOneWidget);
    expect(find.text('Surface Area and Volume'), findsOneWidget);
  });
}

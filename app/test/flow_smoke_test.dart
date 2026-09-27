import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_gym/core/theme/theme_mode.dart';
import 'package:study_gym/main.dart';

import 'test_content.dart';

/// End-to-end smoke test of the POC's golden path:
/// Welcome -> Today, then every tab (Today · Theory · Mission · Tests · Me).
/// There is no Quick Setup step and no diagnostic (deliberately dropped —
/// see welcome_screen.dart): every path from Welcome lands straight on the
/// main dashboard, and mastery fills in as the student works through real
/// workouts instead of a separate up-front quiz. This is the same check the
/// `run` skill calls for: drive the app to where a user would actually see
/// something, on every screen in scope.
void main() {
  setUp(() {
    StudyGymApp.contentLoader = fakeContentLoader;
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

  testWidgets('welcome -> today -> workout flow renders without exceptions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();

    // S1. Welcome -> straight into the app, no setup step and no diagnostic.
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Today tab (app shell)
    expect(find.text('Today'), findsWidgets);
    expect(find.text("Today's workout"), findsOneWidget);

    // Every tab shows its own screen.
    await tester.tap(find.text('Theory').last);
    await tester.pumpAndSettle();
    expect(find.text('1 lesson'), findsOneWidget);

    await tester.tap(find.text('Mission').last);
    await tester.pumpAndSettle();
    expect(find.text('Sequences and Progressions'), findsOneWidget);
    expect(find.text('Start Mission'), findsNothing);

    await tester.tap(find.text('Tests').last);
    await tester.pumpAndSettle();
    expect(find.text('Create a custom test'), findsOneWidget);

    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Today').last);
    await tester.pumpAndSettle();
    expect(find.text("Today's workout"), findsOneWidget);
  });

  testWidgets('"I already have an account" also lands directly on the dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.text("Today's workout"), findsOneWidget);
  });

  testWidgets('custom test builder is reachable and shows a Pro lock for free users', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tests').last);
    await tester.pumpAndSettle();

    expect(find.text('Create a custom test'), findsOneWidget);
    expect(find.text('PRO'), findsWidgets); // free by default -> lock badges visible

    await tester.tap(find.text('Create a custom test'));
    await tester.pumpAndSettle();
    expect(find.text('Custom test'), findsOneWidget);
    expect(find.text('Maths'), findsNothing);
    expect(find.text('Science'), findsNothing);
    expect(find.text('Sequences and Progressions'), findsOneWidget);
    expect(find.text('Surface Areas and Volumes'), findsOneWidget);
  });
}

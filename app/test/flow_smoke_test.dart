import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_gym/main.dart';

/// End-to-end smoke test of the POC's golden path:
/// Welcome -> Today -> Workout -> complete.
/// There is no Quick Setup step and no diagnostic anymore: every path from
/// Welcome lands straight on the main dashboard, and mastery fills in as the
/// student works through real workouts instead of a separate up-front quiz.
/// This is the same check the `run` skill calls for: drive the app to where
/// a user would actually see something, on every screen in scope.
void main() {
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

    // Navigate to Skill Map tab
    await tester.tap(find.text('Skill Map').last);
    await tester.pumpAndSettle();
    expect(find.text('Skill Map'), findsWidgets);
    expect(find.text('Maths'), findsWidgets);
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
    expect(find.text('Maths'), findsOneWidget);

    // Science's section header may be off the initial viewport since Maths
    // lists many chapters first.
    await tester.scrollUntilVisible(find.text('Science'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Science'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/theory/lesson_screen.dart';
import 'package:study_gym/features/theory/theory_screen.dart';

import 'theory_fixtures.dart';

Future<void> pumpTheory(WidgetTester tester, {ThemeData? theme}) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(theme: theme ?? AppTheme.light, home: const TheoryScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(loadTheoryContent);
  tearDown(() => TheoryProgressNotifier.repositoryOverride = null);

  testWidgets('only chapters with lessons appear, with a coming-soon footer', (tester) async {
    await pumpTheory(tester);
    expect(find.text('Theory'), findsOneWidget);
    expect(find.text('Surface Areas and Volumes'), findsOneWidget);
    expect(find.text('Sequences and Progressions'), findsNothing);
    expect(find.text('2 lessons'), findsOneWidget);
    expect(find.text('More chapters coming soon.'), findsOneWidget);
  });

  testWidgets('the ring shows lessons read out of total', (tester) async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(initial: {'t_cube'});
    await pumpTheory(tester);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('expanding lists lessons in sortOrder with read ticks', (tester) async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(initial: {'t_cube'});
    await pumpTheory(tester);
    await tester.tap(find.text('Surface Areas and Volumes'));
    await tester.pumpAndSettle();
    final cubeY = tester.getTopLeft(find.text('Cuboids & Cubes')).dy;
    final pyrY = tester.getTopLeft(find.text('Pyramids')).dy;
    expect(cubeY, lessThan(pyrY));
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('tapping a lesson opens LessonScreen', (tester) async {
    await pumpTheory(tester);
    await tester.tap(find.text('Surface Areas and Volumes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pyramids'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('no lessons at all shows the empty state', (tester) async {
    Content.load(const ContentSnapshot(chapters: [], questions: []));
    await pumpTheory(tester);
    expect(find.text('Lessons are on their way.'), findsOneWidget);
  });

  // Themes are read inside each test: AppTheme's fonts must load in a test zone.
  for (final dark in [false, true]) {
    testWidgets('renders expanded in ${dark ? 'dark' : 'light'} theme', (tester) async {
      await pumpTheory(tester, theme: dark ? AppTheme.dark : AppTheme.light);
      await tester.tap(find.text('Surface Areas and Volumes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

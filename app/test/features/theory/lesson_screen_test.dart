import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/theory/lesson_screen.dart';

import 'theory_fixtures.dart';

/// Pushes the lesson on top of a placeholder so "goes back" is observable.
Future<void> pumpLesson(WidgetTester tester, Lesson lesson, {ThemeData? theme}) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
            ),
            child: const Text('list'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('list'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(loadTheoryContent);
  tearDown(() => TheoryProgressNotifier.repositoryOverride = null);

  testWidgets('real_world hook label and a Try it card when present', (tester) async {
    await pumpLesson(tester, cube);
    expect(find.text('Cuboids & Cubes'), findsOneWidget);
    expect(find.text('Where this shows up'), findsOneWidget);
    expect(find.text('Try it'), findsOneWidget);
    expect(find.text('Measure a shoebox.'), findsOneWidget);
  });

  testWidgets('historical hook label and no Try it card when absent', (tester) async {
    await pumpLesson(tester, pyramid);
    expect(find.text('A bit of history'), findsOneWidget);
    expect(find.text('Try it'), findsNothing);
  });

  testWidgets('Mark as read writes once and goes back', (tester) async {
    final repo = FakeTheoryRepo();
    TheoryProgressNotifier.repositoryOverride = repo;
    await pumpLesson(tester, cube);
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();
    expect(repo.writes, ['t_cube']);
    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('an already-read lesson shows a disabled Read ✓ and never writes', (tester) async {
    final repo = FakeTheoryRepo(initial: {'t_cube'});
    TheoryProgressNotifier.repositoryOverride = repo;
    await pumpLesson(tester, cube);
    expect(find.text('Read ✓'), findsOneWidget);
    await tester.tap(find.text('Read ✓'));
    await tester.pumpAndSettle();
    expect(repo.writes, isEmpty);
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('tapping Mark as read twice on a slow network writes once', (tester) async {
    final repo = FakeTheoryRepo()..writeGate = Completer<void>();
    TheoryProgressNotifier.repositoryOverride = repo;
    await pumpLesson(tester, cube);
    await tester.tap(find.text('Mark as read'));
    await tester.pump();
    await tester.tap(find.text('Mark as read'));
    await tester.pump();
    repo.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(repo.writes, ['t_cube']);
    expect(find.text('list'), findsOneWidget);
  });

  testWidgets('a failed save shows a snackbar and stays', (tester) async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(failWrites: true);
    await pumpLesson(tester, cube);
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save — try again"), findsOneWidget);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('Mark as read'), findsOneWidget);
  });

  // Themes are read inside each test: AppTheme's fonts must load in a test zone.
  for (final dark in [false, true]) {
    testWidgets('renders in ${dark ? 'dark' : 'light'} theme', (tester) async {
      await pumpLesson(tester, cube, theme: dark ? AppTheme.dark : AppTheme.light);
      expect(tester.takeException(), isNull);
    });
  }
}

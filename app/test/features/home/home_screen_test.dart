import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/daily_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/chapter/chapter_screen.dart';
import 'package:study_gym/features/home/home_screen.dart';
import 'package:study_gym/features/theory/lesson_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';
import 'package:study_gym/shared/widgets/streak_flame.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

final today = DateTime(2026, 9, 30, 10); // a Wednesday

ProviderContainer _container({StudentState? student}) {
  final c = ProviderContainer(overrides: [
    if (student != null) studentProvider.overrideWith(() => SeededStudent(student)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void _workoutOn(ProviderContainer c, DateTime day, {int correct = 4}) {
  DailyNotifier.clock = () => day;
  c.read(dailyProvider.notifier).recordWorkout(
        questionIds: const [],
        correct: correct,
        total: 5,
        keepGoing: false,
        startedAt: day,
      );
  DailyNotifier.clock = () => today;
}

List<DayState> _week(WidgetTester tester) => tester.widget<WeekDotsRow>(find.byType(WeekDotsRow)).days;

void main() {
  setUp(() {
    loadSlice1Content();
    DailyNotifier.clock = () => today;
  });
  tearDown(() => DailyNotifier.clock = DateTime.now);

  for (final t in themes.entries) {
    testWidgets('before today\'s workout: the workout hero, week row, no Needs attention (${t.key})', (tester) async {
      await pumpScreen(tester, const HomeScreen(), theme: t.value);
      expect(find.text('Class 9 ▾'), findsOneWidget);
      expect(find.text('Start your streak'), findsOneWidget);
      expect(find.text('Start workout'), findsOneWidget);
      expect(find.textContaining('Arithmetic progressions'), findsOneWidget);
      expect(_week(tester), hasLength(7));
      expect(_week(tester)[2], DayState.today);
      expect(find.byKey(const ValueKey('needs_attention')), findsNothing);
      expect(find.byKey(const ValueKey('continue_card')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a live streak changes the title', (tester) async {
    final c = _container();
    _workoutOn(c, today.subtract(const Duration(days: 1)));
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('Keep your 1-day streak going'), findsOneWidget);
  });

  testWidgets('Start workout opens a 5-question workout', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(of: find.byType(AppBar), matching: find.byType(LinearProgressIndicator)));
    expect(bar.value, closeTo(0.2, 1e-9));
  });

  testWidgets('after the workout: Continue replaces the hero; today\'s dot is done; the done row shows', (tester) async {
    final c = _container();
    _workoutOn(c, today);
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.byKey(const ValueKey('workout_hero')), findsNothing);
    expect(find.byKey(const ValueKey('continue_card')), findsOneWidget);
    expect(_week(tester)[2], DayState.done);
    expect(find.text('Daily workout · 4 / 5'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('workout_done_row')), matching: find.text('Keep going')), findsOneWidget);
  });

  testWidgets('no chapter started: suggests the first chapter and opens it', (tester) async {
    final c = _container();
    _workoutOn(c, today);
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('Start your first chapter'), findsOneWidget);
    expect(find.text('Sequences and Progressions'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsOneWidget);
  });

  testWidgets('Continue opens the next lesson directly', (tester) async {
    final c = _container();
    _workoutOn(c, today);
    await c.read(theoryProgressProvider.notifier).markRead('t_cube');
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('Continue your chapter'), findsOneWidget);
    expect(find.text('Topic 2 of 3'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('Cylinders'), findsOneWidget);
  });

  testWidgets('with every topic done, Continue goes straight into the next Trial level', (tester) async {
    final c = _container();
    _workoutOn(c, today);
    for (final id in ['t_cube', 't_cyl', 't_cone']) {
      await c.read(theoryProgressProvider.notifier).markRead(id);
    }
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('Trial level 1 of 10'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });

  testWidgets('Needs attention appears for fading topics and opens a review', (tester) async {
    final c = _container(
      student: StudentState(mastery: {
        'c.ap': ConceptMastery(
          conceptId: 'c.ap',
          masteryPercent: 90,
          attempts: 5,
          lastPracticed: today.subtract(const Duration(days: 6)),
        ),
      }),
    );
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('1 topic fading · Review'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('needs_attention')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });
}

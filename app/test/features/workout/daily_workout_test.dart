import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/daily_state.dart';
import 'package:study_gym/features/workout/workout_complete_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';
import 'package:study_gym/features/workout/workout_selector.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

final today = DateTime(2026, 9, 28, 10);

double _progress(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(
        find.descendant(of: find.byType(AppBar), matching: find.byType(LinearProgressIndicator)))
    .value!;

Future<ProviderContainer> _startDaily(WidgetTester tester, {bool pro = false}) async {
  final container = ProviderContainer(overrides: [
    studentProvider.overrideWith(() => SeededStudent(StudentState(isPro: pro))),
  ]);
  addTearDown(container.dispose);
  await pumpScreen(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => WorkoutScreen(
              concepts: [Content.conceptById('c.ap'), Content.conceptById('c.gp')],
              kind: WorkoutKind.daily,
            ),
          )),
          child: const Text('start'),
        ),
      ),
    ),
    container: container,
  );
  await tester.tap(find.text('start'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    loadSlice1Content();
    DailyNotifier.clock = () => today;
  });
  tearDown(() => DailyNotifier.clock = DateTime.now);

  testWidgets('the daily workout has 5 questions and is saved when finished', (tester) async {
    final container = await _startDaily(tester);
    expect(_progress(tester), closeTo(0.2, 1e-9), reason: 'question 1 of 5');

    await answerQuestions(tester, 5);

    expect(find.byType(WorkoutCompleteScreen), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);
    expect(find.text('Keep going'), findsOneWidget);
    final daily = container.read(dailyProvider);
    expect(daily.workoutDoneOn(today), isTrue);
    expect(daily.firstWorkoutOn(today)!.total, 5);
    expect(daily.servedQuestionIds, hasLength(5));
  });

  testWidgets('free users get the Pro sheet for Keep going', (tester) async {
    await _startDaily(tester);
    await answerQuestions(tester, 5);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('Keep going is a Pro feature'), findsOneWidget);
    expect(find.byType(WorkoutScreen), findsNothing);
  });

  testWidgets('Pro users get 5 more, unseen questions; the daily workout stays done', (tester) async {
    final container = await _startDaily(tester, pro: true);
    await answerQuestions(tester, 5);
    final served = container.read(dailyProvider).servedQuestionIds;

    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(_progress(tester), closeTo(0.2, 1e-9), reason: 'question 1 of 5 again');
    for (final id in served) {
      expect(find.textContaining('Stem $id', findRichText: true), findsNothing, reason: '$id was already served');
    }

    await answerQuestions(tester, 5);
    final daily = container.read(dailyProvider);
    expect(daily.workouts, hasLength(2));
    expect(daily.workouts.last.keepGoing, isTrue);
    expect(daily.streakOn(today), 1, reason: 'Keep going never adds a second day');
  });

  testWidgets('a practice run is not saved as a workout and offers no Keep going', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await pumpScreen(tester, WorkoutScreen(concepts: [Content.conceptById('c.ap')]), container: container);
    // Practice keeps 10 questions: c.ap's 6, widened to its chapter for 4 more.
    await answerQuestions(tester, 10);
    expect(find.byType(WorkoutCompleteScreen), findsOneWidget);
    expect(find.text('Keep going'), findsNothing);
    expect(container.read(dailyProvider).workouts, isEmpty);
  });
}

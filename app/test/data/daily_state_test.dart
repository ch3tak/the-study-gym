import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/daily_repository.dart';
import 'package:study_gym/data/daily_state.dart';
import 'package:study_gym/shared/widgets/streak_flame.dart';

// 28 Sep 2026 is a Monday.
final mon = DateTime(2026, 9, 28, 10);
final tue = DateTime(2026, 9, 29, 10);
final wed = DateTime(2026, 9, 30, 10);

class FakeDailyRepo implements DailyRepository {
  FakeDailyRepo({this.snapshot = const DailySnapshot(workouts: [], streak: StreakRecord())});
  final DailySnapshot snapshot;
  final saved = <WorkoutRecord>[];
  final streaks = <StreakRecord>[];

  @override
  Future<DailySnapshot> fetch({int days = 14}) async => snapshot;

  @override
  Future<void> recordWorkout(WorkoutRecord workout, {required DateTime startedAt}) async => saved.add(workout);

  @override
  Future<void> saveStreak(StreakRecord streak) async => streaks.add(streak);
}

/// A repository whose first load finishes (or fails) when the test says so.
class _SlowDailyRepo extends FakeDailyRepo {
  _SlowDailyRepo(this._fetch);
  final Future<DailySnapshot> _fetch;

  @override
  Future<DailySnapshot> fetch({int days = 14}) => _fetch;
}

void main() {
  tearDown(() {
    DailyNotifier.clock = DateTime.now;
    DailyNotifier.repositoryOverride = null;
  });

  group('streak', () {
    test('first ever workout starts the streak at 1', () {
      final s = streakAfterWorkout(const StreakRecord(), mon);
      expect(s.current, 1);
      expect(s.longest, 1);
      expect(s.lastActiveDate, calendarDay(mon));
    });

    test('a workout the day after adds one', () {
      final s = streakAfterWorkout(StreakRecord(current: 4, longest: 4, lastActiveDate: mon), tue);
      expect(s.current, 5);
      expect(s.longest, 5);
    });

    test('a second workout the same day changes nothing', () {
      final before = StreakRecord(current: 4, longest: 6, lastActiveDate: mon);
      expect(streakAfterWorkout(before, mon.add(const Duration(hours: 5))), same(before));
    });

    test('a missed day restarts at 1 and keeps the longest', () {
      final s = streakAfterWorkout(StreakRecord(current: 4, longest: 6, lastActiveDate: mon), wed);
      expect(s.current, 1);
      expect(s.longest, 6);
    });

    test("a DST change doesn't break the streak", () {
      // Europe moves clocks back on 25 Oct 2026; the local days are still consecutive.
      final s = streakAfterWorkout(
        StreakRecord(current: 2, longest: 2, lastActiveDate: DateTime(2026, 10, 25)),
        DateTime(2026, 10, 26, 0, 30),
      );
      expect(s.current, 3);
    });

    test('streakOn shows the stored streak only while it is alive', () {
      final state = DailyState(streak: StreakRecord(current: 3, longest: 3, lastActiveDate: mon));
      expect(state.streakOn(mon), 3);
      expect(state.streakOn(tue), 3);
      expect(state.streakOn(wed), 0);
      expect(const DailyState().streakOn(mon), 0);
    });
  });

  group('week row', () {
    test('seven Monday-to-Sunday dots; today stays open until the workout is done', () {
      final state = DailyState(workouts: [WorkoutRecord(completedAt: tue, correct: 4, total: 5)]);
      expect(state.weekOf(wed), [
        DayState.missed,
        DayState.done,
        DayState.today,
        DayState.future,
        DayState.future,
        DayState.future,
        DayState.future,
      ]);
      final after = DailyState(workouts: [...state.workouts, WorkoutRecord(completedAt: wed, correct: 5, total: 5)]);
      expect(after.weekOf(wed)[2], DayState.done);
    });

    test('a late-night workout counts for its own day', () {
      final state = DailyState(workouts: [WorkoutRecord(completedAt: DateTime(2026, 9, 29, 23, 30), correct: 5, total: 5)]);
      expect(state.workoutDoneOn(tue), isTrue);
      expect(state.workoutDoneOn(wed), isFalse);
    });

    test("firstWorkoutOn returns the day's first workout, not Keep going", () {
      final state = DailyState(workouts: [
        WorkoutRecord(completedAt: mon.add(const Duration(hours: 2)), correct: 5, total: 5, keepGoing: true),
        WorkoutRecord(completedAt: mon, correct: 3, total: 5),
      ]);
      expect(state.firstWorkoutOn(mon)!.correct, 3);
    });
  });

  group('DailyNotifier', () {
    test('recording a workout saves the session and streak and remembers served questions', () async {
      final repo = FakeDailyRepo();
      DailyNotifier.repositoryOverride = repo;
      DailyNotifier.clock = () => mon;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(dailyProvider);
      await Future<void>.delayed(Duration.zero);

      container.read(dailyProvider.notifier).recordWorkout(
            questionIds: ['a', 'b'],
            correct: 1,
            total: 2,
            keepGoing: false,
            startedAt: mon,
          );

      final state = container.read(dailyProvider);
      expect(state.workoutDoneOn(mon), isTrue);
      expect(state.streakOn(mon), 1);
      expect(state.servedQuestionIds, {'a', 'b'});
      expect(repo.saved.single.total, 2);
      expect(repo.streaks.single.current, 1);
    });

    test('a workout finished before the saved streak loads builds on it instead of overwriting it', () async {
      final fetch = Completer<DailySnapshot>();
      final repo = _SlowDailyRepo(fetch.future);
      DailyNotifier.repositoryOverride = repo;
      DailyNotifier.clock = () => tue;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(dailyProvider);

      container.read(dailyProvider.notifier).recordWorkout(
            questionIds: ['a'],
            correct: 1,
            total: 1,
            keepGoing: false,
            startedAt: tue,
          );
      fetch.complete(DailySnapshot(workouts: const [], streak: StreakRecord(current: 7, longest: 7, lastActiveDate: mon)));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(dailyProvider).streakOn(tue), 8);
      expect(repo.streaks.map((s) => s.current), [8], reason: 'a streak of 1 must never be saved over 7');
      expect(repo.saved, hasLength(1));
    });

    test('if the saved streak never loads, a workout does not overwrite it', () async {
      final repo = _SlowDailyRepo(Future.error(StateError('offline')));
      DailyNotifier.repositoryOverride = repo;
      DailyNotifier.clock = () => tue;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(dailyProvider);
      await Future<void>.delayed(Duration.zero);

      container.read(dailyProvider.notifier).recordWorkout(
            questionIds: ['a'],
            correct: 1,
            total: 1,
            keepGoing: false,
            startedAt: tue,
          );

      expect(repo.streaks, isEmpty);
      expect(repo.saved, hasLength(1), reason: 'the workout itself is still saved');
      expect(container.read(dailyProvider).workoutDoneOn(tue), isTrue);
    });

    test('hydrates past workouts and the stored streak', () async {
      DailyNotifier.repositoryOverride = FakeDailyRepo(
        snapshot: DailySnapshot(
          workouts: [WorkoutRecord(completedAt: mon, correct: 5, total: 5)],
          streak: StreakRecord(current: 7, longest: 9, lastActiveDate: mon),
        ),
      );
      DailyNotifier.clock = () => tue;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(dailyProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(dailyProvider);
      expect(state.workoutDoneOn(mon), isTrue);
      expect(state.streakOn(tue), 7);
    });
  });
}

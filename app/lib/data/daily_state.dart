import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/widgets/streak_flame.dart' show DayState;
import 'daily_repository.dart';

/// The calendar day of [t] as a UTC midnight, so day arithmetic ignores DST.
/// [t] must be a local time (or already a calendar day).
DateTime calendarDay(DateTime t) => DateTime.utc(t.year, t.month, t.day);

/// `YYYY-MM-DD` for a calendar day, as `streaks.last_active_date` stores it.
String isoDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

/// One finished workout (a `sessions` row of kind `workout`).
class WorkoutRecord {
  const WorkoutRecord({required this.completedAt, required this.correct, required this.total, this.keepGoing = false});

  /// Local time.
  final DateTime completedAt;
  final int correct;
  final int total;
  final bool keepGoing;
}

/// Mirrors the `streaks` row.
class StreakRecord {
  const StreakRecord({this.current = 0, this.longest = 0, this.lastActiveDate});
  final int current;
  final int longest;

  /// The last calendar day with a workout.
  final DateTime? lastActiveDate;
}

class DailySnapshot {
  const DailySnapshot({required this.workouts, required this.streak});
  final List<WorkoutRecord> workouts;
  final StreakRecord streak;
}

/// Everything day-based on Home: whether today's workout is done, the streak
/// and the week row. The only owner of the streak.
class DailyState {
  const DailyState({this.workouts = const [], this.streak = const StreakRecord(), this.servedQuestionIds = const {}});

  /// Recent workouts (the last two weeks, plus any finished this run).
  final List<WorkoutRecord> workouts;
  final StreakRecord streak;

  /// Question ids served since the app started; the next Keep going batch
  /// leaves them out.
  final Set<String> servedQuestionIds;

  WorkoutRecord? firstWorkoutOn(DateTime day) {
    final d = calendarDay(day);
    final sameDay = workouts.where((w) => calendarDay(w.completedAt) == d).toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return sameDay.firstOrNull;
  }

  bool workoutDoneOn(DateTime day) => firstWorkoutOn(day) != null;

  /// The streak as of [today]: the stored count while it's alive (last
  /// workout today or yesterday), else 0.
  int streakOn(DateTime today) {
    final last = streak.lastActiveDate;
    if (last == null) return 0;
    final gap = calendarDay(today).difference(calendarDay(last)).inDays;
    return gap <= 1 ? streak.current : 0;
  }

  /// Monday-to-Sunday dots for the week containing [today]. Today is
  /// [DayState.today] (drawn dashed) until its workout is done.
  List<DayState> weekOf(DateTime today) {
    final t = calendarDay(today);
    final monday = t.subtract(Duration(days: t.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final done = workoutDoneOn(day);
      if (day == t) return done ? DayState.done : DayState.today;
      if (day.isAfter(t)) return DayState.future;
      return done ? DayState.done : DayState.missed;
    });
  }
}

/// The streak after a workout finishes at [now]. A second workout on the
/// same day changes nothing; a missed day restarts it at 1.
StreakRecord streakAfterWorkout(StreakRecord s, DateTime now) {
  final today = calendarDay(now);
  final last = s.lastActiveDate == null ? null : calendarDay(s.lastActiveDate!);
  if (last == today) return s;
  final current = (last != null && today.difference(last).inDays == 1) ? s.current + 1 : 1;
  return StreakRecord(current: current, longest: current > s.longest ? current : s.longest, lastActiveDate: today);
}

class DailyNotifier extends Notifier<DailyState> {
  /// Set by main.dart; null in tests that don't need persistence.
  static DailyRepository? repositoryOverride;

  /// "Now" for everything date-based. Tests pin it.
  static DateTime Function() clock = DateTime.now;

  DailyRepository? get _repo => repositoryOverride;

  /// Whether the saved streak has loaded. Until it has, the streak in state
  /// started from zero and must never be saved over the real one.
  bool _streakLoaded = false;

  /// The load in flight, so a retry never starts a second one.
  Future<void>? _loading;

  @override
  DailyState build() {
    if (_repo != null) _load();
    return const DailyState();
  }

  void _load() => _loading ??= _hydrate().whenComplete(() => _loading = null);

  Future<void> _hydrate() async {
    try {
      final snap = await _repo!.fetch();
      // A workout finished while this fetch was in flight is already in
      // state: keep it, and replay it onto the saved streak so the streak
      // continues rather than restarting at 1. The fetch may already
      // include its saved session; don't count that twice.
      final local = state.workouts;
      var streak = snap.streak;
      for (final w in local) {
        streak = streakAfterWorkout(streak, w.completedAt);
      }
      state = DailyState(
        workouts: [
          ...snap.workouts.where((w) => !local.any((l) => l.completedAt == w.completedAt)),
          ...local,
        ],
        streak: streak,
        servedQuestionIds: state.servedQuestionIds,
      );
      _streakLoaded = true;
      if (!identical(streak, snap.streak)) _saveStreak(streak);
    } catch (e) {
      debugPrint('Could not load daily progress: $e');
    }
  }

  void _saveStreak(StreakRecord streak) =>
      _repo?.saveStreak(streak).catchError((Object e) => debugPrint('Could not save streak: $e'));

  void recordWorkout({
    required List<String> questionIds,
    required int correct,
    required int total,
    required bool keepGoing,
    required DateTime startedAt,
  }) {
    final now = clock();
    final record = WorkoutRecord(completedAt: now, correct: correct, total: total, keepGoing: keepGoing);
    final streak = streakAfterWorkout(state.streak, now);
    state = DailyState(
      workouts: [...state.workouts, record],
      streak: streak,
      servedQuestionIds: {...state.servedQuestionIds, ...questionIds},
    );
    _repo?.recordWorkout(record, startedAt: startedAt).catchError((Object e) => debugPrint('Could not save workout: $e'));
    // Before the saved streak has loaded, this one was counted from zero:
    // saving it could wipe a real streak. Load it (again, if the first load
    // failed); _hydrate replays this workout onto it and saves the result.
    if (_streakLoaded) {
      _saveStreak(streak);
    } else if (_repo != null) {
      _load();
    }
  }
}

final dailyProvider = NotifierProvider<DailyNotifier, DailyState>(DailyNotifier.new);

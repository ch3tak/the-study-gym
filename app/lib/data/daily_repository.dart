import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'daily_state.dart';

/// Reads/writes workouts (`sessions` rows of kind `workout`) and the
/// `streaks` row. Both tables and their own-rows RLS policies already exist
/// (20260926000000_core_schema.sql).
class DailyRepository {
  DailyRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in user — cannot read/write daily progress.');
    return id;
  }

  Future<DailySnapshot> fetch({int days = 14}) async {
    final userId = _userId;
    final since = DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();
    final sessionRows = await _client
        .from('sessions')
        .select('completed_at, score, meta')
        .eq('user_id', userId)
        .eq('kind', 'workout')
        .not('completed_at', 'is', null)
        .gte('completed_at', since);
    final streakRow = await _client
        .from('streaks')
        .select('current, longest, last_active_date')
        .eq('user_id', userId)
        .maybeSingle();

    final workouts = <WorkoutRecord>[
      for (final r in sessionRows as List)
        WorkoutRecord(
          completedAt: DateTime.parse(r['completed_at'] as String).toLocal(),
          correct: (r['score'] as num?)?.round() ?? 0,
          total: ((r['meta'] as Map?)?['total'] as num?)?.round() ?? 0,
          keepGoing: (r['meta'] as Map?)?['keep_going'] == true,
        ),
    ];
    final last = streakRow?['last_active_date'] as String?;
    return DailySnapshot(
      workouts: workouts,
      streak: StreakRecord(
        current: streakRow?['current'] as int? ?? 0,
        longest: streakRow?['longest'] as int? ?? 0,
        lastActiveDate: last == null ? null : DateTime.parse(last),
      ),
    );
  }

  Future<void> recordWorkout(WorkoutRecord workout, {required DateTime startedAt}) async {
    await _client.from('sessions').insert({
      'id': _uuid.v4(),
      'user_id': _userId,
      'kind': 'workout',
      'started_at': startedAt.toUtc().toIso8601String(),
      'completed_at': workout.completedAt.toUtc().toIso8601String(),
      'score': workout.correct,
      'meta': {'total': workout.total, 'keep_going': workout.keepGoing},
    });
  }

  Future<void> saveStreak(StreakRecord streak) async {
    await _client.from('streaks').upsert({
      'user_id': _userId,
      'current': streak.current,
      'longest': streak.longest,
      if (streak.lastActiveDate != null) 'last_active_date': isoDate(streak.lastActiveDate!),
    });
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

/// Reads/writes the per-student tables from docs/PLAN.md §6:
/// `concept_mastery`, `streaks`, `attempts`, `sessions`. RLS scopes every
/// row to `auth.uid()`, so all calls here run as the signed-in user
/// (anonymous or real — see main.dart).
class StudentRepository {
  StudentRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in user — cannot read/write student data.');
    return id;
  }

  Future<StudentSnapshot> fetchAll() async {
    final userId = _userId;

    final masteryRows = await _client
        .from('concept_mastery')
        .select('concept_id, theta, attempts, correct')
        .eq('user_id', userId);

    final streakRows = await _client
        .from('streaks')
        .select('current, longest')
        .eq('user_id', userId)
        .maybeSingle();

    final mastery = <String, ConceptMastery>{};
    for (final row in masteryRows as List) {
      final percent = ((row['theta'] as num?) ?? 0).toDouble().clamp(0.0, 100.0);
      mastery[row['concept_id'] as String] = ConceptMastery(
        conceptId: row['concept_id'] as String,
        masteryPercent: percent,
        attempts: row['attempts'] as int? ?? 0,
        correct: row['correct'] as int? ?? 0,
        state: _stateFor(percent),
      );
    }

    return StudentSnapshot(
      mastery: mastery,
      streak: streakRows?['current'] as int? ?? 0,
    );
  }

  static MasteryState _stateFor(double percent) {
    if (percent >= 80) return MasteryState.mastered;
    if (percent >= 50) return MasteryState.practising;
    if (percent > 0) return MasteryState.learning;
    return MasteryState.notStarted;
  }

  /// Upserts one concept's mastery row and appends the append-only attempt
  /// record. `newPercent`/`newState` are computed client-side by the mastery
  /// engine (see `app_state.dart`) — this just persists the result.
  Future<void> recordAttempt({
    required String questionId,
    required String conceptId,
    required bool correct,
    required int hintsUsed,
    required double newMasteryPercent,
    required int newAttempts,
    required int newCorrect,
  }) async {
    final userId = _userId;

    await _client.from('attempts').insert({
      'id': _uuid.v4(),
      'user_id': userId,
      'question_id': questionId,
      'answer': {}, // the raw answer isn't modeled client-side yet
      'outcome': correct ? 1.0 : 0.0,
      'hints_used': hintsUsed,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _client.from('concept_mastery').upsert({
      'user_id': userId,
      'concept_id': conceptId,
      'theta': newMasteryPercent,
      'attempts': newAttempts,
      'correct': newCorrect,
      'last_practiced': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> setStreak(int current, {int? longest}) async {
    await _client.from('streaks').upsert({
      'user_id': _userId,
      'current': current,
      if (longest != null) 'longest': longest,
      'last_active_date': DateTime.now().toUtc().toIso8601String().split('T').first,
    });
  }
}

class StudentSnapshot {
  const StudentSnapshot({required this.mastery, required this.streak});

  final Map<String, ConceptMastery> mastery;
  final int streak;
}

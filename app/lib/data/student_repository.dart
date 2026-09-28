import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

/// Reads/writes the per-student tables from docs/PLAN.md §6:
/// `concept_mastery` and `attempts` (workouts and the streak are in
/// daily_repository.dart). RLS scopes every
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
        .select('concept_id, theta, attempts, correct, last_practiced, half_life_days')
        .eq('user_id', userId);

    final mastery = <String, ConceptMastery>{};
    for (final row in masteryRows as List) {
      final percent = ((row['theta'] as num?) ?? 0).toDouble().clamp(0.0, 100.0);
      mastery[row['concept_id'] as String] = ConceptMastery(
        conceptId: row['concept_id'] as String,
        masteryPercent: percent,
        attempts: row['attempts'] as int? ?? 0,
        correct: row['correct'] as int? ?? 0,
        state: _stateFor(percent),
        lastPracticed: row['last_practiced'] == null ? null : DateTime.parse(row['last_practiced'] as String).toLocal(),
        halfLifeDays: (row['half_life_days'] as num?)?.toDouble() ?? 2,
      );
    }

    return StudentSnapshot(mastery: mastery);
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
}

class StudentSnapshot {
  const StudentSnapshot({required this.mastery});

  final Map<String, ConceptMastery> mastery;
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'mission_state.dart';

/// Reads/writes the per-student `level_progress` table. RLS scopes every
/// row to `auth.uid()` — mirrors `StudentRepository`'s shape exactly.
class LevelProgressRepository {
  LevelProgressRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No signed-in user — cannot read/write level progress.');
    }
    return id;
  }

  /// Every completed level per chapter, with its result.
  Future<Map<String, Map<int, LevelResult>>> fetchAll() async {
    final userId = _userId;
    List rows;
    try {
      rows = await _client
          .from('level_progress')
          .select('chapter_id, level, score, solution_viewed')
          .eq('user_id', userId) as List;
    } on PostgrestException {
      // A database without 20261001000000 has no solution_viewed column.
      rows = await _client.from('level_progress').select('chapter_id, level, score').eq('user_id', userId) as List;
    }
    final result = <String, Map<int, LevelResult>>{};
    for (final row in rows) {
      result.putIfAbsent(row['chapter_id'] as String, () => {})[row['level'] as int] = LevelResult(
        score: (row['score'] as num?)?.toDouble() ?? 0,
        solutionViewed: row['solution_viewed'] as bool? ?? false,
      );
    }
    return result;
  }

  /// Inserts the level's first completion; a replay leaves the row as is.
  Future<void> completeLevel({
    required String chapterId,
    required int level,
    required double score,
    bool solutionViewed = false,
  }) async {
    final row = <String, dynamic>{
      'user_id': _userId,
      'chapter_id': chapterId,
      'level': level,
      'score': score,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'solution_viewed': solutionViewed,
    };
    try {
      await _client.from('level_progress').upsert(row, onConflict: 'user_id,chapter_id,level', ignoreDuplicates: true);
    } on PostgrestException {
      // A database without 20261001000000: save the completion without the new column.
      row.remove('solution_viewed');
      await _client.from('level_progress').upsert(row, onConflict: 'user_id,chapter_id,level', ignoreDuplicates: true);
    }
  }
}

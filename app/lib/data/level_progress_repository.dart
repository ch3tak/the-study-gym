import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Returns every completed level number per chapter, for the signed-in user.
  Future<Map<String, Set<int>>> fetchAll() async {
    final userId = _userId;
    final rows = await _client
        .from('level_progress')
        .select('chapter_id, level')
        .eq('user_id', userId);

    final result = <String, Set<int>>{};
    for (final row in rows as List) {
      final chapterId = row['chapter_id'] as String;
      final level = row['level'] as int;
      result.putIfAbsent(chapterId, () => {}).add(level);
    }
    return result;
  }

  Future<void> completeLevel({
    required String chapterId,
    required int level,
    required double score,
  }) async {
    await _client.from('level_progress').upsert({
      'user_id': _userId,
      'chapter_id': chapterId,
      'level': level,
      'score': score,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

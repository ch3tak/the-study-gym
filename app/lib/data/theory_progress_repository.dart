import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes the per-student `theory_progress` table. RLS scopes every
/// row to `auth.uid()` — same shape as `LevelProgressRepository`.
class TheoryProgressRepository {
  TheoryProgressRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No signed-in user — cannot read/write theory progress.');
    }
    return id;
  }

  /// Ids of every lesson the signed-in user has marked read.
  Future<Set<String>> fetchAll() async {
    final rows = await _client.from('theory_progress').select('lesson_id').eq('user_id', _userId);
    return {for (final row in rows as List) row['lesson_id'] as String};
  }

  Future<void> markRead(String lessonId) async {
    await _client.from('theory_progress').upsert({
      'user_id': _userId,
      'lesson_id': lessonId,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

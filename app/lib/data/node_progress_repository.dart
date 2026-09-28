import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Reads/writes `node_progress` (20261001000000_units_nodes_trial_meta.sql).
class NodeProgressRepository {
  NodeProgressRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in user — cannot read/write node progress.');
    return id;
  }

  Future<Map<String, Set<TopicNode>>> fetchAll() async {
    final rows = await _client.from('node_progress').select('concept_id, node').eq('user_id', _userId);
    final result = <String, Set<TopicNode>>{};
    for (final row in rows as List) {
      final node = TopicNode.fromDb(row['node']);
      if (node == null) continue;
      result.putIfAbsent(row['concept_id'] as String, () => {}).add(node);
    }
    return result;
  }

  Future<void> passNode(String conceptId, TopicNode node) async {
    await _client.from('node_progress').upsert({'user_id': _userId, 'concept_id': conceptId, 'node': node.dbValue});
  }
}

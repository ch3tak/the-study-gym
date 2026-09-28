import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'node_progress_repository.dart';

/// Which topic question nodes the student has passed.
class NodeProgressState {
  const NodeProgressState({this.passed = const {}});

  /// Concept id → the nodes passed in that topic.
  final Map<String, Set<TopicNode>> passed;

  bool isPassed(String conceptId, TopicNode node) => passed[conceptId]?.contains(node) ?? false;
}

class NodeProgressNotifier extends Notifier<NodeProgressState> {
  /// Set by main.dart; null in tests that don't need persistence.
  static NodeProgressRepository? repositoryOverride;

  NodeProgressRepository? get _repo => repositoryOverride;

  @override
  NodeProgressState build() {
    if (_repo != null) _hydrate();
    return const NodeProgressState();
  }

  Future<void> _hydrate() async {
    try {
      final fetched = await _repo!.fetchAll();
      // Merge, don't replace: a node passed while this fetch was in flight
      // must stay passed.
      final merged = {for (final e in fetched.entries) e.key: {...e.value}};
      for (final e in state.passed.entries) {
        merged.putIfAbsent(e.key, () => {}).addAll(e.value);
      }
      state = NodeProgressState(passed: merged);
    } catch (e) {
      // Also covers a database without node_progress yet.
      debugPrint('Could not load node progress: $e');
    }
  }

  void passNode(String conceptId, TopicNode node) {
    if (state.isPassed(conceptId, node)) return;
    state = NodeProgressState(passed: {
      ...state.passed,
      conceptId: {...?state.passed[conceptId], node},
    });
    _repo?.passNode(conceptId, node).catchError((Object e) => debugPrint('Could not save node progress: $e'));
  }
}

final nodeProgressProvider = NotifierProvider<NodeProgressNotifier, NodeProgressState>(NodeProgressNotifier.new);

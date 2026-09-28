import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'level_progress_repository.dart';

/// One completed Trial level: right first time (score 1.0) or not, and
/// whether a solution was opened (both needed for Platinum).
class LevelResult {
  const LevelResult({required this.score, this.solutionViewed = false});
  final double score;
  final bool solutionViewed;
}

class LevelProgressState {
  const LevelProgressState({this.completedLevels = const {}, this.results = const {}});

  final Map<String, Set<int>> completedLevels;

  /// Per-level results, for trophies. The first completion stands.
  final Map<String, Map<int, LevelResult>> results;

  LevelResult? resultFor(String chapterId, int level) => results[chapterId]?[level];

  bool isCompleted(String chapterId, int level) =>
      completedLevels[chapterId]?.contains(level) ?? false;

  /// Whether a level is playable, given the level that comes immediately
  /// before it in the list of levels the app actually loaded for [chapterId].
  ///
  /// Unlocking is positional, not arithmetic: the loaded list can have gaps
  /// (only `status = 'live'` questions reach the client, so an unverified
  /// level 1 or level 4 is simply absent). The first loaded level
  /// ([previousLevelInList] == null) is always unlocked; every other level
  /// is unlocked iff its predecessor *in that list* is in the completed set.
  /// Completion is never assumed contiguous — a completed level 10 does not
  /// unlock anything except the level that directly follows 10 in the list.
  ///
  /// This class deliberately has no view of what content loaded, so the
  /// caller (MissionScreen, which owns the sorted list) supplies the
  /// predecessor.
  bool isUnlocked(String chapterId, {required int? previousLevelInList}) {
    if (previousLevelInList == null) return true;
    return isCompleted(chapterId, previousLevelInList);
  }

  LevelProgressState copyWith({
    Map<String, Set<int>>? completedLevels,
    Map<String, Map<int, LevelResult>>? results,
  }) {
    return LevelProgressState(
      completedLevels: completedLevels ?? this.completedLevels,
      results: results ?? this.results,
    );
  }
}

class LevelProgressNotifier extends Notifier<LevelProgressState> {
  static LevelProgressRepository? repositoryOverride;

  LevelProgressRepository? get _repo => repositoryOverride;

  @override
  LevelProgressState build() {
    if (_repo != null) {
      _hydrate();
    }
    return const LevelProgressState();
  }

  Future<void> _hydrate() async {
    final snapshot = await _repo!.fetchAll();
    state = state.copyWith(
      completedLevels: {for (final e in snapshot.entries) e.key: e.value.keys.toSet()},
      results: snapshot,
    );
  }

  /// Marks a level complete. The first completion's result stands: a replay
  /// can't turn a right-first-time level into a wrong one, or the reverse.
  void completeLevel({
    required String chapterId,
    required int level,
    required double score,
    bool solutionViewed = false,
  }) {
    if (state.isCompleted(chapterId, level)) return;
    final result = LevelResult(score: score, solutionViewed: solutionViewed);
    state = state.copyWith(
      completedLevels: {
        ...state.completedLevels,
        chapterId: {...?state.completedLevels[chapterId], level},
      },
      results: {
        ...state.results,
        chapterId: {...?state.results[chapterId], level: result},
      },
    );
    _repo
        ?.completeLevel(chapterId: chapterId, level: level, score: score, solutionViewed: solutionViewed)
        .catchError((_) {});
  }
}

final levelProgressProvider = NotifierProvider<LevelProgressNotifier, LevelProgressState>(
  LevelProgressNotifier.new,
);

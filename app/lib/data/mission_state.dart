import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'level_progress_repository.dart';

class LevelProgressState {
  const LevelProgressState({this.completedLevels = const {}});

  final Map<String, Set<int>> completedLevels;

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

  LevelProgressState copyWith({Map<String, Set<int>>? completedLevels}) {
    return LevelProgressState(completedLevels: completedLevels ?? this.completedLevels);
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
    state = state.copyWith(completedLevels: snapshot);
  }

  void completeLevel({
    required String chapterId,
    required int level,
    required double score,
  }) {
    final updated = Map<String, Set<int>>.from(state.completedLevels);
    updated[chapterId] = {...(updated[chapterId] ?? {}), level};
    state = state.copyWith(completedLevels: updated);

    _repo
        ?.completeLevel(chapterId: chapterId, level: level, score: score)
        .catchError((_) {});
  }
}

final levelProgressProvider = NotifierProvider<LevelProgressNotifier, LevelProgressState>(
  LevelProgressNotifier.new,
);

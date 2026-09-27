import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'level_progress_repository.dart';

class LevelProgressState {
  const LevelProgressState({this.completedLevels = const {}});

  final Map<String, Set<int>> completedLevels;

  bool isCompleted(String chapterId, int level) =>
      completedLevels[chapterId]?.contains(level) ?? false;

  /// Level 1 is always unlocked. Level N (N > 1) is unlocked iff level N-1
  /// is in the completed set — completion is never assumed contiguous, so a
  /// completed level 10 with no level 3 row does not unlock level 3.
  bool isUnlocked(String chapterId, int level) {
    if (level <= 1) return true;
    return completedLevels[chapterId]?.contains(level - 1) ?? false;
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

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content.dart';
import 'theory_progress_repository.dart';

/// Which theory lessons the student has read — mirrors `theory_progress`.
class TheoryProgressState {
  const TheoryProgressState({this.readLessonIds = const {}});

  final Set<String> readLessonIds;

  bool isRead(String lessonId) => readLessonIds.contains(lessonId);

  int readCountForChapter(String chapterId) =>
      Content.lessonsForChapter(chapterId).where((l) => isRead(l.id)).length;
}

class TheoryProgressNotifier extends Notifier<TheoryProgressState> {
  /// Set by `main.dart`; null in tests that don't need persistence.
  static TheoryProgressRepository? repositoryOverride;

  TheoryProgressRepository? get _repo => repositoryOverride;

  @override
  TheoryProgressState build() {
    if (_repo != null) _hydrate();
    return const TheoryProgressState();
  }

  Future<void> _hydrate() async {
    try {
      final fetched = await _repo!.fetchAll();
      // Merge, don't replace: a lesson marked read while this fetch was in
      // flight must stay read.
      state = TheoryProgressState(readLessonIds: {...fetched, ...state.readLessonIds});
    } catch (e) {
      debugPrint('Could not load theory progress: $e');
    }
  }

  /// Writes first, then updates state, so a failed write (e.g. offline)
  /// throws to the caller and the lesson stays unread. No-op if already read.
  Future<void> markRead(String lessonId) async {
    if (state.isRead(lessonId)) return;
    await _repo?.markRead(lessonId);
    state = TheoryProgressState(readLessonIds: {...state.readLessonIds, lessonId});
  }
}

final theoryProgressProvider = NotifierProvider<TheoryProgressNotifier, TheoryProgressState>(
  TheoryProgressNotifier.new,
);

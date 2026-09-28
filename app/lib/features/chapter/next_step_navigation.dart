import 'package:flutter/material.dart';

import '../../data/chapter_progress.dart';
import '../theory/lesson_screen.dart';
import '../workout/workout_screen.dart';
import 'chapter_screen.dart';

/// Opens exactly what comes next (spec: "a Continue button that opens the
/// next node directly"). Only when nothing specific can be opened does it
/// fall back to the chapter screen.
void openNextStep(BuildContext context, ChapterProgress chapter, NextStep step) {
  final Widget page = switch (step) {
    LessonStep(:final lesson) => LessonScreen(lesson: lesson),
    NodeStep(:final concept, :final node) => WorkoutScreen.node(concept: concept, node: node),
    TrialLevelStep(:final level) => WorkoutScreen.singleLevel(level),
    OpenChapterStep() => ChapterScreen(chapterId: chapter.chapter.id),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

/// "Topic N of M" or "Trial level N of M".
String nextStepPosition(ChapterProgress chapter, NextStep step) => switch (step) {
      TrialLevelStep(:final number, :final total) => 'Trial level $number of $total',
      LessonStep(:final topicNumber) || NodeStep(:final topicNumber) => 'Topic $topicNumber of ${chapter.topics.length}',
      OpenChapterStep() => chapter.topics.isEmpty ? '' : 'Topic ${chapter.currentTopicNumber ?? 1} of ${chapter.topics.length}',
    };

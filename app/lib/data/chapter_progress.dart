import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content.dart';
import 'mission_state.dart';
import 'models.dart';
import 'node_progress_state.dart';
import 'theory_state.dart';

// Everything here is derived from Content and the progress stores, never
// stored (spec: "Avoid storing derived progress redundantly").

enum TopicStatus { done, current, locked }

enum NodeStatus { passed, open, locked, comingSoon }

enum ChapterStatus { soon, notStarted, inProgress, complete }

class NodeSlot {
  const NodeSlot({required this.node, required this.questionCount, required this.status});
  final TopicNode node;
  final int questionCount;
  final NodeStatus status;
}

class TopicProgress {
  const TopicProgress({
    required this.concept,
    required this.lesson,
    required this.lessonRead,
    required this.nodes,
    required this.usesInterimRule,
    required this.status,
  });

  final Concept concept;

  /// The Learn node's lesson; null shows "Lesson coming soon".
  final Lesson? lesson;
  final bool lessonRead;

  /// Always the four question nodes in path order. Nodes without questions
  /// are [NodeStatus.comingSoon] and never gate the next node.
  final List<NodeSlot> nodes;

  /// No topic questions yet, so the topic is finished once its lesson is
  /// read. Switches off by itself when tagged questions arrive.
  final bool usesInterimRule;
  final TopicStatus status;

  bool get isDone => status == TopicStatus.done;

  /// Question nodes that have questions.
  int get nodeCount => nodes.where((n) => n.questionCount > 0).length;
  int get nodesPassed => nodes.where((n) => n.status == NodeStatus.passed).length;
}

/// Where Home's Continue goes.
sealed class NextStep {
  const NextStep();
}

class LessonStep extends NextStep {
  const LessonStep(this.lesson, this.topicNumber);
  final Lesson lesson;
  final int topicNumber;
}

class NodeStep extends NextStep {
  const NodeStep(this.concept, this.node, this.topicNumber);
  final Concept concept;
  final TopicNode node;
  final int topicNumber;
}

class TrialLevelStep extends NextStep {
  const TrialLevelStep(this.level, this.number, this.total);
  final Question level;

  /// 1-based position among the loaded levels, and how many loaded.
  final int number;
  final int total;
}

/// Nothing more specific can be opened (e.g. a topic with no lesson yet).
class OpenChapterStep extends NextStep {
  const OpenChapterStep();
}

class ChapterProgress {
  const ChapterProgress({
    required this.chapter,
    required this.topics,
    required this.trialLevels,
    required this.levelsCleared,
    required this.hasContent,
    required this.levels,
  });

  final Chapter chapter;
  final List<TopicProgress> topics;

  /// The Chapter Trial's levels as loaded (live only: possibly fewer than 62).
  final List<Question> trialLevels;
  final int levelsCleared;
  final bool hasContent;
  final LevelProgressState levels;

  int get topicsDone => topics.where((t) => t.isDone).length;
  bool get allTopicsDone => topics.isNotEmpty && topics.every((t) => t.isDone);

  /// The gate opens only when every topic's seal is broken.
  bool get trialUnlocked => trialLevels.isNotEmpty && allTopicsDone;

  int? get currentTopicNumber {
    final i = topics.indexWhere((t) => t.status == TopicStatus.current);
    return i < 0 ? null : i + 1;
  }

  ChapterStatus get status {
    if (!hasContent) return ChapterStatus.soon;
    final trialDone = trialLevels.isEmpty || levelsCleared == trialLevels.length;
    if (allTopicsDone && trialDone) return ChapterStatus.complete;
    final started = levelsCleared > 0 || topics.any((t) => t.isDone || t.lessonRead || t.nodesPassed > 0);
    return started ? ChapterStatus.inProgress : ChapterStatus.notStarted;
  }

  bool get isStarted => status == ChapterStatus.inProgress || status == ChapterStatus.complete;

  /// Topics and the Trial count half each when there is a Trial.
  double get fraction {
    if (topics.isEmpty) return 0;
    final topicPart = topicsDone / topics.length;
    if (trialLevels.isEmpty) return topicPart;
    return 0.5 * topicPart + 0.5 * levelsCleared / trialLevels.length;
  }

  NextStep get nextStep {
    final i = topics.indexWhere((t) => t.status == TopicStatus.current);
    if (i >= 0) {
      final t = topics[i];
      if (t.lesson != null && !t.lessonRead) return LessonStep(t.lesson!, i + 1);
      for (final slot in t.nodes) {
        if (slot.status == NodeStatus.open) return NodeStep(t.concept, slot.node, i + 1);
      }
      return const OpenChapterStep();
    }
    if (trialUnlocked) {
      for (var j = 0; j < trialLevels.length; j++) {
        final unlocked = levels.isUnlocked(chapter.id, previousLevelInList: j == 0 ? null : trialLevels[j - 1].level);
        if (unlocked && !levels.isCompleted(chapter.id, trialLevels[j].level!)) {
          return TrialLevelStep(trialLevels[j], j + 1, trialLevels.length);
        }
      }
    }
    return const OpenChapterStep();
  }
}

ChapterProgress chapterProgress(
  Chapter chapter, {
  required TheoryProgressState theory,
  required NodeProgressState nodes,
  required LevelProgressState levels,
}) {
  final topics = <TopicProgress>[];
  var allBeforeDone = true;
  for (final concept in chapter.concepts) {
    final lesson = Content.lessonForConcept(concept.id);
    final lessonRead = lesson != null && theory.isRead(lesson.id);
    final interim = !Content.hasTopicQuestions(concept.id);
    final unlocked = allBeforeDone;

    final slots = <NodeSlot>[];
    // The Learn node gates the first question node; with no lesson there
    // is nothing to wait for.
    var previousPassed = lesson == null || lessonRead;
    for (final node in TopicNode.values) {
      final count = interim ? 0 : Content.nodeQuestions(concept.id, node).length;
      final NodeStatus status;
      if (count == 0) {
        status = NodeStatus.comingSoon;
      } else if (nodes.isPassed(concept.id, node)) {
        status = NodeStatus.passed;
      } else if (unlocked && previousPassed) {
        status = NodeStatus.open;
      } else {
        status = NodeStatus.locked;
      }
      if (count > 0) previousPassed = status == NodeStatus.passed;
      slots.add(NodeSlot(node: node, questionCount: count, status: status));
    }

    final finished = interim
        ? lessonRead
        : (lesson == null || lessonRead) &&
            slots.where((s) => s.questionCount > 0).every((s) => s.status == NodeStatus.passed);
    topics.add(TopicProgress(
      concept: concept,
      lesson: lesson,
      lessonRead: lessonRead,
      nodes: slots,
      usesInterimRule: interim,
      status: finished ? TopicStatus.done : (unlocked ? TopicStatus.current : TopicStatus.locked),
    ));
    allBeforeDone = allBeforeDone && finished;
  }

  final trialLevels = Content.trialLevels(chapter.id);
  return ChapterProgress(
    chapter: chapter,
    topics: topics,
    trialLevels: trialLevels,
    levelsCleared: trialLevels.where((q) => levels.isCompleted(chapter.id, q.level!)).length,
    hasContent: Content.hasContent(chapter.id),
    levels: levels,
  );
}

class CourseProgress {
  const CourseProgress(this.chapters);

  /// Every chapter of the active course, in syllabus order.
  final List<ChapterProgress> chapters;

  ChapterProgress? chapter(String id) {
    for (final c in chapters) {
      if (c.chapter.id == id) return c;
    }
    return null;
  }

  int get chaptersStarted => chapters.where((c) => c.isStarted).length;
  int get levelsCleared => chapters.fold(0, (sum, c) => sum + c.levelsCleared);
  bool get anyStarted => chaptersStarted > 0;
  double get fraction => chapters.isEmpty ? 0 : chapters.fold<double>(0, (s, c) => s + c.fraction) / chapters.length;

  /// Pinned on Learn and continued from Home: the first chapter in
  /// progress, else the first one that can start. Null when nothing has content.
  ChapterProgress? get current =>
      chapters.where((c) => c.status == ChapterStatus.inProgress).firstOrNull ??
      chapters.where((c) => c.status == ChapterStatus.notStarted).firstOrNull;

  /// "1 of 15 chapters started · 13 levels cleared"
  String get summary {
    final n = levelsCleared;
    return '$chaptersStarted of ${chapters.length} chapters started · $n ${n == 1 ? 'level' : 'levels'} cleared';
  }
}

CourseProgress courseProgress({
  required TheoryProgressState theory,
  required NodeProgressState nodes,
  required LevelProgressState levels,
}) =>
    CourseProgress([
      for (final c in Content.chapters) chapterProgress(c, theory: theory, nodes: nodes, levels: levels),
    ]);

final courseProgressProvider = Provider<CourseProgress>((ref) => courseProgress(
      theory: ref.watch(theoryProgressProvider),
      nodes: ref.watch(nodeProgressProvider),
      levels: ref.watch(levelProgressProvider),
    ));

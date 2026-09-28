import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/chapter_progress.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/node_progress_state.dart';
import 'package:study_gym/data/theory_state.dart';

import '../fixtures/slice1_content.dart';

CourseProgress _course({
  Set<String> read = const {},
  Map<String, Set<TopicNode>> passed = const {},
  Map<String, Set<int>> levels = const {},
}) =>
    courseProgress(
      theory: TheoryProgressState(readLessonIds: read),
      nodes: NodeProgressState(passed: passed),
      levels: LevelProgressState(completedLevels: levels),
    );

ChapterProgress _ch(String id, {Set<String> read = const {}, Map<String, Set<TopicNode>> passed = const {}, Map<String, Set<int>> levels = const {}}) =>
    _course(read: read, passed: passed, levels: levels).chapter(id)!;

List<TopicStatus> _statuses(ChapterProgress p) => p.topics.map((t) => t.status).toList();

void main() {
  setUp(loadSlice1Content);

  group('topics', () {
    test('topics come in syllabus order; the first is current, the rest locked', () {
      final p = _ch(savChapter);
      expect(p.topics.map((t) => t.concept.id), ['c.cube', 'c.cyl', 'c.cone']);
      expect(_statuses(p), [TopicStatus.current, TopicStatus.locked, TopicStatus.locked]);
    });

    test('interim rule: a topic with no topic questions is finished when its lesson is read', () {
      final p = _ch(savChapter, read: {'t_cube'});
      expect(p.topics.first.usesInterimRule, isTrue);
      expect(_statuses(p), [TopicStatus.done, TopicStatus.current, TopicStatus.locked]);
      expect(p.topics.first.nodes.every((n) => n.status == NodeStatus.comingSoon), isTrue);
    });

    test('a topic with topic questions does NOT finish on lesson read', () {
      final p = _ch(idenChapter, read: {'t_iden'});
      final t = p.topics.single;
      expect(t.usesInterimRule, isFalse);
      expect(t.status, TopicStatus.current);
    });

    test('question nodes open one after another; nodes without questions are skipped', () {
      NodeStatus s(ChapterProgress p, TopicNode n) => p.topics.single.nodes.firstWhere((x) => x.node == n).status;

      var p = _ch(idenChapter);
      expect(s(p, TopicNode.guided), NodeStatus.locked, reason: 'Learn comes first');

      p = _ch(idenChapter, read: {'t_iden'});
      expect(s(p, TopicNode.guided), NodeStatus.open);
      expect(s(p, TopicNode.practice), NodeStatus.comingSoon);
      expect(s(p, TopicNode.spotTheMistake), NodeStatus.comingSoon);
      expect(s(p, TopicNode.challenge), NodeStatus.locked);

      p = _ch(idenChapter, read: {'t_iden'}, passed: {'c.iden': {TopicNode.guided}});
      expect(s(p, TopicNode.challenge), NodeStatus.open);

      p = _ch(idenChapter, read: {'t_iden'}, passed: {'c.iden': {TopicNode.guided, TopicNode.challenge}});
      expect(p.topics.single.status, TopicStatus.done);
      expect(p.topics.single.nodesPassed, 2);
      expect(p.topics.single.nodeCount, 2);
    });

    test('lessons read out of order never make two current topics', () {
      final p = _ch(savChapter, read: {'t_cyl'});
      expect(_statuses(p), [TopicStatus.current, TopicStatus.done, TopicStatus.locked]);
    });
  });

  group('Trial gate', () {
    test('stays locked while any topic is unfinished', () {
      expect(_ch(savChapter, read: {'t_cube', 't_cyl'}).trialUnlocked, isFalse);
    });

    test('opens when every seal is broken', () {
      expect(_ch(savChapter, read: {'t_cube', 't_cyl', 't_cone'}).trialUnlocked, isTrue);
    });

    test('old Mission progress is kept behind a locked gate', () {
      final course = _course(levels: {savChapter: {1, 2, 3}});
      final p = course.chapter(savChapter)!;
      expect(p.trialUnlocked, isFalse);
      expect(p.levelsCleared, 3);
      expect(p.status, ChapterStatus.inProgress);
      expect(course.levelsCleared, 3);
    });
  });

  group('chapter status and fraction', () {
    test('soon, not started, in progress, complete', () {
      expect(_ch(triChapter).status, ChapterStatus.soon);
      expect(_ch(seqChapter).status, ChapterStatus.notStarted);
      expect(_ch(savChapter, read: {'t_cube'}).status, ChapterStatus.inProgress);
      final all = {for (var l = 1; l <= 10; l++) l};
      expect(_ch(savChapter, read: {'t_cube', 't_cyl', 't_cone'}, levels: {savChapter: all}).status, ChapterStatus.complete);
    });

    test('topics and the Trial count half each', () {
      final p = _ch(savChapter, read: {'t_cube', 't_cyl', 't_cone'}, levels: {savChapter: {1, 2, 3, 4, 5}});
      expect(p.fraction, closeTo(0.5 + 0.25, 1e-9));
    });
  });

  group('next step', () {
    test('the current topic\'s lesson, then its first open node', () {
      var step = _ch(savChapter, read: {'t_cube'}).nextStep;
      expect(step, isA<LessonStep>());
      expect((step as LessonStep).lesson.id, 't_cyl');
      expect(step.topicNumber, 2);

      step = _ch(idenChapter, read: {'t_iden'}).nextStep;
      expect(step, isA<NodeStep>());
      expect((step as NodeStep).node, TopicNode.guided);
    });

    test('after every topic, the next unlocked Trial level', () {
      final step = _ch(savChapter, read: {'t_cube', 't_cyl', 't_cone'}, levels: {savChapter: {1, 2}}).nextStep;
      expect(step, isA<TrialLevelStep>());
      step as TrialLevelStep;
      expect(step.level.level, 3);
      expect(step.number, 3);
      expect(step.total, 10);
    });

    test('a topic with no lesson and no questions falls back to opening the chapter', () {
      expect(_ch(seqChapter).nextStep, isA<OpenChapterStep>());
    });
  });

  group('course', () {
    test('summary line counts started chapters and cleared levels', () {
      final course = _course(read: {'t_cube'}, levels: {savChapter: {1}});
      expect(course.chaptersStarted, 1);
      expect(course.summary, '1 of 4 chapters started · 1 level cleared');
    });

    test('current chapter: first in progress, else the first that can start', () {
      expect(_course().current!.chapter.id, seqChapter);
      expect(_course(read: {'t_cube'}).current!.chapter.id, savChapter);
    });
  });
}

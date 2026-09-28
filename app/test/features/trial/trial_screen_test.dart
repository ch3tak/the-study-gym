import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/trial/trial_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

Finder _node(int level) => find.byKey(ValueKey('trial_node_$level'));
bool _locked(int level) =>
    find.descendant(of: _node(level), matching: find.byIcon(Icons.lock_rounded)).evaluate().isNotEmpty;

Future<ProviderContainer> _openTrial(WidgetTester tester, {Set<int> done = const {}, Brightness? theme, bool readAll = true}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (readAll) {
    for (final id in ['t_cube', 't_cyl', 't_cone']) {
      await container.read(theoryProgressProvider.notifier).markRead(id);
    }
  }
  for (final l in done) {
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: l, score: 1);
  }
  await pumpScreen(tester, const TrialScreen(chapterId: savChapter), container: container, theme: theme);
  return container;
}

void main() {
  setUp(loadSlice1Content);

  for (final t in themes.entries) {
    testWidgets('fresh Trial: Foundation open, the other four stages folded in order (${t.key})', (tester) async {
      await _openTrial(tester, theme: t.value);
      expect(find.byKey(const ValueKey('trial_stage_FOUNDATION_current')), findsOneWidget);
      expect(_locked(1), isFalse);
      expect(_locked(2), isTrue);
      expect(find.byKey(const ValueKey('trial_checkpoint_2')), findsOneWidget, reason: 'last level of a stage');

      final futures = ['GUIDED_PRACTICE', 'SKILL_BUILDING', 'APPLICATION', 'MASTERY']
          .map((s) => tester.getTopLeft(find.byKey(ValueKey('trial_stage_${s}_future'))).dy)
          .toList();
      expect(futures, [...futures]..sort(), reason: 'stages keep their order');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a finished stage folds to one line and the next opens', (tester) async {
    await _openTrial(tester, done: {1, 2});
    expect(find.byKey(const ValueKey('trial_stage_FOUNDATION_folded')), findsOneWidget);
    expect(find.text('Foundation · 2 / 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('trial_stage_GUIDED_PRACTICE_current')), findsOneWidget);
    expect(_locked(3), isFalse);
    expect(_locked(4), isTrue);
  });

  testWidgets('tapping a level opens its preview; Start level launches it', (tester) async {
    await _openTrial(tester);
    await tester.tap(_node(1));
    await tester.pumpAndSettle();

    expect(find.text('Level 1 of 10 · Foundation'), findsOneWidget);
    expect(find.text('Cuboids and cubes'), findsOneWidget);
    expect(find.text('Multiple choice · About 1 min'), findsOneWidget);
    expect(find.textContaining('Why level 1 comes next.', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Start level'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });

  testWidgets('locked while any topic is unfinished', (tester) async {
    await _openTrial(tester, readAll: false);
    expect(find.text('Finish all 3 topics to open the Trial'), findsOneWidget);
    expect(_node(1), findsNothing);
  });

  testWidgets('trophy line shows Platinum when earned', (tester) async {
    await _openTrial(tester, done: {for (var l = 1; l <= 10; l++) l});
    expect(find.text('Platinum trophy earned'), findsOneWidget);
  });

  testWidgets('all 62 levels stay reachable, unlocking one by one', (tester) async {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(id: savChapter, name: 'Surface Area and Volume', boardWeightMarks: 6, concepts: [
          Concept(id: 'c.cube', name: 'Cuboids and cubes', chapterId: savChapter),
        ]),
      ],
      questions: [
        for (var l = 1; l <= 62; l++) fixtureQuestion('q_l$l', 'c.cube', level: l, stage: stages[((l - 1) * 5) ~/ 62]),
      ],
      lessons: const [cubeLesson],
    ));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(theoryProgressProvider.notifier).markRead('t_cube');
    for (var l = 1; l <= 61; l++) {
      container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: l, score: 1);
    }
    await pumpScreen(tester, const TrialScreen(chapterId: savChapter), container: container);
    expect(_locked(62), isFalse);
    expect(find.byKey(const ValueKey('trial_stage_MASTERY_current')), findsOneWidget);
  });

  testWidgets('gapped levels unlock off the previous LOADED level', (tester) async {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(id: savChapter, name: 'Surface Area and Volume', boardWeightMarks: 6, concepts: [
          Concept(id: 'c.cube', name: 'Cuboids and cubes', chapterId: savChapter),
        ]),
      ],
      questions: [for (final l in [2, 3, 5]) fixtureQuestion('q_l$l', 'c.cube', level: l, stage: 'FOUNDATION')],
      lessons: const [cubeLesson],
    ));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(theoryProgressProvider.notifier).markRead('t_cube');
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: 2, score: 1);
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: 3, score: 1);
    await pumpScreen(tester, const TrialScreen(chapterId: savChapter), container: container);
    expect(_locked(5), isFalse, reason: 'level 4 never loaded, so it is not required');
  });
}

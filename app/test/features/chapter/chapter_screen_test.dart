import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/chapter/chapter_screen.dart';
import 'package:study_gym/features/chapter/notes_screen.dart';
import 'package:study_gym/features/theory/lesson_screen.dart';
import 'package:study_gym/features/trial/trial_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

Finder _in(String key, Finder f) => find.descendant(of: find.byKey(ValueKey(key)), matching: f);

/// The header's Practice button; the current topic's Practice node has the
/// same label.
Finder _practiceButton() =>
    find.descendant(of: find.byWidgetPredicate((w) => w is OutlinedButton), matching: find.text('Practice'));

Future<ProviderContainer> _open(WidgetTester tester, String chapterId, {Set<String> read = const {}, Brightness? theme}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  for (final id in read) {
    await container.read(theoryProgressProvider.notifier).markRead(id);
  }
  await pumpScreen(tester, ChapterScreen(chapterId: chapterId), container: container, theme: theme);
  return container;
}

void main() {
  setUp(loadSlice1Content);

  for (final t in themes.entries) {
    testWidgets('fresh chapter: first topic open with Do you know?, others locked (${t.key})', (tester) async {
      await _open(tester, savChapter, theme: t.value);

      expect(find.text('0 of 3 topics done · Trial locked'), findsOneWidget);
      final ys = ['c.cube', 'c.cyl', 'c.cone'].map((id) => tester.getTopLeft(find.byKey(ValueKey('topic_$id'))).dy).toList();
      expect(ys, [...ys]..sort(), reason: 'syllabus order');

      expect(_in('topic_c.cube', find.text('Do you know?')), findsOneWidget);
      expect(_in('topic_c.cube', find.textContaining('Every shipping box is a cuboid.', findRichText: true)), findsOneWidget);
      expect(_in('topic_c.cube', find.text('Questions coming soon')), findsNWidgets(4));
      expect(_in('topic_c.cyl', find.byIcon(Icons.lock_rounded)), findsOneWidget);
      expect(_in('topic_c.cyl', find.text('Do you know?')), findsNothing);
      expect(find.text('Finish all 3 topics to open the Trial'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Learn opens the lesson; marking it read finishes the topic (interim rule)', (tester) async {
    await _open(tester, savChapter);
    await tester.tap(find.byKey(const ValueKey('node_c.cube_learn')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);

    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();

    expect(find.byType(ChapterScreen), findsOneWidget);
    expect(find.text('Cuboids and cubes · Lesson read'), findsOneWidget);
    expect(_in('topic_c.cyl', find.text('Do you know?')), findsOneWidget, reason: 'next topic is now current');
    expect(tester.widget<Icon>(find.byKey(const ValueKey('seal_c.cube'))).icon, Icons.lock_open_rounded);
    expect(tester.widget<Icon>(find.byKey(const ValueKey('seal_c.cyl'))).icon, Icons.lock_rounded);
  });

  testWidgets('all seals broken opens the Trial', (tester) async {
    await _open(tester, savChapter, read: {'t_cube', 't_cyl', 't_cone'});
    expect(find.text('3 of 3 topics done · Trial open'), findsOneWidget);
    await tester.tap(find.text('Open the Trial'));
    await tester.pumpAndSettle();
    expect(find.byType(TrialScreen), findsOneWidget);
  });

  testWidgets('a topic with questions uses its nodes, not the lesson-read rule', (tester) async {
    await _open(tester, idenChapter, read: {'t_iden'});
    expect(find.text('0 of 1 topics done'), findsOneWidget);
    expect(_in('node_c.iden_practice', find.text('Questions coming soon')), findsOneWidget);
    expect(_in('node_c.iden_challenge', find.byIcon(Icons.lock_rounded)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('node_c.iden_guided')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });

  testWidgets('Notes lists the chapter\'s lessons; Practice lists its topics', (tester) async {
    await _open(tester, savChapter);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.text('Cylinders'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(_practiceButton());
    await tester.pumpAndSettle();
    expect(_in('practice_c.cube', find.text('No practice questions yet')), findsOneWidget);
  });

  testWidgets('Practice starts a topic drill when questions exist', (tester) async {
    await _open(tester, seqChapter);
    await tester.tap(_practiceButton());
    await tester.pumpAndSettle();
    expect(_in('practice_c.ap', find.text('0% mastery')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('practice_c.ap')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/chapter/chapter_screen.dart';
import 'package:study_gym/features/learn/learn_screen.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

double _y(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;
Finder _row(String id) => find.byKey(ValueKey('chapter_row_$id'));

void main() {
  setUp(loadSlice1Content);

  for (final t in themes.entries) {
    testWidgets('units in syllabus order with marks; chapters inside them; Tests last (${t.key})', (tester) async {
      await pumpScreen(tester, const LearnScreen(), theme: t.value);

      expect(find.text('Class 9 ▾'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('0 of 4 chapters started · 0 levels cleared'), findsOneWidget);

      final algebra = find.text('Algebra · 20 marks');
      final geometry = find.text('Geometry · 25 marks');
      final mensuration = find.text('Mensuration · 14 marks');
      expect(_y(tester, algebra) < _y(tester, geometry), isTrue);
      expect(_y(tester, geometry) < _y(tester, mensuration), isTrue);
      expect(_y(tester, _row(seqChapter)) < _y(tester, _row(idenChapter)), isTrue);
      expect(_y(tester, algebra) < _y(tester, _row(seqChapter)), isTrue);
      expect(_y(tester, _row(idenChapter)) < _y(tester, geometry), isTrue);

      expect(_y(tester, find.text('Tests')) > _y(tester, _row(savChapter)), isTrue, reason: 'Tests at the end');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a chapter with no content shows Soon and does not open', (tester) async {
    await pumpScreen(tester, const LearnScreen());
    expect(find.descendant(of: _row(triChapter), matching: find.text('Soon')), findsOneWidget);
    await tester.tap(_row(triChapter));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsNothing);
  });

  testWidgets('the chapter in progress is pinned, with real progress', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(theoryProgressProvider.notifier).markRead('t_cube');
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: 1, score: 1);
    await pumpScreen(tester, const LearnScreen(), container: container);

    expect(find.text('1 of 4 chapters started · 1 level cleared'), findsOneWidget);
    final pinned = find.byKey(const ValueKey('pinned_chapter'));
    expect(find.descendant(of: pinned, matching: find.text('Surface Area and Volume')), findsOneWidget);
    expect(_y(tester, pinned) < _y(tester, find.text('Algebra · 20 marks')), isTrue);

    await tester.tap(pinned);
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsOneWidget);
  });

  testWidgets('no chapter started: the first chapter with content is suggested', (tester) async {
    await pumpScreen(tester, const LearnScreen());
    expect(find.text('Start here'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('pinned_chapter')), matching: find.text('Sequences and Progressions')), findsOneWidget);
  });

  testWidgets('chapters with no unit (database without the units migration) are still listed', (tester) async {
    // No units loaded: what the app gets from a database without 20261001000000.
    final snap = slice1Snapshot();
    Content.load(ContentSnapshot(chapters: snap.chapters, questions: snap.questions, lessons: snap.lessons));
    await pumpScreen(tester, const LearnScreen());
    expect(find.text('More chapters'), findsOneWidget);
    expect(_row(savChapter), findsOneWidget);
  });
}

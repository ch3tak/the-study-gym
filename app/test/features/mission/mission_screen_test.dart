import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/mission/mission_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

const _chapterId = 'surface_area_volume';
const _stages = ['FOUNDATION', 'GUIDED_PRACTICE', 'SKILL_BUILDING', 'APPLICATION', 'MASTERY'];

Question _level(int level) => Question(
      id: 'q_l$level',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.mcq,
      difficulty: 1,
      marks: 1,
      stem: 'stem $level',
      options: const ['a', 'b'],
      correctIndex: 0,
      level: level,
      stage: _stages[(level - 1) ~/ 13 % _stages.length],
      solutionSteps: const [],
    );

void _loadLevels(Iterable<int> levels) {
  Content.load(ContentSnapshot(
    chapters: const [
      Chapter(
        id: _chapterId,
        name: 'Mensuration: Surface Area and Volume',
        subject: Subject.maths,
        boardWeightMarks: 6,
        concepts: [Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: _chapterId)],
      ),
    ],
    questions: levels.map(_level).toList(),
  ));
}

Finder _node(int level) => find.byKey(ValueKey('mission_node_$level'));

bool _isLocked(WidgetTester tester, int level) =>
    find.descendant(of: _node(level), matching: find.byIcon(Icons.lock_rounded)).evaluate().isNotEmpty;

VoidCallback? _onTap(WidgetTester tester, int level) => tester
    .widget<GestureDetector>(find.descendant(of: _node(level), matching: find.byType(GestureDetector)).first)
    .onTap;

void main() {
  testWidgets('fresh student: only level 1 unlocked and tappable, 2-62 locked, all 5 stage headers', (tester) async {
    _loadLevels(List.generate(62, (i) => i + 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          levelProgressProvider.overrideWith(LevelProgressNotifier.new),
        ],
        child: const MaterialApp(home: MissionScreen(chapterId: _chapterId)),
      ),
    );
    await tester.pumpAndSettle();

    expect(_node(1), findsOneWidget);
    expect(_node(62), findsOneWidget);

    expect(_isLocked(tester, 1), isFalse);
    expect(_onTap(tester, 1), isNotNull);
    for (var level = 2; level <= 62; level++) {
      expect(_isLocked(tester, level), isTrue, reason: 'level $level should be locked');
      expect(_onTap(tester, level), isNull, reason: 'level $level should not be tappable');
    }

    for (final label in ['Foundation', 'Guided Practice', 'Skill Building', 'Application', 'Mastery']) {
      expect(find.text(label), findsOneWidget, reason: 'missing stage header "$label"');
    }

    await tester.tap(_node(1));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });

  testWidgets('gapped level set {2, 3, 5}: unlock follows the loaded list, not level - 1', (tester) async {
    // Simulates levels 1 and 4 being review-status and so never loaded.
    _loadLevels([2, 3, 5]);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MissionScreen(chapterId: _chapterId)),
      ),
    );
    await tester.pumpAndSettle();

    // Level 2 is first in the list, so it is unlocked even though level 1
    // was never completed (it doesn't exist client-side).
    expect(_isLocked(tester, 2), isFalse);
    expect(_onTap(tester, 2), isNotNull);
    expect(_isLocked(tester, 3), isTrue);
    expect(_isLocked(tester, 5), isTrue);

    container.read(levelProgressProvider.notifier).completeLevel(chapterId: _chapterId, level: 2, score: 1);
    await tester.pumpAndSettle();
    expect(_isLocked(tester, 3), isFalse);
    expect(_isLocked(tester, 5), isTrue);

    // Level 5 unlocks off level 3 — the absent level 4 is not required.
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: _chapterId, level: 3, score: 1);
    await tester.pumpAndSettle();
    expect(_isLocked(tester, 5), isFalse);
    expect(_onTap(tester, 5), isNotNull);
  });
}

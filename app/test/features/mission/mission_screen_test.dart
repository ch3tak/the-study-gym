import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/mission/mission_screen.dart';

List<Question> _levels() {
  const stages = ['FOUNDATION', 'GUIDED_PRACTICE', 'SKILL_BUILDING', 'APPLICATION', 'MASTERY'];
  return List.generate(62, (i) {
    final level = i + 1;
    final stage = stages[(level - 1) ~/ 13 % stages.length];
    return Question(
      id: 'q_l$level',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.mcq,
      difficulty: 1,
      marks: 1,
      stem: 'stem $level',
      options: const ['a', 'b'],
      correctIndex: 0,
      level: level,
      stage: stage,
      solutionSteps: const [],
    );
  });
}

void main() {
  setUp(() {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(
          id: 'surface_area_volume',
          name: 'Mensuration: Surface Area and Volume',
          subject: Subject.maths,
          boardWeightMarks: 6,
          concepts: [Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: 'surface_area_volume')],
        ),
      ],
      questions: _levels(),
    ));
  });

  testWidgets('renders 62 nodes in level order with only level 1 unlocked for a fresh student', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          levelProgressProvider.overrideWith(LevelProgressNotifier.new),
        ],
        child: const MaterialApp(home: MissionScreen(chapterId: 'surface_area_volume')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mission_node_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('mission_node_62')), findsOneWidget);

    final lockedIcon = find.descendant(
      of: find.byKey(const ValueKey('mission_node_2')),
      matching: find.byIcon(Icons.lock_rounded),
    );
    expect(lockedIcon, findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/workout/question_card.dart';

void main() {
  testWidgets('renders one sub-card per part for a case_based question', (tester) async {
    final part0 = Question(
      id: 'q1_part0',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 1,
      stem: 'Find the volume.',
      numericAnswer: '216',
      unit: 'cm^3',
      solutionSteps: const [],
    );
    final part1 = Question(
      id: 'q1_part1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'Which formula gives the surface area?',
      options: const ['6a^2', 'a^3'],
      correctIndex: 0,
      solutionSteps: const [],
    );
    final question = Question(
      id: 'q1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.caseBased,
      difficulty: 2,
      marks: 2,
      stem: 'A cube has side 6 cm.',
      parts: [part0, part1],
      solutionSteps: const [],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: QuestionCard(
          question: question,
          selectedIndex: null,
          onSelect: (_) {},
          partSelections: const {},
          onSelectPart: (_, __) {},
          partNumericControllers: {0: TextEditingController()},
        ),
      ),
    ));

    expect(find.text('Find the volume.'), findsOneWidget);
    expect(find.text('Which formula gives the surface area?'), findsOneWidget);
    expect(find.text('6a^2'), findsOneWidget);
  });
}

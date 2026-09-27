import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/skill_map/skill_map_screen.dart';

void main() {
  testWidgets('shows Start Mission only for a chapter with mission-leveled questions', (tester) async {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(
          id: 'surface_area_volume',
          name: 'Mensuration: Surface Area and Volume',
          subject: Subject.maths,
          boardWeightMarks: 6,
          concepts: [Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: 'surface_area_volume')],
        ),
        Chapter(
          id: 'sequences_progressions',
          name: 'Sequences and Progressions',
          subject: Subject.maths,
          boardWeightMarks: 6,
          concepts: [Concept(id: 'c9.seq.ap_nth_term', name: 'nth term of an AP', chapterId: 'sequences_progressions')],
        ),
      ],
      questions: [
        Question(
          id: 'q_l1',
          conceptId: 'c9.sav.cuboid_cube',
          type: QuestionType.mcq,
          difficulty: 1,
          marks: 1,
          stem: 'stem',
          options: const ['a', 'b'],
          correctIndex: 0,
          level: 1,
          stage: 'FOUNDATION',
          solutionSteps: const [],
        ),
        Question(
          id: 'q_ap',
          conceptId: 'c9.seq.ap_nth_term',
          type: QuestionType.mcq,
          difficulty: 1,
          marks: 1,
          stem: 'stem',
          options: const ['a', 'b'],
          correctIndex: 0,
          solutionSteps: const [],
        ),
      ],
    ));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SkillMapScreen())),
    );
    await tester.pumpAndSettle();

    // Verify "Start Mission" button appears under the mission chapter (surface_area_volume)
    expect(
      find.descendant(
        of: find.widgetWithText(Container, 'Mensuration: Surface Area and Volume'),
        matching: find.text('Start Mission'),
      ),
      findsOneWidget,
    );

    // Verify "Start Mission" button does NOT appear under the non-mission chapter (sequences_progressions)
    expect(
      find.descendant(
        of: find.widgetWithText(Container, 'Sequences and Progressions'),
        matching: find.text('Start Mission'),
      ),
      findsNothing,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

Question _numericPart(String id, String answer) => Question(
      id: id,
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 1,
      stem: 'part stem $id',
      numericAnswer: answer,
      solutionSteps: const [],
    );

Question _caseBasedLevel({required List<Question> parts}) => Question(
      id: 'q_case',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.caseBased,
      difficulty: 2,
      marks: 2,
      stem: 'case stem',
      level: 8,
      stage: 'FOUNDATION',
      parts: parts,
      conceptIds: const ['c9.sav.cuboid_cube'],
      solutionSteps: const [],
    );

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
      questions: [],
    ));
  });

  Future<void> _pump(WidgetTester tester, Question level) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: WorkoutScreen.singleLevel(level)),
      ),
    );
  }

  testWidgets('case_based level: both parts correct -> Correct! feedback', (tester) async {
    final level = _caseBasedLevel(parts: [
      _numericPart('p0', '216'),
      _numericPart('p1', '216'),
    ]);
    await _pump(tester, level);

    await tester.enterText(find.byType(TextField).at(0), '216');
    await tester.enterText(find.byType(TextField).at(1), '216');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Correct!'), findsOneWidget);
  });

  testWidgets('case_based level: one part wrong -> Not yet feedback', (tester) async {
    final level = _caseBasedLevel(parts: [
      _numericPart('p0', '216'),
      _numericPart('p1', '216'),
    ]);
    await _pump(tester, level);

    await tester.enterText(find.byType(TextField).at(0), '216');
    await tester.enterText(find.byType(TextField).at(1), '999');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Not yet'), findsOneWidget);
  });

  testWidgets('case_based level: all parts wrong -> Not yet feedback', (tester) async {
    final level = _caseBasedLevel(parts: [
      _numericPart('p0', '216'),
      _numericPart('p1', '216'),
    ]);
    await _pump(tester, level);

    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Not yet'), findsOneWidget);
  });
}

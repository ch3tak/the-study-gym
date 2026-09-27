import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/workout/workout_screen.dart';
import 'package:study_gym/shared/widgets/chunky_button.dart';

const _chapterId = 'surface_area_volume';

Question _numericPart(String id, String answer, {List<String> steps = const []}) => Question(
      id: id,
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 1,
      stem: 'part stem $id',
      numericAnswer: answer,
      solutionSteps: steps,
    );

Question _mcqPart(String id, {required int correctIndex}) => Question(
      id: id,
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'mcq part stem $id',
      options: const ['option A', 'option B', 'option C'],
      correctIndex: correctIndex,
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

Question _mcqLevel({List<String> conceptIds = const ['c9.sav.cuboid_cube']}) => Question(
      id: 'q_mcq',
      conceptId: conceptIds.first,
      type: QuestionType.mcq,
      difficulty: 1,
      marks: 1,
      stem: 'mcq stem',
      options: const ['right', 'wrong'],
      correctIndex: 0,
      level: 4,
      stage: 'FOUNDATION',
      conceptIds: conceptIds,
      solutionSteps: const [],
    );

Question _toleranceLevel() => Question(
      id: 'q_tol',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 3,
      marks: 2,
      stem: 'capsule volume',
      numericAnswer: '487.67',
      tolerance: 0.1,
      level: 49,
      stage: 'APPLICATION',
      solutionSteps: const [],
    );

void main() {
  setUp(() {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(
          id: _chapterId,
          name: 'Mensuration: Surface Area and Volume',
          subject: Subject.maths,
          boardWeightMarks: 6,
          concepts: [
            Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: _chapterId),
            Concept(id: 'c9.sav.cylinder', name: 'Cylinder', chapterId: _chapterId),
            Concept(id: 'c9.sav.cone', name: 'Cone', chapterId: _chapterId),
          ],
        ),
      ],
      questions: [],
    ));
  });

  Future<void> pumpLevel(WidgetTester tester, Question level) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: WorkoutScreen.singleLevel(level)),
      ),
    );
  }

  /// Pushes the workout from a host page (as MissionScreen does) so that
  /// Continue's pop has somewhere to return to.
  Future<ProviderContainer> pushLevel(WidgetTester tester, Question level) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => WorkoutScreen.singleLevel(level)),
                ),
                child: const Text('open level'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open level'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] into the (800x600) test viewport before tapping —
  /// case_based parts and the feedback panel sit below the fold.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  group('case_based grading', () {
    testWidgets('both parts correct -> Correct! feedback', (tester) async {
      await pumpLevel(tester, _caseBasedLevel(parts: [_numericPart('p0', '216'), _numericPart('p1', '216')]));
      await tester.enterText(find.byType(TextField).at(0), '216');
      await tester.enterText(find.byType(TextField).at(1), '216');
      await submit(tester);
      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('one part wrong -> Not yet feedback', (tester) async {
      await pumpLevel(tester, _caseBasedLevel(parts: [_numericPart('p0', '216'), _numericPart('p1', '216')]));
      await tester.enterText(find.byType(TextField).at(0), '216');
      await tester.enterText(find.byType(TextField).at(1), '999');
      await submit(tester);
      expect(find.text('Not yet'), findsOneWidget);
    });

    testWidgets('all parts wrong -> Not yet feedback', (tester) async {
      await pumpLevel(tester, _caseBasedLevel(parts: [_numericPart('p0', '216'), _numericPart('p1', '216')]));
      await tester.enterText(find.byType(TextField).at(0), '1');
      await tester.enterText(find.byType(TextField).at(1), '2');
      await submit(tester);
      expect(find.text('Not yet'), findsOneWidget);
    });

    testWidgets('mcq part graded via partSelections: correct option -> Correct!', (tester) async {
      await pumpLevel(tester, _caseBasedLevel(parts: [_numericPart('p0', '216'), _mcqPart('p1', correctIndex: 1)]));
      await tester.enterText(find.byType(TextField).at(0), '216');
      await tapVisible(tester, find.text('option B'));
      await submit(tester);
      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('mcq part graded via partSelections: wrong option -> Not yet', (tester) async {
      await pumpLevel(tester, _caseBasedLevel(parts: [_numericPart('p0', '216'), _mcqPart('p1', correctIndex: 1)]));
      await tester.enterText(find.byType(TextField).at(0), '216');
      await tapVisible(tester, find.text('option C'));
      await submit(tester);
      expect(find.text('Not yet'), findsOneWidget);
    });

    testWidgets('Submit stays disabled until the mcq part has a selection', (tester) async {
      await pumpLevel(tester, _caseBasedLevel(parts: [_mcqPart('p0', correctIndex: 0)]));
      await tester.pump();
      expect(tester.widget<ChunkyButton>(find.widgetWithText(ChunkyButton, 'Submit')).onPressed, isNull);
      await tapVisible(tester, find.text('option A'));
      await tester.pump();
      expect(tester.widget<ChunkyButton>(find.widgetWithText(ChunkyButton, 'Submit')).onPressed, isNotNull);
    });

    testWidgets('case_based with no parts can never be submitted', (tester) async {
      await pumpLevel(tester, _caseBasedLevel(parts: const []));
      await tester.pump();
      expect(tester.widget<ChunkyButton>(find.widgetWithText(ChunkyButton, 'Submit')).onPressed, isNull);
    });
  });

  group('level completion', () {
    testWidgets('wrong answer + Continue does NOT complete the level', (tester) async {
      final container = await pushLevel(tester, _mcqLevel());
      await tester.tap(find.text('wrong'));
      await submit(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutScreen), findsNothing, reason: 'Continue still returns to the path');
      expect(container.read(levelProgressProvider).isCompleted(_chapterId, 4), isFalse);
      expect(container.read(levelProgressProvider).isUnlocked(_chapterId, previousLevelInList: 4), isFalse);
    });

    testWidgets('wrong answer, wrong retry + Continue does NOT complete the level', (tester) async {
      final container = await pushLevel(tester, _mcqLevel());
      await tester.tap(find.text('wrong'));
      await submit(tester);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('wrong'));
      await submit(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(container.read(levelProgressProvider).isCompleted(_chapterId, 4), isFalse);
    });

    testWidgets('correct answer + Continue completes the level', (tester) async {
      final container = await pushLevel(tester, _mcqLevel());
      await tester.tap(find.text('right'));
      await submit(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(container.read(levelProgressProvider).isCompleted(_chapterId, 4), isTrue);
      expect(container.read(levelProgressProvider).isUnlocked(_chapterId, previousLevelInList: 4), isTrue);
    });

    testWidgets('wrong first attempt, correct retry passes the level', (tester) async {
      final container = await pushLevel(tester, _mcqLevel());
      await tester.tap(find.text('wrong'));
      await submit(tester);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('right'));
      await submit(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(container.read(levelProgressProvider).isCompleted(_chapterId, 4), isTrue);
    });

    testWidgets('case_based all wrong + Continue does NOT complete; all right does', (tester) async {
      final level = _caseBasedLevel(parts: [_numericPart('p0', '216'), _numericPart('p1', '216')]);

      var container = await pushLevel(tester, level);
      await tester.enterText(find.byType(TextField).at(0), '1');
      await tester.enterText(find.byType(TextField).at(1), '2');
      await submit(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(container.read(levelProgressProvider).isCompleted(_chapterId, 8), isFalse);

      container = await pushLevel(tester, level);
      await tester.enterText(find.byType(TextField).at(0), '216');
      await tester.enterText(find.byType(TextField).at(1), '216');
      await submit(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(container.read(levelProgressProvider).isCompleted(_chapterId, 8), isTrue);
    });
  });

  testWidgets('a multi-concept question records mastery for every concept', (tester) async {
    const ids = ['c9.sav.cuboid_cube', 'c9.sav.cylinder', 'c9.sav.cone'];
    final container = await pushLevel(tester, _mcqLevel(conceptIds: ids));
    await tester.tap(find.text('right'));
    await submit(tester);

    final mastery = container.read(studentProvider).mastery;
    for (final id in ids) {
      expect(mastery[id]?.attempts, 1, reason: 'no attempt recorded for $id');
      expect(mastery[id]?.correct, 1);
    }
  });

  group('numeric tolerance', () {
    testWidgets('an answer within tolerance is accepted', (tester) async {
      await pumpLevel(tester, _toleranceLevel());
      await tester.enterText(find.byType(TextField), '487.6');
      await submit(tester);
      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('an answer outside tolerance is rejected', (tester) async {
      await pumpLevel(tester, _toleranceLevel());
      await tester.enterText(find.byType(TextField), '487.5');
      await submit(tester);
      expect(find.text('Not yet'), findsOneWidget);
    });
  });

  testWidgets('case_based feedback panel shows each part\'s solution steps', (tester) async {
    await pumpLevel(
      tester,
      _caseBasedLevel(parts: [
        _numericPart('p0', '320', steps: ['Room volume = 320']),
        _numericPart('p1', '85.33', steps: ['Pyramid volume = 256/3']),
      ]),
    );
    await tester.enterText(find.byType(TextField).at(0), '320');
    await tester.enterText(find.byType(TextField).at(1), '85.33');
    await submit(tester);

    await tapVisible(tester, find.text('Show solution'));
    await tester.pumpAndSettle();

    expect(find.text('• Room volume = 320'), findsOneWidget);
    expect(find.text('• Pyramid volume = 256/3'), findsOneWidget);
    // "Part N" appears once on the question card and once in the solution.
    expect(find.text('Part 1'), findsNWidgets(2));
    expect(find.text('Part 2'), findsNWidgets(2));
  });
}

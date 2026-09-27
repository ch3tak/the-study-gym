import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

void main() {
  Map<String, dynamic> chapterRow(String id, String subjectCode) => {
        'id': id,
        'name': id,
        'board_weight': 6,
        'sort_order': 1,
        'subjects': {'class_id': 'cbse_9', 'code': subjectCode, 'status': 'live'},
      };

  test('a non-maths chapter row is dropped even if its subject is live', () {
    final snapshot = ContentRepository.forTesting().buildSnapshot(
      chapterRows: [chapterRow('surface_area_volume', 'maths'), chapterRow('motion', 'science')],
      conceptRows: [
        {'id': 'c9.sav.cuboid_cube', 'chapter_id': 'surface_area_volume', 'name': 'Cuboids'},
        {'id': 'c9.motion.speed', 'chapter_id': 'motion', 'name': 'Speed'},
      ],
      questionRows: const [],
    );
    expect(snapshot.chapters.map((c) => c.id), ['surface_area_volume']);
  });

  Map<String, dynamic> lessonRow(String id, String conceptId,
          {String hookKind = 'real_world', String? tryIt, int sortOrder = 1}) =>
      {
        'id': id,
        'concept_id': conceptId,
        'title': 'Title $id',
        'body': 'Body with \$x^2\$.',
        'hook_kind': hookKind,
        'hook': 'Hook $id',
        'try_it': tryIt,
        'sort_order': sortOrder,
      };

  ContentSnapshot snapshotWithLessons(List<Map<String, dynamic>> lessonRows) =>
      ContentRepository.forTesting().buildSnapshot(
        chapterRows: [chapterRow('surface_area_volume', 'maths')],
        conceptRows: [
          {'id': 'c9.sav.cuboid_cube', 'chapter_id': 'surface_area_volume', 'name': 'Cuboids'},
        ],
        questionRows: const [],
        lessonRows: lessonRows,
      );

  test('a lessons row parses into a Lesson', () {
    final s = snapshotWithLessons([
      lessonRow('t_a', 'c9.sav.cuboid_cube', hookKind: 'historical', tryIt: 'Try this', sortOrder: 3),
    ]);
    final l = s.lessons.single;
    expect(l.id, 't_a');
    expect(l.conceptId, 'c9.sav.cuboid_cube');
    expect(l.title, 'Title t_a');
    expect(l.body, r'Body with $x^2$.');
    expect(l.hookKind, HookKind.historical);
    expect(l.hook, 'Hook t_a');
    expect(l.tryIt, 'Try this');
    expect(l.sortOrder, 3);
  });

  test('try_it is optional and real_world maps to HookKind.realWorld', () {
    final l = snapshotWithLessons([lessonRow('t_a', 'c9.sav.cuboid_cube')]).lessons.single;
    expect(l.tryIt, isNull);
    expect(l.hookKind, HookKind.realWorld);
  });

  test('a lesson whose concept is not loaded is dropped', () {
    final s = snapshotWithLessons([
      lessonRow('t_a', 'c9.sav.cuboid_cube'),
      lessonRow('t_ghost', 'c9.motion.speed'),
    ]);
    expect(s.lessons.map((l) => l.id), ['t_a']);
  });

  test('a lesson with an unknown hook_kind is skipped, not fatal', () {
    final s = snapshotWithLessons([
      lessonRow('t_a', 'c9.sav.cuboid_cube'),
      lessonRow('t_bad', 'c9.sav.cuboid_cube', hookKind: 'fun_fact'),
    ]);
    expect(s.lessons.map((l) => l.id), ['t_a']);
  });

  test('lessonsForChapter orders by sortOrder', () {
    Content.load(snapshotWithLessons([
      lessonRow('t_b', 'c9.sav.cuboid_cube', sortOrder: 2),
      lessonRow('t_a', 'c9.sav.cuboid_cube', sortOrder: 1),
    ]));
    expect(Content.lessonsForChapter('surface_area_volume').map((l) => l.id), ['t_a', 't_b']);
    expect(Content.lessonsForChapter('no_such_chapter'), isEmpty);
  });

  test('a case_based row round-trips into a Question with populated parts', () {
    final repo = ContentRepository.forTesting();
    final body = {
      'stem': 'A cube has side 6 cm. Answer both parts.',
      'parts': [
        {
          'type': 'numeric',
          'stem': 'Find the volume.',
          'numericAnswer': '216',
          'unit': 'cm^3',
          'marks': 1,
          'concept_ids': ['c9.sav.cuboid_cube'],
          'hints': <String>[],
          'solutionSteps': ['Volume = 216 cm^3'],
        },
        {
          'type': 'numeric',
          'stem': 'Find the surface area.',
          'numericAnswer': '216',
          'unit': 'cm^2',
          'marks': 1,
          'concept_ids': ['c9.sav.cuboid_cube'],
          'hints': <String>[],
          'solutionSteps': ['TSA = 216 cm^2'],
        },
      ],
      'hints': <String>[],
      'solutionSteps': <String>[],
    };

    final question = repo.questionFromRowForTesting(
      id: 'q_c9_sav_l008',
      conceptId: 'c9.sav.cuboid_cube',
      type: 'case_based',
      difficulty: 2,
      marks: 2,
      body: body,
      level: 8,
      stage: 'FOUNDATION',
    );

    expect(question.type, QuestionType.caseBased);
    expect(question.level, 8);
    expect(question.stage, 'FOUNDATION');
    expect(question.parts, hasLength(2));
    expect(question.parts[0].type, QuestionType.numeric);
    expect(question.parts[0].numericAnswer, '216');
    expect(question.parts[0].unit, 'cm^3');
    expect(question.parts[1].unit, 'cm^2');
  });

  test('an mcq row still parses with level/stage null when absent', () {
    final repo = ContentRepository.forTesting();
    final question = repo.questionFromRowForTesting(
      id: 'q_ap_nth_1',
      conceptId: 'c9.seq.ap_nth_term',
      type: 'mcq',
      difficulty: 2,
      marks: 1,
      body: {
        'stem': 'stem',
        'options': ['a', 'b'],
        'correctIndex': 0,
        'hints': <String>[],
        'solutionSteps': <String>[],
      },
    );
    expect(question.level, isNull);
    expect(question.stage, isNull);
    expect(question.parts, isEmpty);
  });

  test('tolerance parses onto top-level numeric questions and case_based parts', () {
    final repo = ContentRepository.forTesting();
    final numeric = repo.questionFromRowForTesting(
      id: 'q_tol',
      conceptId: 'c9.sav.cylinder',
      type: 'numeric',
      difficulty: 3,
      marks: 2,
      body: {'stem': 's', 'numericAnswer': '487.67', 'tolerance': 0.1, 'solutionSteps': <String>[]},
    );
    expect(numeric.tolerance, 0.1);

    final noTol = repo.questionFromRowForTesting(
      id: 'q_exact',
      conceptId: 'c9.sav.cylinder',
      type: 'numeric',
      difficulty: 1,
      marks: 1,
      body: {'stem': 's', 'numericAnswer': '216', 'solutionSteps': <String>[]},
    );
    expect(noTol.tolerance, isNull);

    final caseBased = repo.questionFromRowForTesting(
      id: 'q_case',
      conceptId: 'c9.sav.cylinder',
      type: 'case_based',
      difficulty: 3,
      marks: 2,
      body: {
        'stem': 's',
        'parts': [
          {'type': 'numeric', 'marks': 2, 'stem': 'p', 'numericAnswer': '309.37', 'tolerance': 1},
        ],
      },
    );
    // An integer JSON tolerance still parses as a double.
    expect(caseBased.parts.single.tolerance, 1.0);
  });

  test('a case_based row with empty or missing parts is rejected, not parsed as 0-part', () {
    final repo = ContentRepository.forTesting();
    for (final body in [
      {'stem': 's', 'parts': <Object>[]},
      {'stem': 's'},
    ]) {
      expect(
        () => repo.questionFromRowForTesting(
          id: 'q_bad',
          conceptId: 'c9.sav.cylinder',
          type: 'case_based',
          difficulty: 2,
          marks: 2,
          body: body,
        ),
        throwsFormatException,
      );
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

void main() {
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
}

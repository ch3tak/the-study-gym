import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/models.dart';

void main() {
  test('Question.conceptIds defaults to a single-element list from conceptId', () {
    final q = Question(
      id: 'q1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.mcq,
      difficulty: 1,
      marks: 1,
      stem: 'stem',
      solutionSteps: [],
    );
    expect(q.conceptIds, ['c9.sav.cuboid_cube']);
  });

  test('Question can carry level, stage, and case_based parts', () {
    final part = Question(
      id: 'q1_part0',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 1,
      stem: 'Find the volume.',
      numericAnswer: '216',
      solutionSteps: [],
    );
    final q = Question(
      id: 'q1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.caseBased,
      difficulty: 2,
      marks: 2,
      stem: 'A cube has side 6 cm.',
      level: 8,
      stage: 'FOUNDATION',
      parts: [part],
      solutionSteps: [],
    );
    expect(q.level, 8);
    expect(q.stage, 'FOUNDATION');
    expect(q.parts, [part]);
  });

  test('LevelProgress carries level, chapterId, completedAt, score', () {
    final progress = LevelProgress(
      level: 3,
      chapterId: 'surface_area_volume',
      completedAt: DateTime.utc(2026, 9, 27),
      score: 1.0,
    );
    expect(progress.level, 3);
    expect(progress.chapterId, 'surface_area_volume');
    expect(progress.score, 1.0);
  });
}

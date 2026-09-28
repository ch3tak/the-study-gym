import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/workout/workout_selector.dart';

import '../../fixtures/slice1_content.dart';

List<Concept> _concepts(List<String> ids) => ids.map(Content.conceptById).toList();

void main() {
  setUp(loadSlice1Content);

  test('the daily workout is exactly 5 questions: 2 warm-up, 2 strength, 1 challenge', () {
    final picked = selectWorkout(_concepts(['c.ap', 'c.gp']));
    expect(picked, hasLength(5));
    expect(picked.map((s) => s.section), [
      WorkoutSection.warmUp,
      WorkoutSection.warmUp,
      WorkoutSection.strength,
      WorkoutSection.strength,
      WorkoutSection.challenge,
    ]);
  });

  test('Keep going gives 5 more, none repeated', () {
    final first = selectWorkout(_concepts(['c.ap', 'c.gp']));
    final served = first.map((s) => s.question.id).toSet();
    final more = selectWorkout(_concepts(['c.ap', 'c.gp']), exclude: served);
    expect(more, hasLength(5));
    expect(more.map((s) => s.question.id).toSet().intersection(served), isEmpty);
  });

  test('Trial levels are never served', () {
    expect(selectWorkout(_concepts(['c.cube'])), isEmpty);
  });

  test('an exhausted pool gives fewer questions, not a crash', () {
    final all = Content.questions.where((q) => q.level == null && q.conceptId.startsWith('c.')).map((q) => q.id).toSet();
    final ten = all.where((id) => id != 'q_c.ap_6' && id != 'q_c.gp_6').toSet();
    expect(selectWorkout(_concepts(['c.ap', 'c.gp']), exclude: ten), hasLength(2));
    expect(selectWorkout(_concepts(['c.ap', 'c.gp']), exclude: all), isEmpty);
  });

  test('a new student trains the first chapter that has practice questions', () {
    expect(pickWorkoutConcepts(StudentState()).map((c) => c.id), ['c.ap', 'c.gp']);
  });

  test('weakest concepts first, but concepts with only Trial questions are never picked', () {
    final student = StudentState(mastery: {
      'c.cube': ConceptMastery(conceptId: 'c.cube', masteryPercent: 1, attempts: 3),
      'c.gp': ConceptMastery(conceptId: 'c.gp', masteryPercent: 10, attempts: 3),
      'c.ap': ConceptMastery(conceptId: 'c.ap', masteryPercent: 90, attempts: 3),
    });
    expect(pickWorkoutConcepts(student).map((c) => c.id), ['c.gp', 'c.ap']);
  });
}

import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/models.dart';

enum WorkoutSection { warmUp, strength, challenge }

/// Daily and Keep going runs are saved as workouts (they keep the streak)
/// and end with Keep going. Practice runs (topic practice, fading review,
/// custom tests) are not.
enum WorkoutKind { daily, keepGoing, practice }

class SelectedQuestion {
  const SelectedQuestion(this.question, this.section);
  final Question question;
  final WorkoutSection section;
}

/// The Daily Workout and each Keep going batch (spec: "5-question, about
/// 5-minute workout").
const dailyWorkoutSize = 5;

/// Topic practice and custom tests keep the old workout's size.
const practiceWorkoutSize = 10;

/// The concepts a workout trains: the student's three weakest that have
/// practice questions, or, for a new student, up to three from the first
/// chapter that has any.
List<Concept> pickWorkoutConcepts(StudentState student) {
  final entries = student.mastery.values.toList()
    ..sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));
  final picked = entries
      .map((m) => Content.conceptOrNull(m.conceptId))
      .whereType<Concept>()
      .where((c) => Content.practiceQuestions(c.id).isNotEmpty)
      .take(3)
      .toList();
  if (picked.isNotEmpty) return picked;
  for (final chapter in Content.chapters) {
    final withQuestions = chapter.concepts.where((c) => Content.practiceQuestions(c.id).isNotEmpty).take(3).toList();
    if (withQuestions.isNotEmpty) return withQuestions;
  }
  return const [];
}

/// Picks up to [count] questions for [concepts]: 2 warm-up (difficulty 1),
/// 2 strength (difficulty 2) and 1 challenge (difficulty 2+), the 10-question
/// workout's 3/5/2 scaled to 5. A thin bucket is backfilled from the rest
/// of the pool, then from the concepts' whole chapters. Trial levels are never
/// served, so the workout can't spoil them. [exclude] keeps a Keep going
/// batch from repeating today's questions.
List<SelectedQuestion> selectWorkout(
  List<Concept> concepts, {
  int count = dailyWorkoutSize,
  Set<String> exclude = const {},
}) {
  final pool = concepts
      .expand((c) => Content.practiceQuestions(c.id))
      .where((q) => !exclude.contains(q.id))
      .toList();
  final result = <SelectedQuestion>[];
  final used = <String>{};

  void add(Iterable<Question> candidates, WorkoutSection section, int max) {
    var added = 0;
    for (final q in candidates) {
      if (added >= max || result.length >= count) return;
      if (used.add(q.id)) {
        result.add(SelectedQuestion(q, section));
        added++;
      }
    }
  }

  add(pool.where((q) => q.difficulty == 1), WorkoutSection.warmUp, 2);
  add(pool.where((q) => q.difficulty == 2), WorkoutSection.strength, 2);
  add(pool.where((q) => q.difficulty >= 2), WorkoutSection.challenge, 1);
  add(pool, WorkoutSection.strength, count);

  if (result.length < count) {
    final chapterConcepts = concepts.map((c) => Content.chapterOf(c.id)).toSet().expand((ch) => ch.concepts);
    final wider = chapterConcepts
        .expand((c) => Content.practiceQuestions(c.id))
        .where((q) => !exclude.contains(q.id));
    add(wider, WorkoutSection.strength, count);
  }
  return result;
}

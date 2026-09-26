/// Mirrors the shared data model from docs/PLAN.md §6 and the content
/// pipeline's question schema (content/pipeline/questions.py), simplified for
/// an in-memory mockup. Field names match the pipeline where practical, so
/// porting this to Supabase-backed data later is a rename, not a redesign.
library;

enum Subject { maths, science }

extension SubjectX on Subject {
  String get label => this == Subject.maths ? 'Maths' : 'Science';
  String get code => this == Subject.maths ? 'maths' : 'science';
}

enum MasteryState { notStarted, learning, practising, mastered, fading }

enum QuestionType { mcq, numeric, assertionReason }

class Concept {
  const Concept({
    required this.id,
    required this.name,
    required this.chapterId,
  });

  final String id;
  final String name;
  final String chapterId;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.name,
    required this.subject,
    required this.boardWeightMarks,
    required this.concepts,
  });

  final String id;
  final String name;
  final Subject subject;
  final int boardWeightMarks;
  final List<Concept> concepts;
}

/// A single misconception-mapped distractor, used to generate the coach's
/// "why this was wrong" message — mirrors `distractors` in the question schema.
class Distractor {
  const Distractor({required this.optionIndex, required this.explanation});

  final int optionIndex;
  final String explanation;
}

class Question {
  const Question({
    required this.id,
    required this.conceptId,
    required this.type,
    required this.difficulty,
    required this.marks,
    required this.stem,
    this.options = const [],
    this.correctIndex,
    this.numericAnswer,
    this.unit,
    this.assertion,
    this.reason,
    this.hints = const [],
    required this.solutionSteps,
    this.distractors = const [],
  });

  final String id;
  final String conceptId;
  final QuestionType type;
  final int difficulty; // 1..3
  final int marks;
  final String stem;

  // mcq
  final List<String> options;
  final int? correctIndex;
  final List<Distractor> distractors;

  // numeric
  final String? numericAnswer;
  final String? unit;

  // assertion_reason
  final String? assertion;
  final String? reason;

  final List<String> hints;
  final List<String> solutionSteps;
}

/// Per-student, per-concept mastery — mirrors the `concept_mastery` table.
class ConceptMastery {
  ConceptMastery({
    required this.conceptId,
    this.masteryPercent = 0,
    this.attempts = 0,
    this.correct = 0,
    this.state = MasteryState.notStarted,
  });

  final String conceptId;
  double masteryPercent; // 0..100, displayed
  int attempts;
  int correct;
  MasteryState state;
}

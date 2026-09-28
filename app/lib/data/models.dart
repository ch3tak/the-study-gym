/// Mirrors the shared data model from docs/PLAN.md §6 and the content
/// pipeline's question schema (content/pipeline/questions.py), simplified for
/// an in-memory mockup. Field names match the pipeline where practical, so
/// porting this to Supabase-backed data later is a rename, not a redesign.
library;

enum MasteryState { notStarted, learning, practising, mastered, fading }

enum QuestionType { mcq, numeric, assertionReason, caseBased, expression }

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
    required this.boardWeightMarks,
    required this.concepts,
    this.unitId,
  });

  final String id;
  final String name;
  final int boardWeightMarks;
  final List<Concept> concepts;

  /// The syllabus unit this chapter belongs to (`units.id`). Null when the
  /// database predates 20261001000000_units_nodes_trial_meta.sql.
  final String? unitId;
}

/// A syllabus unit ("Geometry · 25 marks") — mirrors the `units` table,
/// generated from content/syllabus/<board>/<class>/<subject>.yaml.
class Unit {
  const Unit({required this.id, required this.name, required this.sortOrder, this.marks});

  final String id;
  final String name;

  /// Exam marks for the unit. Null for a course with no exam.
  final int? marks;
  final int sortOrder;
}

/// A topic's four question nodes, in path order (spec: "The chapter screen").
enum TopicNode {
  guided('guided', 'Guided'),
  practice('practice', 'Practice'),
  spotTheMistake('spot_the_mistake', 'Spot the mistake'),
  challenge('challenge', 'Challenge');

  const TopicNode(this.dbValue, this.label);

  /// The value in a question body's `node` field and in `node_progress.node`.
  final String dbValue;
  final String label;

  static TopicNode? fromDb(Object? value) {
    for (final n in values) {
      if (n.dbValue == value) return n;
    }
    return null;
  }
}

/// A single misconception-mapped distractor, used to generate the coach's
/// "why this was wrong" message — mirrors `distractors` in the question schema.
class Distractor {
  const Distractor({required this.optionIndex, required this.explanation});

  final int optionIndex;
  final String explanation;
}

class Question {
  Question({
    required this.id,
    required this.conceptId,
    required this.type,
    required this.difficulty,
    required this.marks,
    required this.stem,
    this.options = const [],
    this.correctIndex,
    this.numericAnswer,
    this.tolerance,
    this.unit,
    this.assertion,
    this.reason,
    this.hints = const [],
    required this.solutionSteps,
    this.distractors = const [],
    this.level,
    this.stage,
    this.parts = const [],
    this.node,
    this.whyAfterPrevious,
    List<String>? conceptIds,
  }) : conceptIds = conceptIds ?? [conceptId];

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

  /// Accepted absolute error for a numeric answer (e.g. `0.1` accepts
  /// 487.6–487.77 for an answer of 487.67). Null means exact match.
  final double? tolerance;
  final String? unit;

  // assertion_reason
  final String? assertion;
  final String? reason;

  final List<String> hints;
  final List<String> solutionSteps;

  // Mission-level metadata — null/empty for every non-mission question.
  final int? level;
  final String? stage;

  // case_based
  final List<Question> parts;

  /// The topic node this question belongs to, from the body's `node` tag.
  /// Null for Trial levels and plain practice questions — only tagged
  /// questions count as "topic questions" (spec: the interim rule).
  final TopicNode? node;

  /// Trial levels only: why this level follows the previous one, shown in
  /// the level preview sheet.
  final String? whyAfterPrevious;

  /// All concepts this question touches — plural counterpart to [conceptId].
  /// Defaults to `[conceptId]` when not supplied, so every existing
  /// single-concept call site keeps working unchanged.
  final List<String> conceptIds;
}

enum HookKind { historical, realWorld }

/// A short theory lesson for one concept — mirrors the `lessons` table
/// (20260930000000_theory_lessons.sql).
class Lesson {
  const Lesson({
    required this.id,
    required this.conceptId,
    required this.title,
    required this.body,
    required this.hookKind,
    required this.hook,
    this.tryIt,
    required this.sortOrder,
  });

  final String id;
  final String conceptId;
  final String title;
  final String body;
  final HookKind hookKind;
  final String hook;
  final String? tryIt;
  final int sortOrder;
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

/// Per-student, per-level completion — mirrors the `level_progress` table.
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.chapterId,
    required this.completedAt,
    required this.score,
  });

  final int level;
  final String chapterId;
  final DateTime completedAt;
  final double score;
}

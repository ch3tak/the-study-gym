import '../../data/models.dart';

const trialStageLabels = {
  'FOUNDATION': 'Foundation',
  'GUIDED_PRACTICE': 'Guided practice',
  'SKILL_BUILDING': 'Skill building',
  'APPLICATION': 'Application',
  'MASTERY': 'Mastery',
};

String stageLabel(String? stage) => trialStageLabels[stage] ?? stage ?? 'Trial';

String questionTypeLabel(QuestionType type) => switch (type) {
      QuestionType.mcq => 'Multiple choice',
      QuestionType.numeric => 'Number answer',
      QuestionType.assertionReason => 'Assertion and reason',
      QuestionType.caseBased => 'Case study',
      QuestionType.expression => 'Expression',
    };

/// No level carries a time yet, so this is a per-type estimate.
int estimatedMinutes(Question q) => switch (q.type) {
      QuestionType.caseBased => 4,
      QuestionType.numeric || QuestionType.expression => 2,
      _ => 1,
    };

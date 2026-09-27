import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';

/// Renders one question by type (mcq / numeric / assertion_reason) with a
/// shared card layout — docs/PLAN.md §3: "all subject-specific input widgets
/// share one card layout and one submit/feedback pattern".
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
    this.revealAnswer = false,
    this.numericController,
    this.numericSubmitted,
    this.partSelections = const {},
    this.onSelectPart,
    this.partNumericControllers = const {},
  });

  final Question question;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool revealAnswer;
  final TextEditingController? numericController;
  final bool? numericSubmitted;

  /// case_based only: part index -> selected option index (mcq part) or
  /// unused (numeric part, which reads its own controller instead).
  final Map<int, int?> partSelections;
  final void Function(int partIndex, int optionIndex)? onSelectPart;
  final Map<int, TextEditingController> partNumericControllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StemCard(question: question),
        const SizedBox(height: AppTheme.space20),
        if (question.type == QuestionType.mcq) _McqOptions(
          question: question,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          revealAnswer: revealAnswer,
        ),
        if (question.type == QuestionType.assertionReason) _AssertionReasonOptions(
          question: question,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          revealAnswer: revealAnswer,
        ),
        if (question.type == QuestionType.numeric) _NumericInput(
          question: question,
          controller: numericController,
          submitted: numericSubmitted ?? false,
        ),
        if (question.type == QuestionType.caseBased) _CaseBasedParts(
          question: question,
          partSelections: partSelections,
          onSelectPart: onSelectPart,
          partNumericControllers: partNumericControllers,
          revealAnswer: revealAnswer,
        ),
      ],
    );
  }
}

class _StemCard extends StatelessWidget {
  const _StemCard({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DifficultyPips(difficulty: question.difficulty),
              const Spacer(),
              _MarksBadge(marks: question.marks),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          if (question.type == QuestionType.assertionReason) ...[
            _LabeledText(label: 'Assertion (A)', text: question.assertion ?? ''),
            const SizedBox(height: 12),
            _LabeledText(label: 'Reason (R)', text: question.reason ?? ''),
          ] else
            Text(
              question.stem,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
        ],
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
      ],
    );
  }
}

class _DifficultyPips extends StatelessWidget {
  const _DifficultyPips({required this.difficulty});
  final int difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final filled = i < difficulty;
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: filled ? AppColors.brand : AppColors.border,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _MarksBadge extends StatelessWidget {
  const _MarksBadge({required this.marks});
  final int marks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        '$marks ${marks == 1 ? 'mark' : 'marks'}',
        style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _McqOptions extends StatelessWidget {
  const _McqOptions({
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
    required this.revealAnswer,
  });

  final Question question;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool revealAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(question.options.length, (i) {
        final isSelected = selectedIndex == i;
        final isCorrect = i == question.correctIndex;

        Color bg = AppColors.surface;
        Color border = AppColors.border;
        Color text = AppColors.ink;
        Widget? trailing;

        if (revealAnswer) {
          if (isCorrect) {
            bg = AppColors.masteredLight;
            border = AppColors.mastered;
            text = AppColors.masteredDark;
            trailing = const Icon(Icons.check_circle_rounded, color: AppColors.mastered);
          } else if (isSelected) {
            bg = AppColors.weakLight;
            border = AppColors.weak;
            text = AppColors.weakDark;
            trailing = const Icon(Icons.cancel_rounded, color: AppColors.weak);
          }
        } else if (isSelected) {
          bg = AppColors.brandLight;
          border = AppColors.brand;
          text = AppColors.brandDark;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: revealAnswer ? null : () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: border, width: isSelected || (revealAnswer && isCorrect) ? 2 : 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question.options[i],
                      style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AssertionReasonOptions extends StatelessWidget {
  const _AssertionReasonOptions({
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
    required this.revealAnswer,
  });

  final Question question;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool revealAnswer;

  @override
  Widget build(BuildContext context) {
    // Assertion-Reason uses the same rendering as MCQ (4 CBSE-standard options).
    return _McqOptions(
      question: question,
      selectedIndex: selectedIndex,
      onSelect: onSelect,
      revealAnswer: revealAnswer,
    );
  }
}

class _NumericInput extends StatelessWidget {
  const _NumericInput({required this.question, required this.controller, required this.submitted});

  final Question question;
  final TextEditingController? controller;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: submitted ? AppColors.brand : AppColors.border, width: submitted ? 2 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !submitted,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Type your answer',
              ),
            ),
          ),
          if (question.unit != null && question.unit != 'none')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                question.unit!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.inkFaint),
              ),
            ),
        ],
      ),
    );
  }
}

class _CaseBasedParts extends StatelessWidget {
  const _CaseBasedParts({
    required this.question,
    required this.partSelections,
    required this.onSelectPart,
    required this.partNumericControllers,
    required this.revealAnswer,
  });

  final Question question;
  final Map<int, int?> partSelections;
  final void Function(int partIndex, int optionIndex)? onSelectPart;
  final Map<int, TextEditingController> partNumericControllers;
  final bool revealAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: question.parts.asMap().entries.map((entry) {
        final i = entry.key;
        final part = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space16),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Part ${i + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 6),
                Text(part.stem, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (part.type == QuestionType.mcq)
                  _McqOptions(
                    question: part,
                    selectedIndex: partSelections[i],
                    onSelect: (opt) => onSelectPart?.call(i, opt),
                    revealAnswer: revealAnswer,
                  ),
                if (part.type == QuestionType.numeric)
                  _NumericInput(
                    question: part,
                    controller: partNumericControllers[i],
                    submitted: revealAnswer,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

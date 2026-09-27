import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/mission_state.dart';
import '../../data/models.dart';
import '../../shared/widgets/chunky_button.dart';
import 'question_card.dart';
import 'workout_complete_screen.dart';

enum _Section { warmUp, strength, challenge }

class _WorkoutItem {
  _WorkoutItem({required this.question, required this.section}) {
    for (var i = 0; i < question.parts.length; i++) {
      if (question.parts[i].type == QuestionType.numeric) {
        partNumericControllers[i] = TextEditingController();
      }
    }
  }

  final Question question;
  final _Section section;
  int hintsRevealed = 0;
  bool submitted = false;
  bool? wasCorrect;
  int? selectedIndex;
  final TextEditingController numericController = TextEditingController();

  /// case_based only: part index -> selected mcq option index.
  final Map<int, int?> partSelections = {};

  /// case_based only: part index -> numeric input controller.
  final Map<int, TextEditingController> partNumericControllers = {};

  /// The outcome of the FIRST submission only. This is what mastery and
  /// mistake-tracking are built from — a workout is treated like a small
  /// exam: retrying is allowed as practice (so the student still gets the
  /// learning value of trying again), but it can't rewrite what actually
  /// happened on attempt one, the same way a retake can't undo a real exam.
  bool? firstAttemptCorrect;

  void disposePartControllers() {
    for (final c in partNumericControllers.values) {
      c.dispose();
    }
  }
}

/// S6. Workout player — docs/PLAN.md §3: warm-up/strength/challenge sections,
/// submit feedback (green pulse / gentle shake), hint ladder.
///
/// Retry is exam-like by design: a student may retry for practice after a
/// wrong answer, but only the first submission is recorded into mastery and
/// mistake-tracking (`firstAttemptCorrect`). This mirrors how a real exam
/// works — you don't get to silently redo a wrong answer and have it count
/// as right — while still letting the student learn from a second attempt.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.concepts}) : singleLevelQuestion = null;

  const WorkoutScreen.singleLevel(Question level, {super.key})
      : concepts = const [],
        singleLevelQuestion = level;

  final List<Concept> concepts;
  final Question? singleLevelQuestion;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> with SingleTickerProviderStateMixin {
  late final List<_WorkoutItem> _items;
  int _index = 0;
  bool _usedRetry = false;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _items = _buildWorkout();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    for (final item in _items) {
      item.numericController.addListener(() => setState(() {}));
      for (final c in item.partNumericControllers.values) {
        c.addListener(() => setState(() {}));
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (final item in _items) {
      item.numericController.dispose();
      item.disposePartControllers();
    }
    super.dispose();
  }

  List<_WorkoutItem> _buildWorkout() {
    final singleLevel = widget.singleLevelQuestion;
    if (singleLevel != null) {
      return [_WorkoutItem(question: singleLevel, section: _Section.strength)];
    }

    final all = <_WorkoutItem>[];
    final pool = widget.concepts.expand((c) => Content.forConcept(c.id)).toList();
    if (pool.isEmpty) return all;

    final warmUp = pool.where((q) => q.difficulty == 1).take(3).toList();
    final strength = pool.where((q) => q.difficulty == 2).take(5).toList();
    final challenge = pool.where((q) => q.difficulty >= 2).skip(strength.length).take(2).toList();

    // Fallback: if a bucket is thin (small mock content set), backfill from
    // the full pool so the workout always has something to show.
    final used = <String>{};
    void addAll(List<Question> qs, _Section s) {
      for (final q in qs) {
        if (used.add(q.id)) all.add(_WorkoutItem(question: q, section: s));
      }
    }

    addAll(warmUp, _Section.warmUp);
    addAll(strength, _Section.strength);
    addAll(challenge, _Section.challenge);
    if (all.length < 5) {
      addAll(pool, _Section.strength);
    }
    return all.take(10).toList();
  }

  _WorkoutItem get _current => _items[_index];

  bool _isCorrect(_WorkoutItem item) {
    final q = item.question;
    if (q.type == QuestionType.caseBased) {
      for (var i = 0; i < q.parts.length; i++) {
        final part = q.parts[i];
        if (part.type == QuestionType.numeric) {
          final input = item.partNumericControllers[i]?.text.trim().replaceAll(' ', '') ?? '';
          if (input != part.numericAnswer) return false;
        } else {
          if (item.partSelections[i] != part.correctIndex) return false;
        }
      }
      return q.parts.isNotEmpty;
    }
    if (q.type == QuestionType.numeric) {
      final input = item.numericController.text.trim().replaceAll(' ', '');
      return input == q.numericAnswer;
    }
    return item.selectedIndex == q.correctIndex;
  }

  void _submit() {
    final item = _current;
    final correct = _isCorrect(item);
    final isFirstAttempt = item.firstAttemptCorrect == null;

    setState(() {
      item.submitted = true;
      item.wasCorrect = correct;
      if (isFirstAttempt) item.firstAttemptCorrect = correct;
    });
    if (!correct) {
      _shakeController.forward(from: 0);
    }

    // Only the first attempt counts toward mastery and mistake-tracking —
    // a retry is practice, not a do-over of the record.
    if (isFirstAttempt) {
      for (final conceptId in item.question.conceptIds) {
        ref.read(studentProvider.notifier).recordAttempt(
              questionId: item.question.id,
              conceptId: conceptId,
              correct: correct,
              hintsUsed: item.hintsRevealed,
            );
      }
      if (correct) {
        ref.read(studentProvider.notifier).addXp(item.question.marks * 5);
      }
    }
  }

  void _retry() {
    setState(() {
      _current.submitted = false;
      _current.wasCorrect = null;
      _usedRetry = true;
    });
  }

  void _next() {
    final singleLevel = widget.singleLevelQuestion;
    if (singleLevel != null) {
      final item = _items.first;
      final chapter = Content.chapterOf(singleLevel.conceptId);
      ref.read(levelProgressProvider.notifier).completeLevel(
            chapterId: chapter.id,
            level: singleLevel.level!,
            score: (item.firstAttemptCorrect ?? false) ? 1.0 : 0.0,
          );
      Navigator.of(context).pop();
      return;
    }

    if (_index == _items.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutCompleteScreen(
            items: _items
                .map((i) => WorkoutResultItem(
                      concept: Content.conceptById(i.question.conceptId),
                      // The score reflects the first attempt, exam-style —
                      // a later retry is practice and doesn't inflate it.
                      correct: i.firstAttemptCorrect ?? false,
                    ))
                .toList(),
          ),
        ),
      );
    } else {
      setState(() {
        _index++;
        _usedRetry = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('No questions available for this workout yet.')),
      );
    }

    final item = _current;
    final canSubmit = switch (item.question.type) {
      QuestionType.numeric => item.numericController.text.trim().isNotEmpty,
      QuestionType.caseBased => item.question.parts.asMap().entries.every((e) {
          final i = e.key;
          final part = e.value;
          if (part.type == QuestionType.numeric) {
            return (item.partNumericControllers[i]?.text.trim() ?? '').isNotEmpty;
          }
          return item.partSelections[i] != null;
        }),
      _ => item.selectedIndex != null,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            _SectionBadge(section: item.section),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: (_index + 1) / _items.length,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.brand),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.space16),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final t = _shakeController.value;
                      final offset = (t == 0 || t == 1) ? 0.0 : (t < 0.5 ? -8.0 : 8.0) * (1 - t) * 2;
                      return Transform.translate(offset: Offset(offset, 0), child: child);
                    },
                    child: Column(
                      children: [
                        QuestionCard(
                          question: item.question,
                          selectedIndex: item.selectedIndex,
                          revealAnswer: item.submitted && item.question.type != QuestionType.numeric,
                          numericController: item.numericController,
                          numericSubmitted: item.submitted,
                          onSelect: item.submitted
                              ? (_) {}
                              : (i) => setState(() => item.selectedIndex = i),
                          partSelections: item.partSelections,
                          onSelectPart: item.submitted
                              ? null
                              : (i, opt) => setState(() => item.partSelections[i] = opt),
                          partNumericControllers: item.partNumericControllers,
                        ),
                        if (item.hintsRevealed > 0 && !item.submitted) ...[
                          const SizedBox(height: AppTheme.space16),
                          _HintsPanel(hints: item.question.hints.take(item.hintsRevealed).toList()),
                        ],
                        if (item.submitted) ...[
                          const SizedBox(height: AppTheme.space16),
                          _FeedbackPanel(
                            correct: item.wasCorrect ?? false,
                            question: item.question,
                            selectedIndex: item.selectedIndex,
                            isRetryAttempt: _usedRetry,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              _BottomBar(
                item: item,
                canSubmit: canSubmit,
                usedRetry: _usedRetry,
                onHint: () => setState(() {
                  if (item.hintsRevealed < item.question.hints.length) item.hintsRevealed++;
                }),
                onSubmit: _submit,
                onRetry: _retry,
                onNext: _next,
                onRebuild: () => setState(() {}),
              ),
              const SizedBox(height: AppTheme.space16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge({required this.section});
  final _Section section;

  @override
  Widget build(BuildContext context) {
    final (label, emoji) = switch (section) {
      _Section.warmUp => ('Warm-up', '🔥'),
      _Section.strength => ('Strength', '💪'),
      _Section.challenge => ('Challenge', '🧠'),
    };
    return Text('$emoji $label', style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _HintsPanel extends StatelessWidget {
  const _HintsPanel({required this.hints});
  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hints
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: EdgeInsets.only(top: e.key > 0 ? 8 : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 ', style: Theme.of(context).textTheme.bodyLarge),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.correct,
    required this.question,
    required this.selectedIndex,
    this.isRetryAttempt = false,
  });
  final bool correct;
  final Question question;
  final int? selectedIndex;
  final bool isRetryAttempt;

  String? get _misconceptionNote {
    if (correct || selectedIndex == null) return null;
    final match = question.distractors.where((d) => d.optionIndex == selectedIndex).toList();
    return match.isNotEmpty ? match.first.explanation : null;
  }

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.mastered : AppColors.weak;
    final lightColor = correct ? AppColors.masteredLight : AppColors.weakLight;
    final darkColor = correct ? AppColors.masteredDark : AppColors.weakDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                correct ? 'Correct!' : 'Not yet',
                style: TextStyle(color: darkColor, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          if (_misconceptionNote != null) ...[
            const SizedBox(height: 8),
            Text(_misconceptionNote!, style: TextStyle(color: darkColor, fontWeight: FontWeight.w600)),
          ],
          if (isRetryAttempt) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: darkColor.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'This retry is just for practice — your first answer is what counts.',
                    style: TextStyle(color: darkColor.withValues(alpha: 0.7), fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Show solution',
                style: TextStyle(color: darkColor, fontWeight: FontWeight.w800, fontSize: 13),
              ),
              iconColor: darkColor,
              collapsedIconColor: darkColor,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: question.solutionSteps
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('• $s', style: TextStyle(color: darkColor)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.item,
    required this.canSubmit,
    required this.usedRetry,
    required this.onHint,
    required this.onSubmit,
    required this.onRetry,
    required this.onNext,
    required this.onRebuild,
  });

  final _WorkoutItem item;
  final bool canSubmit;
  final bool usedRetry;
  final VoidCallback onHint;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onRebuild;

  @override
  Widget build(BuildContext context) {
    if (item.submitted) {
      if (!(item.wasCorrect ?? false) && !usedRetry) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.weak),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                child: const Text('Try again', style: TextStyle(color: AppColors.weak, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ChunkyButton(label: 'Continue', color: AppColors.weak, onPressed: onNext),
            ),
          ],
        );
      }
      return ChunkyButton(
        label: 'Continue',
        color: item.wasCorrect ?? false ? AppColors.mastered : AppColors.weak,
        onPressed: onNext,
      );
    }

    return Column(
      children: [
        if (item.question.hints.isNotEmpty && item.hintsRevealed < item.question.hints.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextButton.icon(
              onPressed: onHint,
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.brand),
              label: Text(
                item.hintsRevealed == 0 ? 'Get a hint' : 'Get another hint',
                style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ChunkyButton(label: 'Submit', onPressed: canSubmit ? onSubmit : null),
      ],
    );
  }
}

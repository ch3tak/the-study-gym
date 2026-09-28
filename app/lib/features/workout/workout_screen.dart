import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/daily_state.dart';
import '../../data/mission_state.dart';
import '../../data/models.dart';
import '../../data/node_progress_state.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/math_text.dart';
import 'numeric_grading.dart';
import 'question_card.dart';
import 'workout_complete_screen.dart';
import 'workout_selector.dart';

class _WorkoutItem {
  _WorkoutItem({required this.question, required this.section}) {
    for (var i = 0; i < question.parts.length; i++) {
      if (question.parts[i].type == QuestionType.numeric) {
        partNumericControllers[i] = TextEditingController();
      }
    }
  }

  final Question question;
  final WorkoutSection section;
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
  const WorkoutScreen({
    super.key,
    required this.concepts,
    this.kind = WorkoutKind.practice,
    this.exclude = const {},
  })  : singleLevelQuestion = null,
        nodeConcept = null,
        node = null;

  const WorkoutScreen.singleLevel(Question level, {super.key})
      : concepts = const [],
        kind = WorkoutKind.practice,
        exclude = const {},
        singleLevelQuestion = level,
        nodeConcept = null,
        node = null;

  /// One node of a topic (Guided, Practice, Spot the mistake, Challenge).
  /// A wrong answer comes back at the end; the node is passed once every
  /// question has been answered right, and the screen pops with `true`.
  const WorkoutScreen.node({super.key, required Concept concept, required TopicNode this.node})
      : concepts = const [],
        kind = WorkoutKind.practice,
        exclude = const {},
        singleLevelQuestion = null,
        nodeConcept = concept;

  final List<Concept> concepts;

  /// Daily and Keep going runs are recorded as workouts (Task 7).
  final WorkoutKind kind;

  /// Question ids already served today, kept out of a Keep going batch.
  final Set<String> exclude;
  final Question? singleLevelQuestion;
  final Concept? nodeConcept;
  final TopicNode? node;
  bool get isNodeSession => node != null;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> with SingleTickerProviderStateMixin {
  late final List<_WorkoutItem> _items;
  final DateTime _startedAt = DailyNotifier.clock();
  int _index = 0;
  bool _usedRetry = false;

  /// Whether a solution was opened (Trial levels: Platinum needs none).
  bool _solutionViewed = false;
  final Set<String> _recordedQuestionIds = {};
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
      return [_WorkoutItem(question: singleLevel, section: WorkoutSection.strength)];
    }

    final node = widget.node;
    if (node != null) {
      return Content.nodeQuestions(widget.nodeConcept!.id, node)
          .map((q) => _WorkoutItem(question: q, section: WorkoutSection.strength))
          .toList();
    }

    final count = widget.kind == WorkoutKind.practice ? practiceWorkoutSize : dailyWorkoutSize;
    return selectWorkout(widget.concepts, count: count, exclude: widget.exclude)
        .map((s) => _WorkoutItem(question: s.question, section: s.section))
        .toList();
  }

  _WorkoutItem get _current => _items[_index];

  bool _isCorrect(_WorkoutItem item) {
    final q = item.question;
    if (q.type == QuestionType.caseBased) {
      for (var i = 0; i < q.parts.length; i++) {
        final part = q.parts[i];
        if (part.type == QuestionType.numeric) {
          if (!isNumericAnswerCorrect(part, item.partNumericControllers[i]?.text ?? '')) return false;
        } else {
          if (item.partSelections[i] != part.correctIndex) return false;
        }
      }
      return q.parts.isNotEmpty;
    }
    if (q.type == QuestionType.numeric) {
      return isNumericAnswerCorrect(q, item.numericController.text);
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
    final level = widget.singleLevelQuestion;
    if (level != null && isFirstAttempt && !correct) {
      // Remembered past this visit: passing the level later is not "right
      // first time".
      ref
          .read(levelProgressProvider.notifier)
          .noteWrongFirstAttempt(chapterId: Content.chapterOf(level.conceptId).id, level: level.level!);
    }

    // Only the first attempt counts toward mastery and mistake-tracking —
    // a retry is practice, not a do-over of the record — and only a
    // question's first attempt ever counts, even when a node session brings
    // it back at the end.
    if (isFirstAttempt && _recordedQuestionIds.add(item.question.id)) {
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

  void _onSolutionOpened() {
    _solutionViewed = true;
    final level = widget.singleLevelQuestion;
    if (level != null) {
      ref
          .read(levelProgressProvider.notifier)
          .noteSolutionViewed(chapterId: Content.chapterOf(level.conceptId).id, level: level.level!);
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
      // A level is passed only by a correct answer. The latest attempt
      // counts for *progression* (so getting it right on the practice retry
      // still passes the level), while the recorded score stays exam-style
      // and reflects the first attempt only — a retry never rewrites the
      // record, it just stops the student being stuck. A wrong answer pops
      // back without completing, so the level stays open for another go and
      // the next level stays locked.
      if (item.wasCorrect ?? false) {
        final chapter = Content.chapterOf(singleLevel.conceptId);
        ref.read(levelProgressProvider.notifier).completeLevel(
              chapterId: chapter.id,
              level: singleLevel.level!,
              score: (item.firstAttemptCorrect ?? false) ? 1.0 : 0.0,
              solutionViewed: _solutionViewed,
            );
      }
      Navigator.of(context).pop();
      return;
    }

    final item = _current;
    if (widget.isNodeSession && !(item.wasCorrect ?? false)) {
      // A wrong question comes back at the end of the node.
      final again = _WorkoutItem(question: item.question, section: item.section);
      again.numericController.addListener(() => setState(() {}));
      for (final c in again.partNumericControllers.values) {
        c.addListener(() => setState(() {}));
      }
      _items.add(again);
    }
    if (widget.isNodeSession && _index == _items.length - 1) {
      ref.read(nodeProgressProvider.notifier).passNode(widget.nodeConcept!.id, widget.node!);
      Navigator.of(context).pop(true);
      return;
    }

    if (_index == _items.length - 1) {
      final results = _items
          .map((i) => WorkoutResultItem(
                concept: Content.conceptById(i.question.conceptId),
                // The score reflects the first attempt, exam-style — a
                // later retry is practice and doesn't inflate it.
                correct: i.firstAttemptCorrect ?? false,
              ))
          .toList();
      if (widget.kind != WorkoutKind.practice) {
        ref.read(dailyProvider.notifier).recordWorkout(
              questionIds: _items.map((i) => i.question.id).toList(),
              correct: results.where((r) => r.correct).length,
              total: results.length,
              keepGoing: widget.kind == WorkoutKind.keepGoing,
              startedAt: _startedAt,
            );
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WorkoutCompleteScreen(items: results, kind: widget.kind)),
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
      // `every` over an empty list is vacuously true, so a malformed
      // case_based item with no parts must be explicitly non-submittable.
      QuestionType.caseBased => item.question.parts.isNotEmpty &&
          item.question.parts.asMap().entries.every((e) {
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
            widget.node != null
                ? Text(widget.node!.label, style: Theme.of(context).textTheme.bodyMedium)
                : _SectionBadge(section: item.section),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: (_index + 1) / _items.length,
                minHeight: 8,
                backgroundColor: context.colors.border,
                valueColor: AlwaysStoppedAnimation(context.colors.brand),
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
                            onSolutionOpened: _onSolutionOpened,
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
                allowRetry: !widget.isNodeSession,
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
  final WorkoutSection section;

  @override
  Widget build(BuildContext context) {
    final (label, emoji) = switch (section) {
      WorkoutSection.warmUp => ('Warm-up', '🔥'),
      WorkoutSection.strength => ('Strength', '💪'),
      WorkoutSection.challenge => ('Challenge', '🧠'),
    };
    return Text('$emoji $label', style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _HintsPanel extends StatelessWidget {
  const _HintsPanel({required this.hints});
  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.brandLight,
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
                        child: MathText(
                          e.value,
                          style: TextStyle(color: colors.brandDark, fontWeight: FontWeight.w700),
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
    this.onSolutionOpened,
  });
  final bool correct;
  final Question question;
  final int? selectedIndex;
  final bool isRetryAttempt;
  final VoidCallback? onSolutionOpened;

  String? get _misconceptionNote {
    if (correct || selectedIndex == null) return null;
    final match = question.distractors.where((d) => d.optionIndex == selectedIndex).toList();
    return match.isNotEmpty ? match.first.explanation : null;
  }

  List<Widget> _steps(List<String> steps, Color color) => steps
      .map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: MathText('• $s', style: TextStyle(color: color)),
          ))
      .toList();

  /// A case_based question's own hints/solutionSteps are empty — the real
  /// worked solution lives on each part — so group each part's steps under
  /// a "Part N" heading (matching `_CaseBasedParts`' labelling). A part
  /// with no solution steps falls back to showing its hints.
  List<Widget> _caseBasedSolution(Color color) {
    final widgets = <Widget>[..._steps(question.solutionSteps, color)];
    for (var i = 0; i < question.parts.length; i++) {
      final part = question.parts[i];
      final hasSteps = part.solutionSteps.isNotEmpty;
      if (!hasSteps && part.hints.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Text('Part ${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ));
      widgets.addAll(hasSteps
          ? _steps(part.solutionSteps, color)
          : _steps(part.hints.map((h) => 'Hint: $h').toList(), color));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = correct ? colors.mastered : colors.weak;
    final lightColor = correct ? colors.masteredLight : colors.weakLight;
    final darkColor = correct ? colors.masteredDark : colors.weakDark;

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
            MathText(_misconceptionNote!, style: TextStyle(color: darkColor, fontWeight: FontWeight.w600)),
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
              onExpansionChanged: (open) {
                if (open) onSolutionOpened?.call();
              },
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
                    children: question.type == QuestionType.caseBased
                        ? _caseBasedSolution(darkColor)
                        : _steps(question.solutionSteps, darkColor),
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
    required this.allowRetry,
    required this.onHint,
    required this.onSubmit,
    required this.onRetry,
    required this.onNext,
    required this.onRebuild,
  });

  final _WorkoutItem item;
  final bool canSubmit;
  final bool usedRetry;

  /// False in node sessions, where a wrong question comes back at the end
  /// instead.
  final bool allowRetry;
  final VoidCallback onHint;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onRebuild;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (item.submitted) {
      if (!(item.wasCorrect ?? false) && !usedRetry && allowRetry) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colors.weak),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                child: Text('Try again', style: TextStyle(color: colors.weak, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ChunkyButton(label: 'Continue', color: colors.weak, onPressed: onNext),
            ),
          ],
        );
      }
      return ChunkyButton(
        label: 'Continue',
        color: item.wasCorrect ?? false ? colors.mastered : colors.weak,
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
              icon: Icon(Icons.lightbulb_outline_rounded, size: 18, color: colors.brand),
              label: Text(
                item.hintsRevealed == 0 ? 'Get a hint' : 'Get another hint',
                style: TextStyle(color: colors.brand, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ChunkyButton(label: 'Submit', onPressed: canSubmit ? onSubmit : null),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/chapter_progress.dart';
import '../../data/content.dart';
import '../../data/daily_state.dart';
import '../../data/fading.dart';
import '../../data/models.dart';
import '../../shared/widgets/course_chip.dart';
import '../../shared/widgets/streak_flame.dart';
import '../chapter/next_step_navigation.dart';
import '../workout/keep_going.dart';
import '../workout/workout_screen.dart';
import '../workout/workout_selector.dart';

/// Home: one big next step (spec: "Home"). Before today's workout the hero
/// is the Daily Workout; after it, Continue your chapter.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DailyNotifier.clock();
    final daily = ref.watch(dailyProvider);
    final student = ref.watch(studentProvider);
    final course = ref.watch(courseProgressProvider);
    final streak = daily.streakOn(now);
    final done = daily.workoutDoneOn(now);
    // Only topics a review can actually drill.
    final fading = fadingConcepts(student, now).where((c) => Content.practiceQuestions(c.id).isNotEmpty).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, AppTheme.space32),
          children: [
            Row(children: [const CourseChip(), const Spacer(), StreakFlame(count: streak)]),
            const SizedBox(height: AppTheme.space20),
            if (done)
              _ContinueCard(course: course)
            else
              _WorkoutHero(streak: streak, concepts: pickWorkoutConcepts(student)),
            const SizedBox(height: AppTheme.space20),
            _WeekCard(days: daily.weekOf(now)),
            if (done && daily.firstWorkoutOn(now) != null) ...[
              const SizedBox(height: AppTheme.space12),
              _WorkoutDoneRow(record: daily.firstWorkoutOn(now)!),
            ],
            if (fading.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space12),
              _NeedsAttention(concepts: fading),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({required this.streak, required this.concepts});
  final int streak;
  final List<Concept> concepts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('workout_hero'),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(color: colors.brand, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            streak > 0 ? 'Keep your $streak-day streak going' : 'Start your streak',
            style: textTheme.headlineMedium?.copyWith(color: colors.accentInk),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            concepts.isEmpty
                ? 'No practice questions are available yet.'
                : '5 questions · ${concepts.map((c) => c.name).join(', ')}',
            style: textTheme.bodyMedium?.copyWith(color: colors.accentInk.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: AppTheme.space20),
          _WhiteButton(
            label: 'Start workout',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => WorkoutScreen(concepts: concepts, kind: WorkoutKind.daily),
            )),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.course});
  final CourseProgress course;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final chapter = course.current;
    if (chapter == null) {
      return Container(
        key: const ValueKey('continue_card'),
        padding: const EdgeInsets.all(AppTheme.space24),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        child: Text('Nothing to continue yet.', style: textTheme.titleMedium),
      );
    }
    final step = chapter.nextStep;
    final position = nextStepPosition(chapter, step);
    return Container(
      key: const ValueKey('continue_card'),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(color: colors.brand, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chapter.isStarted ? 'Continue your chapter' : 'Start your first chapter',
            style: textTheme.titleMedium?.copyWith(color: colors.accentInk.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(chapter.chapter.name, style: textTheme.headlineMedium?.copyWith(color: colors.accentInk)),
          if (position.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space4),
            Text(position, style: textTheme.bodyMedium?.copyWith(color: colors.accentInk.withValues(alpha: 0.8))),
          ],
          const SizedBox(height: AppTheme.space20),
          _WhiteButton(label: 'Continue', onPressed: () => openNextStep(context, chapter, step)),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.days});
  final List<DayState> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: const ValueKey('week_row'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: WeekDotsRow(days: days),
    );
  }
}

class _WorkoutDoneRow extends ConsumerWidget {
  const _WorkoutDoneRow({required this.record});
  final WorkoutRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      key: const ValueKey('workout_done_row'),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
      decoration: BoxDecoration(color: colors.masteredLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.mastered),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text('Daily workout · ${record.correct} / ${record.total}',
                style: TextStyle(color: colors.masteredDark, fontWeight: FontWeight.w800)),
          ),
          TextButton(onPressed: () => startKeepGoing(context, ref), child: const Text('Keep going')),
        ],
      ),
    );
  }
}

class _NeedsAttention extends StatelessWidget {
  const _NeedsAttention({required this.concepts});
  final List<Concept> concepts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final n = concepts.length;
    return Material(
      color: colors.learningLight,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        key: const ValueKey('needs_attention'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WorkoutScreen(concepts: concepts))),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              Icon(Icons.refresh_rounded, color: colors.learningDark),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Text('$n ${n == 1 ? 'topic' : 'topics'} fading · Review',
                    style: TextStyle(color: colors.learningDark, fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.learningDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteButton extends StatefulWidget {
  const _WhiteButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_WhiteButton> createState() => _WhiteButtonState();
}

class _WhiteButtonState extends State<_WhiteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        height: 56 + 5,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              top: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.accentInk.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              top: _pressed ? 5 : 0,
              left: 0,
              right: 0,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(color: colors.brand, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

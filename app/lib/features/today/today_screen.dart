import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../shared/widgets/mastery_ring.dart';
import '../../shared/widgets/streak_flame.dart';
import '../workout/workout_screen.dart';

/// S5. Today tab — docs/PLAN.md §3: hero workout card, streak + week dots,
/// review-due nudge, Board-Readiness mini-gauge.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    final weak = student.weakConcepts;
    final workoutConcepts = _pickWorkoutConcepts(student);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space20,
                  AppTheme.space16,
                  AppTheme.space20,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today', style: Theme.of(context).textTheme.headlineLarge),
                    Row(
                      children: [
                        _DailyGoalRing(progress: student.dailyGoalProgress, met: student.dailyGoalMet),
                        const SizedBox(width: 14),
                        StreakFlame(count: student.streak),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.space20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WorkoutHeroCard(concepts: workoutConcepts),
                  const SizedBox(height: AppTheme.space20),
                  _DailyGoalCard(xpToday: student.xpToday, goal: student.dailyXpGoal),
                  const SizedBox(height: AppTheme.space20),
                  _StreakCard(streak: student.streak),
                  const SizedBox(height: AppTheme.space20),
                  if (weak.isNotEmpty) ...[
                    _ReviewDueCard(concepts: weak),
                    const SizedBox(height: AppTheme.space20),
                  ],
                  _ReadinessCard(percent: student.overallReadiness),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Concept> _pickWorkoutConcepts(StudentState student) {
    final entries = student.mastery.values.toList()
      ..sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));
    final picked = entries
        .map((m) => Content.conceptOrNull(m.conceptId))
        .whereType<Concept>()
        .take(3)
        .toList();
    if (picked.isEmpty) {
      return Content.chapters.first.concepts.take(3).toList();
    }
    return picked;
  }
}

/// Small daily-goal indicator in the header, next to the streak — a
/// Duolingo-style at-a-glance "am I done for today" signal.
class _DailyGoalRing extends StatelessWidget {
  const _DailyGoalRing({required this.progress, required this.met});
  final double progress;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MasteryRing(
      progress: progress,
      size: 28,
      strokeWidth: 3.5,
      trackColor: colors.border,
      child: Icon(
        met ? Icons.check_rounded : Icons.flag_rounded,
        size: 14,
        color: met ? colors.mastered : colors.inkFaint,
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.xpToday, required this.goal});
  final int xpToday;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = goal == 0 ? 0.0 : (xpToday / goal).clamp(0.0, 1.0);
    final met = xpToday >= goal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            met ? Icons.emoji_events_rounded : Icons.flag_rounded,
            color: met ? colors.xp : colors.brand,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Daily goal', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      met ? 'Goal reached! 🎉' : '$xpToday / $goal XP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: met ? colors.mastered : colors.inkFaint,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation(met ? colors.mastered : colors.brand),
                    ),
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

class _WorkoutHeroCard extends StatelessWidget {
  const _WorkoutHeroCard({required this.concepts});
  final List<Concept> concepts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: colors.accentInk, size: 22),
              const SizedBox(width: 6),
              Text(
                "Today's workout",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.accentInk.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '15 min · 10 reps',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: colors.accentInk),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: concepts
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.accentInk.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        c.name,
                        style: TextStyle(color: colors.accentInk, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _WhiteButton(
            label: 'Start workout',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WorkoutScreen(concepts: concepts)),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A white variant of the chunky button, for use on the brand-colored hero card.
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

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});
  final int streak;

  List<DayState> _weekStates() {
    // Simple mock: last `streak` days done (up to 7), rest is today/future.
    final states = List.generate(7, (i) => DayState.future);
    final todayIndex = (streak - 1).clamp(0, 6);
    for (var i = 0; i < todayIndex; i++) {
      states[i] = DayState.done;
    }
    if (todayIndex < 7) states[todayIndex] = DayState.today;
    return states;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('This week', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              StreakFlame(count: streak, size: 22),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          WeekDotsRow(days: _weekStates()),
        ],
      ),
    );
  }
}

class _ReviewDueCard extends StatelessWidget {
  const _ReviewDueCard({required this.concepts});
  final List<Concept> concepts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.learningLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Icon(Icons.refresh_rounded, color: colors.learningDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${concepts.length} concepts are fading. Quick refresh?',
              style: TextStyle(color: colors.learningDark, fontWeight: FontWeight.w700),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.learningDark),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marks = (percent * 80).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          MasteryRing(
            progress: percent,
            size: 64,
            strokeWidth: 7,
            child: Text('$marks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exam readiness', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '~$marks / 80 marks based on what you\'ve practised so far',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

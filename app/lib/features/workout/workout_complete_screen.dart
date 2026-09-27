import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_shell.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/mastery_ring.dart';

class WorkoutResultItem {
  const WorkoutResultItem({required this.concept, required this.correct});
  final Concept concept;
  final bool correct;
}

/// S7. Workout complete — docs/PLAN.md §3: score, XP, streak update,
/// per-concept mastery bars animating old → new, coach message, share/done.
class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  const WorkoutCompleteScreen({super.key, required this.items});

  final List<WorkoutResultItem> items;

  @override
  ConsumerState<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends ConsumerState<WorkoutCompleteScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    final correctCount = widget.items.where((i) => i.correct).length;
    if (correctCount >= widget.items.length * 0.6) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _coachMessage(int correct, int total) {
    final ratio = total == 0 ? 0 : correct / total;
    if (ratio >= 0.9) {
      return "Outstanding work! You're really getting the hang of this — keep up this pace and boards will feel easy.";
    } else if (ratio >= 0.6) {
      return "Solid session! A couple of concepts need one more pass, but you're moving in the right direction.";
    }
    return "Good effort showing up today. Tomorrow we'll go over the tricky ones again — that's how mastery works.";
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final student = ref.watch(studentProvider);
    final correctCount = widget.items.where((i) => i.correct).length;
    final total = widget.items.length;
    final xpEarned = student.xpToday;

    // Distinct concepts touched this workout, for the mastery-bar list.
    final seen = <String>{};
    final uniqueConcepts = <Concept>[];
    for (final item in widget.items) {
      if (seen.add(item.concept.id)) uniqueConcepts.add(item.concept);
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.space16),
                  Text('$correctCount/$total', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48)),
                  const SizedBox(height: 4),
                  Text('Workout complete!', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppTheme.space24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatPill(icon: Icons.star_rounded, color: colors.xp, label: '+$xpEarned XP'),
                      const SizedBox(width: 12),
                      _StatPill(
                        icon: Icons.local_fire_department_rounded,
                        color: colors.streak,
                        label: '${student.streak} day streak',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Mastery progress', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  ...uniqueConcepts.map((c) => _MasteryBarRow(concept: c)),
                  const SizedBox(height: AppTheme.space24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: colors.brandLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🧑‍🏫', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _coachMessage(correctCount, total),
                            style: TextStyle(color: colors.brandDark, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing to parent (mocked) 📤')),
                      );
                    },
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share with parent'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                      side: BorderSide(color: colors.border),
                      foregroundColor: colors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  ChunkyButton(
                    label: 'Done',
                    color: colors.mastered,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AppShell()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              maxBlastForce: 12,
              minBlastForce: 6,
              emissionFrequency: 0.06,
              numberOfParticles: 16,
              gravity: 0.25,
              colors: [
                colors.brand,
                colors.mastered,
                colors.xp,
                colors.streak,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MasteryBarRow extends ConsumerWidget {
  const _MasteryBarRow({required this.concept});
  final Concept concept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mastery = ref.watch(studentProvider).mastery[concept.id];
    final percent = (mastery?.masteryPercent ?? 0) / 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          MasteryRing(progress: percent, size: 40, strokeWidth: 4),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(concept.name, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: percent),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation(
                        value >= 0.8 ? colors.mastered : (value >= 0.5 ? colors.learning : colors.weak),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(percent * 100).round()}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

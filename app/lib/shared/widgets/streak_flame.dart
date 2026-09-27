import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Streak flame + count, with a week-dots row (rest day shown as a moon).
/// Matches plan §3 S5: "Streak flame with a week dots row".
class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key, required this.count, this.size = 28});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lit = count > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          color: lit ? colors.streak : colors.notStarted,
          size: size,
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: lit ? colors.streak : colors.inkFaint,
                fontSize: size * 0.7,
              ),
        ),
      ],
    );
  }
}

enum DayState { done, rest, missed, today, future }

class WeekDotsRow extends StatelessWidget {
  const WeekDotsRow({super.key, required this.days, this.labels});

  final List<DayState> days; // Mon..Sun, length 7
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    const defaultLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final lbls = labels ?? defaultLabels;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (i) {
        return Column(
          children: [
            _Dot(state: days[i]),
            const SizedBox(height: 6),
            Text(
              lbls[i],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.inkFaint,
                    fontSize: 11,
                  ),
            ),
          ],
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final DayState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const dim = 32.0;
    switch (state) {
      case DayState.done:
        return Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            color: colors.streak,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
        );
      case DayState.rest:
        return Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            color: colors.brandLight,
            shape: BoxShape.circle,
            border: Border.all(color: colors.brand.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.nightlight_round, color: colors.brand, size: 16),
        );
      case DayState.missed:
        return Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            color: colors.notStartedLight,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Icon(Icons.close_rounded, color: colors.inkFaint, size: 16),
        );
      case DayState.today:
        return Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.brand, width: 2.5),
          ),
        );
      case DayState.future:
        return Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            color: colors.notStartedLight,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
        );
    }
  }
}

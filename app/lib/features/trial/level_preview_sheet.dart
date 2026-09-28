import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/math_text.dart';
import '../workout/workout_screen.dart';
import 'level_labels.dart';

/// The sheet shown before a Trial level starts (spec: "Tapping a level
/// opens a preview sheet").
Future<void> showLevelPreview(BuildContext context, {required Question level, required int number, required int total}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => LevelPreviewSheet(level: level, number: number, total: total),
  );
}

class LevelPreviewSheet extends StatelessWidget {
  const LevelPreviewSheet({super.key, required this.level, required this.number, required this.total});
  final Question level;
  final int number;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    // No short names exist yet, so a level is named after its topic.
    final name = Content.conceptOrNull(level.conceptId)?.name ?? 'Level ${level.level}';
    final why = level.whyAfterPrevious;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.space24, AppTheme.space16, AppTheme.space24, AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Level $number of $total · ${stageLabel(level.stage)}',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
            const SizedBox(height: AppTheme.space8),
            Text(name, style: textTheme.headlineMedium),
            const SizedBox(height: AppTheme.space8),
            Text('${questionTypeLabel(level.type)} · About ${estimatedMinutes(level)} min',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkFaint)),
            if (why != null) ...[
              const SizedBox(height: AppTheme.space16),
              Text('Why this comes next', style: textTheme.titleSmall),
              const SizedBox(height: AppTheme.space4),
              MathText(why, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: AppTheme.space24),
            ChunkyButton(
              label: 'Start level',
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(MaterialPageRoute<void>(builder: (_) => WorkoutScreen.singleLevel(level)));
              },
            ),
          ],
        ),
      ),
    );
  }
}

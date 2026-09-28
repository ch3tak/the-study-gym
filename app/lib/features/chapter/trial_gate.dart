import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../shared/widgets/chunky_button.dart';
import '../trial/trial_screen.dart';

/// Closes the chapter: a trophy, one seal per topic (broken when the topic
/// is finished), and the way into the Trial once every seal is broken.
class TrialGate extends StatelessWidget {
  const TrialGate({super.key, required this.progress});
  final ChapterProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final open = progress.trialUnlocked;
    return Container(
      key: const ValueKey('trial_gate'),
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: open ? colors.xp : colors.border, width: open ? 2 : 1),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 40, color: open ? colors.xp : colors.notStarted),
          const SizedBox(height: AppTheme.space8),
          Text('Chapter Trial', style: textTheme.titleLarge),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            spacing: AppTheme.space8,
            children: [
              for (final t in progress.topics)
                Icon(
                  t.isDone ? Icons.lock_open_rounded : Icons.lock_rounded,
                  key: ValueKey('seal_${t.concept.id}'),
                  color: t.isDone ? colors.mastered : colors.notStarted,
                  semanticLabel: t.isDone ? 'Seal broken: ${t.concept.name}' : 'Sealed: ${t.concept.name}',
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          if (!open)
            Text('Finish all ${progress.topics.length} topics to open the Trial',
                textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft))
          else ...[
            Text('${progress.levelsCleared} of ${progress.trialLevels.length} levels cleared',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
            const SizedBox(height: AppTheme.space12),
            ChunkyButton(
              label: progress.levelsCleared == 0 ? 'Open the Trial' : 'Continue the Trial',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => TrialScreen(chapterId: progress.chapter.id),
              )),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../data/mission_state.dart';
import '../../data/models.dart';
import '../../data/trial_trophy.dart';
import 'level_labels.dart';
import 'level_preview_sheet.dart';

/// The Chapter Trial (the old Mission path): the chapter's levels in their
/// five stages. Finished stages fold to one line, the current stage is a
/// winding path, later stages are single cards. Unlocking is unchanged:
/// positional, via LevelProgressState.isUnlocked.
class TrialScreen extends ConsumerWidget {
  const TrialScreen({super.key, required this.chapterId});
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final chapter = ref.watch(courseProgressProvider).chapter(chapterId);
    final progress = ref.watch(levelProgressProvider);

    if (chapter == null || !chapter.trialUnlocked) {
      final n = chapter?.topics.length ?? 0;
      return Scaffold(
        appBar: AppBar(title: const Text('Chapter Trial')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Text('Finish all $n topics to open the Trial', textAlign: TextAlign.center, style: textTheme.bodyLarge),
          ),
        ),
      );
    }

    final levels = chapter.trialLevels;
    final stages = <String>[];
    final byStage = <String, List<int>>{};
    for (var i = 0; i < levels.length; i++) {
      final s = levels[i].stage ?? '';
      if (!byStage.containsKey(s)) stages.add(s);
      byStage.putIfAbsent(s, () => []).add(i);
    }
    bool done(int i) => progress.isCompleted(chapterId, levels[i].level!);
    final firstOpen = List.generate(levels.length, (i) => i).where((i) => !done(i)).firstOrNull;
    final currentStage = firstOpen == null ? null : (levels[firstOpen].stage ?? '');

    return Scaffold(
      appBar: AppBar(title: Text('${chapter.chapter.name} · Trial')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space32),
        children: [
          _TrophyLine(
            trophy: trialTrophy(chapterId, levels, progress),
            cleared: chapter.levelsCleared,
            total: levels.length,
          ),
          const SizedBox(height: AppTheme.space16),
          for (final stage in stages) ...[
            if (byStage[stage]!.every(done))
              _FoldedStage(stage: stage, count: byStage[stage]!.length)
            else if (stage == currentStage)
              _CurrentStage(stage: stage, indexes: byStage[stage]!, levels: levels, chapterId: chapterId, progress: progress)
            else
              _FutureStage(stage: stage, count: byStage[stage]!.length),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }
}

class _TrophyLine extends StatelessWidget {
  const _TrophyLine({required this.trophy, required this.cleared, required this.total});
  final TrialTrophy trophy;
  final int cleared;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = switch (trophy) {
      TrialTrophy.platinum => 'Platinum trophy earned',
      TrialTrophy.gold => 'Gold trophy earned',
      TrialTrophy.none => '$cleared of $total levels cleared · Gold for finishing, '
          'Platinum for 90% right first time with no solutions viewed',
    };
    return Row(
      children: [
        Icon(Icons.emoji_events_rounded, color: trophy == TrialTrophy.none ? colors.notStarted : colors.xp),
        const SizedBox(width: AppTheme.space8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkSoft))),
      ],
    );
  }
}

class _FoldedStage extends StatelessWidget {
  const _FoldedStage({required this.stage, required this.count});
  final String stage;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: ValueKey('trial_stage_${stage}_folded'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(color: colors.masteredLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.mastered),
          const SizedBox(width: AppTheme.space8),
          Text('${stageLabel(stage)} · $count / $count',
              style: TextStyle(color: colors.masteredDark, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _FutureStage extends StatelessWidget {
  const _FutureStage({required this.stage, required this.count});
  final String stage;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: ValueKey('trial_stage_${stage}_future'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: colors.inkFaint),
          const SizedBox(width: AppTheme.space8),
          Text('${stageLabel(stage)} · $count levels', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

const _windingOffsets = [0.0, 56.0, 112.0, 56.0];

class _CurrentStage extends StatelessWidget {
  const _CurrentStage({
    required this.stage,
    required this.indexes,
    required this.levels,
    required this.chapterId,
    required this.progress,
  });

  final String stage;
  final List<int> indexes;
  final List<Question> levels;
  final String chapterId;
  final LevelProgressState progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('trial_stage_${stage}_current'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(stageLabel(stage), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTheme.space12),
        for (var k = 0; k < indexes.length; k++) _node(context, indexes[k], k, checkpoint: k == indexes.length - 1),
      ],
    );
  }

  Widget _node(BuildContext context, int i, int k, {required bool checkpoint}) {
    final level = levels[i];
    final completed = progress.isCompleted(chapterId, level.level!);
    // Positional unlock: the predecessor is the previous LOADED level.
    final unlocked = progress.isUnlocked(chapterId, previousLevelInList: i == 0 ? null : levels[i - 1].level);
    return Padding(
      padding: EdgeInsets.only(left: _windingOffsets[k % _windingOffsets.length], bottom: AppTheme.space12),
      child: _TrialNode(
        key: ValueKey('trial_node_${level.level}'),
        level: level,
        number: i + 1,
        completed: completed,
        unlocked: unlocked,
        checkpoint: checkpoint,
        onTap: unlocked ? () => showLevelPreview(context, level: level, number: i + 1, total: levels.length) : null,
      ),
    );
  }
}

class _TrialNode extends StatelessWidget {
  const _TrialNode({
    super.key,
    required this.level,
    required this.number,
    required this.completed,
    required this.unlocked,
    required this.checkpoint,
    required this.onTap,
  });

  final Question level;
  final int number;
  final bool completed;
  final bool unlocked;

  /// The last level of a stage, drawn as a diamond.
  final bool checkpoint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color fill;
    final Widget icon;
    if (completed) {
      fill = colors.mastered;
      icon = Icon(Icons.check_rounded, color: colors.background);
    } else if (unlocked) {
      fill = colors.brand;
      icon = Text('$number', style: TextStyle(color: colors.accentInk, fontWeight: FontWeight.w800));
    } else {
      fill = colors.notStarted;
      icon = Icon(Icons.lock_rounded, color: colors.background, size: 18);
    }
    final shape = checkpoint
        ? Transform.rotate(
            key: ValueKey('trial_checkpoint_${level.level}'),
            angle: math.pi / 4,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Transform.rotate(angle: -math.pi / 4, child: icon),
            ),
          )
        : Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: icon,
          );
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 48, height: 48, child: Center(child: shape)),
          const SizedBox(width: AppTheme.space12),
          Text(checkpoint ? 'Level $number · Checkpoint' : 'Level $number',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

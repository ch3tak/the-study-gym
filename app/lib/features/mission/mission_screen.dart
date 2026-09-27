import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/content.dart';
import '../../data/mission_state.dart';
import '../../data/models.dart';
import '../workout/workout_screen.dart';

/// The Duolingo-style level path for a mission-sequenced chapter (currently
/// only `surface_area_volume`). Groups levels by `stage`, shows lock state
/// from `levelProgressProvider`, and pushes a single-level workout on tap.
///
/// Renders all level nodes in a single scrollable `Column` (not a
/// virtualized `ListView`) since a chapter's level count is small and
/// bounded (~60); this keeps every node materialized so off-screen nodes
/// remain reachable via `find.byKey` without explicit scrolling.
class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key, required this.chapterId});

  final String chapterId;

  static const _stageLabels = {
    'FOUNDATION': 'Foundation',
    'GUIDED_PRACTICE': 'Guided Practice',
    'SKILL_BUILDING': 'Skill Building',
    'APPLICATION': 'Application',
    'MASTERY': 'Mastery',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(levelProgressProvider);
    final levels = Content.forChapter(chapterId).where((q) => q.level != null).toList()
      ..sort((a, b) => a.level!.compareTo(b.level!));

    return Scaffold(
      appBar: AppBar(title: const Text('Mission')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space20, horizontal: AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < levels.length; i++)
              _buildLevelItem(context, ref, levels, i, progress),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelItem(
    BuildContext context,
    WidgetRef ref,
    List<Question> levels,
    int i,
    LevelProgressState progress,
  ) {
    final level = levels[i];
    final showStageHeader = i == 0 || levels[i - 1].stage != level.stage;
    final completed = progress.isCompleted(chapterId, level.level!);
    // Positional unlock: the predecessor is whichever level precedes this
    // one in the loaded (live-only, possibly gapped) list, not `level - 1`.
    final unlocked = progress.isUnlocked(
      chapterId,
      previousLevelInList: i == 0 ? null : levels[i - 1].level,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showStageHeader)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.space16, bottom: AppTheme.space12),
            child: Text(
              _stageLabels[level.stage] ?? level.stage ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        _MissionNode(
          key: ValueKey('mission_node_${level.level}'),
          level: level,
          completed: completed,
          unlocked: unlocked,
          onTap: unlocked
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WorkoutScreen.singleLevel(level)),
                  )
              : null,
        ),
      ],
    );
  }
}

class _MissionNode extends StatelessWidget {
  const _MissionNode({
    super.key,
    required this.level,
    required this.completed,
    required this.unlocked,
    required this.onTap,
  });

  final Question level;
  final bool completed;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Widget icon;
    if (completed) {
      fill = AppColors.mastered;
      icon = const Icon(Icons.check_rounded, color: Colors.white);
    } else if (unlocked) {
      fill = AppColors.brand;
      icon = Text('${level.level}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800));
    } else {
      fill = AppColors.notStarted;
      icon = const Icon(Icons.lock_rounded, color: Colors.white, size: 18);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Level ${level.level}', style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

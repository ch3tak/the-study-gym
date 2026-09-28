import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../data/content.dart';
import '../../shared/widgets/course_chip.dart';
import '../../shared/widgets/mastery_ring.dart';
import '../chapter/chapter_screen.dart';
import '../tests/tests_section.dart';

/// Learn: course progress, the chapter in progress, chapters grouped by
/// the syllabus's units, then Tests (spec: "Learn").
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final course = ref.watch(courseProgressProvider);
    final pinned = course.current;
    final unitIds = Content.units.map((u) => u.id).toSet();
    final ungrouped = course.chapters.where((c) => !unitIds.contains(c.chapter.unitId)).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, AppTheme.space32),
          children: [
            const Align(alignment: Alignment.centerLeft, child: CourseChip()),
            const SizedBox(height: AppTheme.space12),
            Text('Learn', style: textTheme.headlineLarge),
            const SizedBox(height: AppTheme.space16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: course.fraction,
                minHeight: 10,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation(colors.brand),
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(course.summary, style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
            if (pinned != null) ...[
              const SizedBox(height: AppTheme.space24),
              Text(course.anyStarted ? 'In progress' : 'Start here', style: textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              ChapterRow(key: const ValueKey('pinned_chapter'), progress: pinned),
            ],
            for (final unit in Content.units)
              if (Content.chaptersInUnit(unit.id).isNotEmpty) ...[
                const SizedBox(height: AppTheme.space24),
                Text(
                  unit.marks == null ? unit.name : '${unit.name} · ${unit.marks} marks',
                  key: ValueKey('unit_${unit.id}'),
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.space8),
                for (final chapter in Content.chaptersInUnit(unit.id)) ...[
                  ChapterRow(key: ValueKey('chapter_row_${chapter.id}'), progress: course.chapter(chapter.id)!),
                  const SizedBox(height: AppTheme.space8),
                ],
              ],
            if (ungrouped.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space24),
              Text('More chapters', style: textTheme.titleLarge),
              const SizedBox(height: AppTheme.space8),
              for (final p in ungrouped) ...[
                ChapterRow(key: ValueKey('chapter_row_${p.chapter.id}'), progress: p),
                const SizedBox(height: AppTheme.space8),
              ],
            ],
            const SizedBox(height: AppTheme.space32),
            const TestsSection(),
          ],
        ),
      ),
    );
  }
}

class ChapterRow extends StatelessWidget {
  const ChapterRow({super.key, required this.progress});
  final ChapterProgress progress;

  static String statusLabel(ChapterProgress p) => switch (p.status) {
        ChapterStatus.soon => 'Soon',
        ChapterStatus.notStarted => 'Not started',
        ChapterStatus.inProgress => '${p.topicsDone} of ${p.topics.length} topics · In progress',
        ChapterStatus.complete => 'Complete',
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final soon = progress.status == ChapterStatus.soon;
    return Opacity(
      opacity: soon ? 0.45 : 1,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: soon
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ChapterScreen(chapterId: progress.chapter.id),
                  )),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Row(
              children: [
                MasteryRing(
                  progress: progress.fraction,
                  size: 44,
                  strokeWidth: 5,
                  animate: false,
                  child: Text('${(progress.fraction * 100).round()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(progress.chapter.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(statusLabel(progress), style: TextStyle(color: colors.inkFaint, fontSize: 12)),
                    ],
                  ),
                ),
                if (!soon) Icon(Icons.chevron_right_rounded, color: colors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

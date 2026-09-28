import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../data/content.dart';
import 'notes_screen.dart';
import 'topic_practice_sheet.dart';
import 'topic_tile.dart';
import 'trial_gate.dart';

/// A chapter as its syllabus topics, each Learn → question nodes, closed
/// by the Trial gate (spec: "The chapter screen").
class ChapterScreen extends ConsumerWidget {
  const ChapterScreen({super.key, required this.chapterId});
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(courseProgressProvider).chapter(chapterId);
    if (progress == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('This chapter is not available.')));
    }
    final colors = context.colors;
    final chapter = progress.chapter;
    final hasLessons = Content.lessonsForChapter(chapter.id).isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(chapter.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space32),
        children: [
          Text(_summary(progress), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
          const SizedBox(height: AppTheme.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation(colors.brand),
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasLessons
                      ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NotesScreen(chapter: chapter)))
                      : null,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Notes'),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showTopicPracticeSheet(context, chapter),
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: const Text('Practice'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space24),
          for (final topic in progress.topics) ...[
            TopicTile(topic: topic),
            const SizedBox(height: AppTheme.space12),
          ],
          if (progress.trialLevels.isNotEmpty) TrialGate(progress: progress),
        ],
      ),
    );
  }

  static String _summary(ChapterProgress p) {
    final topics = '${p.topicsDone} of ${p.topics.length} topics done';
    if (p.trialLevels.isEmpty) return topics;
    final trial = !p.trialUnlocked
        ? 'Trial locked'
        : (p.levelsCleared == p.trialLevels.length ? 'Trial complete' : 'Trial open');
    return '$topics · $trial';
  }
}

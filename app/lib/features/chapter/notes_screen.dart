import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/theory_state.dart';
import '../theory/lesson_screen.dart';

/// Re-read this chapter's lessons (replaces the old Theory tab).
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key, required this.chapter});
  final Chapter chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final progress = ref.watch(theoryProgressProvider);
    final lessons = Content.lessonsForChapter(chapter.id);
    return Scaffold(
      appBar: AppBar(title: Text('Notes · ${chapter.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space20),
        children: [
          for (final lesson in lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space8),
              child: Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: ListTile(
                  leading: Icon(
                    progress.isRead(lesson.id) ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: progress.isRead(lesson.id) ? colors.mastered : colors.notStarted,
                  ),
                  title: Text(lesson.title),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.inkFaint),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

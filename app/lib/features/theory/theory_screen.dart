import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/theory_state.dart';
import '../../shared/widgets/mastery_ring.dart';
import 'lesson_screen.dart';

/// Theory tab: one card per chapter that has lessons, with a lessons-read
/// ring; tapping expands the lesson list, tapping a lesson opens it.
class TheoryScreen extends StatefulWidget {
  const TheoryScreen({super.key});

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen> {
  String? _expandedChapterId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final chapters = Content.chapters.where((c) => Content.lessonsForChapter(c.id).isNotEmpty).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, 0),
              child: Text('Theory', style: textTheme.headlineLarge),
            ),
            const SizedBox(height: AppTheme.space16),
            Expanded(
              child: chapters.isEmpty
                  ? Center(
                      child: Text(
                        'Lessons are on their way.',
                        style: textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space24),
                      children: [
                        for (final chapter in chapters) ...[
                          _TheoryChapterCard(
                            chapter: chapter,
                            expanded: _expandedChapterId == chapter.id,
                            onToggle: () => setState(() {
                              _expandedChapterId = _expandedChapterId == chapter.id ? null : chapter.id;
                            }),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'More chapters coming soon.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TheoryChapterCard extends ConsumerWidget {
  const _TheoryChapterCard({required this.chapter, required this.expanded, required this.onToggle});
  final Chapter chapter;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final lessons = Content.lessonsForChapter(chapter.id);
    final progress = ref.watch(theoryProgressProvider);
    final read = progress.readCountForChapter(chapter.id);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                children: [
                  MasteryRing(
                    progress: lessons.isEmpty ? 0 : read / lessons.length,
                    size: 48,
                    strokeWidth: 5,
                    child: Text(
                      '$read/${lessons.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chapter.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          lessons.length == 1 ? '1 lesson' : '${lessons.length} lessons',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.inkFaint,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: colors.inkFaint),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  for (final lesson in lessons) _LessonRow(lesson: lesson, read: progress.isRead(lesson.id)),
                ],
              ),
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.read});
  final Lesson lesson;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  read ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: read ? colors.mastered : colors.notStarted,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(lesson.title, style: Theme.of(context).textTheme.bodyMedium)),
                Icon(Icons.chevron_right_rounded, color: colors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

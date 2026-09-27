import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../shared/widgets/mastery_ring.dart';
import '../../shared/widgets/chunky_button.dart';
import '../workout/workout_screen.dart';
import '../mission/mission_screen.dart';

/// S8. Skill Map tab — docs/PLAN.md §3: chapters with a mastery ring,
/// expandable concept list with status chips, "Practice" CTA. Subject
/// switcher pill row per §3.
class SkillMapScreen extends ConsumerStatefulWidget {
  const SkillMapScreen({super.key});

  @override
  ConsumerState<SkillMapScreen> createState() => _SkillMapScreenState();
}

class _SkillMapScreenState extends ConsumerState<SkillMapScreen> {
  Subject _subject = Subject.maths;
  String? _expandedChapterId;

  @override
  Widget build(BuildContext context) {
    final chapters = Content.forSubject(_subject);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, 0),
              child: Row(
                children: [
                  Text('Skill Map', style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
              child: _SubjectSwitcher(
                selected: _subject,
                onChanged: (s) => setState(() {
                  _subject = s;
                  _expandedChapterId = null;
                }),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space20,
                  0,
                  AppTheme.space20,
                  AppTheme.space24,
                ),
                itemCount: chapters.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final chapter = chapters[i];
                  return _ChapterCard(
                    chapter: chapter,
                    expanded: _expandedChapterId == chapter.id,
                    onToggle: () => setState(() {
                      _expandedChapterId = _expandedChapterId == chapter.id ? null : chapter.id;
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectSwitcher extends StatelessWidget {
  const _SubjectSwitcher({required this.selected, required this.onChanged});
  final Subject selected;
  final ValueChanged<Subject> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.notStartedLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        children: Subject.values.map((s) {
          final isSelected = s == selected;
          final accent = s == Subject.maths ? AppColors.mathsAccent : AppColors.scienceAccent;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      s == Subject.maths ? Icons.calculate_rounded : Icons.science_rounded,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.inkFaint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.inkFaint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChapterCard extends ConsumerWidget {
  const _ChapterCard({required this.chapter, required this.expanded, required this.onToggle});
  final Chapter chapter;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    final progress = student.chapterMastery(chapter.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
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
                    progress: progress,
                    size: 48,
                    strokeWidth: 5,
                    child: Text(
                      '${(progress * 100).round()}%',
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
                          '${chapter.concepts.length} concepts · ${chapter.boardWeightMarks} marks',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.inkFaint,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.inkFaint),
                  ),
                ],
              ),
            ),
          ),
          if (Content.forChapter(chapter.id).any((q) => q.level != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ChunkyButton(
                label: 'Start Mission',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MissionScreen(chapterId: chapter.id)),
                ),
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: chapter.concepts
                    .map((c) => _ConceptRow(concept: c))
                    .toList(),
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

class _ConceptRow extends ConsumerWidget {
  const _ConceptRow({required this.concept});
  final Concept concept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(studentProvider).mastery[concept.id];
    final state = mastery?.state ?? MasteryState.notStarted;
    final percent = mastery?.masteryPercent ?? 0;

    final (color, lightColor, label) = switch (state) {
      MasteryState.mastered => (AppColors.mastered, AppColors.masteredLight, 'Mastered'),
      MasteryState.practising => (AppColors.learning, AppColors.learningLight, 'Practising'),
      MasteryState.learning => (AppColors.weak, AppColors.weakLight, 'Learning'),
      MasteryState.fading => (AppColors.learning, AppColors.learningLight, 'Fading'),
      MasteryState.notStarted => (AppColors.notStarted, AppColors.notStartedLight, 'Not started'),
    };

    final hasQuestions = Content.forConcept(concept.id).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(concept.name, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    if (percent > 0) ...[
                      const SizedBox(width: 6),
                      Text('${percent.round()}%', style: const TextStyle(color: AppColors.inkFaint, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (hasQuestions)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => WorkoutScreen(concepts: [concept])),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Practice', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

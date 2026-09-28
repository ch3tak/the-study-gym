import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../shared/widgets/mastery_ring.dart';
import '../workout/workout_screen.dart';

/// The chapter's Practice button: pick a topic, see its mastery, drill it.
Future<void> showTopicPracticeSheet(BuildContext context, Chapter chapter) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TopicPracticeSheet(chapter: chapter),
  );
}

class _TopicPracticeSheet extends ConsumerWidget {
  const _TopicPracticeSheet({required this.chapter});
  final Chapter chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mastery = ref.watch(studentProvider).mastery;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space8),
              child: Text('Practice a topic', style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final concept in chapter.concepts)
              Builder(builder: (context) {
                final hasQuestions = Content.practiceQuestions(concept.id).isNotEmpty;
                final percent = mastery[concept.id]?.masteryPercent ?? 0;
                return ListTile(
                  key: ValueKey('practice_${concept.id}'),
                  leading: MasteryRing(progress: percent / 100, size: 36, strokeWidth: 4, animate: false),
                  title: Text(concept.name),
                  subtitle: Text(
                    hasQuestions ? '${percent.round()}% mastery' : 'No practice questions yet',
                    style: TextStyle(color: colors.inkFaint),
                  ),
                  enabled: hasQuestions,
                  onTap: hasQuestions
                      ? () {
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          navigator.push(MaterialPageRoute<void>(builder: (_) => WorkoutScreen(concepts: [concept])));
                        }
                      : null,
                );
              }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../data/models.dart';
import '../../shared/widgets/math_text.dart';
import '../theory/lesson_screen.dart';
import '../workout/workout_screen.dart';

/// One topic on the chapter screen: a finished topic folds to one line,
/// the current topic is open, later topics are single cards.
class TopicTile extends StatelessWidget {
  const TopicTile({super.key, required this.topic});
  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey('topic_${topic.concept.id}');
    return switch (topic.status) {
      TopicStatus.done => _FinishedTopic(key: key, topic: topic),
      TopicStatus.current => _CurrentTopic(key: key, topic: topic),
      TopicStatus.locked => _LockedTopic(key: key, topic: topic),
    };
  }
}

BoxDecoration _card(AppColors colors) => BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(color: colors.border),
    );

class _FinishedTopic extends StatelessWidget {
  const _FinishedTopic({super.key, required this.topic});
  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = topic.usesInterimRule ? 'Lesson read' : '${topic.nodesPassed} / ${topic.nodeCount}';
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(color: colors.masteredLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.mastered),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text('${topic.concept.name} · $detail',
                style: TextStyle(color: colors.masteredDark, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _LockedTopic extends StatelessWidget {
  const _LockedTopic({super.key, required this.topic});
  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String detail;
    if (topic.usesInterimRule) {
      detail = topic.lesson != null ? 'lesson · questions coming soon' : 'coming soon';
    } else {
      detail = '${topic.lesson != null ? 'lesson + ' : ''}${topic.nodeCount} nodes';
    }
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: _card(colors),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: colors.inkFaint),
          const SizedBox(width: AppTheme.space12),
          Expanded(child: Text('${topic.concept.name} · $detail', style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

const _windingOffsets = [0.0, 40.0, 80.0, 40.0, 0.0];

class _CurrentTopic extends StatelessWidget {
  const _CurrentTopic({super.key, required this.topic});
  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final concept = topic.concept;
    final lesson = topic.lesson;
    final steps = <Widget>[
      _PathNode(
        key: ValueKey('node_${concept.id}_learn'),
        label: '▶ Learn',
        subtitle: lesson == null ? 'Lesson coming soon' : null,
        status: lesson == null
            ? NodeStatus.comingSoon
            : (topic.lessonRead ? NodeStatus.passed : NodeStatus.open),
        onTap: lesson == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson))),
      ),
      for (final slot in topic.nodes)
        _PathNode(
          key: ValueKey('node_${concept.id}_${slot.node.dbValue}'),
          label: slot.node.label,
          subtitle: slot.status == NodeStatus.comingSoon ? 'Questions coming soon' : '${slot.questionCount} questions',
          status: slot.status,
          onTap: slot.status == NodeStatus.open
              ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => WorkoutScreen.node(concept: concept, node: slot.node),
                  ))
              : null,
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: _card(colors).copyWith(border: Border.all(color: colors.brand, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(concept.name, style: Theme.of(context).textTheme.titleLarge),
          if (lesson != null && lesson.hook.trim().isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            DoYouKnowCard(lesson: lesson),
          ],
          const SizedBox(height: AppTheme.space16),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(left: _windingOffsets[i % _windingOffsets.length], bottom: AppTheme.space8),
              child: steps[i],
            ),
        ],
      ),
    );
  }
}

/// "Do you know?" from the lesson's existing `hook` (spec: no new content).
class DoYouKnowCard extends StatelessWidget {
  const DoYouKnowCard({super.key, required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kind = switch (lesson.hookKind) {
      HookKind.realWorld => 'Real world',
      HookKind.historical => 'From history',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Do you know?', style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800)),
              const SizedBox(width: AppTheme.space8),
              Text(kind, style: TextStyle(color: colors.inkSoft, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          MathText(lesson.hook, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink)),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({super.key, required this.label, required this.status, this.subtitle, this.onTap});
  final String label;
  final String? subtitle;
  final NodeStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (fill, icon, iconColor) = switch (status) {
      NodeStatus.passed => (colors.mastered, Icons.check_rounded, colors.background),
      NodeStatus.open => (colors.brand, Icons.play_arrow_rounded, colors.accentInk),
      NodeStatus.locked => (colors.notStarted, Icons.lock_rounded, colors.background),
      NodeStatus.comingSoon => (colors.notStartedLight, Icons.hourglass_empty_rounded, colors.inkFaint),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppTheme.space12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: colors.inkFaint, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

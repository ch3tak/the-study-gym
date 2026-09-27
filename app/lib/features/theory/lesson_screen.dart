import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../data/theory_state.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/math_text.dart';

/// One theory lesson: title, body, a hook card, an optional "Try it"
/// prompt (no input, no grading), and "Mark as read".
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _saving = false;

  Future<void> _markRead() async {
    setState(() => _saving = true);
    try {
      await ref.read(theoryProgressProvider.notifier).markRead(widget.lesson.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save — try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final textTheme = Theme.of(context).textTheme;
    final isRead = ref.watch(theoryProgressProvider).isRead(lesson.id);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space24),
                children: [
                  Text(lesson.title, style: textTheme.headlineLarge),
                  const SizedBox(height: AppTheme.space16),
                  MathText(lesson.body, style: textTheme.bodyLarge),
                  const SizedBox(height: AppTheme.space20),
                  _HookCard(lesson: lesson),
                  if (lesson.tryIt != null) ...[
                    const SizedBox(height: AppTheme.space16),
                    _TryItCard(prompt: lesson.tryIt!),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space20),
              child: ChunkyButton(
                label: isRead ? 'Read ✓' : 'Mark as read',
                onPressed: isRead || _saving ? null : _markRead,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HookCard extends StatelessWidget {
  const _HookCard({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, icon) = switch (lesson.hookKind) {
      HookKind.realWorld => ('Where this shows up', Icons.public_rounded),
      HookKind.historical => ('A bit of history', Icons.history_edu_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLabel(icon: icon, label: label),
          const SizedBox(height: AppTheme.space8),
          MathText(lesson.hook, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink)),
        ],
      ),
    );
  }
}

class _TryItCard extends StatelessWidget {
  const _TryItCard({required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(icon: Icons.lightbulb_outline_rounded, label: 'Try it'),
          const SizedBox(height: AppTheme.space8),
          MathText(prompt, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.inkSoft),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: colors.inkSoft, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

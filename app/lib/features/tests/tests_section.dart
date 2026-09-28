import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import 'custom_test_builder_screen.dart';

/// Tests, at the end of Learn: custom test (Pro) and mock papers (one
/// free, the rest Pro). No chapter tests exist yet.
class TestsSection extends ConsumerWidget {
  const TestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(studentProvider).isPro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tests', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTheme.space12),
        _CustomTestCard(isPro: isPro),
        const SizedBox(height: AppTheme.space20),
        Text('Mock papers', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTheme.space12),
        const _MockPaperTile(name: 'Mock Paper 1', locked: false, marks: 80, duration: '3 hrs'),
        const SizedBox(height: 10),
        _MockPaperTile(name: 'Mock Paper 2', locked: !isPro, marks: 80, duration: '3 hrs'),
        const SizedBox(height: 10),
        _MockPaperTile(name: 'Mock Paper 3', locked: !isPro, marks: 80, duration: '3 hrs'),
      ],
    );
  }
}

class _CustomTestCard extends StatelessWidget {
  const _CustomTestCard({required this.isPro});
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CustomTestBuilderScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.brand, colors.brandDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.accentInk.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(Icons.tune_rounded, color: colors.accentInk, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Create a custom test',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.accentInk),
                      ),
                      if (!isPro) ...[
                        const SizedBox(width: 8),
                        const _ProBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick any chapters and build your own quiz',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.accentInk.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.accentInk),
          ],
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.xp,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 12, color: colors.ink),
          const SizedBox(width: 3),
          Text('PRO', style: TextStyle(color: colors.ink, fontWeight: FontWeight.w900, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MockPaperTile extends StatelessWidget {
  const _MockPaperTile({
    required this.name,
    required this.locked,
    required this.marks,
    required this.duration,
  });

  final String name;
  final bool locked;
  final int marks;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.brandLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              locked ? Icons.lock_rounded : Icons.description_rounded,
              color: colors.brand,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '$marks marks · $duration',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint, fontSize: 12),
                ),
              ],
            ),
          ),
          if (locked) const _ProBadge(),
        ],
      ),
    );
  }
}

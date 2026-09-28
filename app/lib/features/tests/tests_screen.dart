import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import 'tests_section.dart';

/// S9. Tests tab — docs/PLAN.md §3: mock papers, chapter tests, and (new)
/// a custom test builder where the student picks their own chapters. Custom
/// tests are Pro-only — free users see the feature with a lock, not a
/// paywall wall; tapping it explains what unlocks rather than hiding it.
class TestsScreen extends ConsumerWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isPro = ref.watch(studentProvider).isPro;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space16,
            AppTheme.space20,
            AppTheme.space24,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tests', style: Theme.of(context).textTheme.headlineLarge),
                // Demo-only Pro toggle so both states are easy to show.
                TextButton(
                  onPressed: () => ref.read(studentProvider.notifier).togglePro(),
                  child: Text(
                    isPro ? 'Pro (demo)' : 'Free (demo)',
                    style: TextStyle(
                      color: isPro ? colors.mastered : colors.inkFaint,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space20),
            const TestsSection(),
          ],
        ),
      ),
    );
  }
}

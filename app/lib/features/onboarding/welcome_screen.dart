import 'package:flutter/material.dart';

import '../../core/router/app_shell.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/chunky_button.dart';

/// S1. Welcome — docs/PLAN.md §3.
///
/// There is no separate diagnostic screen (deliberately dropped — see
/// docs/PLAN.md's "Alpha scope" decision log): it added a whole extra flow
/// just to ask questions we can infer from normal practice instead. Every
/// path from here lands straight on the main dashboard (AppShell) and
/// mastery starts at its seeded baseline, filling in as the student works
/// through real workouts.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _HeroMark(),
              const SizedBox(height: AppTheme.space32),
              Text(
                'Your daily study workout',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                "We find exactly what you're weak at in Maths,\ntrain it, and show your real progress.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.inkSoft),
              ),
              const Spacer(flex: 3),
              ChunkyButton(
                label: 'Get started',
                icon: Icons.bolt_rounded,
                onPressed: () => _enterApp(context),
              ),
              const SizedBox(height: AppTheme.space16),
              TextButton(
                onPressed: () => _enterApp(context),
                child: Text(
                  'I already have an account',
                  style: TextStyle(color: colors.inkFaint, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: AppTheme.space24),
            ],
          ),
        ),
      ),
    );
  }
}

void _enterApp(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AppShell()),
    (route) => false,
  );
}

class _HeroMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colors.brandLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Icon(Icons.fitness_center_rounded, size: 64, color: colors.brand),
    );
  }
}

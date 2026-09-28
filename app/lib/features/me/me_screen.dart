import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode.dart';
import '../../data/app_state.dart';

/// Me tab. Appearance and the Pro demo switch for now; profile and streak
/// history come later.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final mode = ref.watch(themeModeProvider);
    final isPro = ref.watch(studentProvider).isPro;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, AppTheme.space24),
          children: [
            Text('Me', style: textTheme.headlineLarge),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Appearance', style: textTheme.titleMedium),
                  const SizedBox(height: AppTheme.space12),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).setMode(s.first),
                    style: SegmentedButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.inkSoft,
                      selectedBackgroundColor: colors.accent,
                      selectedForegroundColor: colors.accentInk,
                      side: BorderSide(color: colors.border),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            // A Material, not a coloured Container: a ListTile's ink must
            // paint on the Material that carries the background.
            Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                side: BorderSide(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                key: const ValueKey('pro_demo_switch'),
                title: Text('Study Gym Pro (demo)', style: textTheme.titleMedium),
                subtitle: const Text('Payments are not built yet. This switch shows the Pro experience.'),
                value: isPro,
                onChanged: (_) => ref.read(studentProvider.notifier).togglePro(),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Profile and streak history are coming soon.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

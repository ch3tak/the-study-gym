import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/skill_map/skill_map_screen.dart';
import '../../features/tests/tests_screen.dart';
import '../../features/today/today_screen.dart';

/// The 4-tab bottom nav shell from docs/PLAN.md §3 ("Today · Skill Map ·
/// Tests · Me"). Me is stubbed for this mockup; Tests now hosts mock papers
/// and the custom test builder.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    _TabDef('Today', Icons.wb_sunny_rounded, Icons.wb_sunny_outlined),
    _TabDef('Skill Map', Icons.grid_view_rounded, Icons.grid_view_outlined),
    _TabDef('Tests', Icons.assignment_rounded, Icons.assignment_outlined),
    _TabDef('Me', Icons.person_rounded, Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          SkillMapScreen(),
          TestsScreen(),
          _ComingSoonTab(title: 'Me', subtitle: 'Profile, streak history and settings.'),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = i == _index;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? tab.activeIcon : tab.icon,
                          color: selected ? colors.brand : colors.inkFaint,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: selected ? colors.brand : colors.inkFaint,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.activeIcon, this.icon);
  final String label;
  final IconData activeIcon;
  final IconData icon;
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_rounded, size: 48, color: colors.inkFaint),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

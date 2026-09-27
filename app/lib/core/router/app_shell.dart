import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/me/me_screen.dart';
import '../../features/mission/mission_list_screen.dart';
import '../../features/tests/tests_screen.dart';
import '../../features/theory/theory_screen.dart';
import '../../features/today/today_screen.dart';

/// The 5-tab bottom nav shell: Today · Theory · Mission · Tests · Me.
/// Tests hosts mock papers and the custom test builder; Me holds settings.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    _TabDef('Today', Icons.wb_sunny_rounded, Icons.wb_sunny_outlined),
    _TabDef('Theory', Icons.menu_book_rounded, Icons.menu_book_outlined),
    _TabDef('Mission', Icons.flag_rounded, Icons.outlined_flag_rounded),
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
          TheoryScreen(),
          MissionListScreen(),
          TestsScreen(),
          MeScreen(),
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

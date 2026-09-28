import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn/learn_screen.dart';
import '../../features/me/me_screen.dart';

/// The 4-tab bottom nav shell: Home · Learn · History · Me.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    _TabDef('Home', Icons.home_rounded, Icons.home_outlined),
    _TabDef('Learn', Icons.school_rounded, Icons.school_outlined),
    _TabDef('History', Icons.auto_stories_rounded, Icons.auto_stories_outlined),
    _TabDef('Me', Icons.person_rounded, Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), LearnScreen(), HistoryScreen(), MeScreen()],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../shared/widgets/chunky_button.dart';
import '../workout/workout_screen.dart';

/// Custom test builder — the student picks any chapters and we assemble a quiz from them. Pro-only: a free user can browse and
/// select, but generating the test shows an upgrade sheet instead of a
/// silent block, so the feature still demonstrates its value.
class CustomTestBuilderScreen extends ConsumerStatefulWidget {
  const CustomTestBuilderScreen({super.key});

  @override
  ConsumerState<CustomTestBuilderScreen> createState() => _CustomTestBuilderScreenState();
}

class _CustomTestBuilderScreenState extends ConsumerState<CustomTestBuilderScreen> {
  final Set<String> _selectedChapterIds = {};

  int get _questionCount {
    return _selectedChapterIds
        .expand((id) => Content.forChapter(id))
        .length;
  }

  void _generate() {
    final isPro = ref.read(studentProvider).isPro;
    if (!isPro) {
      _showUpgradeSheet();
      return;
    }
    final concepts = _selectedChapterIds
        .expand((id) => Content.chapters.firstWhere((c) => c.id == id).concepts)
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutScreen(concepts: concepts)),
    );
  }

  void _showUpgradeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _UpgradeSheet(
        onUpgrade: () {
          ref.read(studentProvider.notifier).togglePro();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPro = ref.watch(studentProvider).isPro;

    return Scaffold(
      appBar: AppBar(title: const Text('Custom test')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space20),
                children: [
                  Text(
                    'Pick the chapters you want to be tested on.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  ...Content.chapters.map((chapter) {
                    final selected = _selectedChapterIds.contains(chapter.id);
                    return _ChapterCheckTile(
                      chapter: chapter,
                      selected: selected,
                      onTap: () => setState(() {
                        selected ? _selectedChapterIds.remove(chapter.id) : _selectedChapterIds.add(chapter.id);
                      }),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space20,
                0,
                AppTheme.space20,
                AppTheme.space20,
              ),
              child: Column(
                children: [
                  if (_selectedChapterIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${_selectedChapterIds.length} chapters selected · ~$_questionCount questions available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
                      ),
                    ),
                  ChunkyButton(
                    label: isPro ? 'Generate test' : 'Generate test 🔒',
                    onPressed: _selectedChapterIds.isEmpty ? null : _generate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterCheckTile extends StatelessWidget {
  const _ChapterCheckTile({required this.chapter, required this.selected, required this.onTap});
  final Chapter chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colors.brandLight : colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: selected ? colors.brand : colors.border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? colors.brand : colors.inkFaint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${chapter.concepts.length} concepts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
          ),
          const SizedBox(height: AppTheme.space20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: colors.brandLight, shape: BoxShape.circle),
            child: Icon(Icons.workspace_premium_rounded, color: colors.brand, size: 32),
          ),
          const SizedBox(height: AppTheme.space16),
          Text('Custom tests are a Pro feature', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Build unlimited tests from any chapter, whenever you want to check yourself.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
          ),
          const SizedBox(height: AppTheme.space24),
          ChunkyButton(label: 'Upgrade to Pro (demo)', onPressed: onUpgrade),
          const SizedBox(height: AppTheme.space12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Not now', style: TextStyle(color: colors.inkFaint, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import 'chunky_button.dart';

/// The sheet a Pro lock opens: it explains that one feature (spec: "A lock
/// opens a Pro sheet that explains that one feature"). "Upgrade" is still
/// the demo toggle; there are no payments.
Future<void> showProSheet(BuildContext context, WidgetRef ref, {required String title, required String body}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ProSheet(
      title: title,
      body: body,
      onUpgrade: () {
        ref.read(studentProvider.notifier).togglePro();
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class ProSheet extends StatelessWidget {
  const ProSheet({super.key, required this.title, required this.body, required this.onUpgrade});
  final String title;
  final String body;
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
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.space8),
          Text(
            body,
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

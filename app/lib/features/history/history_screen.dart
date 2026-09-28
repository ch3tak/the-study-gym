import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// History tab placeholder. The map, timeline and stories come in Slice 3.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('History', style: textTheme.headlineLarge),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Where maths happened, told as short stories on a map. Coming soon.',
                style: textTheme.bodyLarge?.copyWith(color: context.colors.inkFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

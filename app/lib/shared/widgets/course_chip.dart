import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/course.dart';

/// "Class 9 ▾" at the top of Home and Learn; opens the course switcher.
class CourseChip extends ConsumerWidget {
  const CourseChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final course = ref.watch(activeCourseProvider);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => showCourseSwitcher(context, course),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            '${course.shortLabel} ▾',
            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

Future<void> showCourseSwitcher(BuildContext context, Course active) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => _CourseSwitcherSheet(active: active),
  );
}

class _CourseSwitcherSheet extends StatelessWidget {
  const _CourseSwitcherSheet({required this.active});
  final Course active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space8),
              child: Text('Your courses', style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final course in Courses.all)
              ListTile(
                title: Text(course.title),
                enabled: course.available,
                trailing: course.id == active.id
                    ? Icon(Icons.check_rounded, color: colors.brand)
                    : (course.available ? null : Text('Coming soon', style: TextStyle(color: colors.inkFaint))),
                onTap: course.available ? () => Navigator.of(context).pop() : null,
              ),
            ListTile(
              leading: Icon(Icons.add_rounded, color: colors.brand),
              title: const Text('Add a course'),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger.showSnackBar(const SnackBar(content: Text('More courses are on the way.')));
              },
            ),
          ],
        ),
      ),
    );
  }
}

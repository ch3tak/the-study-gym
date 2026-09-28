import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_state.dart';
import '../../data/daily_state.dart';
import '../../shared/widgets/pro_sheet.dart';
import 'workout_screen.dart';
import 'workout_selector.dart';

/// Keep going: five more questions from the same selector, leaving out what
/// was already served. Pro only (spec: "Free users get one workout a day;
/// Keep going is Pro").
void startKeepGoing(BuildContext context, WidgetRef ref, {bool replace = false}) {
  final student = ref.read(studentProvider);
  if (!student.isPro) {
    showProSheet(
      context,
      ref,
      title: 'Keep going is a Pro feature',
      body: 'Free accounts get one daily workout. Pro adds as many five-question rounds as you like.',
    );
    return;
  }
  final route = MaterialPageRoute<void>(
    builder: (_) => WorkoutScreen(
      concepts: pickWorkoutConcepts(student),
      kind: WorkoutKind.keepGoing,
      exclude: ref.read(dailyProvider).servedQuestionIds,
    ),
  );
  final navigator = Navigator.of(context);
  replace ? navigator.pushReplacement(route) : navigator.push(route);
}

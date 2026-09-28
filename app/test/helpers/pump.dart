import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/data/app_state.dart';

/// Both themes, so each screen test can run in light and dark (spec:
/// "Everything renders in both light and dark themes").
final themes = <String, ThemeData>{'light': AppTheme.light, 'dark': AppTheme.dark};

/// Pumps [home] in a tall viewport (long lists stay on screen) inside a
/// MaterialApp and the given (or a fresh) ProviderContainer, and returns the
/// container so tests can read and drive state.
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget home, {
  ThemeData? theme,
  ProviderContainer? container,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = container ?? ProviderContainer();
  if (container == null) addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(theme: theme ?? AppTheme.light, home: home),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

/// A StudentNotifier that starts from [seed] (mastery, Pro flag) instead
/// of an empty state. Use via `studentProvider.overrideWith(() => SeededStudent(...))`.
class SeededStudent extends StudentNotifier {
  SeededStudent(this.seed);
  final StudentState seed;

  @override
  StudentState build() => seed;
}

/// Answers [count] questions in a running WorkoutScreen by tapping [answer],
/// Submit and Continue for each.
Future<void> answerQuestions(WidgetTester tester, int count, {String answer = 'right'}) async {
  for (var i = 0; i < count; i++) {
    await tester.tap(find.text(answer).first);
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }
}

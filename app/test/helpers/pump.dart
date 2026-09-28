import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/data/app_state.dart';

/// Both themes, so each screen test can run in light and dark (spec:
/// "Everything renders in both light and dark themes").
///
/// Brightness, not ThemeData: tests loop over this in main(), and building
/// AppTheme there (outside a test) makes google_fonts fail the whole file.
/// [pumpScreen] turns it into AppTheme.light or AppTheme.dark.
const themes = <String, Brightness>{'light': Brightness.light, 'dark': Brightness.dark};

/// Pumps [home] in a tall viewport (long lists stay on screen) inside a
/// MaterialApp themed with AppTheme.light or AppTheme.dark ([theme], light by
/// default) and the given (or a fresh) ProviderContainer, and returns the
/// container so tests can read and drive state.
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget home, {
  Brightness? theme,
  ProviderContainer? container,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Reduced motion: the workout-done confetti times its particles by the
  // wall clock, so under the test clock it never settles.
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final c = container ?? ProviderContainer();
  if (container == null) addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(theme: theme == Brightness.dark ? AppTheme.dark : AppTheme.light, home: home),
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

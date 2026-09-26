import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_gym/data/app_state.dart';

void main() {
  group('StudentNotifier.recordAttempt', () {
    test('a correct attempt raises mastery toward 100', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(studentProvider.notifier);
      const conceptId = 'c9.seq.ap_nth_term';

      notifier.recordAttempt(conceptId: conceptId, correct: true);

      final mastery = container.read(studentProvider).mastery[conceptId]!;
      expect(mastery.masteryPercent, greaterThan(0));
      expect(mastery.attempts, 1);
      expect(mastery.correct, 1);
    });

    test('a wrong attempt keeps mastery at zero and counts as an attempt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(studentProvider.notifier);
      const conceptId = 'c9.seq.ap_nth_term';

      notifier.recordAttempt(conceptId: conceptId, correct: false);

      final mastery = container.read(studentProvider).mastery[conceptId]!;
      expect(mastery.masteryPercent, 0);
      expect(mastery.attempts, 1);
      expect(mastery.correct, 0);
    });
  });

  group('daily goal', () {
    test('progress and met flag track xpToday against dailyXpGoal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(studentProvider.notifier);

      expect(container.read(studentProvider).dailyGoalMet, isFalse);
      expect(container.read(studentProvider).dailyGoalProgress, 0);

      notifier.addXp(25);
      expect(container.read(studentProvider).dailyGoalProgress, closeTo(0.5, 0.001));
      expect(container.read(studentProvider).dailyGoalMet, isFalse);

      notifier.addXp(25);
      expect(container.read(studentProvider).dailyGoalMet, isTrue);
    });
  });

  group('Pro toggle', () {
    test('togglePro flips isPro', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(studentProvider.notifier);

      expect(container.read(studentProvider).isPro, isFalse);
      notifier.togglePro();
      expect(container.read(studentProvider).isPro, isTrue);
      notifier.togglePro();
      expect(container.read(studentProvider).isPro, isFalse);
    });
  });
}

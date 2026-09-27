import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/theory_state.dart';

import '../features/theory/theory_fixtures.dart';

void main() {
  setUp(loadTheoryContent);
  tearDown(() => TheoryProgressNotifier.repositoryOverride = null);

  test('hydrates read lessons and counts them per chapter', () async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(initial: {'t_cube'});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(theoryProgressProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(theoryProgressProvider).isRead('t_cube'), isTrue);
    expect(c.read(theoryProgressProvider).readCountForChapter('sav'), 1);
    expect(c.read(theoryProgressProvider).readCountForChapter('seq'), 0);
  });

  test('markRead writes once and marks the lesson read', () async {
    final repo = FakeTheoryRepo();
    TheoryProgressNotifier.repositoryOverride = repo;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(theoryProgressProvider.notifier).markRead('t_pyr');
    await c.read(theoryProgressProvider.notifier).markRead('t_pyr');
    expect(repo.writes, ['t_pyr']);
    expect(c.read(theoryProgressProvider).isRead('t_pyr'), isTrue);
  });

  test('a failed write throws and leaves the lesson unread', () async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(failWrites: true);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await expectLater(c.read(theoryProgressProvider.notifier).markRead('t_cube'), throwsException);
    expect(c.read(theoryProgressProvider).isRead('t_cube'), isFalse);
  });

  test('a slow initial fetch does not wipe a lesson marked read meanwhile', () async {
    final repo = FakeTheoryRepo()..fetchGate = Completer<Set<String>>();
    TheoryProgressNotifier.repositoryOverride = repo;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(theoryProgressProvider);
    await c.read(theoryProgressProvider.notifier).markRead('t_pyr');
    repo.fetchGate!.complete({'t_cube'});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(theoryProgressProvider).readLessonIds, {'t_cube', 't_pyr'});
  });
}

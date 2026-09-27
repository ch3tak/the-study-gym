import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/mission_state.dart';

void main() {
  const ch = 'surface_area_volume';

  test('the first loaded level (no predecessor) is always unlocked, even with no progress', () {
    const state = LevelProgressState(completedLevels: {});
    expect(state.isUnlocked(ch, previousLevelInList: null), isTrue);
    expect(state.isUnlocked(ch, previousLevelInList: 1), isFalse);
  });

  test('a level is unlocked iff its predecessor in the list is complete', () {
    const state = LevelProgressState(
      completedLevels: {
        ch: {1, 2, 3},
      },
    );
    expect(state.isUnlocked(ch, previousLevelInList: 3), isTrue);
    expect(state.isUnlocked(ch, previousLevelInList: 4), isFalse);
  });

  test('completion is not assumed contiguous — level 10 complete does not unlock level 3', () {
    const state = LevelProgressState(
      completedLevels: {
        ch: {10},
      },
    );
    // Level 3's predecessor (level 2) is not complete.
    expect(state.isUnlocked(ch, previousLevelInList: 2), isFalse);
    // Level 11's predecessor (level 10) is complete.
    expect(state.isUnlocked(ch, previousLevelInList: 10), isTrue);
  });

  test('gapped list: predecessor is the previous LOADED level, not level - 1', () {
    // Loaded levels {2, 3, 5}: level 5's predecessor is 3 — level 4 never
    // loaded, so it must not be required.
    const state = LevelProgressState(
      completedLevels: {
        ch: {2, 3},
      },
    );
    expect(state.isUnlocked(ch, previousLevelInList: 3), isTrue);
  });

  test('a chapter with no progress rows unlocks only the first loaded level', () {
    const state = LevelProgressState(completedLevels: {});
    expect(state.isUnlocked('any_chapter', previousLevelInList: null), isTrue);
    for (var prev = 1; prev < 62; prev++) {
      expect(state.isUnlocked('any_chapter', previousLevelInList: prev), isFalse);
    }
  });

  test('isCompleted reflects completedLevels', () {
    const state = LevelProgressState(
      completedLevels: {
        ch: {1, 2},
      },
    );
    expect(state.isCompleted(ch, 1), isTrue);
    expect(state.isCompleted(ch, 3), isFalse);
  });
}

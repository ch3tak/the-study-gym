import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/mission_state.dart';

void main() {
  test('level 1 is always unlocked, even with no progress at all', () {
    const state = LevelProgressState(completedLevels: {});
    expect(state.isUnlocked('surface_area_volume', 1), isTrue);
    expect(state.isUnlocked('surface_area_volume', 2), isFalse);
  });

  test('level N+1 is unlocked iff level N is complete', () {
    const state = LevelProgressState(
      completedLevels: {
        'surface_area_volume': {1, 2, 3},
      },
    );
    expect(state.isUnlocked('surface_area_volume', 4), isTrue);
    expect(state.isUnlocked('surface_area_volume', 5), isFalse);
  });

  test('completion is not assumed contiguous — level 10 complete does not unlock level 3', () {
    const state = LevelProgressState(
      completedLevels: {
        'surface_area_volume': {10},
      },
    );
    expect(state.isUnlocked('surface_area_volume', 3), isFalse);
    expect(state.isUnlocked('surface_area_volume', 11), isTrue);
  });

  test('a chapter with no progress rows unlocks only level 1', () {
    const state = LevelProgressState(completedLevels: {});
    expect(state.isUnlocked('any_chapter', 1), isTrue);
    for (var lvl = 2; lvl <= 62; lvl++) {
      expect(state.isUnlocked('any_chapter', lvl), isFalse);
    }
  });

  test('isCompleted reflects completedLevels', () {
    const state = LevelProgressState(
      completedLevels: {
        'surface_area_volume': {1, 2},
      },
    );
    expect(state.isCompleted('surface_area_volume', 1), isTrue);
    expect(state.isCompleted('surface_area_volume', 3), isFalse);
  });
}

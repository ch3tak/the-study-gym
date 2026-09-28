import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/trial_trophy.dart';

import '../fixtures/slice1_content.dart';

LevelProgressState _state(Map<int, LevelResult> results) => LevelProgressState(
      completedLevels: {savChapter: results.keys.toSet()},
      results: {savChapter: results},
    );

void main() {
  setUp(loadSlice1Content);

  test('no trophy until every loaded level is done', () {
    final levels = Content.trialLevels(savChapter);
    final nine = {for (var l = 1; l <= 9; l++) l: const LevelResult(score: 1)};
    expect(trialTrophy(savChapter, levels, _state(nine)), TrialTrophy.none);
  });

  test('Platinum: at least 90% right first time and no solutions viewed', () {
    final levels = Content.trialLevels(savChapter);
    final results = {for (var l = 1; l <= 10; l++) l: LevelResult(score: l == 10 ? 0 : 1)};
    expect(trialTrophy(savChapter, levels, _state(results)), TrialTrophy.platinum);
  });

  test('Gold when below 90% first time, or when a solution was viewed', () {
    final levels = Content.trialLevels(savChapter);
    final lowScore = {for (var l = 1; l <= 10; l++) l: LevelResult(score: l >= 9 ? 0 : 1)};
    expect(trialTrophy(savChapter, levels, _state(lowScore)), TrialTrophy.gold);
    final peeked = {for (var l = 1; l <= 10; l++) l: LevelResult(score: 1, solutionViewed: l == 3)};
    expect(trialTrophy(savChapter, levels, _state(peeked)), TrialTrophy.gold);
  });

  test('no Trial, no trophy', () {
    expect(trialTrophy(seqChapter, const [], const LevelProgressState()), TrialTrophy.none);
  });
}

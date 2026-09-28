import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/fading.dart';
import 'package:study_gym/data/models.dart';

import '../fixtures/slice1_content.dart';

final now = DateTime(2026, 9, 28, 10);

ConceptMastery _m(String id, double percent, {int? daysAgo, double halfLife = 2}) => ConceptMastery(
      conceptId: id,
      masteryPercent: percent,
      attempts: 5,
      lastPracticed: daysAgo == null ? null : now.subtract(Duration(days: daysAgo)),
      halfLifeDays: halfLife,
    );

void main() {
  setUp(loadSlice1Content);

  test('effective mastery halves every half-life', () {
    expect(effectiveMastery(_m('c.ap', 80, daysAgo: 2), now), closeTo(40, 1e-6));
    expect(effectiveMastery(_m('c.ap', 80, daysAgo: 0), now), 80);
    expect(effectiveMastery(_m('c.ap', 80), now), 80, reason: 'never practised: no decay');
  });

  test('fading = was mastered (>= 80%) and has decayed below 70%', () {
    expect(isFading(_m('c.ap', 90, daysAgo: 1), now), isTrue); // 63.6
    expect(isFading(_m('c.ap', 90, daysAgo: 0), now), isFalse);
    expect(isFading(_m('c.ap', 60, daysAgo: 30), now), isFalse, reason: 'never mastered');
    expect(isFading(_m('c.ap', 90, daysAgo: 1, halfLife: 60), now), isFalse);
  });

  test('fadingConcepts lists only known, fading concepts', () {
    final student = StudentState(mastery: {
      'c.ap': _m('c.ap', 90, daysAgo: 5),
      'c.gp': _m('c.gp', 90, daysAgo: 0),
      'gone': _m('gone', 90, daysAgo: 5),
    });
    expect(fadingConcepts(student, now).map((c) => c.id), ['c.ap']);
  });
}

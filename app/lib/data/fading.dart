import 'dart:math' as math;

import 'app_state.dart';
import 'content.dart';
import 'models.dart';

/// Retention decay from docs/PLAN.md §5.1:
/// effective mastery = mastery × 2^(−days since last practice / half-life).
double effectiveMastery(ConceptMastery m, DateTime now) {
  final last = m.lastPracticed;
  if (last == null) return m.masteryPercent;
  final days = now.difference(last).inMinutes / (60 * 24);
  if (days <= 0) return m.masteryPercent;
  final halfLife = m.halfLifeDays <= 0 ? 2.0 : m.halfLifeDays;
  return m.masteryPercent * math.pow(2, -days / halfLife);
}

/// PLAN.md §5.1's Fading: a mastered concept whose effective mastery has
/// dropped below 70%. Read-only and simplified: "mastered" is the stored
/// percent (≥ 80). The "on 2 days at least 3 days apart" rule and half-life
/// growth come with the full mastery engine.
bool isFading(ConceptMastery m, DateTime now) => m.masteryPercent >= 80 && effectiveMastery(m, now) < 70;

List<Concept> fadingConcepts(StudentState student, DateTime now) => student.mastery.values
    .where((m) => isFading(m, now))
    .map((m) => Content.conceptOrNull(m.conceptId))
    .whereType<Concept>()
    .toList();

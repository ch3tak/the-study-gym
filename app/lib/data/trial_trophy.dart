import 'mission_state.dart';
import 'models.dart';

enum TrialTrophy { none, gold, platinum }

/// Gold: every loaded Trial level finished. Platinum: finished with at least
/// 90% right first time and no solution viewed (spec: "The Chapter Trial").
TrialTrophy trialTrophy(String chapterId, List<Question> levels, LevelProgressState progress) {
  if (levels.isEmpty) return TrialTrophy.none;
  final results = <LevelResult>[];
  for (final q in levels) {
    final r = progress.resultFor(chapterId, q.level!);
    if (r == null) return TrialTrophy.none;
    results.add(r);
  }
  final firstTime = results.where((r) => r.score >= 1).length / results.length;
  final anySolution = results.any((r) => r.solutionViewed);
  return firstTime >= 0.9 && !anySolution ? TrialTrophy.platinum : TrialTrophy.gold;
}

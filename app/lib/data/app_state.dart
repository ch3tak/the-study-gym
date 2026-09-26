import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content.dart';
import 'models.dart';

/// All the mutable "student" state for the mockup, in memory only.
/// Mirrors the shape of `concept_mastery` / `streaks` / `sessions` tables
/// from docs/PLAN.md §6, simplified: no persistence, no sync.
class StudentState {
  StudentState({
    Map<String, ConceptMastery>? mastery,
    this.streak = 4,
    this.xpToday = 0,
    this.dailyXpGoal = 50,
    this.onboardingDone = false,
    this.isPro = false,
  }) : mastery = mastery ?? _seedMastery();

  final Map<String, ConceptMastery> mastery;
  final int streak;
  final int xpToday;

  /// Daily activity target (docs/PLAN.md §2's daily-workout framing, made
  /// explicit as a Duolingo-style daily goal to drive return visits).
  final int dailyXpGoal;
  final bool onboardingDone;

  /// Pro subscription flag — gates custom tests (docs/PLAN.md §7 monetisation).
  /// No real paywall in this mockup; toggled here for demo purposes.
  final bool isPro;

  double get dailyGoalProgress => dailyXpGoal == 0 ? 0 : (xpToday / dailyXpGoal).clamp(0.0, 1.0);
  bool get dailyGoalMet => xpToday >= dailyXpGoal;

  static Map<String, ConceptMastery> _seedMastery() {
    final map = <String, ConceptMastery>{};
    for (final chapter in Content.chapters) {
      for (final concept in chapter.concepts) {
        map[concept.id] = ConceptMastery(conceptId: concept.id);
      }
    }
    return map;
  }

  double chapterMastery(String chapterId) {
    final chapter = Content.chapters.firstWhere((c) => c.id == chapterId);
    if (chapter.concepts.isEmpty) return 0;
    final total = chapter.concepts
        .map((c) => mastery[c.id]?.masteryPercent ?? 0)
        .fold<double>(0, (a, b) => a + b);
    return total / (chapter.concepts.length * 100);
  }

  /// Weighted overall readiness across every seeded chapter (stand-in for
  /// "Board Readiness" from docs/PLAN.md §5.4, simplified to a single number
  /// for this mockup rather than a ± range).
  double get overallReadiness {
    final chapters = Content.chapters;
    final totalWeight = chapters.fold<double>(0, (a, c) => a + c.boardWeightMarks);
    if (totalWeight == 0) return 0;
    var weighted = 0.0;
    for (final chapter in chapters) {
      weighted += chapterMastery(chapter.id) * chapter.boardWeightMarks;
    }
    return weighted / totalWeight;
  }

  List<Concept> get weakConcepts {
    final entries = mastery.values.where((m) => m.attempts > 0).toList()
      ..sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));
    return entries.take(3).map((m) => Content.conceptById(m.conceptId)).toList();
  }

  StudentState copyWith({
    Map<String, ConceptMastery>? mastery,
    int? streak,
    int? xpToday,
    int? dailyXpGoal,
    bool? onboardingDone,
    bool? isPro,
  }) {
    return StudentState(
      mastery: mastery ?? this.mastery,
      streak: streak ?? this.streak,
      xpToday: xpToday ?? this.xpToday,
      dailyXpGoal: dailyXpGoal ?? this.dailyXpGoal,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      isPro: isPro ?? this.isPro,
    );
  }
}

class StudentNotifier extends Notifier<StudentState> {
  @override
  StudentState build() => StudentState();

  void completeOnboarding() {
    state = state.copyWith(onboardingDone: true);
  }

  /// Demo-only toggle so the mockup can show both the free and Pro
  /// experience without a real payment flow.
  void togglePro() {
    state = state.copyWith(isPro: !state.isPro);
  }

  /// Applies one attempt's outcome to a concept's mastery using a simplified
  /// version of the Elo-style update in docs/PLAN.md §5.1 (K fixed at 12 for
  /// the mockup rather than decaying with attempt count).
  void recordAttempt({
    required String conceptId,
    required bool correct,
    int hintsUsed = 0,
  }) {
    final current = state.mastery[conceptId] ?? ConceptMastery(conceptId: conceptId);
    final weight = hintsUsed == 0 ? 1.0 : (hintsUsed == 1 ? 0.6 : 0.35);
    const k = 12.0;
    final outcome = correct ? 1.0 : 0.0;
    final p = current.masteryPercent / 100;
    final delta = k * weight * (outcome - p);
    final newPercent = (current.masteryPercent + delta).clamp(0.0, 100.0);

    final MasteryState newState;
    if (newPercent >= 80) {
      newState = MasteryState.mastered;
    } else if (newPercent >= 50) {
      newState = MasteryState.practising;
    } else if (newPercent > 0) {
      newState = MasteryState.learning;
    } else {
      newState = MasteryState.notStarted;
    }

    final updated = ConceptMastery(
      conceptId: conceptId,
      masteryPercent: newPercent,
      attempts: current.attempts + 1,
      correct: current.correct + (correct ? 1 : 0),
      state: newState,
    );

    final newMastery = Map<String, ConceptMastery>.from(state.mastery);
    newMastery[conceptId] = updated;
    state = state.copyWith(mastery: newMastery);
  }

  void addXp(int amount) {
    state = state.copyWith(xpToday: state.xpToday + amount);
  }

  void resetXpForNewDay() {
    state = state.copyWith(xpToday: 0);
  }
}

final studentProvider = NotifierProvider<StudentNotifier, StudentState>(StudentNotifier.new);

import 'content_repository.dart';
import 'models.dart';

/// Curriculum content cache. Historically this held hardcoded CBSE Class 9
/// Maths data; it now holds a snapshot fetched from Supabase once at
/// startup (see `content_repository.dart` and `main.dart`'s loading gate),
/// but every other screen keeps reading `Content.chapters` etc. synchronously
/// so this phase's backend switch didn't require rewriting the UI screens.
///
/// This is a deliberate simplification (docs/PLAN.md-style tradeoff): content
/// only refreshes on app restart, not live. Fine for now — questions change
/// rarely and there's no realtime requirement yet.
class Content {
  Content._();

  static List<Chapter> _chapters = const [];
  static List<Question> _questions = const [];
  static List<Lesson> _lessons = const [];
  static List<Unit> _units = const [];
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  /// Populates the cache from a fetched snapshot. Call once at startup
  /// before any screen that reads `Content.*` is shown.
  static void load(ContentSnapshot snapshot) {
    _chapters = snapshot.chapters;
    _questions = snapshot.questions;
    _lessons = snapshot.lessons;
    _units = snapshot.units;
    _loaded = true;
  }

  static List<Chapter> get chapters => _chapters;
  static List<Question> get questions => _questions;
  static List<Lesson> get lessons => _lessons;

  static Chapter chapterOf(String conceptId) =>
      chapters.firstWhere((c) => c.concepts.any((k) => k.id == conceptId));

  static Concept conceptById(String id) =>
      chapters.expand((c) => c.concepts).firstWhere((c) => c.id == id);

  /// Null when [id] isn't in the loaded content — e.g. an old mastery row
  /// for a concept whose subject is no longer served.
  static Concept? conceptOrNull(String id) {
    for (final c in chapters.expand((c) => c.concepts)) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Question> forConcept(String conceptId) =>
      questions.where((q) => q.conceptId == conceptId).toList();

  static List<Question> forChapter(String chapterId) {
    final ids = chapters.firstWhere((c) => c.id == chapterId).concepts.map((c) => c.id).toSet();
    return questions.where((q) => ids.contains(q.conceptId)).toList();
  }

  /// The chapter's lessons, ordered by `sortOrder`. Empty for an unknown
  /// chapter or one with no lessons.
  static List<Lesson> lessonsForChapter(String chapterId) {
    final conceptIds = chapters
        .where((c) => c.id == chapterId)
        .expand((c) => c.concepts)
        .map((c) => c.id)
        .toSet();
    return lessons.where((l) => conceptIds.contains(l.conceptId)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  static List<Unit> get units => _units;

  /// A unit's chapters, in syllabus order (chapters load sorted by sort_order).
  static List<Chapter> chaptersInUnit(String unitId) =>
      chapters.where((c) => c.unitId == unitId).toList();

  /// The lesson that teaches [conceptId] (a topic's Learn node), if any.
  static Lesson? lessonForConcept(String conceptId) {
    final matches = lessons.where((l) => l.conceptId == conceptId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return matches.isEmpty ? null : matches.first;
  }

  /// The chapter's Trial levels in level order. Only live levels load, so
  /// the list can have gaps and be shorter than the 62 designed.
  static List<Question> trialLevels(String chapterId) {
    if (!chapters.any((c) => c.id == chapterId)) return const [];
    return forChapter(chapterId).where((q) => q.level != null).toList()
      ..sort((a, b) => a.level!.compareTo(b.level!));
  }

  /// Questions tagged for one node of a topic. Trial levels never count.
  static List<Question> nodeQuestions(String conceptId, TopicNode node) =>
      questions.where((q) => q.conceptId == conceptId && q.level == null && q.node == node).toList();

  /// Whether any node of this topic has questions. False turns on the
  /// interim rule: the topic is finished once its lesson is read.
  static bool hasTopicQuestions(String conceptId) =>
      questions.any((q) => q.conceptId == conceptId && q.level == null && q.node != null);

  /// A concept's practice pool: every question except Trial levels.
  static List<Question> practiceQuestions(String conceptId) =>
      questions.where((q) => q.conceptId == conceptId && q.level == null).toList();

  /// Whether a chapter has anything to open. Learn shows the rest as "Soon".
  static bool hasContent(String chapterId) {
    if (!chapters.any((c) => c.id == chapterId)) return false;
    return lessonsForChapter(chapterId).isNotEmpty || forChapter(chapterId).isNotEmpty;
  }
}

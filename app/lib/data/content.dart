import 'content_repository.dart';
import 'models.dart';

/// Curriculum content cache. Historically this held hardcoded CBSE Class 9
/// Maths+Science data; it now holds a snapshot fetched from Supabase once at
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
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  /// Populates the cache from a fetched snapshot. Call once at startup
  /// before any screen that reads `Content.*` is shown.
  static void load(ContentSnapshot snapshot) {
    _chapters = snapshot.chapters;
    _questions = snapshot.questions;
    _loaded = true;
  }

  static List<Chapter> get chapters => _chapters;
  static List<Question> get questions => _questions;

  static Chapter chapterOf(String conceptId) =>
      chapters.firstWhere((c) => c.concepts.any((k) => k.id == conceptId));

  static Concept conceptById(String id) =>
      chapters.expand((c) => c.concepts).firstWhere((c) => c.id == id);

  static List<Chapter> forSubject(Subject s) => chapters.where((c) => c.subject == s).toList();

  static List<Question> forConcept(String conceptId) =>
      questions.where((q) => q.conceptId == conceptId).toList();

  static List<Question> forChapter(String chapterId) {
    final ids = chapters.firstWhere((c) => c.id == chapterId).concepts.map((c) => c.id).toSet();
    return questions.where((q) => ids.contains(q.conceptId)).toList();
  }
}

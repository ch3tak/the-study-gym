import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Fetches curriculum content (subjects → chapters → concepts → questions,
/// plus theory lessons)
/// from Supabase. Called once at app startup; results are handed to
/// `Content.load()` so the rest of the app can keep reading `Content.*`
/// synchronously (see docs/PLAN.md §6 for the table shapes).
class ContentRepository {
  ContentRepository(this._client);

  /// Test-only constructor — no real Supabase client is touched by the
  /// methods exercised in tests (`questionFromRowForTesting`), so leaving
  /// `_client` uninitialized is safe here despite the field being typed
  /// non-nullable for production use. `late` defers the "no value" error
  /// until (and unless) something actually reads `_client`, which the
  /// testing-only methods never do; the brief's literal `null as
  /// SupabaseClient` was found to throw immediately under sound null
  /// safety, so this constructor deviates from that snippet to make the
  /// test actually pass.
  @visibleForTesting
  ContentRepository.forTesting();

  late final SupabaseClient _client;

  /// The class this alpha build serves. Hardcoded for now — becomes a
  /// profile-driven value once onboarding lets a student pick board/class.
  static const _classId = 'cbse_9';

  Future<ContentSnapshot> fetchAll() async {
    // Maths only, whatever a status flag says — the code filter is what
    // keeps a non-maths subject out, not `status`.
    final chapterRows = await _client
        .from('chapters')
        .select('id, subject_id, name, board_weight, sort_order, subjects!inner(class_id, code, status)')
        .eq('subjects.class_id', _classId)
        .eq('subjects.status', 'live')
        .eq('subjects.code', 'maths')
        .order('sort_order');

    final conceptRows = await _client
        .from('concepts')
        .select('id, chapter_id, name, sort_order')
        .order('sort_order');

    // Filtered client-side against this class's concept ids rather than a
    // subject_id column, since a question can span concepts and the class
    // scope is really defined by chapters → concepts, not the questions
    // table directly.
    final questionRows = await _client
        .from('questions')
        .select('id, concept_ids, difficulty, type, marks, body, level, stage')
        .eq('status', 'live');

    // Lessons are optional: a database without the lessons table (or a
    // failed fetch) gives an empty Theory tab, not a failed app start.
    List lessonRows = const [];
    try {
      lessonRows = await _client
          .from('lessons')
          .select('id, concept_id, title, body, hook_kind, hook, try_it, sort_order')
          .order('sort_order') as List;
    } on PostgrestException catch (e) {
      debugPrint('Lessons unavailable: ${e.message}');
    }

    return buildSnapshot(
      chapterRows: chapterRows as List,
      conceptRows: conceptRows as List,
      questionRows: questionRows as List,
      lessonRows: lessonRows,
    );
  }

  /// Turns raw rows into a snapshot. Pure (no network) so it's unit-tested
  /// directly. Re-checks `subjects.code` client-side as well as in the query.
  @visibleForTesting
  ContentSnapshot buildSnapshot({
    required List chapterRows,
    required List conceptRows,
    required List questionRows,
    List lessonRows = const [],
  }) {
    final mathsChapterRows =
        chapterRows.where((r) => (r['subjects'] as Map)['code'] == 'maths').toList();
    final validChapterIds = mathsChapterRows.map((r) => r['id'] as String).toSet();

    final conceptsByChapter = <String, List<Concept>>{};
    for (final row in conceptRows) {
      final chapterId = row['chapter_id'] as String;
      conceptsByChapter.putIfAbsent(chapterId, () => []).add(Concept(
            id: row['id'] as String,
            name: row['name'] as String,
            chapterId: chapterId,
          ));
    }
    final validConceptIds = conceptRows
        .where((r) => validChapterIds.contains(r['chapter_id']))
        .map((r) => r['id'] as String)
        .toSet();

    final chapters = <Chapter>[];
    for (final row in mathsChapterRows) {
      final chapterId = row['id'] as String;
      chapters.add(Chapter(
        id: chapterId,
        name: row['name'] as String,
        boardWeightMarks: (row['board_weight'] as num).round(),
        concepts: conceptsByChapter[chapterId] ?? const [],
      ));
    }

    final questions = <Question>[];
    for (final row in questionRows) {
      final conceptIds = (row['concept_ids'] as List).cast<String>();
      if (!conceptIds.any(validConceptIds.contains)) continue;
      final body = row['body'] as Map<String, dynamic>;
      try {
        questions.add(_questionFromRow(
          id: row['id'] as String,
          conceptId: conceptIds.first,
          type: row['type'] as String,
          difficulty: row['difficulty'] as int,
          marks: (row['marks'] as num).round(),
          body: body,
          level: row['level'] as int?,
          stage: row['stage'] as String?,
          allConceptIds: conceptIds,
        ));
      } on FormatException catch (e) {
        // One malformed row (e.g. a case_based question with no parts) is
        // skipped rather than failing the whole content load.
        debugPrint('Skipping malformed question ${row['id']}: ${e.message}');
      }
    }

    final lessons = <Lesson>[];
    for (final row in lessonRows) {
      if (!validConceptIds.contains(row['concept_id'])) continue;
      final hookKind = switch (row['hook_kind']) {
        'historical' => HookKind.historical,
        'real_world' => HookKind.realWorld,
        _ => null,
      };
      if (hookKind == null) {
        debugPrint('Skipping lesson ${row['id']}: unknown hook_kind ${row['hook_kind']}');
        continue;
      }
      lessons.add(Lesson(
        id: row['id'] as String,
        conceptId: row['concept_id'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        hookKind: hookKind,
        hook: row['hook'] as String,
        tryIt: row['try_it'] as String?,
        sortOrder: (row['sort_order'] as num).toInt(),
      ));
    }

    return ContentSnapshot(chapters: chapters, questions: questions, lessons: lessons);
  }

  @visibleForTesting
  Question questionFromRowForTesting({
    required String id,
    required String conceptId,
    required String type,
    required int difficulty,
    required int marks,
    required Map<String, dynamic> body,
    int? level,
    String? stage,
  }) =>
      _questionFromRow(
        id: id,
        conceptId: conceptId,
        type: type,
        difficulty: difficulty,
        marks: marks,
        body: body,
        level: level,
        stage: stage,
      );

  Question _questionFromRow({
    required String id,
    required String conceptId,
    required String type,
    required int difficulty,
    required int marks,
    required Map<String, dynamic> body,
    int? level,
    String? stage,
    List<String>? allConceptIds,
  }) {
    QuestionType questionType;
    switch (type) {
      case 'mcq':
        questionType = QuestionType.mcq;
      case 'numeric':
        questionType = QuestionType.numeric;
      case 'assertion_reason':
        questionType = QuestionType.assertionReason;
      case 'case_based':
        questionType = QuestionType.caseBased;
      case 'expression':
        questionType = QuestionType.expression;
      default:
        throw StateError('Unknown question type "$type" for question $id');
    }

    final distractorsRaw = (body['distractors'] as List?) ?? const [];
    final hintsRaw = (body['hints'] as List?) ?? const [];
    final stepsRaw = (body['solutionSteps'] as List?) ?? const [];
    final optionsRaw = (body['options'] as List?) ?? const [];
    final partsRaw = (body['parts'] as List?) ?? const [];

    final parts = <Question>[];
    for (var i = 0; i < partsRaw.length; i++) {
      final partBody = partsRaw[i] as Map<String, dynamic>;
      final partConceptIds = (partBody['concept_ids'] as List?)?.cast<String>() ?? [conceptId];
      parts.add(_questionFromRow(
        id: '${id}_part$i',
        conceptId: partConceptIds.first,
        type: partBody['type'] as String,
        difficulty: difficulty,
        marks: (partBody['marks'] as num).round(),
        body: partBody,
        allConceptIds: partConceptIds,
      ));
    }
    // A case_based question with no parts would have nothing to answer and
    // must never be able to "complete" vacuously — reject it here so
    // fetchAll skips the row.
    if (questionType == QuestionType.caseBased && parts.isEmpty) {
      throw FormatException('case_based question $id has no parts');
    }

    return Question(
      id: id,
      conceptId: conceptId,
      type: questionType,
      difficulty: difficulty,
      marks: marks,
      stem: body['stem'] as String,
      options: optionsRaw.cast<String>(),
      correctIndex: body['correctIndex'] as int?,
      numericAnswer: body['numericAnswer'] as String?,
      tolerance: (body['tolerance'] as num?)?.toDouble(),
      unit: body['unit'] as String?,
      assertion: body['assertion'] as String?,
      reason: body['reason'] as String?,
      hints: hintsRaw.cast<String>(),
      solutionSteps: stepsRaw.cast<String>(),
      distractors: distractorsRaw
          .map((d) => Distractor(
                optionIndex: d['optionIndex'] as int,
                explanation: d['explanation'] as String,
              ))
          .toList(),
      level: level,
      stage: stage,
      parts: parts,
      conceptIds: allConceptIds,
    );
  }
}

/// Plain data holder passed from the repository to `Content.load()`.
class ContentSnapshot {
  const ContentSnapshot({required this.chapters, required this.questions, this.lessons = const []});

  final List<Chapter> chapters;
  final List<Question> questions;
  final List<Lesson> lessons;
}

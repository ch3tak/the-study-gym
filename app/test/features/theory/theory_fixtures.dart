import 'dart:async';

import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_progress_repository.dart';

/// In-memory stand-in for the Supabase-backed repository. [fetchGate] and
/// [writeGate], when set, hold `fetchAll()` / `markRead()` open until the
/// test completes them.
class FakeTheoryRepo implements TheoryProgressRepository {
  FakeTheoryRepo({Set<String>? initial, this.failWrites = false}) : _initial = initial ?? {};
  final Set<String> _initial;
  final bool failWrites;
  final writes = <String>[];
  Completer<Set<String>>? fetchGate;
  Completer<void>? writeGate;

  @override
  Future<Set<String>> fetchAll() => fetchGate?.future ?? Future.value(_initial);

  @override
  Future<void> markRead(String lessonId) async {
    if (failWrites) throw Exception('offline');
    writes.add(lessonId);
    await writeGate?.future;
  }
}

const cube = Lesson(
  id: 't_cube',
  conceptId: 'c.cube',
  title: 'Cuboids & Cubes',
  body: 'A cube has 6 faces.',
  hookKind: HookKind.realWorld,
  hook: 'Boxes are cuboids.',
  tryIt: 'Measure a shoebox.',
  sortOrder: 1,
);

const pyramid = Lesson(
  id: 't_pyr',
  conceptId: 'c.pyr',
  title: 'Pyramids',
  body: 'A pyramid has an apex.',
  hookKind: HookKind.historical,
  hook: 'Egyptian scrolls.',
  sortOrder: 2,
);

/// Two chapters; only 'sav' has lessons (added out of order on purpose).
void loadTheoryContent() {
  Content.load(const ContentSnapshot(
    chapters: [
      Chapter(id: 'sav', name: 'Surface Areas and Volumes', boardWeightMarks: 6, concepts: [
        Concept(id: 'c.cube', name: 'Cube', chapterId: 'sav'),
        Concept(id: 'c.pyr', name: 'Pyramid', chapterId: 'sav'),
      ]),
      Chapter(id: 'seq', name: 'Sequences and Progressions', boardWeightMarks: 6, concepts: [
        Concept(id: 'c.ap', name: 'AP', chapterId: 'seq'),
      ]),
    ],
    questions: [],
    lessons: [pyramid, cube],
  ));
}

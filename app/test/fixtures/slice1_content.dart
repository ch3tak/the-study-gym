import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

/// A small course shaped like the real one, for Slice 1's tests:
/// - Sequences (Algebra): 12 practice questions, no lessons.
/// - Identities (Algebra): one topic with a lesson and node questions
///   (Guided ×2, Challenge ×1), so it does NOT use the interim rule.
/// - Triangles (Geometry): no content, so Learn shows "Soon".
/// - Surface Area and Volume (Mensuration): three lessons, no topic
///   questions (the interim rule), and a 10-level Trial, 2 per stage.
const seqChapter = 'sequences_progressions';
const idenChapter = 'algebraic_identities';
const triChapter = 'triangles';
const savChapter = 'surface_area_volume';

const stages = ['FOUNDATION', 'GUIDED_PRACTICE', 'SKILL_BUILDING', 'APPLICATION', 'MASTERY'];

Question fixtureQuestion(
  String id,
  String conceptId, {
  int difficulty = 1,
  TopicNode? node,
  int? level,
  String? stage,
  String? why,
}) =>
    Question(
      id: id,
      conceptId: conceptId,
      type: QuestionType.mcq,
      difficulty: difficulty,
      marks: 1,
      stem: 'Stem $id',
      options: const ['right', 'wrong'],
      correctIndex: 0,
      solutionSteps: ['Step for $id'],
      node: node,
      level: level,
      stage: stage,
      whyAfterPrevious: why,
    );

const cubeLesson = Lesson(
  id: 't_cube',
  conceptId: 'c.cube',
  title: 'Cuboids and cubes',
  body: 'A cube is a cuboid with equal edges.',
  hookKind: HookKind.realWorld,
  hook: 'Every shipping box is a cuboid.',
  sortOrder: 1,
);
const cylLesson = Lesson(
  id: 't_cyl',
  conceptId: 'c.cyl',
  title: 'Cylinders',
  body: 'A cylinder has two circular faces.',
  hookKind: HookKind.historical,
  hook: 'Archimedes asked for a cylinder on his tomb.',
  sortOrder: 2,
);
const coneLesson = Lesson(
  id: 't_cone',
  conceptId: 'c.cone',
  title: 'Cones',
  body: 'A cone is a third of its cylinder.',
  hookKind: HookKind.realWorld,
  hook: 'An ice-cream cone holds a third of the matching cylinder.',
  sortOrder: 3,
);
const idenLesson = Lesson(
  id: 't_iden',
  conceptId: 'c.iden',
  title: 'Square of a sum',
  body: 'a plus b, squared.',
  hookKind: HookKind.historical,
  hook: 'Euclid proved this with squares.',
  sortOrder: 1,
);

ContentSnapshot slice1Snapshot() => ContentSnapshot(
      units: const [
        Unit(id: 'u.algebra', name: 'Algebra', marks: 20, sortOrder: 1),
        Unit(id: 'u.geometry', name: 'Geometry', marks: 25, sortOrder: 2),
        Unit(id: 'u.mensuration', name: 'Mensuration', marks: 14, sortOrder: 3),
      ],
      chapters: const [
        Chapter(id: seqChapter, name: 'Sequences and Progressions', boardWeightMarks: 6, unitId: 'u.algebra', concepts: [
          Concept(id: 'c.ap', name: 'Arithmetic progressions', chapterId: seqChapter),
          Concept(id: 'c.gp', name: 'Geometric progressions', chapterId: seqChapter),
        ]),
        Chapter(id: idenChapter, name: 'Exploring Algebraic Identities', boardWeightMarks: 5, unitId: 'u.algebra', concepts: [
          Concept(id: 'c.iden', name: 'Square of a sum', chapterId: idenChapter),
        ]),
        Chapter(id: triChapter, name: 'Triangles', boardWeightMarks: 6, unitId: 'u.geometry', concepts: []),
        Chapter(id: savChapter, name: 'Surface Area and Volume', boardWeightMarks: 6, unitId: 'u.mensuration', concepts: [
          Concept(id: 'c.cube', name: 'Cuboids and cubes', chapterId: savChapter),
          Concept(id: 'c.cyl', name: 'Cylinders', chapterId: savChapter),
          Concept(id: 'c.cone', name: 'Cones', chapterId: savChapter),
        ]),
      ],
      questions: [
        // difficulty 1, 1, 2, 2, 3, 3 per concept
        for (final c in ['c.ap', 'c.gp'])
          for (var i = 1; i <= 6; i++) fixtureQuestion('q_${c}_$i', c, difficulty: (i + 1) ~/ 2),
        fixtureQuestion('q_iden_g1', 'c.iden', node: TopicNode.guided),
        fixtureQuestion('q_iden_g2', 'c.iden', node: TopicNode.guided),
        fixtureQuestion('q_iden_c1', 'c.iden', difficulty: 3, node: TopicNode.challenge),
        for (var l = 1; l <= 10; l++)
          fixtureQuestion('q_l$l', 'c.cube', level: l, stage: stages[(l - 1) ~/ 2], why: 'Why level $l comes next.'),
      ],
      lessons: const [cubeLesson, cylLesson, coneLesson, idenLesson],
    );

void loadSlice1Content() => Content.load(slice1Snapshot());

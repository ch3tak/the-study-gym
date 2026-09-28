import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

/// A small, in-memory Class 9 Maths fixture, used by widget tests so
/// they don't need a live Supabase fetch (see `StudyGymApp.contentLoader` in
/// main.dart). This is not the full seed data from
/// backend/supabase/seed/001_cbse_9_maths_science.sql — just enough for the
/// app's start-up test (widget_test.dart) to render.
Future<ContentSnapshot> fakeContentLoader() async {
  const chapters = <Chapter>[
    Chapter(
      id: 'sequences_progressions',
      name: 'Sequences and Progressions',
      boardWeightMarks: 6,
      concepts: [
        Concept(id: 'c9.seq.ap_nth_term', name: 'nth term of an AP', chapterId: 'sequences_progressions'),
      ],
    ),
    Chapter(
      id: 'surface_area_volume',
      name: 'Surface Areas and Volumes',
      boardWeightMarks: 6,
      concepts: [
        Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: 'surface_area_volume'),
      ],
    ),
  ];

  final questions = <Question>[
    Question(
      id: 'q_ap_nth_1',
      conceptId: 'c9.seq.ap_nth_term',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'The first term of an AP is 5 and the common difference is 3. What is its 12th term?',
      options: const ['38', '41', '33', '36'],
      correctIndex: 0,
      solutionSteps: const ['aₙ = a + (n − 1)d', 'aₙ = 5 + (11)(3) = 38'],
    ),
    Question(
      id: 'q_cube_1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'A cube has side 6 cm. Find its volume.',
      numericAnswer: '216',
      unit: 'cm^3',
      solutionSteps: const ['V = 6 × 6 × 6 = 216 cm³'],
    ),
  ];

  const lessons = <Lesson>[
    Lesson(
      id: 't_c9_sav_cuboid_cube',
      conceptId: 'c9.sav.cuboid_cube',
      title: 'Cuboids & Cubes',
      body: 'A cube is a cuboid with all sides equal.',
      hookKind: HookKind.realWorld,
      hook: 'Every cardboard box is a cuboid.',
      sortOrder: 1,
    ),
  ];

  return ContentSnapshot(chapters: chapters, questions: questions, lessons: lessons);
}

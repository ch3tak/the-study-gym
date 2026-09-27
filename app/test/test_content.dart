import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

/// A small, in-memory Class 9 Maths+Science fixture, used by widget tests so
/// they don't need a live Supabase fetch (see `StudyGymApp.contentLoader` in
/// main.dart). This is not the full seed data from
/// backend/supabase/seed/001_cbse_9_maths_science.sql — just enough for the
/// screens under test (Today, Skill Map, Workout, Tests) to render.
Future<ContentSnapshot> fakeContentLoader() async {
  const chapters = <Chapter>[
    Chapter(
      id: 'sequences_progressions',
      name: 'Sequences and Progressions',
      subject: Subject.maths,
      boardWeightMarks: 6,
      concepts: [
        Concept(id: 'c9.seq.ap_nth_term', name: 'nth term of an AP', chapterId: 'sequences_progressions'),
      ],
    ),
    Chapter(
      id: 'motion',
      name: 'Motion',
      subject: Subject.science,
      boardWeightMarks: 7,
      concepts: [
        Concept(id: 'c9.motion.speed_velocity', name: 'Speed and velocity', chapterId: 'motion'),
      ],
    ),
  ];

  const questions = <Question>[
    Question(
      id: 'q_ap_nth_1',
      conceptId: 'c9.seq.ap_nth_term',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'The first term of an AP is 5 and the common difference is 3. What is its 12th term?',
      options: ['38', '41', '33', '36'],
      correctIndex: 0,
      solutionSteps: ['aₙ = a + (n − 1)d', 'aₙ = 5 + (11)(3) = 38'],
    ),
    Question(
      id: 'q_speed_1',
      conceptId: 'c9.motion.speed_velocity',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'A car covers 150 km in 3 hours. Find its average speed.',
      numericAnswer: '50',
      unit: 'km/h',
      solutionSteps: ['Speed = 150 / 3 = 50 km/h'],
    ),
  ];

  return const ContentSnapshot(chapters: chapters, questions: questions);
}

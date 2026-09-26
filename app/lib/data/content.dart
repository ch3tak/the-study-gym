import 'models.dart';

/// Hardcoded CBSE Class 9 content for the mockup. Chapters/concepts are a
/// trimmed slice of content/syllabus/cbse/9/{maths,science}.yaml (real names
/// and ids, not placeholders). Questions are adapted from
/// content/questions/cbse/9/{maths,science}/golden.yaml plus a few extra
/// per concept so the workout player has enough variety to feel real.
class Content {
  Content._();

  static const chapters = <Chapter>[
    Chapter(
      id: 'sequences_progressions',
      name: 'Sequences and Progressions',
      subject: Subject.maths,
      boardWeightMarks: 6,
      concepts: [
        Concept(id: 'c9.seq.ap_nth_term', name: 'nth term of an AP', chapterId: 'sequences_progressions'),
        Concept(id: 'c9.seq.sum_natural', name: 'Sum of first n natural numbers', chapterId: 'sequences_progressions'),
        Concept(id: 'c9.seq.gp_nth_term', name: 'nth term of a GP', chapterId: 'sequences_progressions'),
        Concept(id: 'c9.seq.tower_of_hanoi', name: 'Tower of Hanoi', chapterId: 'sequences_progressions'),
      ],
    ),
    Chapter(
      id: 'algebraic_identities',
      name: 'Exploring Algebraic Identities',
      subject: Subject.maths,
      boardWeightMarks: 5,
      concepts: [
        Concept(id: 'c9.iden.standard', name: 'Standard identities', chapterId: 'algebraic_identities'),
        Concept(id: 'c9.iden.factorise_identities', name: 'Factorising with identities', chapterId: 'algebraic_identities'),
        Concept(id: 'c9.iden.factorise_quadratic', name: 'Factorising quadratics', chapterId: 'algebraic_identities'),
      ],
    ),
    Chapter(
      id: 'area_perimeter',
      name: 'Mensuration: Area and Perimeter',
      subject: Subject.maths,
      boardWeightMarks: 8,
      concepts: [
        Concept(id: 'c9.area.herons_formula', name: "Heron's formula", chapterId: 'area_perimeter'),
        Concept(id: 'c9.area.circle_area', name: 'Area of a circle', chapterId: 'area_perimeter'),
        Concept(id: 'c9.area.sector_segment', name: 'Sectors and segments', chapterId: 'area_perimeter'),
      ],
    ),
    Chapter(
      id: 'circles',
      name: 'Circles',
      subject: Subject.maths,
      boardWeightMarks: 6,
      concepts: [
        Concept(id: 'c9.circ.same_segment', name: 'Angles in the same segment', chapterId: 'circles'),
        Concept(id: 'c9.circ.cyclic_quadrilateral', name: 'Cyclic 4-gons', chapterId: 'circles'),
      ],
    ),
    Chapter(
      id: 'probability',
      name: 'Introduction to Probability',
      subject: Subject.maths,
      boardWeightMarks: 5,
      concepts: [
        Concept(id: 'c9.prob.theoretical', name: 'Theoretical probability', chapterId: 'probability'),
        Concept(id: 'c9.prob.tree_tables', name: 'Tree diagrams and tables', chapterId: 'probability'),
      ],
    ),
    Chapter(
      id: 'motion',
      name: 'Motion',
      subject: Subject.science,
      boardWeightMarks: 7,
      concepts: [
        Concept(id: 'c9.motion.speed_velocity', name: 'Speed and velocity', chapterId: 'motion'),
        Concept(id: 'c9.motion.acceleration', name: 'Acceleration', chapterId: 'motion'),
        Concept(id: 'c9.motion.velocity_time_graph', name: 'Velocity-time graphs', chapterId: 'motion'),
      ],
    ),
    Chapter(
      id: 'force_laws',
      name: 'Force and Laws of Motion',
      subject: Subject.science,
      boardWeightMarks: 6,
      concepts: [
        Concept(id: 'c9.force.second_law', name: "Newton's second law", chapterId: 'force_laws'),
        Concept(id: 'c9.force.third_law', name: "Newton's third law", chapterId: 'force_laws'),
      ],
    ),
    Chapter(
      id: 'work_energy',
      name: 'Work, Energy and Simple Machines',
      subject: Subject.science,
      boardWeightMarks: 5,
      concepts: [
        Concept(id: 'c9.work.kinetic_energy', name: 'Kinetic energy', chapterId: 'work_energy'),
        Concept(id: 'c9.work.conservation', name: 'Conservation of mechanical energy', chapterId: 'work_energy'),
      ],
    ),
    Chapter(
      id: 'sound',
      name: 'Sound',
      subject: Subject.science,
      boardWeightMarks: 5,
      concepts: [
        Concept(id: 'c9.sound.speed', name: 'Speed of sound', chapterId: 'sound'),
        Concept(id: 'c9.sound.echo_reverberation', name: 'Echo and reverberation', chapterId: 'sound'),
      ],
    ),
    Chapter(
      id: 'atoms_molecules',
      name: 'Atoms and Molecules',
      subject: Subject.science,
      boardWeightMarks: 8,
      concepts: [
        Concept(id: 'c9.atom.mass_number', name: 'Atomic number and mass number', chapterId: 'atoms_molecules'),
        Concept(id: 'c9.mol.molecular_mass', name: 'Molecular mass', chapterId: 'atoms_molecules'),
      ],
    ),
  ];

  static Chapter chapterOf(String conceptId) =>
      chapters.firstWhere((c) => c.concepts.any((k) => k.id == conceptId));

  static Concept conceptById(String id) =>
      chapters.expand((c) => c.concepts).firstWhere((c) => c.id == id);

  static List<Chapter> forSubject(Subject s) => chapters.where((c) => c.subject == s).toList();

  static final questions = <Question>[
    // --- Sequences and Progressions ---
    Question(
      id: 'q_ap_nth_1',
      conceptId: 'c9.seq.ap_nth_term',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'The first term of an AP is 5 and the common difference is 3. What is its 12th term?',
      options: const ['38', '41', '33', '36'],
      correctIndex: 0,
      distractors: const [
        Distractor(optionIndex: 1, explanation: "You used a + n·d instead of a + (n − 1)·d — that adds one extra step."),
        Distractor(optionIndex: 2, explanation: 'Check your multiplication: 11 × 3 should be 33, then add 5.'),
        Distractor(optionIndex: 3, explanation: 'This looks like you used n = 10 instead of n = 12.'),
      ],
      hints: const [
        'Use the formula aₙ = a + (n − 1)d.',
        'Here a = 5, d = 3, n = 12. Compute (12 − 1) × 3 first.',
      ],
      solutionSteps: const [
        'a = 5, d = 3, n = 12',
        'aₙ = a + (n − 1)d = 5 + (11)(3)',
        'aₙ = 5 + 33 = 38',
      ],
    ),
    Question(
      id: 'q_ap_nth_2',
      conceptId: 'c9.seq.ap_nth_term',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'An AP has first term 7 and common difference −2. Find its 15th term.',
      numericAnswer: '-21',
      unit: 'none',
      hints: const ['Remember d is negative here, so the terms decrease.'],
      solutionSteps: const [
        'a = 7, d = −2, n = 15',
        'aₙ = 7 + (14)(−2) = 7 − 28 = −21',
      ],
    ),
    Question(
      id: 'q_sum_natural_1',
      conceptId: 'c9.seq.sum_natural',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'Find the sum 1 + 2 + 3 + ⋯ + 50.',
      numericAnswer: '1275',
      unit: 'none',
      hints: const [r'Use n(n+1)/2.'],
      solutionSteps: const [r'50 × 51 / 2 = 1275'],
    ),
    Question(
      id: 'q_gp_nth_1',
      conceptId: 'c9.seq.gp_nth_term',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'What is the 8th term of the GP 3, 6, 12, 24, …?',
      options: const ['384', '768', '48', '279936'],
      correctIndex: 0,
      distractors: const [
        Distractor(optionIndex: 1, explanation: 'You used a·rⁿ instead of a·rⁿ⁻¹ — one power too many.'),
        Distractor(optionIndex: 2, explanation: 'This treats the growth as linear (multiplying by n) instead of exponential.'),
        Distractor(optionIndex: 3, explanation: 'This computes (a·r)ⁿ⁻¹ — multiply a and r once, not raise their product.'),
      ],
      hints: const [
        'Find a and r first: a = 3, r = 6/3 = 2.',
        'The nth term of a GP is a·rⁿ⁻¹.',
      ],
      solutionSteps: const [
        'a = 3, r = 2',
        'a₈ = 3 × 2⁷ = 3 × 128 = 384',
      ],
    ),
    Question(
      id: 'q_hanoi_1',
      conceptId: 'c9.seq.tower_of_hanoi',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'What is the minimum number of moves needed to solve the Tower of Hanoi with 5 discs?',
      numericAnswer: '31',
      unit: 'none',
      hints: const [
        'With 1, 2, 3 discs the minimum moves are 1, 3, 7 — spot the pattern.',
        'Mₙ = 2Mₙ₋₁ + 1, which gives Mₙ = 2ⁿ − 1.',
      ],
      solutionSteps: const ['Mₙ = 2ⁿ − 1', 'M₅ = 2⁵ − 1 = 31'],
    ),

    // --- Algebraic Identities ---
    Question(
      id: 'q_iden_1',
      conceptId: 'c9.iden.standard',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'Use an identity to compute 103².',
      numericAnswer: '10609',
      unit: 'none',
      hints: const [r'103² = (100 + 3)². Expand using (a + b)² = a² + 2ab + b².'],
      solutionSteps: const [
        '(100 + 3)² = 100² + 2(100)(3) + 3²',
        '= 10000 + 600 + 9 = 10609',
      ],
    ),
    Question(
      id: 'q_iden_factor_1',
      conceptId: 'c9.iden.factorise_identities',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'Factorise 9x² − 12x + 4.',
      options: const ['(3x − 2)²', '(3x + 2)²', '(3x − 4)(3x + 1)', '(9x − 4)(x − 1)'],
      correctIndex: 0,
      distractors: const [
        Distractor(optionIndex: 1, explanation: 'Check the sign of the middle term — it should give −12x, not +12x.'),
        Distractor(optionIndex: 2, explanation: 'This does not match the a² − 2ab + b² pattern here.'),
        Distractor(optionIndex: 3, explanation: 'Try expanding this — it will not give back the original expression.'),
      ],
      hints: const [r'Check whether it matches a² − 2ab + b².'],
      solutionSteps: const [
        '9x² = (3x)², 4 = 2², and 12x = 2 × 3x × 2',
        '9x² − 12x + 4 = (3x − 2)²',
      ],
    ),
    Question(
      id: 'q_iden_factor_2',
      conceptId: 'c9.iden.factorise_quadratic',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'Factorise x² + 7x + 12.',
      options: const ['(x + 3)(x + 4)', '(x + 2)(x + 6)', '(x + 1)(x + 12)', '(x − 3)(x − 4)'],
      correctIndex: 0,
      distractors: const [
        Distractor(optionIndex: 1, explanation: '2 × 6 = 12, but 2 + 6 = 8, not 7 — check your factor pair.'),
        Distractor(optionIndex: 2, explanation: '1 × 12 = 12, but 1 + 12 = 13, not 7.'),
        Distractor(optionIndex: 3, explanation: 'The signs are wrong: with +7x and +12, both factors need a plus sign.'),
      ],
      hints: const ['Find two numbers that multiply to 12 and add to 7.'],
      solutionSteps: const ['3 × 4 = 12 and 3 + 4 = 7', 'x² + 7x + 12 = (x + 3)(x + 4)'],
    ),

    // --- Mensuration ---
    Question(
      id: 'q_heron_1',
      conceptId: 'c9.area.herons_formula',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'A triangular garden has sides 13 m, 14 m and 15 m. Find its area.',
      numericAnswer: '84',
      unit: 'm^2',
      hints: const [
        'Start with the semi-perimeter s = (a + b + c) / 2.',
        'Area = √(s(s − a)(s − b)(s − c)).',
      ],
      solutionSteps: const [
        's = (13 + 14 + 15) / 2 = 21',
        'Area = √(21 × 8 × 7 × 6) = √7056',
        'Area = 84 m²',
      ],
    ),
    Question(
      id: 'q_circle_area_1',
      conceptId: 'c9.area.circle_area',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'Find the area of a circle with radius 7 cm. (Use π = 22/7)',
      numericAnswer: '154',
      unit: 'cm^2',
      hints: const [r'Area = πr².'],
      solutionSteps: const [r'Area = (22/7) × 7 × 7 = 154 cm²'],
    ),
    Question(
      id: 'q_sector_1',
      conceptId: 'c9.area.sector_segment',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'A sector of a circle of radius 14 cm has a central angle of 90°. Find its area. (π = 22/7)',
      options: const ['154 cm²', '616 cm²', '77 cm²', '44 cm²'],
      correctIndex: 0,
      distractors: const [
        Distractor(optionIndex: 1, explanation: 'This is the full circle area — you forgot to scale by θ/360°.'),
        Distractor(optionIndex: 2, explanation: 'Check your angle fraction: 90°/360° is 1/4, not 1/2.'),
        Distractor(optionIndex: 3, explanation: 'This looks like the arc length calculation, not the area.'),
      ],
      hints: const [r'Sector area = (θ/360°) × πr².'],
      solutionSteps: const [
        r'Area = (90/360) × (22/7) × 14 × 14',
        '= (1/4) × 616 = 154 cm²',
      ],
    ),

    // --- Circles ---
    Question(
      id: 'q_semicircle_1',
      conceptId: 'c9.circ.same_segment',
      type: QuestionType.assertionReason,
      difficulty: 1,
      marks: 1,
      stem: 'Read the Assertion (A) and Reason (R) and choose the correct option.',
      assertion: 'The angle in a semicircle is a right angle.',
      reason: 'The angle subtended by an arc at the centre is double the angle it subtends at any point on the remaining part of the circle.',
      options: const [
        'Both A and R are true, and R is the correct explanation of A.',
        'Both A and R are true, but R is not the correct explanation of A.',
        'A is true, but R is false.',
        'A is false, but R is true.',
      ],
      correctIndex: 0,
      hints: const [r"A semicircle's arc subtends 180° at the centre — what does that make the inscribed angle?"],
      solutionSteps: const [
        r"A semicircle's arc subtends 180° at the centre.",
        r'So it subtends 180°/2 = 90° at the circle: A is true, and R explains it.',
      ],
    ),
    Question(
      id: 'q_cyclic_1',
      conceptId: 'c9.circ.cyclic_quadrilateral',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'In a cyclic quadrilateral, one angle is 75°. Find the angle opposite to it.',
      numericAnswer: '105',
      unit: 'degrees',
      hints: const ['Opposite angles of a cyclic quadrilateral add up to 180°.'],
      solutionSteps: const ['180° − 75° = 105°'],
    ),

    // --- Probability ---
    Question(
      id: 'q_prob_1',
      conceptId: 'c9.prob.theoretical',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'A die is thrown once. What is the probability of getting a number greater than 4?',
      numericAnswer: '1/3',
      unit: 'none',
      hints: const ['Numbers greater than 4 on a die: 5 and 6.'],
      solutionSteps: const ['Favourable outcomes: {5, 6} → 2 outcomes', 'P = 2/6 = 1/3'],
    ),
    Question(
      id: 'q_prob_2',
      conceptId: 'c9.prob.tree_tables',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'Two fair coins are tossed together. What is the probability of getting exactly one head?',
      options: const ['1/2', '1/3', '1/4', '2/3'],
      correctIndex: 0,
      distractors: const [
        Distractor(optionIndex: 1, explanation: 'This treats HT and TH as one outcome — they are different, ordered outcomes.'),
        Distractor(optionIndex: 2, explanation: 'This is the probability of exactly two heads (HH), not exactly one.'),
        Distractor(optionIndex: 3, explanation: 'Recount the favourable outcomes: only HT and TH give exactly one head.'),
      ],
      hints: const ['List all 4 outcomes: HH, HT, TH, TT.'],
      solutionSteps: const ['Favourable: HT, TH → 2 outcomes', 'P = 2/4 = 1/2'],
    ),

    // --- Science: Motion ---
    Question(
      id: 'q_speed_1',
      conceptId: 'c9.motion.speed_velocity',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'A car covers 150 km in 3 hours. Find its average speed.',
      numericAnswer: '50',
      unit: 'km/h',
      hints: const ['Average speed = total distance ÷ total time.'],
      solutionSteps: const ['Speed = 150 / 3 = 50 km/h'],
    ),
    Question(
      id: 'q_accel_1',
      conceptId: 'c9.motion.acceleration',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'A bus moving at 10 m/s speeds up to 25 m/s in 5 s. Find its acceleration.',
      numericAnswer: '3',
      unit: 'm/s^2',
      hints: const ['Acceleration is the change in velocity divided by the time taken.'],
      solutionSteps: const [
        'a = (v − u) / t = (25 − 10) / 5',
        'a = 3 m/s²',
      ],
    ),
    Question(
      id: 'q_vt_graph_1',
      conceptId: 'c9.motion.velocity_time_graph',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'On a velocity-time graph, what does the area under the graph represent?',
      options: const ['Displacement', 'Acceleration', 'Speed', 'Force'],
      correctIndex: 0,
      distractors: const [
        Distractor(optionIndex: 1, explanation: "Acceleration is the graph's slope, not the area under it."),
        Distractor(optionIndex: 2, explanation: 'Speed is what the graph plots on the y-axis, not the area.'),
        Distractor(optionIndex: 3, explanation: 'Force is not read directly off a velocity-time graph.'),
      ],
      hints: const ['Think about what units you get when you multiply velocity by time.'],
      solutionSteps: const ['Area = velocity × time = displacement.'],
    ),

    // --- Science: Force ---
    Question(
      id: 'q_second_law_1',
      conceptId: 'c9.force.second_law',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'A force of 20 N acts on a mass of 4 kg. Find the acceleration produced.',
      numericAnswer: '5',
      unit: 'm/s^2',
      hints: const ['Use F = ma, and solve for a.'],
      solutionSteps: const ['a = F / m = 20 / 4 = 5 m/s²'],
    ),
    Question(
      id: 'q_third_law_1',
      conceptId: 'c9.force.third_law',
      type: QuestionType.assertionReason,
      difficulty: 1,
      marks: 1,
      stem: 'Read the Assertion (A) and Reason (R) and choose the correct option.',
      assertion: "When a swimmer pushes water backward, the water pushes the swimmer forward.",
      reason: "For every action, there is an equal and opposite reaction, and these two forces act on different bodies.",
      options: const [
        'Both A and R are true, and R is the correct explanation of A.',
        'Both A and R are true, but R is not the correct explanation of A.',
        'A is true, but R is false.',
        'A is false, but R is true.',
      ],
      correctIndex: 0,
      hints: const ["This is a classic application of Newton's third law."],
      solutionSteps: const [
        'The swimmer (action) pushes water backward.',
        'Water (reaction) pushes the swimmer forward — equal, opposite, different bodies. A is true and R explains it.',
      ],
    ),

    // --- Science: Work & Energy ---
    Question(
      id: 'q_ke_1',
      conceptId: 'c9.work.kinetic_energy',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'Find the kinetic energy of a 2 kg object moving at 3 m/s.',
      numericAnswer: '9',
      unit: 'J',
      hints: const [r'KE = ½mv².'],
      solutionSteps: const [r'KE = ½ × 2 × 3² = ½ × 2 × 9 = 9 J'],
    ),
    Question(
      id: 'q_conservation_1',
      conceptId: 'c9.work.conservation',
      type: QuestionType.numeric,
      difficulty: 3,
      marks: 3,
      stem: 'A 0.5 kg ball is dropped from 20 m. Taking g = 10 m/s², find its speed just before hitting the ground.',
      numericAnswer: '20',
      unit: 'm/s',
      hints: const [
        'All the potential energy converts to kinetic energy on the way down.',
        r'½mv² = mgh, so v = √(2gh).',
      ],
      solutionSteps: const [
        r'v = √(2 × 10 × 20) = √400',
        'v = 20 m/s',
      ],
    ),

    // --- Science: Sound ---
    Question(
      id: 'q_sound_speed_1',
      conceptId: 'c9.sound.speed',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'A sound wave has a frequency of 500 Hz and a wavelength of 0.68 m. Find its speed.',
      numericAnswer: '340',
      unit: 'm/s',
      hints: const ['Use v = fλ.'],
      solutionSteps: const ['v = 500 × 0.68 = 340 m/s'],
    ),
    Question(
      id: 'q_echo_1',
      conceptId: 'c9.sound.echo_reverberation',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'A person shouts near a cliff and hears the echo after 2 s. If the speed of sound is 340 m/s, find the distance to the cliff.',
      numericAnswer: '340',
      unit: 'm',
      hints: const ['The sound travels to the cliff and back, so remember to account for the round trip.'],
      solutionSteps: const [
        'Total distance = speed × time = 340 × 2 = 680 m',
        'Distance to cliff = 680 / 2 = 340 m',
      ],
    ),

    // --- Science: Atoms ---
    Question(
      id: 'q_neutrons_1',
      conceptId: 'c9.atom.mass_number',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'An atom of sodium has atomic number 11 and mass number 23. How many neutrons does it have?',
      numericAnswer: '12',
      unit: 'none',
      hints: const ['Mass number = protons + neutrons.'],
      solutionSteps: const ['Neutrons = 23 − 11 = 12'],
    ),
    Question(
      id: 'q_molmass_1',
      conceptId: 'c9.mol.molecular_mass',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 2,
      stem: 'Find the molecular mass of water, H₂O. (H = 1, O = 16)',
      numericAnswer: '18',
      unit: 'u',
      hints: const ['Add up the atomic masses of all atoms in the molecule, counting each one.'],
      solutionSteps: const ['H₂O has 2 H atoms and 1 O atom', '2(1) + 16 = 18 u'],
    ),
  ];

  static List<Question> forConcept(String conceptId) =>
      questions.where((q) => q.conceptId == conceptId).toList();

  static List<Question> forChapter(String chapterId) {
    final ids = chapters.firstWhere((c) => c.id == chapterId).concepts.map((c) => c.id).toSet();
    return questions.where((q) => ids.contains(q.conceptId)).toList();
  }
}

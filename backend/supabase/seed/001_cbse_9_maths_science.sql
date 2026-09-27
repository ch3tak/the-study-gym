-- Seed: CBSE Class 9 Maths + Science.
-- Mirrors app/lib/data/content.dart exactly (same ids, names, weights,
-- questions) so the app can switch from hardcoded content to real queries
-- without changing any displayed data. See docs/PLAN.md §4 and §6.
--
-- Run this AFTER the core_schema.sql migration, on a fresh database
-- (it assumes these rows don't already exist — safe to re-run only if you
-- truncate boards/classes/subjects/chapters/concepts/questions first).

begin;

-- ---------------------------------------------------------------------------
-- Curriculum spine
-- ---------------------------------------------------------------------------

insert into boards (id, name) values
  ('cbse', 'CBSE');

insert into classes (id, board_id, grade, academic_year) values
  ('cbse_9', 'cbse', 9, '2026-27');

insert into subjects (id, class_id, code, name, status, accent_color, sort_order) values
  ('cbse_9_maths',   'cbse_9', 'maths',   'Mathematics', 'live', '#4F46E5', 1),
  ('cbse_9_science', 'cbse_9', 'science', 'Science',     'live', '#059669', 2);

-- Chapters (id, subject, board_weight, sort_order) — matches Content.chapters.
insert into chapters (id, subject_id, name, board_weight, sort_order) values
  ('sequences_progressions', 'cbse_9_maths',   'Sequences and Progressions',        6, 1),
  ('algebraic_identities',   'cbse_9_maths',   'Exploring Algebraic Identities',    5, 2),
  ('area_perimeter',         'cbse_9_maths',   'Mensuration: Area and Perimeter',   8, 3),
  ('circles',                'cbse_9_maths',   'Circles',                          6, 4),
  ('probability',            'cbse_9_maths',   'Introduction to Probability',       5, 5),
  ('motion',                 'cbse_9_science', 'Motion',                           7, 1),
  ('force_laws',             'cbse_9_science', 'Force and Laws of Motion',         6, 2),
  ('work_energy',            'cbse_9_science', 'Work, Energy and Simple Machines', 5, 3),
  ('sound',                  'cbse_9_science', 'Sound',                            5, 4),
  ('atoms_molecules',        'cbse_9_science', 'Atoms and Molecules',              8, 5);

-- Concepts (id, chapter, name) — matches Content.chapters[*].concepts.
insert into concepts (id, chapter_id, name, sort_order) values
  ('c9.seq.ap_nth_term',            'sequences_progressions', 'nth term of an AP',                    1),
  ('c9.seq.sum_natural',            'sequences_progressions', 'Sum of first n natural numbers',       2),
  ('c9.seq.gp_nth_term',            'sequences_progressions', 'nth term of a GP',                     3),
  ('c9.seq.tower_of_hanoi',         'sequences_progressions', 'Tower of Hanoi',                       4),

  ('c9.iden.standard',              'algebraic_identities',   'Standard identities',                  1),
  ('c9.iden.factorise_identities',  'algebraic_identities',   'Factorising with identities',          2),
  ('c9.iden.factorise_quadratic',   'algebraic_identities',   'Factorising quadratics',               3),

  ('c9.area.herons_formula',        'area_perimeter',         'Heron''s formula',                     1),
  ('c9.area.circle_area',           'area_perimeter',         'Area of a circle',                     2),
  ('c9.area.sector_segment',        'area_perimeter',         'Sectors and segments',                 3),

  ('c9.circ.same_segment',          'circles',                'Angles in the same segment',           1),
  ('c9.circ.cyclic_quadrilateral',  'circles',                'Cyclic 4-gons',                        2),

  ('c9.prob.theoretical',           'probability',             'Theoretical probability',              1),
  ('c9.prob.tree_tables',           'probability',             'Tree diagrams and tables',             2),

  ('c9.motion.speed_velocity',      'motion',                  'Speed and velocity',                   1),
  ('c9.motion.acceleration',        'motion',                  'Acceleration',                         2),
  ('c9.motion.velocity_time_graph', 'motion',                  'Velocity-time graphs',                 3),

  ('c9.force.second_law',           'force_laws',              'Newton''s second law',                 1),
  ('c9.force.third_law',            'force_laws',              'Newton''s third law',                  2),

  ('c9.work.kinetic_energy',        'work_energy',             'Kinetic energy',                       1),
  ('c9.work.conservation',          'work_energy',             'Conservation of mechanical energy',    2),

  ('c9.sound.speed',                'sound',                   'Speed of sound',                       1),
  ('c9.sound.echo_reverberation',   'sound',                   'Echo and reverberation',               2),

  ('c9.atom.mass_number',           'atoms_molecules',         'Atomic number and mass number',        1),
  ('c9.mol.molecular_mass',         'atoms_molecules',         'Molecular mass',                       2);

-- ---------------------------------------------------------------------------
-- Questions
-- `body` holds everything type-specific (options, correctIndex, distractors,
-- numericAnswer, unit, assertion, reason, hints, solutionSteps), matching the
-- shape in docs/PLAN.md §4.2, trimmed to what content.dart's Question uses.
-- All questions here are pre-verified/hand-written (no SymPy step yet — this
-- is the same content already shipped in the app, not new content), so
-- status is 'live' and content_version is 1.
-- ---------------------------------------------------------------------------

insert into questions (id, subject_id, concept_ids, difficulty, type, marks, body, status, content_version) values

('q_ap_nth_1', 'cbse_9_maths', array['c9.seq.ap_nth_term'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'The first term of an AP is 5 and the common difference is 3. What is its 12th term?',
  'options', jsonb_build_array('38', '41', '33', '36'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'You used a + n·d instead of a + (n − 1)·d — that adds one extra step.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Check your multiplication: 11 × 3 should be 33, then add 5.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This looks like you used n = 10 instead of n = 12.')
  ),
  'hints', jsonb_build_array('Use the formula aₙ = a + (n − 1)d.', 'Here a = 5, d = 3, n = 12. Compute (12 − 1) × 3 first.'),
  'solutionSteps', jsonb_build_array('a = 5, d = 3, n = 12', 'aₙ = a + (n − 1)d = 5 + (11)(3)', 'aₙ = 5 + 33 = 38')
), 'live', 1),

('q_ap_nth_2', 'cbse_9_maths', array['c9.seq.ap_nth_term'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'An AP has first term 7 and common difference −2. Find its 15th term.',
  'numericAnswer', '-21', 'unit', 'none',
  'hints', jsonb_build_array('Remember d is negative here, so the terms decrease.'),
  'solutionSteps', jsonb_build_array('a = 7, d = −2, n = 15', 'aₙ = 7 + (14)(−2) = 7 − 28 = −21')
), 'live', 1),

('q_sum_natural_1', 'cbse_9_maths', array['c9.seq.sum_natural'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the sum 1 + 2 + 3 + ⋯ + 50.',
  'numericAnswer', '1275', 'unit', 'none',
  'hints', jsonb_build_array('Use n(n+1)/2.'),
  'solutionSteps', jsonb_build_array('50 × 51 / 2 = 1275')
), 'live', 1),

('q_gp_nth_1', 'cbse_9_maths', array['c9.seq.gp_nth_term'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'What is the 8th term of the GP 3, 6, 12, 24, …?',
  'options', jsonb_build_array('384', '768', '48', '279936'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'You used a·rⁿ instead of a·rⁿ⁻¹ — one power too many.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This treats the growth as linear (multiplying by n) instead of exponential.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This computes (a·r)ⁿ⁻¹ — multiply a and r once, not raise their product.')
  ),
  'hints', jsonb_build_array('Find a and r first: a = 3, r = 6/3 = 2.', 'The nth term of a GP is a·rⁿ⁻¹.'),
  'solutionSteps', jsonb_build_array('a = 3, r = 2', 'a₈ = 3 × 2⁷ = 3 × 128 = 384')
), 'live', 1),

('q_hanoi_1', 'cbse_9_maths', array['c9.seq.tower_of_hanoi'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'What is the minimum number of moves needed to solve the Tower of Hanoi with 5 discs?',
  'numericAnswer', '31', 'unit', 'none',
  'hints', jsonb_build_array('With 1, 2, 3 discs the minimum moves are 1, 3, 7 — spot the pattern.', 'Mₙ = 2Mₙ₋₁ + 1, which gives Mₙ = 2ⁿ − 1.'),
  'solutionSteps', jsonb_build_array('Mₙ = 2ⁿ − 1', 'M₅ = 2⁵ − 1 = 31')
), 'live', 1),

('q_iden_1', 'cbse_9_maths', array['c9.iden.standard'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Use an identity to compute 103².',
  'numericAnswer', '10609', 'unit', 'none',
  'hints', jsonb_build_array('103² = (100 + 3)². Expand using (a + b)² = a² + 2ab + b².'),
  'solutionSteps', jsonb_build_array('(100 + 3)² = 100² + 2(100)(3) + 3²', '= 10000 + 600 + 9 = 10609')
), 'live', 1),

('q_iden_factor_1', 'cbse_9_maths', array['c9.iden.factorise_identities'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Factorise 9x² − 12x + 4.',
  'options', jsonb_build_array('(3x − 2)²', '(3x + 2)²', '(3x − 4)(3x + 1)', '(9x − 4)(x − 1)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Check the sign of the middle term — it should give −12x, not +12x.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This does not match the a² − 2ab + b² pattern here.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Try expanding this — it will not give back the original expression.')
  ),
  'hints', jsonb_build_array('Check whether it matches a² − 2ab + b².'),
  'solutionSteps', jsonb_build_array('9x² = (3x)², 4 = 2², and 12x = 2 × 3x × 2', '9x² − 12x + 4 = (3x − 2)²')
), 'live', 1),

('q_iden_factor_2', 'cbse_9_maths', array['c9.iden.factorise_quadratic'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Factorise x² + 7x + 12.',
  'options', jsonb_build_array('(x + 3)(x + 4)', '(x + 2)(x + 6)', '(x + 1)(x + 12)', '(x − 3)(x − 4)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '2 × 6 = 12, but 2 + 6 = 8, not 7 — check your factor pair.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '1 × 12 = 12, but 1 + 12 = 13, not 7.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The signs are wrong: with +7x and +12, both factors need a plus sign.')
  ),
  'hints', jsonb_build_array('Find two numbers that multiply to 12 and add to 7.'),
  'solutionSteps', jsonb_build_array('3 × 4 = 12 and 3 + 4 = 7', 'x² + 7x + 12 = (x + 3)(x + 4)')
), 'live', 1),

('q_heron_1', 'cbse_9_maths', array['c9.area.herons_formula'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A triangular garden has sides 13 m, 14 m and 15 m. Find its area.',
  'numericAnswer', '84', 'unit', 'm^2',
  'hints', jsonb_build_array('Start with the semi-perimeter s = (a + b + c) / 2.', 'Area = √(s(s − a)(s − b)(s − c)).'),
  'solutionSteps', jsonb_build_array('s = (13 + 14 + 15) / 2 = 21', 'Area = √(21 × 8 × 7 × 6) = √7056', 'Area = 84 m²')
), 'live', 1),

('q_circle_area_1', 'cbse_9_maths', array['c9.area.circle_area'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the area of a circle with radius 7 cm. (Use π = 22/7)',
  'numericAnswer', '154', 'unit', 'cm^2',
  'hints', jsonb_build_array('Area = πr².'),
  'solutionSteps', jsonb_build_array('Area = (22/7) × 7 × 7 = 154 cm²')
), 'live', 1),

('q_sector_1', 'cbse_9_maths', array['c9.area.sector_segment'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A sector of a circle of radius 14 cm has a central angle of 90°. Find its area. (π = 22/7)',
  'options', jsonb_build_array('154 cm²', '616 cm²', '77 cm²', '44 cm²'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is the full circle area — you forgot to scale by θ/360°.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Check your angle fraction: 90°/360° is 1/4, not 1/2.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This looks like the arc length calculation, not the area.')
  ),
  'hints', jsonb_build_array('Sector area = (θ/360°) × πr².'),
  'solutionSteps', jsonb_build_array('Area = (90/360) × (22/7) × 14 × 14', '= (1/4) × 616 = 154 cm²')
), 'live', 1),

('q_semicircle_1', 'cbse_9_maths', array['c9.circ.same_segment'], 1, 'assertion_reason', 1, jsonb_build_object(
  'stem', 'Read the Assertion (A) and Reason (R) and choose the correct option.',
  'assertion', 'The angle in a semicircle is a right angle.',
  'reason', 'The angle subtended by an arc at the centre is double the angle it subtends at any point on the remaining part of the circle.',
  'options', jsonb_build_array(
    'Both A and R are true, and R is the correct explanation of A.',
    'Both A and R are true, but R is not the correct explanation of A.',
    'A is true, but R is false.',
    'A is false, but R is true.'
  ),
  'correctIndex', 0,
  'hints', jsonb_build_array('A semicircle''s arc subtends 180° at the centre — what does that make the inscribed angle?'),
  'solutionSteps', jsonb_build_array('A semicircle''s arc subtends 180° at the centre.', 'So it subtends 180°/2 = 90° at the circle: A is true, and R explains it.')
), 'live', 1),

('q_cyclic_1', 'cbse_9_maths', array['c9.circ.cyclic_quadrilateral'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'In a cyclic quadrilateral, one angle is 75°. Find the angle opposite to it.',
  'numericAnswer', '105', 'unit', 'degrees',
  'hints', jsonb_build_array('Opposite angles of a cyclic quadrilateral add up to 180°.'),
  'solutionSteps', jsonb_build_array('180° − 75° = 105°')
), 'live', 1),

('q_prob_1', 'cbse_9_maths', array['c9.prob.theoretical'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'A die is thrown once. What is the probability of getting a number greater than 4?',
  'numericAnswer', '1/3', 'unit', 'none',
  'hints', jsonb_build_array('Numbers greater than 4 on a die: 5 and 6.'),
  'solutionSteps', jsonb_build_array('Favourable outcomes: {5, 6} → 2 outcomes', 'P = 2/6 = 1/3')
), 'live', 1),

('q_prob_2', 'cbse_9_maths', array['c9.prob.tree_tables'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Two fair coins are tossed together. What is the probability of getting exactly one head?',
  'options', jsonb_build_array('1/2', '1/3', '1/4', '2/3'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This treats HT and TH as one outcome — they are different, ordered outcomes.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This is the probability of exactly two heads (HH), not exactly one.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Recount the favourable outcomes: only HT and TH give exactly one head.')
  ),
  'hints', jsonb_build_array('List all 4 outcomes: HH, HT, TH, TT.'),
  'solutionSteps', jsonb_build_array('Favourable: HT, TH → 2 outcomes', 'P = 2/4 = 1/2')
), 'live', 1),

('q_speed_1', 'cbse_9_science', array['c9.motion.speed_velocity'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'A car covers 150 km in 3 hours. Find its average speed.',
  'numericAnswer', '50', 'unit', 'km/h',
  'hints', jsonb_build_array('Average speed = total distance ÷ total time.'),
  'solutionSteps', jsonb_build_array('Speed = 150 / 3 = 50 km/h')
), 'live', 1),

('q_accel_1', 'cbse_9_science', array['c9.motion.acceleration'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'A bus moving at 10 m/s speeds up to 25 m/s in 5 s. Find its acceleration.',
  'numericAnswer', '3', 'unit', 'm/s^2',
  'hints', jsonb_build_array('Acceleration is the change in velocity divided by the time taken.'),
  'solutionSteps', jsonb_build_array('a = (v − u) / t = (25 − 10) / 5', 'a = 3 m/s²')
), 'live', 1),

('q_vt_graph_1', 'cbse_9_science', array['c9.motion.velocity_time_graph'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'On a velocity-time graph, what does the area under the graph represent?',
  'options', jsonb_build_array('Displacement', 'Acceleration', 'Speed', 'Force'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Acceleration is the graph''s slope, not the area under it.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Speed is what the graph plots on the y-axis, not the area.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Force is not read directly off a velocity-time graph.')
  ),
  'hints', jsonb_build_array('Think about what units you get when you multiply velocity by time.'),
  'solutionSteps', jsonb_build_array('Area = velocity × time = displacement.')
), 'live', 1),

('q_second_law_1', 'cbse_9_science', array['c9.force.second_law'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A force of 20 N acts on a mass of 4 kg. Find the acceleration produced.',
  'numericAnswer', '5', 'unit', 'm/s^2',
  'hints', jsonb_build_array('Use F = ma, and solve for a.'),
  'solutionSteps', jsonb_build_array('a = F / m = 20 / 4 = 5 m/s²')
), 'live', 1),

('q_third_law_1', 'cbse_9_science', array['c9.force.third_law'], 1, 'assertion_reason', 1, jsonb_build_object(
  'stem', 'Read the Assertion (A) and Reason (R) and choose the correct option.',
  'assertion', 'When a swimmer pushes water backward, the water pushes the swimmer forward.',
  'reason', 'For every action, there is an equal and opposite reaction, and these two forces act on different bodies.',
  'options', jsonb_build_array(
    'Both A and R are true, and R is the correct explanation of A.',
    'Both A and R are true, but R is not the correct explanation of A.',
    'A is true, but R is false.',
    'A is false, but R is true.'
  ),
  'correctIndex', 0,
  'hints', jsonb_build_array('This is a classic application of Newton''s third law.'),
  'solutionSteps', jsonb_build_array('The swimmer (action) pushes water backward.', 'Water (reaction) pushes the swimmer forward — equal, opposite, different bodies. A is true and R explains it.')
), 'live', 1),

('q_ke_1', 'cbse_9_science', array['c9.work.kinetic_energy'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'Find the kinetic energy of a 2 kg object moving at 3 m/s.',
  'numericAnswer', '9', 'unit', 'J',
  'hints', jsonb_build_array('KE = ½mv².'),
  'solutionSteps', jsonb_build_array('KE = ½ × 2 × 3² = ½ × 2 × 9 = 9 J')
), 'live', 1),

('q_conservation_1', 'cbse_9_science', array['c9.work.conservation'], 3, 'numeric', 3, jsonb_build_object(
  'stem', 'A 0.5 kg ball is dropped from 20 m. Taking g = 10 m/s², find its speed just before hitting the ground.',
  'numericAnswer', '20', 'unit', 'm/s',
  'hints', jsonb_build_array('All the potential energy converts to kinetic energy on the way down.', '½mv² = mgh, so v = √(2gh).'),
  'solutionSteps', jsonb_build_array('v = √(2 × 10 × 20) = √400', 'v = 20 m/s')
), 'live', 1),

('q_sound_speed_1', 'cbse_9_science', array['c9.sound.speed'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A sound wave has a frequency of 500 Hz and a wavelength of 0.68 m. Find its speed.',
  'numericAnswer', '340', 'unit', 'm/s',
  'hints', jsonb_build_array('Use v = fλ.'),
  'solutionSteps', jsonb_build_array('v = 500 × 0.68 = 340 m/s')
), 'live', 1),

('q_echo_1', 'cbse_9_science', array['c9.sound.echo_reverberation'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A person shouts near a cliff and hears the echo after 2 s. If the speed of sound is 340 m/s, find the distance to the cliff.',
  'numericAnswer', '340', 'unit', 'm',
  'hints', jsonb_build_array('The sound travels to the cliff and back, so remember to account for the round trip.'),
  'solutionSteps', jsonb_build_array('Total distance = speed × time = 340 × 2 = 680 m', 'Distance to cliff = 680 / 2 = 340 m')
), 'live', 1),

('q_neutrons_1', 'cbse_9_science', array['c9.atom.mass_number'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'An atom of sodium has atomic number 11 and mass number 23. How many neutrons does it have?',
  'numericAnswer', '12', 'unit', 'none',
  'hints', jsonb_build_array('Mass number = protons + neutrons.'),
  'solutionSteps', jsonb_build_array('Neutrons = 23 − 11 = 12')
), 'live', 1),

('q_molmass_1', 'cbse_9_science', array['c9.mol.molecular_mass'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'Find the molecular mass of water, H₂O. (H = 1, O = 16)',
  'numericAnswer', '18', 'unit', 'u',
  'hints', jsonb_build_array('Add up the atomic masses of all atoms in the molecule, counting each one.'),
  'solutionSteps', jsonb_build_array('H₂O has 2 H atoms and 1 O atom', '2(1) + 16 = 18 u')
), 'live', 1);

commit;

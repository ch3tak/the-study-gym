-- Complete the 8-chapter Class 9 Maths content: deletes the old, unsourced
-- mock questions for Sequences, Algebraic Identities, Area/Perimeter,
-- Circles, and Probability (from 001_cbse_9_maths_science.sql, written
-- before the curriculum blueprint existed), and replaces them with real
-- hand-authored questions against every skill in
-- docs/curriculum/class9_maths.md's Part 5 tables, including the brand-new
-- Number System chapter. Same authoring style as 002_m9_coord_poly.sql:
-- every numeric/algebraic answer checked by hand, every mcq's distractors
-- mapped to that skill's blueprint "common mistake" column.
--
-- Run this AFTER 20260928000000_m9_maths_remaining_chapters.sql (needs its
-- concept rows) and after 002_m9_coord_poly.sql (no hard dependency, but
-- keeps the numbering/ordering of seed files consistent).

begin;

-- ---------------------------------------------------------------------------
-- Delete the old mock questions for the 5 chapters being replaced.
-- (Coordinate Geometry and Linear Polynomials are untouched -- already real.)
-- After migration 20260927000000's array_replace, these old mock questions'
-- concept_ids now hold the NEW M9-* ids listed below, not their original
-- dotted-style ids.
--
-- Some of these old questions already have student attempts recorded
-- against them (attempts.question_id -> questions.id, no cascade), which
-- would otherwise block the delete with a foreign key violation. Since
-- these are unsourced mock questions being permanently retired (not
-- edited/replaced in place), we delete their attempt history along with
-- them -- that history has no ongoing analytical value once the question
-- itself no longer exists.
-- ---------------------------------------------------------------------------

delete from attempts where question_id in (
  select id from questions where concept_ids && array[
    'M9-SEQ-005', 'M9-SEQ-006', 'M9-SEQ-008', 'M9-SEQ-009',
    'M9-IDENT-002', 'M9-IDENT-003', 'M9-IDENT-005',
    'M9-MENS-006', 'M9-MENS-008', 'M9-MENS-008a',
    'M9-CIRC-007', 'M9-CIRC-009',
    'M9-PROB-003', 'M9-PROB-006'
  ]
);

delete from questions where concept_ids && array[
  'M9-SEQ-005', 'M9-SEQ-006', 'M9-SEQ-008', 'M9-SEQ-009',
  'M9-IDENT-002', 'M9-IDENT-003', 'M9-IDENT-005',
  'M9-MENS-006', 'M9-MENS-008', 'M9-MENS-008a',
  'M9-CIRC-007', 'M9-CIRC-009',
  'M9-PROB-003', 'M9-PROB-006'
];

insert into questions (id, subject_id, concept_ids, difficulty, type, marks, body, status, content_version) values

-- =============================================================================
-- NUMBER SYSTEM (NUM) -- Ganita Manjari Ch.3, "The World of Numbers"
-- =============================================================================

-- M9-NUM-001: Recall integer arithmetic
('q_m9_num_001_01', 'cbse_9_maths', array['M9-NUM-001'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the value of (−8) + 15 − 6.',
  'numericAnswer', '1', 'unit', 'none',
  'hints', jsonb_build_array('Work left to right: first combine −8 and 15.'),
  'solutionSteps', jsonb_build_array('(−8) + 15 = 7', '7 − 6 = 1')
), 'live', 1),
('q_m9_num_001_02', 'cbse_9_maths', array['M9-NUM-001'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the value of (−12) × (−3).',
  'numericAnswer', '36', 'unit', 'none',
  'hints', jsonb_build_array('A negative times a negative is positive.'),
  'solutionSteps', jsonb_build_array('(−12) × (−3) = 36 (both signs negative, so the product is positive)')
), 'live', 1),
('q_m9_num_001_03', 'cbse_9_maths', array['M9-NUM-001'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'What is (−7) − (−10)?',
  'options', jsonb_build_array('3', '−17', '17', '−3'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Subtracting a negative means adding its positive — this treats it as adding both negatives instead.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Check the final sign — combining −7 with +10 doesn''t give a number this large.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This drops the sign flip from subtracting a negative.')
  ),
  'hints', jsonb_build_array('Subtracting a negative number is the same as adding its positive.'),
  'solutionSteps', jsonb_build_array('(−7) − (−10) = (−7) + 10 = 3')
), 'live', 1),

-- M9-NUM-002: Understand zero as a mathematical concept
('q_m9_num_002_01', 'cbse_9_maths', array['M9-NUM-002'], 1, 'assertion_reason', 1, jsonb_build_object(
  'stem', 'Read the Assertion (A) and Reason (R) and choose the correct option.',
  'assertion', 'Zero is a number, not the absence of a number.',
  'reason', 'Zero has defined arithmetic: it can be added, subtracted, and multiplied, and it is the additive identity (n + 0 = n for any n).',
  'options', jsonb_build_array(
    'Both A and R are true, and R is the correct explanation of A.',
    'Both A and R are true, but R is not the correct explanation of A.',
    'A is true, but R is false.',
    'A is false, but R is true.'
  ),
  'correctIndex', 0,
  'hints', jsonb_build_array('Compare zero to "nothing" — can you do arithmetic with "nothing"?'),
  'solutionSteps', jsonb_build_array('Zero behaves like any other number under arithmetic rules (it has an additive identity property), which is exactly why it counts as a number rather than an absence of one.')
), 'live', 1),
('q_m9_num_002_02', 'cbse_9_maths', array['M9-NUM-002'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Which of these is NOT a valid statement about zero?',
  'options', jsonb_build_array(
    'Division by zero is defined and equals zero',
    'n + 0 = n for any number n',
    '0 × n = 0 for any number n',
    'Zero is neither positive nor negative'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is a true statement — zero is the additive identity.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This is also true — multiplying anything by zero gives zero.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This is true as well — zero sits exactly at the boundary between positive and negative.')
  ),
  'hints', jsonb_build_array('Division by zero is a special case in mathematics — think about what happens if you try to "undo" a multiplication by zero.'),
  'solutionSteps', jsonb_build_array('Division by zero is undefined, not equal to zero — this is the one false statement among the options.')
), 'live', 1),

-- M9-NUM-003: Represent rational numbers on the number line
('q_m9_num_003_01', 'cbse_9_maths', array['M9-NUM-003'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Which point is closer to 0 on the number line: 3/4 or 2/3?',
  'options', jsonb_build_array('2/3', '3/4', 'They are the same distance from 0', 'Cannot be determined'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Compare the two fractions with a common denominator before deciding — 3/4 is actually farther from 0.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'These fractions have different denominators, so they are not automatically equal — check by converting to a common denominator.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Both are positive rational numbers with different values — this can absolutely be determined.')
  ),
  'hints', jsonb_build_array('Convert both fractions to a common denominator (12ths) to compare them directly.'),
  'solutionSteps', jsonb_build_array('3/4 = 9/12, 2/3 = 8/12', '8/12 < 9/12, so 2/3 is closer to 0.')
), 'live', 1),
('q_m9_num_003_02', 'cbse_9_maths', array['M9-NUM-003'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Where does −5/2 lie on the number line?',
  'options', jsonb_build_array('Between −3 and −2', 'Between −2 and −1', 'Between 2 and 3', 'Exactly at −2'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Convert −5/2 to a decimal first (−2.5) to see where it actually falls.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This drops the negative sign — the fraction is negative, so it lies to the left of 0.'),
    jsonb_build_object('optionIndex', 3, 'explanation', '−5/2 is not a whole number, so it can''t sit exactly on an integer point.')
  ),
  'hints', jsonb_build_array('Convert −5/2 to a mixed number or decimal: it equals −2.5.'),
  'solutionSteps', jsonb_build_array('−5/2 = −2.5', '−2.5 lies between −3 and −2 on the number line.')
), 'live', 1),

-- M9-NUM-004: Understand the density of rational numbers
('q_m9_num_004_01', 'cbse_9_maths', array['M9-NUM-004'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'How many rational numbers lie strictly between 1/2 and 3/4?',
  'options', jsonb_build_array('Infinitely many', 'Exactly 1', 'Exactly 0', 'Exactly 2'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Try finding just one — you''ll notice you can always find another one between any two you pick.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '1/2 and 3/4 are different values, so there is room between them — e.g. 5/8 lies strictly between.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'There isn''t a fixed, finite count — between any two distinct rationals, more rationals can always be found.')
  ),
  'hints', jsonb_build_array('Try finding the average of 1/2 and 3/4 — is that number strictly between them? Can you repeat the process?'),
  'solutionSteps', jsonb_build_array('The average of 1/2 and 3/4 is 5/8, which lies strictly between them.', 'This averaging process can be repeated forever, producing infinitely many rationals between any two distinct rationals — this is the density property.')
), 'live', 1),
('q_m9_num_004_02', 'cbse_9_maths', array['M9-NUM-004'], 3, 'numeric', 1, jsonb_build_object(
  'stem', 'Find one rational number strictly between 1/3 and 1/2. (Give it as a fraction with denominator 6.)',
  'numericAnswer', '5/12', 'unit', 'none',
  'hints', jsonb_build_array('Averaging the two numbers always gives a value strictly between them.'),
  'solutionSteps', jsonb_build_array('Average of 1/3 and 1/2 = (1/3 + 1/2)/2 = (5/6)/2 = 5/12', '5/12 lies strictly between 1/3 (=4/12) and 1/2 (=6/12).')
), 'live', 1),

-- M9-NUM-005: Prove sqrt(2) is irrational
('q_m9_num_005_01', 'cbse_9_maths', array['M9-NUM-005'], 3, 'mcq', 3, jsonb_build_object(
  'stem', 'The proof that √2 is irrational starts by assuming √2 = p/q in lowest terms. What contradiction does this lead to?',
  'options', jsonb_build_array(
    'Both p and q turn out to be even, contradicting "lowest terms"',
    'p and q turn out to both be odd, which is impossible',
    'p turns out to be negative, which is impossible for a square root',
    'q turns out to equal zero, making the fraction undefined'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The actual contradiction is that BOTH p and q are shown to be even — not that they''re both odd.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'The proof never claims p is negative — it works entirely with the assumption that p and q are positive integers.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'q = 0 is ruled out from the start since p/q must be a valid fraction — that''s not where the contradiction comes from.')
  ),
  'hints', jsonb_build_array('If p²=2q², what does that tell you about whether p itself must be even?', 'If p is even, write p=2k and substitute back — what happens to q?'),
  'solutionSteps', jsonb_build_array('Assume √2 = p/q in lowest terms, so p² = 2q².', 'This means p² is even, so p itself must be even. Write p = 2k.', 'Substituting: (2k)² = 2q² → 4k² = 2q² → q² = 2k², so q is also even.', 'But p and q can''t both be even if p/q was in lowest terms — contradiction.')
), 'live', 1),
('q_m9_num_005_02', 'cbse_9_maths', array['M9-NUM-005'], 3, 'mcq', 1, jsonb_build_object(
  'stem', 'Why does this proof technique (proof by contradiction) work here?',
  'options', jsonb_build_array(
    'Because assuming the opposite of what we want to prove, and reaching an impossible result, means the opposite must be false',
    'Because it lets us skip checking any cases',
    'Because it only works for even numbers',
    'Because irrational numbers cannot be proven any other way'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The proof still carefully works through cases — it doesn''t skip anything, it derives a contradiction step by step.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'The technique itself has nothing specifically to do with evenness — evenness is just how this particular contradiction happens to arise.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Other proof techniques do exist for other numbers, though contradiction is a very common one for irrationality proofs.')
  ),
  'hints', jsonb_build_array('If assuming "√2 is rational" leads to something impossible, what does that say about the assumption?'),
  'solutionSteps', jsonb_build_array('In proof by contradiction, assuming a statement is false and reaching a logical impossibility proves the original statement must be true.')
), 'live', 1),

-- M9-NUM-006: Construct a length of sqrt(n)
('q_m9_num_006_01', 'cbse_9_maths', array['M9-NUM-006'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'To construct a length of √5 on the number line using a right triangle, which two leg lengths should you use?',
  'options', jsonb_build_array('1 and 2', '2 and 2', '1 and 4', '5 and 1'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Check: 2² + 2² = 8, and √8 ≠ √5.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Check: 1² + 4² = 17, and √17 ≠ √5.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Check: 5² + 1² = 26, and √26 ≠ √5 — this is much too large.')
  ),
  'hints', jsonb_build_array('You need two legs a and b where a² + b² = 5.'),
  'solutionSteps', jsonb_build_array('By the Pythagorean theorem, the hypotenuse of a right triangle with legs 1 and 2 is √(1²+2²) = √5.')
), 'live', 1),
('q_m9_num_006_02', 'cbse_9_maths', array['M9-NUM-006'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'In constructing √n as a hypotenuse, what mathematical result is being used?',
  'options', jsonb_build_array('The Pythagorean theorem', 'Heron''s formula', 'The distance formula on a number line only', 'Euclid''s fifth postulate'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Heron''s formula computes triangle area from side lengths — it isn''t what generates the length √n here.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This construction happens on a 2D plane using a right angle, not purely along a single number line.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The fifth postulate is about parallel lines, unrelated to this construction.')
  ),
  'hints', jsonb_build_array('This construction relies on right-triangle side-length relationships.'),
  'solutionSteps', jsonb_build_array('a² + b² = c² (Pythagorean theorem) lets you pick a, b so that c = √n exactly.')
), 'live', 1),

-- M9-NUM-007: Classify a decimal
('q_m9_num_007_01', 'cbse_9_maths', array['M9-NUM-007'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Which of these decimals is repeating (not terminating)?',
  'options', jsonb_build_array('0.333...', '0.25', '0.125', '0.5'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '0.25 stops after two digits — it terminates.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '0.125 stops after three digits — it terminates.'),
    jsonb_build_object('optionIndex', 3, 'explanation', '0.5 stops after one digit — it terminates.')
  ),
  'hints', jsonb_build_array('A repeating decimal has a block of digits that repeats forever.'),
  'solutionSteps', jsonb_build_array('0.333... = 1/3 has the digit 3 repeating forever — this is a repeating decimal.')
), 'live', 1),
('q_m9_num_007_02', 'cbse_9_maths', array['M9-NUM-007'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A decimal has digits that never repeat in any block and never terminate. What kind of number is it?',
  'options', jsonb_build_array('Irrational', 'Rational, terminating', 'Rational, repeating', 'An integer'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'A terminating decimal, by definition, does eventually stop — this one never does.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'A repeating decimal has a block that eventually repeats — this one has no such pattern at all.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Integers have no decimal part at all, let alone an infinite non-repeating one.')
  ),
  'hints', jsonb_build_array('Rational numbers always produce a decimal that either terminates or eventually repeats.'),
  'solutionSteps', jsonb_build_array('Every rational number, when written as a decimal, either terminates or repeats.', 'A decimal that does neither cannot come from a fraction of integers — it is irrational.')
), 'live', 1),

-- M9-NUM-008: Convert a repeating decimal to a fraction
('q_m9_num_008_01', 'cbse_9_maths', array['M9-NUM-008'], 3, 'numeric', 2, jsonb_build_object(
  'stem', 'Convert 0.777... (7 repeating) to a fraction in lowest terms. Give the numerator only (denominator is 9).',
  'numericAnswer', '7', 'unit', 'none',
  'hints', jsonb_build_array('Let x = 0.777..., then 10x = 7.777... . Subtract to eliminate the repeating part.'),
  'solutionSteps', jsonb_build_array('x = 0.777...', '10x = 7.777...', '10x − x = 7.777... − 0.777... = 7', '9x = 7, so x = 7/9')
), 'live', 1),
('q_m9_num_008_02', 'cbse_9_maths', array['M9-NUM-008'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'To convert 0.363636... (36 repeating) to a fraction, what should you multiply x by before subtracting?',
  'options', jsonb_build_array('100 (since the repeating block has 2 digits)', '10 (since it''s a repeating decimal)', '1000 (to be safe)', '2 (matching the number of digits some other way)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Multiplying by 10 only shifts one digit — but the repeating block here is 2 digits long, so 10x would not align the repeating parts for subtraction.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '1000 shifts three digits, which is one too many for a 2-digit repeating block — it would leave a leftover digit.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The multiplier should match the number of DIGITS in the repeating block (as a power of 10), not just any small number.')
  ),
  'hints', jsonb_build_array('The power of 10 you multiply by should shift the decimal exactly one full repeating block over.'),
  'solutionSteps', jsonb_build_array('The repeating block "36" has 2 digits, so multiply by 10² = 100.', '100x = 36.3636..., and 100x − x = 36, giving x = 36/99 = 4/11.')
), 'live', 1),

-- M9-NUM-009: Classify a number in the real number system
('q_m9_num_009_01', 'cbse_9_maths', array['M9-NUM-009'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Which statement about the number 4 is correct?',
  'options', jsonb_build_array(
    'It is a natural number, a whole number, an integer, and a rational number all at once',
    'It can only be classified as a natural number, not anything else',
    'It cannot be a rational number since it has no fraction part',
    'It is irrational because it has a square root that is a whole number'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'These categories are nested, not exclusive — every natural number is also a whole number, an integer, and a rational number.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'A number can be written as a fraction (4 = 4/1) and still be rational — having no explicit fraction part doesn''t exclude it.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This confuses "has a square root" with irrationality — 4''s square root (2) is itself rational, so 4 is rational too.')
  ),
  'hints', jsonb_build_array('Think of the number categories as nested circles, not separate boxes.'),
  'solutionSteps', jsonb_build_array('Natural numbers ⊂ whole numbers ⊂ integers ⊂ rational numbers ⊂ real numbers — 4 belongs to all of these nested sets.')
), 'live', 1),
('q_m9_num_009_02', 'cbse_9_maths', array['M9-NUM-009'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Which of these numbers is irrational?',
  'options', jsonb_build_array('√3', '√9', '−7', '0.5'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '√9 = 3 exactly — a whole number, so it''s rational.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '−7 is an integer, and every integer is rational.'),
    jsonb_build_object('optionIndex', 3, 'explanation', '0.5 = 1/2, a terminating decimal, so it''s rational.')
  ),
  'hints', jsonb_build_array('Check whether each square root simplifies to a whole number.'),
  'solutionSteps', jsonb_build_array('√3 does not simplify to a whole number and cannot be expressed as a fraction of integers — it is irrational.')
), 'live', 1),

-- =============================================================================
-- SEQUENCES AND PROGRESSIONS (SEQ) -- new skills (001-004,007), PLUS
-- replacements for 005,006,008,009 -- their old mock questions are deleted
-- above (they used unsourced content pre-dating the blueprint), so this
-- re-supplies real questions for those same skills rather than leaving them
-- with zero content.
-- =============================================================================

-- M9-SEQ-005: Find the nth term of an AP
('q_m9_seq_005_01', 'cbse_9_maths', array['M9-SEQ-005'], 2, 'mcq', 1, jsonb_build_object(
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
('q_m9_seq_005_02', 'cbse_9_maths', array['M9-SEQ-005'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'An AP has first term 7 and common difference −2. Find its 15th term.',
  'numericAnswer', '-21', 'unit', 'none',
  'hints', jsonb_build_array('Remember d is negative here, so the terms decrease.'),
  'solutionSteps', jsonb_build_array('a = 7, d = −2, n = 15', 'aₙ = 7 + (14)(−2) = 7 − 28 = −21')
), 'live', 1),

-- M9-SEQ-006: Sum of first n natural numbers
('q_m9_seq_006_01', 'cbse_9_maths', array['M9-SEQ-006'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the sum 1 + 2 + 3 + ... + 50.',
  'numericAnswer', '1275', 'unit', 'none',
  'hints', jsonb_build_array('Use n(n+1)/2.'),
  'solutionSteps', jsonb_build_array('50 × 51 / 2 = 1275')
), 'live', 1),
('q_m9_seq_006_02', 'cbse_9_maths', array['M9-SEQ-006'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A student computes 1+2+...+20 as "20 × 21" without dividing by 2, getting 420. What is the correct sum?',
  'options', jsonb_build_array('210', '420', '190', '400'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is exactly the student''s mistake — forgetting to divide by 2 after multiplying n by (n+1).'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This uses n(n-1) instead of n(n+1) — check the formula again.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This uses 20×20 instead of 20×21.')
  ),
  'hints', jsonb_build_array('The formula n(n+1)/2 pairs up terms — don''t forget the division by 2 at the end.'),
  'solutionSteps', jsonb_build_array('Correct formula: n(n+1)/2 = 20×21/2 = 420/2 = 210.')
), 'live', 1),

-- M9-SEQ-008: Find the nth term of a GP
('q_m9_seq_008_01', 'cbse_9_maths', array['M9-SEQ-008'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'What is the 8th term of the GP 3, 6, 12, 24, ...?',
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
('q_m9_seq_008_02', 'cbse_9_maths', array['M9-SEQ-008'], 2, 'numeric', 1, jsonb_build_object(
  'stem', 'A GP has first term 2 and common ratio 3. Find its 5th term.',
  'numericAnswer', '162', 'unit', 'none',
  'hints', jsonb_build_array('nth term of a GP = a·rⁿ⁻¹.'),
  'solutionSteps', jsonb_build_array('a₅ = 2 × 3⁴ = 2 × 81 = 162')
), 'live', 1),

-- M9-SEQ-009: Recognize a fractal / self-similar pattern as GP thinking
('q_m9_seq_009_01', 'cbse_9_maths', array['M9-SEQ-009'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'What is the minimum number of moves needed to solve the Tower of Hanoi with 5 discs?',
  'numericAnswer', '31', 'unit', 'none',
  'hints', jsonb_build_array('With 1, 2, 3 discs the minimum moves are 1, 3, 7 — spot the pattern.', 'Mₙ = 2Mₙ₋₁ + 1, which gives Mₙ = 2ⁿ − 1.'),
  'solutionSteps', jsonb_build_array('Mₙ = 2ⁿ − 1', 'M₅ = 2⁵ − 1 = 31')
), 'live', 1),
('q_m9_seq_009_02', 'cbse_9_maths', array['M9-SEQ-009'], 3, 'mcq', 1, jsonb_build_object(
  'stem', 'Each stage of a fractal pattern replaces every line segment with 4 smaller copies. If stage 0 has 1 segment, how many segments does stage 3 have?',
  'options', jsonb_build_array('64', '12', '81', '16'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This adds 4 each stage instead of multiplying by 4 — fractal growth is geometric, not arithmetic.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This uses 3⁴ instead of 4³ — check which number is the base and which is the exponent.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This is only 2 stages'' worth of growth (4²), not 3.')
  ),
  'hints', jsonb_build_array('Each stage multiplies the segment count by 4 — this is GP-style (geometric) growth, not additive.'),
  'solutionSteps', jsonb_build_array('Segments follow a GP: 1, 4, 16, 64, ... (a=1, r=4).', 'Stage 3 (the 4th term): 1 × 4³ = 64.')
), 'live', 1),

-- =============================================================================
-- SEQUENCES AND PROGRESSIONS (SEQ) continued -- genuinely new skills
-- =============================================================================

-- M9-SEQ-001: Identify a sequence and its terms
('q_m9_seq_001_01', 'cbse_9_maths', array['M9-SEQ-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'In the sequence 2, 5, 8, 11, ..., what is the 2nd term?',
  'options', jsonb_build_array('5', '2', '8', '3'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is the 1st term, not the 2nd.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This is the 3rd term.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This confuses the common difference (3) with an actual term of the sequence.')
  ),
  'hints', jsonb_build_array('The 2nd term is the second number listed, not its position number.'),
  'solutionSteps', jsonb_build_array('Counting from the start: 2 (1st), 5 (2nd), 8 (3rd), 11 (4th).')
), 'live', 1),
('q_m9_seq_001_02', 'cbse_9_maths', array['M9-SEQ-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'For the sequence with terms a₁=3, a₂=7, a₃=11, what does a₃ represent?',
  'options', jsonb_build_array('The 3rd term of the sequence, which is 11', 'The number 3 itself', 'The common difference', 'The number of terms in the whole sequence'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The subscript 3 is the position, not the value — a₃ means "the 3rd term," whose value happens to be 11.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'The common difference here is 4 (7−3), not what a₃ refers to.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'a₃ only tells you about one specific term, not the total count of terms.')
  ),
  'hints', jsonb_build_array('The subscript in aₙ tells you the POSITION in the sequence, and the value of aₙ is the term itself.'),
  'solutionSteps', jsonb_build_array('a₃ means "the 3rd term of the sequence," and here that value is 11.')
), 'live', 1),

-- M9-SEQ-002: Write an explicit rule for a sequence
('q_m9_seq_002_01', 'cbse_9_maths', array['M9-SEQ-002'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A sequence is 4, 9, 14, 19, ... Which explicit rule gives the nth term (n starting at 1)?',
  'options', jsonb_build_array('5n − 1', '5n + 4', '4n + 5', '5n − 4'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Check n=1: 5(1)+4 = 9, but the first term should be 4 — off by one position.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This mixes up which number is the common difference and which is the starting adjustment.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Check n=1: 5(1)−4 = 1, but the first term is 4.')
  ),
  'hints', jsonb_build_array('Find the common difference first, then test your rule at n=1.'),
  'solutionSteps', jsonb_build_array('Common difference = 5, so the rule has the form 5n + c.', 'At n=1: 5(1)+c = 4, so c = −1.', 'Rule: 5n − 1. Check n=2: 5(2)−1 = 9. Correct.')
), 'live', 1),
('q_m9_seq_002_02', 'cbse_9_maths', array['M9-SEQ-002'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A sequence''s explicit rule is 3n + 2. What is the 20th term?',
  'numericAnswer', '62', 'unit', 'none',
  'hints', jsonb_build_array('Substitute n = 20 into the rule.'),
  'solutionSteps', jsonb_build_array('3(20) + 2 = 60 + 2 = 62')
), 'live', 1),

-- M9-SEQ-003: Write a recursive rule for a sequence
('q_m9_seq_003_01', 'cbse_9_maths', array['M9-SEQ-003'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A sequence starts at 6 and each term is 4 more than the last. Which is the correct recursive rule?',
  'options', jsonb_build_array('a₁ = 6, aₙ = aₙ₋₁ + 4', 'aₙ = 4n + 6', 'a₁ = 6, aₙ = aₙ₋₁ × 4', 'aₙ = 6n + 4'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is the EXPLICIT rule, not a recursive one — a recursive rule must define a term using the previous term, not just n.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This uses multiplication, but the sequence increases by adding 4, not multiplying by 4.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This is also an explicit-style rule using n directly, and it doesn''t reference the previous term.')
  ),
  'hints', jsonb_build_array('A recursive rule defines each term in terms of the term right before it, plus a starting value.'),
  'solutionSteps', jsonb_build_array('Starting value: a₁ = 6.', 'Each next term adds 4 to the previous one: aₙ = aₙ₋₁ + 4.')
), 'live', 1),
('q_m9_seq_003_02', 'cbse_9_maths', array['M9-SEQ-003'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A sequence is defined by a₁ = 5, aₙ = aₙ₋₁ + 3. Find a₄.',
  'numericAnswer', '14', 'unit', 'none',
  'hints', jsonb_build_array('Build up the sequence one term at a time from a₁.'),
  'solutionSteps', jsonb_build_array('a₁ = 5', 'a₂ = 5+3 = 8', 'a₃ = 8+3 = 11', 'a₄ = 11+3 = 14')
), 'live', 1),

-- M9-SEQ-004: Identify an AP and its common difference
('q_m9_seq_004_01', 'cbse_9_maths', array['M9-SEQ-004'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the common difference of the AP: 12, 7, 2, −3, ...',
  'numericAnswer', '-5', 'unit', 'none',
  'hints', jsonb_build_array('Common difference = any term minus the term right before it.'),
  'solutionSteps', jsonb_build_array('7 − 12 = −5', '2 − 7 = −5', 'Common difference = −5')
), 'live', 1),
('q_m9_seq_004_02', 'cbse_9_maths', array['M9-SEQ-004'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Which of these is an arithmetic progression?',
  'options', jsonb_build_array('3, 6, 9, 12, ...', '3, 6, 12, 24, ...', '3, 9, 27, 81, ...', '3, 4, 9, 16, ...'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This doubles each time — a constant RATIO, not a constant difference. That''s a GP, not an AP.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This also multiplies by a constant ratio (3) each time — a GP, not an AP.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Check the differences: 1, 5, 7 — none of these are equal, so this is neither an AP nor a GP.')
  ),
  'hints', jsonb_build_array('An AP has a constant DIFFERENCE between consecutive terms; a GP has a constant RATIO.'),
  'solutionSteps', jsonb_build_array('3,6,9,12: differences are 3,3,3 — constant, so this is an AP.')
), 'live', 1),

-- M9-SEQ-007: Identify a GP and its common ratio
('q_m9_seq_007_01', 'cbse_9_maths', array['M9-SEQ-007'], 2, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the common ratio of the GP: 5, 15, 45, 135, ...',
  'numericAnswer', '3', 'unit', 'none',
  'hints', jsonb_build_array('Common ratio = any term divided by the term right before it.'),
  'solutionSteps', jsonb_build_array('15 / 5 = 3', '45 / 15 = 3', 'Common ratio = 3')
), 'live', 1),
('q_m9_seq_007_02', 'cbse_9_maths', array['M9-SEQ-007'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A GP has first term 4 and common ratio 1/2. What is its 3rd term?',
  'options', jsonb_build_array('1', '2', '8', '4'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is the 2nd term, not the 3rd — one step short.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This mixes up multiplying by the ratio versus adding it, and applies it to the wrong term.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This is just the first term unchanged — the ratio was never applied.')
  ),
  'hints', jsonb_build_array('Multiply by the common ratio each step: term1 → term2 → term3.'),
  'solutionSteps', jsonb_build_array('a₁=4', 'a₂ = 4×(1/2) = 2', 'a₃ = 2×(1/2) = 1')
), 'live', 1),

-- =============================================================================
-- EXPLORING ALGEBRAIC IDENTITIES (IDENT) -- new skills (001,004,006,007),
-- PLUS replacements for 002,003,005 (old mock questions deleted above).
-- =============================================================================

-- M9-IDENT-002: Expand (a+b)^2, (a-b)^2, (a+b)(a-b)
('q_m9_ident_002_01', 'cbse_9_maths', array['M9-IDENT-002'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Use an identity to compute 103².',
  'numericAnswer', '10609', 'unit', 'none',
  'hints', jsonb_build_array('103² = (100 + 3)². Expand using (a + b)² = a² + 2ab + b².'),
  'solutionSteps', jsonb_build_array('(100 + 3)² = 100² + 2(100)(3) + 3²', '= 10000 + 600 + 9 = 10609')
), 'live', 1),
('q_m9_ident_002_02', 'cbse_9_maths', array['M9-IDENT-002'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Expand (x − 5)².',
  'options', jsonb_build_array('x² − 10x + 25', 'x² − 25', 'x² + 10x + 25', 'x² − 10x − 25'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is (x+5)(x−5), the difference-of-squares identity, not (x−5)² — the middle term is missing entirely.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'The sign of the middle term is wrong — squaring a DIFFERENCE gives a NEGATIVE middle term, not positive.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The last term should be +25, not −25 — squaring −5 gives a positive result.')
  ),
  'hints', jsonb_build_array('(a−b)² = a² − 2ab + b² — watch both the middle term''s sign and the last term''s sign.'),
  'solutionSteps', jsonb_build_array('(x−5)² = x² − 2(x)(5) + 5² = x² − 10x + 25')
), 'live', 1),

-- M9-IDENT-003: Factorise using a known identity
('q_m9_ident_003_01', 'cbse_9_maths', array['M9-IDENT-003'], 2, 'mcq', 1, jsonb_build_object(
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
('q_m9_ident_003_02', 'cbse_9_maths', array['M9-IDENT-003'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Factorise 49 − x² using the difference-of-squares identity.',
  'options', jsonb_build_array('(7 − x)(7 + x)', '(7 − x)²', '(x − 7)(x − 7)', '(49 − x)(1 + x)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This drops the cross-term cancellation that makes difference-of-squares work — squaring one factor doesn''t give back the original expression.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This reverses the sign inside each factor incorrectly — check by expanding it.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This doesn''t use the identity structure at all — it just splits 49 and x arbitrarily.')
  ),
  'hints', jsonb_build_array('a² − b² = (a−b)(a+b). Here a=7, b=x.'),
  'solutionSteps', jsonb_build_array('49 − x² = 7² − x² = (7−x)(7+x)')
), 'live', 1),

-- M9-IDENT-005: Factorise without algebra tiles (symbolic method)
('q_m9_ident_005_01', 'cbse_9_maths', array['M9-IDENT-005'], 3, 'mcq', 1, jsonb_build_object(
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
('q_m9_ident_005_02', 'cbse_9_maths', array['M9-IDENT-005'], 3, 'mcq', 1, jsonb_build_object(
  'stem', 'Factorise x² − x − 6.',
  'options', jsonb_build_array('(x − 3)(x + 2)', '(x + 3)(x − 2)', '(x − 6)(x + 1)', '(x − 3)(x − 2)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This reverses which factor is negative and which is positive — check: (x+3)(x−2) expands to x²+x−6, wrong middle sign.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '−6 × 1 = −6, but −6 + 1 = −5, not −1.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Both factors negative would give +6 as the constant term (negative times negative), not −6.')
  ),
  'hints', jsonb_build_array('Find two numbers that multiply to −6 and add to −1.'),
  'solutionSteps', jsonb_build_array('−3 × 2 = −6 and −3 + 2 = −1', 'x² − x − 6 = (x − 3)(x + 2)')
), 'live', 1),

-- =============================================================================
-- EXPLORING ALGEBRAIC IDENTITIES (IDENT) continued -- genuinely new skills
-- =============================================================================

-- M9-IDENT-001: Visualise (a+b)^2 geometrically
('q_m9_ident_001_01', 'cbse_9_maths', array['M9-IDENT-001'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'In the area-model picture for (a+b)², a square of side (a+b) is split into 4 regions. What are they?',
  'options', jsonb_build_array(
    'A square of area a², a square of area b², and two rectangles each of area ab',
    'Two squares of area a² and two squares of area b²',
    'Four equal squares, each of area (a+b)²/4',
    'A square of area a², a square of area b², and a triangle of area ab'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'There is only one a²-square and one b²-square in this picture, plus two cross rectangles.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Splitting into 4 equal squares only works if a=b — in general the regions have different sizes.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The cross-term regions in this picture are rectangles (ab each), not a triangle.')
  ),
  'hints', jsonb_build_array('Draw a square with side (a+b), split into an a-length and b-length on each side, and look at the 4 resulting regions.'),
  'solutionSteps', jsonb_build_array('The big square splits into: an a×a square, a b×b square, and two a×b rectangles.', 'Total area = a² + b² + 2ab = (a+b)².')
), 'live', 1),
('q_m9_ident_001_02', 'cbse_9_maths', array['M9-IDENT-001'], 2, 'assertion_reason', 1, jsonb_build_object(
  'stem', 'Read the Assertion (A) and Reason (R) and choose the correct option.',
  'assertion', 'The identity (a+b)² = a² + 2ab + b² can be seen visually, not just algebraically.',
  'reason', 'A square of side (a+b) splits into an a² square, a b² square, and two ab rectangles, whose areas sum to (a+b)².',
  'options', jsonb_build_array(
    'Both A and R are true, and R is the correct explanation of A.',
    'Both A and R are true, but R is not the correct explanation of A.',
    'A is true, but R is false.',
    'A is false, but R is true.'
  ),
  'correctIndex', 0,
  'hints', jsonb_build_array('Does the area breakdown in R directly justify the identity in A?'),
  'solutionSteps', jsonb_build_array('The area decomposition described in R is exactly the geometric justification for the algebraic identity in A.')
), 'live', 1),

-- M9-IDENT-004: Use algebra tiles to factorise
('q_m9_ident_004_01', 'cbse_9_maths', array['M9-IDENT-004'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Using algebra tiles for x² + 6x + 9, how many "x" tiles and "1" tiles are arranged around the x² tile to form a square?',
  'options', jsonb_build_array('6 "x" tiles and 9 "1" tiles, forming a (x+3) by (x+3) square', '9 "x" tiles and 6 "1" tiles', '3 "x" tiles and 6 "1" tiles', '6 "x" tiles and 3 "1" tiles'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This swaps the tile counts — the middle term''s coefficient (6) tells you the number of x-tiles, and the constant (9) tells you the number of 1-tiles.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This undercounts the 1-tiles needed to complete the square shape.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This undercounts the 1-tiles as well.')
  ),
  'hints', jsonb_build_array('The coefficient of x tells you how many "x" tiles to use; the constant term tells you how many "1" tiles.'),
  'solutionSteps', jsonb_build_array('x² + 6x + 9 uses 1 x²-tile, 6 x-tiles, and 9 unit tiles, arranged into a (x+3)×(x+3) square.', 'This confirms x² + 6x + 9 = (x+3)².')
), 'live', 1),
('q_m9_ident_004_02', 'cbse_9_maths', array['M9-IDENT-004'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'When using algebra tiles for an expression with a NEGATIVE middle term, like x² − 4x + 4, what changes about the tile arrangement?',
  'options', jsonb_build_array(
    'The "x" tiles represent subtraction, so the square is built by removing area rather than adding it',
    'Negative middle terms cannot be represented with algebra tiles at all',
    'The tiles must all be a different color, but the arrangement is otherwise identical',
    'You need twice as many tiles as the positive case'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Negative-term expressions CAN be modeled — typically using a different tile color/orientation to represent subtraction.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Color alone doesn''t capture the mathematical meaning — the arrangement genuinely differs since area is being subtracted.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The number of tiles matches the coefficients directly (4 negative x-tiles, 4 unit tiles here) — not simply doubled.')
  ),
  'hints', jsonb_build_array('Algebra tiles usually use a different color or orientation to represent negative quantities.'),
  'solutionSteps', jsonb_build_array('x² − 4x + 4 = (x−2)² is modeled with negative x-tiles (representing subtraction) rather than added area.')
), 'live', 1),

-- M9-IDENT-006: Derive/apply extended identities
('q_m9_ident_006_01', 'cbse_9_maths', array['M9-IDENT-006'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'Expand (a+b+c)².',
  'options', jsonb_build_array('a² + b² + c² + 2ab + 2bc + 2ca', 'a² + b² + c²', 'a² + b² + c² + ab + bc + ca', 'a² + b² + c² + 2ab'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This drops all the cross terms — a 3-term square has more than just the squared terms.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'The cross terms need a factor of 2 each — this misses that doubling.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This only includes one of the three cross terms — bc and ca are missing.')
  ),
  'hints', jsonb_build_array('Don''t just extend (a+b)² by adding a c² term — every PAIR of the three terms contributes a cross term.'),
  'solutionSteps', jsonb_build_array('(a+b+c)² = (a+b+c)(a+b+c)', 'Expanding fully and collecting like terms gives a² + b² + c² + 2ab + 2bc + 2ca.')
), 'live', 1),
('q_m9_ident_006_02', 'cbse_9_maths', array['M9-IDENT-006'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'Which identity correctly expands a³ + b³?',
  'options', jsonb_build_array('(a+b)(a² − ab + b²)', '(a+b)(a² + ab + b²)', '(a+b)³', '(a−b)(a² + ab + b²)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The middle term inside the bracket should be −ab, not +ab — check by expanding and comparing to a³+b³.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '(a+b)³ expands to a³ + 3a²b + 3ab² + b³, which has extra terms beyond just a³+b³.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This factors a³ − b³ (with a minus), not a³ + b³.')
  ),
  'hints', jsonb_build_array('This is the "sum of cubes" identity — memorize its exact sign pattern, since it differs from (a+b)² and (a+b)³.'),
  'solutionSteps', jsonb_build_array('a³ + b³ = (a+b)(a² − ab + b²)', 'Expanding the right side confirms this matches a³ + b³ exactly.')
), 'live', 1),

-- M9-IDENT-007: Simplify a rational expression using identities
('q_m9_ident_007_01', 'cbse_9_maths', array['M9-IDENT-007'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'Simplify (x² − 9) / (x − 3), for x ≠ 3.',
  'options', jsonb_build_array('x + 3', 'x − 3', 'x² − 3', '9/x'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This just copies the denominator instead of actually cancelling the shared factor.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This cancels only part of the numerator incorrectly, rather than factoring it properly first.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This treats the expression as if you could cancel terms directly across the fraction, which isn''t valid.')
  ),
  'hints', jsonb_build_array('Factor the numerator first using the difference-of-squares identity: x² − 9 = (x−3)(x+3).'),
  'solutionSteps', jsonb_build_array('x² − 9 = (x−3)(x+3)', '(x−3)(x+3) / (x−3) = x+3, for x ≠ 3 (cancelling the shared factor, not individual terms)')
), 'live', 1),
('q_m9_ident_007_02', 'cbse_9_maths', array['M9-IDENT-007'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'A student simplifies (x² + 2x) / x as "2" by cancelling the x² with x and leaving 2x. What is wrong with this?',
  'options', jsonb_build_array(
    'You must factor the numerator first (x(x+2)) and cancel the common FACTOR x, not cancel individual terms across the fraction',
    'Nothing is wrong — 2 is the correct simplified answer',
    'The expression can''t be simplified at all',
    'The mistake is only in the sign, not the method'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The correct simplification is x+2, not 2 — check by testing a value like x=1: (1+2)/1 = 3, but the claimed answer would give 2.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'It can be simplified, just not the way this student did it.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The error is more fundamental than a sign — it''s cancelling terms instead of factors.')
  ),
  'hints', jsonb_build_array('Factor x out of the numerator first: x² + 2x = x(x+2). What can you cancel now?'),
  'solutionSteps', jsonb_build_array('x² + 2x = x(x+2)', 'x(x+2) / x = x+2 (cancelling the shared FACTOR x, valid for x≠0)', 'Cancelling individual terms (like x² with x) across a sum is not a valid algebraic operation.')
), 'live', 1),

-- =============================================================================
-- AREA AND PERIMETER (MENS) -- new skills (001,002,003,004,005,007), PLUS
-- replacements for 006,008,008a (old mock questions deleted above).
-- =============================================================================

-- M9-MENS-006: Apply Heron's formula
('q_m9_mens_006_01', 'cbse_9_maths', array['M9-MENS-006'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A triangular garden has sides 13 m, 14 m and 15 m. Find its area.',
  'numericAnswer', '84', 'unit', 'm^2',
  'hints', jsonb_build_array('Start with the semi-perimeter s = (a + b + c) / 2.', 'Area = √(s(s − a)(s − b)(s − c)).'),
  'solutionSteps', jsonb_build_array('s = (13 + 14 + 15) / 2 = 21', 'Area = √(21 × 8 × 7 × 6) = √7056', 'Area = 84 m²')
), 'live', 1),
('q_m9_mens_006_02', 'cbse_9_maths', array['M9-MENS-006'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A student computes the semi-perimeter of a triangle with sides 5, 6, 7 as "18" (just adding the sides). What went wrong?',
  'options', jsonb_build_array(
    'They forgot to divide the sum by 2 — the semi-perimeter is HALF the perimeter',
    'Nothing is wrong — 18 is correct',
    'They should have multiplied the sides instead of adding',
    'The formula only works for right triangles'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The semi-perimeter (s) is specifically HALF the total perimeter, by definition — 18 is the full perimeter, not the semi-perimeter.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Heron''s formula is built from adding the sides, then halving — not multiplying them.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Heron''s formula works for any triangle given its three side lengths, not just right triangles.')
  ),
  'hints', jsonb_build_array('"Semi" means half — the semi-perimeter is the perimeter divided by 2.'),
  'solutionSteps', jsonb_build_array('Perimeter = 5+6+7 = 18. Semi-perimeter s = 18/2 = 9, not 18.')
), 'live', 1),

-- M9-MENS-008: Area of a circle and a sector
('q_m9_mens_008_01', 'cbse_9_maths', array['M9-MENS-008'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the area of a circle with radius 7 cm. (Use π = 22/7)',
  'numericAnswer', '154', 'unit', 'cm^2',
  'hints', jsonb_build_array('Area = πr².'),
  'solutionSteps', jsonb_build_array('Area = (22/7) × 7 × 7 = 154 cm²')
), 'live', 1),
('q_m9_mens_008_02', 'cbse_9_maths', array['M9-MENS-008'], 2, 'numeric', 1, jsonb_build_object(
  'stem', 'A circle has diameter 20 cm. Find its area. (Use π = 3.14)',
  'numericAnswer', '314', 'unit', 'cm^2',
  'hints', jsonb_build_array('Find the radius first — it''s half the diameter.'),
  'solutionSteps', jsonb_build_array('radius = 20/2 = 10 cm', 'Area = 3.14 × 10² = 3.14 × 100 = 314 cm²')
), 'live', 1),

-- M9-MENS-008a: Sector area (kept as its own tracked skill per the blueprint
-- deviation noted in the prior migration -- finer-grained mastery here)
('q_m9_mens_008a_01', 'cbse_9_maths', array['M9-MENS-008a'], 2, 'mcq', 1, jsonb_build_object(
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
('q_m9_mens_008a_02', 'cbse_9_maths', array['M9-MENS-008a'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A sector has radius 6 cm and central angle 60°. Find its area (as a multiple of π, give just the numeric coefficient — e.g. for "6π", answer 6).',
  'numericAnswer', '6', 'unit', 'none',
  'hints', jsonb_build_array('Sector area = (θ/360°) × πr². Compute the coefficient of π.'),
  'solutionSteps', jsonb_build_array('Area = (60/360) × π × 6² = (1/6) × 36π = 6π')
), 'live', 1),

-- =============================================================================
-- AREA AND PERIMETER (MENS) continued -- genuinely new skills
-- =============================================================================

-- M9-MENS-001: Compute perimeter of standard polygons
('q_m9_mens_001_01', 'cbse_9_maths', array['M9-MENS-001'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the perimeter of a rectangle with length 12 cm and breadth 7 cm.',
  'numericAnswer', '38', 'unit', 'cm',
  'hints', jsonb_build_array('Perimeter of a rectangle = 2 × (length + breadth).'),
  'solutionSteps', jsonb_build_array('P = 2 × (12 + 7) = 2 × 19 = 38 cm')
), 'live', 1),
('q_m9_mens_001_02', 'cbse_9_maths', array['M9-MENS-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'A square has side 9 cm. What is its perimeter?',
  'options', jsonb_build_array('36 cm', '81 cm', '18 cm', '9 cm'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is the AREA (side²), not the perimeter.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This only doubles the side once — a square has 4 equal sides, not 2.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This is just the side length, not the total distance around the square.')
  ),
  'hints', jsonb_build_array('Perimeter of a square = 4 × side.'),
  'solutionSteps', jsonb_build_array('P = 4 × 9 = 36 cm')
), 'live', 1),

-- M9-MENS-002: Understand the C/D ratio (pi) empirically
('q_m9_mens_002_01', 'cbse_9_maths', array['M9-MENS-002'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'If you measure the circumference and diameter of any circle and divide C by D, what do you always get?',
  'options', jsonb_build_array('Approximately the same value, π (about 3.14159...)', 'A value that depends on how big the circle is', 'Exactly 22/7, with no rounding needed', 'A different ratio for every circle'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This ratio is the same for every circle, regardless of size — that''s exactly what makes π special.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '22/7 is a commonly used APPROXIMATION of π, not its exact value.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Every circle gives (approximately) the same ratio — that''s the whole point of defining π this way.')
  ),
  'hints', jsonb_build_array('Try this with circles of very different sizes — does the ratio change?'),
  'solutionSteps', jsonb_build_array('For any circle, C/D ≈ 3.14159... — this constant ratio is called π.')
), 'live', 1),
('q_m9_mens_002_02', 'cbse_9_maths', array['M9-MENS-002'], 2, 'numeric', 1, jsonb_build_object(
  'stem', 'A circle has a diameter of 14 cm. Using π = 22/7, find its circumference.',
  'numericAnswer', '44', 'unit', 'cm',
  'hints', jsonb_build_array('Circumference = π × diameter.'),
  'solutionSteps', jsonb_build_array('C = (22/7) × 14 = 44 cm')
), 'live', 1),

-- M9-MENS-003: Understand why pi is irrational
('q_m9_mens_003_01', 'cbse_9_maths', array['M9-MENS-003'], 3, 'mcq', 1, jsonb_build_object(
  'stem', 'Why is 22/7 not the "exact" value of π?',
  'options', jsonb_build_array(
    '22/7 is a rational number (a simple fraction), but π is irrational and cannot be written as an exact fraction',
    '22/7 is too small to ever be useful',
    'π only became irrational recently, after new discoveries',
    '22/7 is exactly correct, and "π" is just another name for it'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '22/7 is a perfectly useful and reasonably accurate approximation — that''s not the issue.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'π''s irrationality is a fixed mathematical fact, not something that "became" true at some point.'),
    jsonb_build_object('optionIndex', 3, 'explanation', '22/7 ≈ 3.142857..., while π ≈ 3.14159265... — they are close, but genuinely different numbers.')
  ),
  'hints', jsonb_build_array('Compare the decimal expansions of 22/7 and π — do they match forever, or only for the first few digits?'),
  'solutionSteps', jsonb_build_array('22/7 is a ratio of two integers, so it is rational by definition.', 'π cannot be written as any ratio of integers — its irrationality proof is far more advanced than √2''s, and is typically just stated (not proven) at this level.')
), 'live', 1),
('q_m9_mens_003_02', 'cbse_9_maths', array['M9-MENS-003'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Since π is irrational, what does that tell you about using 22/7 or 3.14 in calculations?',
  'options', jsonb_build_array(
    'They are approximations, and any answer computed with them is also approximate',
    'They give exact answers because they are "close enough"',
    'They cannot be used in any real calculation',
    'It means the circle itself is not a perfect shape'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '"Close enough" is not the same as exact — using an approximation for π means the final answer carries some rounding error too.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'These approximations are used constantly in real calculations — they''re just not perfectly exact.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'π being irrational is a property of the NUMBER, not a flaw in the circle''s shape.')
  ),
  'hints', jsonb_build_array('If the input to a calculation is approximate, what does that make the output?'),
  'solutionSteps', jsonb_build_array('Using 22/7 or 3.14 instead of π''s true value means any resulting area/circumference is an approximation, not an exact value.')
), 'live', 1),

-- M9-MENS-004: Compute arc length
('q_m9_mens_004_01', 'cbse_9_maths', array['M9-MENS-004'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A circle has radius 21 cm. Find the length of an arc that subtends a 60° angle at the centre. (Use π = 22/7)',
  'numericAnswer', '22', 'unit', 'cm',
  'hints', jsonb_build_array('Arc length = (θ/360°) × 2πr.'),
  'solutionSteps', jsonb_build_array('Arc length = (60/360) × 2 × (22/7) × 21', '= (1/6) × 132 = 22 cm')
), 'live', 1),
('q_m9_mens_004_02', 'cbse_9_maths', array['M9-MENS-004'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A student computing arc length for a 90° sector uses the full circumference instead of a quarter of it. What mistake is this?',
  'options', jsonb_build_array(
    'Forgetting to scale the circumference by the angle fraction (θ/360°)',
    'Using the wrong formula for circumference entirely',
    'Confusing radius with diameter',
    'There is no mistake — 90° always means using the full circumference'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The circumference formula itself may be fine — the issue is applying it to the whole circle instead of scaling for the sector''s angle.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This particular mistake isn''t about mixing up radius and diameter.'),
    jsonb_build_object('optionIndex', 3, 'explanation', '90° is only a quarter of the full 360°, so only 1/4 of the circumference should be used.')
  ),
  'hints', jsonb_build_array('An arc length is only a FRACTION of the full circumference, based on its angle out of 360°.'),
  'solutionSteps', jsonb_build_array('Arc length = (θ/360°) × circumference — for 90°, that fraction is 90/360 = 1/4, not the whole thing.')
), 'live', 1),

-- M9-MENS-005: Area of rectangle, parallelogram, triangle
('q_m9_mens_005_01', 'cbse_9_maths', array['M9-MENS-005'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'Find the area of a parallelogram with base 10 cm and height 6 cm.',
  'numericAnswer', '60', 'unit', 'cm^2',
  'hints', jsonb_build_array('Area of a parallelogram = base × height (perpendicular height, not the slant side).'),
  'solutionSteps', jsonb_build_array('Area = 10 × 6 = 60 cm²')
), 'live', 1),
('q_m9_mens_005_02', 'cbse_9_maths', array['M9-MENS-005'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A parallelogram has base 8 cm, a slant side of 6 cm, and a perpendicular height of 5 cm. What area should you use for the formula?',
  'options', jsonb_build_array('8 × 5 = 40 cm² (using the perpendicular height)', '8 × 6 = 48 cm² (using the slant side)', '(8+6) × 5 / 2', '8 × 6 × 5'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The slant side is NOT the height — using it directly overstates the area.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This applies a triangle-style averaging formula, which doesn''t apply to a parallelogram''s area.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This multiplies three lengths together, which doesn''t correspond to any area formula.')
  ),
  'hints', jsonb_build_array('Area of a parallelogram always uses the PERPENDICULAR height, never the slant side.'),
  'solutionSteps', jsonb_build_array('Area = base × perpendicular height = 8 × 5 = 40 cm².')
), 'live', 1),

-- M9-MENS-007: Squaring a rectangle
('q_m9_mens_007_01', 'cbse_9_maths', array['M9-MENS-007'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'What does it mean to "square a rectangle" (a classical construction attributed to the Śulbasūtras)?',
  'options', jsonb_build_array(
    'Constructing a square that has EXACTLY the same area as a given rectangle, using compass-and-straightedge steps',
    'Drawing a rectangle whose sides are all equal',
    'Approximating a rectangle''s area by rounding to the nearest square number',
    'Multiplying a rectangle''s length and breadth to get a decimal area value'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'A rectangle with all equal sides would just be a square already — that''s not what "squaring" refers to here.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This is an exact geometric construction, not an approximation.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This just computes the rectangle''s own area — it doesn''t construct an equal-area square.')
  ),
  'hints', jsonb_build_array('This is a geometric CONSTRUCTION (compass and straightedge), producing an exact result — not a calculation or approximation.'),
  'solutionSteps', jsonb_build_array('"Squaring a rectangle" means constructing (exactly, with geometric tools) a square whose area equals that of a given rectangle — an ancient technique described in the Śulbasūtras.')
), 'live', 1),
('q_m9_mens_007_02', 'cbse_9_maths', array['M9-MENS-007'], 3, 'numeric', 1, jsonb_build_object(
  'stem', 'A rectangle has area 36 cm². If it is "squared" (an equal-area square is constructed), what is the side length of that square?',
  'numericAnswer', '6', 'unit', 'cm',
  'hints', jsonb_build_array('The square''s area must equal 36 cm² — what side length gives that area?'),
  'solutionSteps', jsonb_build_array('Square area = side²= 36, so side = √36 = 6 cm.')
), 'live', 1),

-- =============================================================================
-- CIRCLES (CIRC) -- new skills (001-006,008), PLUS replacements for 007 and
-- the disclosed extra 009 (old mock questions deleted above).
-- =============================================================================

-- M9-CIRC-007: Apply the angle-subtended-by-an-arc theorem
('q_m9_circ_007_01', 'cbse_9_maths', array['M9-CIRC-007'], 1, 'assertion_reason', 1, jsonb_build_object(
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
('q_m9_circ_007_02', 'cbse_9_maths', array['M9-CIRC-007'], 2, 'numeric', 1, jsonb_build_object(
  'stem', 'An arc subtends an angle of 70° at a point on the remaining part of the circle. What angle does it subtend at the centre?',
  'numericAnswer', '140', 'unit', 'degrees',
  'hints', jsonb_build_array('The central angle is double the angle at the circumference, for the same arc.'),
  'solutionSteps', jsonb_build_array('Central angle = 2 × 70° = 140°')
), 'live', 1),

-- M9-CIRC-009 (disclosed extra, cyclic quadrilateral -- kept per prior migration's decision)
('q_m9_circ_009_01', 'cbse_9_maths', array['M9-CIRC-009'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'In a cyclic quadrilateral, one angle is 75°. Find the angle opposite to it.',
  'numericAnswer', '105', 'unit', 'degrees',
  'hints', jsonb_build_array('Opposite angles of a cyclic quadrilateral add up to 180°.'),
  'solutionSteps', jsonb_build_array('180° − 75° = 105°')
), 'live', 1),
('q_m9_circ_009_02', 'cbse_9_maths', array['M9-CIRC-009'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A quadrilateral has opposite angles 100° and 80°. Is it necessarily cyclic?',
  'options', jsonb_build_array(
    'Yes — its opposite angles are supplementary (sum to 180°), satisfying the cyclic condition',
    'No — a quadrilateral is never cyclic',
    'Only if all four sides are equal',
    'Cannot be determined from angles alone, ever'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Many quadrilaterals ARE cyclic — this claim is too absolute.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Equal sides isn''t the cyclic condition — supplementary opposite angles is.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The opposite-angle-sum condition is exactly the tool used to determine this from angles alone.')
  ),
  'hints', jsonb_build_array('Check: do the given opposite angles sum to 180°?'),
  'solutionSteps', jsonb_build_array('100° + 80° = 180° — the opposite angles are supplementary, so the quadrilateral is cyclic.')
), 'live', 1),

-- =============================================================================
-- CIRCLES (CIRC) continued -- genuinely new skills
-- =============================================================================

-- M9-CIRC-001: Define circle, radius, diameter, chord, arc, sector, segment
('q_m9_circ_001_01', 'cbse_9_maths', array['M9-CIRC-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'What is a chord of a circle?',
  'options', jsonb_build_array(
    'A line segment joining any two points on the circle',
    'A line segment from the centre to any point on the circle',
    'The region enclosed between a chord and one of its arcs',
    'The distance around the circle'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This describes a RADIUS, not a chord.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This describes a SEGMENT (the region), not the chord (the line) itself.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This describes the CIRCUMFERENCE, not a chord.')
  ),
  'hints', jsonb_build_array('A chord doesn''t have to pass through the centre — a diameter is just a special (longest) chord that does.'),
  'solutionSteps', jsonb_build_array('A chord is any line segment with both endpoints on the circle. A diameter is the special case that passes through the centre.')
), 'live', 1),
('q_m9_circ_001_02', 'cbse_9_maths', array['M9-CIRC-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'What is the difference between a sector and a segment of a circle?',
  'options', jsonb_build_array(
    'A sector is bounded by two radii and an arc; a segment is bounded by a chord and an arc',
    'They are two different names for exactly the same region',
    'A sector always has a larger area than a segment',
    'A segment always passes through the centre, but a sector never does'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'These are genuinely different shapes — a sector is "pie-slice" shaped, while a segment is bounded by a straight chord.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'The relative sizes can go either way depending on the specific circle and angle — there''s no fixed rule that one is always bigger.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Neither region is defined by passing through the centre — a sector''s two straight boundaries (radii) meet AT the centre, but that''s a different property.')
  ),
  'hints', jsonb_build_array('A sector looks like a "pie slice" (two straight radii + an arc). A segment is cut off by a single straight chord + an arc.'),
  'solutionSteps', jsonb_build_array('Sector: bounded by 2 radii and an arc. Segment: bounded by a chord and an arc.')
), 'live', 1),

-- M9-CIRC-002: Identify symmetries of a circle
('q_m9_circ_002_01', 'cbse_9_maths', array['M9-CIRC-002'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'How many lines of symmetry does a circle have?',
  'options', jsonb_build_array('Infinitely many (every diameter is a line of symmetry)', 'Exactly 4', 'Exactly 1', 'None — a circle has no lines of symmetry'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This undercounts significantly — every single diameter (and there are infinitely many) is a line of symmetry.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'A circle actually has far more symmetry than just one line — try rotating any diameter and checking.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'A circle is actually one of the MOST symmetric shapes possible, not the least.')
  ),
  'hints', jsonb_build_array('Try drawing several different diameters — is each one a valid line of symmetry?'),
  'solutionSteps', jsonb_build_array('Every diameter divides the circle into two identical mirror-image halves.', 'Since there are infinitely many possible diameters, a circle has infinitely many lines of symmetry.')
), 'live', 1),
('q_m9_circ_002_02', 'cbse_9_maths', array['M9-CIRC-002'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Does a circle have rotational symmetry?',
  'options', jsonb_build_array(
    'Yes — rotating it by any angle around its centre leaves it looking unchanged',
    'No — only shapes with straight edges can have rotational symmetry',
    'Yes, but only for rotations of exactly 90°',
    'Only if the circle''s radius is a whole number'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Rotational symmetry applies to curved shapes too — a circle is actually a prime example of it.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'A circle''s rotational symmetry isn''t limited to just 90° — ANY rotation around the centre leaves it unchanged.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The radius value (whole number or not) has nothing to do with whether the shape has rotational symmetry.')
  ),
  'hints', jsonb_build_array('Picture rotating a circle by, say, 10° around its centre — does it look any different?'),
  'solutionSteps', jsonb_build_array('A circle looks identical after a rotation by ANY angle around its centre — this is its rotational symmetry.')
), 'live', 1),

-- M9-CIRC-003: How many circles through 1/2/3 points
('q_m9_circ_003_01', 'cbse_9_maths', array['M9-CIRC-003'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'How many circles can pass through exactly one given point?',
  'options', jsonb_build_array('Infinitely many', 'Exactly one', 'Exactly zero', 'Exactly two'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'A single point places almost no constraint — many different circles of many sizes and centres can pass through it.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'A circle absolutely can be drawn through a single point — many, in fact.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This undercounts drastically — there''s no upper limit with only one point given.')
  ),
  'hints', jsonb_build_array('Think about how many different circles (of different sizes, with different centres) could all pass through the same single point.'),
  'solutionSteps', jsonb_build_array('A single point gives very little constraint — infinitely many circles of varying size and centre location can pass through it.')
), 'live', 1),
('q_m9_circ_003_02', 'cbse_9_maths', array['M9-CIRC-003'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'Given 3 points that are NOT all on one straight line (non-collinear), how many circles pass through all 3?',
  'options', jsonb_build_array('Exactly one', 'Infinitely many', 'Exactly zero', 'Exactly three'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is true for just 1 or 2 points, but 3 non-collinear points pin down the circle uniquely.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Non-collinear points CAN always be enclosed by exactly one circle — this is a key geometric fact.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'There is exactly one such circle, not three — three points don''t each get their own circle here.')
  ),
  'hints', jsonb_build_array('This works differently from the "3 collinear points" case — non-collinear points give a unique answer.'),
  'solutionSteps', jsonb_build_array('Given 3 non-collinear points, exactly one circle passes through all three — this circle is called the circumcircle of the triangle they form.')
), 'live', 1),

-- M9-CIRC-004: Relate a chord's length to subtended angle
('q_m9_circ_004_01', 'cbse_9_maths', array['M9-CIRC-004'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Two chords in the same circle are equal in length. What must be true of the angles they subtend at the centre?',
  'options', jsonb_build_array('The angles are equal', 'The angles are supplementary', 'One angle is always double the other', 'Nothing can be concluded about the angles'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This mixes up the equal-chords property with a different relationship (like the linear pair) that doesn''t apply here.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This mismatches the equal-chords theorem with the "angle at centre = 2× angle at circumference" theorem, which is a different relationship.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'There is in fact a clean, guaranteed relationship: equal chords subtend equal angles.')
  ),
  'hints', jsonb_build_array('Equal chords ↔ equal central angles is a direct, two-way relationship.'),
  'solutionSteps', jsonb_build_array('In the same circle, equal chords subtend equal angles at the centre (and the converse also holds).')
), 'live', 1),
('q_m9_circ_004_02', 'cbse_9_maths', array['M9-CIRC-004'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'If a chord subtends a LARGER angle at the centre than another chord in the same circle, what can you say about the chords'' lengths?',
  'options', jsonb_build_array('The chord with the larger angle is longer', 'The chord with the larger angle is shorter', 'They must be equal in length', 'No relationship exists between angle size and chord length'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This reverses the actual relationship — a bigger central angle corresponds to a LONGER chord, not shorter.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'They can only be equal if the angles themselves are equal — here the angles are different.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'There is in fact a consistent relationship between chord length and its subtended central angle, in the same circle.')
  ),
  'hints', jsonb_build_array('Picture a very small central angle versus a central angle close to 180° — which chord is longer?'),
  'solutionSteps', jsonb_build_array('In the same circle, a larger central angle corresponds to a longer chord.')
), 'live', 1),

-- M9-CIRC-005: Apply perpendicular-bisector-of-chord property
('q_m9_circ_005_01', 'cbse_9_maths', array['M9-CIRC-005'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A line from the centre of a circle bisects a chord. What must be true about that line?',
  'options', jsonb_build_array('It is perpendicular to the chord', 'It is parallel to the chord', 'It has the same length as the chord', 'It is a diameter'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'A line parallel to the chord would never even reach it to bisect it.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This property is about the ANGLE the line makes with the chord, not matching lengths.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This line from the centre to the chord''s midpoint is not itself a diameter — it''s a segment perpendicular to the chord.')
  ),
  'hints', jsonb_build_array('This is a specific theorem: a line from the centre to the MIDPOINT of a chord always makes a right angle with it.'),
  'solutionSteps', jsonb_build_array('The line from the centre that bisects a chord is always perpendicular to that chord.')
), 'live', 1),
('q_m9_circ_005_02', 'cbse_9_maths', array['M9-CIRC-005'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A student claims "any line through the centre bisects any chord it crosses." Is this always true?',
  'options', jsonb_build_array(
    'No — only the line PERPENDICULAR to the chord (passing through the centre) is guaranteed to bisect it',
    'Yes, any line through the centre always bisects every chord it crosses',
    'Only true for chords longer than the radius',
    'Only true if the chord is also a diameter'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is the misconception — a line through the centre at some OTHER angle to the chord will cross it but not necessarily at its midpoint.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Chord length doesn''t change which specific line bisects it — the correct condition is about the angle (perpendicularity), not length.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'If the chord IS a diameter, it passes through the centre itself, which is a different (trivial) case.')
  ),
  'hints', jsonb_build_array('Try drawing a chord and a line through the centre that crosses it at a slant, not a right angle — does it hit the exact midpoint?'),
  'solutionSteps', jsonb_build_array('Only the specific line through the centre that is PERPENDICULAR to the chord is guaranteed to bisect it — an arbitrary line through the centre generally is not.')
), 'live', 1),

-- M9-CIRC-006: Compare distances of unequal chords from centre
('q_m9_circ_006_01', 'cbse_9_maths', array['M9-CIRC-006'], 3, 'mcq', 1, jsonb_build_object(
  'stem', 'Of two unequal chords in the same circle, which one is farther from the centre?',
  'options', jsonb_build_array('The shorter chord', 'The longer chord', 'Both are always the same distance from the centre', 'It depends on the circle''s radius'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This reverses the actual relationship — the longer chord is actually CLOSER to the centre.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Unequal chords are, by this theorem, at different distances from the centre — not the same.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This relationship (shorter chord farther from centre) holds regardless of the specific radius.')
  ),
  'hints', jsonb_build_array('Picture a very short chord near the circle''s edge versus a very long chord (like a diameter) through the centre — which is farther from the centre?'),
  'solutionSteps', jsonb_build_array('Of two unequal chords in the same circle, the SHORTER one is farther from the centre (and the longer one is closer).')
), 'live', 1),
('q_m9_circ_006_02', 'cbse_9_maths', array['M9-CIRC-006'], 3, 'mcq', 1, jsonb_build_object(
  'stem', 'Which chord is closest to the centre of any circle?',
  'options', jsonb_build_array('The diameter — it passes exactly through the centre, at distance 0', 'The shortest possible chord', 'All chords are equally close to the centre', 'There is no single closest chord'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This has the relationship backwards — the SHORTEST chords are actually the FARTHEST from the centre, not the closest.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Chords of different lengths sit at genuinely different distances from the centre — they''re not all equal.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'There is in fact a well-defined closest chord — the diameter, at distance exactly 0.')
  ),
  'hints', jsonb_build_array('The longer a chord is, the closer it sits to the centre — what is the longest possible chord in a circle?'),
  'solutionSteps', jsonb_build_array('The diameter is the longest possible chord and passes directly through the centre, so its distance from the centre is 0 — the smallest possible distance.')
), 'live', 1),

-- M9-CIRC-008: Determine concyclicity of points
('q_m9_circ_008_01', 'cbse_9_maths', array['M9-CIRC-008'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'Four points form a quadrilateral where opposite angles sum to 180°. What does this tell you?',
  'options', jsonb_build_array('The four points are concyclic (lie on a common circle)', 'The quadrilateral must be a square', 'The points cannot lie on a common circle', 'The quadrilateral has no diagonals'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This condition doesn''t force a specific shape like a square — many different cyclic quadrilaterals satisfy it.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This is the OPPOSITE of the correct conclusion — supplementary opposite angles is exactly the condition for concyclicity.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Every quadrilateral has diagonals — this property is unrelated to concyclicity.')
  ),
  'hints', jsonb_build_array('This is the defining property of a "cyclic quadrilateral" — one whose vertices all lie on one circle.'),
  'solutionSteps', jsonb_build_array('A quadrilateral is cyclic (its 4 vertices lie on a common circle) exactly when its opposite angles are supplementary (sum to 180°).')
), 'live', 1),
('q_m9_circ_008_02', 'cbse_9_maths', array['M9-CIRC-008'], 3, 'mcq', 1, jsonb_build_object(
  'stem', 'A student assumes any 4 points are automatically concyclic without checking anything. What is wrong with this assumption?',
  'options', jsonb_build_array(
    'Concyclicity is a special condition — most sets of 4 points do NOT lie on a common circle, and it must be verified (e.g. via the opposite-angle condition)',
    'Nothing is wrong — any 4 points always lie on some circle',
    'It''s only a problem if the points form a straight line',
    'Concyclicity only applies to points inside a triangle'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'While any 3 non-collinear points do determine a unique circle, a 4th point generally will NOT also lie on that same circle unless a special condition holds.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Collinearity is a separate issue (collinear points can never all lie on one circle) — but even non-collinear points aren''t automatically concyclic.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Concyclicity is about points on a circle, not a triangle-specific concept.')
  ),
  'hints', jsonb_build_array('Any 3 non-collinear points determine a UNIQUE circle — what are the odds a random 4th point also happens to sit exactly on that same circle?'),
  'solutionSteps', jsonb_build_array('3 non-collinear points fix one specific circle. A 4th point lies on that same circle only in a special case — this must be checked, e.g. via the cyclic-quadrilateral opposite-angle condition, not assumed.')
), 'live', 1),

-- =============================================================================
-- INTRODUCTION TO PROBABILITY (PROB) -- new skills (001,002,004,005), PLUS
-- replacements for 003,006 (old mock questions deleted above).
-- =============================================================================

-- M9-PROB-003: Compute theoretical probability
('q_m9_prob_003_01', 'cbse_9_maths', array['M9-PROB-003'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'A die is thrown once. What is the probability of getting a number greater than 4?',
  'numericAnswer', '1/3', 'unit', 'none',
  'hints', jsonb_build_array('Numbers greater than 4 on a die: 5 and 6.'),
  'solutionSteps', jsonb_build_array('Favourable outcomes: {5, 6} → 2 outcomes', 'P = 2/6 = 1/3')
), 'live', 1),
('q_m9_prob_003_02', 'cbse_9_maths', array['M9-PROB-003'], 2, 'numeric', 1, jsonb_build_object(
  'stem', 'A bag has 4 red balls and 6 blue balls. If one ball is drawn at random, what is the probability it is red? (Give as a fraction, e.g. "2/5".)',
  'numericAnswer', '2/5', 'unit', 'none',
  'hints', jsonb_build_array('Total balls = 4 + 6 = 10. Probability = favourable / total.'),
  'solutionSteps', jsonb_build_array('P(red) = 4/10 = 2/5')
), 'live', 1),

-- M9-PROB-006: Use a tree diagram to enumerate outcomes
('q_m9_prob_006_01', 'cbse_9_maths', array['M9-PROB-006'], 2, 'mcq', 1, jsonb_build_object(
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
('q_m9_prob_006_02', 'cbse_9_maths', array['M9-PROB-006'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'A tree diagram for tossing 3 coins has how many final branches (leaf outcomes)?',
  'options', jsonb_build_array('8', '6', '3', '9'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This isn''t a power of 2 — each coin toss doubles the branches, so the total must be 2×2×2.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This confuses the number of stages (3 tosses) with the number of final outcomes.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This would be correct for 3 independent choices each with 3 options, not 2 (heads/tails).')
  ),
  'hints', jsonb_build_array('Each toss doubles the number of branches from the previous stage — start with 1 and double 3 times.'),
  'solutionSteps', jsonb_build_array('1 toss: 2 branches. 2 tosses: 4 branches. 3 tosses: 8 branches (2×2×2 = 2³).')
), 'live', 1),

-- =============================================================================
-- INTRODUCTION TO PROBABILITY (PROB) continued -- genuinely new skills
-- =============================================================================

-- M9-PROB-001: Understand randomness and the probability scale
('q_m9_prob_001_01', 'cbse_9_maths', array['M9-PROB-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'A fair coin has landed on heads 4 times in a row. What is the probability the next flip is heads?',
  'options', jsonb_build_array('1/2 — each flip is independent of previous ones', 'Less than 1/2, since heads is "due" for a break', 'More than 1/2, since heads is "on a streak"', 'Exactly 0, since it can''t happen a 5th time'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This is the "gambler''s fallacy" — a fair coin has no memory of past flips, so the streak doesn''t make tails more likely.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Past outcomes don''t influence future independent trials — the streak doesn''t make heads more likely either.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'A fair coin can absolutely land heads a 5th time — there is no rule against consecutive identical outcomes.')
  ),
  'hints', jsonb_build_array('Does a coin "remember" what it landed on before? Each flip is an independent event.'),
  'solutionSteps', jsonb_build_array('Since the coin is fair and each flip is independent, the probability of heads on any single flip is always 1/2, regardless of history.')
), 'live', 1),
('q_m9_prob_001_02', 'cbse_9_maths', array['M9-PROB-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'Where does an "impossible event" sit on the probability scale (from 0 to 1)?',
  'options', jsonb_build_array('At 0', 'At 1', 'At 0.5', 'Anywhere below 0.5'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'A probability of 1 represents a CERTAIN event, not an impossible one.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '0.5 represents an event that is equally likely to happen or not — not something impossible.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Only the single value 0 represents "impossible" — values just below 0.5 still represent perfectly possible (if unlikely) events.')
  ),
  'hints', jsonb_build_array('The probability scale runs from 0 (impossible) to 1 (certain).'),
  'solutionSteps', jsonb_build_array('An impossible event has probability exactly 0.')
), 'live', 1),

-- M9-PROB-002: Compute experimental (empirical) probability
('q_m9_prob_002_01', 'cbse_9_maths', array['M9-PROB-002'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'A coin is flipped 50 times and lands heads 28 times. What is the experimental probability of heads (as a decimal)?',
  'numericAnswer', '0.56', 'unit', 'none',
  'hints', jsonb_build_array('Experimental probability = number of favourable outcomes ÷ total number of trials.'),
  'solutionSteps', jsonb_build_array('P(heads) = 28/50 = 0.56')
), 'live', 1),
('q_m9_prob_002_02', 'cbse_9_maths', array['M9-PROB-002'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A die is rolled 60 times; a "6" comes up 15 times. A student says the experimental probability of rolling a 6 is "15." What is wrong?',
  'options', jsonb_build_array(
    'They forgot to divide by the total number of trials (60) — probability should be a fraction/ratio, not a raw count',
    'Nothing is wrong — 15 is the correct probability',
    'They should have divided by 6 instead of 60',
    'The die must be unfair since 6 came up so often'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'A probability must be between 0 and 1 — a raw count like 15 (bigger than 1) cannot be a valid probability value.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'The total number of TRIALS is what belongs in the denominator (60), not the number of faces on the die.'),
    jsonb_build_object('optionIndex', 3, 'explanation', '15 out of 60 rolls (25%) is not unusually high for a fair die — this isn''t evidence of unfairness on its own.')
  ),
  'hints', jsonb_build_array('Probability is always a fraction between 0 and 1 — it''s a RATE, not a raw frequency count.'),
  'solutionSteps', jsonb_build_array('Experimental probability = (favourable outcomes) / (total trials) = 15/60 = 0.25, not 15.')
), 'live', 1),

-- M9-PROB-004: Identify sample space
('q_m9_prob_004_01', 'cbse_9_maths', array['M9-PROB-004'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'What is the sample space for rolling a single standard 6-sided die?',
  'options', jsonb_build_array('{1, 2, 3, 4, 5, 6}', '{1, 2, 3}', '{even, odd}', '{6}'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This misses half the possible outcomes — a standard die has 6 faces, not 3.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This groups outcomes into just 2 categories, but the sample space needs every individual possible outcome listed.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This lists just one possible outcome, not the full set of all outcomes.')
  ),
  'hints', jsonb_build_array('The sample space is the set of ALL possible individual outcomes, not a summary or a single result.'),
  'solutionSteps', jsonb_build_array('A standard die can land on any of 6 faces, so the sample space is {1, 2, 3, 4, 5, 6}.')
), 'live', 1),
('q_m9_prob_004_02', 'cbse_9_maths', array['M9-PROB-004'], 2, 'mcq', 2, jsonb_build_object(
  'stem', 'What is the sample space for tossing two coins together?',
  'options', jsonb_build_array('{HH, HT, TH, TT}', '{HH, TT}', '{H, T}', '{HH, HT, TT}'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This misses the two "one head, one tail" outcomes — HT and TH are different, ordered outcomes.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This describes the sample space for a SINGLE coin toss, not two coins together.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This drops HT as a separate outcome from TH, undercounting the full sample space by one.')
  ),
  'hints', jsonb_build_array('Since the coins are distinguishable (e.g. "first coin" and "second coin"), HT and TH count as two separate outcomes.'),
  'solutionSteps', jsonb_build_array('Each coin has 2 possible outcomes, so there are 2×2 = 4 total: {HH, HT, TH, TT}.')
), 'live', 1),

-- M9-PROB-005: Identify events (simple/compound)
('q_m9_prob_005_01', 'cbse_9_maths', array['M9-PROB-005'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'When rolling a die, "getting a number greater than 4" describes which outcomes?',
  'options', jsonb_build_array('{5, 6}', '{4, 5, 6}', '{1, 2, 3, 4}', '{5}'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This includes 4 itself, but "greater than 4" means strictly more than 4 — 4 does not qualify.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This lists numbers 4 or less, not the numbers greater than 4.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This lists only one of the two qualifying outcomes — 6 is also greater than 4.')
  ),
  'hints', jsonb_build_array('"Greater than 4" means strictly more than 4 — does that include 4 itself?'),
  'solutionSteps', jsonb_build_array('Numbers on a die strictly greater than 4: 5 and 6. So the event is {5, 6}.')
), 'live', 1),
('q_m9_prob_005_02', 'cbse_9_maths', array['M9-PROB-005'], 3, 'mcq', 1, jsonb_build_object(
  'stem', 'For tossing two coins, "at least one head" and "exactly one head" — are these the same event?',
  'options', jsonb_build_array(
    'No — "at least one head" includes HH, HT, TH, while "exactly one head" includes only HT, TH',
    'Yes, they describe exactly the same set of outcomes',
    'No — "exactly one head" is the larger set of the two',
    'They can''t be compared since they involve different coins'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '"At least one" and "exactly one" are subtly different wordings that lead to different outcome sets — check whether HH belongs to each.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This has the sizes backwards — "at least one head" is actually the LARGER set here (it includes HH too).'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Both phrases describe outcomes from the very same two-coin experiment — they can be compared directly.')
  ),
  'hints', jsonb_build_array('Does HH (two heads) count as "at least one head"? Does it count as "exactly one head"?'),
  'solutionSteps', jsonb_build_array('"At least one head" = {HH, HT, TH} (includes 1 or 2 heads).', '"Exactly one head" = {HT, TH} only (excludes HH). These are different events.')
), 'live', 1);

commit;

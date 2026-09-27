-- Seed: Class 9 Maths MVP content — Coordinate Geometry (M9-COORD) and
-- Introduction to Linear Polynomials (M9-POLY), per
-- docs/curriculum/class9_maths.md Part 5 and Part 19's MVP recommendation.
--
-- Hand-written (not yet run through the generate.py/validate.py pipeline in
-- docs/PLAN.md §4.3, which doesn't exist as code yet — see that section's
-- decision to hand-write a first batch rather than wait on tooling). Every
-- numeric/expression answer here was checked by hand; each question maps to
-- exactly one skill id from the blueprint, and every mcq's distractors map to
-- that skill's "common mistake" from the blueprint's Part 5 table.
--
-- Run this AFTER 20260927000000_m9_maths_id_convention_and_new_chapters.sql
-- (needs its M9-COORD-*/M9-POLY-* concept rows to exist first).

begin;

insert into questions (id, subject_id, concept_ids, difficulty, type, marks, body, status, content_version) values

-- ---------------------------------------------------------------------------
-- M9-COORD-001: Understand the need for a coordinate system
-- ---------------------------------------------------------------------------

('q_m9_coord_001_01', 'cbse_9_maths', array['M9-COORD-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'Why do we need both an x-coordinate and a y-coordinate to describe a point''s position on a plane?',
  'options', jsonb_build_array(
    'A single number can''t distinguish between all the different points on a flat surface',
    'It makes the numbers look more balanced',
    'Only the x-coordinate actually matters for finding a point',
    'Two numbers are required by law in mathematics'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Coordinates describe position precisely, not aesthetics.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Try to locate a point on a page using only one number — you''ll find many different points share that number.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This isn''t an arbitrary rule — a plane is two-dimensional, so it genuinely needs two independent numbers.')
  ),
  'hints', jsonb_build_array('Think about how many points share the same x-value alone, without a y-value.'),
  'solutionSteps', jsonb_build_array('A plane has two independent directions (left-right and up-down).', 'One number alone can only narrow a point down to a whole line, not a single spot — a second number is needed to pin down exactly where on that line.')
), 'live', 1),

('q_m9_coord_001_02', 'cbse_9_maths', array['M9-COORD-001'], 1, 'assertion_reason', 1, jsonb_build_object(
  'stem', 'Read the Assertion (A) and Reason (R) and choose the correct option.',
  'assertion', 'A treasure map that says "10 steps from the tree" is not enough to find the treasure.',
  'reason', 'A single distance only narrows the location down to a circle of points around the tree, not one exact spot.',
  'options', jsonb_build_array(
    'Both A and R are true, and R is the correct explanation of A.',
    'Both A and R are true, but R is not the correct explanation of A.',
    'A is true, but R is false.',
    'A is false, but R is true.'
  ),
  'correctIndex', 0,
  'hints', jsonb_build_array('Picture every point that is exactly 10 steps from the tree — what shape do they form?'),
  'solutionSteps', jsonb_build_array('Every point 10 steps from the tree lies on a circle of radius 10 around it.', 'A direction (or a second measurement) is needed to pick one exact point on that circle — this is exactly why two coordinates are needed on a plane.')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-COORD-002: Identify the axes, origin, and quadrants
-- ---------------------------------------------------------------------------

('q_m9_coord_002_01', 'cbse_9_maths', array['M9-COORD-002'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'What are the coordinates of the origin?',
  'options', jsonb_build_array('(0, 0)', '(1, 1)', '(1, 0)', '(0, 1)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The origin is where both axes meet — that''s where both coordinates are zero, not one.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This point lies on the x-axis, one unit from the origin — not the origin itself.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This point lies on the y-axis, one unit from the origin — not the origin itself.')
  ),
  'hints', jsonb_build_array('The origin is where the x-axis and y-axis cross.'),
  'solutionSteps', jsonb_build_array('The x-axis and y-axis intersect at the point where both coordinates are 0.', 'So the origin is (0, 0).')
), 'live', 1),

('q_m9_coord_002_02', 'cbse_9_maths', array['M9-COORD-002'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'Which axis is usually drawn horizontally?',
  'options', jsonb_build_array('The x-axis', 'The y-axis', 'Both are drawn horizontally', 'Neither — they''re both diagonal'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'The y-axis is the vertical one, not the horizontal one.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'The two axes are perpendicular to each other — they can''t both be horizontal.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The axes are drawn perpendicular (at 90°) to each other, one horizontal and one vertical — not diagonal.')
  ),
  'hints', jsonb_build_array('x comes before y — and horizontal comes before vertical when reading left to right.'),
  'solutionSteps', jsonb_build_array('By convention, the x-axis is horizontal and the y-axis is vertical.')
), 'live', 1),

('q_m9_coord_002_03', 'cbse_9_maths', array['M9-COORD-002'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'In which quadrant do points have a negative x-coordinate and a positive y-coordinate?',
  'options', jsonb_build_array('Quadrant II', 'Quadrant I', 'Quadrant III', 'Quadrant IV'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Quadrant I has both coordinates positive, not one negative and one positive.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Quadrant III has both coordinates negative.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Quadrant IV has a positive x-coordinate and a negative y-coordinate — the opposite of what''s described here.')
  ),
  'hints', jsonb_build_array('Quadrants are numbered counter-clockwise starting from the top-right (both positive).'),
  'solutionSteps', jsonb_build_array('Quadrant I: (+, +). Quadrant II: (−, +). Quadrant III: (−, −). Quadrant IV: (+, −).', 'Negative x, positive y matches Quadrant II.')
), 'live', 1),

('q_m9_coord_002_04', 'cbse_9_maths', array['M9-COORD-002'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'A point lies on the x-axis (not at the origin). What can you say about its y-coordinate?',
  'options', jsonb_build_array('It is 0', 'It is 1', 'It could be any positive number', 'It could be any negative number'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'A point on the x-axis has y = 0 exactly — not just a small positive number.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Any point with a nonzero y-coordinate is off the x-axis, above it.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Any point with a nonzero y-coordinate is off the x-axis, below it.')
  ),
  'hints', jsonb_build_array('The x-axis is the set of all points where height above/below it is exactly zero.'),
  'solutionSteps', jsonb_build_array('Every point on the x-axis has y = 0, by definition of the axis.')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-COORD-003: Plot a point given its coordinates
-- ---------------------------------------------------------------------------

('q_m9_coord_003_01', 'cbse_9_maths', array['M9-COORD-003'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'To plot the point (3, 5), which order do you move in?',
  'options', jsonb_build_array(
    'Move 3 units along the x-axis, then 5 units parallel to the y-axis',
    'Move 5 units along the x-axis, then 3 units parallel to the y-axis',
    'Move 3 units up, then 5 units right',
    'It doesn''t matter which order you move in'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This reverses the coordinates — you''d end up plotting (5, 3) instead of (3, 5).'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This also reverses which number controls which direction.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The order does matter — (3, 5) and (5, 3) are different points.')
  ),
  'hints', jsonb_build_array('The first number in an ordered pair is always the x-coordinate.'),
  'solutionSteps', jsonb_build_array('In (x, y), the first number is the horizontal distance, the second is the vertical distance.', 'So for (3, 5): move 3 along x, then 5 parallel to y.')
), 'live', 1),

('q_m9_coord_003_02', 'cbse_9_maths', array['M9-COORD-003'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A student is asked to plot (2, 7) but instead plots (7, 2). What mistake did they make?',
  'options', jsonb_build_array(
    'They swapped the x-coordinate and y-coordinate',
    'They used the wrong colour pen',
    'They plotted a point in the wrong quadrant only',
    'There is no mistake — both points are the same'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Pen colour has nothing to do with plotting accuracy.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Both (2,7) and (7,2) are in Quadrant I — the mistake is about which axis each number belongs to, not the quadrant.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'These are two different points unless x = y — reversing the order changes where the point actually is.')
  ),
  'hints', jsonb_build_array('Compare where 2 and 7 each end up in both orderings.'),
  'solutionSteps', jsonb_build_array('(2,7) means 2 along x, 7 along y.', '(7,2) means 7 along x, 2 along y — the coordinates were swapped.')
), 'live', 1),

('q_m9_coord_003_03', 'cbse_9_maths', array['M9-COORD-003'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'What are the coordinates of a point that is 4 units to the left of the y-axis and 2 units above the x-axis?',
  'options', jsonb_build_array('(−4, 2)', '(4, 2)', '(−4, −2)', '(2, −4)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '"To the left" means the x-coordinate should be negative, not positive.'),
    jsonb_build_object('optionIndex', 2, 'explanation', '"Above the x-axis" means the y-coordinate should be positive, not negative.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This swaps which number represents left-right versus up-down.')
  ),
  'hints', jsonb_build_array('Left of the y-axis means a negative x. Above the x-axis means a positive y.'),
  'solutionSteps', jsonb_build_array('Left of y-axis by 4 -> x = −4.', 'Above x-axis by 2 -> y = 2.', 'Point is (−4, 2).')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-COORD-004: Read the coordinates of a plotted point
-- ---------------------------------------------------------------------------

('q_m9_coord_004_01', 'cbse_9_maths', array['M9-COORD-004'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'A point is plotted 6 units to the right of the y-axis and 3 units below the x-axis. What are its coordinates?',
  'options', jsonb_build_array('(6, −3)', '(−6, 3)', '(6, 3)', '(3, 6)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This has the signs reversed on both coordinates.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Below the x-axis means the y-coordinate is negative, not positive.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This swaps the x and y values.')
  ),
  'hints', jsonb_build_array('Right of the y-axis is positive x. Below the x-axis is negative y.'),
  'solutionSteps', jsonb_build_array('Right by 6 -> x = 6.', 'Below by 3 -> y = −3.', 'Point is (6, −3).')
), 'live', 1),

('q_m9_coord_004_02', 'cbse_9_maths', array['M9-COORD-004'], 2, 'numeric', 1, jsonb_build_object(
  'stem', 'A point lies exactly halfway between (0,0) and (8,0) on the x-axis. What is its x-coordinate?',
  'numericAnswer', '4', 'unit', 'none',
  'hints', jsonb_build_array('Halfway means the midpoint of the two x-values.'),
  'solutionSteps', jsonb_build_array('Midpoint x = (0 + 8) / 2 = 4.', 'Since the point is on the x-axis, y = 0, but only the x-coordinate is asked for here.')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-COORD-005: Identify the quadrant/axis a point lies on
-- ---------------------------------------------------------------------------

('q_m9_coord_005_01', 'cbse_9_maths', array['M9-COORD-005'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'The point (0, −5) lies on which axis?',
  'options', jsonb_build_array('The y-axis', 'The x-axis', 'It lies in Quadrant III', 'It lies in Quadrant IV'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'A point with x = 0 lies on the y-axis, not the x-axis — check which coordinate is zero.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'A point with x = 0 doesn''t belong to any quadrant — it lies on an axis, between two quadrants.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Same as above — being on an axis means it isn''t in any quadrant at all.')
  ),
  'hints', jsonb_build_array('A point belongs to an axis, not a quadrant, if one of its coordinates is zero.'),
  'solutionSteps', jsonb_build_array('x = 0 here, so the point lies on the y-axis (below the origin, since y is negative).')
), 'live', 1),

('q_m9_coord_005_02', 'cbse_9_maths', array['M9-COORD-005'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'The point (−2, 0) lies:',
  'options', jsonb_build_array(
    'On the x-axis, and not in any quadrant',
    'In Quadrant II',
    'In Quadrant III',
    'On the y-axis'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Quadrant II needs BOTH coordinates to follow the (−,+) pattern — here y = 0, so it''s on an axis, not in a quadrant.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Quadrant III needs both coordinates negative — here y = 0.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'A point on the y-axis has x = 0 — here it''s y that is 0, so this point is on the x-axis instead.')
  ),
  'hints', jsonb_build_array('Since y = 0 here, this point sits exactly on one of the axes.'),
  'solutionSteps', jsonb_build_array('y = 0, so the point lies on the x-axis (to the left of the origin, since x is negative) — not inside any quadrant.')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-COORD-006: Apply the distance formula between two points
-- ---------------------------------------------------------------------------

('q_m9_coord_006_01', 'cbse_9_maths', array['M9-COORD-006'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'What is the distance between the points (2, 3) and (5, 7)?',
  'options', jsonb_build_array('5', '7', '√58', '9'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This adds the differences (3+4) instead of using the distance formula — that only works for movement along one straight axis-aligned line.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This is what you''d get if you forgot to take the square root at the end.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This adds the coordinate differences directly (3+6) rather than squaring, summing, and taking a square root.')
  ),
  'hints', jsonb_build_array('Use the distance formula: √((x₂−x₁)² + (y₂−y₁)²).', 'x₂−x₁ = 3, y₂−y₁ = 4. What is √(3² + 4²)?'),
  'solutionSteps', jsonb_build_array('√((5−2)² + (7−3)²)', '√(9 + 16)', '√25 = 5')
), 'live', 1),

('q_m9_coord_006_02', 'cbse_9_maths', array['M9-COORD-006'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'Find the distance between the points (−1, 1) and (3, −2).',
  'numericAnswer', '5', 'unit', 'none',
  'hints', jsonb_build_array('Compute x₂−x₁ and y₂−y₁ first, being careful with the signs.'),
  'solutionSteps', jsonb_build_array('x₂−x₁ = 3−(−1) = 4', 'y₂−y₁ = −2−1 = −3', '√(4² + (−3)²) = √(16+9) = √25 = 5')
), 'live', 1),

('q_m9_coord_006_03', 'cbse_9_maths', array['M9-COORD-006'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'Find the distance of the point (6, 8) from the origin.',
  'numericAnswer', '10', 'unit', 'none',
  'hints', jsonb_build_array('The origin is (0,0) — use the distance formula with that as one of the two points.'),
  'solutionSteps', jsonb_build_array('√((6−0)² + (8−0)²)', '√(36+64) = √100 = 10')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-COORD-007: Word problems using distance between points
-- ---------------------------------------------------------------------------

('q_m9_coord_007_01', 'cbse_9_maths', array['M9-COORD-007'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'A triangle has vertices A(0,0), B(4,0), and C(0,3). What type of triangle is it, based on its side lengths?',
  'options', jsonb_build_array('Right-angled (a 3-4-5 triangle)', 'Equilateral', 'Obtuse', 'It is not a valid triangle'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Compute all three side lengths first — they are not all equal, so it can''t be equilateral.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Check the side lengths against the Pythagorean relationship before assuming obtuse.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Three non-collinear points always form a valid triangle — these three don''t lie on one line.')
  ),
  'hints', jsonb_build_array('Compute AB, BC, and AC using the distance formula.', 'Check if the three lengths satisfy a² + b² = c² for some ordering.'),
  'solutionSteps', jsonb_build_array('AB = √((4-0)²+(0-0)²) = 4', 'AC = √((0-0)²+(3-0)²) = 3', 'BC = √((4-0)²+(0-3)²) = √(16+9) = 5', '3² + 4² = 9+16 = 25 = 5² — this is a right triangle.')
), 'live', 1),

('q_m9_coord_007_02', 'cbse_9_maths', array['M9-COORD-007'], 3, 'mcq', 2, jsonb_build_object(
  'stem', 'Points P(1,2), Q(4,2), R(4,6) are given. Which two points are the same distance apart as P and Q?',
  'options', jsonb_build_array(
    'No other pair — PQ = 3 is not repeated among QR or PR',
    'Q and R, since QR also equals 3',
    'P and R, since PR also equals 3',
    'All three pairs are equal in distance'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Compute QR using the distance formula rather than assuming — it comes out to 4, not 3.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Compute PR using the distance formula — it comes out to 5, not 3.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'These three points form a 3-4-5 right triangle, with three different side lengths.')
  ),
  'hints', jsonb_build_array('Compute PQ, QR, and PR separately using the distance formula, then compare.'),
  'solutionSteps', jsonb_build_array('PQ = √((4-1)²+(2-2)²) = 3', 'QR = √((4-4)²+(6-2)²) = 4', 'PR = √((4-1)²+(6-2)²) = √(9+16) = 5', 'All three distances are different: 3, 4, 5.')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-POLY-001: Identify a linear polynomial in one variable
-- ---------------------------------------------------------------------------

('q_m9_poly_001_01', 'cbse_9_maths', array['M9-POLY-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'Which of these is a linear polynomial in one variable?',
  'options', jsonb_build_array('3x + 5', '3x + 5 = 11', 'x² + 2x + 1', '3x + 2y'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This has an "=" sign — it''s an equation, not a polynomial. An equation states two things are equal; a polynomial is just an expression.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This has an x² term — that makes it quadratic (degree 2), not linear (degree 1).'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This has two variables (x and y), not one.')
  ),
  'hints', jsonb_build_array('A polynomial has no "=" sign — it''s just an expression, not a statement that two things are equal.', 'A linear polynomial has the highest power of the variable equal to 1.'),
  'solutionSteps', jsonb_build_array('3x + 5 has one variable (x), degree 1, and no equals sign — it fits every requirement for a linear polynomial in one variable.')
), 'live', 1),

('q_m9_poly_001_02', 'cbse_9_maths', array['M9-POLY-001'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'Is "2x − 7" an equation or an expression?',
  'options', jsonb_build_array(
    'An expression — it has no "=" sign, so it can only be evaluated or simplified, not "solved"',
    'An equation — it can be solved for x',
    'Both, depending on context',
    'Neither — it is just a number'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'There is no "=" sign here — nothing is being set equal to anything, so there is nothing to "solve for."'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'It has to be one or the other based on whether an "=" sign is present — it can''t be ambiguous.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'It contains a variable (x), so it isn''t just a single number.')
  ),
  'hints', jsonb_build_array('Look for whether there is an "=" sign anywhere.'),
  'solutionSteps', jsonb_build_array('"2x − 7" has no "=" sign, so it is an expression — it can be evaluated at a value of x, or simplified, but it can''t be "solved."')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-POLY-002: Identify coefficient, variable, constant term
-- ---------------------------------------------------------------------------

('q_m9_poly_002_01', 'cbse_9_maths', array['M9-POLY-002'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'In the linear polynomial 7x − 4, what is the constant term?',
  'options', jsonb_build_array('−4', '7', '4', 'x'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '7 is the coefficient of x, not the constant term.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Don''t drop the negative sign — the constant term is −4, not 4.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'x is the variable, not the constant term.')
  ),
  'hints', jsonb_build_array('The constant term is the part with no variable attached, including its sign.'),
  'solutionSteps', jsonb_build_array('7x − 4 = 7x + (−4)', 'The constant term (no variable attached) is −4.')
), 'live', 1),

('q_m9_poly_002_02', 'cbse_9_maths', array['M9-POLY-002'], 1, 'mcq', 1, jsonb_build_object(
  'stem', 'In the linear polynomial −3x + 9, what is the coefficient of x?',
  'options', jsonb_build_array('−3', '9', '3', '−9'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', '9 is the constant term, not the coefficient of x.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Don''t drop the negative sign — the coefficient is −3, not 3.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This mixes up the sign of the coefficient with the constant term.')
  ),
  'hints', jsonb_build_array('The coefficient of x is the number directly multiplying x, sign included.'),
  'solutionSteps', jsonb_build_array('In −3x + 9, the number multiplying x is −3.')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-POLY-003: Evaluate a linear polynomial at a given value
-- ---------------------------------------------------------------------------

('q_m9_poly_003_01', 'cbse_9_maths', array['M9-POLY-003'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'If p(x) = 4x − 5, find p(3).',
  'numericAnswer', '7', 'unit', 'none',
  'hints', jsonb_build_array('Substitute x = 3 into the expression.'),
  'solutionSteps', jsonb_build_array('p(3) = 4(3) − 5 = 12 − 5 = 7')
), 'live', 1),

('q_m9_poly_003_02', 'cbse_9_maths', array['M9-POLY-003'], 2, 'numeric', 1, jsonb_build_object(
  'stem', 'If p(x) = −2x + 6, find p(−4).',
  'numericAnswer', '14', 'unit', 'none',
  'hints', jsonb_build_array('Watch the signs carefully — you are multiplying two negative numbers.'),
  'solutionSteps', jsonb_build_array('p(−4) = −2(−4) + 6 = 8 + 6 = 14')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-POLY-004: Recognize and continue a linear numeric pattern
-- ---------------------------------------------------------------------------

('q_m9_poly_004_01', 'cbse_9_maths', array['M9-POLY-004'], 1, 'numeric', 1, jsonb_build_object(
  'stem', 'What is the next number in the pattern: 5, 9, 13, 17, ...?',
  'numericAnswer', '21', 'unit', 'none',
  'hints', jsonb_build_array('Find the constant difference between consecutive terms first.'),
  'solutionSteps', jsonb_build_array('Each term increases by 4 (9−5=4, 13−9=4, 17−13=4).', '17 + 4 = 21')
), 'live', 1),

('q_m9_poly_004_02', 'cbse_9_maths', array['M9-POLY-004'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Which of these patterns is NOT linear (does not have a constant difference between terms)?',
  'options', jsonb_build_array('2, 4, 8, 16, ...', '3, 7, 11, 15, ...', '10, 8, 6, 4, ...', '1, 1.5, 2, 2.5, ...'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This one does have a constant difference of 4 — check by subtracting consecutive terms.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This one has a constant difference of −2 — decreasing linear patterns are still linear.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This one has a constant difference of 0.5.')
  ),
  'hints', jsonb_build_array('Check the difference between each pair of consecutive terms — is it always the same number?'),
  'solutionSteps', jsonb_build_array('2,4,8,16: differences are 2,4,8 — not constant, so this pattern is NOT linear (it doubles each time instead).', 'The other three all have a constant difference, so they are linear.')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-POLY-005: Write the explicit rule for a linear pattern
-- ---------------------------------------------------------------------------

('q_m9_poly_005_01', 'cbse_9_maths', array['M9-POLY-005'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A pattern starts at 3 and increases by 5 each time: 3, 8, 13, 18, ... Which rule gives the nth term (starting at n=1)?',
  'options', jsonb_build_array('5n − 2', '5n + 3', '5n − 5', '3n + 5'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Check n=1: 5(1)+3 = 8, but the first term is 3, not 8 — this rule is off by one position.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Check n=1: 5(1)−5 = 0, but the first term is 3.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This mixes up the starting value and the common difference — the rate of change here is 5, not 3.')
  ),
  'hints', jsonb_build_array('Test your rule against n=1 (should give 3) and n=2 (should give 8) before trusting it.'),
  'solutionSteps', jsonb_build_array('The pattern increases by 5 each step, so the rule has the form 5n + c for some constant c.', 'At n=1, the value is 3: 5(1) + c = 3, so c = −2.', 'Rule: 5n − 2. Check n=2: 5(2)−2 = 8. Correct.')
), 'live', 1),

('q_m9_poly_005_02', 'cbse_9_maths', array['M9-POLY-005'], 2, 'numeric', 2, jsonb_build_object(
  'stem', 'A pattern''s nth term is given by 4n + 1. What is the 10th term?',
  'numericAnswer', '41', 'unit', 'none',
  'hints', jsonb_build_array('Substitute n = 10 into the rule.'),
  'solutionSteps', jsonb_build_array('4(10) + 1 = 40 + 1 = 41')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-POLY-006: Distinguish linear growth from linear decay
-- ---------------------------------------------------------------------------

('q_m9_poly_006_01', 'cbse_9_maths', array['M9-POLY-006'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'A water tank starts with 200 litres and loses 15 litres every hour. Is this linear growth or linear decay?',
  'options', jsonb_build_array(
    'Linear decay — the amount decreases by a constant rate each hour',
    'Linear growth — the amount changes by a constant rate each hour',
    'Neither — 200 is a positive starting value, so it must be growth',
    'It depends on how many hours have passed'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'It''s true the rate is constant, but the amount is decreasing, not increasing — that makes it decay, not growth.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'Whether the starting value is positive doesn''t determine growth vs decay — the sign of the RATE of change does.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'The rate of change here is constant throughout, so it doesn''t suddenly switch between growth and decay.')
  ),
  'hints', jsonb_build_array('Growth vs. decay depends on whether the rate of change is positive or negative, not on the starting value.'),
  'solutionSteps', jsonb_build_array('The tank loses 15 litres/hour — a constant negative rate of change.', 'A constant negative rate means linear decay.')
), 'live', 1),

('q_m9_poly_006_02', 'cbse_9_maths', array['M9-POLY-006'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Which of these represents linear decay?',
  'options', jsonb_build_array('50, 44, 38, 32, ...', '50, 44, 50, 44, ...', '50, 56, 62, 68, ...', '50, 50, 50, 50, ...'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This alternates rather than steadily decreasing — it has no single constant rate of change.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This is increasing by a constant amount each time — that''s growth, not decay.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This stays constant — the rate of change is 0, which is neither growth nor decay.')
  ),
  'hints', jsonb_build_array('Decay means the value steadily decreases by the same amount each step.'),
  'solutionSteps', jsonb_build_array('50,44,38,32: each term decreases by 6 — a constant negative rate, so this is linear decay.')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-POLY-007: Interpret a polynomial as a two-quantity relationship
-- ---------------------------------------------------------------------------

('q_m9_poly_007_01', 'cbse_9_maths', array['M9-POLY-007'], 2, 'mcq', 2, jsonb_build_object(
  'stem', 'A taxi charges ₹50 as a base fare plus ₹12 per km. If the fare is F and the distance is d km, which expression gives F?',
  'options', jsonb_build_array('F = 12d + 50', 'F = 50d + 12', 'F = 12d − 50', 'F = 62d'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This swaps which number is the per-km rate and which is the fixed base fare.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'A base fare should be added, not subtracted — the fare can''t be less than ₹50 minus something.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'This adds the two numbers together and treats the whole ₹62 as a per-km rate, losing the fixed base fare entirely.')
  ),
  'hints', jsonb_build_array('The base fare is a fixed amount added once; the per-km charge depends on distance.'),
  'solutionSteps', jsonb_build_array('Fixed base fare = ₹50 (the constant term).', 'Per-km rate = ₹12 (the coefficient of d).', 'F = 12d + 50')
), 'live', 1),

('q_m9_poly_007_02', 'cbse_9_maths', array['M9-POLY-007'], 3, 'numeric', 2, jsonb_build_object(
  'stem', 'Using F = 12d + 50 (taxi fare for d km), find the distance travelled if the fare was ₹146.',
  'numericAnswer', '8', 'unit', 'km',
  'hints', jsonb_build_array('Set F = 146 and solve for d.'),
  'solutionSteps', jsonb_build_array('146 = 12d + 50', '96 = 12d', 'd = 8')
), 'live', 1),

-- ---------------------------------------------------------------------------
-- M9-POLY-008: Visualise (graph) a linear relationship
-- ---------------------------------------------------------------------------

('q_m9_poly_008_01', 'cbse_9_maths', array['M9-POLY-008', 'M9-COORD-003'], 2, 'mcq', 2, jsonb_build_object(
  'stem', 'For the relationship y = 2x + 1, which point lies on its graph?',
  'options', jsonb_build_array('(3, 7)', '(3, 6)', '(3, 5)', '(1, 1)'),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'Check by substituting x=3 into the rule: y = 2(3)+1 = 7, not 6.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'This forgets to add the "+1" after doubling x.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Substituting x=1 gives y = 2(1)+1 = 3, not 1 — this point does not satisfy the rule.')
  ),
  'hints', jsonb_build_array('For a point to lie on the graph, its y-value must equal 2x+1 for its own x-value.'),
  'solutionSteps', jsonb_build_array('At x=3: y = 2(3)+1 = 7.', 'So (3, 7) lies on the graph of y = 2x+1.')
), 'live', 1),

('q_m9_poly_008_02', 'cbse_9_maths', array['M9-POLY-008'], 2, 'mcq', 1, jsonb_build_object(
  'stem', 'Why is it a good idea to plot at least 2-3 points before drawing the graph of a linear relationship, rather than just 1?',
  'options', jsonb_build_array(
    'A single point doesn''t tell you the line''s direction or slope — you need at least two to draw the right line',
    'More points always look nicer on a graph',
    'A single point is mathematically impossible to plot',
    'Only the very first point actually matters'
  ),
  'correctIndex', 0,
  'distractors', jsonb_build_array(
    jsonb_build_object('optionIndex', 1, 'explanation', 'This isn''t about appearance — it''s about having enough information to know exactly which line to draw.'),
    jsonb_build_object('optionIndex', 2, 'explanation', 'A single point can absolutely be plotted — the issue is that infinitely many different lines could pass through just one point.'),
    jsonb_build_object('optionIndex', 3, 'explanation', 'Every point you compute is equally valid data for drawing the line accurately — none of them is more "important" than another.')
  ),
  'hints', jsonb_build_array('Think about how many different straight lines could pass through just a single point.'),
  'solutionSteps', jsonb_build_array('Infinitely many lines pass through any single point.', 'A second point pins down the exact line; a third is useful as a check that both points and the rule agree.')
), 'live', 1);

commit;

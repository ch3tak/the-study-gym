-- Complete the 8-chapter Class 9 Maths target from the curriculum blueprint
-- (docs/curriculum/class9_maths.md, Part 5 and Part 20's index): adds the
-- missing chapter (Number System) and every missing concept row for the 6
-- chapters that were partially migrated in
-- 20260927000000_m9_maths_id_convention_and_new_chapters.sql, bringing all 8
-- confirmed chapters to their full blueprint skill counts (NUM=9, SEQ=9,
-- IDENT=7, MENS=8 [+008a split], CIRC=8 [+ pre-existing CIRC-009, a known
-- numbering gap left as-is -- see that migration's own notes], PROB=6).
--
-- Also re-sequences all 8 chapters' sort_order to match the blueprint's
-- Part 4 recommended learning sequence exactly, now that Number System
-- exists (the prior migration's partial resequencing was necessarily
-- incomplete, since NUM didn't have a row yet).

begin;

-- ---------------------------------------------------------------------------
-- New chapter: Number System (Ch.3 in Ganita Manjari, "The World of Numbers")
-- ---------------------------------------------------------------------------

insert into chapters (id, subject_id, name, board_weight, sort_order) values
  ('num', 'cbse_9_maths', 'The World of Numbers', 7, 0); -- sort_order fixed below

-- ---------------------------------------------------------------------------
-- Re-sequence all 8 Maths chapters to match the blueprint's Part 4 order:
-- Coordinate Geometry -> Number System -> Linear Polynomials ->
-- Algebraic Identities -> Sequences -> Circles -> Area/Perimeter -> Probability
-- ---------------------------------------------------------------------------

update chapters set sort_order = 1 where id = 'coord';
update chapters set sort_order = 2 where id = 'num';
update chapters set sort_order = 3 where id = 'poly';
update chapters set sort_order = 4 where id = 'algebraic_identities';
update chapters set sort_order = 5 where id = 'sequences_progressions';
update chapters set sort_order = 6 where id = 'circles';
update chapters set sort_order = 7 where id = 'area_perimeter';
update chapters set sort_order = 8 where id = 'probability';

-- ---------------------------------------------------------------------------
-- Missing concepts: Number System (all 9 -- new chapter, no prior rows)
-- ---------------------------------------------------------------------------

insert into concepts (id, chapter_id, name, sort_order) values
  ('M9-NUM-001', 'num', 'Recall integer arithmetic', 1),
  ('M9-NUM-002', 'num', 'Understand zero as a mathematical concept', 2),
  ('M9-NUM-003', 'num', 'Represent rational numbers on the number line', 3),
  ('M9-NUM-004', 'num', 'Understand the density of rational numbers', 4),
  ('M9-NUM-005', 'num', 'Prove that a number like the square root of 2 is irrational', 5),
  ('M9-NUM-006', 'num', 'Construct a length equal to the square root of n on the number line', 6),
  ('M9-NUM-007', 'num', 'Classify a decimal as terminating, repeating, or neither', 7),
  ('M9-NUM-008', 'num', 'Convert a repeating decimal to a fraction', 8),
  ('M9-NUM-009', 'num', 'Classify a number within the real number system', 9);

-- ---------------------------------------------------------------------------
-- Missing concepts: Sequences and Progressions (5 of 9 -- 005,006,008,009
-- already exist from the prior migration's rename)
-- ---------------------------------------------------------------------------

insert into concepts (id, chapter_id, name, sort_order) values
  ('M9-SEQ-001', 'sequences_progressions', 'Identify a sequence and its terms', 1),
  ('M9-SEQ-002', 'sequences_progressions', 'Write an explicit rule for a sequence', 2),
  ('M9-SEQ-003', 'sequences_progressions', 'Write a recursive rule for a sequence', 3),
  ('M9-SEQ-004', 'sequences_progressions', 'Identify an arithmetic progression and its common difference', 4),
  ('M9-SEQ-007', 'sequences_progressions', 'Identify a geometric progression and its common ratio', 7);

-- ---------------------------------------------------------------------------
-- Missing concepts: Exploring Algebraic Identities (4 of 7 -- 002,003,005
-- already exist)
-- ---------------------------------------------------------------------------

insert into concepts (id, chapter_id, name, sort_order) values
  ('M9-IDENT-001', 'algebraic_identities', 'Visualise (a+b) squared geometrically', 1),
  ('M9-IDENT-004', 'algebraic_identities', 'Use algebra tiles to factorise a quadratic-form expression', 4),
  ('M9-IDENT-006', 'algebraic_identities', 'Derive and apply extended identities', 6),
  ('M9-IDENT-007', 'algebraic_identities', 'Simplify a rational algebraic expression using identities', 7);

-- ---------------------------------------------------------------------------
-- Missing concepts: Area and Perimeter (6 of 8 [+008a split] -- 006,008,008a
-- already exist)
-- ---------------------------------------------------------------------------

insert into concepts (id, chapter_id, name, sort_order) values
  ('M9-MENS-001', 'area_perimeter', 'Compute perimeter of standard polygons', 1),
  ('M9-MENS-002', 'area_perimeter', 'Understand the circumference-to-diameter ratio (pi) empirically', 2),
  ('M9-MENS-003', 'area_perimeter', 'Understand why pi is irrational', 3),
  ('M9-MENS-004', 'area_perimeter', 'Compute arc length', 4),
  ('M9-MENS-005', 'area_perimeter', 'Compute area of a rectangle, parallelogram, and triangle', 5),
  ('M9-MENS-007', 'area_perimeter', 'Understand "squaring a rectangle" (constructing a square of equal area)', 7);

-- ---------------------------------------------------------------------------
-- Missing concepts: Circles (7 of 8 -- 007 already exists as M9-CIRC-007;
-- the pre-existing M9-CIRC-009 is a known numbering gap from the prior
-- migration, left untouched per the user's decision -- see that migration's
-- header comment)
-- ---------------------------------------------------------------------------

insert into concepts (id, chapter_id, name, sort_order) values
  ('M9-CIRC-001', 'circles', 'Define circle, radius, diameter, chord, arc, sector, segment', 1),
  ('M9-CIRC-002', 'circles', 'Identify symmetries of a circle', 2),
  ('M9-CIRC-003', 'circles', 'Determine how many circles pass through 1, 2, or 3 given points', 3),
  ('M9-CIRC-004', 'circles', 'Relate a chord''s length to the angle it subtends at the centre', 4),
  ('M9-CIRC-005', 'circles', 'Apply the perpendicular-bisector-of-a-chord property', 5),
  ('M9-CIRC-006', 'circles', 'Compare distances of unequal chords from the centre', 6),
  ('M9-CIRC-008', 'circles', 'Determine concyclicity of points', 8);

-- ---------------------------------------------------------------------------
-- Missing concepts: Introduction to Probability (4 of 6 -- 003,006 already
-- exist)
-- ---------------------------------------------------------------------------

insert into concepts (id, chapter_id, name, sort_order) values
  ('M9-PROB-001', 'probability', 'Understand randomness and the probability scale', 1),
  ('M9-PROB-002', 'probability', 'Compute experimental (empirical) probability from data', 2),
  ('M9-PROB-004', 'probability', 'Identify the sample space for an experiment', 4),
  ('M9-PROB-005', 'probability', 'Identify events (simple/compound) within a sample space', 5);

commit;

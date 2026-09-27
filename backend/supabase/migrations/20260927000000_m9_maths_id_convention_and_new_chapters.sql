-- Migrate Class 9 Maths concept IDs to the M9-{CHAPTER-CODE}-{NNN} convention
-- (decided 26 Sep 2026 while building the Class 9 Maths curriculum blueprint,
-- see docs/curriculum/class9_maths.md and docs/PLAN.md §4.1), and add the two
-- MVP chapters the blueprint recommends building first: Coordinate Geometry
-- and Introduction to Linear Polynomials.
--
-- Science's concept IDs are intentionally NOT touched here — Science hasn't
-- had the same curriculum research pass yet, so its dotted-style IDs
-- (c9.motion.speed_velocity etc.) stay as-is for now. Science is flipped to
-- 'coming_soon' status instead (see bottom of this file) so the app stops
-- presenting it as live content until it gets the same rigor.
--
-- `concept_mastery.concept_id` has a foreign key to concepts(id) with no
-- `on update cascade`, and it was NOT declared deferrable in the original
-- schema -- so if ANY concept_mastery row already references one of these
-- old ids (e.g. from earlier manual testing against this project), a plain
-- `update concepts set id = ...` on the parent fails outright while a child
-- still points at the old value, and `set constraints all deferred` alone
-- would silently do nothing for a non-deferrable constraint (Postgres skips
-- it rather than erroring). So this migration first makes the constraint
-- deferrable (a one-time schema change, harmless to run again if this
-- migration is ever re-applied), then defers it for this transaction.

begin;

alter table concept_mastery
  drop constraint concept_mastery_concept_id_fkey,
  add constraint concept_mastery_concept_id_fkey
    foreign key (concept_id) references concepts(id)
    deferrable initially deferred;

set constraints concept_mastery_concept_id_fkey deferred;

-- ---------------------------------------------------------------------------
-- Rename existing Maths concept ids (old dotted style -> M9-{CODE}-{NNN}).
-- Update concept_mastery's references FIRST, then the concepts table itself
-- -- with the FK check deferred to commit time, the order between these two
-- doesn't matter, but this order keeps the intent readable either way.
-- ---------------------------------------------------------------------------

update concept_mastery set concept_id = 'M9-SEQ-005' where concept_id = 'c9.seq.ap_nth_term';
update concept_mastery set concept_id = 'M9-SEQ-006' where concept_id = 'c9.seq.sum_natural';
update concept_mastery set concept_id = 'M9-SEQ-008' where concept_id = 'c9.seq.gp_nth_term';
update concept_mastery set concept_id = 'M9-SEQ-009' where concept_id = 'c9.seq.tower_of_hanoi';
update concept_mastery set concept_id = 'M9-IDENT-002' where concept_id = 'c9.iden.standard';
update concept_mastery set concept_id = 'M9-IDENT-003' where concept_id = 'c9.iden.factorise_identities';
update concept_mastery set concept_id = 'M9-IDENT-005' where concept_id = 'c9.iden.factorise_quadratic';
update concept_mastery set concept_id = 'M9-MENS-006' where concept_id = 'c9.area.herons_formula';
update concept_mastery set concept_id = 'M9-MENS-008' where concept_id = 'c9.area.circle_area';
update concept_mastery set concept_id = 'M9-MENS-008a' where concept_id = 'c9.area.sector_segment';
update concept_mastery set concept_id = 'M9-CIRC-007' where concept_id = 'c9.circ.same_segment';
update concept_mastery set concept_id = 'M9-CIRC-009' where concept_id = 'c9.circ.cyclic_quadrilateral';
update concept_mastery set concept_id = 'M9-PROB-003' where concept_id = 'c9.prob.theoretical';
update concept_mastery set concept_id = 'M9-PROB-006' where concept_id = 'c9.prob.tree_tables';

update concepts set id = 'M9-SEQ-005' where id = 'c9.seq.ap_nth_term';
update concepts set id = 'M9-SEQ-006' where id = 'c9.seq.sum_natural';
update concepts set id = 'M9-SEQ-008' where id = 'c9.seq.gp_nth_term';
update concepts set id = 'M9-SEQ-009' where id = 'c9.seq.tower_of_hanoi';

update concepts set id = 'M9-IDENT-002' where id = 'c9.iden.standard';
update concepts set id = 'M9-IDENT-003' where id = 'c9.iden.factorise_identities';
update concepts set id = 'M9-IDENT-005' where id = 'c9.iden.factorise_quadratic';

update concepts set id = 'M9-MENS-006' where id = 'c9.area.herons_formula';
-- The blueprint's Part 5 has one combined skill (MENS-008: "compute area of a
-- circle and a sector"), but the app already tracks these as two separate
-- concepts with separate mastery -- a deliberate, disclosed split from the
-- blueprint (finer-grained mastery here is more useful, not less), not a
-- naming accident. See docs/curriculum/class9_maths.md Part 5, which now
-- notes this split too.
update concepts set id = 'M9-MENS-008' where id = 'c9.area.circle_area';
update concepts set id = 'M9-MENS-008a' where id = 'c9.area.sector_segment';

update concepts set id = 'M9-CIRC-007' where id = 'c9.circ.same_segment';
update concepts set id = 'M9-CIRC-009' where id = 'c9.circ.cyclic_quadrilateral';

update concepts set id = 'M9-PROB-003' where id = 'c9.prob.theoretical';
update concepts set id = 'M9-PROB-006' where id = 'c9.prob.tree_tables';

-- concept_ids on questions is a plain text[], not FK-linked -- update each
-- element in place using array_replace, once per renamed id.
update questions set concept_ids = array_replace(concept_ids, 'c9.seq.ap_nth_term', 'M9-SEQ-005') where 'c9.seq.ap_nth_term' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.seq.sum_natural', 'M9-SEQ-006') where 'c9.seq.sum_natural' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.seq.gp_nth_term', 'M9-SEQ-008') where 'c9.seq.gp_nth_term' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.seq.tower_of_hanoi', 'M9-SEQ-009') where 'c9.seq.tower_of_hanoi' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.iden.standard', 'M9-IDENT-002') where 'c9.iden.standard' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.iden.factorise_identities', 'M9-IDENT-003') where 'c9.iden.factorise_identities' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.iden.factorise_quadratic', 'M9-IDENT-005') where 'c9.iden.factorise_quadratic' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.area.herons_formula', 'M9-MENS-006') where 'c9.area.herons_formula' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.area.circle_area', 'M9-MENS-008') where 'c9.area.circle_area' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.area.sector_segment', 'M9-MENS-008a') where 'c9.area.sector_segment' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.circ.same_segment', 'M9-CIRC-007') where 'c9.circ.same_segment' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.circ.cyclic_quadrilateral', 'M9-CIRC-009') where 'c9.circ.cyclic_quadrilateral' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.prob.theoretical', 'M9-PROB-003') where 'c9.prob.theoretical' = any(concept_ids);
update questions set concept_ids = array_replace(concept_ids, 'c9.prob.tree_tables', 'M9-PROB-006') where 'c9.prob.tree_tables' = any(concept_ids);

-- NOTE: chapter ids are intentionally NOT renamed here. concepts.chapter_id
-- has a foreign key to chapters(id) with no `on update cascade`, so renaming
-- a chapter id while concepts still reference the old value would violate
-- that constraint. The existing chapter ids (sequences_progressions,
-- algebraic_identities, area_perimeter, circles, probability) stay as-is --
-- only concept ids follow the new M9-{CODE}-{NNN} convention (chapter ids
-- were never part of that convention or of the decision that prompted this
-- migration).

-- ---------------------------------------------------------------------------
-- New MVP chapters: Coordinate Geometry (Ch.1) and Introduction to Linear
-- Polynomials (Ch.2) -- both fully confirmed against the real NCERT "Ganita
-- Manjari" textbook. See docs/curriculum/class9_maths.md Part 5 and Part 19.
-- ---------------------------------------------------------------------------

insert into chapters (id, subject_id, name, board_weight, sort_order) values
  ('coord', 'cbse_9_maths', 'Coordinate Geometry',              4, 0),
  ('poly',  'cbse_9_maths', 'Introduction to Linear Polynomials', 20, 0);

-- sort_order 0 places these first, ahead of the 5 existing chapters, matching
-- the blueprint's Part 4 recommended learning sequence (Coordinate Geometry
-- first, Linear Polynomials third). Re-sequence all Maths chapters to match
-- Part 4's full order now that both new chapters exist.
update chapters set sort_order = 1 where id = 'coord';
update chapters set sort_order = 2 where id = 'poly';
update chapters set sort_order = 3 where id = 'sequences_progressions'; -- was 1
update chapters set sort_order = 4 where id = 'algebraic_identities';  -- was 2
update chapters set sort_order = 5 where id = 'circles';               -- was 4, moved up per Part 4
update chapters set sort_order = 6 where id = 'area_perimeter';        -- was 3
update chapters set sort_order = 7 where id = 'probability';           -- was 5

insert into concepts (id, chapter_id, name, sort_order) values
  ('M9-COORD-001', 'coord', 'Understand the need for a coordinate system', 1),
  ('M9-COORD-002', 'coord', 'Identify the axes, origin, and quadrants', 2),
  ('M9-COORD-003', 'coord', 'Plot a point given its coordinates', 3),
  ('M9-COORD-004', 'coord', 'Read the coordinates of a plotted point', 4),
  ('M9-COORD-005', 'coord', 'Identify the quadrant/axis a point lies on', 5),
  ('M9-COORD-006', 'coord', 'Apply the distance formula between two points', 6),
  ('M9-COORD-007', 'coord', 'Solve word problems using distance between points', 7),

  ('M9-POLY-001', 'poly', 'Identify a linear polynomial in one variable', 1),
  ('M9-POLY-002', 'poly', 'Identify coefficient, variable, and constant term', 2),
  ('M9-POLY-003', 'poly', 'Evaluate a linear polynomial at a given value', 3),
  ('M9-POLY-004', 'poly', 'Recognize and continue a linear numeric pattern', 4),
  ('M9-POLY-005', 'poly', 'Write the explicit rule for a linear pattern', 5),
  ('M9-POLY-006', 'poly', 'Distinguish linear growth from linear decay', 6),
  ('M9-POLY-007', 'poly', 'Interpret a linear polynomial as a relationship between two quantities', 7),
  ('M9-POLY-008', 'poly', 'Visualise (graph) a linear relationship on the coordinate plane', 8);

-- ---------------------------------------------------------------------------
-- Science: mark as coming_soon. Science content hasn't had the same
-- curriculum research pass as Maths (see docs/curriculum/class9_maths.md);
-- its current seed content is the original placeholder/mock set. Flipping
-- this status stops the app from presenting Science as live content until
-- it gets equivalent rigor. The Flutter ContentRepository is updated
-- alongside this migration to actually filter on this field.
-- ---------------------------------------------------------------------------

update subjects set status = 'coming_soon' where id = 'cbse_9_science';

commit;

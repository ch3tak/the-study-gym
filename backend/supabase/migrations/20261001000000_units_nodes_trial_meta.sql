-- Slice 1 (docs/superpowers/specs/2026-09-28-app-structure-and-screens-design.md):
--   * units: the syllabus's units ("Geometry · 25 marks"), so Learn can group
--     chapters. Rows come from seed 007, generated from the syllabus YAML.
--   * chapters.unit_id: which unit a chapter belongs to.
--   * node_progress: which topic question nodes (Guided, Practice, Spot the
--     mistake, Challenge) a student has passed.
--   * level_progress.solution_viewed: whether a solution was opened on a
--     Trial level, for the Platinum trophy.
-- All additive: no existing row changes meaning.

begin;

create table units (
  id         text primary key,      -- 'cbse_9_maths.geometry'
  subject_id text not null references subjects(id),
  name       text not null,
  marks      numeric(5,2),          -- null for a course with no exam
  sort_order smallint not null
);

alter table chapters add column unit_id text references units(id);

create table node_progress (
  user_id      uuid not null references profiles(id) on delete cascade,
  concept_id   text not null references concepts(id),
  node         text not null check (node in ('guided', 'practice', 'spot_the_mistake', 'challenge')),
  completed_at timestamptz not null default now(),
  primary key (user_id, concept_id, node)
);

alter table level_progress add column solution_viewed boolean not null default false;

alter table units enable row level security;
alter table node_progress enable row level security;

create policy read_units on units for select using (true);
create policy own_node_progress on node_progress
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

commit;

-- Adds mission-level sequencing to `questions` and a per-student completion
-- table. Both `level`/`stage` are nullable — only mission-sequenced content
-- (currently just Surface Areas & Volumes) sets them; every other existing
-- question row is unaffected.

begin;

alter table questions
  add column level smallint,
  add column stage text;

create index questions_level_idx on questions(subject_id, level) where level is not null;

create table level_progress (
  user_id      uuid not null references profiles(id) on delete cascade,
  chapter_id   text not null references chapters(id),
  level        smallint not null,
  completed_at timestamptz not null default now(),
  score        numeric(4,2),
  primary key (user_id, chapter_id, level)
);

alter table level_progress enable row level security;
create policy own_level_progress on level_progress
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

commit;

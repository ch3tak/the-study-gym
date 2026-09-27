-- Theory content: a short lesson per concept, plus per-student read state.
-- Mirrors the questions/level_progress pattern in 20260926000000_core_schema.sql
-- and 20260929000000_mission_levels.sql — a content table (readable by any
-- signed-in user, like questions) and a progress table (own-rows-only).

begin;

create table lessons (
  id         text primary key,
  concept_id text not null references concepts(id),
  title      text not null,
  body       text not null,
  hook_kind  text not null check (hook_kind in ('historical', 'real_world')),
  hook       text not null,
  try_it     text,
  sort_order smallint not null default 0
);
create index lessons_concept_idx on lessons(concept_id);

create table theory_progress (
  user_id   uuid not null references profiles(id) on delete cascade,
  lesson_id text not null references lessons(id),
  read_at   timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

alter table lessons enable row level security;
alter table theory_progress enable row level security;

create policy read_lessons on lessons for select to authenticated using (true);
create policy own_theory_progress on theory_progress
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

commit;

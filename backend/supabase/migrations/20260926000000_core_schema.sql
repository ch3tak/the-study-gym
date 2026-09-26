-- Core schema: multi-subject curriculum, content, per-student learning state.
-- Nothing here assumes a particular subject; see docs/PLAN.md §6.

-- ---------------------------------------------------------------------------
-- Curriculum (read-only to clients)
-- ---------------------------------------------------------------------------

create table boards (
  id   text primary key,               -- 'cbse', 'icse', ...
  name text not null
);

create table classes (
  id            text primary key,      -- 'cbse_10'
  board_id      text not null references boards(id),
  grade         smallint not null,
  academic_year text not null,         -- '2026-27'
  unique (board_id, grade, academic_year)
);

create type subject_status as enum ('live', 'coming_soon', 'hidden');

create table subjects (
  id           text primary key,       -- 'cbse_10_maths_standard'
  class_id     text not null references classes(id),
  code         text not null,          -- 'maths_standard', 'science', 'hindi_a', ...
  name         text not null,
  status       subject_status not null default 'coming_soon',
  eta          text,                   -- human label, e.g. 'Jan 2027'
  accent_color text,                   -- '#RRGGBB'
  sort_order   smallint not null default 0,
  unique (class_id, code)
);

create table chapters (
  id           text primary key,       -- 'maths_standard.quadratic_equations'
  subject_id   text not null references subjects(id),
  name         text not null,
  board_weight numeric(5,2) not null default 0,
  sort_order   smallint not null
);

create table concepts (
  id             text primary key,     -- 'quad.discriminant'
  chapter_id     text not null references chapters(id),
  name           text not null,
  description    text,
  prerequisites  text[] not null default '{}',  -- may point at other subjects/classes
  misconceptions jsonb not null default '[]',
  sort_order     smallint not null default 0
);
create index concepts_chapter_idx on concepts(chapter_id);

create type question_status as enum ('live', 'hidden', 'review');

create table questions (
  id              text primary key,
  subject_id      text not null references subjects(id),
  concept_ids     text[] not null,
  difficulty      smallint not null check (difficulty between 1 and 3),
  type            text not null,       -- key into the question-type registry
  section         text,                -- exam section, e.g. CBSE 'A'..'E'
  marks           numeric(4,1) not null default 1,
  body            jsonb not null,      -- type-specific payload
  rubric          jsonb,               -- value points, for subjective types
  status          question_status not null default 'review',
  content_version integer not null,
  report_count    integer not null default 0,
  created_at      timestamptz not null default now()
);
create index questions_subject_idx on questions(subject_id) where status = 'live';
create index questions_concepts_idx on questions using gin (concept_ids);

create table blueprints (
  id         text primary key,
  subject_id text not null references subjects(id),
  sections   jsonb not null,
  weightage  jsonb not null,
  version    integer not null
);

-- ---------------------------------------------------------------------------
-- Students
-- ---------------------------------------------------------------------------

create table profiles (
  id                uuid primary key references auth.users(id) on delete cascade,
  display_name      text,
  board_id          text references boards(id),
  class_id          text references classes(id),
  target_band       text,              -- 'pass', '60', '75', '90'
  reminder_time     time,
  daily_minutes     smallint default 15,
  parent_contact    text,
  parent_consent_at timestamptz,
  created_at        timestamptz not null default now()
);

create table enrollments (
  user_id            uuid not null references profiles(id) on delete cascade,
  subject_id         text not null references subjects(id),
  target_band        text,
  exam_date          date,
  diagnostic_done_at timestamptz,
  primary key (user_id, subject_id)
);

create table subject_waitlist (
  user_id    uuid not null references profiles(id) on delete cascade,
  subject_id text not null references subjects(id),
  created_at timestamptz not null default now(),
  primary key (user_id, subject_id)
);

create type session_kind as enum ('diagnostic', 'workout', 'practice', 'mock');

create table sessions (
  id           uuid primary key,       -- client-generated for idempotent sync
  user_id      uuid not null references profiles(id) on delete cascade,
  subject_id   text references subjects(id),  -- null for a cross-subject workout
  kind         session_kind not null,
  started_at   timestamptz not null,
  completed_at timestamptz,
  score        numeric(6,2),
  meta         jsonb not null default '{}'
);
create index sessions_user_idx on sessions(user_id, started_at desc);

-- Append-only; the source of truth mastery can always be recomputed from.
create table attempts (
  id               uuid primary key,   -- client-generated for idempotent sync
  user_id          uuid not null references profiles(id) on delete cascade,
  question_id      text not null references questions(id),
  session_id       uuid references sessions(id) on delete cascade,
  answer           jsonb,
  outcome          real not null check (outcome between 0 and 1),  -- 0/1, or partial credit
  misconception_id text,
  hints_used       smallint not null default 0,
  solution_viewed  boolean not null default false,
  time_ms          integer,
  created_at       timestamptz not null
);
create index attempts_user_idx on attempts(user_id, created_at desc);

create type grader_kind as enum ('deterministic', 'rubric_ai', 'self_check');

create table grading_results (
  attempt_id        uuid primary key references attempts(id) on delete cascade,
  grader            grader_kind not null,
  marks             numeric(4,1),
  value_points_hit  jsonb,
  confidence        real,
  model             text,
  created_at        timestamptz not null default now()
);

create table concept_mastery (
  user_id        uuid not null references profiles(id) on delete cascade,
  concept_id     text not null references concepts(id),
  theta          real not null default 0,
  half_life_days real not null default 2,
  last_practiced timestamptz,
  mastered_at    timestamptz,
  attempts       integer not null default 0,
  correct        integer not null default 0,
  updated_at     timestamptz not null default now(),
  primary key (user_id, concept_id)
);

create table streaks (
  user_id          uuid primary key references profiles(id) on delete cascade,
  current          integer not null default 0,
  longest          integer not null default 0,
  rest_tokens      smallint not null default 1,
  last_active_date date
);

create type report_status as enum ('open', 'confirmed', 'rejected', 'fixed');

create table question_reports (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references profiles(id) on delete cascade,
  question_id text not null references questions(id),
  reason      text not null,
  note        text,
  status      report_status not null default 'open',
  created_at  timestamptz not null default now(),
  unique (user_id, question_id)
);

create table subscriptions (
  user_id    uuid primary key references profiles(id) on delete cascade,
  product    text not null,
  status     text not null,
  expires_at timestamptz,
  source     text not null default 'revenuecat',
  updated_at timestamptz not null default now()
);

create table mock_results (
  session_id     uuid primary key references sessions(id) on delete cascade,
  section_scores jsonb not null,
  chapter_scores jsonb not null
);

-- ---------------------------------------------------------------------------
-- Trust rule: a question with 2+ reports is hidden until reviewed.
-- ---------------------------------------------------------------------------

create function on_question_report() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update questions
     set report_count = report_count + 1,
         status = case when report_count + 1 >= 2 and status = 'live'
                       then 'hidden'::question_status else status end
   where id = new.question_id;
  return new;
end $$;

create trigger question_report_hide
  after insert on question_reports
  for each row execute function on_question_report();

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------

-- Content: readable by everyone signed in, writable only by the service role.
alter table boards     enable row level security;
alter table classes    enable row level security;
alter table subjects   enable row level security;
alter table chapters   enable row level security;
alter table concepts   enable row level security;
alter table questions  enable row level security;
alter table blueprints enable row level security;

create policy read_boards     on boards     for select using (true);
create policy read_classes    on classes    for select using (true);
create policy read_subjects   on subjects   for select using (status <> 'hidden');
create policy read_chapters   on chapters   for select using (true);
create policy read_concepts   on concepts   for select using (true);
create policy read_questions  on questions  for select to authenticated using (status = 'live');
create policy read_blueprints on blueprints for select using (true);

-- Student data: each user sees and writes only their own rows.
alter table profiles         enable row level security;
alter table enrollments      enable row level security;
alter table subject_waitlist enable row level security;
alter table sessions         enable row level security;
alter table attempts         enable row level security;
alter table grading_results  enable row level security;
alter table concept_mastery  enable row level security;
alter table streaks          enable row level security;
alter table question_reports enable row level security;
alter table subscriptions    enable row level security;
alter table mock_results     enable row level security;

create policy own_profile on profiles
  for all using (id = auth.uid()) with check (id = auth.uid());
create policy own_enrollments on enrollments
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_waitlist on subject_waitlist
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_sessions on sessions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_concept_mastery on concept_mastery
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_streaks on streaks
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Attempts are append-only from the client.
create policy read_own_attempts on attempts
  for select using (user_id = auth.uid());
create policy insert_own_attempts on attempts
  for insert with check (user_id = auth.uid());

-- Reports: a user can file and see their own.
create policy read_own_reports on question_reports
  for select using (user_id = auth.uid());
create policy insert_own_reports on question_reports
  for insert with check (user_id = auth.uid());

-- Server-written tables: users can read their own rows only.
create policy read_own_grading on grading_results
  for select using (exists (select 1 from attempts a
                            where a.id = attempt_id and a.user_id = auth.uid()));
create policy read_own_subscription on subscriptions
  for select using (user_id = auth.uid());
create policy read_own_mock_results on mock_results
  for select using (exists (select 1 from sessions s
                            where s.id = session_id and s.user_id = auth.uid()));

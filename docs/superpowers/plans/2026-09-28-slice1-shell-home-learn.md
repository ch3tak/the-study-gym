# Slice 1: Shell, Home and Learn — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the five-tab app (Today · Theory · Mission · Tests · Me) with Home · Learn · History · Me, a 5-question Daily Workout with Keep going, a syllabus-grouped Learn tab, a topic-based chapter screen with the interim lesson-read rule, and the old Mission path restyled as the Chapter Trial.

**Architecture:** New screens sit on top of the existing player (`WorkoutScreen`), lessons (`LessonScreen`), content cache (`Content`) and progress stores (`studentProvider`, `theoryProgressProvider`, `levelProgressProvider`). What the chapter screen, Learn and Home show is *derived* in one pure module (`chapter_progress.dart`) and never stored. Three small stores are added where nothing existed: daily workouts and the streak (on the existing `sessions`/`streaks` tables), topic-node passes (new `node_progress` table) and per-level Trial results (a new column on `level_progress`). Units come from the syllabus YAML via a generated, idempotent seed.

**Tech Stack:** Flutter (Dart ^3.13), flutter_riverpod 2.x, supabase_flutter 2.x, Postgres (Supabase), Python 3.11 content pipeline, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-28-app-structure-and-screens-design.md` (Slice 1 in "Build order"). Read it before starting.

**Decisions this plan implements** (agreed in the 28 Sep architecture audit; all "as recommended"):

1. **Interim rule.** A *topic question* is a question whose body has a `node` tag (`guided`, `practice`, `spot_the_mistake`, `challenge`). Trial levels (`level != null`) and untagged practice questions never count. No question is tagged today, so every topic uses the lesson-read rule, and it switches off per topic as tagged questions ship. The node player (all right, wrong ones return at the end) is built and tested on fixtures.
2. **Units** live in a new `units` table plus `chapters.unit_id`, generated from `content/syllabus/cbse/9/maths.yaml`. CI gains a job that applies every migration and seed to a real Postgres first (the gap recorded on 27 Sep).
3. **Level preview metadata.** `why_after_previous` goes into the question body as `whyAfterPrevious`. Type comes from the question type. Time is a per-type estimate in code, shown as "About N min".
4. **Level count** is what actually loads (48 live today): "Level N of 48". Gold means every loaded level is done.
5. **Chapters.** All 15 syllabus chapters are listed. A chapter with lessons *or* questions opens. A topic with no lesson shows "Lesson coming soon" (the user's "mock them for design" is this placeholder state; no fake lessons or questions are added). Only chapters with neither show "Soon".
6. **Daily workout, streak and week row** use the existing `sessions` and `streaks` tables. `DailyNotifier` becomes the only streak writer and reader.
7. **Needs attention** uses read-only fading from PLAN.md §5.1 (mastery ≥ 80% whose decayed value is below 70%).
8. **Platinum.** Solution viewing is recorded per Trial level (`level_progress.solution_viewed`). Gold and Platinum show on the Trial screen; the Me trophy shelf is Slice 4.
9. **Selector.** A workout has 5 questions (2 warm-up, 2 strength, 1 challenge). Keep going excludes questions already served. The workout never serves Trial levels.
10. **Pro demo toggle** moves from the Tests header to Me.

## Global Constraints

- Bottom tabs, exactly and in order: `Home` · `Learn` · `History` · `Me`.
- Colours only from `context.colors` (`lib/core/theme/app_colors.dart`). The only literal colours allowed are `Colors.transparent` and `Colors.white` where existing widgets already use them.
- Every new screen renders in `AppTheme.light` and `AppTheme.dark` without exceptions.
- Learning is never Pro-locked: lessons, topic nodes, the Trial, the daily workout. Only Keep going, mock papers 2–3 and custom tests show Pro.
- The course chip reads `Class 9 ▾`. The switcher lists `CBSE Class 9 Maths`, `CBSE Class 10 Maths` with `Coming soon` (not selectable), and `Add a course`.
- Copy, verbatim: `Keep your N-day streak going`, `Start your streak`, `Start workout`, `Keep going`, `Continue your chapter`, `Continue`, `Topic N of M`, `Trial level N of M`, `N topics fading · Review`, `Learn`, `Soon`, `Tests`, `Notes`, `Practice`, `Trial locked`, `Finish all N topics to open the Trial`, `Questions coming soon`, `Do you know?`, `Level N of M`, `Start level`.
- No hard-coded chapter or topic names in logic, including no special case for Surface Area and Volume.
- Never wipe progress: `theory_progress`, `level_progress`, `concept_mastery`, `attempts`, `streaks` rows stay as they are.
- The live Supabase project (ref `rwkwidndquymwdgqdpmb`) is **never** touched by this plan. The new migration and seed 007 are applied to it only later, and only with the user's explicit go-ahead.
- Git: the user's global instructions forbid Claude co-author lines and "Generated with Claude Code" footers in commits. Commit messages are plain.
- Repo root for every command below is `study-gym/`. Flutter commands run in `study-gym/app/`.

## Review Focus

1. **The live database doesn't have migration `20261001000000` yet.** The app must still start: Learn shows one ungrouped "More chapters" list, and Trial completions still save (the repository retries without the new column). Covered by Task 3 (`without the units migration…`) and Task 14 (`chapters with no unit…`). The level-progress fallback can't be unit-tested without a Supabase client, so the Task 11 reviewer checks it by reading.
2. **A student who played the old Mission path without reading lessons.** Their Trial is gated until the topics are done, but their cleared levels still count in Learn's summary and aren't lost. Task 9 test `old Mission progress is kept behind a locked gate`.
3. **Lessons read out of order in the old Theory tab** must never produce two "current" topics. Task 9 test `lessons read out of order never make two current topics`.
4. **Day boundaries.** A workout at 23:30 counts for that local day, and the streak survives a DST change. Task 6 tests `a late-night workout counts for its own day` and `a DST change doesn't break the streak`.
5. **Running out of questions.** Keep going with few unseen questions left, or a weakest concept with only Trial questions, must give a shorter or empty workout (the existing "No questions available" screen), never a crash. Task 5 tests `an exhausted pool gives fewer questions, not a crash` and `concepts with only Trial questions are never picked`.

---

## Before you start

- [ ] Create the branch from `main`: `git checkout -b feat/slice1-shell-home-learn` (or a worktree via superpowers:using-git-worktrees).
- [ ] Run the baseline: `cd app && flutter test` and `python -m pytest content/pipeline/tests -q` from the repo root. Write down any failures that already exist, so they aren't blamed on this work.

---

### Task 1: CI applies every migration and seed to a real Postgres, and runs the app's tests

Closes the gap in memory note `project_ci_sql_validation_gap` *before* this plan generates new SQL.

**Files:**
- Create: `backend/supabase/ci/auth_shim.sql`
- Create: `backend/supabase/ci/apply_all.sh`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Produces: `backend/supabase/ci/apply_all.sh`, which reads `$DATABASE_URL` and applies files in the order of its `FILES` array. Task 2 appends to that array.

- [ ] **Step 1: Write the auth shim**

`backend/supabase/ci/auth_shim.sql`:

```sql
-- The Supabase-only objects our migrations reference, recreated on plain
-- Postgres so CI can apply the real migration files unchanged. Not applied
-- to Supabase itself, which already has all of these.

create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key
);

-- Supabase's auth.uid(): the signed-in user's id from the request JWT.
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
end $$;
```

- [ ] **Step 2: Write the apply script**

`backend/supabase/ci/apply_all.sh`:

```bash
#!/usr/bin/env bash
# Applies every migration and seed, in dependency order, to the Postgres at
# $DATABASE_URL and stops at the first error. Seeds interleave with
# migrations because each seed's header names the migration it needs
# (e.g. seed 002 runs after 20260927000000).
set -euo pipefail
cd "$(dirname "$0")/.."

FILES=(
  ci/auth_shim.sql
  migrations/20260926000000_core_schema.sql
  migrations/20260926000001_profile_on_signup.sql
  seed/001_cbse_9_maths_science.sql
  migrations/20260927000000_m9_maths_id_convention_and_new_chapters.sql
  seed/002_m9_coord_poly.sql
  migrations/20260928000000_m9_maths_remaining_chapters.sql
  seed/003_m9_remaining_chapters.sql
  migrations/20260929000000_mission_levels.sql
  seed/004_surface_area_volume_mission.sql
  migrations/20260930000000_theory_lessons.sql
  seed/005_surface_area_volume_theory.sql
  seed/006_maths_only.sql
)

for f in "${FILES[@]}"; do
  echo "== $f"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -f "$f"
done
echo "All ${#FILES[@]} files applied."
```

- [ ] **Step 3: Run it against a local Postgres**

If Docker is available:

```bash
docker run -d --name sg-pg -e POSTGRES_PASSWORD=pg -p 55432:5432 postgres:16
sleep 5
DATABASE_URL=postgres://postgres:pg@localhost:55432/postgres bash backend/supabase/ci/apply_all.sh
```

Expected: `All 13 files applied.` If a file fails because a seed runs before the migration it needs, move it after that migration (its header comment names it) and note the reason in the commit message. If Docker isn't installed, **stop and ask the user** whether to push the branch so CI runs it. Never point `DATABASE_URL` at the live Supabase project.

- [ ] **Step 4: Add the `sql` and `app` jobs to CI**

In `.github/workflows/ci.yml`, replace the trailing comment line `# app: flutter analyze + flutter test get added once app/ is scaffolded.` with:

```yaml
  # Applies every migration and seed to a real Postgres, so SQL that only
  # "looks right" as a string (the 27 Sep seed_mission escaping bug) fails
  # here instead of in manual QA.
  sql:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        ports: ["5432:5432"]
        options: >-
          --health-cmd pg_isready --health-interval 5s
          --health-timeout 5s --health-retries 10
    env:
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/postgres
    steps:
      - uses: actions/checkout@v4
      - name: Apply every migration and seed
        run: bash backend/supabase/ci/apply_all.sh

  app:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: app
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter analyze --no-fatal-infos
      - run: flutter test
```

- [ ] **Step 5: Check the app job would pass locally**

Run: `cd app && flutter analyze --no-fatal-infos && flutter test`
Expected: no analyzer errors or warnings, all tests pass (or only the baseline failures you wrote down). If the analyzer reports warnings that already existed, stop and show them to the user before continuing.

- [ ] **Step 6: Commit**

```bash
git add backend/supabase/ci .github/workflows/ci.yml
git commit -m "ci: apply every migration and seed to Postgres; run flutter analyze and test"
```

---

### Task 2: Migration for units, node progress and Trial solution viewing; generated course-structure seed

**Files:**
- Create: `backend/supabase/migrations/20261001000000_units_nodes_trial_meta.sql`
- Create: `content/pipeline/seed_course.py`
- Create: `content/pipeline/tests/test_seed_course.py`
- Create (generated): `backend/supabase/seed/007_course_structure.sql`
- Create: `backend/supabase/ci/checks.sql`
- Modify: `content/pipeline/seed_mission.py:126-144` (`_body_for_question`)
- Modify: `content/pipeline/tests/test_seed_mission.py`
- Modify (regenerated): `backend/supabase/seed/004_surface_area_volume_mission.sql`
- Modify: `backend/supabase/ci/apply_all.sh`

**Interfaces:**
- Produces, for the database: table `units(id, subject_id, name, marks, sort_order)` with unit ids namespaced as `cbse_9_maths.<yaml unit id>`; column `chapters.unit_id`; table `node_progress(user_id, concept_id, node, completed_at)` where `node` is one of `guided|practice|spot_the_mistake|challenge`; column `level_progress.solution_viewed boolean`.
- Produces, in question bodies: `whyAfterPrevious` (string) on every Trial level.
- Produces, for chapters: all 15 syllabus chapters, `sort_order` 1–15 in syllabus order. Three chapters keep legacy ids (`number_system→num`, `coordinate_geometry→coord`, `polynomials→poly`). Six are new and empty.

- [ ] **Step 1: Write the migration**

`backend/supabase/migrations/20261001000000_units_nodes_trial_meta.sql`:

```sql
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
```

- [ ] **Step 2: Write the failing pipeline tests**

`content/pipeline/tests/test_seed_course.py`:

```python
import re
from pathlib import Path

import pytest

from content.pipeline.seed_course import _text_literal, generate_sql

ROOT = Path(__file__).resolve().parents[2]
SYLLABUS = ROOT / "syllabus/cbse/9/maths.yaml"
MISSION = ROOT / "questions/cbse/9/maths/surface_area_volume.yaml"

UNIT_ROW = re.compile(r"^  \('(cbse_9_maths\.[a-z_]+)', 'cbse_9_maths', '(?:[^']|'')*', [\d.]+, (\d+)\)", re.M)
CHAPTER_ROW = re.compile(
    r"^  \('([a-z_]+)', 'cbse_9_maths', '(?:[^']|'')*', [\d.]+, (\d+), 'cbse_9_maths\.([a-z_]+)'\)", re.M
)


def sql() -> str:
    return generate_sql(SYLLABUS, MISSION)


def test_units_are_namespaced_ordered_and_carry_marks():
    s = sql()
    assert "('cbse_9_maths.number_system', 'cbse_9_maths', 'Number System', 7, 1)" in s
    assert "('cbse_9_maths.geometry', 'cbse_9_maths', 'Geometry', 25, 4)" in s
    assert [int(m[1]) for m in UNIT_ROW.findall(s)] == [1, 2, 3, 4, 5, 6]


def test_units_are_inserted_before_chapters():
    s = sql()
    assert s.index("insert into units") < s.index("insert into chapters")


def test_every_syllabus_chapter_is_upserted_once_in_syllabus_order():
    rows = CHAPTER_ROW.findall(sql())
    assert len(rows) == 15
    assert [int(r[1]) for r in rows] == list(range(1, 16))
    assert [r[0] for r in rows][:3] == ["num", "poly", "sequences_progressions"]


def test_legacy_chapter_ids_are_kept():
    s = sql()
    assert "  ('coord', 'cbse_9_maths', 'Coordinate Geometry', 4, 6, 'cbse_9_maths.coordinate_geometry')" in s
    assert "  ('coordinate_geometry'," not in s
    assert "  ('surface_area_volume', 'cbse_9_maths'," in s


def test_new_chapters_are_created_so_learn_can_show_them_as_soon():
    ids = [r[0] for r in CHAPTER_ROW.findall(sql())]
    for new in ["linear_equations", "euclid_geometry", "lines_angles", "triangles", "quadrilaterals", "statistics"]:
        assert new in ids


def test_seed_is_idempotent():
    s = sql()
    assert s.count("on conflict (id) do update set") == 2
    assert "insert into questions" not in s


def test_every_trial_level_gets_why_after_previous_verbatim():
    s = sql()
    updates = re.findall(r"^update questions set body = body \|\| jsonb_build_object\('whyAfterPrevious', \$wap\$", s, re.M)
    assert len(updates) == 62
    assert "$l=b=h$" in s  # LaTeX kept as written


def test_text_literal_refuses_its_own_tag():
    with pytest.raises(ValueError):
        _text_literal("a $wap$ b")
```

Append to `content/pipeline/tests/test_seed_mission.py`:

```python
def test_why_after_previous_is_carried_into_body():
    sql = generate_sql(REAL_MISSION_YAML, REAL_SYLLABUS_YAML)
    assert (
        '"whyAfterPrevious": "First level of the mission: establishes the l/b/h labelling '
        'every later formula depends on."'
    ) in sql
```

- [ ] **Step 3: Run them to confirm they fail**

Run: `python -m pytest content/pipeline/tests/test_seed_course.py content/pipeline/tests/test_seed_mission.py -q`
Expected: FAIL (`ModuleNotFoundError: content.pipeline.seed_course`, and the new seed_mission test fails).

- [ ] **Step 4: Write `seed_course.py`**

`content/pipeline/seed_course.py`:

```python
"""Generates the course-structure seed from the syllabus and the Trial YAML:
the syllabus's units, every syllabus chapter (in syllabus order, linked to its
unit) and each Trial level's `why_after_previous` text.

Idempotent: safe on the live database (seeds 001-006 already applied) and on a
fresh one. Upserts units and chapters, and updates question bodies in place.

Run (from repo root): python -m content.pipeline.seed_course
Writes: backend/supabase/seed/007_course_structure.sql
"""
from __future__ import annotations

from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
SYLLABUS_YAML = REPO_ROOT / "content/syllabus/cbse/9/maths.yaml"
MISSION_YAML = REPO_ROOT / "content/questions/cbse/9/maths/surface_area_volume.yaml"
OUTPUT_SQL = REPO_ROOT / "backend/supabase/seed/007_course_structure.sql"

SUBJECT_ID = "cbse_9_maths"

# Chapters created before the syllabus file existed kept their old ids:
# renaming a chapter id breaks the concepts and level_progress foreign keys
# (see 20260927000000_m9_maths_id_convention_and_new_chapters.sql). Every
# other syllabus chapter id is used as the database id unchanged.
LEGACY_CHAPTER_IDS = {
    "number_system": "num",
    "coordinate_geometry": "coord",
    "polynomials": "poly",
}

_TAG = "$wap$"


def _sql_str(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def _text_literal(value: str) -> str:
    # A tagged dollar quote: the text contains LaTeX ($...$), and the tag
    # makes an accidental "$$" inside it harmless.
    if _TAG in value:
        raise ValueError(f"text contains the quote tag {_TAG}: {value!r}")
    return f"{_TAG}{value}{_TAG}"


def _load_yaml(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def unit_id(yaml_unit: str) -> str:
    return f"{SUBJECT_ID}.{yaml_unit}"


def chapter_db_id(yaml_chapter: str) -> str:
    return LEGACY_CHAPTER_IDS.get(yaml_chapter, yaml_chapter)


def _number(value) -> str:
    return str(int(value)) if float(value).is_integer() else str(value)


def generate_sql(syllabus_path: Path, mission_path: Path) -> str:
    syllabus = _load_yaml(syllabus_path)
    mission = _load_yaml(mission_path)

    lines = [
        "-- Generated by content/pipeline/seed_course.py — do not hand-edit.",
        "-- Units and chapters from content/syllabus/cbse/9/maths.yaml, and each",
        "-- Trial level's why_after_previous. Safe to re-run.",
        "",
        "begin;",
        "",
        "insert into units (id, subject_id, name, marks, sort_order) values",
    ]
    unit_rows = [
        f"  ({_sql_str(unit_id(u['id']))}, {_sql_str(SUBJECT_ID)}, {_sql_str(u['name'])}, "
        f"{_number(u['marks'])}, {i})"
        for i, u in enumerate(syllabus["units"], start=1)
    ]
    lines.append(",\n".join(unit_rows))
    lines.append("on conflict (id) do update set")
    lines.append("  name = excluded.name, marks = excluded.marks, sort_order = excluded.sort_order;")
    lines.append("")

    lines.append("insert into chapters (id, subject_id, name, board_weight, sort_order, unit_id) values")
    chapter_rows = [
        f"  ({_sql_str(chapter_db_id(ch['id']))}, {_sql_str(SUBJECT_ID)}, {_sql_str(ch['name'])}, "
        f"{_number(ch['board_weight_marks'])}, {i}, {_sql_str(unit_id(ch['unit']))})"
        for i, ch in enumerate(syllabus["chapters"], start=1)
    ]
    lines.append(",\n".join(chapter_rows))
    lines.append("on conflict (id) do update set")
    lines.append(
        "  name = excluded.name, board_weight = excluded.board_weight, "
        "sort_order = excluded.sort_order, unit_id = excluded.unit_id;"
    )
    lines.append("")

    for q in mission["questions"]:
        why = q.get("why_after_previous")
        if not why:
            continue
        lines.append(
            "update questions set body = body || jsonb_build_object('whyAfterPrevious', "
            f"{_text_literal(why)}::text) where id = {_sql_str(q['id'])};"
        )
    lines.append("")
    lines.append("commit;")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    OUTPUT_SQL.write_text(generate_sql(SYLLABUS_YAML, MISSION_YAML), encoding="utf-8")
    print(f"Wrote {OUTPUT_SQL}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 5: Carry `why_after_previous` in `seed_mission.py`**

In `_body_for_question`, add these lines just before `return body`:

```python
    if question.get("why_after_previous"):
        body["whyAfterPrevious"] = question["why_after_previous"]
```

- [ ] **Step 6: Run the pipeline tests**

Run: `python -m pytest content/pipeline/tests -q`
Expected: all pass, including the 8 new tests.

- [ ] **Step 7: Generate both seeds**

```bash
python -m content.pipeline.seed_mission
python -m content.pipeline.seed_course
git diff --stat backend/supabase/seed/004_surface_area_volume_mission.sql
```

Expected: 004's diff only adds `"whyAfterPrevious": ...` to question bodies. 007 is new.

- [ ] **Step 8: Add post-apply checks and extend the apply script**

`backend/supabase/ci/checks.sql`:

```sql
-- Run after apply_all.sh: raises (failing CI) if the course structure didn't land.
do $$
declare n int;
begin
  select count(*) into n from units where subject_id = 'cbse_9_maths';
  if n <> 6 then raise exception 'expected 6 units, got %', n; end if;

  select count(*) into n from chapters where subject_id = 'cbse_9_maths' and unit_id is not null;
  if n <> 15 then raise exception 'expected 15 maths chapters with a unit, got %', n; end if;

  select count(*) into n from chapters where subject_id = 'cbse_9_maths' and unit_id is null;
  if n <> 0 then raise exception '% maths chapters have no unit', n; end if;

  select count(*) into n from questions where level is not null and body ? 'whyAfterPrevious';
  if n <> 62 then raise exception 'expected 62 Trial levels with whyAfterPrevious, got %', n; end if;
end $$;
```

In `backend/supabase/ci/apply_all.sh`, add three entries to the end of `FILES`, after `seed/006_maths_only.sql`:

```bash
  migrations/20261001000000_units_nodes_trial_meta.sql
  seed/007_course_structure.sql
  seed/007_course_structure.sql   # twice on purpose: proves it's idempotent
  ci/checks.sql
```

- [ ] **Step 9: Apply against the local Postgres again**

```bash
docker rm -f sg-pg && docker run -d --name sg-pg -e POSTGRES_PASSWORD=pg -p 55432:5432 postgres:16 && sleep 5
DATABASE_URL=postgres://postgres:pg@localhost:55432/postgres bash backend/supabase/ci/apply_all.sh
```

Expected: `All 17 files applied.` with no exception from `checks.sql`. (Without Docker, ask the user as in Task 1.)

- [ ] **Step 10: Commit**

```bash
git add backend/supabase content/pipeline
git commit -m "feat(content): units, node_progress and Trial solution_viewed; seed 007 from the syllabus"
```

---

### Task 3: App content model — units, topic nodes, level metadata; shared test fixture

**Files:**
- Modify: `app/lib/data/models.dart`
- Modify: `app/lib/data/content.dart`
- Modify: `app/lib/data/content_repository.dart`
- Create: `app/test/data/content_repository_units_test.dart`
- Create: `app/test/data/content_test.dart`
- Create: `app/test/fixtures/slice1_content.dart`
- Create: `app/test/helpers/pump.dart`

**Interfaces:**
- Produces (`models.dart`):
  - `class Unit { const Unit({required String id, required String name, required int sortOrder, int? marks}); }`
  - `Chapter.unitId` (`String?`, optional named constructor arg `unitId`)
  - `enum TopicNode { guided, practice, spotTheMistake, challenge }` with `String dbValue`, `String label`, `static TopicNode? fromDb(Object?)`
  - `Question.node` (`TopicNode?`), `Question.whyAfterPrevious` (`String?`), both optional named args
- Produces (`content.dart`): `Content.units`, `Content.chaptersInUnit(String unitId)`, `Content.lessonForConcept(String conceptId) → Lesson?`, `Content.trialLevels(String chapterId) → List<Question>` (sorted by level), `Content.nodeQuestions(String conceptId, TopicNode node)`, `Content.hasTopicQuestions(String conceptId) → bool`, `Content.practiceQuestions(String conceptId)` (all non-Trial questions), `Content.hasContent(String chapterId) → bool`
- Produces: `ContentSnapshot({..., List<Unit> units = const []})`, and `buildSnapshot({..., List unitRows = const [], List chapterUnitRows = const []})`
- Produces (tests): `test/fixtures/slice1_content.dart` exporting `seqChapter`, `idenChapter`, `triChapter`, `savChapter`, `stages`, `fixtureQuestion(...)`, the lessons `cubeLesson`, `cylLesson`, `coneLesson`, `idenLesson`, `slice1Snapshot()` and `loadSlice1Content()`. `test/helpers/pump.dart` exporting `themes`, `pumpScreen(...)`, `SeededStudent` and `answerQuestions(...)`.

- [ ] **Step 1: Add the model types**

In `app/lib/data/models.dart`:

Replace the `Chapter` class with:

```dart
class Chapter {
  const Chapter({
    required this.id,
    required this.name,
    required this.boardWeightMarks,
    required this.concepts,
    this.unitId,
  });

  final String id;
  final String name;
  final int boardWeightMarks;
  final List<Concept> concepts;

  /// The syllabus unit this chapter belongs to (`units.id`). Null when the
  /// database predates 20261001000000_units_nodes_trial_meta.sql.
  final String? unitId;
}

/// A syllabus unit ("Geometry · 25 marks") — mirrors the `units` table,
/// generated from content/syllabus/<board>/<class>/<subject>.yaml.
class Unit {
  const Unit({required this.id, required this.name, required this.sortOrder, this.marks});

  final String id;
  final String name;

  /// Exam marks for the unit. Null for a course with no exam.
  final int? marks;
  final int sortOrder;
}

/// A topic's four question nodes, in path order (spec: "The chapter screen").
enum TopicNode {
  guided('guided', 'Guided'),
  practice('practice', 'Practice'),
  spotTheMistake('spot_the_mistake', 'Spot the mistake'),
  challenge('challenge', 'Challenge');

  const TopicNode(this.dbValue, this.label);

  /// The value in a question body's `node` field and in `node_progress.node`.
  final String dbValue;
  final String label;

  static TopicNode? fromDb(Object? value) {
    for (final n in values) {
      if (n.dbValue == value) return n;
    }
    return null;
  }
}
```

In `Question`'s constructor, add `this.node,` and `this.whyAfterPrevious,` after `this.parts = const [],`. Add these fields after `final List<Question> parts;`:

```dart
  /// The topic node this question belongs to, from the body's `node` tag.
  /// Null for Trial levels and plain practice questions — only tagged
  /// questions count as "topic questions" (spec: the interim rule).
  final TopicNode? node;

  /// Trial levels only: why this level follows the previous one, shown in
  /// the level preview sheet.
  final String? whyAfterPrevious;
```

- [ ] **Step 2: Write the shared fixture and helpers**

`app/test/fixtures/slice1_content.dart`:

```dart
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

/// A small course shaped like the real one, for Slice 1's tests:
/// - Sequences (Algebra): 12 practice questions, no lessons.
/// - Identities (Algebra): one topic with a lesson and node questions
///   (Guided ×2, Challenge ×1), so it does NOT use the interim rule.
/// - Triangles (Geometry): no content, so Learn shows "Soon".
/// - Surface Area and Volume (Mensuration): three lessons, no topic
///   questions (the interim rule), and a 10-level Trial, 2 per stage.
const seqChapter = 'sequences_progressions';
const idenChapter = 'algebraic_identities';
const triChapter = 'triangles';
const savChapter = 'surface_area_volume';

const stages = ['FOUNDATION', 'GUIDED_PRACTICE', 'SKILL_BUILDING', 'APPLICATION', 'MASTERY'];

Question fixtureQuestion(
  String id,
  String conceptId, {
  int difficulty = 1,
  TopicNode? node,
  int? level,
  String? stage,
  String? why,
}) =>
    Question(
      id: id,
      conceptId: conceptId,
      type: QuestionType.mcq,
      difficulty: difficulty,
      marks: 1,
      stem: 'Stem $id',
      options: const ['right', 'wrong'],
      correctIndex: 0,
      solutionSteps: ['Step for $id'],
      node: node,
      level: level,
      stage: stage,
      whyAfterPrevious: why,
    );

const cubeLesson = Lesson(
  id: 't_cube',
  conceptId: 'c.cube',
  title: 'Cuboids and cubes',
  body: 'A cube is a cuboid with equal edges.',
  hookKind: HookKind.realWorld,
  hook: 'Every shipping box is a cuboid.',
  sortOrder: 1,
);
const cylLesson = Lesson(
  id: 't_cyl',
  conceptId: 'c.cyl',
  title: 'Cylinders',
  body: 'A cylinder has two circular faces.',
  hookKind: HookKind.historical,
  hook: 'Archimedes asked for a cylinder on his tomb.',
  sortOrder: 2,
);
const coneLesson = Lesson(
  id: 't_cone',
  conceptId: 'c.cone',
  title: 'Cones',
  body: 'A cone is a third of its cylinder.',
  hookKind: HookKind.realWorld,
  hook: 'An ice-cream cone holds a third of the matching cylinder.',
  sortOrder: 3,
);
const idenLesson = Lesson(
  id: 't_iden',
  conceptId: 'c.iden',
  title: 'Square of a sum',
  body: 'a plus b, squared.',
  hookKind: HookKind.historical,
  hook: 'Euclid proved this with squares.',
  sortOrder: 1,
);

ContentSnapshot slice1Snapshot() => ContentSnapshot(
      units: const [
        Unit(id: 'u.algebra', name: 'Algebra', marks: 20, sortOrder: 1),
        Unit(id: 'u.geometry', name: 'Geometry', marks: 25, sortOrder: 2),
        Unit(id: 'u.mensuration', name: 'Mensuration', marks: 14, sortOrder: 3),
      ],
      chapters: const [
        Chapter(id: seqChapter, name: 'Sequences and Progressions', boardWeightMarks: 6, unitId: 'u.algebra', concepts: [
          Concept(id: 'c.ap', name: 'Arithmetic progressions', chapterId: seqChapter),
          Concept(id: 'c.gp', name: 'Geometric progressions', chapterId: seqChapter),
        ]),
        Chapter(id: idenChapter, name: 'Exploring Algebraic Identities', boardWeightMarks: 5, unitId: 'u.algebra', concepts: [
          Concept(id: 'c.iden', name: 'Square of a sum', chapterId: idenChapter),
        ]),
        Chapter(id: triChapter, name: 'Triangles', boardWeightMarks: 6, unitId: 'u.geometry', concepts: []),
        Chapter(id: savChapter, name: 'Surface Area and Volume', boardWeightMarks: 6, unitId: 'u.mensuration', concepts: [
          Concept(id: 'c.cube', name: 'Cuboids and cubes', chapterId: savChapter),
          Concept(id: 'c.cyl', name: 'Cylinders', chapterId: savChapter),
          Concept(id: 'c.cone', name: 'Cones', chapterId: savChapter),
        ]),
      ],
      questions: [
        // difficulty 1, 1, 2, 2, 3, 3 per concept
        for (final c in ['c.ap', 'c.gp'])
          for (var i = 1; i <= 6; i++) fixtureQuestion('q_${c}_$i', c, difficulty: (i + 1) ~/ 2),
        fixtureQuestion('q_iden_g1', 'c.iden', node: TopicNode.guided),
        fixtureQuestion('q_iden_g2', 'c.iden', node: TopicNode.guided),
        fixtureQuestion('q_iden_c1', 'c.iden', difficulty: 3, node: TopicNode.challenge),
        for (var l = 1; l <= 10; l++)
          fixtureQuestion('q_l$l', 'c.cube', level: l, stage: stages[(l - 1) ~/ 2], why: 'Why level $l comes next.'),
      ],
      lessons: const [cubeLesson, cylLesson, coneLesson, idenLesson],
    );

void loadSlice1Content() => Content.load(slice1Snapshot());
```

`app/test/helpers/pump.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/data/app_state.dart';

/// Both themes, so each screen test can run in light and dark (spec:
/// "Everything renders in both light and dark themes").
final themes = <String, ThemeData>{'light': AppTheme.light, 'dark': AppTheme.dark};

/// Pumps [home] in a tall viewport (long lists stay on screen) inside a
/// MaterialApp and the given (or a fresh) ProviderContainer, and returns the
/// container so tests can read and drive state.
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget home, {
  ThemeData? theme,
  ProviderContainer? container,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = container ?? ProviderContainer();
  if (container == null) addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(theme: theme ?? AppTheme.light, home: home),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

/// A StudentNotifier that starts from [seed] (mastery, Pro flag) instead
/// of an empty state. Use via `studentProvider.overrideWith(() => SeededStudent(...))`.
class SeededStudent extends StudentNotifier {
  SeededStudent(this.seed);
  final StudentState seed;

  @override
  StudentState build() => seed;
}

/// Answers [count] questions in a running WorkoutScreen by tapping [answer],
/// Submit and Continue for each.
Future<void> answerQuestions(WidgetTester tester, int count, {String answer = 'right'}) async {
  for (var i = 0; i < count; i++) {
    await tester.tap(find.text(answer).first);
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }
}
```

- [ ] **Step 3: Write the failing tests**

`app/test/data/content_repository_units_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

Map<String, dynamic> _chapterRow(String id) => {
      'id': id,
      'subject_id': 'cbse_9_maths',
      'name': 'Chapter $id',
      'board_weight': 5,
      'sort_order': 1,
      'subjects': {'class_id': 'cbse_9', 'code': 'maths', 'status': 'live'},
    };

Map<String, dynamic> _conceptRow(String id, String chapterId) =>
    {'id': id, 'chapter_id': chapterId, 'name': 'Concept $id', 'sort_order': 1};

Map<String, dynamic> _questionRow(String id, Map<String, dynamic> body, {int? level}) => {
      'id': id,
      'concept_ids': ['c1'],
      'difficulty': 1,
      'type': 'mcq',
      'marks': 1,
      'body': body,
      'level': level,
      'stage': level == null ? null : 'FOUNDATION',
    };

Map<String, dynamic> _mcq([Map<String, dynamic> extra = const {}]) => {
      'stem': 's',
      'options': ['a', 'b'],
      'correctIndex': 0,
      ...extra,
    };

void main() {
  final repo = ContentRepository.forTesting();

  test('units load and each chapter carries its unit', () {
    final snap = repo.buildSnapshot(
      chapterRows: [_chapterRow('geo')],
      conceptRows: [_conceptRow('c1', 'geo')],
      questionRows: const [],
      unitRows: [
        {'id': 'cbse_9_maths.geometry', 'name': 'Geometry', 'marks': 25, 'sort_order': 4},
      ],
      chapterUnitRows: [
        {'id': 'geo', 'unit_id': 'cbse_9_maths.geometry'},
      ],
    );
    expect(snap.units.single.name, 'Geometry');
    expect(snap.units.single.marks, 25);
    expect(snap.units.single.sortOrder, 4);
    expect(snap.chapters.single.unitId, 'cbse_9_maths.geometry');
  });

  test('without the units migration, chapters load with no unit', () {
    final snap = repo.buildSnapshot(
      chapterRows: [_chapterRow('geo')],
      conceptRows: [_conceptRow('c1', 'geo')],
      questionRows: const [],
    );
    expect(snap.units, isEmpty);
    expect(snap.chapters.single.unitId, isNull);
  });

  test("a question body's node and whyAfterPrevious are parsed", () {
    final snap = repo.buildSnapshot(
      chapterRows: [_chapterRow('geo')],
      conceptRows: [_conceptRow('c1', 'geo')],
      questionRows: [
        _questionRow('q1', _mcq({'node': 'spot_the_mistake'})),
        _questionRow('q2', _mcq({'whyAfterPrevious': 'Because.'}), level: 1),
        _questionRow('q3', _mcq({'node': 'nonsense'})),
      ],
    );
    final byId = {for (final q in snap.questions) q.id: q};
    expect(byId['q1']!.node, TopicNode.spotTheMistake);
    expect(byId['q2']!.whyAfterPrevious, 'Because.');
    expect(byId['q2']!.node, isNull);
    expect(byId['q3']!.node, isNull);
  });
}
```

`app/test/data/content_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/models.dart';

import '../fixtures/slice1_content.dart';

void main() {
  setUp(loadSlice1Content);

  test('Trial levels come sorted and only for their chapter', () {
    final levels = Content.trialLevels(savChapter);
    expect(levels.map((q) => q.level), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    expect(Content.trialLevels(seqChapter), isEmpty);
    expect(Content.trialLevels('no_such_chapter'), isEmpty);
  });

  test('Trial levels never count as topic questions (interim rule)', () {
    expect(Content.hasTopicQuestions('c.cube'), isFalse, reason: 'c.cube only has Trial levels');
    expect(Content.hasTopicQuestions('c.ap'), isFalse, reason: 'untagged practice questions');
    expect(Content.hasTopicQuestions('c.iden'), isTrue);
    expect(Content.nodeQuestions('c.iden', TopicNode.guided).map((q) => q.id), ['q_iden_g1', 'q_iden_g2']);
    expect(Content.nodeQuestions('c.iden', TopicNode.practice), isEmpty);
  });

  test('practice questions exclude Trial levels', () {
    expect(Content.practiceQuestions('c.cube'), isEmpty);
    expect(Content.practiceQuestions('c.ap'), hasLength(6));
  });

  test('a chapter has content if it has lessons or questions', () {
    expect(Content.hasContent(seqChapter), isTrue);
    expect(Content.hasContent(savChapter), isTrue);
    expect(Content.hasContent(triChapter), isFalse);
  });

  test('units, chapters in a unit, and a concept\'s lesson', () {
    expect(Content.units.map((u) => u.name), ['Algebra', 'Geometry', 'Mensuration']);
    expect(Content.chaptersInUnit('u.algebra').map((c) => c.id), [seqChapter, idenChapter]);
    expect(Content.lessonForConcept('c.cyl')?.id, 't_cyl');
    expect(Content.lessonForConcept('c.ap'), isNull);
  });
}
```

- [ ] **Step 4: Run them to confirm they fail**

Run: `cd app && flutter test test/data/content_repository_units_test.dart test/data/content_test.dart`
Expected: compile errors (`units`, `trialLevels`, `unitRows` not defined).

- [ ] **Step 5: Implement `Content` helpers**

In `app/lib/data/content.dart`: add `static List<Unit> _units = const [];` next to the other fields. Add `_units = snapshot.units;` in `load`. Then add these members after `lessonsForChapter`:

```dart
  static List<Unit> get units => _units;

  /// A unit's chapters, in syllabus order (chapters load sorted by sort_order).
  static List<Chapter> chaptersInUnit(String unitId) =>
      chapters.where((c) => c.unitId == unitId).toList();

  /// The lesson that teaches [conceptId] (a topic's Learn node), if any.
  static Lesson? lessonForConcept(String conceptId) {
    final matches = lessons.where((l) => l.conceptId == conceptId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return matches.isEmpty ? null : matches.first;
  }

  /// The chapter's Trial levels in level order. Only live levels load, so
  /// the list can have gaps and be shorter than the 62 designed.
  static List<Question> trialLevels(String chapterId) {
    if (!chapters.any((c) => c.id == chapterId)) return const [];
    return forChapter(chapterId).where((q) => q.level != null).toList()
      ..sort((a, b) => a.level!.compareTo(b.level!));
  }

  /// Questions tagged for one node of a topic. Trial levels never count.
  static List<Question> nodeQuestions(String conceptId, TopicNode node) =>
      questions.where((q) => q.conceptId == conceptId && q.level == null && q.node == node).toList();

  /// Whether any node of this topic has questions. False turns on the
  /// interim rule: the topic is finished once its lesson is read.
  static bool hasTopicQuestions(String conceptId) =>
      questions.any((q) => q.conceptId == conceptId && q.level == null && q.node != null);

  /// A concept's practice pool: every question except Trial levels.
  static List<Question> practiceQuestions(String conceptId) =>
      questions.where((q) => q.conceptId == conceptId && q.level == null).toList();

  /// Whether a chapter has anything to open. Learn shows the rest as "Soon".
  static bool hasContent(String chapterId) {
    if (!chapters.any((c) => c.id == chapterId)) return false;
    return lessonsForChapter(chapterId).isNotEmpty || forChapter(chapterId).isNotEmpty;
  }
```

- [ ] **Step 6: Implement repository parsing**

In `app/lib/data/content_repository.dart`:

1. `ContentSnapshot` becomes:

```dart
class ContentSnapshot {
  const ContentSnapshot({
    required this.chapters,
    required this.questions,
    this.lessons = const [],
    this.units = const [],
  });

  final List<Chapter> chapters;
  final List<Question> questions;
  final List<Lesson> lessons;
  final List<Unit> units;
}
```

2. In `fetchAll`, after the `chapterRows` query, add:

```dart
    // Units (20261001000000_units_nodes_trial_meta.sql) are optional in the
    // same way lessons are: a database without that migration gives one
    // ungrouped chapter list on Learn, not a failed start.
    List unitRows = const [];
    List chapterUnitRows = const [];
    try {
      final chapterList = chapterRows as List;
      final subjectIds = chapterList.map((r) => r['subject_id'] as String).toSet().toList();
      unitRows = await _client
          .from('units')
          .select('id, name, marks, sort_order')
          .inFilter('subject_id', subjectIds)
          .order('sort_order') as List;
      chapterUnitRows = await _client
          .from('chapters')
          .select('id, unit_id')
          .inFilter('id', chapterList.map((r) => r['id'] as String).toList()) as List;
    } on PostgrestException catch (e) {
      debugPrint('Units unavailable: ${e.message}');
    }
```

and pass `unitRows: unitRows, chapterUnitRows: chapterUnitRows,` to `buildSnapshot`.

3. `buildSnapshot` gains `List unitRows = const [], List chapterUnitRows = const [],`. Before the chapters loop, add:

```dart
    final unitByChapter = <String, String?>{
      for (final r in chapterUnitRows) r['id'] as String: r['unit_id'] as String?,
    };
```

Pass `unitId: unitByChapter[chapterId],` into `Chapter(...)`. Before the `return`, add:

```dart
    final units = <Unit>[
      for (final r in unitRows)
        Unit(
          id: r['id'] as String,
          name: r['name'] as String,
          marks: (r['marks'] as num?)?.round(),
          sortOrder: (r['sort_order'] as num).toInt(),
        ),
    ];
```

and return `ContentSnapshot(chapters: chapters, questions: questions, lessons: lessons, units: units)`.

4. In `_questionFromRow`'s `return Question(...)`, add:

```dart
      node: TopicNode.fromDb(body['node']),
      whyAfterPrevious: body['whyAfterPrevious'] as String?,
```

- [ ] **Step 7: Run the tests**

Run: `cd app && flutter test test/data`
Expected: all pass (new and existing).

- [ ] **Step 8: Commit**

```bash
git add app/lib/data app/test/data app/test/fixtures app/test/helpers
git commit -m "feat(app): load units, topic node tags and Trial level metadata"
```

---

### Task 4: Course model and the course chip

**Files:**
- Create: `app/lib/data/course.dart`
- Create: `app/lib/shared/widgets/course_chip.dart`
- Test: `app/test/shared/course_chip_test.dart`

**Interfaces:**
- Produces: `class Course { id, shortLabel, title, available }`, `Courses.all`, `final activeCourseProvider = Provider<Course>`, `class CourseChip extends ConsumerWidget` (no args), `Future<void> showCourseSwitcher(BuildContext, Course active)`.

- [ ] **Step 1: Write the failing test**

`app/test/shared/course_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/shared/widgets/course_chip.dart';

import '../helpers/pump.dart';

void main() {
  for (final t in themes.entries) {
    testWidgets('chip shows the active course and opens the switcher (${t.key})', (tester) async {
      await pumpScreen(tester, const Scaffold(body: Center(child: CourseChip())), theme: t.value);
      expect(find.text('Class 9 ▾'), findsOneWidget);

      await tester.tap(find.text('Class 9 ▾'));
      await tester.pumpAndSettle();
      expect(find.text('CBSE Class 9 Maths'), findsOneWidget);
      expect(find.text('CBSE Class 10 Maths'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.text('Add a course'), findsOneWidget);

      final class10 = tester.widget<ListTile>(find.widgetWithText(ListTile, 'CBSE Class 10 Maths'));
      expect(class10.enabled, isFalse, reason: 'Class 10 must not be selectable');
    });
  }
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/shared/course_chip_test.dart`
Expected: compile error (`course_chip.dart` doesn't exist).

- [ ] **Step 3: Implement**

`app/lib/data/course.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A course the student studies (spec "Decisions" 1–2). Only one is live;
/// the others are listed so the switcher is honest about what's coming.
class Course {
  const Course({required this.id, required this.shortLabel, required this.title, required this.available});

  /// The `subjects.id` the course is built from.
  final String id;

  /// Chip text, e.g. "Class 9".
  final String shortLabel;
  final String title;
  final bool available;
}

class Courses {
  Courses._();

  static const all = [
    Course(id: 'cbse_9_maths', shortLabel: 'Class 9', title: 'CBSE Class 9 Maths', available: true),
    Course(id: 'cbse_10_maths_standard', shortLabel: 'Class 10', title: 'CBSE Class 10 Maths', available: false),
  ];
}

/// The course Home and Learn show. One live course for now; switching
/// between several comes with onboarding (Slice 5).
final activeCourseProvider = Provider<Course>((ref) => Courses.all.firstWhere((c) => c.available));
```

`app/lib/shared/widgets/course_chip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/course.dart';

/// "Class 9 ▾" at the top of Home and Learn; opens the course switcher.
class CourseChip extends ConsumerWidget {
  const CourseChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final course = ref.watch(activeCourseProvider);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => showCourseSwitcher(context, course),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            '${course.shortLabel} ▾',
            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

Future<void> showCourseSwitcher(BuildContext context, Course active) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => _CourseSwitcherSheet(active: active),
  );
}

class _CourseSwitcherSheet extends StatelessWidget {
  const _CourseSwitcherSheet({required this.active});
  final Course active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space8),
              child: Text('Your courses', style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final course in Courses.all)
              ListTile(
                title: Text(course.title),
                enabled: course.available,
                trailing: course.id == active.id
                    ? Icon(Icons.check_rounded, color: colors.brand)
                    : (course.available ? null : Text('Coming soon', style: TextStyle(color: colors.inkFaint))),
                onTap: course.available ? () => Navigator.of(context).pop() : null,
              ),
            ListTile(
              leading: Icon(Icons.add_rounded, color: colors.brand),
              title: const Text('Add a course'),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger.showSnackBar(const SnackBar(content: Text('More courses are on the way.')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test**

Run: `cd app && flutter test test/shared/course_chip_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add app/lib/data/course.dart app/lib/shared/widgets/course_chip.dart app/test/shared
git commit -m "feat(app): course chip and switcher (Class 9 live, Class 10 coming soon)"
```

---

### Task 5: The workout selector — 5 questions, Keep going exclusions, no Trial levels

Moves the existing selection out of `TodayScreen._pickWorkoutConcepts` and `WorkoutScreen._buildWorkout` into one module. Same bucket logic, scaled from 10 to 5.

**Files:**
- Create: `app/lib/features/workout/workout_selector.dart`
- Modify: `app/lib/features/workout/workout_screen.dart`
- Modify: `app/lib/features/today/today_screen.dart` (uses the moved function until Task 16 deletes it)
- Test: `app/test/features/workout/workout_selector_test.dart`

**Interfaces:**
- Produces: `enum WorkoutSection { warmUp, strength, challenge }`, `enum WorkoutKind { daily, keepGoing, practice }`, `class SelectedQuestion { Question question; WorkoutSection section; }`, `const dailyWorkoutSize = 5`, `const practiceWorkoutSize = 10`, `List<Concept> pickWorkoutConcepts(StudentState)`, `List<SelectedQuestion> selectWorkout(List<Concept>, {int count = dailyWorkoutSize, Set<String> exclude = const {}})`.
- Produces: `WorkoutScreen({required List<Concept> concepts, WorkoutKind kind = WorkoutKind.practice, Set<String> exclude = const {}})` plus fields `kind` and `exclude`.

- [ ] **Step 1: Write the failing test**

`app/test/features/workout/workout_selector_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/workout/workout_selector.dart';

import '../../fixtures/slice1_content.dart';

List<Concept> _concepts(List<String> ids) => ids.map(Content.conceptById).toList();

void main() {
  setUp(loadSlice1Content);

  test('the daily workout is exactly 5 questions: 2 warm-up, 2 strength, 1 challenge', () {
    final picked = selectWorkout(_concepts(['c.ap', 'c.gp']));
    expect(picked, hasLength(5));
    expect(picked.map((s) => s.section), [
      WorkoutSection.warmUp,
      WorkoutSection.warmUp,
      WorkoutSection.strength,
      WorkoutSection.strength,
      WorkoutSection.challenge,
    ]);
  });

  test('Keep going gives 5 more, none repeated', () {
    final first = selectWorkout(_concepts(['c.ap', 'c.gp']));
    final served = first.map((s) => s.question.id).toSet();
    final more = selectWorkout(_concepts(['c.ap', 'c.gp']), exclude: served);
    expect(more, hasLength(5));
    expect(more.map((s) => s.question.id).toSet().intersection(served), isEmpty);
  });

  test('Trial levels are never served', () {
    expect(selectWorkout(_concepts(['c.cube'])), isEmpty);
  });

  test('an exhausted pool gives fewer questions, not a crash', () {
    final all = Content.questions.where((q) => q.level == null && q.conceptId.startsWith('c.')).map((q) => q.id).toSet();
    final ten = all.where((id) => id != 'q_c.ap_6' && id != 'q_c.gp_6').toSet();
    expect(selectWorkout(_concepts(['c.ap', 'c.gp']), exclude: ten), hasLength(2));
    expect(selectWorkout(_concepts(['c.ap', 'c.gp']), exclude: all), isEmpty);
  });

  test('a new student trains the first chapter that has practice questions', () {
    expect(pickWorkoutConcepts(StudentState()).map((c) => c.id), ['c.ap', 'c.gp']);
  });

  test('weakest concepts first, but concepts with only Trial questions are never picked', () {
    final student = StudentState(mastery: {
      'c.cube': ConceptMastery(conceptId: 'c.cube', masteryPercent: 1, attempts: 3),
      'c.gp': ConceptMastery(conceptId: 'c.gp', masteryPercent: 10, attempts: 3),
      'c.ap': ConceptMastery(conceptId: 'c.ap', masteryPercent: 90, attempts: 3),
    });
    expect(pickWorkoutConcepts(student).map((c) => c.id), ['c.gp', 'c.ap']);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/features/workout/workout_selector_test.dart`
Expected: compile error (`workout_selector.dart` doesn't exist).

- [ ] **Step 3: Implement the selector**

`app/lib/features/workout/workout_selector.dart`:

```dart
import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/models.dart';

enum WorkoutSection { warmUp, strength, challenge }

/// Daily and Keep going runs are saved as workouts (they keep the streak)
/// and end with Keep going. Practice runs (topic practice, fading review,
/// custom tests) are not.
enum WorkoutKind { daily, keepGoing, practice }

class SelectedQuestion {
  const SelectedQuestion(this.question, this.section);
  final Question question;
  final WorkoutSection section;
}

/// The Daily Workout and each Keep going batch (spec: "5-question, about
/// 5-minute workout").
const dailyWorkoutSize = 5;

/// Topic practice and custom tests keep the old workout's size.
const practiceWorkoutSize = 10;

/// The concepts a workout trains: the student's three weakest that have
/// practice questions, or, for a new student, up to three from the first
/// chapter that has any.
List<Concept> pickWorkoutConcepts(StudentState student) {
  final entries = student.mastery.values.toList()
    ..sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));
  final picked = entries
      .map((m) => Content.conceptOrNull(m.conceptId))
      .whereType<Concept>()
      .where((c) => Content.practiceQuestions(c.id).isNotEmpty)
      .take(3)
      .toList();
  if (picked.isNotEmpty) return picked;
  for (final chapter in Content.chapters) {
    final withQuestions = chapter.concepts.where((c) => Content.practiceQuestions(c.id).isNotEmpty).take(3).toList();
    if (withQuestions.isNotEmpty) return withQuestions;
  }
  return const [];
}

/// Picks up to [count] questions for [concepts]: 2 warm-up (difficulty 1),
/// 2 strength (difficulty 2) and 1 challenge (difficulty 2+), the 10-question
/// workout's 3/5/2 scaled to 5. A thin bucket is backfilled from the rest
/// of the pool, then from the concepts' whole chapters. Trial levels are never
/// served, so the workout can't spoil them. [exclude] keeps a Keep going
/// batch from repeating today's questions.
List<SelectedQuestion> selectWorkout(
  List<Concept> concepts, {
  int count = dailyWorkoutSize,
  Set<String> exclude = const {},
}) {
  final pool = concepts
      .expand((c) => Content.practiceQuestions(c.id))
      .where((q) => !exclude.contains(q.id))
      .toList();
  final result = <SelectedQuestion>[];
  final used = <String>{};

  void add(Iterable<Question> candidates, WorkoutSection section, int max) {
    var added = 0;
    for (final q in candidates) {
      if (added >= max || result.length >= count) return;
      if (used.add(q.id)) {
        result.add(SelectedQuestion(q, section));
        added++;
      }
    }
  }

  add(pool.where((q) => q.difficulty == 1), WorkoutSection.warmUp, 2);
  add(pool.where((q) => q.difficulty == 2), WorkoutSection.strength, 2);
  add(pool.where((q) => q.difficulty >= 2), WorkoutSection.challenge, 1);
  add(pool, WorkoutSection.strength, count);

  if (result.length < count) {
    final chapterConcepts = concepts.map((c) => Content.chapterOf(c.id)).toSet().expand((ch) => ch.concepts);
    final wider = chapterConcepts
        .expand((c) => Content.practiceQuestions(c.id))
        .where((q) => !exclude.contains(q.id));
    add(wider, WorkoutSection.strength, count);
  }
  return result;
}
```

- [ ] **Step 4: Use it in `WorkoutScreen`**

In `app/lib/features/workout/workout_screen.dart`:

1. Add `import 'workout_selector.dart';`. Delete `enum _Section { warmUp, strength, challenge }`. Replace every `_Section` with `WorkoutSection` (in `_WorkoutItem`, `_SectionBadge` and `_buildWorkout`).
2. Replace the two constructors and the fields above `createState` with:

```dart
  const WorkoutScreen({
    super.key,
    required this.concepts,
    this.kind = WorkoutKind.practice,
    this.exclude = const {},
  }) : singleLevelQuestion = null;

  const WorkoutScreen.singleLevel(Question level, {super.key})
      : concepts = const [],
        kind = WorkoutKind.practice,
        exclude = const {},
        singleLevelQuestion = level;

  final List<Concept> concepts;

  /// Daily and Keep going runs are recorded as workouts (Task 7).
  final WorkoutKind kind;

  /// Question ids already served today, kept out of a Keep going batch.
  final Set<String> exclude;
  final Question? singleLevelQuestion;
```

3. Replace the body of `_buildWorkout()` below the single-level branch (from `final all = <_WorkoutItem>[];` to `return all.take(10).toList();`) with:

```dart
    final count = widget.kind == WorkoutKind.practice ? practiceWorkoutSize : dailyWorkoutSize;
    return selectWorkout(widget.concepts, count: count, exclude: widget.exclude)
        .map((s) => _WorkoutItem(question: s.question, section: s.section))
        .toList();
```

- [ ] **Step 5: Point `TodayScreen` at the moved function**

In `app/lib/features/today/today_screen.dart`, add `import '../workout/workout_selector.dart';`. Delete the `_pickWorkoutConcepts` method and replace its call with `pickWorkoutConcepts(student)`. The file is deleted in Task 16; this only keeps it compiling until then.

- [ ] **Step 6: Run the tests**

Run: `cd app && flutter test test/features/workout`
Expected: all pass, including the existing `workout_screen_test.dart`.

- [ ] **Step 7: Commit**

```bash
git add app/lib/features app/test/features/workout
git commit -m "feat(app): 5-question workout selector with Keep going exclusions; Trial levels never served"
```

---

### Task 6: Daily workouts, the streak and the week row

**Files:**
- Create: `app/lib/data/daily_state.dart`
- Create: `app/lib/data/daily_repository.dart`
- Modify: `app/lib/data/app_state.dart` (remove `streak`)
- Modify: `app/lib/data/student_repository.dart` (stop reading `streaks`)
- Modify: `app/lib/shared/widgets/streak_flame.dart` (dashed "today" dot)
- Modify: `app/lib/features/today/today_screen.dart`, `app/lib/features/workout/workout_complete_screen.dart` (read the streak from `dailyProvider`)
- Modify: `app/lib/main.dart`
- Test: `app/test/data/daily_state_test.dart`

**Interfaces:**
- Produces: `DateTime calendarDay(DateTime)`, `String isoDate(DateTime)`, `WorkoutRecord`, `StreakRecord`, `DailySnapshot`, and `DailyState` with `workouts`, `streak`, `servedQuestionIds`, `workoutDoneOn(DateTime)`, `firstWorkoutOn(DateTime)`, `streakOn(DateTime)` and `weekOf(DateTime) → List<DayState>`. Also `StreakRecord streakAfterWorkout(StreakRecord, DateTime)`, and `DailyNotifier` with `static DailyRepository? repositoryOverride`, `static DateTime Function() clock` and `recordWorkout({required List<String> questionIds, required int correct, required int total, required bool keepGoing, required DateTime startedAt})`. Finally `dailyProvider`, and `DailyRepository` with `fetch()`, `recordWorkout(WorkoutRecord, {required DateTime startedAt})` and `saveStreak(StreakRecord)`.
- Removes: `StudentState.streak`, `StudentSnapshot.streak`.

- [ ] **Step 1: Write the failing test**

`app/test/data/daily_state_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/daily_repository.dart';
import 'package:study_gym/data/daily_state.dart';
import 'package:study_gym/shared/widgets/streak_flame.dart';

// 28 Sep 2026 is a Monday.
final mon = DateTime(2026, 9, 28, 10);
final tue = DateTime(2026, 9, 29, 10);
final wed = DateTime(2026, 9, 30, 10);

class FakeDailyRepo implements DailyRepository {
  FakeDailyRepo({this.snapshot = const DailySnapshot(workouts: [], streak: StreakRecord())});
  final DailySnapshot snapshot;
  final saved = <WorkoutRecord>[];
  final streaks = <StreakRecord>[];

  @override
  Future<DailySnapshot> fetch({int days = 14}) async => snapshot;

  @override
  Future<void> recordWorkout(WorkoutRecord workout, {required DateTime startedAt}) async => saved.add(workout);

  @override
  Future<void> saveStreak(StreakRecord streak) async => streaks.add(streak);
}

void main() {
  tearDown(() {
    DailyNotifier.clock = DateTime.now;
    DailyNotifier.repositoryOverride = null;
  });

  group('streak', () {
    test('first ever workout starts the streak at 1', () {
      final s = streakAfterWorkout(const StreakRecord(), mon);
      expect(s.current, 1);
      expect(s.longest, 1);
      expect(s.lastActiveDate, calendarDay(mon));
    });

    test('a workout the day after adds one', () {
      final s = streakAfterWorkout(StreakRecord(current: 4, longest: 4, lastActiveDate: mon), tue);
      expect(s.current, 5);
      expect(s.longest, 5);
    });

    test('a second workout the same day changes nothing', () {
      final before = StreakRecord(current: 4, longest: 6, lastActiveDate: mon);
      expect(streakAfterWorkout(before, mon.add(const Duration(hours: 5))), same(before));
    });

    test('a missed day restarts at 1 and keeps the longest', () {
      final s = streakAfterWorkout(StreakRecord(current: 4, longest: 6, lastActiveDate: mon), wed);
      expect(s.current, 1);
      expect(s.longest, 6);
    });

    test("a DST change doesn't break the streak", () {
      // Europe moves clocks back on 25 Oct 2026; the local days are still consecutive.
      final s = streakAfterWorkout(
        StreakRecord(current: 2, longest: 2, lastActiveDate: DateTime(2026, 10, 25)),
        DateTime(2026, 10, 26, 0, 30),
      );
      expect(s.current, 3);
    });

    test('streakOn shows the stored streak only while it is alive', () {
      final state = DailyState(streak: StreakRecord(current: 3, longest: 3, lastActiveDate: mon));
      expect(state.streakOn(mon), 3);
      expect(state.streakOn(tue), 3);
      expect(state.streakOn(wed), 0);
      expect(const DailyState().streakOn(mon), 0);
    });
  });

  group('week row', () {
    test('seven Monday-to-Sunday dots; today stays open until the workout is done', () {
      final state = DailyState(workouts: [WorkoutRecord(completedAt: tue, correct: 4, total: 5)]);
      expect(state.weekOf(wed), [
        DayState.missed,
        DayState.done,
        DayState.today,
        DayState.future,
        DayState.future,
        DayState.future,
        DayState.future,
      ]);
      final after = DailyState(workouts: [...state.workouts, WorkoutRecord(completedAt: wed, correct: 5, total: 5)]);
      expect(after.weekOf(wed)[2], DayState.done);
    });

    test('a late-night workout counts for its own day', () {
      final state = DailyState(workouts: [WorkoutRecord(completedAt: DateTime(2026, 9, 29, 23, 30), correct: 5, total: 5)]);
      expect(state.workoutDoneOn(tue), isTrue);
      expect(state.workoutDoneOn(wed), isFalse);
    });

    test("firstWorkoutOn returns the day's first workout, not Keep going", () {
      final state = DailyState(workouts: [
        WorkoutRecord(completedAt: mon.add(const Duration(hours: 2)), correct: 5, total: 5, keepGoing: true),
        WorkoutRecord(completedAt: mon, correct: 3, total: 5),
      ]);
      expect(state.firstWorkoutOn(mon)!.correct, 3);
    });
  });

  group('DailyNotifier', () {
    test('recording a workout saves the session and streak and remembers served questions', () async {
      final repo = FakeDailyRepo();
      DailyNotifier.repositoryOverride = repo;
      DailyNotifier.clock = () => mon;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(dailyProvider);
      await Future<void>.delayed(Duration.zero);

      container.read(dailyProvider.notifier).recordWorkout(
            questionIds: ['a', 'b'],
            correct: 1,
            total: 2,
            keepGoing: false,
            startedAt: mon,
          );

      final state = container.read(dailyProvider);
      expect(state.workoutDoneOn(mon), isTrue);
      expect(state.streakOn(mon), 1);
      expect(state.servedQuestionIds, {'a', 'b'});
      expect(repo.saved.single.total, 2);
      expect(repo.streaks.single.current, 1);
    });

    test('hydrates past workouts and the stored streak', () async {
      DailyNotifier.repositoryOverride = FakeDailyRepo(
        snapshot: DailySnapshot(
          workouts: [WorkoutRecord(completedAt: mon, correct: 5, total: 5)],
          streak: StreakRecord(current: 7, longest: 9, lastActiveDate: mon),
        ),
      );
      DailyNotifier.clock = () => tue;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(dailyProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(dailyProvider);
      expect(state.workoutDoneOn(mon), isTrue);
      expect(state.streakOn(tue), 7);
    });
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/data/daily_state_test.dart`
Expected: compile error (`daily_state.dart` doesn't exist).

- [ ] **Step 3: Implement the state**

`app/lib/data/daily_state.dart`:

```dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/widgets/streak_flame.dart' show DayState;
import 'daily_repository.dart';

/// The calendar day of [t] as a UTC midnight, so day arithmetic ignores DST.
/// [t] must be a local time (or already a calendar day).
DateTime calendarDay(DateTime t) => DateTime.utc(t.year, t.month, t.day);

/// `YYYY-MM-DD` for a calendar day, as `streaks.last_active_date` stores it.
String isoDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

/// One finished workout (a `sessions` row of kind `workout`).
class WorkoutRecord {
  const WorkoutRecord({required this.completedAt, required this.correct, required this.total, this.keepGoing = false});

  /// Local time.
  final DateTime completedAt;
  final int correct;
  final int total;
  final bool keepGoing;
}

/// Mirrors the `streaks` row.
class StreakRecord {
  const StreakRecord({this.current = 0, this.longest = 0, this.lastActiveDate});
  final int current;
  final int longest;

  /// The last calendar day with a workout.
  final DateTime? lastActiveDate;
}

class DailySnapshot {
  const DailySnapshot({required this.workouts, required this.streak});
  final List<WorkoutRecord> workouts;
  final StreakRecord streak;
}

/// Everything day-based on Home: whether today's workout is done, the streak
/// and the week row. The only owner of the streak.
class DailyState {
  const DailyState({this.workouts = const [], this.streak = const StreakRecord(), this.servedQuestionIds = const {}});

  /// Recent workouts (the last two weeks, plus any finished this run).
  final List<WorkoutRecord> workouts;
  final StreakRecord streak;

  /// Question ids served since the app started; the next Keep going batch
  /// leaves them out.
  final Set<String> servedQuestionIds;

  WorkoutRecord? firstWorkoutOn(DateTime day) {
    final d = calendarDay(day);
    final sameDay = workouts.where((w) => calendarDay(w.completedAt) == d).toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return sameDay.firstOrNull;
  }

  bool workoutDoneOn(DateTime day) => firstWorkoutOn(day) != null;

  /// The streak as of [today]: the stored count while it's alive (last
  /// workout today or yesterday), else 0.
  int streakOn(DateTime today) {
    final last = streak.lastActiveDate;
    if (last == null) return 0;
    final gap = calendarDay(today).difference(calendarDay(last)).inDays;
    return gap <= 1 ? streak.current : 0;
  }

  /// Monday-to-Sunday dots for the week containing [today]. Today is
  /// [DayState.today] (drawn dashed) until its workout is done.
  List<DayState> weekOf(DateTime today) {
    final t = calendarDay(today);
    final monday = t.subtract(Duration(days: t.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final done = workoutDoneOn(day);
      if (day == t) return done ? DayState.done : DayState.today;
      if (day.isAfter(t)) return DayState.future;
      return done ? DayState.done : DayState.missed;
    });
  }
}

/// The streak after a workout finishes at [now]. A second workout on the
/// same day changes nothing; a missed day restarts it at 1.
StreakRecord streakAfterWorkout(StreakRecord s, DateTime now) {
  final today = calendarDay(now);
  final last = s.lastActiveDate == null ? null : calendarDay(s.lastActiveDate!);
  if (last == today) return s;
  final current = (last != null && today.difference(last).inDays == 1) ? s.current + 1 : 1;
  return StreakRecord(current: current, longest: current > s.longest ? current : s.longest, lastActiveDate: today);
}

class DailyNotifier extends Notifier<DailyState> {
  /// Set by main.dart; null in tests that don't need persistence.
  static DailyRepository? repositoryOverride;

  /// "Now" for everything date-based. Tests pin it.
  static DateTime Function() clock = DateTime.now;

  DailyRepository? get _repo => repositoryOverride;

  @override
  DailyState build() {
    if (_repo != null) _hydrate();
    return const DailyState();
  }

  Future<void> _hydrate() async {
    try {
      final snap = await _repo!.fetch();
      // A workout finished while this fetch was in flight is already in
      // state: keep it, and the streak it produced.
      state = DailyState(
        workouts: [...snap.workouts, ...state.workouts],
        streak: state.workouts.isEmpty ? snap.streak : state.streak,
        servedQuestionIds: state.servedQuestionIds,
      );
    } catch (e) {
      debugPrint('Could not load daily progress: $e');
    }
  }

  void recordWorkout({
    required List<String> questionIds,
    required int correct,
    required int total,
    required bool keepGoing,
    required DateTime startedAt,
  }) {
    final now = clock();
    final record = WorkoutRecord(completedAt: now, correct: correct, total: total, keepGoing: keepGoing);
    final streak = streakAfterWorkout(state.streak, now);
    state = DailyState(
      workouts: [...state.workouts, record],
      streak: streak,
      servedQuestionIds: {...state.servedQuestionIds, ...questionIds},
    );
    _repo?.recordWorkout(record, startedAt: startedAt).catchError((Object e) => debugPrint('Could not save workout: $e'));
    _repo?.saveStreak(streak).catchError((Object e) => debugPrint('Could not save streak: $e'));
  }
}

final dailyProvider = NotifierProvider<DailyNotifier, DailyState>(DailyNotifier.new);
```

`app/lib/data/daily_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'daily_state.dart';

/// Reads/writes workouts (`sessions` rows of kind `workout`) and the
/// `streaks` row. Both tables and their own-rows RLS policies already exist
/// (20260926000000_core_schema.sql).
class DailyRepository {
  DailyRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in user — cannot read/write daily progress.');
    return id;
  }

  Future<DailySnapshot> fetch({int days = 14}) async {
    final userId = _userId;
    final since = DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();
    final sessionRows = await _client
        .from('sessions')
        .select('completed_at, score, meta')
        .eq('user_id', userId)
        .eq('kind', 'workout')
        .not('completed_at', 'is', null)
        .gte('completed_at', since);
    final streakRow = await _client
        .from('streaks')
        .select('current, longest, last_active_date')
        .eq('user_id', userId)
        .maybeSingle();

    final workouts = <WorkoutRecord>[
      for (final r in sessionRows as List)
        WorkoutRecord(
          completedAt: DateTime.parse(r['completed_at'] as String).toLocal(),
          correct: (r['score'] as num?)?.round() ?? 0,
          total: ((r['meta'] as Map?)?['total'] as num?)?.round() ?? 0,
          keepGoing: (r['meta'] as Map?)?['keep_going'] == true,
        ),
    ];
    final last = streakRow?['last_active_date'] as String?;
    return DailySnapshot(
      workouts: workouts,
      streak: StreakRecord(
        current: streakRow?['current'] as int? ?? 0,
        longest: streakRow?['longest'] as int? ?? 0,
        lastActiveDate: last == null ? null : DateTime.parse(last),
      ),
    );
  }

  Future<void> recordWorkout(WorkoutRecord workout, {required DateTime startedAt}) async {
    await _client.from('sessions').insert({
      'id': _uuid.v4(),
      'user_id': _userId,
      'kind': 'workout',
      'started_at': startedAt.toUtc().toIso8601String(),
      'completed_at': workout.completedAt.toUtc().toIso8601String(),
      'score': workout.correct,
      'meta': {'total': workout.total, 'keep_going': workout.keepGoing},
    });
  }

  Future<void> saveStreak(StreakRecord streak) async {
    await _client.from('streaks').upsert({
      'user_id': _userId,
      'current': streak.current,
      'longest': streak.longest,
      if (streak.lastActiveDate != null) 'last_active_date': isoDate(streak.lastActiveDate!),
    });
  }
}
```

- [ ] **Step 4: Remove the streak from `StudentState` and `StudentRepository`**

- `app/lib/data/app_state.dart`: delete the `streak` field, its constructor parameter, its `copyWith` parameter and its use in `copyWith`. In `_hydrate`, change to `state = state.copyWith(mastery: snapshot.mastery);`.
- `app/lib/data/student_repository.dart`: delete the `streakRows` query, `StudentSnapshot.streak` and the `setStreak` method. `fetchAll` returns `StudentSnapshot(mastery: mastery)`.
- `app/lib/features/today/today_screen.dart`: add `import '../../data/daily_state.dart';`. In `build`, add `final streak = ref.watch(dailyProvider).streakOn(DailyNotifier.clock());` and replace both `student.streak` uses with `streak`.
- `app/lib/features/workout/workout_complete_screen.dart`: add `import '../../data/daily_state.dart';` and replace `'${student.streak} day streak'` with `'${ref.watch(dailyProvider).streakOn(DailyNotifier.clock())} day streak'`.
- `app/lib/main.dart`: add `import 'data/daily_repository.dart';` and `import 'data/daily_state.dart';`, and after the `TheoryProgressNotifier.repositoryOverride` line add `DailyNotifier.repositoryOverride = DailyRepository(Supabase.instance.client);`.

- [ ] **Step 5: Draw today's dot dashed**

In `app/lib/shared/widgets/streak_flame.dart`, add `import 'dart:math' as math;` at the top. Replace the `case DayState.today:` branch with:

```dart
      case DayState.today:
        // Dashed until today's workout is done (spec: Home's week row).
        return SizedBox(
          width: dim,
          height: dim,
          child: CustomPaint(painter: _DashedRingPainter(color: colors.brand)),
        );
```

and add at the end of the file:

```dart
class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final rect = (Offset.zero & size).deflate(1.25);
    const dashes = 12;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.6, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) => oldDelegate.color != color;
}
```

- [ ] **Step 6: Run all app tests**

Run: `cd app && flutter test`
Expected: all pass. `grep -rn "\.streak\b" app/lib app/test` shows no `StudentState` streak use left (only `colors.streak` and `DailyState.streak`).

- [ ] **Step 7: Commit**

```bash
git add app/lib app/test
git commit -m "feat(app): daily workouts, streak and week row on sessions/streaks; dashed today dot"
```

---

### Task 7: Finishing a workout — record it, offer Keep going, share the Pro sheet

**Files:**
- Create: `app/lib/shared/widgets/pro_sheet.dart`
- Create: `app/lib/features/workout/keep_going.dart`
- Modify: `app/lib/features/workout/workout_screen.dart`
- Modify: `app/lib/features/workout/workout_complete_screen.dart`
- Modify: `app/lib/features/tests/custom_test_builder_screen.dart`
- Test: `app/test/features/workout/daily_workout_test.dart`

**Interfaces:**
- Consumes: `selectWorkout`, `pickWorkoutConcepts`, `WorkoutKind` (Task 5), `dailyProvider` and `DailyNotifier.clock` (Task 6).
- Produces: `Future<void> showProSheet(BuildContext, WidgetRef, {required String title, required String body})`, `void startKeepGoing(BuildContext, WidgetRef, {bool replace = false})` and `WorkoutCompleteScreen({required List<WorkoutResultItem> items, WorkoutKind kind = WorkoutKind.practice})`.

- [ ] **Step 1: Write the failing test**

`app/test/features/workout/daily_workout_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/daily_state.dart';
import 'package:study_gym/features/workout/workout_complete_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';
import 'package:study_gym/features/workout/workout_selector.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

final today = DateTime(2026, 9, 28, 10);

double _progress(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(
        find.descendant(of: find.byType(AppBar), matching: find.byType(LinearProgressIndicator)))
    .value!;

Future<ProviderContainer> _startDaily(WidgetTester tester, {bool pro = false}) async {
  final container = ProviderContainer(overrides: [
    studentProvider.overrideWith(() => SeededStudent(StudentState(isPro: pro))),
  ]);
  addTearDown(container.dispose);
  await pumpScreen(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => WorkoutScreen(
              concepts: [Content.conceptById('c.ap'), Content.conceptById('c.gp')],
              kind: WorkoutKind.daily,
            ),
          )),
          child: const Text('start'),
        ),
      ),
    ),
    container: container,
  );
  await tester.tap(find.text('start'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    loadSlice1Content();
    DailyNotifier.clock = () => today;
  });
  tearDown(() => DailyNotifier.clock = DateTime.now);

  testWidgets('the daily workout has 5 questions and is saved when finished', (tester) async {
    final container = await _startDaily(tester);
    expect(_progress(tester), closeTo(0.2, 1e-9), reason: 'question 1 of 5');

    await answerQuestions(tester, 5);

    expect(find.byType(WorkoutCompleteScreen), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);
    expect(find.text('Keep going'), findsOneWidget);
    final daily = container.read(dailyProvider);
    expect(daily.workoutDoneOn(today), isTrue);
    expect(daily.firstWorkoutOn(today)!.total, 5);
    expect(daily.servedQuestionIds, hasLength(5));
  });

  testWidgets('free users get the Pro sheet for Keep going', (tester) async {
    await _startDaily(tester);
    await answerQuestions(tester, 5);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('Keep going is a Pro feature'), findsOneWidget);
    expect(find.byType(WorkoutScreen), findsNothing);
  });

  testWidgets('Pro users get 5 more, unseen questions; the daily workout stays done', (tester) async {
    final container = await _startDaily(tester, pro: true);
    await answerQuestions(tester, 5);
    final served = container.read(dailyProvider).servedQuestionIds;

    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(_progress(tester), closeTo(0.2, 1e-9), reason: 'question 1 of 5 again');
    for (final id in served) {
      expect(find.textContaining('Stem $id', findRichText: true), findsNothing, reason: '$id was already served');
    }

    await answerQuestions(tester, 5);
    final daily = container.read(dailyProvider);
    expect(daily.workouts, hasLength(2));
    expect(daily.workouts.last.keepGoing, isTrue);
    expect(daily.streakOn(today), 1, reason: 'Keep going never adds a second day');
  });

  testWidgets('a practice run is not saved as a workout and offers no Keep going', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await pumpScreen(tester, WorkoutScreen(concepts: [Content.conceptById('c.ap')]), container: container);
    // Practice keeps 10 questions: c.ap's 6, widened to its chapter for 4 more.
    await answerQuestions(tester, 10);
    expect(find.byType(WorkoutCompleteScreen), findsOneWidget);
    expect(find.text('Keep going'), findsNothing);
    expect(container.read(dailyProvider).workouts, isEmpty);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/features/workout/daily_workout_test.dart`
Expected: FAIL (`'5 / 5'` and `'Keep going'` not found, no workout recorded).

- [ ] **Step 3: Extract the Pro sheet**

`app/lib/shared/widgets/pro_sheet.dart`: move `_UpgradeSheet` out of `custom_test_builder_screen.dart`, renamed `ProSheet` and taking `title` and `body`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import 'chunky_button.dart';

/// The sheet a Pro lock opens: it explains that one feature (spec: "A lock
/// opens a Pro sheet that explains that one feature"). "Upgrade" is still
/// the demo toggle; there are no payments.
Future<void> showProSheet(BuildContext context, WidgetRef ref, {required String title, required String body}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ProSheet(
      title: title,
      body: body,
      onUpgrade: () {
        ref.read(studentProvider.notifier).togglePro();
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class ProSheet extends StatelessWidget {
  const ProSheet({super.key, required this.title, required this.body, required this.onUpgrade});
  final String title;
  final String body;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
          ),
          const SizedBox(height: AppTheme.space20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: colors.brandLight, shape: BoxShape.circle),
            child: Icon(Icons.workspace_premium_rounded, color: colors.brand, size: 32),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.space8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
          ),
          const SizedBox(height: AppTheme.space24),
          ChunkyButton(label: 'Upgrade to Pro (demo)', onPressed: onUpgrade),
          const SizedBox(height: AppTheme.space12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Not now', style: TextStyle(color: colors.inkFaint, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
```

In `custom_test_builder_screen.dart`, delete the `_UpgradeSheet` class, add `import '../../shared/widgets/pro_sheet.dart';`, and replace the body of `_showUpgradeSheet()` with:

```dart
    showProSheet(
      context,
      ref,
      title: 'Custom tests are a Pro feature',
      body: 'Build unlimited tests from any chapter, whenever you want to check yourself.',
    );
```

- [ ] **Step 4: Add Keep going**

`app/lib/features/workout/keep_going.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_state.dart';
import '../../data/daily_state.dart';
import '../../shared/widgets/pro_sheet.dart';
import 'workout_screen.dart';
import 'workout_selector.dart';

/// Keep going: five more questions from the same selector, leaving out what
/// was already served. Pro only (spec: "Free users get one workout a day;
/// Keep going is Pro").
void startKeepGoing(BuildContext context, WidgetRef ref, {bool replace = false}) {
  final student = ref.read(studentProvider);
  if (!student.isPro) {
    showProSheet(
      context,
      ref,
      title: 'Keep going is a Pro feature',
      body: 'Free accounts get one daily workout. Pro adds as many five-question rounds as you like.',
    );
    return;
  }
  final route = MaterialPageRoute<void>(
    builder: (_) => WorkoutScreen(
      concepts: pickWorkoutConcepts(student),
      kind: WorkoutKind.keepGoing,
      exclude: ref.read(dailyProvider).servedQuestionIds,
    ),
  );
  final navigator = Navigator.of(context);
  replace ? navigator.pushReplacement(route) : navigator.push(route);
}
```

- [ ] **Step 5: Record the workout when it ends**

In `app/lib/features/workout/workout_screen.dart`:

1. Add `import '../../data/daily_state.dart';`.
2. In `_WorkoutScreenState`, add the field `final DateTime _startedAt = DailyNotifier.clock();`.
3. Replace the `if (_index == _items.length - 1) { ... }` branch of `_next()` (the `pushReplacement` to `WorkoutCompleteScreen`) with:

```dart
    if (_index == _items.length - 1) {
      final results = _items
          .map((i) => WorkoutResultItem(
                concept: Content.conceptById(i.question.conceptId),
                // The score reflects the first attempt, exam-style — a
                // later retry is practice and doesn't inflate it.
                correct: i.firstAttemptCorrect ?? false,
              ))
          .toList();
      if (widget.kind != WorkoutKind.practice) {
        ref.read(dailyProvider.notifier).recordWorkout(
              questionIds: _items.map((i) => i.question.id).toList(),
              correct: results.where((r) => r.correct).length,
              total: results.length,
              keepGoing: widget.kind == WorkoutKind.keepGoing,
              startedAt: _startedAt,
            );
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WorkoutCompleteScreen(items: results, kind: widget.kind)),
      );
    } else {
```

(leave the existing `else { setState(...) }` as it is).

- [ ] **Step 6: Show score and Keep going on the done screen**

In `app/lib/features/workout/workout_complete_screen.dart`:

1. Add `import 'keep_going.dart';` and `import 'workout_selector.dart';`.
2. The constructor becomes `const WorkoutCompleteScreen({super.key, required this.items, this.kind = WorkoutKind.practice});`, with a new field `final WorkoutKind kind;`.
3. Change the score text from `'$correctCount/$total'` to `'$correctCount / $total'`.
4. Directly before the `ChunkyButton(label: 'Done', ...)`, add:

```dart
                  if (widget.kind != WorkoutKind.practice) ...[
                    ChunkyButton(
                      label: 'Keep going',
                      icon: Icons.bolt_rounded,
                      onPressed: () => startKeepGoing(context, ref, replace: true),
                    ),
                    const SizedBox(height: AppTheme.space12),
                  ],
```

- [ ] **Step 7: Run the tests**

Run: `cd app && flutter test`
Expected: all pass, including `flow_smoke_test.dart`'s custom-test Pro lock check.

- [ ] **Step 8: Commit**

```bash
git add app/lib app/test
git commit -m "feat(app): save daily workouts, 5-question Keep going for Pro, shared Pro sheet"
```

---

### Task 8: Fading topics (read-only decay)

**Files:**
- Create: `app/lib/data/fading.dart`
- Modify: `app/lib/data/models.dart` (`ConceptMastery`)
- Modify: `app/lib/data/student_repository.dart`
- Modify: `app/lib/data/app_state.dart` (`recordAttempt`)
- Test: `app/test/data/fading_test.dart`

**Interfaces:**
- Produces: `ConceptMastery.lastPracticed` (`DateTime?`), `ConceptMastery.halfLifeDays` (`double`, default 2), `double effectiveMastery(ConceptMastery, DateTime now)`, `bool isFading(ConceptMastery, DateTime now)`, `List<Concept> fadingConcepts(StudentState, DateTime now)`.

- [ ] **Step 1: Write the failing test**

`app/test/data/fading_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/fading.dart';
import 'package:study_gym/data/models.dart';

import '../fixtures/slice1_content.dart';

final now = DateTime(2026, 9, 28, 10);

ConceptMastery _m(String id, double percent, {int? daysAgo, double halfLife = 2}) => ConceptMastery(
      conceptId: id,
      masteryPercent: percent,
      attempts: 5,
      lastPracticed: daysAgo == null ? null : now.subtract(Duration(days: daysAgo)),
      halfLifeDays: halfLife,
    );

void main() {
  setUp(loadSlice1Content);

  test('effective mastery halves every half-life', () {
    expect(effectiveMastery(_m('c.ap', 80, daysAgo: 2), now), closeTo(40, 1e-6));
    expect(effectiveMastery(_m('c.ap', 80, daysAgo: 0), now), 80);
    expect(effectiveMastery(_m('c.ap', 80), now), 80, reason: 'never practised: no decay');
  });

  test('fading = was mastered (>= 80%) and has decayed below 70%', () {
    expect(isFading(_m('c.ap', 90, daysAgo: 1), now), isTrue); // 63.6
    expect(isFading(_m('c.ap', 90, daysAgo: 0), now), isFalse);
    expect(isFading(_m('c.ap', 60, daysAgo: 30), now), isFalse, reason: 'never mastered');
    expect(isFading(_m('c.ap', 90, daysAgo: 1, halfLife: 60), now), isFalse);
  });

  test('fadingConcepts lists only known, fading concepts', () {
    final student = StudentState(mastery: {
      'c.ap': _m('c.ap', 90, daysAgo: 5),
      'c.gp': _m('c.gp', 90, daysAgo: 0),
      'gone': _m('gone', 90, daysAgo: 5),
    });
    expect(fadingConcepts(student, now).map((c) => c.id), ['c.ap']);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/data/fading_test.dart`
Expected: compile error (`lastPracticed`, `fading.dart`).

- [ ] **Step 3: Implement**

In `models.dart`, `ConceptMastery` gains two constructor parameters, `this.lastPracticed,` and `this.halfLifeDays = 2,`, and two fields:

```dart
  /// When this concept was last practised (`concept_mastery.last_practiced`).
  DateTime? lastPracticed;

  /// Retention half-life in days (PLAN.md §5.1; starts at 2).
  double halfLifeDays;
```

In `student_repository.dart`, `fetchAll` selects `'concept_id, theta, attempts, correct, last_practiced, half_life_days'` and passes:

```dart
        lastPracticed: row['last_practiced'] == null ? null : DateTime.parse(row['last_practiced'] as String).toLocal(),
        halfLifeDays: (row['half_life_days'] as num?)?.toDouble() ?? 2,
```

In `app_state.dart` `recordAttempt`, the `updated` mastery also sets `lastPracticed: DateTime.now(), halfLifeDays: current.halfLifeDays,`.

`app/lib/data/fading.dart`:

```dart
import 'dart:math' as math;

import 'app_state.dart';
import 'content.dart';
import 'models.dart';

/// Retention decay from docs/PLAN.md §5.1:
/// effective mastery = mastery × 2^(−days since last practice / half-life).
double effectiveMastery(ConceptMastery m, DateTime now) {
  final last = m.lastPracticed;
  if (last == null) return m.masteryPercent;
  final days = now.difference(last).inMinutes / (60 * 24);
  if (days <= 0) return m.masteryPercent;
  final halfLife = m.halfLifeDays <= 0 ? 2.0 : m.halfLifeDays;
  return m.masteryPercent * math.pow(2, -days / halfLife);
}

/// PLAN.md §5.1's Fading: a mastered concept whose effective mastery has
/// dropped below 70%. Read-only and simplified: "mastered" is the stored
/// percent (≥ 80). The "on 2 days at least 3 days apart" rule and half-life
/// growth come with the full mastery engine.
bool isFading(ConceptMastery m, DateTime now) => m.masteryPercent >= 80 && effectiveMastery(m, now) < 70;

List<Concept> fadingConcepts(StudentState student, DateTime now) => student.mastery.values
    .where((m) => isFading(m, now))
    .map((m) => Content.conceptOrNull(m.conceptId))
    .whereType<Concept>()
    .toList();
```

- [ ] **Step 4: Run the tests**

Run: `cd app && flutter test test/data`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add app/lib/data app/test/data/fading_test.dart
git commit -m "feat(app): read-only fading from last practice and half-life"
```

---

### Task 9: Topic-node progress and the derived chapter/course progress

The heart of the slice: one pure module turns content plus the progress stores into what the chapter screen, Learn and Home show.

**Files:**
- Create: `app/lib/data/node_progress_repository.dart`
- Create: `app/lib/data/node_progress_state.dart`
- Create: `app/lib/data/chapter_progress.dart`
- Modify: `app/lib/main.dart`
- Test: `app/test/data/node_progress_state_test.dart`
- Test: `app/test/data/chapter_progress_test.dart`

**Interfaces:**
- Produces: `NodeProgressState({Map<String, Set<TopicNode>> passed})` with `isPassed(String conceptId, TopicNode)`, `NodeProgressNotifier` with `static NodeProgressRepository? repositoryOverride` and `void passNode(String conceptId, TopicNode node)`, `nodeProgressProvider`, `NodeProgressRepository(fetchAll, passNode)`.
- Produces (`chapter_progress.dart`):
  - `enum TopicStatus { done, current, locked }`, `enum NodeStatus { passed, open, locked, comingSoon }`, `enum ChapterStatus { soon, notStarted, inProgress, complete }`
  - `NodeSlot { TopicNode node; int questionCount; NodeStatus status; }`
  - `TopicProgress { Concept concept; Lesson? lesson; bool lessonRead; List<NodeSlot> nodes; bool usesInterimRule; TopicStatus status; bool isDone; int nodeCount; int nodesPassed; }`
  - `sealed class NextStep` with `LessonStep(Lesson lesson, int topicNumber)`, `NodeStep(Concept concept, TopicNode node, int topicNumber)`, `TrialLevelStep(Question level, int number, int total)` and `OpenChapterStep()`
  - `ChapterProgress` with `chapter`, `topics`, `trialLevels`, `levelsCleared`, `hasContent`, `topicsDone`, `allTopicsDone`, `trialUnlocked`, `currentTopicNumber`, `status`, `isStarted`, `fraction` and `nextStep`
  - `ChapterProgress chapterProgress(Chapter, {required TheoryProgressState theory, required NodeProgressState nodes, required LevelProgressState levels})`
  - `CourseProgress` with `chapters`, `chapter(String id)`, `chaptersStarted`, `levelsCleared`, `anyStarted`, `fraction`, `current` and `summary`
  - `CourseProgress courseProgress({...same three...})`, `final courseProgressProvider = Provider<CourseProgress>`

- [ ] **Step 1: Write the failing tests**

`app/test/data/node_progress_state_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/node_progress_repository.dart';
import 'package:study_gym/data/node_progress_state.dart';

class FakeNodeRepo implements NodeProgressRepository {
  FakeNodeRepo([this.initial = const {}]);
  final Map<String, Set<TopicNode>> initial;
  final writes = <String>[];

  @override
  Future<Map<String, Set<TopicNode>>> fetchAll() async => initial;

  @override
  Future<void> passNode(String conceptId, TopicNode node) async => writes.add('$conceptId/${node.dbValue}');
}

void main() {
  tearDown(() => NodeProgressNotifier.repositoryOverride = null);

  test('passing a node is remembered and saved once', () async {
    final repo = FakeNodeRepo();
    NodeProgressNotifier.repositoryOverride = repo;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(nodeProgressProvider);
    await Future<void>.delayed(Duration.zero);

    c.read(nodeProgressProvider.notifier).passNode('c.iden', TopicNode.guided);
    c.read(nodeProgressProvider.notifier).passNode('c.iden', TopicNode.guided);

    expect(c.read(nodeProgressProvider).isPassed('c.iden', TopicNode.guided), isTrue);
    expect(c.read(nodeProgressProvider).isPassed('c.iden', TopicNode.challenge), isFalse);
    expect(repo.writes, ['c.iden/guided']);
  });

  test('hydrates saved passes', () async {
    NodeProgressNotifier.repositoryOverride = FakeNodeRepo({
      'c.iden': {TopicNode.challenge},
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(nodeProgressProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(nodeProgressProvider).isPassed('c.iden', TopicNode.challenge), isTrue);
  });
}
```

`app/test/data/chapter_progress_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/chapter_progress.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/node_progress_state.dart';
import 'package:study_gym/data/theory_state.dart';

import '../fixtures/slice1_content.dart';

CourseProgress _course({
  Set<String> read = const {},
  Map<String, Set<TopicNode>> passed = const {},
  Map<String, Set<int>> levels = const {},
}) =>
    courseProgress(
      theory: TheoryProgressState(readLessonIds: read),
      nodes: NodeProgressState(passed: passed),
      levels: LevelProgressState(completedLevels: levels),
    );

ChapterProgress _ch(String id, {Set<String> read = const {}, Map<String, Set<TopicNode>> passed = const {}, Map<String, Set<int>> levels = const {}}) =>
    _course(read: read, passed: passed, levels: levels).chapter(id)!;

List<TopicStatus> _statuses(ChapterProgress p) => p.topics.map((t) => t.status).toList();

void main() {
  setUp(loadSlice1Content);

  group('topics', () {
    test('topics come in syllabus order; the first is current, the rest locked', () {
      final p = _ch(savChapter);
      expect(p.topics.map((t) => t.concept.id), ['c.cube', 'c.cyl', 'c.cone']);
      expect(_statuses(p), [TopicStatus.current, TopicStatus.locked, TopicStatus.locked]);
    });

    test('interim rule: a topic with no topic questions is finished when its lesson is read', () {
      final p = _ch(savChapter, read: {'t_cube'});
      expect(p.topics.first.usesInterimRule, isTrue);
      expect(_statuses(p), [TopicStatus.done, TopicStatus.current, TopicStatus.locked]);
      expect(p.topics.first.nodes.every((n) => n.status == NodeStatus.comingSoon), isTrue);
    });

    test('a topic with topic questions does NOT finish on lesson read', () {
      final p = _ch(idenChapter, read: {'t_iden'});
      final t = p.topics.single;
      expect(t.usesInterimRule, isFalse);
      expect(t.status, TopicStatus.current);
    });

    test('question nodes open one after another; nodes without questions are skipped', () {
      NodeStatus s(ChapterProgress p, TopicNode n) => p.topics.single.nodes.firstWhere((x) => x.node == n).status;

      var p = _ch(idenChapter);
      expect(s(p, TopicNode.guided), NodeStatus.locked, reason: 'Learn comes first');

      p = _ch(idenChapter, read: {'t_iden'});
      expect(s(p, TopicNode.guided), NodeStatus.open);
      expect(s(p, TopicNode.practice), NodeStatus.comingSoon);
      expect(s(p, TopicNode.spotTheMistake), NodeStatus.comingSoon);
      expect(s(p, TopicNode.challenge), NodeStatus.locked);

      p = _ch(idenChapter, read: {'t_iden'}, passed: {'c.iden': {TopicNode.guided}});
      expect(s(p, TopicNode.challenge), NodeStatus.open);

      p = _ch(idenChapter, read: {'t_iden'}, passed: {'c.iden': {TopicNode.guided, TopicNode.challenge}});
      expect(p.topics.single.status, TopicStatus.done);
      expect(p.topics.single.nodesPassed, 2);
      expect(p.topics.single.nodeCount, 2);
    });

    test('lessons read out of order never make two current topics', () {
      final p = _ch(savChapter, read: {'t_cyl'});
      expect(_statuses(p), [TopicStatus.current, TopicStatus.done, TopicStatus.locked]);
    });
  });

  group('Trial gate', () {
    test('stays locked while any topic is unfinished', () {
      expect(_ch(savChapter, read: {'t_cube', 't_cyl'}).trialUnlocked, isFalse);
    });

    test('opens when every seal is broken', () {
      expect(_ch(savChapter, read: {'t_cube', 't_cyl', 't_cone'}).trialUnlocked, isTrue);
    });

    test('old Mission progress is kept behind a locked gate', () {
      final course = _course(levels: {savChapter: {1, 2, 3}});
      final p = course.chapter(savChapter)!;
      expect(p.trialUnlocked, isFalse);
      expect(p.levelsCleared, 3);
      expect(p.status, ChapterStatus.inProgress);
      expect(course.levelsCleared, 3);
    });
  });

  group('chapter status and fraction', () {
    test('soon, not started, in progress, complete', () {
      expect(_ch(triChapter).status, ChapterStatus.soon);
      expect(_ch(seqChapter).status, ChapterStatus.notStarted);
      expect(_ch(savChapter, read: {'t_cube'}).status, ChapterStatus.inProgress);
      final all = {for (var l = 1; l <= 10; l++) l};
      expect(_ch(savChapter, read: {'t_cube', 't_cyl', 't_cone'}, levels: {savChapter: all}).status, ChapterStatus.complete);
    });

    test('topics and the Trial count half each', () {
      final p = _ch(savChapter, read: {'t_cube', 't_cyl', 't_cone'}, levels: {savChapter: {1, 2, 3, 4, 5}});
      expect(p.fraction, closeTo(0.5 + 0.25, 1e-9));
    });
  });

  group('next step', () {
    test('the current topic\'s lesson, then its first open node', () {
      var step = _ch(savChapter, read: {'t_cube'}).nextStep;
      expect(step, isA<LessonStep>());
      expect((step as LessonStep).lesson.id, 't_cyl');
      expect(step.topicNumber, 2);

      step = _ch(idenChapter, read: {'t_iden'}).nextStep;
      expect(step, isA<NodeStep>());
      expect((step as NodeStep).node, TopicNode.guided);
    });

    test('after every topic, the next unlocked Trial level', () {
      final step = _ch(savChapter, read: {'t_cube', 't_cyl', 't_cone'}, levels: {savChapter: {1, 2}}).nextStep;
      expect(step, isA<TrialLevelStep>());
      step as TrialLevelStep;
      expect(step.level.level, 3);
      expect(step.number, 3);
      expect(step.total, 10);
    });

    test('a topic with no lesson and no questions falls back to opening the chapter', () {
      expect(_ch(seqChapter).nextStep, isA<OpenChapterStep>());
    });
  });

  group('course', () {
    test('summary line counts started chapters and cleared levels', () {
      final course = _course(read: {'t_cube'}, levels: {savChapter: {1}});
      expect(course.chaptersStarted, 1);
      expect(course.summary, '1 of 4 chapters started · 1 level cleared');
    });

    test('current chapter: first in progress, else the first that can start', () {
      expect(_course().current!.chapter.id, seqChapter);
      expect(_course(read: {'t_cube'}).current!.chapter.id, savChapter);
    });
  });
}
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `cd app && flutter test test/data/node_progress_state_test.dart test/data/chapter_progress_test.dart`
Expected: compile errors (files don't exist).

- [ ] **Step 3: Implement node progress**

`app/lib/data/node_progress_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Reads/writes `node_progress` (20261001000000_units_nodes_trial_meta.sql).
class NodeProgressRepository {
  NodeProgressRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No signed-in user — cannot read/write node progress.');
    return id;
  }

  Future<Map<String, Set<TopicNode>>> fetchAll() async {
    final rows = await _client.from('node_progress').select('concept_id, node').eq('user_id', _userId);
    final result = <String, Set<TopicNode>>{};
    for (final row in rows as List) {
      final node = TopicNode.fromDb(row['node']);
      if (node == null) continue;
      result.putIfAbsent(row['concept_id'] as String, () => {}).add(node);
    }
    return result;
  }

  Future<void> passNode(String conceptId, TopicNode node) async {
    await _client.from('node_progress').upsert({'user_id': _userId, 'concept_id': conceptId, 'node': node.dbValue});
  }
}
```

`app/lib/data/node_progress_state.dart`:

```dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'node_progress_repository.dart';

/// Which topic question nodes the student has passed.
class NodeProgressState {
  const NodeProgressState({this.passed = const {}});

  /// Concept id → the nodes passed in that topic.
  final Map<String, Set<TopicNode>> passed;

  bool isPassed(String conceptId, TopicNode node) => passed[conceptId]?.contains(node) ?? false;
}

class NodeProgressNotifier extends Notifier<NodeProgressState> {
  /// Set by main.dart; null in tests that don't need persistence.
  static NodeProgressRepository? repositoryOverride;

  NodeProgressRepository? get _repo => repositoryOverride;

  @override
  NodeProgressState build() {
    if (_repo != null) _hydrate();
    return const NodeProgressState();
  }

  Future<void> _hydrate() async {
    try {
      final fetched = await _repo!.fetchAll();
      // Merge, don't replace: a node passed while this fetch was in flight
      // must stay passed.
      final merged = {for (final e in fetched.entries) e.key: {...e.value}};
      for (final e in state.passed.entries) {
        merged.putIfAbsent(e.key, () => {}).addAll(e.value);
      }
      state = NodeProgressState(passed: merged);
    } catch (e) {
      // Also covers a database without node_progress yet.
      debugPrint('Could not load node progress: $e');
    }
  }

  void passNode(String conceptId, TopicNode node) {
    if (state.isPassed(conceptId, node)) return;
    state = NodeProgressState(passed: {
      ...state.passed,
      conceptId: {...?state.passed[conceptId], node},
    });
    _repo?.passNode(conceptId, node).catchError((Object e) => debugPrint('Could not save node progress: $e'));
  }
}

final nodeProgressProvider = NotifierProvider<NodeProgressNotifier, NodeProgressState>(NodeProgressNotifier.new);
```

In `main.dart`, add the imports and `NodeProgressNotifier.repositoryOverride = NodeProgressRepository(Supabase.instance.client);` after the `DailyNotifier` line.

- [ ] **Step 4: Implement the derived progress**

`app/lib/data/chapter_progress.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content.dart';
import 'mission_state.dart';
import 'models.dart';
import 'node_progress_state.dart';
import 'theory_state.dart';

// Everything here is derived from Content and the progress stores, never
// stored (spec: "Avoid storing derived progress redundantly").

enum TopicStatus { done, current, locked }

enum NodeStatus { passed, open, locked, comingSoon }

enum ChapterStatus { soon, notStarted, inProgress, complete }

class NodeSlot {
  const NodeSlot({required this.node, required this.questionCount, required this.status});
  final TopicNode node;
  final int questionCount;
  final NodeStatus status;
}

class TopicProgress {
  const TopicProgress({
    required this.concept,
    required this.lesson,
    required this.lessonRead,
    required this.nodes,
    required this.usesInterimRule,
    required this.status,
  });

  final Concept concept;

  /// The Learn node's lesson; null shows "Lesson coming soon".
  final Lesson? lesson;
  final bool lessonRead;

  /// Always the four question nodes in path order. Nodes without questions
  /// are [NodeStatus.comingSoon] and never gate the next node.
  final List<NodeSlot> nodes;

  /// No topic questions yet, so the topic is finished once its lesson is
  /// read. Switches off by itself when tagged questions arrive.
  final bool usesInterimRule;
  final TopicStatus status;

  bool get isDone => status == TopicStatus.done;

  /// Question nodes that have questions.
  int get nodeCount => nodes.where((n) => n.questionCount > 0).length;
  int get nodesPassed => nodes.where((n) => n.status == NodeStatus.passed).length;
}

/// Where Home's Continue goes.
sealed class NextStep {
  const NextStep();
}

class LessonStep extends NextStep {
  const LessonStep(this.lesson, this.topicNumber);
  final Lesson lesson;
  final int topicNumber;
}

class NodeStep extends NextStep {
  const NodeStep(this.concept, this.node, this.topicNumber);
  final Concept concept;
  final TopicNode node;
  final int topicNumber;
}

class TrialLevelStep extends NextStep {
  const TrialLevelStep(this.level, this.number, this.total);
  final Question level;

  /// 1-based position among the loaded levels, and how many loaded.
  final int number;
  final int total;
}

/// Nothing more specific can be opened (e.g. a topic with no lesson yet).
class OpenChapterStep extends NextStep {
  const OpenChapterStep();
}

class ChapterProgress {
  const ChapterProgress({
    required this.chapter,
    required this.topics,
    required this.trialLevels,
    required this.levelsCleared,
    required this.hasContent,
    required this.levels,
  });

  final Chapter chapter;
  final List<TopicProgress> topics;

  /// The Chapter Trial's levels as loaded (live only: possibly fewer than 62).
  final List<Question> trialLevels;
  final int levelsCleared;
  final bool hasContent;
  final LevelProgressState levels;

  int get topicsDone => topics.where((t) => t.isDone).length;
  bool get allTopicsDone => topics.isNotEmpty && topics.every((t) => t.isDone);

  /// The gate opens only when every topic's seal is broken.
  bool get trialUnlocked => trialLevels.isNotEmpty && allTopicsDone;

  int? get currentTopicNumber {
    final i = topics.indexWhere((t) => t.status == TopicStatus.current);
    return i < 0 ? null : i + 1;
  }

  ChapterStatus get status {
    if (!hasContent) return ChapterStatus.soon;
    final trialDone = trialLevels.isEmpty || levelsCleared == trialLevels.length;
    if (allTopicsDone && trialDone) return ChapterStatus.complete;
    final started = levelsCleared > 0 || topics.any((t) => t.isDone || t.lessonRead || t.nodesPassed > 0);
    return started ? ChapterStatus.inProgress : ChapterStatus.notStarted;
  }

  bool get isStarted => status == ChapterStatus.inProgress || status == ChapterStatus.complete;

  /// Topics and the Trial count half each when there is a Trial.
  double get fraction {
    if (topics.isEmpty) return 0;
    final topicPart = topicsDone / topics.length;
    if (trialLevels.isEmpty) return topicPart;
    return 0.5 * topicPart + 0.5 * levelsCleared / trialLevels.length;
  }

  NextStep get nextStep {
    final i = topics.indexWhere((t) => t.status == TopicStatus.current);
    if (i >= 0) {
      final t = topics[i];
      if (t.lesson != null && !t.lessonRead) return LessonStep(t.lesson!, i + 1);
      for (final slot in t.nodes) {
        if (slot.status == NodeStatus.open) return NodeStep(t.concept, slot.node, i + 1);
      }
      return const OpenChapterStep();
    }
    if (trialUnlocked) {
      for (var j = 0; j < trialLevels.length; j++) {
        final unlocked = levels.isUnlocked(chapter.id, previousLevelInList: j == 0 ? null : trialLevels[j - 1].level);
        if (unlocked && !levels.isCompleted(chapter.id, trialLevels[j].level!)) {
          return TrialLevelStep(trialLevels[j], j + 1, trialLevels.length);
        }
      }
    }
    return const OpenChapterStep();
  }
}

ChapterProgress chapterProgress(
  Chapter chapter, {
  required TheoryProgressState theory,
  required NodeProgressState nodes,
  required LevelProgressState levels,
}) {
  final topics = <TopicProgress>[];
  var allBeforeDone = true;
  for (final concept in chapter.concepts) {
    final lesson = Content.lessonForConcept(concept.id);
    final lessonRead = lesson != null && theory.isRead(lesson.id);
    final interim = !Content.hasTopicQuestions(concept.id);
    final unlocked = allBeforeDone;

    final slots = <NodeSlot>[];
    // The Learn node gates the first question node; with no lesson there
    // is nothing to wait for.
    var previousPassed = lesson == null || lessonRead;
    for (final node in TopicNode.values) {
      final count = interim ? 0 : Content.nodeQuestions(concept.id, node).length;
      final NodeStatus status;
      if (count == 0) {
        status = NodeStatus.comingSoon;
      } else if (nodes.isPassed(concept.id, node)) {
        status = NodeStatus.passed;
      } else if (unlocked && previousPassed) {
        status = NodeStatus.open;
      } else {
        status = NodeStatus.locked;
      }
      if (count > 0) previousPassed = status == NodeStatus.passed;
      slots.add(NodeSlot(node: node, questionCount: count, status: status));
    }

    final finished = interim
        ? lessonRead
        : (lesson == null || lessonRead) &&
            slots.where((s) => s.questionCount > 0).every((s) => s.status == NodeStatus.passed);
    topics.add(TopicProgress(
      concept: concept,
      lesson: lesson,
      lessonRead: lessonRead,
      nodes: slots,
      usesInterimRule: interim,
      status: finished ? TopicStatus.done : (unlocked ? TopicStatus.current : TopicStatus.locked),
    ));
    allBeforeDone = allBeforeDone && finished;
  }

  final trialLevels = Content.trialLevels(chapter.id);
  return ChapterProgress(
    chapter: chapter,
    topics: topics,
    trialLevels: trialLevels,
    levelsCleared: trialLevels.where((q) => levels.isCompleted(chapter.id, q.level!)).length,
    hasContent: Content.hasContent(chapter.id),
    levels: levels,
  );
}

class CourseProgress {
  const CourseProgress(this.chapters);

  /// Every chapter of the active course, in syllabus order.
  final List<ChapterProgress> chapters;

  ChapterProgress? chapter(String id) {
    for (final c in chapters) {
      if (c.chapter.id == id) return c;
    }
    return null;
  }

  int get chaptersStarted => chapters.where((c) => c.isStarted).length;
  int get levelsCleared => chapters.fold(0, (sum, c) => sum + c.levelsCleared);
  bool get anyStarted => chaptersStarted > 0;
  double get fraction => chapters.isEmpty ? 0 : chapters.fold<double>(0, (s, c) => s + c.fraction) / chapters.length;

  /// Pinned on Learn and continued from Home: the first chapter in
  /// progress, else the first one that can start. Null when nothing has content.
  ChapterProgress? get current =>
      chapters.where((c) => c.status == ChapterStatus.inProgress).firstOrNull ??
      chapters.where((c) => c.status == ChapterStatus.notStarted).firstOrNull;

  /// "1 of 15 chapters started · 13 levels cleared"
  String get summary {
    final n = levelsCleared;
    return '$chaptersStarted of ${chapters.length} chapters started · $n ${n == 1 ? 'level' : 'levels'} cleared';
  }
}

CourseProgress courseProgress({
  required TheoryProgressState theory,
  required NodeProgressState nodes,
  required LevelProgressState levels,
}) =>
    CourseProgress([
      for (final c in Content.chapters) chapterProgress(c, theory: theory, nodes: nodes, levels: levels),
    ]);

final courseProgressProvider = Provider<CourseProgress>((ref) => courseProgress(
      theory: ref.watch(theoryProgressProvider),
      nodes: ref.watch(nodeProgressProvider),
      levels: ref.watch(levelProgressProvider),
    ));
```

- [ ] **Step 5: Run the tests**

Run: `cd app && flutter test test/data`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add app/lib app/test/data
git commit -m "feat(app): topic-node progress and derived chapter/course progress with the interim rule"
```

---

### Task 10: Topic node sessions in the player

**Files:**
- Modify: `app/lib/features/workout/workout_screen.dart`
- Test: `app/test/features/workout/node_session_test.dart`

**Interfaces:**
- Consumes: `Content.nodeQuestions`, `TopicNode` (Task 3), `nodeProgressProvider` (Task 9).
- Produces: `WorkoutScreen.node({required Concept concept, required TopicNode node})`, which pops with `true` once the node is passed.

- [ ] **Step 1: Write the failing test**

`app/test/features/workout/node_session_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/node_progress_state.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

Future<ProviderContainer> _openGuided(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await pumpScreen(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => WorkoutScreen.node(concept: Content.conceptById('c.iden'), node: TopicNode.guided),
          )),
          child: const Text('open'),
        ),
      ),
    ),
    container: container,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(loadSlice1Content);

  testWidgets('a wrong answer comes back at the end; the node passes once all are right', (tester) async {
    final container = await _openGuided(tester);

    expect(find.textContaining('q_iden_g1', findRichText: true), findsOneWidget);
    await tester.tap(find.text('wrong').first);
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsNothing, reason: 'node sessions requeue instead');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('q_iden_g2', findRichText: true), findsOneWidget);
    await answerQuestions(tester, 1);
    expect(container.read(nodeProgressProvider).isPassed('c.iden', TopicNode.guided), isFalse);

    expect(find.textContaining('q_iden_g1', findRichText: true), findsOneWidget, reason: 'g1 returns');
    await answerQuestions(tester, 1);

    expect(find.byType(WorkoutScreen), findsNothing);
    expect(container.read(nodeProgressProvider).isPassed('c.iden', TopicNode.guided), isTrue);
  });

  testWidgets('leaving part-way does not pass the node', (tester) async {
    final container = await _openGuided(tester);
    await answerQuestions(tester, 1);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(container.read(nodeProgressProvider).isPassed('c.iden', TopicNode.guided), isFalse);
  });

  testWidgets('a returning question is recorded in mastery only once', (tester) async {
    final container = await _openGuided(tester);
    await answerQuestions(tester, 1, answer: 'wrong');
    await answerQuestions(tester, 2);
    expect(container.read(studentProvider).mastery['c.iden']!.attempts, 2);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/features/workout/node_session_test.dart`
Expected: compile error (`WorkoutScreen.node` doesn't exist).

- [ ] **Step 3: Implement node sessions**

In `app/lib/features/workout/workout_screen.dart`:

1. Add `import '../../data/node_progress_state.dart';`.
2. Add `nodeConcept = null, node = null` to the initializer lists of the default and `.singleLevel` constructors. Then add:

```dart
  /// One node of a topic (Guided, Practice, Spot the mistake, Challenge).
  /// A wrong answer comes back at the end; the node is passed once every
  /// question has been answered right, and the screen pops with `true`.
  const WorkoutScreen.node({super.key, required Concept concept, required TopicNode this.node})
      : concepts = const [],
        kind = WorkoutKind.practice,
        exclude = const {},
        singleLevelQuestion = null,
        nodeConcept = concept;
```

and the fields:

```dart
  final Concept? nodeConcept;
  final TopicNode? node;
  bool get isNodeSession => node != null;
```

3. In `_buildWorkout`, after the single-level branch, add:

```dart
    final node = widget.node;
    if (node != null) {
      return Content.nodeQuestions(widget.nodeConcept!.id, node)
          .map((q) => _WorkoutItem(question: q, section: WorkoutSection.strength))
          .toList();
    }
```

4. In the state, add `final Set<String> _recordedQuestionIds = {};`. In `_submit`, change `if (isFirstAttempt) {` (the block that calls `recordAttempt` and `addXp`) to:

```dart
    // Only a question's first attempt ever counts, even when a node session
    // brings it back at the end.
    if (isFirstAttempt && _recordedQuestionIds.add(item.question.id)) {
```

5. In `_next`, directly after the single-level branch's `return;` and its closing `}`, add:

```dart
    final item = _current;
    if (widget.isNodeSession && !(item.wasCorrect ?? false)) {
      // A wrong question comes back at the end of the node.
      final again = _WorkoutItem(question: item.question, section: item.section);
      again.numericController.addListener(() => setState(() {}));
      for (final c in again.partNumericControllers.values) {
        c.addListener(() => setState(() {}));
      }
      _items.add(again);
    }
    if (widget.isNodeSession && _index == _items.length - 1) {
      ref.read(nodeProgressProvider.notifier).passNode(widget.nodeConcept!.id, widget.node!);
      Navigator.of(context).pop(true);
      return;
    }
```

6. `_BottomBar` gets a new field `final bool allowRetry;` (required in its constructor). Its retry condition becomes `if (!(item.wasCorrect ?? false) && !usedRetry && allowRetry) {`. Pass `allowRetry: !widget.isNodeSession` from `build`.
7. In the AppBar title, replace `_SectionBadge(section: item.section),` with:

```dart
            widget.node != null
                ? Text(widget.node!.label, style: Theme.of(context).textTheme.bodyMedium)
                : _SectionBadge(section: item.section),
```

- [ ] **Step 4: Run the tests**

Run: `cd app && flutter test test/features/workout`
Expected: all pass (new and existing).

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/workout/workout_screen.dart app/test/features/workout/node_session_test.dart
git commit -m "feat(app): topic node sessions — wrong answers return, node passes when all are right"
```

---

### Task 11: Trial level results, solution viewing and trophies

**Files:**
- Modify: `app/lib/data/mission_state.dart`
- Modify: `app/lib/data/level_progress_repository.dart`
- Modify: `app/lib/features/workout/workout_screen.dart`
- Create: `app/lib/data/trial_trophy.dart`
- Test: `app/test/data/level_progress_test.dart` (extend)
- Test: `app/test/data/trial_trophy_test.dart`
- Test: `app/test/features/workout/workout_screen_test.dart` (extend)

**Interfaces:**
- Produces: `class LevelResult { double score; bool solutionViewed; }`, `LevelProgressState.results` (`Map<String, Map<int, LevelResult>>`), `LevelProgressState.resultFor(String chapterId, int level) → LevelResult?`, `LevelProgressNotifier.completeLevel({required chapterId, required level, required score, bool solutionViewed = false})` where the first completion stands, `LevelProgressRepository.fetchAll() → Future<Map<String, Map<int, LevelResult>>>`, `enum TrialTrophy { none, gold, platinum }`, `TrialTrophy trialTrophy(String chapterId, List<Question> levels, LevelProgressState progress)`.

- [ ] **Step 1: Write the failing tests**

Append to `app/test/data/level_progress_test.dart` (inside `main`, and add `import 'package:flutter_riverpod/flutter_riverpod.dart';`):

```dart
  test('the first completion stands: a replay does not overwrite its result', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(levelProgressProvider.notifier);
    n.completeLevel(chapterId: ch, level: 1, score: 1, solutionViewed: false);
    n.completeLevel(chapterId: ch, level: 1, score: 0, solutionViewed: true);
    final r = c.read(levelProgressProvider).resultFor(ch, 1)!;
    expect(r.score, 1);
    expect(r.solutionViewed, isFalse);
  });
```

`app/test/data/trial_trophy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/trial_trophy.dart';

import '../fixtures/slice1_content.dart';

LevelProgressState _state(Map<int, LevelResult> results) => LevelProgressState(
      completedLevels: {savChapter: results.keys.toSet()},
      results: {savChapter: results},
    );

void main() {
  setUp(loadSlice1Content);

  test('no trophy until every loaded level is done', () {
    final levels = Content.trialLevels(savChapter);
    final nine = {for (var l = 1; l <= 9; l++) l: const LevelResult(score: 1)};
    expect(trialTrophy(savChapter, levels, _state(nine)), TrialTrophy.none);
  });

  test('Platinum: at least 90% right first time and no solutions viewed', () {
    final levels = Content.trialLevels(savChapter);
    final results = {for (var l = 1; l <= 10; l++) l: LevelResult(score: l == 10 ? 0 : 1)};
    expect(trialTrophy(savChapter, levels, _state(results)), TrialTrophy.platinum);
  });

  test('Gold when below 90% first time, or when a solution was viewed', () {
    final levels = Content.trialLevels(savChapter);
    final lowScore = {for (var l = 1; l <= 10; l++) l: LevelResult(score: l >= 9 ? 0 : 1)};
    expect(trialTrophy(savChapter, levels, _state(lowScore)), TrialTrophy.gold);
    final peeked = {for (var l = 1; l <= 10; l++) l: LevelResult(score: 1, solutionViewed: l == 3)};
    expect(trialTrophy(savChapter, levels, _state(peeked)), TrialTrophy.gold);
  });

  test('no Trial, no trophy', () {
    expect(trialTrophy(seqChapter, const [], const LevelProgressState()), TrialTrophy.none);
  });
}
```

Append to `app/test/features/workout/workout_screen_test.dart`, inside the `level completion` group:

```dart
    testWidgets('opening the solution is recorded on the level', (tester) async {
      final container = await pushLevel(tester, _mcqLevel());
      await tester.tap(find.text('right'));
      await submit(tester);
      await tapVisible(tester, find.text('Show solution'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      final r = container.read(levelProgressProvider).resultFor(_chapterId, 4)!;
      expect(r.score, 1);
      expect(r.solutionViewed, isTrue);
    });
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `cd app && flutter test test/data/level_progress_test.dart test/data/trial_trophy_test.dart test/features/workout/workout_screen_test.dart`
Expected: compile errors (`solutionViewed`, `resultFor`, `trial_trophy.dart`).

- [ ] **Step 3: Implement level results**

In `app/lib/data/mission_state.dart`:

1. Add above `LevelProgressState`:

```dart
/// One completed Trial level: right first time (score 1.0) or not, and
/// whether a solution was opened (both needed for Platinum).
class LevelResult {
  const LevelResult({required this.score, this.solutionViewed = false});
  final double score;
  final bool solutionViewed;
}
```

2. `LevelProgressState`'s constructor becomes `const LevelProgressState({this.completedLevels = const {}, this.results = const {}});`. Add:

```dart
  /// Per-level results, for trophies. The first completion stands.
  final Map<String, Map<int, LevelResult>> results;

  LevelResult? resultFor(String chapterId, int level) => results[chapterId]?[level];
```

and give `copyWith` a `Map<String, Map<int, LevelResult>>? results` parameter, passed through as `results: results ?? this.results`.

3. In the notifier, `_hydrate` becomes:

```dart
  Future<void> _hydrate() async {
    final snapshot = await _repo!.fetchAll();
    state = state.copyWith(
      completedLevels: {for (final e in snapshot.entries) e.key: e.value.keys.toSet()},
      results: snapshot,
    );
  }
```

and `completeLevel` becomes:

```dart
  /// Marks a level complete. The first completion's result stands: a replay
  /// can't turn a right-first-time level into a wrong one, or the reverse.
  void completeLevel({
    required String chapterId,
    required int level,
    required double score,
    bool solutionViewed = false,
  }) {
    if (state.isCompleted(chapterId, level)) return;
    final result = LevelResult(score: score, solutionViewed: solutionViewed);
    state = state.copyWith(
      completedLevels: {
        ...state.completedLevels,
        chapterId: {...?state.completedLevels[chapterId], level},
      },
      results: {
        ...state.results,
        chapterId: {...?state.results[chapterId], level: result},
      },
    );
    _repo
        ?.completeLevel(chapterId: chapterId, level: level, score: score, solutionViewed: solutionViewed)
        .catchError((_) {});
  }
```

In `app/lib/data/level_progress_repository.dart`, add `import 'mission_state.dart';` and replace both methods:

```dart
  /// Every completed level per chapter, with its result.
  Future<Map<String, Map<int, LevelResult>>> fetchAll() async {
    final userId = _userId;
    List rows;
    try {
      rows = await _client
          .from('level_progress')
          .select('chapter_id, level, score, solution_viewed')
          .eq('user_id', userId) as List;
    } on PostgrestException {
      // A database without 20261001000000 has no solution_viewed column.
      rows = await _client.from('level_progress').select('chapter_id, level, score').eq('user_id', userId) as List;
    }
    final result = <String, Map<int, LevelResult>>{};
    for (final row in rows) {
      result.putIfAbsent(row['chapter_id'] as String, () => {})[row['level'] as int] = LevelResult(
        score: (row['score'] as num?)?.toDouble() ?? 0,
        solutionViewed: row['solution_viewed'] as bool? ?? false,
      );
    }
    return result;
  }

  /// Inserts the level's first completion; a replay leaves the row as is.
  Future<void> completeLevel({
    required String chapterId,
    required int level,
    required double score,
    bool solutionViewed = false,
  }) async {
    final row = <String, dynamic>{
      'user_id': _userId,
      'chapter_id': chapterId,
      'level': level,
      'score': score,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'solution_viewed': solutionViewed,
    };
    try {
      await _client.from('level_progress').upsert(row, onConflict: 'user_id,chapter_id,level', ignoreDuplicates: true);
    } on PostgrestException {
      // A database without 20261001000000: save the completion without the new column.
      row.remove('solution_viewed');
      await _client.from('level_progress').upsert(row, onConflict: 'user_id,chapter_id,level', ignoreDuplicates: true);
    }
  }
```

`app/lib/data/trial_trophy.dart`:

```dart
import 'mission_state.dart';
import 'models.dart';

enum TrialTrophy { none, gold, platinum }

/// Gold: every loaded Trial level finished. Platinum: finished with at least
/// 90% right first time and no solution viewed (spec: "The Chapter Trial").
TrialTrophy trialTrophy(String chapterId, List<Question> levels, LevelProgressState progress) {
  if (levels.isEmpty) return TrialTrophy.none;
  final results = <LevelResult>[];
  for (final q in levels) {
    final r = progress.resultFor(chapterId, q.level!);
    if (r == null) return TrialTrophy.none;
    results.add(r);
  }
  final firstTime = results.where((r) => r.score >= 1).length / results.length;
  final anySolution = results.any((r) => r.solutionViewed);
  return firstTime >= 0.9 && !anySolution ? TrialTrophy.platinum : TrialTrophy.gold;
}
```

- [ ] **Step 4: Track solution viewing in the player**

In `workout_screen.dart`:

1. State field: `bool _solutionViewed = false;`.
2. `_FeedbackPanel` gains `this.onSolutionOpened` (a `final VoidCallback? onSolutionOpened;`). Its `ExpansionTile` gets `onExpansionChanged: (open) { if (open) onSolutionOpened?.call(); },`.
3. Where `_FeedbackPanel(...)` is built, pass `onSolutionOpened: () => _solutionViewed = true,`.
4. In the single-level branch of `_next`, the `completeLevel` call gains `solutionViewed: _solutionViewed,`.

- [ ] **Step 5: Run the tests**

Run: `cd app && flutter test`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add app/lib app/test
git commit -m "feat(app): Trial level results with solution viewing; Gold and Platinum"
```

---

### Task 12: The Chapter Trial screen and level preview sheet

**Files:**
- Create: `app/lib/features/trial/level_labels.dart`
- Create: `app/lib/features/trial/level_preview_sheet.dart`
- Create: `app/lib/features/trial/trial_screen.dart`
- Test: `app/test/features/trial/trial_screen_test.dart`

**Interfaces:**
- Consumes: `courseProgressProvider` (Task 9), `trialTrophy` (Task 11), `WorkoutScreen.singleLevel`.
- Produces: `TrialScreen({required String chapterId})`, `Future<void> showLevelPreview(BuildContext, {required Question level, required int number, required int total})`, `String stageLabel(String?)`, `String questionTypeLabel(QuestionType)`, `int estimatedMinutes(Question)`. Widget keys: `trial_node_<level>`, `trial_checkpoint_<level>`, `trial_stage_<STAGE>_folded|_current|_future`.

- [ ] **Step 1: Write the failing test**

`app/test/features/trial/trial_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/trial/trial_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

Finder _node(int level) => find.byKey(ValueKey('trial_node_$level'));
bool _locked(int level) =>
    find.descendant(of: _node(level), matching: find.byIcon(Icons.lock_rounded)).evaluate().isNotEmpty;

Future<ProviderContainer> _openTrial(WidgetTester tester, {Set<int> done = const {}, ThemeData? theme, bool readAll = true}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (readAll) {
    for (final id in ['t_cube', 't_cyl', 't_cone']) {
      await container.read(theoryProgressProvider.notifier).markRead(id);
    }
  }
  for (final l in done) {
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: l, score: 1);
  }
  await pumpScreen(tester, const TrialScreen(chapterId: savChapter), container: container, theme: theme);
  return container;
}

void main() {
  setUp(loadSlice1Content);

  for (final t in themes.entries) {
    testWidgets('fresh Trial: Foundation open, the other four stages folded in order (${t.key})', (tester) async {
      await _openTrial(tester, theme: t.value);
      expect(find.byKey(const ValueKey('trial_stage_FOUNDATION_current')), findsOneWidget);
      expect(_locked(1), isFalse);
      expect(_locked(2), isTrue);
      expect(find.byKey(const ValueKey('trial_checkpoint_2')), findsOneWidget, reason: 'last level of a stage');

      final futures = ['GUIDED_PRACTICE', 'SKILL_BUILDING', 'APPLICATION', 'MASTERY']
          .map((s) => tester.getTopLeft(find.byKey(ValueKey('trial_stage_${s}_future'))).dy)
          .toList();
      expect(futures, [...futures]..sort(), reason: 'stages keep their order');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a finished stage folds to one line and the next opens', (tester) async {
    await _openTrial(tester, done: {1, 2});
    expect(find.byKey(const ValueKey('trial_stage_FOUNDATION_folded')), findsOneWidget);
    expect(find.text('Foundation · 2 / 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('trial_stage_GUIDED_PRACTICE_current')), findsOneWidget);
    expect(_locked(3), isFalse);
    expect(_locked(4), isTrue);
  });

  testWidgets('tapping a level opens its preview; Start level launches it', (tester) async {
    await _openTrial(tester);
    await tester.tap(_node(1));
    await tester.pumpAndSettle();

    expect(find.text('Level 1 of 10 · Foundation'), findsOneWidget);
    expect(find.text('Cuboids and cubes'), findsOneWidget);
    expect(find.text('Multiple choice · About 1 min'), findsOneWidget);
    expect(find.textContaining('Why level 1 comes next.', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Start level'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });

  testWidgets('locked while any topic is unfinished', (tester) async {
    await _openTrial(tester, readAll: false);
    expect(find.text('Finish all 3 topics to open the Trial'), findsOneWidget);
    expect(_node(1), findsNothing);
  });

  testWidgets('trophy line shows Platinum when earned', (tester) async {
    await _openTrial(tester, done: {for (var l = 1; l <= 10; l++) l});
    expect(find.text('Platinum trophy earned'), findsOneWidget);
  });

  testWidgets('all 62 levels stay reachable, unlocking one by one', (tester) async {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(id: savChapter, name: 'Surface Area and Volume', boardWeightMarks: 6, concepts: [
          Concept(id: 'c.cube', name: 'Cuboids and cubes', chapterId: savChapter),
        ]),
      ],
      questions: [
        for (var l = 1; l <= 62; l++) fixtureQuestion('q_l$l', 'c.cube', level: l, stage: stages[((l - 1) * 5) ~/ 62]),
      ],
      lessons: const [cubeLesson],
    ));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(theoryProgressProvider.notifier).markRead('t_cube');
    for (var l = 1; l <= 61; l++) {
      container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: l, score: 1);
    }
    await pumpScreen(tester, const TrialScreen(chapterId: savChapter), container: container);
    expect(_locked(62), isFalse);
    expect(find.byKey(const ValueKey('trial_stage_MASTERY_current')), findsOneWidget);
  });

  testWidgets('gapped levels unlock off the previous LOADED level', (tester) async {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(id: savChapter, name: 'Surface Area and Volume', boardWeightMarks: 6, concepts: [
          Concept(id: 'c.cube', name: 'Cuboids and cubes', chapterId: savChapter),
        ]),
      ],
      questions: [for (final l in [2, 3, 5]) fixtureQuestion('q_l$l', 'c.cube', level: l, stage: 'FOUNDATION')],
      lessons: const [cubeLesson],
    ));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(theoryProgressProvider.notifier).markRead('t_cube');
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: 2, score: 1);
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: 3, score: 1);
    await pumpScreen(tester, const TrialScreen(chapterId: savChapter), container: container);
    expect(_locked(5), isFalse, reason: 'level 4 never loaded, so it is not required');
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/features/trial/trial_screen_test.dart`
Expected: compile error (`trial_screen.dart` doesn't exist).

- [ ] **Step 3: Implement labels and the preview sheet**

`app/lib/features/trial/level_labels.dart`:

```dart
import '../../data/models.dart';

const trialStageLabels = {
  'FOUNDATION': 'Foundation',
  'GUIDED_PRACTICE': 'Guided practice',
  'SKILL_BUILDING': 'Skill building',
  'APPLICATION': 'Application',
  'MASTERY': 'Mastery',
};

String stageLabel(String? stage) => trialStageLabels[stage] ?? stage ?? 'Trial';

String questionTypeLabel(QuestionType type) => switch (type) {
      QuestionType.mcq => 'Multiple choice',
      QuestionType.numeric => 'Number answer',
      QuestionType.assertionReason => 'Assertion and reason',
      QuestionType.caseBased => 'Case study',
      QuestionType.expression => 'Expression',
    };

/// No level carries a time yet, so this is a per-type estimate.
int estimatedMinutes(Question q) => switch (q.type) {
      QuestionType.caseBased => 4,
      QuestionType.numeric || QuestionType.expression => 2,
      _ => 1,
    };
```

`app/lib/features/trial/level_preview_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/math_text.dart';
import '../workout/workout_screen.dart';
import 'level_labels.dart';

/// The sheet shown before a Trial level starts (spec: "Tapping a level
/// opens a preview sheet").
Future<void> showLevelPreview(BuildContext context, {required Question level, required int number, required int total}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => LevelPreviewSheet(level: level, number: number, total: total),
  );
}

class LevelPreviewSheet extends StatelessWidget {
  const LevelPreviewSheet({super.key, required this.level, required this.number, required this.total});
  final Question level;
  final int number;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    // No short names exist yet, so a level is named after its topic.
    final name = Content.conceptOrNull(level.conceptId)?.name ?? 'Level ${level.level}';
    final why = level.whyAfterPrevious;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.space24, AppTheme.space16, AppTheme.space24, AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Level $number of $total · ${stageLabel(level.stage)}',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
            const SizedBox(height: AppTheme.space8),
            Text(name, style: textTheme.headlineMedium),
            const SizedBox(height: AppTheme.space8),
            Text('${questionTypeLabel(level.type)} · About ${estimatedMinutes(level)} min',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkFaint)),
            if (why != null) ...[
              const SizedBox(height: AppTheme.space16),
              Text('Why this comes next', style: textTheme.titleSmall),
              const SizedBox(height: AppTheme.space4),
              MathText(why, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: AppTheme.space24),
            ChunkyButton(
              label: 'Start level',
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(MaterialPageRoute<void>(builder: (_) => WorkoutScreen.singleLevel(level)));
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement the Trial screen**

`app/lib/features/trial/trial_screen.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../data/mission_state.dart';
import '../../data/models.dart';
import '../../data/trial_trophy.dart';
import 'level_labels.dart';
import 'level_preview_sheet.dart';

/// The Chapter Trial (the old Mission path): the chapter's levels in their
/// five stages. Finished stages fold to one line, the current stage is a
/// winding path, later stages are single cards. Unlocking is unchanged:
/// positional, via LevelProgressState.isUnlocked.
class TrialScreen extends ConsumerWidget {
  const TrialScreen({super.key, required this.chapterId});
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final chapter = ref.watch(courseProgressProvider).chapter(chapterId);
    final progress = ref.watch(levelProgressProvider);

    if (chapter == null || !chapter.trialUnlocked) {
      final n = chapter?.topics.length ?? 0;
      return Scaffold(
        appBar: AppBar(title: const Text('Chapter Trial')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Text('Finish all $n topics to open the Trial', textAlign: TextAlign.center, style: textTheme.bodyLarge),
          ),
        ),
      );
    }

    final levels = chapter.trialLevels;
    final stages = <String>[];
    final byStage = <String, List<int>>{};
    for (var i = 0; i < levels.length; i++) {
      final s = levels[i].stage ?? '';
      if (!byStage.containsKey(s)) stages.add(s);
      byStage.putIfAbsent(s, () => []).add(i);
    }
    bool done(int i) => progress.isCompleted(chapterId, levels[i].level!);
    final firstOpen = List.generate(levels.length, (i) => i).where((i) => !done(i)).firstOrNull;
    final currentStage = firstOpen == null ? null : (levels[firstOpen].stage ?? '');

    return Scaffold(
      appBar: AppBar(title: Text('${chapter.chapter.name} · Trial')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space32),
        children: [
          _TrophyLine(
            trophy: trialTrophy(chapterId, levels, progress),
            cleared: chapter.levelsCleared,
            total: levels.length,
          ),
          const SizedBox(height: AppTheme.space16),
          for (final stage in stages) ...[
            if (byStage[stage]!.every(done))
              _FoldedStage(stage: stage, count: byStage[stage]!.length)
            else if (stage == currentStage)
              _CurrentStage(stage: stage, indexes: byStage[stage]!, levels: levels, chapterId: chapterId, progress: progress)
            else
              _FutureStage(stage: stage, count: byStage[stage]!.length),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }
}

class _TrophyLine extends StatelessWidget {
  const _TrophyLine({required this.trophy, required this.cleared, required this.total});
  final TrialTrophy trophy;
  final int cleared;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = switch (trophy) {
      TrialTrophy.platinum => 'Platinum trophy earned',
      TrialTrophy.gold => 'Gold trophy earned',
      TrialTrophy.none => '$cleared of $total levels cleared · Gold for finishing, '
          'Platinum for 90% right first time with no solutions viewed',
    };
    return Row(
      children: [
        Icon(Icons.emoji_events_rounded, color: trophy == TrialTrophy.none ? colors.notStarted : colors.xp),
        const SizedBox(width: AppTheme.space8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkSoft))),
      ],
    );
  }
}

class _FoldedStage extends StatelessWidget {
  const _FoldedStage({required this.stage, required this.count});
  final String stage;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: ValueKey('trial_stage_${stage}_folded'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(color: colors.masteredLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.mastered),
          const SizedBox(width: AppTheme.space8),
          Text('${stageLabel(stage)} · $count / $count',
              style: TextStyle(color: colors.masteredDark, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _FutureStage extends StatelessWidget {
  const _FutureStage({required this.stage, required this.count});
  final String stage;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: ValueKey('trial_stage_${stage}_future'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: colors.inkFaint),
          const SizedBox(width: AppTheme.space8),
          Text('${stageLabel(stage)} · $count levels', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

const _windingOffsets = [0.0, 56.0, 112.0, 56.0];

class _CurrentStage extends StatelessWidget {
  const _CurrentStage({
    required this.stage,
    required this.indexes,
    required this.levels,
    required this.chapterId,
    required this.progress,
  });

  final String stage;
  final List<int> indexes;
  final List<Question> levels;
  final String chapterId;
  final LevelProgressState progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('trial_stage_${stage}_current'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(stageLabel(stage), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTheme.space12),
        for (var k = 0; k < indexes.length; k++) _node(context, indexes[k], k, checkpoint: k == indexes.length - 1),
      ],
    );
  }

  Widget _node(BuildContext context, int i, int k, {required bool checkpoint}) {
    final level = levels[i];
    final completed = progress.isCompleted(chapterId, level.level!);
    // Positional unlock: the predecessor is the previous LOADED level.
    final unlocked = progress.isUnlocked(chapterId, previousLevelInList: i == 0 ? null : levels[i - 1].level);
    return Padding(
      padding: EdgeInsets.only(left: _windingOffsets[k % _windingOffsets.length], bottom: AppTheme.space12),
      child: _TrialNode(
        key: ValueKey('trial_node_${level.level}'),
        level: level,
        number: i + 1,
        completed: completed,
        unlocked: unlocked,
        checkpoint: checkpoint,
        onTap: unlocked ? () => showLevelPreview(context, level: level, number: i + 1, total: levels.length) : null,
      ),
    );
  }
}

class _TrialNode extends StatelessWidget {
  const _TrialNode({
    super.key,
    required this.level,
    required this.number,
    required this.completed,
    required this.unlocked,
    required this.checkpoint,
    required this.onTap,
  });

  final Question level;
  final int number;
  final bool completed;
  final bool unlocked;

  /// The last level of a stage, drawn as a diamond.
  final bool checkpoint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color fill;
    final Widget icon;
    if (completed) {
      fill = colors.mastered;
      icon = Icon(Icons.check_rounded, color: colors.background);
    } else if (unlocked) {
      fill = colors.brand;
      icon = Text('$number', style: TextStyle(color: colors.accentInk, fontWeight: FontWeight.w800));
    } else {
      fill = colors.notStarted;
      icon = Icon(Icons.lock_rounded, color: colors.background, size: 18);
    }
    final shape = checkpoint
        ? Transform.rotate(
            key: ValueKey('trial_checkpoint_${level.level}'),
            angle: math.pi / 4,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Transform.rotate(angle: -math.pi / 4, child: icon),
            ),
          )
        : Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: icon,
          );
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 48, height: 48, child: Center(child: shape)),
          const SizedBox(width: AppTheme.space12),
          Text(checkpoint ? 'Level $number · Checkpoint' : 'Level $number',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests**

Run: `cd app && flutter test test/features/trial`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/trial app/test/features/trial
git commit -m "feat(app): Chapter Trial with folding stages, checkpoints and a level preview sheet"
```

---

### Task 13: The topic-based chapter screen

**Files:**
- Create: `app/lib/features/chapter/chapter_screen.dart`
- Create: `app/lib/features/chapter/topic_tile.dart`
- Create: `app/lib/features/chapter/trial_gate.dart`
- Create: `app/lib/features/chapter/notes_screen.dart`
- Create: `app/lib/features/chapter/topic_practice_sheet.dart`
- Create: `app/lib/features/chapter/next_step_navigation.dart`
- Test: `app/test/features/chapter/chapter_screen_test.dart`

**Interfaces:**
- Consumes: `courseProgressProvider`, `ChapterProgress`, `TopicProgress`, `NodeStatus`, `NextStep` (Task 9); `WorkoutScreen.node` (Task 10); `TrialScreen` (Task 12); `LessonScreen`.
- Produces: `ChapterScreen({required String chapterId})`, `NotesScreen({required Chapter chapter})`, `Future<void> showTopicPracticeSheet(BuildContext, Chapter)`, `void openNextStep(BuildContext, ChapterProgress, NextStep)`, `String nextStepPosition(ChapterProgress, NextStep)`. Widget keys: `topic_<conceptId>`, `node_<conceptId>_learn`, `node_<conceptId>_<dbValue>`, `trial_gate`, `seal_<conceptId>`, `practice_<conceptId>`.

- [ ] **Step 1: Write the failing test**

`app/test/features/chapter/chapter_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/chapter/chapter_screen.dart';
import 'package:study_gym/features/chapter/notes_screen.dart';
import 'package:study_gym/features/theory/lesson_screen.dart';
import 'package:study_gym/features/trial/trial_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

Finder _in(String key, Finder f) => find.descendant(of: find.byKey(ValueKey(key)), matching: f);

Future<ProviderContainer> _open(WidgetTester tester, String chapterId, {Set<String> read = const {}, ThemeData? theme}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  for (final id in read) {
    await container.read(theoryProgressProvider.notifier).markRead(id);
  }
  await pumpScreen(tester, ChapterScreen(chapterId: chapterId), container: container, theme: theme);
  return container;
}

void main() {
  setUp(loadSlice1Content);

  for (final t in themes.entries) {
    testWidgets('fresh chapter: first topic open with Do you know?, others locked (${t.key})', (tester) async {
      await _open(tester, savChapter, theme: t.value);

      expect(find.text('0 of 3 topics done · Trial locked'), findsOneWidget);
      final ys = ['c.cube', 'c.cyl', 'c.cone'].map((id) => tester.getTopLeft(find.byKey(ValueKey('topic_$id'))).dy).toList();
      expect(ys, [...ys]..sort(), reason: 'syllabus order');

      expect(_in('topic_c.cube', find.text('Do you know?')), findsOneWidget);
      expect(_in('topic_c.cube', find.textContaining('Every shipping box is a cuboid.', findRichText: true)), findsOneWidget);
      expect(_in('topic_c.cube', find.text('Questions coming soon')), findsNWidgets(4));
      expect(_in('topic_c.cyl', find.byIcon(Icons.lock_rounded)), findsOneWidget);
      expect(_in('topic_c.cyl', find.text('Do you know?')), findsNothing);
      expect(find.text('Finish all 3 topics to open the Trial'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Learn opens the lesson; marking it read finishes the topic (interim rule)', (tester) async {
    await _open(tester, savChapter);
    await tester.tap(find.byKey(const ValueKey('node_c.cube_learn')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);

    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();

    expect(find.byType(ChapterScreen), findsOneWidget);
    expect(find.text('Cuboids and cubes · Lesson read'), findsOneWidget);
    expect(_in('topic_c.cyl', find.text('Do you know?')), findsOneWidget, reason: 'next topic is now current');
    expect(tester.widget<Icon>(find.byKey(const ValueKey('seal_c.cube'))).icon, Icons.lock_open_rounded);
    expect(tester.widget<Icon>(find.byKey(const ValueKey('seal_c.cyl'))).icon, Icons.lock_rounded);
  });

  testWidgets('all seals broken opens the Trial', (tester) async {
    await _open(tester, savChapter, read: {'t_cube', 't_cyl', 't_cone'});
    expect(find.text('3 of 3 topics done · Trial open'), findsOneWidget);
    await tester.tap(find.text('Open the Trial'));
    await tester.pumpAndSettle();
    expect(find.byType(TrialScreen), findsOneWidget);
  });

  testWidgets('a topic with questions uses its nodes, not the lesson-read rule', (tester) async {
    await _open(tester, idenChapter, read: {'t_iden'});
    expect(find.text('0 of 1 topics done'), findsOneWidget);
    expect(_in('node_c.iden_practice', find.text('Questions coming soon')), findsOneWidget);
    expect(_in('node_c.iden_challenge', find.byIcon(Icons.lock_rounded)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('node_c.iden_guided')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });

  testWidgets('Notes lists the chapter\'s lessons; Practice lists its topics', (tester) async {
    await _open(tester, savChapter);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.text('Cylinders'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(_in('practice_c.cube', find.text('No practice questions yet')), findsOneWidget);
  });

  testWidgets('Practice starts a topic drill when questions exist', (tester) async {
    await _open(tester, seqChapter);
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(_in('practice_c.ap', find.text('0% mastery')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('practice_c.ap')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/features/chapter/chapter_screen_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement next-step navigation**

`app/lib/features/chapter/next_step_navigation.dart`:

```dart
import 'package:flutter/material.dart';

import '../../data/chapter_progress.dart';
import '../theory/lesson_screen.dart';
import '../workout/workout_screen.dart';
import 'chapter_screen.dart';

/// Opens exactly what comes next (spec: "a Continue button that opens the
/// next node directly"). Only when nothing specific can be opened does it
/// fall back to the chapter screen.
void openNextStep(BuildContext context, ChapterProgress chapter, NextStep step) {
  final Widget page = switch (step) {
    LessonStep(:final lesson) => LessonScreen(lesson: lesson),
    NodeStep(:final concept, :final node) => WorkoutScreen.node(concept: concept, node: node),
    TrialLevelStep(:final level) => WorkoutScreen.singleLevel(level),
    OpenChapterStep() => ChapterScreen(chapterId: chapter.chapter.id),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

/// "Topic N of M" or "Trial level N of M".
String nextStepPosition(ChapterProgress chapter, NextStep step) => switch (step) {
      TrialLevelStep(:final number, :final total) => 'Trial level $number of $total',
      LessonStep(:final topicNumber) || NodeStep(:final topicNumber) => 'Topic $topicNumber of ${chapter.topics.length}',
      OpenChapterStep() => chapter.topics.isEmpty ? '' : 'Topic ${chapter.currentTopicNumber ?? 1} of ${chapter.topics.length}',
    };
```

- [ ] **Step 4: Implement the topic tiles and the Trial gate**

`app/lib/features/chapter/topic_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../data/models.dart';
import '../../shared/widgets/math_text.dart';
import '../theory/lesson_screen.dart';
import '../workout/workout_screen.dart';

/// One topic on the chapter screen: a finished topic folds to one line,
/// the current topic is open, later topics are single cards.
class TopicTile extends StatelessWidget {
  const TopicTile({super.key, required this.topic});
  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey('topic_${topic.concept.id}');
    return switch (topic.status) {
      TopicStatus.done => _FinishedTopic(key: key, topic: topic),
      TopicStatus.current => _CurrentTopic(key: key, topic: topic),
      TopicStatus.locked => _LockedTopic(key: key, topic: topic),
    };
  }
}

BoxDecoration _card(AppColors colors) => BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(color: colors.border),
    );

class _FinishedTopic extends StatelessWidget {
  const _FinishedTopic({super.key, required this.topic});
  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = topic.usesInterimRule ? 'Lesson read' : '${topic.nodesPassed} / ${topic.nodeCount}';
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(color: colors.masteredLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.mastered),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text('${topic.concept.name} · $detail',
                style: TextStyle(color: colors.masteredDark, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _LockedTopic extends StatelessWidget {
  const _LockedTopic({super.key, required this.topic});
  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String detail;
    if (topic.usesInterimRule) {
      detail = topic.lesson != null ? 'lesson · questions coming soon' : 'coming soon';
    } else {
      detail = '${topic.lesson != null ? 'lesson + ' : ''}${topic.nodeCount} nodes';
    }
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: _card(colors),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: colors.inkFaint),
          const SizedBox(width: AppTheme.space12),
          Expanded(child: Text('${topic.concept.name} · $detail', style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

const _windingOffsets = [0.0, 40.0, 80.0, 40.0, 0.0];

class _CurrentTopic extends StatelessWidget {
  const _CurrentTopic({super.key, required this.topic});
  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final concept = topic.concept;
    final lesson = topic.lesson;
    final steps = <Widget>[
      _PathNode(
        key: ValueKey('node_${concept.id}_learn'),
        label: '▶ Learn',
        subtitle: lesson == null ? 'Lesson coming soon' : null,
        status: lesson == null
            ? NodeStatus.comingSoon
            : (topic.lessonRead ? NodeStatus.passed : NodeStatus.open),
        onTap: lesson == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson))),
      ),
      for (final slot in topic.nodes)
        _PathNode(
          key: ValueKey('node_${concept.id}_${slot.node.dbValue}'),
          label: slot.node.label,
          subtitle: slot.status == NodeStatus.comingSoon ? 'Questions coming soon' : '${slot.questionCount} questions',
          status: slot.status,
          onTap: slot.status == NodeStatus.open
              ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => WorkoutScreen.node(concept: concept, node: slot.node),
                  ))
              : null,
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: _card(colors).copyWith(border: Border.all(color: colors.brand, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(concept.name, style: Theme.of(context).textTheme.titleLarge),
          if (lesson != null && lesson.hook.trim().isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            DoYouKnowCard(lesson: lesson),
          ],
          const SizedBox(height: AppTheme.space16),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(left: _windingOffsets[i % _windingOffsets.length], bottom: AppTheme.space8),
              child: steps[i],
            ),
        ],
      ),
    );
  }
}

/// "Do you know?" from the lesson's existing `hook` (spec: no new content).
class DoYouKnowCard extends StatelessWidget {
  const DoYouKnowCard({super.key, required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kind = switch (lesson.hookKind) {
      HookKind.realWorld => 'Real world',
      HookKind.historical => 'From history',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Do you know?', style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800)),
              const SizedBox(width: AppTheme.space8),
              Text(kind, style: TextStyle(color: colors.inkSoft, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          MathText(lesson.hook, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink)),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({super.key, required this.label, required this.status, this.subtitle, this.onTap});
  final String label;
  final String? subtitle;
  final NodeStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (fill, icon, iconColor) = switch (status) {
      NodeStatus.passed => (colors.mastered, Icons.check_rounded, colors.background),
      NodeStatus.open => (colors.brand, Icons.play_arrow_rounded, colors.accentInk),
      NodeStatus.locked => (colors.notStarted, Icons.lock_rounded, colors.background),
      NodeStatus.comingSoon => (colors.notStartedLight, Icons.hourglass_empty_rounded, colors.inkFaint),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppTheme.space12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: colors.inkFaint, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
```

`app/lib/features/chapter/trial_gate.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../shared/widgets/chunky_button.dart';
import '../trial/trial_screen.dart';

/// Closes the chapter: a trophy, one seal per topic (broken when the topic
/// is finished), and the way into the Trial once every seal is broken.
class TrialGate extends StatelessWidget {
  const TrialGate({super.key, required this.progress});
  final ChapterProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final open = progress.trialUnlocked;
    return Container(
      key: const ValueKey('trial_gate'),
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: open ? colors.xp : colors.border, width: open ? 2 : 1),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 40, color: open ? colors.xp : colors.notStarted),
          const SizedBox(height: AppTheme.space8),
          Text('Chapter Trial', style: textTheme.titleLarge),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            spacing: AppTheme.space8,
            children: [
              for (final t in progress.topics)
                Icon(
                  t.isDone ? Icons.lock_open_rounded : Icons.lock_rounded,
                  key: ValueKey('seal_${t.concept.id}'),
                  color: t.isDone ? colors.mastered : colors.notStarted,
                  semanticLabel: t.isDone ? 'Seal broken: ${t.concept.name}' : 'Sealed: ${t.concept.name}',
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          if (!open)
            Text('Finish all ${progress.topics.length} topics to open the Trial',
                textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft))
          else ...[
            Text('${progress.levelsCleared} of ${progress.trialLevels.length} levels cleared',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
            const SizedBox(height: AppTheme.space12),
            ChunkyButton(
              label: progress.levelsCleared == 0 ? 'Open the Trial' : 'Continue the Trial',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => TrialScreen(chapterId: progress.chapter.id),
              )),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Implement Notes, Practice and the screen**

`app/lib/features/chapter/notes_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/theory_state.dart';
import '../theory/lesson_screen.dart';

/// Re-read this chapter's lessons (replaces the old Theory tab).
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key, required this.chapter});
  final Chapter chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final progress = ref.watch(theoryProgressProvider);
    final lessons = Content.lessonsForChapter(chapter.id);
    return Scaffold(
      appBar: AppBar(title: Text('Notes · ${chapter.name}')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space20),
        children: [
          for (final lesson in lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space8),
              child: Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: ListTile(
                  leading: Icon(
                    progress.isRead(lesson.id) ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: progress.isRead(lesson.id) ? colors.mastered : colors.notStarted,
                  ),
                  title: Text(lesson.title),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.inkFaint),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

`app/lib/features/chapter/topic_practice_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../shared/widgets/mastery_ring.dart';
import '../workout/workout_screen.dart';

/// The chapter's Practice button: pick a topic, see its mastery, drill it.
Future<void> showTopicPracticeSheet(BuildContext context, Chapter chapter) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TopicPracticeSheet(chapter: chapter),
  );
}

class _TopicPracticeSheet extends ConsumerWidget {
  const _TopicPracticeSheet({required this.chapter});
  final Chapter chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mastery = ref.watch(studentProvider).mastery;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space8),
              child: Text('Practice a topic', style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final concept in chapter.concepts)
              Builder(builder: (context) {
                final hasQuestions = Content.practiceQuestions(concept.id).isNotEmpty;
                final percent = mastery[concept.id]?.masteryPercent ?? 0;
                return ListTile(
                  key: ValueKey('practice_${concept.id}'),
                  leading: MasteryRing(progress: percent / 100, size: 36, strokeWidth: 4, animate: false),
                  title: Text(concept.name),
                  subtitle: Text(
                    hasQuestions ? '${percent.round()}% mastery' : 'No practice questions yet',
                    style: TextStyle(color: colors.inkFaint),
                  ),
                  enabled: hasQuestions,
                  onTap: hasQuestions
                      ? () {
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          navigator.push(MaterialPageRoute<void>(builder: (_) => WorkoutScreen(concepts: [concept])));
                        }
                      : null,
                );
              }),
          ],
        ),
      ),
    );
  }
}
```

`app/lib/features/chapter/chapter_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../data/content.dart';
import 'notes_screen.dart';
import 'topic_practice_sheet.dart';
import 'topic_tile.dart';
import 'trial_gate.dart';

/// A chapter as its syllabus topics, each Learn → question nodes, closed
/// by the Trial gate (spec: "The chapter screen").
class ChapterScreen extends ConsumerWidget {
  const ChapterScreen({super.key, required this.chapterId});
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(courseProgressProvider).chapter(chapterId);
    if (progress == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('This chapter is not available.')));
    }
    final colors = context.colors;
    final chapter = progress.chapter;
    final hasLessons = Content.lessonsForChapter(chapter.id).isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(chapter.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space32),
        children: [
          Text(_summary(progress), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
          const SizedBox(height: AppTheme.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation(colors.brand),
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasLessons
                      ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NotesScreen(chapter: chapter)))
                      : null,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Notes'),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showTopicPracticeSheet(context, chapter),
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: const Text('Practice'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space24),
          for (final topic in progress.topics) ...[
            TopicTile(topic: topic),
            const SizedBox(height: AppTheme.space12),
          ],
          if (progress.trialLevels.isNotEmpty) TrialGate(progress: progress),
        ],
      ),
    );
  }

  static String _summary(ChapterProgress p) {
    final topics = '${p.topicsDone} of ${p.topics.length} topics done';
    if (p.trialLevels.isEmpty) return topics;
    final trial = !p.trialUnlocked
        ? 'Trial locked'
        : (p.levelsCleared == p.trialLevels.length ? 'Trial complete' : 'Trial open');
    return '$topics · $trial';
  }
}
```

- [ ] **Step 6: Run the tests**

Run: `cd app && flutter test test/features/chapter`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add app/lib/features/chapter app/test/features/chapter
git commit -m "feat(app): topic-based chapter screen with Do you know?, node path, Notes, Practice and the Trial gate"
```

---

### Task 14: The Learn tab and the Tests section

**Files:**
- Create: `app/lib/features/learn/learn_screen.dart`
- Create: `app/lib/features/tests/tests_section.dart`
- Modify: `app/lib/features/tests/tests_screen.dart` (becomes a thin wrapper until Task 16 deletes it)
- Test: `app/test/features/learn/learn_screen_test.dart`

**Interfaces:**
- Consumes: `CourseChip` (Task 4), `courseProgressProvider` (Task 9), `ChapterScreen` (Task 13).
- Produces: `LearnScreen()`, `ChapterRow({Key? key, required ChapterProgress progress})`, `TestsSection()`. Keys: `pinned_chapter`, `chapter_row_<id>`, `unit_<id>`.

- [ ] **Step 1: Write the failing test**

`app/test/features/learn/learn_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/chapter/chapter_screen.dart';
import 'package:study_gym/features/learn/learn_screen.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

double _y(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;
Finder _row(String id) => find.byKey(ValueKey('chapter_row_$id'));

void main() {
  setUp(loadSlice1Content);

  for (final t in themes.entries) {
    testWidgets('units in syllabus order with marks; chapters inside them; Tests last (${t.key})', (tester) async {
      await pumpScreen(tester, const LearnScreen(), theme: t.value);

      expect(find.text('Class 9 ▾'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('0 of 4 chapters started · 0 levels cleared'), findsOneWidget);

      final algebra = find.text('Algebra · 20 marks');
      final geometry = find.text('Geometry · 25 marks');
      final mensuration = find.text('Mensuration · 14 marks');
      expect(_y(tester, algebra) < _y(tester, geometry), isTrue);
      expect(_y(tester, geometry) < _y(tester, mensuration), isTrue);
      expect(_y(tester, _row(seqChapter)) < _y(tester, _row(idenChapter)), isTrue);
      expect(_y(tester, algebra) < _y(tester, _row(seqChapter)), isTrue);
      expect(_y(tester, _row(idenChapter)) < _y(tester, geometry), isTrue);

      expect(_y(tester, find.text('Tests')) > _y(tester, _row(savChapter)), isTrue, reason: 'Tests at the end');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a chapter with no content shows Soon and does not open', (tester) async {
    await pumpScreen(tester, const LearnScreen());
    expect(find.descendant(of: _row(triChapter), matching: find.text('Soon')), findsOneWidget);
    await tester.tap(_row(triChapter));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsNothing);
  });

  testWidgets('the chapter in progress is pinned, with real progress', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(theoryProgressProvider.notifier).markRead('t_cube');
    container.read(levelProgressProvider.notifier).completeLevel(chapterId: savChapter, level: 1, score: 1);
    await pumpScreen(tester, const LearnScreen(), container: container);

    expect(find.text('1 of 4 chapters started · 1 level cleared'), findsOneWidget);
    final pinned = find.byKey(const ValueKey('pinned_chapter'));
    expect(find.descendant(of: pinned, matching: find.text('Surface Area and Volume')), findsOneWidget);
    expect(_y(tester, pinned) < _y(tester, find.text('Algebra · 20 marks')), isTrue);

    await tester.tap(pinned);
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsOneWidget);
  });

  testWidgets('no chapter started: the first chapter with content is suggested', (tester) async {
    await pumpScreen(tester, const LearnScreen());
    expect(find.text('Start here'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('pinned_chapter')), matching: find.text('Sequences and Progressions')), findsOneWidget);
  });

  testWidgets('chapters with no unit (database without the units migration) are still listed', (tester) async {
    // No units loaded: what the app gets from a database without 20261001000000.
    final snap = slice1Snapshot();
    Content.load(ContentSnapshot(chapters: snap.chapters, questions: snap.questions, lessons: snap.lessons));
    await pumpScreen(tester, const LearnScreen());
    expect(find.text('More chapters'), findsOneWidget);
    expect(_row(savChapter), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/features/learn/learn_screen_test.dart`
Expected: compile error.

- [ ] **Step 3: Extract the Tests section**

Create `app/lib/features/tests/tests_section.dart`. Move the classes `_CustomTestCard`, `_ProBadge` and `_MockPaperTile` **unchanged** from `tests_screen.dart` (lines 66–215) into it, with the same imports as `tests_screen.dart`. Add:

```dart
/// Tests, at the end of Learn: custom test (Pro) and mock papers (one
/// free, the rest Pro). No chapter tests exist yet.
class TestsSection extends ConsumerWidget {
  const TestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(studentProvider).isPro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tests', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTheme.space12),
        _CustomTestCard(isPro: isPro),
        const SizedBox(height: AppTheme.space20),
        Text('Mock papers', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTheme.space12),
        const _MockPaperTile(name: 'Mock Paper 1', locked: false, marks: 80, duration: '3 hrs'),
        const SizedBox(height: 10),
        _MockPaperTile(name: 'Mock Paper 2', locked: !isPro, marks: 80, duration: '3 hrs'),
        const SizedBox(height: 10),
        _MockPaperTile(name: 'Mock Paper 3', locked: !isPro, marks: 80, duration: '3 hrs'),
      ],
    );
  }
}
```

Reduce `tests_screen.dart` to its header row (title and the demo toggle) followed by `const TestsSection()`, and delete the moved classes from it. Task 16 deletes this file.

- [ ] **Step 4: Implement Learn**

`app/lib/features/learn/learn_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/chapter_progress.dart';
import '../../data/content.dart';
import '../../shared/widgets/course_chip.dart';
import '../../shared/widgets/mastery_ring.dart';
import '../chapter/chapter_screen.dart';
import '../tests/tests_section.dart';

/// Learn: course progress, the chapter in progress, chapters grouped by
/// the syllabus's units, then Tests (spec: "Learn").
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final course = ref.watch(courseProgressProvider);
    final pinned = course.current;
    final unitIds = Content.units.map((u) => u.id).toSet();
    final ungrouped = course.chapters.where((c) => !unitIds.contains(c.chapter.unitId)).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, AppTheme.space32),
          children: [
            const Align(alignment: Alignment.centerLeft, child: CourseChip()),
            const SizedBox(height: AppTheme.space12),
            Text('Learn', style: textTheme.headlineLarge),
            const SizedBox(height: AppTheme.space16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: course.fraction,
                minHeight: 10,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation(colors.brand),
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(course.summary, style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
            if (pinned != null) ...[
              const SizedBox(height: AppTheme.space24),
              Text(course.anyStarted ? 'In progress' : 'Start here', style: textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              ChapterRow(key: const ValueKey('pinned_chapter'), progress: pinned),
            ],
            for (final unit in Content.units)
              if (Content.chaptersInUnit(unit.id).isNotEmpty) ...[
                const SizedBox(height: AppTheme.space24),
                Text(
                  unit.marks == null ? unit.name : '${unit.name} · ${unit.marks} marks',
                  key: ValueKey('unit_${unit.id}'),
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.space8),
                for (final chapter in Content.chaptersInUnit(unit.id)) ...[
                  ChapterRow(key: ValueKey('chapter_row_${chapter.id}'), progress: course.chapter(chapter.id)!),
                  const SizedBox(height: AppTheme.space8),
                ],
              ],
            if (ungrouped.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space24),
              Text('More chapters', style: textTheme.titleLarge),
              const SizedBox(height: AppTheme.space8),
              for (final p in ungrouped) ...[
                ChapterRow(key: ValueKey('chapter_row_${p.chapter.id}'), progress: p),
                const SizedBox(height: AppTheme.space8),
              ],
            ],
            const SizedBox(height: AppTheme.space32),
            const TestsSection(),
          ],
        ),
      ),
    );
  }
}

class ChapterRow extends StatelessWidget {
  const ChapterRow({super.key, required this.progress});
  final ChapterProgress progress;

  static String statusLabel(ChapterProgress p) => switch (p.status) {
        ChapterStatus.soon => 'Soon',
        ChapterStatus.notStarted => 'Not started',
        ChapterStatus.inProgress => '${p.topicsDone} of ${p.topics.length} topics · In progress',
        ChapterStatus.complete => 'Complete',
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final soon = progress.status == ChapterStatus.soon;
    return Opacity(
      opacity: soon ? 0.45 : 1,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: soon
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ChapterScreen(chapterId: progress.chapter.id),
                  )),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Row(
              children: [
                MasteryRing(
                  progress: progress.fraction,
                  size: 44,
                  strokeWidth: 5,
                  animate: false,
                  child: Text('${(progress.fraction * 100).round()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(progress.chapter.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(statusLabel(progress), style: TextStyle(color: colors.inkFaint, fontSize: 12)),
                    ],
                  ),
                ),
                if (!soon) Icon(Icons.chevron_right_rounded, color: colors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests**

Run: `cd app && flutter test test/features/learn test/flow_smoke_test.dart`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/learn app/lib/features/tests app/test/features/learn
git commit -m "feat(app): Learn tab with course progress, pinned chapter, syllabus units and Tests"
```

---

### Task 15: The Home tab

**Files:**
- Create: `app/lib/features/home/home_screen.dart`
- Test: `app/test/features/home/home_screen_test.dart`

**Interfaces:**
- Consumes: `CourseChip`, `dailyProvider`, `DailyNotifier.clock`, `pickWorkoutConcepts`, `WorkoutKind`, `startKeepGoing`, `fadingConcepts`, `courseProgressProvider`, `openNextStep`, `nextStepPosition`.
- Produces: `HomeScreen()`. Keys: `workout_hero`, `continue_card`, `week_row`, `workout_done_row`, `needs_attention`.

- [ ] **Step 1: Write the failing test**

`app/test/features/home/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/daily_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/chapter/chapter_screen.dart';
import 'package:study_gym/features/home/home_screen.dart';
import 'package:study_gym/features/theory/lesson_screen.dart';
import 'package:study_gym/features/workout/workout_screen.dart';
import 'package:study_gym/shared/widgets/streak_flame.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

final today = DateTime(2026, 9, 30, 10); // a Wednesday

ProviderContainer _container({StudentState? student}) {
  final c = ProviderContainer(overrides: [
    if (student != null) studentProvider.overrideWith(() => SeededStudent(student)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void _workoutOn(ProviderContainer c, DateTime day, {int correct = 4}) {
  DailyNotifier.clock = () => day;
  c.read(dailyProvider.notifier).recordWorkout(
        questionIds: const [],
        correct: correct,
        total: 5,
        keepGoing: false,
        startedAt: day,
      );
  DailyNotifier.clock = () => today;
}

List<DayState> _week(WidgetTester tester) => tester.widget<WeekDotsRow>(find.byType(WeekDotsRow)).days;

void main() {
  setUp(() {
    loadSlice1Content();
    DailyNotifier.clock = () => today;
  });
  tearDown(() => DailyNotifier.clock = DateTime.now);

  for (final t in themes.entries) {
    testWidgets('before today\'s workout: the workout hero, week row, no Needs attention (${t.key})', (tester) async {
      await pumpScreen(tester, const HomeScreen(), theme: t.value);
      expect(find.text('Class 9 ▾'), findsOneWidget);
      expect(find.text('Start your streak'), findsOneWidget);
      expect(find.text('Start workout'), findsOneWidget);
      expect(find.textContaining('Arithmetic progressions'), findsOneWidget);
      expect(_week(tester), hasLength(7));
      expect(_week(tester)[2], DayState.today);
      expect(find.byKey(const ValueKey('needs_attention')), findsNothing);
      expect(find.byKey(const ValueKey('continue_card')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a live streak changes the title', (tester) async {
    final c = _container();
    _workoutOn(c, today.subtract(const Duration(days: 1)));
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('Keep your 1-day streak going'), findsOneWidget);
  });

  testWidgets('Start workout opens a 5-question workout', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
        find.descendant(of: find.byType(AppBar), matching: find.byType(LinearProgressIndicator)));
    expect(bar.value, closeTo(0.2, 1e-9));
  });

  testWidgets('after the workout: Continue replaces the hero; today\'s dot is done; the done row shows', (tester) async {
    final c = _container();
    _workoutOn(c, today);
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.byKey(const ValueKey('workout_hero')), findsNothing);
    expect(find.byKey(const ValueKey('continue_card')), findsOneWidget);
    expect(_week(tester)[2], DayState.done);
    expect(find.text('Daily workout · 4 / 5'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('workout_done_row')), matching: find.text('Keep going')), findsOneWidget);
  });

  testWidgets('no chapter started: suggests the first chapter and opens it', (tester) async {
    final c = _container();
    _workoutOn(c, today);
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('Start your first chapter'), findsOneWidget);
    expect(find.text('Sequences and Progressions'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterScreen), findsOneWidget);
  });

  testWidgets('Continue opens the next lesson directly', (tester) async {
    final c = _container();
    _workoutOn(c, today);
    await c.read(theoryProgressProvider.notifier).markRead('t_cube');
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('Continue your chapter'), findsOneWidget);
    expect(find.text('Topic 2 of 3'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('Cylinders'), findsOneWidget);
  });

  testWidgets('with every topic done, Continue goes straight into the next Trial level', (tester) async {
    final c = _container();
    _workoutOn(c, today);
    for (final id in ['t_cube', 't_cyl', 't_cone']) {
      await c.read(theoryProgressProvider.notifier).markRead(id);
    }
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('Trial level 1 of 10'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });

  testWidgets('Needs attention appears for fading topics and opens a review', (tester) async {
    final c = _container(
      student: StudentState(mastery: {
        'c.ap': ConceptMastery(
          conceptId: 'c.ap',
          masteryPercent: 90,
          attempts: 5,
          lastPracticed: today.subtract(const Duration(days: 6)),
        ),
      }),
    );
    await pumpScreen(tester, const HomeScreen(), container: c);
    expect(find.text('1 topic fading · Review'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('needs_attention')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `cd app && flutter test test/features/home/home_screen_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement Home**

`app/lib/features/home/home_screen.dart`. Move `_WhiteButton` **unchanged** from `today_screen.dart` (lines 247–308) to the bottom of this file. Then:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/chapter_progress.dart';
import '../../data/content.dart';
import '../../data/daily_state.dart';
import '../../data/fading.dart';
import '../../data/models.dart';
import '../../shared/widgets/course_chip.dart';
import '../../shared/widgets/streak_flame.dart';
import '../chapter/next_step_navigation.dart';
import '../workout/keep_going.dart';
import '../workout/workout_screen.dart';
import '../workout/workout_selector.dart';

/// Home: one big next step (spec: "Home"). Before today's workout the hero
/// is the Daily Workout; after it, Continue your chapter.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DailyNotifier.clock();
    final daily = ref.watch(dailyProvider);
    final student = ref.watch(studentProvider);
    final course = ref.watch(courseProgressProvider);
    final streak = daily.streakOn(now);
    final done = daily.workoutDoneOn(now);
    // Only topics a review can actually drill.
    final fading = fadingConcepts(student, now).where((c) => Content.practiceQuestions(c.id).isNotEmpty).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, AppTheme.space32),
          children: [
            Row(children: [const CourseChip(), const Spacer(), StreakFlame(count: streak)]),
            const SizedBox(height: AppTheme.space20),
            if (done)
              _ContinueCard(course: course)
            else
              _WorkoutHero(streak: streak, concepts: pickWorkoutConcepts(student)),
            const SizedBox(height: AppTheme.space20),
            _WeekCard(days: daily.weekOf(now)),
            if (done && daily.firstWorkoutOn(now) != null) ...[
              const SizedBox(height: AppTheme.space12),
              _WorkoutDoneRow(record: daily.firstWorkoutOn(now)!),
            ],
            if (fading.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space12),
              _NeedsAttention(concepts: fading),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({required this.streak, required this.concepts});
  final int streak;
  final List<Concept> concepts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('workout_hero'),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(color: colors.brand, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            streak > 0 ? 'Keep your $streak-day streak going' : 'Start your streak',
            style: textTheme.headlineMedium?.copyWith(color: colors.accentInk),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            concepts.isEmpty
                ? 'No practice questions are available yet.'
                : '5 questions · ${concepts.map((c) => c.name).join(', ')}',
            style: textTheme.bodyMedium?.copyWith(color: colors.accentInk.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: AppTheme.space20),
          _WhiteButton(
            label: 'Start workout',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => WorkoutScreen(concepts: concepts, kind: WorkoutKind.daily),
            )),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.course});
  final CourseProgress course;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final chapter = course.current;
    if (chapter == null) {
      return Container(
        key: const ValueKey('continue_card'),
        padding: const EdgeInsets.all(AppTheme.space24),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        child: Text('Nothing to continue yet.', style: textTheme.titleMedium),
      );
    }
    final step = chapter.nextStep;
    final position = nextStepPosition(chapter, step);
    return Container(
      key: const ValueKey('continue_card'),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(color: colors.brand, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chapter.isStarted ? 'Continue your chapter' : 'Start your first chapter',
            style: textTheme.titleMedium?.copyWith(color: colors.accentInk.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(chapter.chapter.name, style: textTheme.headlineMedium?.copyWith(color: colors.accentInk)),
          if (position.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space4),
            Text(position, style: textTheme.bodyMedium?.copyWith(color: colors.accentInk.withValues(alpha: 0.8))),
          ],
          const SizedBox(height: AppTheme.space20),
          _WhiteButton(label: 'Continue', onPressed: () => openNextStep(context, chapter, step)),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.days});
  final List<DayState> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: const ValueKey('week_row'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: WeekDotsRow(days: days),
    );
  }
}

class _WorkoutDoneRow extends ConsumerWidget {
  const _WorkoutDoneRow({required this.record});
  final WorkoutRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      key: const ValueKey('workout_done_row'),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
      decoration: BoxDecoration(color: colors.masteredLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.mastered),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text('Daily workout · ${record.correct} / ${record.total}',
                style: TextStyle(color: colors.masteredDark, fontWeight: FontWeight.w800)),
          ),
          TextButton(onPressed: () => startKeepGoing(context, ref), child: const Text('Keep going')),
        ],
      ),
    );
  }
}

class _NeedsAttention extends StatelessWidget {
  const _NeedsAttention({required this.concepts});
  final List<Concept> concepts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final n = concepts.length;
    return Material(
      color: colors.learningLight,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        key: const ValueKey('needs_attention'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WorkoutScreen(concepts: concepts))),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              Icon(Icons.refresh_rounded, color: colors.learningDark),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Text('$n ${n == 1 ? 'topic' : 'topics'} fading · Review',
                    style: TextStyle(color: colors.learningDark, fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.learningDark),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `cd app && flutter test test/features/home`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/home app/test/features/home
git commit -m "feat(app): Home with workout hero, Continue card, week row, done row and Needs attention"
```

---

### Task 16: The four-tab shell; History placeholder; Pro demo toggle in Me; remove the old tabs

**Files:**
- Modify: `app/lib/core/router/app_shell.dart`
- Create: `app/lib/features/history/history_screen.dart`
- Modify: `app/lib/features/me/me_screen.dart`
- Delete: `app/lib/features/today/today_screen.dart`, `app/lib/features/theory/theory_screen.dart`, `app/lib/features/mission/mission_list_screen.dart`, `app/lib/features/mission/mission_screen.dart`, `app/lib/features/tests/tests_screen.dart`
- Delete: `app/test/features/theory/theory_screen_test.dart`, `app/test/features/mission/mission_list_screen_test.dart`, `app/test/features/mission/mission_screen_test.dart` (their behaviour is covered by the Learn, chapter and Trial tests)
- Modify: `app/test/flow_smoke_test.dart`
- Modify: `app/test/features/me/me_screen_test.dart`
- Test: `app/test/core/app_shell_test.dart`

**Interfaces:**
- Consumes: `HomeScreen`, `LearnScreen`, `MeScreen`.
- Produces: `HistoryScreen()`.

- [ ] **Step 1: Write the failing tests**

`app/test/core/app_shell_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/router/app_shell.dart';
import 'package:study_gym/data/daily_state.dart';

import '../fixtures/slice1_content.dart';
import '../helpers/pump.dart';

void main() {
  setUp(() {
    loadSlice1Content();
    DailyNotifier.clock = () => DateTime(2026, 9, 30, 10);
  });
  tearDown(() => DailyNotifier.clock = DateTime.now);

  for (final t in themes.entries) {
    testWidgets('four tabs, each showing its screen (${t.key})', (tester) async {
      await pumpScreen(tester, const AppShell(), theme: t.value);

      for (final label in ['Home', 'Learn', 'History', 'Me']) {
        expect(find.text(label), findsWidgets, reason: 'tab $label');
      }
      for (final gone in ['Today', 'Theory', 'Mission']) {
        expect(find.text(gone), findsNothing, reason: '$gone is no longer a tab');
      }
      expect(find.text('Start workout'), findsOneWidget);

      await tester.tap(find.text('Learn').last);
      await tester.pumpAndSettle();
      expect(find.text('Mock papers'), findsOneWidget, reason: 'Tests live at the end of Learn');

      await tester.tap(find.text('History').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Coming soon'), findsOneWidget);

      await tester.tap(find.text('Me').last);
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
```

Append to `app/test/features/me/me_screen_test.dart`, inside `main` (add imports `package:flutter/material.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `package:study_gym/data/app_state.dart`, `package:study_gym/features/me/me_screen.dart` and `../../helpers/pump.dart` if missing):

```dart
  testWidgets('the Pro demo switch lives in Me', (tester) async {
    final container = await pumpScreen(tester, const MeScreen());
    expect(container.read(studentProvider).isPro, isFalse);
    await tester.tap(find.byKey(const ValueKey('pro_demo_switch')));
    await tester.pumpAndSettle();
    expect(container.read(studentProvider).isPro, isTrue);
  });
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `cd app && flutter test test/core/app_shell_test.dart test/features/me/me_screen_test.dart`
Expected: FAIL (old tabs still shown; no `pro_demo_switch`).

- [ ] **Step 3: Implement the shell, History and the Me toggle**

`app/lib/features/history/history_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// History tab placeholder. The map, timeline and stories come in Slice 3.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('History', style: textTheme.headlineLarge),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Where maths happened, told as short stories on a map. Coming soon.',
                style: textTheme.bodyLarge?.copyWith(color: context.colors.inkFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

In `app/lib/core/router/app_shell.dart`: replace the five feature imports with imports of `home_screen.dart`, `learn_screen.dart`, `history_screen.dart` and `me_screen.dart`. Update the doc comment to `/// The 4-tab bottom nav shell: Home · Learn · History · Me.` Then:

```dart
  static const _tabs = [
    _TabDef('Home', Icons.home_rounded, Icons.home_outlined),
    _TabDef('Learn', Icons.school_rounded, Icons.school_outlined),
    _TabDef('History', Icons.auto_stories_rounded, Icons.auto_stories_outlined),
    _TabDef('Me', Icons.person_rounded, Icons.person_outline_rounded),
  ];
```

and the `IndexedStack` children become `const [HomeScreen(), LearnScreen(), HistoryScreen(), MeScreen()]`.

In `app/lib/features/me/me_screen.dart`, add `import '../../data/app_state.dart';`. In `build`, add `final isPro = ref.watch(studentProvider).isPro;`, and after the Appearance container's `SizedBox(height: AppTheme.space16)` insert:

```dart
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: colors.border),
              ),
              child: SwitchListTile(
                key: const ValueKey('pro_demo_switch'),
                title: Text('Study Gym Pro (demo)', style: textTheme.titleMedium),
                subtitle: const Text('Payments are not built yet. This switch shows the Pro experience.'),
                value: isPro,
                onChanged: (_) => ref.read(studentProvider.notifier).togglePro(),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
```

- [ ] **Step 4: Delete the old tabs and their tests**

```bash
git rm app/lib/features/today/today_screen.dart app/lib/features/theory/theory_screen.dart \
  app/lib/features/mission/mission_list_screen.dart app/lib/features/mission/mission_screen.dart \
  app/lib/features/tests/tests_screen.dart \
  app/test/features/theory/theory_screen_test.dart app/test/features/mission/mission_list_screen_test.dart \
  app/test/features/mission/mission_screen_test.dart
```

Keep `lesson_screen.dart`, `custom_test_builder_screen.dart`, `theory_fixtures.dart` and `test_content.dart`; they're still used.

- [ ] **Step 5: Update the smoke test**

In `app/test/flow_smoke_test.dart`:

1. Replace `import 'test_content.dart';` with `import 'fixtures/slice1_content.dart';`. In `setUp`, set `StudyGymApp.contentLoader = () async => slice1Snapshot();`.
2. Replace the body of `'welcome -> today -> workout flow renders without exceptions'` (and rename it `'welcome -> home, then every tab'`) with:

```dart
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text('Sequences and Progressions'), findsWidgets);

    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    expect(find.text('History'), findsWidgets);

    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Start workout'), findsOneWidget);
```

3. In `'"I already have an account" also lands directly on the dashboard'`, change the expectation to `expect(find.text('Start workout'), findsOneWidget);`.
4. In `'custom test builder is reachable…'`, replace `await tester.tap(find.text('Tests').last);` with `await tester.tap(find.text('Learn').last);` followed by `await tester.pumpAndSettle();` and `await tester.scrollUntilVisible(find.text('Create a custom test'), 300);`. Keep the `'Custom test'` and chapter-name expectations; they still hold with the fixture (`Sequences and Progressions`, `Surface Area and Volume`). Replace the `'Surface Areas and Volumes'` text with `'Surface Area and Volume'`.

- [ ] **Step 6: Run the whole suite**

Run: `cd app && flutter analyze --no-fatal-infos && flutter test`
Expected: no analyzer errors or warnings (no dangling imports of deleted files) and all tests pass.

- [ ] **Step 7: Commit**

```bash
git add -A app
git commit -m "feat(app): Home · Learn · History · Me shell; Pro demo switch in Me; remove old tabs"
```

---

### Task 17: Theme sweep and full regression

**Files:** none new. Fixes only, if the checks below find something.

- [ ] **Step 1: No hard-coded colours in new code**

Run from the repo root:

```bash
grep -rnE "Color\(0x|Colors\.[a-z]" app/lib/features/home app/lib/features/learn app/lib/features/chapter \
  app/lib/features/trial app/lib/features/history app/lib/shared/widgets/course_chip.dart \
  app/lib/shared/widgets/pro_sheet.dart | grep -v "Colors.transparent" | grep -v "Colors.white"
```

Expected: no output. Replace any hit with a `context.colors` token.

- [ ] **Step 2: Every new screen has a light and dark test**

Run: `grep -ln "themes.entries" app/test -r`
Expected: `course_chip_test.dart`, `trial_screen_test.dart`, `chapter_screen_test.dart`, `learn_screen_test.dart`, `home_screen_test.dart`, `app_shell_test.dart`.

- [ ] **Step 3: Full regression**

```bash
cd app && flutter analyze --no-fatal-infos && flutter test
cd .. && python -m pytest content/pipeline/tests -q && python -m content.pipeline.validate
```

Expected: everything passes. Compare against the baseline from "Before you start": any failure that isn't on that list is this slice's to fix.

- [ ] **Step 4: Seeds still match their generators**

```bash
python -m content.pipeline.seed_mission && python -m content.pipeline.seed_course
git status --porcelain backend/supabase/seed
```

Expected: no output (the committed seeds are exactly what the generators write).

- [ ] **Step 5: Commit any fixes**

```bash
git add -A && git commit -m "chore(app): theme and regression fixes for Slice 1"
```

(Skip if nothing changed.)

---

## What this plan does not do

- **The live Supabase project is untouched.** Migration `20261001000000` and seed `007` must be applied to it separately, with the user's go-ahead (the 27 Sep "transaction + raise exception" dry run is the agreed way to rehearse it). Until then the app runs in its fallback mode: Learn is ungrouped, preview sheets have no "Why this comes next", topic-node passes aren't saved, and Platinum can't see solution viewing.
- **No topic questions or lessons are written.** Every topic uses the interim rule. The 8 chapters without lessons show "Lesson coming soon", and 6 chapters show "Soon".
- **The Trial shows the 48 live levels**, not 62, until the 14 `review` levels are verified.
- Served-question memory for Keep going lasts only while the app runs; after a restart it may repeat questions from earlier that day.
- Puzzle of the Day, History content, the Me redesign, onboarding, lesson building blocks, new question formats, payments and the Class 10 course are all out of scope.
- PLAN.md §3 and §5.3 still describe the old navigation and the 10-question workout (the spec leaves that edit for later).

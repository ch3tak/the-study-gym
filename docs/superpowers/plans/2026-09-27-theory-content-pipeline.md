# Theory Content Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the content-authoring and backend half of the Theory feature: a lesson YAML schema, a validator, a seed script, the Supabase migration for `lessons`/`theory_progress`, and a hand-authored pilot lesson set for the Surface Areas & Volumes chapter.

**Architecture:** Follows the existing question-content pipeline's shape exactly. A new `content/pipeline/types/lesson.py` module (standalone, not registered in the question-type `REGISTRY`, since lessons aren't questions) validates lesson dicts the same way `mcq.py` validates MCQ dicts. `content/pipeline/validate.py` gains a second pass that walks `*_theory.yaml` files. A new `content/pipeline/seed_theory.py` script, structurally identical to `seed_mission.py`, converts the lesson YAML into a SQL seed file. A new migration adds the two tables.

**Tech Stack:** Python 3.11, PyYAML, pytest (content pipeline); Postgres/Supabase SQL migrations.

**Spec:** `docs/superpowers/specs/2026-09-27-theory-content-and-tab-design.md`

## Global Constraints

- `id` for a lesson uses the `t_` prefix (mirrors `q_` for questions), e.g. `t_c9_sav_cuboid_cube`.
- `concept_id` must reference an existing concept in `content/syllabus/cbse/9/maths.yaml`.
- `hook_kind` is exactly `historical` or `real_world` — no other value.
- `id` must start with `t_` and be unique across **all** theory files (the `lessons` table's primary key is global, not per-chapter). Enforced by the validator and by `seed_theory.py`.
- `sort_order` must be an integer.
- `body`, `hook` and `try_it` are each capped at 400 characters (enforced by the validator) to keep lessons brief, per the spec's "one idea at a time" requirement.
- No text field may have leading/trailing whitespace. In YAML this means folded blocks use `>-`, never `>` (plain `>` keeps a trailing `\n` that would be stored in the database). The validator rejects it.
- `$...$` math delimiters in `body`/`hook`/`try_it` get a balanced-`$` check using `base.py`'s `_DOLLAR` regex. This is deliberately narrower than `base.check_latex` (which takes a question `Context` and also checks `\frac`/brace syntax that lesson prose doesn't use).
- Lesson text is student-facing: every historical or factual claim in a `hook` must be one you can back with a source. If you can't, write a `real_world` hook instead.
- The pilot covers exactly the 7 concepts of the `surface_area_volume` chapter: `c9.sav.cuboid_cube`, `c9.sav.cylinder`, `c9.sav.cone`, `c9.sav.pyramid`, `c9.sav.sphere_hemisphere`, `c9.sav.scaling`, `c9.sav.units`.
- Nothing in this plan touches `content/pipeline/generate.py`, `questions.py`, or the `REGISTRY` — lessons are a parallel, independent content type.

## Review Focus

- **A lesson referencing a concept_id that doesn't exist in the syllabus** — the validator must error, not silently pass (mirrors how `check_misconception` in `base.py` catches unknown misconception ids). Covered in Task 2.
- **A lesson body or hook exceeding the length cap** — must error with a message naming the field, not just fail silently or truncate. Covered in Task 2.
- **Two lessons sharing the same `id`, in the same file or in different theory files** — since `lessons` seeds via a plain `id text primary key`, a duplicate id would only surface as a Postgres insert failure at seed time, not at validate time; the validator and the seed script must both catch it earlier. Covered in Task 3 (`validate.py`, one id set across all files) and Task 4 (`seed_theory.py`).
- **A lesson with unbalanced `$` math delimiters in `body`, `hook`, or `try_it`** — the balanced-`$` check must run on all three fields, not just `body`. Covered in Task 2.
- **Trailing newlines from YAML `>` blocks** — would be stored verbatim in `lessons.body` etc. and render as stray blank lines. The validator must reject leading/trailing whitespace. Covered in Task 2.
- **The seed script's SQL ordering** — `lessons` rows reference `concept_id`, which must already exist (from `004_surface_area_volume_mission.sql`'s concept inserts) by the time `005_surface_area_volume_theory.sql` runs. CI never applies generated SQL to a real Postgres, so the pytest string checks can't prove this. Task 5 Step 6 applies the migrations and seeds to a real Postgres.
- **Factual accuracy of pilot hooks** — student-facing content; no invented history. Covered in Task 5.
- **`validate.py`'s existing question-file glob picking up `*_theory.yaml`** — `main()`'s `QUESTIONS_ROOT.glob("*/*/*/**/*.yaml")` matches every `.yaml` under `content/questions/`, including theory files once they exist (they live in the same directories as question banks). Left unfixed, a theory file would be fed into `validate_bank` as a malformed question bank. Covered in Task 3.

---

## File Structure

- Create: `content/pipeline/types/lesson.py` — `validate_lesson()` function + `MAX_FIELD_CHARS` constant.
- Modify: `content/pipeline/validate.py` — add a `validate_theory_files()` pass, wired into `main()`.
- Create: `content/pipeline/seed_theory.py` — mirrors `seed_mission.py`, generates the SQL seed.
- Create: `content/questions/cbse/9/maths/surface_area_volume_theory.yaml` — the 7 pilot lessons.
- Create: `backend/supabase/migrations/20260930000000_theory_lessons.sql` — `lessons` + `theory_progress` tables.
- Create: `backend/supabase/seed/005_surface_area_volume_theory.sql` — generated output (committed, like the existing `004_...sql`).
- Create: `content/pipeline/tests/test_lesson.py` — validator unit tests.
- Create: `content/pipeline/tests/test_seed_theory.py` — seed-script unit tests.
- Create: `content/pipeline/tests/fixtures/mini_theory.yaml` — fixture for the seed-script tests.
- Modify: `Makefile` — add a `seed-theory` target alongside `seed-mission`.

---

### Task 1: Migration for `lessons` and `theory_progress`

**Files:**
- Create: `backend/supabase/migrations/20260930000000_theory_lessons.sql`

**Interfaces:**
- Consumes: `concepts(id)` and `profiles(id)` from `backend/supabase/migrations/20260926000000_core_schema.sql`.
- Produces: `lessons` table (columns: `id text primary key`, `concept_id text`, `title text`, `body text`, `hook_kind text`, `hook text`, `try_it text` nullable, `sort_order smallint`) and `theory_progress` table (columns: `user_id uuid`, `lesson_id text`, `read_at timestamptz`, primary key `(user_id, lesson_id)`) — both tables later tasks' seed SQL and the Flutter repository (a separate plan) depend on these exact column names.

This task has no Python/Dart tests — Supabase migrations are verified by applying them to a real or local Postgres instance. If the project has a way to run migrations locally (check `Makefile` for a `supabase` or `migrate` target), use it; otherwise this task's "test" is a manual review against the existing migration files' patterns, which Task 4's SQL generation implicitly exercises (the generated `INSERT`s must reference columns this migration creates).

- [ ] **Step 1: Write the migration file**

```sql
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
```

- [ ] **Step 2: Check the file against the two existing migrations for pattern consistency**

Open `backend/supabase/migrations/20260929000000_mission_levels.sql` side by
side. Confirm: `begin;`/`commit;` wrapping (matches), RLS enabled + a single
`for all using (user_id = auth.uid())` policy on the progress table
(matches `level_progress`'s `own_level_progress` policy), a `select`-only
policy restricted `to authenticated` on the content table (matches
`read_questions` in `20260926000000_core_schema.sql` — lessons are
learning content like questions, not browse-before-signup metadata like
`read_concepts`).

- [ ] **Step 3: Commit**

```bash
git add backend/supabase/migrations/20260930000000_theory_lessons.sql
git commit -m "feat(db): add lessons and theory_progress tables"
```

---

### Task 2: Lesson validator

**Files:**
- Create: `content/pipeline/types/lesson.py`
- Test: `content/pipeline/tests/test_lesson.py`

**Interfaces:**
- Consumes: `Issues` from `content/pipeline/issues.py` (`.error(where, message)`, `.warn(where, message)`, `.errors`, `.warnings` — see `content/pipeline/issues.py:1-38`), the `_DOLLAR` regex from `content/pipeline/types/base.py:71` (not `check_latex` itself — it takes a question `Context`, not `Issues`, and checks `\frac`/brace syntax lesson prose doesn't need), `Syllabus` from `content/pipeline/syllabus.py` (`.concepts: dict[str, Concept]`).
- Produces: `validate_lesson(lesson: dict, syllabus: Syllabus, issues: Issues, where: str) -> None` — called once per lesson dict by the validator (Task 3), the seed script (Task 4) and its own tests. `MAX_FIELD_CHARS = 400` (module-level constant, importable for tests). Duplicate-id detection is **not** here — it needs to see every lesson at once, so it lives in the callers (Tasks 3 and 4).

- [ ] **Step 1: Write the failing tests**

Create `content/pipeline/tests/test_lesson.py`:

```python
"""Lesson validator tests — mirrors test_questions.py's shape but for the
theory content type (not a question type, so it isn't part of REGISTRY)."""

from content.pipeline.issues import Issues
from content.pipeline.types import REGISTRY
from content.pipeline.types.lesson import MAX_FIELD_CHARS, validate_lesson
from content.pipeline.syllabus import load, syllabus_path

VALID_LESSON = {
    "id": "t_c9_sav_cuboid_cube",
    "concept_id": "c9.sav.cuboid_cube",
    "title": "Cuboids & Cubes",
    "body": "A cuboid is a box shape: two matching ends, four flat sides, every corner square.",
    "hook_kind": "real_world",
    "hook": "Packaging designers work out a box's surface area to know how much cardboard to buy.",
    "try_it": "A shoebox is 30 cm long, 20 cm wide, 15 cm tall. Roughly how much cardboard covers it?",
    "sort_order": 1,
}


def syllabus():
    issues = Issues()
    syl = load(syllabus_path("cbse", 9, "maths"), issues, set(REGISTRY))
    assert issues.errors == []
    return syl


def messages(issues: Issues) -> str:
    return "\n".join(i.message for i in issues.errors)


def test_valid_lesson_is_clean():
    issues = Issues()
    validate_lesson(VALID_LESSON, syllabus(), issues, "test")
    assert issues.errors == []


def test_unknown_concept_id_is_caught():
    lesson = dict(VALID_LESSON, concept_id="c9.sav.not_a_real_concept")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "unknown concept" in messages(issues)


def test_missing_required_field_is_caught():
    lesson = dict(VALID_LESSON)
    del lesson["hook"]
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "missing field 'hook'" in messages(issues)


def test_invalid_hook_kind_is_caught():
    lesson = dict(VALID_LESSON, hook_kind="anecdote")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "hook_kind" in messages(issues)


def test_body_over_length_cap_is_caught():
    lesson = dict(VALID_LESSON, body="x" * (MAX_FIELD_CHARS + 1))
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "body" in messages(issues) and "characters" in messages(issues)


def test_hook_over_length_cap_is_caught():
    lesson = dict(VALID_LESSON, hook="x" * (MAX_FIELD_CHARS + 1))
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "hook" in messages(issues) and "characters" in messages(issues)


def test_unbalanced_dollar_in_body_is_caught():
    lesson = dict(VALID_LESSON, body="The area is $l \\times b square units.")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "math delimiters" in messages(issues)


def test_unbalanced_dollar_in_hook_is_caught():
    lesson = dict(VALID_LESSON, hook="A pyramid's base is $ 230 m wide.")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "math delimiters" in messages(issues)


def test_unbalanced_dollar_in_try_it_is_caught():
    lesson = dict(VALID_LESSON, try_it="If $l = 2 what is the area?")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "math delimiters" in messages(issues)


def test_try_it_is_optional():
    lesson = dict(VALID_LESSON)
    del lesson["try_it"]
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert issues.errors == []


def test_try_it_over_length_cap_is_caught():
    lesson = dict(VALID_LESSON, try_it="x" * (MAX_FIELD_CHARS + 1))
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "try_it" in messages(issues) and "characters" in messages(issues)


def test_id_without_t_prefix_is_caught():
    lesson = dict(VALID_LESSON, id="c9_sav_cuboid_cube")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "id: must start with 't_'" in messages(issues)


def test_non_integer_sort_order_is_caught():
    lesson = dict(VALID_LESSON, sort_order="1")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "sort_order" in messages(issues)


def test_trailing_newline_from_folded_yaml_is_caught():
    # A YAML `>` block (instead of `>-`) leaves a trailing "\n" on the value.
    lesson = dict(VALID_LESSON, body=VALID_LESSON["body"] + "\n")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "body" in messages(issues) and "whitespace" in messages(issues)
```

- [ ] **Step 2: Run tests to verify they fail**

Run (from repo root): `.venv/Scripts/python.exe -m pytest content/pipeline/tests/test_lesson.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'content.pipeline.types.lesson'`

- [ ] **Step 3: Write the validator**

Create `content/pipeline/types/lesson.py`:

```python
"""Theory lesson validator. Not a question type — lessons aren't part of
the question-type REGISTRY (content/pipeline/types/__init__.py) and never
go through validate_bank. This is a standalone check called by
validate.py's theory-file pass and by seed_theory.py before writing SQL.
"""

from __future__ import annotations

from .base import _DOLLAR
from ..issues import Issues
from ..syllabus import Syllabus

MAX_FIELD_CHARS = 400
ID_PREFIX = "t_"

_REQUIRED_FIELDS = {"id", "concept_id", "title", "body", "hook_kind", "hook", "sort_order"}
_OPTIONAL_FIELDS = {"try_it"}
_VALID_HOOK_KINDS = {"historical", "real_world"}


def _check_latex_field(text: str, label: str, where: str, issues: Issues) -> None:
    """Balanced-$ check only (lesson prose doesn't use \\frac or braces the
    way question stems do, so this is narrower than base.check_latex)."""
    if len(_DOLLAR.findall(text)) % 2:
        issues.error(where, f"{label}: unbalanced $ math delimiters")


def _check_text(value: object, label: str, where: str, issues: Issues) -> bool:
    """Non-empty string with no leading/trailing whitespace. Returns False if
    the value isn't usable text, so callers can skip further checks."""
    if not isinstance(value, str) or not value.strip():
        issues.error(where, f"{label}: must be non-empty text")
        return False
    if value != value.strip():
        issues.error(where, f"{label}: has leading/trailing whitespace (use `>-`, not `>`, for folded YAML text)")
    return True


def validate_lesson(lesson: dict, syllabus: Syllabus, issues: Issues, where: str) -> None:
    missing = _REQUIRED_FIELDS - lesson.keys()
    for key in sorted(missing):
        issues.error(where, f"missing field '{key}'")
    unknown = lesson.keys() - _REQUIRED_FIELDS - _OPTIONAL_FIELDS
    for key in sorted(unknown):
        issues.error(where, f"unknown field '{key}'")
    if missing:
        return

    lesson_id = lesson["id"]
    if not isinstance(lesson_id, str) or not lesson_id.startswith(ID_PREFIX):
        issues.error(where, f"id: must start with '{ID_PREFIX}', got '{lesson_id}'")

    sort_order = lesson["sort_order"]
    if not isinstance(sort_order, int) or isinstance(sort_order, bool):
        issues.error(where, f"sort_order: must be an integer, got {sort_order!r}")

    concept_id = lesson["concept_id"]
    if concept_id not in syllabus.concepts:
        issues.error(where, f"unknown concept '{concept_id}'")

    hook_kind = lesson["hook_kind"]
    if hook_kind not in _VALID_HOOK_KINDS:
        issues.error(where, f"hook_kind: must be one of {sorted(_VALID_HOOK_KINDS)}, got '{hook_kind}'")

    for field_name in ("body", "hook", "try_it"):
        value = lesson.get(field_name)
        if value is None and field_name in _OPTIONAL_FIELDS:
            continue
        if not _check_text(value, field_name, where, issues):
            continue
        if len(value) > MAX_FIELD_CHARS:
            issues.error(where, f"{field_name}: longer than {MAX_FIELD_CHARS} characters")
        _check_latex_field(value, field_name, where, issues)

    _check_text(lesson["title"], "title", where, issues)
```

- [ ] **Step 4: Run tests to verify they pass**

Run (from repo root): `.venv/Scripts/python.exe -m pytest content/pipeline/tests/test_lesson.py -v`
Expected: PASS (all 14 tests)

- [ ] **Step 5: Commit**

```bash
git add content/pipeline/types/lesson.py content/pipeline/tests/test_lesson.py
git commit -m "feat(pipeline): add theory lesson validator"
```

---

### Task 3: Wire the lesson validator into `validate.py`

**Files:**
- Modify: `content/pipeline/validate.py`

**Interfaces:**
- Consumes: `validate_lesson()` from Task 2; `load_all_syllabi()` (already defined at `content/pipeline/validate.py:48-58`); `yaml.safe_load` (already imported).
- Produces: `make pipeline-validate` (and bare `python -m content.pipeline.validate`) now also fails on bad theory YAML, which Task 5's pilot content must pass before it's considered done.

- [ ] **Step 1: Add a theory-file validation pass**

In `content/pipeline/validate.py`, add `from .types.lesson import validate_lesson`
to the imports (after line 20's `from .types import REGISTRY`), then add this
function after `load_all_syllabi` (after line 58):

```python
THEORY_ROOT = QUESTIONS_ROOT  # theory files live alongside question files, named *_theory.yaml


def validate_theory_files(syllabi: dict[tuple[str, int, str], Syllabus], issues: Issues) -> int:
    total = 0
    # One set across every file: lessons.id is a table-wide primary key.
    seen_ids: dict[str, str] = {}
    for path in sorted(THEORY_ROOT.glob("*/*/*/**/*_theory.yaml")):
        key = subject_of(path)
        if key is None or key not in syllabi:
            issues.error(rel(path), "can't resolve subject for theory file (expected board/class/subject layout)")
            continue
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        lessons = data.get("lessons") if isinstance(data, dict) else None
        if not isinstance(lessons, list):
            issues.error(rel(path), "theory file must have a top-level 'lessons:' list")
            continue
        for lesson in lessons:
            if not isinstance(lesson, dict):
                issues.error(rel(path), f"lesson entry is not a mapping: {lesson!r}")
                continue
            lesson_id = lesson.get("id", "<no id>")
            where = f"{rel(path)}:{lesson_id}"
            if lesson_id in seen_ids:
                issues.error(where, f"duplicate lesson id '{lesson_id}' (first seen in {seen_ids[lesson_id]})")
            else:
                seen_ids[lesson_id] = rel(path)
            validate_lesson(lesson, syllabi[key], issues, where)
            total += 1
    return total
```

Note: `subject_of` already strips the filename via `.parts[:3]` (see
`content/pipeline/validate.py:61-67`), so it works unchanged for
`*_theory.yaml` files since they live in the same
`content/questions/{board}/{class}/{subject}/` directories as question
files — `subject_of` only inspects the path, not the filename.

- [ ] **Step 2: Exclude `*_theory.yaml` from the question-file glob**

`main()`'s existing line 81 —
`files = args.files or sorted(QUESTIONS_ROOT.glob("*/*/*/**/*.yaml"))` —
matches every `.yaml` under `content/questions/`, which now includes
`*_theory.yaml` files (they live in the same
`content/questions/{board}/{class}/{subject}/` directories as question
banks). Left unfixed, the theory file would be fed into `load_file`/
`validate_band` as if it were a question bank and either error (no
`questions:` key) or silently contribute zero questions. Change line 81 to:

```python
    files = args.files or sorted(
        p for p in QUESTIONS_ROOT.glob("*/*/*/**/*.yaml") if not p.name.endswith("_theory.yaml")
    )
```

- [ ] **Step 3: Call `validate_theory_files` from `main()`**

In `main()`, after the existing question-validation loop (after line 100's
`validate_bank(questions, syllabi[key], issues)` call, before the `shown =`
line at 102), add:

```python
    lessons = validate_theory_files(syllabi, issues)
```

Then change the summary `print` (lines 107-110) so lessons are reported on
their own instead of being mixed into the question count:

```python
    print(
        f"\n{len(syllabi)} syllabi ({concepts} concepts), {total} questions, {lessons} lessons: "
        f"{len(issues.errors)} errors, {len(issues.warnings)} warnings"
    )
```

Check first whether any test or CI step parses this summary line
(`grep -rn "questions:" content/pipeline/tests .github`); if one does,
update it to match.

- [ ] **Step 4: Run the full validator against the (currently nonexistent) theory content**

Run (from repo root): `.venv/Scripts/python.exe -m content.pipeline.validate`
Expected: exits 0 and the summary line ends `..., 0 lessons: 0 errors, ...`
(no `*_theory.yaml` files exist yet, so the glob finds nothing — this
confirms the new code path doesn't break the existing validator run, and
the question count is the same as before this task).

- [ ] **Step 5: Run the full pytest suite to confirm nothing broke**

Run (from repo root): `.venv/Scripts/python.exe -m pytest content/pipeline/tests/ -v`
Expected: PASS (all existing tests plus the new `test_lesson.py` tests)

- [ ] **Step 6: Commit**

```bash
git add content/pipeline/validate.py
git commit -m "feat(pipeline): validate theory lesson files alongside questions, exclude them from question validation"
```

---

### Task 4: Seed script

**Files:**
- Create: `content/pipeline/seed_theory.py`
- Create: `content/pipeline/tests/fixtures/mini_theory.yaml`
- Test: `content/pipeline/tests/test_seed_theory.py`

**Interfaces:**
- Consumes: `validate_lesson()` from Task 2 (seed generation refuses to run on invalid content); the same `_sql_str`/`_jsonb`-style helpers pattern as `seed_mission.py` (not imported — this is a separate script, so it defines its own small helpers, matching `seed_mission.py`'s self-contained style).
- Produces: `generate_sql(theory_path: Path, syllabus_path: Path) -> str` — the function Task 5 (or a human) runs via `python -m content.pipeline.seed_theory` to produce `backend/supabase/seed/005_surface_area_volume_theory.sql`.

- [ ] **Step 1: Create the fixture**

Create `content/pipeline/tests/fixtures/mini_theory.yaml`:

```yaml
lessons:
  - id: t_mini_cuboid_cube
    concept_id: c9.sav.cuboid_cube
    title: "Cuboids & Cubes"
    body: "A cuboid is a box shape with six rectangular faces."
    hook_kind: historical
    hook: "Surveyors in ancient Egypt measured land areas after each Nile flood."
    try_it: "A shoebox is 30 cm long. Roughly how much cardboard covers it?"
    sort_order: 1
```

The tests pair this fixture with the **real** `content/syllabus/cbse/9/maths.yaml`,
not `fixtures/mini_syllabus.yaml`. `mini_syllabus.yaml` only works for
`seed_mission.py`, which reads the syllabus as raw YAML. `seed_theory.py`
runs the full `syllabus.load()`, and that rejects `mini_syllabus.yaml` with
15 schema errors (missing `board`, `class`, `schema_version`, concept
`description`, …), checked by running it. The real syllabus already
defines `c9.sav.cuboid_cube`, so no new syllabus fixture is needed.

- [ ] **Step 2: Write the failing tests**

Create `content/pipeline/tests/test_seed_theory.py`:

```python
from pathlib import Path

import pytest
import yaml

from content.pipeline.seed_theory import generate_sql

FIXTURE_YAML = Path(__file__).parent / "fixtures" / "mini_theory.yaml"
# Real syllabus, not fixtures/mini_syllabus.yaml: seed_theory runs the full
# syllabus.load(), which mini_syllabus.yaml (a raw-YAML fixture for
# seed_mission) doesn't satisfy.
FIXTURE_SYLLABUS = Path(__file__).resolve().parents[2] / "syllabus/cbse/9/maths.yaml"


def test_generates_insert_into_lessons():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert "insert into lessons" in sql
    assert "'t_mini_cuboid_cube'" in sql
    assert "'c9.sav.cuboid_cube'" in sql


def test_wraps_in_transaction():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert sql.strip().startswith("-- Generated")
    assert "begin;" in sql
    assert sql.strip().endswith("commit;")


def test_hook_kind_and_try_it_are_carried_through():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert "'historical'" in sql
    assert "Nile flood" in sql
    assert "Roughly how much cardboard" in sql


def test_duplicate_ids_refuse_to_seed(tmp_path):
    data = yaml.safe_load(FIXTURE_YAML.read_text(encoding="utf-8"))
    data["lessons"].append(dict(data["lessons"][0]))
    dup = tmp_path / "dup_theory.yaml"
    dup.write_text(yaml.safe_dump(data), encoding="utf-8")
    with pytest.raises(ValueError, match="duplicate lesson id"):
        generate_sql(dup, FIXTURE_SYLLABUS)


REAL_THEORY_YAML = Path(__file__).resolve().parents[2] / "questions/cbse/9/maths/surface_area_volume_theory.yaml"
REAL_SYLLABUS_YAML = Path(__file__).resolve().parents[2] / "syllabus/cbse/9/maths.yaml"


def test_real_theory_file_generates_seven_lessons():
    sql = generate_sql(REAL_THEORY_YAML, REAL_SYLLABUS_YAML)
    # Count row openers, not "(" — the column list and lesson prose
    # (e.g. "(the apex)") contain parentheses too.
    assert sql.count("\n  ('t_") == 7
```

Note: `test_real_theory_file_generates_seven_lessons` depends on Task 5's
pilot content existing — it will fail with `FileNotFoundError` until Task 5
is done. This is intentional (mirrors `test_seed_mission.py`'s
`test_real_mission_sql_has_tolerances_and_no_fraction_answers`, which
depends on the real mission YAML already existing). Mark it `xfail` for
now if the task runner insists on all-green between tasks; otherwise leave
it and let Task 5 turn it green.

- [ ] **Step 3: Run tests to verify they fail**

Run (from repo root): `.venv/Scripts/python.exe -m pytest content/pipeline/tests/test_seed_theory.py -v`
Expected: collection fails with `ModuleNotFoundError: No module
named 'content.pipeline.seed_theory'`, so all five tests error.

- [ ] **Step 4: Write the seed script**

Create `content/pipeline/seed_theory.py`:

```python
"""One-off script: reads a chapter's theory YAML plus its syllabus, and
writes a SQL seed file that inserts lesson rows into the `lessons` table
(20260930000000_theory_lessons.sql). Mirrors seed_mission.py's shape.

Run (from repo root): python -m content.pipeline.seed_theory
Writes: backend/supabase/seed/005_surface_area_volume_theory.sql
"""
from __future__ import annotations

import json
from pathlib import Path

import yaml

from .issues import Issues
from .syllabus import load as load_syllabus
from .types import REGISTRY
from .types.lesson import validate_lesson

REPO_ROOT = Path(__file__).resolve().parents[2]
THEORY_YAML = REPO_ROOT / "content/questions/cbse/9/maths/surface_area_volume_theory.yaml"
SYLLABUS_YAML = REPO_ROOT / "content/syllabus/cbse/9/maths.yaml"
OUTPUT_SQL = REPO_ROOT / "backend/supabase/seed/005_surface_area_volume_theory.sql"


def _sql_str(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def _sql_str_or_null(value: str | None) -> str:
    return "null" if value is None else _sql_str(value)


def _load_yaml(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def generate_sql(theory_path: Path, syllabus_path: Path) -> str:
    theory = _load_yaml(theory_path)
    lessons = theory["lessons"]

    issues = Issues()
    syllabus = load_syllabus(syllabus_path, issues, set(REGISTRY))
    if issues.errors:
        raise ValueError(f"syllabus failed to load: {issues.errors}")
    seen_ids: set[str] = set()
    for lesson in lessons:
        where = lesson.get("id", "<no id>")
        if where in seen_ids:
            issues.error(where, f"duplicate lesson id '{where}'")
        seen_ids.add(where)
        validate_lesson(lesson, syllabus, issues, where)
    if issues.errors:
        raise ValueError(f"lesson content invalid, refusing to seed: {issues.errors}")

    lines = [
        "-- Generated by content/pipeline/seed_theory.py — do not hand-edit.",
        "-- Seeds lesson rows for the surface_area_volume chapter's theory content.",
        "",
        "begin;",
        "",
        "insert into lessons (id, concept_id, title, body, hook_kind, hook, try_it, sort_order) values",
    ]

    rows = []
    for lesson in lessons:
        rows.append(
            "  (" + ", ".join([
                _sql_str(lesson["id"]),
                _sql_str(lesson["concept_id"]),
                _sql_str(lesson["title"]),
                _sql_str(lesson["body"]),
                _sql_str(lesson["hook_kind"]),
                _sql_str(lesson["hook"]),
                _sql_str_or_null(lesson.get("try_it")),
                str(lesson["sort_order"]),
            ]) + ")"
        )
    lines.append(",\n".join(rows) + ";")
    lines.append("")
    lines.append("commit;")
    lines.append("")

    return "\n".join(lines)


def main() -> None:
    sql = generate_sql(THEORY_YAML, SYLLABUS_YAML)
    OUTPUT_SQL.write_text(sql, encoding="utf-8")
    print(f"Wrote {OUTPUT_SQL}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 5: Run the fixture tests to verify they pass**

Run (from repo root): `.venv/Scripts/python.exe -m pytest content/pipeline/tests/test_seed_theory.py -v -k "not real_theory"`
Expected: PASS (4 tests; the real-file test still fails until Task 5)

- [ ] **Step 6: Add a Makefile target**

In `Makefile`, directly after the `seed-mission` target (lines 87-89), add:

```makefile
.PHONY: seed-theory
seed-theory:
	$(PYTHON) -m content.pipeline.seed_theory
```

(Recipe line must be indented with a tab, like the others.) The `help`
target lists targets by hand, so also add this line directly after line 35
(the `make seed-mission` echo), matching its column alignment:

```makefile
	@echo "  make seed-theory      Regenerate backend/supabase/seed/005_surface_area_volume_theory.sql"
```

- [ ] **Step 7: Commit**

```bash
git add content/pipeline/seed_theory.py content/pipeline/tests/test_seed_theory.py content/pipeline/tests/fixtures/mini_theory.yaml Makefile
git commit -m "feat(pipeline): add theory lesson seed script"
```

---

### Task 5: Pilot content — Surface Areas & Volumes theory YAML

**Files:**
- Create: `content/questions/cbse/9/maths/surface_area_volume_theory.yaml`

**Interfaces:**
- Consumes: `validate_lesson()` (Task 2) and `generate_sql()` (Task 4) both operate on this file once it exists.
- Produces: the 7 lesson rows that the seed SQL generated in Step 4 inserts, and that a later (separate) Flutter plan's `LessonScreen` renders.

- [ ] **Step 1: Write the 7 lessons**

Create `content/questions/cbse/9/maths/surface_area_volume_theory.yaml`.
Each lesson: brief body (one idea, plain language, technical terms
unpacked inline), one hook (historical or real-world), one optional
`try_it`. Concept descriptions/misconceptions are pulled from
`content/syllabus/cbse/9/maths.yaml:1104-1187` (already read during
planning) to keep lesson content technically aligned with what Mission
questions test.

Use the text below verbatim. Two rules apply to any edits:
- Folded text uses `>-`, never `>` (the validator rejects the trailing
  newline `>` leaves).
- Hooks are student-facing facts. The two `historical` hooks were checked
  during planning: the Moscow Mathematical Papyrus (c. 1850 BCE, problem 14,
  volume of a truncated square pyramid); the one-third rule's first proof
  credited to Eudoxus (per Archimedes); Galileo's bone-scaling argument in
  *Two New Sciences* (1638). Don't add a historical claim you can't source
  like this. Use a `real_world` hook instead.

```yaml
# Theory lessons for Surface Areas & Volumes (CBSE Class 9 Maths) — the
# Theory-tab pilot. One lesson per concept, matching the chapter's 7
# concepts in content/syllabus/cbse/9/maths.yaml. Seeded via
# content/pipeline/seed_theory.py into backend/supabase/seed/005_....sql.

lessons:
  - id: t_c9_sav_cuboid_cube
    concept_id: c9.sav.cuboid_cube
    title: "Cuboids & Cubes"
    body: >-
      A cuboid is a box shape: two matching ends, four flat sides, every
      corner a right angle. A cube is just a cuboid where all three
      sides — length, breadth, height — are equal.
    hook_kind: real_world
    hook: >-
      Every cardboard box starts as a flat sheet that gets folded up. To
      know how big that sheet must be, packaging designers add up the
      areas of the box's six faces — its total surface area.
    try_it: >-
      A shoebox is 30 cm long, 20 cm wide and 15 cm tall. Roughly how
      much cardboard wraps around it?
    sort_order: 1

  - id: t_c9_sav_cylinder
    concept_id: c9.sav.cylinder
    title: "Right Circular Cylinders"
    body: >-
      A cylinder is two identical circles joined by a curved side, like
      a tin can. "Curved surface" means just the tube part; "total
      surface" adds the two circular ends.
    hook_kind: real_world
    hook: >-
      Fizzy-drink cans are cylinders partly because a round wall spreads
      the gas pressure evenly. A box-shaped can would bulge at its flat
      sides and need thicker, heavier metal to stay in shape.
    try_it: >-
      A can is 10 cm tall with a 3.5 cm radius. Is more metal used for
      the curved side or the two circular ends?
    sort_order: 2

  - id: t_c9_sav_cone
    concept_id: c9.sav.cone
    title: "Right Circular Cones"
    body: >-
      A cone comes to a point above a circular base. Its "slant height"
      is the distance along the sloped surface from the tip to the edge
      of the base — not the same as the straight-up height through the
      middle.
    hook_kind: real_world
    hook: >-
      A cone holds exactly one-third as much as a cylinder with the same
      base and the same height. That's why a cone of ice cream holds less
      than it looks — most of the space is near the wide top.
    try_it: >-
      An ice-cream cone stands 12 cm tall with a 2.5 cm radius. Which
      distance — height or slant height — would you measure to know how
      much wafer covers the outside?
    sort_order: 3

  - id: t_c9_sav_pyramid
    concept_id: c9.sav.pyramid
    title: "Pyramids"
    body: >-
      A pyramid has a flat base and triangular faces that meet at one
      point (the apex). Its volume is one-third of the base area times
      the height — always a third, whatever the base shape.
    hook_kind: historical
    hook: >-
      An Egyptian scroll from about 1850 BCE, the Moscow Mathematical
      Papyrus, correctly works out the volume of a pyramid with its top
      cut off — one of the oldest volume calculations known. The first
      proof of the one-third rule is credited to the Greek mathematician
      Eudoxus, about 1,500 years later.
    sort_order: 4

  - id: t_c9_sav_sphere_hemisphere
    concept_id: c9.sav.sphere_hemisphere
    title: "Spheres & Hemispheres"
    body: >-
      A sphere is a perfectly round ball; a hemisphere is exactly half
      of one, like a bowl. A hemisphere's total surface counts the
      curved half plus the flat circular top — easy to forget the flat
      part.
    hook_kind: real_world
    hook: >-
      Soap bubbles are round because the soap film pulls itself as tight
      as it can, and of all shapes holding the same amount of air, a
      sphere has the smallest surface area.
    try_it: >-
      A bowl is half of a sphere with radius 7 cm. Does its total
      surface area include the flat circular rim on top, or just the
      curved inside?
    sort_order: 5

  - id: t_c9_sav_scaling
    concept_id: c9.sav.scaling
    title: "Changing Dimensions"
    body: >-
      Double every side of a shape and its surface area does not just
      double — it becomes four times as much, because area scales by
      the square of the size change. Volume becomes eight times as
      much, scaling by the cube.
    hook_kind: historical
    hook: >-
      In 1638 Galileo pointed out that an animal can't simply be scaled
      up. Double its size and its weight (set by volume) grows 8 times,
      but the strength of its bones (set by their cross-section area)
      grows only 4 times. That's why big animals need much thicker bones.
    try_it: >-
      A cube's side is doubled. Its old surface area was 24 cm². What's
      the new surface area?
    sort_order: 6

  - id: t_c9_sav_units
    concept_id: c9.sav.units
    title: "Units & Conversions"
    body: >-
      Area is measured in square units (cm²) and volume in cube units
      (cm³) — they are never interchangeable. For volume, 1 litre
      equals exactly 1000 cm³, which is the conversion used to move
      between everyday measurements and geometry.
    hook_kind: real_world
    hook: >-
      A 1-litre milk carton holds exactly as much as a hollow cube 10 cm
      on each side, because 1 litre is defined as 1000 cm³ and
      10 × 10 × 10 = 1000.
    try_it: >-
      A tank holds 5000 cm³ of water. How many litres is that?
    sort_order: 7
```

- [ ] **Step 2: Validate the new file**

Run (from repo root): `.venv/Scripts/python.exe -m content.pipeline.validate`
Expected: exits 0; the summary line shows the same question count as
before and `7 lessons`.

- [ ] **Step 3: Run the lesson validator's own tests plus the real-file seed test**

Run (from repo root): `.venv/Scripts/python.exe -m pytest content/pipeline/tests/test_lesson.py content/pipeline/tests/test_seed_theory.py -v`
Expected: PASS — all tests including `test_real_theory_file_generates_seven_lessons`
(now that the file exists, this test that was expected to fail in Task 4
should pass).

- [ ] **Step 4: Generate the seed SQL**

Run (from repo root): `.venv/Scripts/python.exe -m content.pipeline.seed_theory`
Expected output: `Wrote <repo_root>/backend/supabase/seed/005_surface_area_volume_theory.sql`

- [ ] **Step 5: Review the generated SQL file**

Open `backend/supabase/seed/005_surface_area_volume_theory.sql`. Confirm:
7 row tuples in the `insert into lessons` statement, each `concept_id`
matches one of the 7 syllabus concept ids, `hook_kind` values are exactly
`'historical'` or `'real_world'`, `try_it` is `null` only for the pyramid
lesson (the one lesson above with no `try_it` field), and no string literal
ends in a line break before its closing `'`.

- [ ] **Step 6: Apply the migrations and seeds to a real Postgres**

CI never applies generated SQL to a database, so the pytest string checks
above can't prove the SQL actually runs: that FK targets exist, that
`005` runs after `004`'s concept inserts, and that the `check` constraint
accepts every `hook_kind`. Apply, in order, to a disposable Supabase database
(the migrations use `auth.uid()` and other Supabase-provided objects, so
plain Postgres needs stubs):

1. every file in `backend/supabase/migrations/` in filename order, ending
   with `20260930000000_theory_lessons.sql`;
2. every file in `backend/supabase/seed/` in filename order, `001` → `005`.

Ways to do this: `supabase start` + `supabase db reset` (needs Docker and
the Supabase CLI), a throwaway branch/project via the Supabase MCP, or
pasting the files into a dev project's SQL editor. As of planning, this
machine has neither `psql` nor Docker, and the Supabase MCP needs
authorizing first. **If none of these is available, stop and ask the user.
Don't skip this step silently or mark Task 5 done without it.**

Expected: every file applies with no error, and
`select count(*) from lessons where concept_id like 'c9.sav.%'` returns 7.

- [ ] **Step 7: Run the full pipeline pytest suite**

Run (from repo root): `.venv/Scripts/python.exe -m pytest content/pipeline/tests/ -v`
Expected: PASS (every existing test plus all new lesson/seed-theory tests)

- [ ] **Step 8: Commit**

```bash
git add content/questions/cbse/9/maths/surface_area_volume_theory.yaml backend/supabase/seed/005_surface_area_volume_theory.sql
git commit -m "feat(content): add Surface Areas & Volumes theory lessons"
```

---

## Self-Review Notes

**Spec coverage:** Lesson YAML schema (Task 5), pipeline validator module
(Task 2), `validate.py` wiring (Task 3), seed script (Task 4), migration
(Task 1) — every backend/content-pipeline item in the spec's "Content
schema", "Database schema", and pipeline-module sections has a task. The
spec's Flutter-side items (data layer, `TheoryScreen`, `LessonScreen`, tab
restructuring) are explicitly out of scope for this plan per the
brainstorm's two-plan split and belong to a second plan.

**Placeholder scan:** No TBD/TODO; every step has real code or an exact
command.

**Type consistency:** `validate_lesson(lesson: dict, syllabus: Syllabus,
issues: Issues, where: str)` signature is identical across Task 2 (where
it's defined and tested) and Task 3/Task 4 (where it's called). Column
names in Task 1's migration (`id`, `concept_id`, `title`, `body`,
`hook_kind`, `hook`, `try_it`, `sort_order`) match the INSERT column list
in Task 4's `generate_sql`.

**Review Focus coverage:** unknown concept_id (Task 2 test), length caps
on body/hook/try_it (Task 2 tests), duplicate lesson ids across all files
(Task 3's `validate_theory_files` + Task 4's `generate_sql` and its
`test_duplicate_ids_refuse_to_seed`), unbalanced `$` in all three text
fields (Task 2 tests), trailing whitespace from YAML `>` (Task 2 test),
seed/migration ordering (Task 5 Step 6, applied to a real database),
factual accuracy of hooks (Task 5 Step 1 sourcing rule), and the
question-glob/theory-file collision in `validate.py`'s `main()` (Task 3
Step 2).

**Fixes made during self-review:** `syllabus.load()`'s `known_types`
parameter was initially passed `set()` in both Task 2's test helper and
Task 4's `seed_theory.py`; this would make every concept's
`default_question_types`/`question_types_allowed` register as "unknown
question type" errors against the real `cbse/9/maths.yaml` syllabus (which
does declare them), so both now pass `set(REGISTRY)` instead — verified
against `content/pipeline/syllabus.py:144`. Also caught and fixed:
`validate.py`'s existing question-file glob would silently swallow
`*_theory.yaml` files once they exist, feeding them into `validate_bank`
as malformed question banks; Task 3 now excludes `_theory.yaml` names
before that loop runs. All `Run:` commands were also corrected from an
invalid `cd content && python -m pipeline.X` form to the verified working
form (`.venv/Scripts/python.exe -m content.pipeline.X`, run from the repo
root), confirmed by actually running `content/pipeline/tests/test_seed_mission.py`
and `content/pipeline/validate.py` against this repo during planning.

**Fixes from the second review:**
- `test_real_theory_file_generates_seven_lessons` counted `(` characters,
  which would have included the column list and parentheses in lesson
  prose (10, not 7). It now counts row openers.
- The pilot YAML used `>`, which stores a trailing `\n` in every field.
  It now uses `>-`, and the validator rejects leading/trailing whitespace.
- Several hooks made unsupported or wrong claims: Giza's builders using the
  one-third rule, "Egyptian arithmetic" on casing stones, a made-up
  cone-material principle, and "leg surface area" where the real reason is
  cross-section area. These were rewritten with sourced facts.
- Task 4's tests paired the fixture with `mini_syllabus.yaml`, which
  `syllabus.load()` rejects. All four fixture tests failed when the plan's
  code was run in a scratch copy of the repo. They now use the real syllabus.
- Duplicate-id detection was per-file and missing from the seed script.
  It is now global and in both places.
- Added `t_` prefix and integer `sort_order` checks.
- `read_lessons` is now `to authenticated`, matching the migration comment
  and `read_questions`.
- Dropped the unused `GENERIC_MISCONCEPTIONS` re-export.
- Lesson count is now reported separately from questions in the
  validator summary.
- Added the `seed-theory` Makefile target and a real-Postgres apply step.

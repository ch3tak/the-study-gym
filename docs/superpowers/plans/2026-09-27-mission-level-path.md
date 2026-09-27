# Mission Level Path Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a student open the Surface Areas & Volumes chapter, play through all 62 hand-authored mission levels in a locked/unlocked/complete node path (including 20 `case_based` multi-part levels), with completion persisted per-student in Supabase.

**Architecture:** Extend the existing Supabase `questions` table with nullable `level`/`stage` columns (existing rows unaffected) and a new `body.parts` array for `case_based` rows. Add a `level_progress` table (same RLS shape as `concept_mastery`/`streaks`). Seed the 62-level YAML via a one-off Python script into a new SQL seed file. On the Flutter side: extend `Question`/`ContentRepository` to parse `level`/`stage`/`parts`/`conceptIds`; add a `LevelProgressRepository`/`levelProgressProvider` pair mirroring `StudentRepository`/`studentProvider`; add a `_CaseBasedParts` widget reusing `_McqOptions`/`_NumericInput`; add a `WorkoutScreen.singleLevel` constructor; add a new `MissionScreen`; wire a "Start Mission" entry point into `SkillMapScreen`.

**Tech Stack:** Flutter (Riverpod `Notifier`/`NotifierProvider`), Supabase (Postgres + RLS), Python (seed generation script, existing `content/pipeline` conventions), `pytest` (pipeline, untouched), `flutter test` (new unit/widget tests).

**Spec:** `docs/superpowers/specs/2026-09-27-mission-level-path-design.md`

## Global Constraints

- No changes to the content pipeline or `surface_area_volume.yaml` itself (spec Non-goals) — the seed script only *reads* them.
- No changes to the mastery engine's math in `app_state.dart`'s `recordAttempt` (spec Non-goals) — level completion is tracked in a separate table; a level's parts still call `recordAttempt` exactly as any other question does today.
- `subject_id` for every new `questions` row is `cbse_9_maths` (confirmed from `backend/supabase/seed/001_cbse_9_maths_science.sql:23`, NOT `cbse_9_maths_standard` as an earlier draft guessed).
- The `surface_area_volume` chapter and its 7 `c9.sav.*` concepts do **not** exist yet in any seed file (confirmed: no match for `surface_area_volume`/`sav` in `003_m9_remaining_chapters.sql`) — the new seed file must insert the chapter and concept rows before the question rows.
- Existing per-concept practice (`_ConceptRow`'s "Practice" button in `skill_map_screen.dart`, pushing `WorkoutScreen(concepts: [concept])`) must remain untouched — the mission path is additive.
- Every new `Question`/model field must have a safe default so no existing construction call site breaks (spec §3).
- RLS on the new `level_progress` table must follow the exact `own_<table>` pattern already used for `concept_mastery`/`streaks` (`enable row level security` + one `for all using (user_id = auth.uid()) with check (user_id = auth.uid())` policy).

## Review Focus

- **A level whose `body.parts` is empty or missing for a `case_based` row** (malformed seed data, or a future hand-edit) — `_questionFromRow` must not crash the whole content load; it should either skip that question or throw a clear, contained error, not silently render 0 parts as "complete". Covered in Task 3's parsing test.
- **A student who has completed level N but *not* level N-1** (e.g. seed/test data inserted out of order, or a future retry/reset flow) — `isUnlocked` must key off "is level N-1 in the completed set", not "is N-1 ≤ highest completed level", so completion is not assumed contiguous. Covered in Task 6's unlock-logic tests.
- **A case_based level where some parts are correct and others aren't** — must count as incorrect overall (spec §6 `_isCorrect`), not partially-correct or first-part-only. Covered in Task 9's table-driven grading tests.
- **A chapter with mission content that has zero completed levels for a brand-new student** (first ever visit to `MissionScreen`) — only level 1 unlocked, all 61 others locked, and this must render without crashing on an empty `level_progress` result set. Covered in Task 6 and Task 10's widget test.
- **A question whose `concept_ids` array has more than one entry reaching `_submit`'s mastery recording** — every concept in the list must get its own `recordAttempt` call (not just first), including for a `case_based` level whose combined `conceptIds` spans concepts from multiple parts. Covered in Task 9.

---

## File Structure

**New files:**
- `content/pipeline/seed_mission.py` — reads the mission YAML + syllabus YAML, writes the seed SQL.
- `backend/supabase/seed/004_surface_area_volume_mission.sql` — generated output (checked in, like other seed files).
- `backend/supabase/migrations/20260929000000_mission_levels.sql` — schema migration.
- `app/lib/data/level_progress_repository.dart` — Supabase reads/writes for `level_progress`.
- `app/lib/data/mission_state.dart` — `LevelProgressState`, `LevelProgressNotifier`, `levelProgressProvider`.
- `app/lib/features/mission/mission_screen.dart` — the level path UI.
- `app/test/data/level_progress_test.dart` — unlock logic unit tests.
- `app/test/features/mission/mission_screen_test.dart` — widget test.

**Modified files:**
- `app/lib/data/models.dart` — `QuestionType.caseBased`/`.expression`, `Question.level`/`.stage`/`.parts`/`.conceptIds`, new `LevelProgress` model.
- `app/lib/data/content_repository.dart` — select `level, stage`; parse `case_based` via recursive `_questionFromRow` over `body['parts']`.
- `app/lib/data/content.dart` — no signature change (per spec), but verify `forChapter` still works once level-tagged rows exist.
- `app/lib/features/workout/question_card.dart` — new `_CaseBasedParts` widget + branch.
- `app/lib/features/workout/workout_screen.dart` — `_WorkoutItem` gains per-part state; `_isCorrect`/`_submit` gain case_based branches; new `WorkoutScreen.singleLevel` constructor.
- `app/lib/features/skill_map/skill_map_screen.dart` — conditional "Start Mission" button.
- `app/test/data/content_repository_test.dart` (new fixture file, since none exists today) — case_based round-trip test.

---

## Task 1: Supabase migration — level/stage columns and `level_progress` table

**Files:**
- Create: `backend/supabase/migrations/20260929000000_mission_levels.sql`

**Interfaces:**
- Produces: `questions.level` (`smallint`, nullable), `questions.stage` (`text`, nullable), table `level_progress(user_id, chapter_id, level, completed_at, score)` with RLS policy `own_level_progress`. Later tasks (seed script, `LevelProgressRepository`) depend on these exact names/types.

- [ ] **Step 1: Write the migration file**

```sql
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
```

- [ ] **Step 2: Verify the migration applies cleanly**

Run (from `backend/supabase/`): `supabase db reset` (local dev stack) or, if no local Supabase stack is running, `supabase migration list` to confirm the file is picked up in order after `20260928000000_m9_maths_remaining_chapters.sql`.
Expected: migration runs with no errors; `level_progress` and the two new `questions` columns exist.

- [ ] **Step 3: Commit**

```bash
git add backend/supabase/migrations/20260929000000_mission_levels.sql
git commit -m "feat(db): add mission level/stage columns and level_progress table"
```

---

## Task 2: Seed script — YAML to SQL

**Files:**
- Create: `content/pipeline/seed_mission.py`
- Create (generated, but checked in): `backend/supabase/seed/004_surface_area_volume_mission.sql`
- Test: `content/pipeline/tests/test_seed_mission.py`

**Interfaces:**
- Consumes: `content/questions/cbse/9/maths/surface_area_volume.yaml` (`questions:` list, each with `id`, `concepts`, `difficulty`, `type`, `marks`, `level`, `stage`, `stem`, plus type-specific fields, plus `verification` for machine-checked ones, plus `parts` for `case_based`); `content/syllabus/cbse/9/maths.yaml`'s `surface_area_volume` chapter block (7 `c9.sav.*` concepts, confirmed present).
- Produces: `backend/supabase/seed/004_surface_area_volume_mission.sql`, a single transaction that (a) inserts the `surface_area_volume` chapter row and its 7 concept rows, (b) inserts 62 `questions` rows with `level`/`stage`/`body` (including `parts` for case_based), using `subject_id = 'cbse_9_maths'`.

- [ ] **Step 1: Write the failing test — chapter/concept rows are emitted first, in the syllabus's order**

```python
# content/pipeline/tests/test_seed_mission.py
import re
from pathlib import Path

from pipeline.seed_mission import generate_sql

FIXTURE_YAML = Path(__file__).parent / "fixtures" / "mini_mission.yaml"
FIXTURE_SYLLABUS = Path(__file__).parent / "fixtures" / "mini_syllabus.yaml"


def test_chapter_and_concepts_precede_questions():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    chapter_pos = sql.index("insert into chapters")
    concepts_pos = sql.index("insert into concepts")
    questions_pos = sql.index("insert into questions")
    assert chapter_pos < concepts_pos < questions_pos
    assert "'surface_area_volume'" in sql
    assert "'c9.sav.cuboid_cube'" in sql


def test_uses_confirmed_subject_id():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert "'cbse_9_maths'" in sql
    assert "cbse_9_maths_standard" not in sql
```

Create the two fixture files it needs:

```yaml
# content/pipeline/tests/fixtures/mini_mission.yaml
questions:
  - id: q_mini_l001
    concepts: [c9.sav.cuboid_cube]
    difficulty: 1
    type: mcq
    marks: 1
    level: 1
    stage: FOUNDATION
    stem: "Which edge is the breadth?"
    options: ["A", "B", "C", "D"]
    answer: 0
    hints: ["hint one"]
    solution_steps: ["step one"]

  - id: q_mini_l002
    concepts: [c9.sav.cuboid_cube]
    difficulty: 2
    type: case_based
    marks: 2
    level: 2
    stage: FOUNDATION
    stem: "A cube has side 6 cm. Answer both parts."
    parts:
      - type: numeric
        marks: 1
        stem: "Find the volume."
        answers: ["216"]
        unit: "cm^3"
        solution_steps: ["Volume = 216 cm^3"]
      - type: numeric
        marks: 1
        stem: "Find the surface area."
        answers: ["216"]
        unit: "cm^2"
        solution_steps: ["TSA = 216 cm^2"]
        verification:
          sympy: "6*6**2"
```

```yaml
# content/pipeline/tests/fixtures/mini_syllabus.yaml
chapters:
  - id: surface_area_volume
    name: "Mensuration: Surface Area and Volume"
    board_weight_marks: 6
    concepts:
      - id: c9.sav.cuboid_cube
        name: Cuboids and cubes
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd content && ../.venv/Scripts/python.exe -m pytest pipeline/tests/test_seed_mission.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'pipeline.seed_mission'`

- [ ] **Step 3: Write `seed_mission.py`**

```python
"""One-off script: reads the 62-level Surface Areas & Volumes mission YAML
plus the cbse/9/maths syllabus, and writes a SQL seed file that inserts the
chapter/concepts (not yet present in any seed file) and the 62 questions
(with level/stage/parts) into Supabase.

Run: python content/pipeline/seed_mission.py
Writes: backend/supabase/seed/004_surface_area_volume_mission.sql
"""
from __future__ import annotations

import io
import json
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
MISSION_YAML = REPO_ROOT / "content/questions/cbse/9/maths/surface_area_volume.yaml"
SYLLABUS_YAML = REPO_ROOT / "content/syllabus/cbse/9/maths.yaml"
OUTPUT_SQL = REPO_ROOT / "backend/supabase/seed/004_surface_area_volume_mission.sql"

# Confirmed against backend/supabase/seed/001_cbse_9_maths_science.sql:23 —
# do not change without re-checking the actual seeded subject_id.
SUBJECT_ID = "cbse_9_maths"
CHAPTER_ID = "surface_area_volume"


def _sql_str(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def _sql_array(values: list[str]) -> str:
    return "array[" + ", ".join(_sql_str(v) for v in values) + "]"


def _jsonb(value) -> str:
    return f"'{json.dumps(value)}'::jsonb"


def _load_yaml(path: Path) -> dict:
    with io.open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def _chapter_block(syllabus: dict) -> dict:
    for chapter in syllabus["chapters"]:
        if chapter["id"] == CHAPTER_ID:
            return chapter
    raise ValueError(f"Chapter {CHAPTER_ID!r} not found in syllabus")


def _is_machine_verified(question: dict) -> bool:
    """A question counts as machine-verified only if every gradable part
    (itself, or every part of a case_based question) carries a
    `verification` block — matching the app's trust rule that unverified
    content needs human sign-off before going live."""
    if question.get("type") == "case_based":
        parts = question.get("parts", [])
        return bool(parts) and all("verification" in p for p in parts)
    return "verification" in question


def _body_for_part(part: dict) -> dict:
    body: dict = {"stem": part["stem"]}
    if part["type"] == "mcq":
        body["options"] = part["options"]
        body["correctIndex"] = part["answer"]
        if "distractors" in part:
            body["distractors"] = [
                {"optionIndex": int(idx), "explanation": misconception}
                for idx, misconception in part["distractors"].items()
            ]
    elif part["type"] == "numeric":
        body["numericAnswer"] = part["answers"][0]
        body["unit"] = part.get("unit", "none")
    body["hints"] = part.get("hints", [])
    body["solutionSteps"] = part.get("solution_steps", [])
    body["marks"] = part["marks"]
    body["type"] = part["type"]
    body["concept_ids"] = question["concepts"]
    return body


def _body_for_question(question: dict) -> dict:
    body: dict = {"stem": question["stem"]}
    qtype = question["type"]
    if qtype == "mcq":
        body["options"] = question["options"]
        body["correctIndex"] = question["answer"]
        if "distractors" in question:
            body["distractors"] = [
                {"optionIndex": int(idx), "explanation": misconception}
                for idx, misconception in question["distractors"].items()
            ]
    elif qtype == "numeric":
        body["numericAnswer"] = question["answers"][0]
        body["unit"] = question.get("unit", "none")
    elif qtype == "case_based":
        body["parts"] = [_body_for_part(p) for p in question["parts"]]
    body["hints"] = question.get("hints", [])
    body["solutionSteps"] = question.get("solution_steps", [])
    return body


def generate_sql(mission_path: Path, syllabus_path: Path) -> str:
    mission = _load_yaml(mission_path)
    syllabus = _load_yaml(syllabus_path)
    chapter = _chapter_block(syllabus)

    lines = [
        "-- Generated by content/pipeline/seed_mission.py — do not hand-edit.",
        "-- Seeds the surface_area_volume chapter/concepts (new — not present",
        "-- in any earlier seed file) and its 62 mission-sequenced questions.",
        "",
        "begin;",
        "",
        "insert into chapters (id, subject_id, name, board_weight, sort_order) values",
        f"  ({_sql_str(chapter['id'])}, {_sql_str(SUBJECT_ID)}, {_sql_str(chapter['name'])}, "
        f"{chapter['board_weight_marks']}, 6);",
        "",
        "insert into concepts (id, chapter_id, name, sort_order) values",
    ]

    concept_rows = []
    for i, concept in enumerate(chapter["concepts"], start=1):
        concept_rows.append(
            f"  ({_sql_str(concept['id'])}, {_sql_str(chapter['id'])}, "
            f"{_sql_str(concept['name'])}, {i})"
        )
    lines.append(",\n".join(concept_rows) + ";")
    lines.append("")

    lines.append(
        "insert into questions (id, subject_id, concept_ids, difficulty, type, "
        "marks, level, stage, body, status, content_version) values"
    )

    question_rows = []
    for q in mission["questions"]:
        status = "live" if _is_machine_verified(q) else "review"
        body = _body_for_question(q)
        question_rows.append(
            "  (" + ", ".join([
                _sql_str(q["id"]),
                _sql_str(SUBJECT_ID),
                _sql_array(q["concepts"]),
                str(q["difficulty"]),
                _sql_str(q["type"]),
                str(q["marks"]),
                str(q["level"]),
                _sql_str(q["stage"]),
                _jsonb(body),
                _sql_str(status),
                "1",
            ]) + ")"
        )
    lines.append(",\n".join(question_rows) + ";")
    lines.append("")
    lines.append("commit;")
    lines.append("")

    return "\n".join(lines)


def main() -> None:
    sql = generate_sql(MISSION_YAML, SYLLABUS_YAML)
    OUTPUT_SQL.write_text(sql, encoding="utf-8")
    print(f"Wrote {OUTPUT_SQL}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd content && ../.venv/Scripts/python.exe -m pytest pipeline/tests/test_seed_mission.py -v`
Expected: PASS (2 tests)

- [ ] **Step 5: Generate the real seed file and sanity-check row counts**

Run: `cd content && ../.venv/Scripts/python.exe pipeline/seed_mission.py`
Then: `grep -c "^  (" backend/supabase/seed/004_surface_area_volume_mission.sql` — expect 7 concept rows + 62 question rows to appear once each across the file (spot-check by eye; exact grep count will include the chapter row's own line too, so don't assert an exact number here — just confirm the file was written and `wc -l` is in the low hundreds, not near-empty).
Expected: file exists, contains `'surface_area_volume'`, `'cbse_9_maths'`, and 62 `q_c9_sav_l0XX` ids.

- [ ] **Step 6: Run the full pipeline test suite to confirm nothing else broke**

Run: `cd content && ../.venv/Scripts/python.exe -m pytest -v`
Expected: PASS, same green baseline as before (this task adds tests, doesn't touch pipeline code the existing suite covers).

- [ ] **Step 7: Commit**

```bash
git add content/pipeline/seed_mission.py content/pipeline/tests/test_seed_mission.py content/pipeline/tests/fixtures/mini_mission.yaml content/pipeline/tests/fixtures/mini_syllabus.yaml backend/supabase/seed/004_surface_area_volume_mission.sql
git commit -m "feat(content): add seed_mission.py generating the mission's SQL seed"
```

---

## Task 3: Flutter data model — `QuestionType.caseBased`, `Question.level/stage/parts/conceptIds`, `LevelProgress`

**Files:**
- Modify: `app/lib/data/models.dart`
- Test: `app/test/data/models_test.dart`

**Interfaces:**
- Produces: `QuestionType.caseBased`, `QuestionType.expression`; `Question.level` (`int?`), `Question.stage` (`String?`), `Question.parts` (`List<Question>`, default `const []`), `Question.conceptIds` (`List<String>`, defaults to `[conceptId]`); `LevelProgress` class `{required int level, required String chapterId, required DateTime completedAt, required double score}`.
- Consumes: nothing new (pure data class changes).

- [ ] **Step 1: Write the failing test**

```dart
// app/test/data/models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/models.dart';

void main() {
  test('Question.conceptIds defaults to a single-element list from conceptId', () {
    const q = Question(
      id: 'q1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.mcq,
      difficulty: 1,
      marks: 1,
      stem: 'stem',
      solutionSteps: [],
    );
    expect(q.conceptIds, ['c9.sav.cuboid_cube']);
  });

  test('Question can carry level, stage, and case_based parts', () {
    const part = Question(
      id: 'q1_part0',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 1,
      stem: 'Find the volume.',
      numericAnswer: '216',
      solutionSteps: [],
    );
    const q = Question(
      id: 'q1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.caseBased,
      difficulty: 2,
      marks: 2,
      stem: 'A cube has side 6 cm.',
      level: 8,
      stage: 'FOUNDATION',
      parts: [part],
      solutionSteps: [],
    );
    expect(q.level, 8);
    expect(q.stage, 'FOUNDATION');
    expect(q.parts, [part]);
  });

  test('LevelProgress carries level, chapterId, completedAt, score', () {
    final progress = LevelProgress(
      level: 3,
      chapterId: 'surface_area_volume',
      completedAt: DateTime.utc(2026, 9, 27),
      score: 1.0,
    );
    expect(progress.level, 3);
    expect(progress.chapterId, 'surface_area_volume');
    expect(progress.score, 1.0);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd app && flutter test test/data/models_test.dart`
Expected: FAIL — `conceptIds`, `level`, `stage`, `parts`, `caseBased`, and `LevelProgress` are all undefined.

- [ ] **Step 3: Implement the model changes**

In `app/lib/data/models.dart`, replace the `QuestionType` enum:

```dart
enum QuestionType { mcq, numeric, assertionReason, caseBased, expression }
```

Replace the `Question` class:

```dart
class Question {
  const Question({
    required this.id,
    required this.conceptId,
    required this.type,
    required this.difficulty,
    required this.marks,
    required this.stem,
    this.options = const [],
    this.correctIndex,
    this.numericAnswer,
    this.unit,
    this.assertion,
    this.reason,
    this.hints = const [],
    required this.solutionSteps,
    this.distractors = const [],
    this.level,
    this.stage,
    this.parts = const [],
    List<String>? conceptIds,
  }) : conceptIds = conceptIds ?? const [];

  final String id;
  final String conceptId;
  final QuestionType type;
  final int difficulty; // 1..3
  final int marks;
  final String stem;

  // mcq
  final List<String> options;
  final int? correctIndex;
  final List<Distractor> distractors;

  // numeric
  final String? numericAnswer;
  final String? unit;

  // assertion_reason
  final String? assertion;
  final String? reason;

  final List<String> hints;
  final List<String> solutionSteps;

  // Mission-level metadata — null/empty for every non-mission question.
  final int? level;
  final String? stage;

  // case_based
  final List<Question> parts;

  /// All concepts this question touches. Defaults to `[conceptId]` when the
  /// caller only supplies the legacy single-concept constructor arg, so
  /// existing call sites don't need a breaking rename.
  final List<String> _conceptIdsField;
  List<String> get conceptIds => _conceptIdsField.isEmpty ? [conceptId] : _conceptIdsField;
}
```

Wait — a `final` field can't be reassigned via a getter override cleanly with the constructor initializer list shown above; fix this by storing directly:

```dart
class Question {
  Question({
    required this.id,
    required this.conceptId,
    required this.type,
    required this.difficulty,
    required this.marks,
    required this.stem,
    this.options = const [],
    this.correctIndex,
    this.numericAnswer,
    this.unit,
    this.assertion,
    this.reason,
    this.hints = const [],
    required this.solutionSteps,
    this.distractors = const [],
    this.level,
    this.stage,
    this.parts = const [],
    List<String>? conceptIds,
  }) : conceptIds = conceptIds ?? [conceptId];

  final String id;
  final String conceptId;
  final QuestionType type;
  final int difficulty; // 1..3
  final int marks;
  final String stem;

  final List<String> options;
  final int? correctIndex;
  final List<Distractor> distractors;

  final String? numericAnswer;
  final String? unit;

  final String? assertion;
  final String? reason;

  final List<String> hints;
  final List<String> solutionSteps;

  final int? level;
  final String? stage;
  final List<Question> parts;

  /// All concepts this question touches — plural counterpart to [conceptId].
  /// Defaults to `[conceptId]` when not supplied, so every existing
  /// single-concept call site keeps working unchanged.
  final List<String> conceptIds;
}
```

This drops `const` from the constructor (the default-arg logic in the initializer list needs it non-const); update the two test cases above that use `const Question(...)` to plain `Question(...)`.

Add the new model at the end of the file:

```dart
/// Per-student, per-level completion — mirrors the `level_progress` table.
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.chapterId,
    required this.completedAt,
    required this.score,
  });

  final int level;
  final String chapterId;
  final DateTime completedAt;
  final double score;
}
```

- [ ] **Step 4: Fix the two now-invalid `const Question(...)` usages in the test file**

Change `const Question(` to `Question(` in both test cases in Step 1's file (the model constructor is no longer `const`).

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd app && flutter test test/data/models_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 6: Run the full existing test suite to check nothing else regressed from removing `const`**

Run: `cd app && flutter test`
Expected: PASS. If any existing test or widget uses `const Question(...)`, fix those call sites the same way (drop `const`). Grep first: `grep -rn "const Question(" app/lib app/test`.

- [ ] **Step 7: Commit**

```bash
git add app/lib/data/models.dart app/test/data/models_test.dart
git commit -m "feat(models): add level/stage/parts/conceptIds to Question, add LevelProgress"
```

---

## Task 4: `content_repository.dart` — parse level/stage and case_based parts

**Files:**
- Modify: `app/lib/data/content_repository.dart`
- Test: `app/test/data/content_repository_test.dart` (new file)

**Interfaces:**
- Consumes: `Question` fields from Task 3 (`level`, `stage`, `parts`, `conceptIds`).
- Produces: `ContentRepository._questionFromRow` handles `type == 'case_based'` by recursing into `body['parts']`; `fetchAll()`'s question select includes `level, stage`.

- [ ] **Step 1: Write the failing test**

```dart
// app/test/data/content_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

void main() {
  test('a case_based row round-trips into a Question with populated parts', () {
    final repo = ContentRepository.forTesting();
    final body = {
      'stem': 'A cube has side 6 cm. Answer both parts.',
      'parts': [
        {
          'type': 'numeric',
          'stem': 'Find the volume.',
          'numericAnswer': '216',
          'unit': 'cm^3',
          'marks': 1,
          'concept_ids': ['c9.sav.cuboid_cube'],
          'hints': <String>[],
          'solutionSteps': ['Volume = 216 cm^3'],
        },
        {
          'type': 'numeric',
          'stem': 'Find the surface area.',
          'numericAnswer': '216',
          'unit': 'cm^2',
          'marks': 1,
          'concept_ids': ['c9.sav.cuboid_cube'],
          'hints': <String>[],
          'solutionSteps': ['TSA = 216 cm^2'],
        },
      ],
      'hints': <String>[],
      'solutionSteps': <String>[],
    };

    final question = repo.questionFromRowForTesting(
      id: 'q_c9_sav_l008',
      conceptId: 'c9.sav.cuboid_cube',
      type: 'case_based',
      difficulty: 2,
      marks: 2,
      body: body,
      level: 8,
      stage: 'FOUNDATION',
    );

    expect(question.type, QuestionType.caseBased);
    expect(question.level, 8);
    expect(question.stage, 'FOUNDATION');
    expect(question.parts, hasLength(2));
    expect(question.parts[0].type, QuestionType.numeric);
    expect(question.parts[0].numericAnswer, '216');
    expect(question.parts[0].unit, 'cm^3');
    expect(question.parts[1].unit, 'cm^2');
  });

  test('an mcq row still parses with level/stage null when absent', () {
    final repo = ContentRepository.forTesting();
    final question = repo.questionFromRowForTesting(
      id: 'q_ap_nth_1',
      conceptId: 'c9.seq.ap_nth_term',
      type: 'mcq',
      difficulty: 2,
      marks: 1,
      body: {
        'stem': 'stem',
        'options': ['a', 'b'],
        'correctIndex': 0,
        'hints': <String>[],
        'solutionSteps': <String>[],
      },
    );
    expect(question.level, isNull);
    expect(question.stage, isNull);
    expect(question.parts, isEmpty);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd app && flutter test test/data/content_repository_test.dart`
Expected: FAIL — `ContentRepository.forTesting()` and `questionFromRowForTesting` don't exist yet (`_questionFromRow` is private and has no `level`/`stage` params).

- [ ] **Step 3: Implement the repository changes**

In `app/lib/data/content_repository.dart`:

Add a testing constructor and a public wrapper right after the existing constructor:

```dart
class ContentRepository {
  ContentRepository(this._client);

  /// Test-only constructor — no real Supabase client is touched by the
  /// methods exercised in tests (`questionFromRowForTesting`), so `null` is
  /// safe here despite the field being typed non-nullable for production use.
  @visibleForTesting
  ContentRepository.forTesting() : _client = null as SupabaseClient;

  final SupabaseClient _client;
```

(Add `import 'package:flutter/foundation.dart' show visibleForTesting;` at the top.)

Add the public wrapper method (keep `_questionFromRow` itself private, called by both):

```dart
  @visibleForTesting
  Question questionFromRowForTesting({
    required String id,
    required String conceptId,
    required String type,
    required int difficulty,
    required int marks,
    required Map<String, dynamic> body,
    int? level,
    String? stage,
  }) =>
      _questionFromRow(
        id: id,
        conceptId: conceptId,
        type: type,
        difficulty: difficulty,
        marks: marks,
        body: body,
        level: level,
        stage: stage,
      );
```

Update `fetchAll()`'s question select and row loop:

```dart
    final questionRows = await _client
        .from('questions')
        .select('id, concept_ids, difficulty, type, marks, body, level, stage')
        .eq('status', 'live');

    final questions = <Question>[];
    for (final row in questionRows as List) {
      final conceptIds = (row['concept_ids'] as List).cast<String>();
      if (!conceptIds.any(validConceptIds.contains)) continue;
      final body = row['body'] as Map<String, dynamic>;
      questions.add(_questionFromRow(
        id: row['id'] as String,
        conceptId: conceptIds.first,
        type: row['type'] as String,
        difficulty: row['difficulty'] as int,
        marks: (row['marks'] as num).round(),
        body: body,
        level: row['level'] as int?,
        stage: row['stage'] as String?,
        allConceptIds: conceptIds,
      ));
    }
```

Update `_questionFromRow` itself:

```dart
  Question _questionFromRow({
    required String id,
    required String conceptId,
    required String type,
    required int difficulty,
    required int marks,
    required Map<String, dynamic> body,
    int? level,
    String? stage,
    List<String>? allConceptIds,
  }) {
    QuestionType questionType;
    switch (type) {
      case 'mcq':
        questionType = QuestionType.mcq;
      case 'numeric':
        questionType = QuestionType.numeric;
      case 'assertion_reason':
        questionType = QuestionType.assertionReason;
      case 'case_based':
        questionType = QuestionType.caseBased;
      case 'expression':
        questionType = QuestionType.expression;
      default:
        throw StateError('Unknown question type "$type" for question $id');
    }

    final distractorsRaw = (body['distractors'] as List?) ?? const [];
    final hintsRaw = (body['hints'] as List?) ?? const [];
    final stepsRaw = (body['solutionSteps'] as List?) ?? const [];
    final optionsRaw = (body['options'] as List?) ?? const [];
    final partsRaw = (body['parts'] as List?) ?? const [];

    final parts = <Question>[];
    for (var i = 0; i < partsRaw.length; i++) {
      final partBody = partsRaw[i] as Map<String, dynamic>;
      final partConceptIds = (partBody['concept_ids'] as List?)?.cast<String>() ?? [conceptId];
      parts.add(_questionFromRow(
        id: '$id_part$i',
        conceptId: partConceptIds.first,
        type: partBody['type'] as String,
        difficulty: difficulty,
        marks: (partBody['marks'] as num).round(),
        body: partBody,
        allConceptIds: partConceptIds,
      ));
    }

    return Question(
      id: id,
      conceptId: conceptId,
      type: questionType,
      difficulty: difficulty,
      marks: marks,
      stem: body['stem'] as String,
      options: optionsRaw.cast<String>(),
      correctIndex: body['correctIndex'] as int?,
      numericAnswer: body['numericAnswer'] as String?,
      unit: body['unit'] as String?,
      assertion: body['assertion'] as String?,
      reason: body['reason'] as String?,
      hints: hintsRaw.cast<String>(),
      solutionSteps: stepsRaw.cast<String>(),
      distractors: distractorsRaw
          .map((d) => Distractor(
                optionIndex: d['optionIndex'] as int,
                explanation: d['explanation'] as String,
              ))
          .toList(),
      level: level,
      stage: stage,
      parts: parts,
      conceptIds: allConceptIds,
    );
  }
```

Note the `'$id_part$i'` string interpolation bug risk — Dart interprets `$id_part` as a single identifier `id_part`, not `$id` followed by literal `_part`. Use `'${id}_part$i'` instead:

```dart
      parts.add(_questionFromRow(
        id: '${id}_part$i',
        ...
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd app && flutter test test/data/content_repository_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Run the full test suite**

Run: `cd app && flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/data/content_repository.dart app/test/data/content_repository_test.dart
git commit -m "feat(content_repository): parse level/stage columns and case_based parts"
```

---

## Task 5: `LevelProgressRepository` and `mission_state.dart` provider

**Files:**
- Create: `app/lib/data/level_progress_repository.dart`
- Create: `app/lib/data/mission_state.dart`
- Test: `app/test/data/level_progress_test.dart`

**Interfaces:**
- Consumes: `LevelProgress` (Task 3), the `StudentRepository`/`StudentNotifier` pattern in `app_state.dart`/`student_repository.dart` (mirrored, not imported).
- Produces: `LevelProgressRepository.fetchAll()` → `Map<String, Set<int>>` keyed by `chapterId`; `LevelProgressRepository.completeLevel(chapterId, level, score)`; `LevelProgressState.completedLevels` (`Map<String, Set<int>>`); `LevelProgressState.isUnlocked(chapterId, level)`; `levelProgressProvider = NotifierProvider<LevelProgressNotifier, LevelProgressState>`.

- [ ] **Step 1: Write the failing test — unlock logic**

```dart
// app/test/data/level_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/mission_state.dart';

void main() {
  test('level 1 is always unlocked, even with no progress at all', () {
    const state = LevelProgressState(completedLevels: {});
    expect(state.isUnlocked('surface_area_volume', 1), isTrue);
    expect(state.isUnlocked('surface_area_volume', 2), isFalse);
  });

  test('level N+1 is unlocked iff level N is complete', () {
    const state = LevelProgressState(
      completedLevels: {
        'surface_area_volume': {1, 2, 3},
      },
    );
    expect(state.isUnlocked('surface_area_volume', 4), isTrue);
    expect(state.isUnlocked('surface_area_volume', 5), isFalse);
  });

  test('completion is not assumed contiguous — level 10 complete does not unlock level 3', () {
    const state = LevelProgressState(
      completedLevels: {
        'surface_area_volume': {10},
      },
    );
    expect(state.isUnlocked('surface_area_volume', 3), isFalse);
    expect(state.isUnlocked('surface_area_volume', 11), isTrue);
  });

  test('a chapter with no progress rows unlocks only level 1', () {
    const state = LevelProgressState(completedLevels: {});
    expect(state.isUnlocked('any_chapter', 1), isTrue);
    for (var lvl = 2; lvl <= 62; lvl++) {
      expect(state.isUnlocked('any_chapter', lvl), isFalse);
    }
  });

  test('isCompleted reflects completedLevels', () {
    const state = LevelProgressState(
      completedLevels: {
        'surface_area_volume': {1, 2},
      },
    );
    expect(state.isCompleted('surface_area_volume', 1), isTrue);
    expect(state.isCompleted('surface_area_volume', 3), isFalse);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd app && flutter test test/data/level_progress_test.dart`
Expected: FAIL — `package:study_gym/data/mission_state.dart` doesn't exist.

- [ ] **Step 3: Write `level_progress_repository.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes the per-student `level_progress` table. RLS scopes every
/// row to `auth.uid()` — mirrors `StudentRepository`'s shape exactly.
class LevelProgressRepository {
  LevelProgressRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No signed-in user — cannot read/write level progress.');
    }
    return id;
  }

  /// Returns every completed level number per chapter, for the signed-in user.
  Future<Map<String, Set<int>>> fetchAll() async {
    final userId = _userId;
    final rows = await _client
        .from('level_progress')
        .select('chapter_id, level')
        .eq('user_id', userId);

    final result = <String, Set<int>>{};
    for (final row in rows as List) {
      final chapterId = row['chapter_id'] as String;
      final level = row['level'] as int;
      result.putIfAbsent(chapterId, () => {}).add(level);
    }
    return result;
  }

  Future<void> completeLevel({
    required String chapterId,
    required int level,
    required double score,
  }) async {
    await _client.from('level_progress').upsert({
      'user_id': _userId,
      'chapter_id': chapterId,
      'level': level,
      'score': score,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
```

- [ ] **Step 4: Write `mission_state.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'level_progress_repository.dart';

class LevelProgressState {
  const LevelProgressState({this.completedLevels = const {}});

  final Map<String, Set<int>> completedLevels;

  bool isCompleted(String chapterId, int level) =>
      completedLevels[chapterId]?.contains(level) ?? false;

  /// Level 1 is always unlocked. Level N (N > 1) is unlocked iff level N-1
  /// is in the completed set — completion is never assumed contiguous, so a
  /// completed level 10 with no level 3 row does not unlock level 3.
  bool isUnlocked(String chapterId, int level) {
    if (level <= 1) return true;
    return completedLevels[chapterId]?.contains(level - 1) ?? false;
  }

  LevelProgressState copyWith({Map<String, Set<int>>? completedLevels}) {
    return LevelProgressState(completedLevels: completedLevels ?? this.completedLevels);
  }
}

class LevelProgressNotifier extends Notifier<LevelProgressState> {
  static LevelProgressRepository? repositoryOverride;

  LevelProgressRepository? get _repo => repositoryOverride;

  @override
  LevelProgressState build() {
    if (_repo != null) {
      _hydrate();
    }
    return const LevelProgressState();
  }

  Future<void> _hydrate() async {
    final snapshot = await _repo!.fetchAll();
    state = state.copyWith(completedLevels: snapshot);
  }

  void completeLevel({
    required String chapterId,
    required int level,
    required double score,
  }) {
    final updated = Map<String, Set<int>>.from(state.completedLevels);
    updated[chapterId] = {...(updated[chapterId] ?? {}), level};
    state = state.copyWith(completedLevels: updated);

    _repo
        ?.completeLevel(chapterId: chapterId, level: level, score: score)
        .catchError((_) {});
  }
}

final levelProgressProvider = NotifierProvider<LevelProgressNotifier, LevelProgressState>(
  LevelProgressNotifier.new,
);
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd app && flutter test test/data/level_progress_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 6: Wire `repositoryOverride` in `main.dart`, next to `StudentNotifier.repositoryOverride`**

Find where `StudentNotifier.repositoryOverride = StudentRepository(client);` is set (in `main.dart`, right after `Supabase.initialize()`), and add the equivalent line immediately after it:

```dart
LevelProgressNotifier.repositoryOverride = LevelProgressRepository(client);
```

(Use the Grep tool for `StudentNotifier.repositoryOverride =` in `app/lib/main.dart` to find the exact spot and existing `client` variable name before editing.)

- [ ] **Step 7: Run the full test suite**

Run: `cd app && flutter test`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add app/lib/data/level_progress_repository.dart app/lib/data/mission_state.dart app/lib/main.dart app/test/data/level_progress_test.dart
git commit -m "feat(mission): add LevelProgressRepository and levelProgressProvider"
```

---

## Task 6: `question_card.dart` — `_CaseBasedParts` widget

**Files:**
- Modify: `app/lib/features/workout/question_card.dart`
- Test: `app/test/features/workout/question_card_test.dart` (new file)

**Interfaces:**
- Consumes: `Question.parts` (Task 3).
- Produces: `QuestionCard` accepts `partSelections` (`Map<int, dynamic>?`) and `onSelectPart`/`onPartNumericChanged` callbacks for case_based questions; new `_CaseBasedParts` widget.

- [ ] **Step 1: Write the failing widget test**

```dart
// app/test/features/workout/question_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/workout/question_card.dart';

void main() {
  testWidgets('renders one sub-card per part for a case_based question', (tester) async {
    final part0 = Question(
      id: 'q1_part0',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 1,
      stem: 'Find the volume.',
      numericAnswer: '216',
      unit: 'cm^3',
      solutionSteps: const [],
    );
    final part1 = Question(
      id: 'q1_part1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.mcq,
      difficulty: 2,
      marks: 1,
      stem: 'Which formula gives the surface area?',
      options: const ['6a^2', 'a^3'],
      correctIndex: 0,
      solutionSteps: const [],
    );
    final question = Question(
      id: 'q1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.caseBased,
      difficulty: 2,
      marks: 2,
      stem: 'A cube has side 6 cm.',
      parts: [part0, part1],
      solutionSteps: const [],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: QuestionCard(
          question: question,
          selectedIndex: null,
          onSelect: (_) {},
          partSelections: const {},
          onSelectPart: (_, __) {},
          partNumericControllers: {0: TextEditingController()},
        ),
      ),
    ));

    expect(find.text('Find the volume.'), findsOneWidget);
    expect(find.text('Which formula gives the surface area?'), findsOneWidget);
    expect(find.text('6a^2'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd app && flutter test test/features/workout/question_card_test.dart`
Expected: FAIL — `partSelections`, `onSelectPart`, `partNumericControllers` are not recognized named parameters.

- [ ] **Step 3: Implement `_CaseBasedParts` and thread the new parameters**

In `app/lib/features/workout/question_card.dart`, update `QuestionCard`:

```dart
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
    this.revealAnswer = false,
    this.numericController,
    this.numericSubmitted,
    this.partSelections = const {},
    this.onSelectPart,
    this.partNumericControllers = const {},
  });

  final Question question;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool revealAnswer;
  final TextEditingController? numericController;
  final bool? numericSubmitted;

  /// case_based only: part index -> selected option index (mcq part) or
  /// unused (numeric part, which reads its own controller instead).
  final Map<int, int?> partSelections;
  final void Function(int partIndex, int optionIndex)? onSelectPart;
  final Map<int, TextEditingController> partNumericControllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StemCard(question: question),
        const SizedBox(height: AppTheme.space20),
        if (question.type == QuestionType.mcq) _McqOptions(
          question: question,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          revealAnswer: revealAnswer,
        ),
        if (question.type == QuestionType.assertionReason) _AssertionReasonOptions(
          question: question,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          revealAnswer: revealAnswer,
        ),
        if (question.type == QuestionType.numeric) _NumericInput(
          question: question,
          controller: numericController,
          submitted: numericSubmitted ?? false,
        ),
        if (question.type == QuestionType.caseBased) _CaseBasedParts(
          question: question,
          partSelections: partSelections,
          onSelectPart: onSelectPart,
          partNumericControllers: partNumericControllers,
          revealAnswer: revealAnswer,
        ),
      ],
    );
  }
}
```

Add the new widget after `_NumericInput`:

```dart
class _CaseBasedParts extends StatelessWidget {
  const _CaseBasedParts({
    required this.question,
    required this.partSelections,
    required this.onSelectPart,
    required this.partNumericControllers,
    required this.revealAnswer,
  });

  final Question question;
  final Map<int, int?> partSelections;
  final void Function(int partIndex, int optionIndex)? onSelectPart;
  final Map<int, TextEditingController> partNumericControllers;
  final bool revealAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: question.parts.asMap().entries.map((entry) {
        final i = entry.key;
        final part = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space16),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Part ${i + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 6),
                Text(part.stem, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (part.type == QuestionType.mcq)
                  _McqOptions(
                    question: part,
                    selectedIndex: partSelections[i],
                    onSelect: (opt) => onSelectPart?.call(i, opt),
                    revealAnswer: revealAnswer,
                  ),
                if (part.type == QuestionType.numeric)
                  _NumericInput(
                    question: part,
                    controller: partNumericControllers[i],
                    submitted: revealAnswer,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd app && flutter test test/features/workout/question_card_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full test suite**

Run: `cd app && flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/workout/question_card.dart app/test/features/workout/question_card_test.dart
git commit -m "feat(question_card): render case_based questions as per-part sub-cards"
```

---

## Task 7: `workout_screen.dart` — per-part state, case_based grading, `WorkoutScreen.singleLevel`

**Files:**
- Modify: `app/lib/features/workout/workout_screen.dart`
- Test: `app/test/features/workout/workout_screen_test.dart` (new file)

**Interfaces:**
- Consumes: `_CaseBasedParts`/`QuestionCard`'s new params (Task 6), `levelProgressProvider` (Task 5), `Question.conceptIds`/`.parts` (Task 3).
- Produces: `WorkoutScreen.singleLevel(Question level)` named constructor; `_isCorrect` case_based branch; `_submit` iterates `conceptIds`; on completing a single-level workout, pops back and calls `levelProgressProvider.notifier.completeLevel(...)` instead of pushing `WorkoutCompleteScreen`.

- [ ] **Step 1: Write the failing tests — grading logic (table-driven)**

Since `_isCorrect`/`_WorkoutItem` are private to `workout_screen.dart`, this test drives them through the public widget rather than importing privates directly (matches how Dart test conventions handle private state — exercise via the public `WorkoutScreen` API and interaction, not direct private access).

```dart
// app/test/features/workout/workout_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

Question _numericPart(String id, String answer) => Question(
      id: id,
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 2,
      marks: 1,
      stem: 'part stem $id',
      numericAnswer: answer,
      solutionSteps: const [],
    );

Question _caseBasedLevel({required List<Question> parts}) => Question(
      id: 'q_case',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.caseBased,
      difficulty: 2,
      marks: 2,
      stem: 'case stem',
      level: 8,
      stage: 'FOUNDATION',
      parts: parts,
      conceptIds: const ['c9.sav.cuboid_cube'],
      solutionSteps: const [],
    );

void main() {
  setUp(() {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(
          id: 'surface_area_volume',
          name: 'Mensuration: Surface Area and Volume',
          subject: Subject.maths,
          boardWeightMarks: 6,
          concepts: [Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: 'surface_area_volume')],
        ),
      ],
      questions: [],
    ));
  });

  Future<void> _pump(WidgetTester tester, Question level) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: WorkoutScreen.singleLevel(level)),
      ),
    );
  }

  testWidgets('case_based level: both parts correct -> Correct! feedback', (tester) async {
    final level = _caseBasedLevel(parts: [
      _numericPart('p0', '216'),
      _numericPart('p1', '216'),
    ]);
    await _pump(tester, level);

    await tester.enterText(find.byType(TextField).at(0), '216');
    await tester.enterText(find.byType(TextField).at(1), '216');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Correct!'), findsOneWidget);
  });

  testWidgets('case_based level: one part wrong -> Not yet feedback', (tester) async {
    final level = _caseBasedLevel(parts: [
      _numericPart('p0', '216'),
      _numericPart('p1', '216'),
    ]);
    await _pump(tester, level);

    await tester.enterText(find.byType(TextField).at(0), '216');
    await tester.enterText(find.byType(TextField).at(1), '999');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Not yet'), findsOneWidget);
  });

  testWidgets('case_based level: all parts wrong -> Not yet feedback', (tester) async {
    final level = _caseBasedLevel(parts: [
      _numericPart('p0', '216'),
      _numericPart('p1', '216'),
    ]);
    await _pump(tester, level);

    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Not yet'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd app && flutter test test/features/workout/workout_screen_test.dart`
Expected: FAIL — `WorkoutScreen.singleLevel` doesn't exist.

- [ ] **Step 3: Implement `workout_screen.dart` changes**

Update `_WorkoutItem` to hold per-part state:

```dart
class _WorkoutItem {
  _WorkoutItem({required this.question, required this.section}) {
    for (var i = 0; i < question.parts.length; i++) {
      if (question.parts[i].type == QuestionType.numeric) {
        partNumericControllers[i] = TextEditingController();
      }
    }
  }

  final Question question;
  final _Section section;
  int hintsRevealed = 0;
  bool submitted = false;
  bool? wasCorrect;
  int? selectedIndex;
  final TextEditingController numericController = TextEditingController();

  /// case_based only: part index -> selected mcq option index.
  final Map<int, int?> partSelections = {};

  /// case_based only: part index -> numeric input controller.
  final Map<int, TextEditingController> partNumericControllers = {};

  bool? firstAttemptCorrect;

  void disposePartControllers() {
    for (final c in partNumericControllers.values) {
      c.dispose();
    }
  }
}
```

Update `dispose()` in `_WorkoutScreenState`:

```dart
  @override
  void dispose() {
    _shakeController.dispose();
    for (final item in _items) {
      item.numericController.dispose();
      item.disposePartControllers();
    }
    super.dispose();
  }
```

Add the new constructor and single-level construction path. Add a field to track single-level mode:

```dart
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.concepts}) : singleLevelQuestion = null;

  const WorkoutScreen.singleLevel(Question level, {super.key})
      : concepts = const [],
        singleLevelQuestion = level;

  final List<Concept> concepts;
  final Question? singleLevelQuestion;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}
```

Update `_buildWorkout`:

```dart
  List<_WorkoutItem> _buildWorkout() {
    final singleLevel = widget.singleLevelQuestion;
    if (singleLevel != null) {
      return [_WorkoutItem(question: singleLevel, section: _Section.strength)];
    }

    final all = <_WorkoutItem>[];
    final pool = widget.concepts.expand((c) => Content.forConcept(c.id)).toList();
    if (pool.isEmpty) return all;

    final warmUp = pool.where((q) => q.difficulty == 1).take(3).toList();
    final strength = pool.where((q) => q.difficulty == 2).take(5).toList();
    final challenge = pool.where((q) => q.difficulty >= 2).skip(strength.length).take(2).toList();

    final used = <String>{};
    void addAll(List<Question> qs, _Section s) {
      for (final q in qs) {
        if (used.add(q.id)) all.add(_WorkoutItem(question: q, section: s));
      }
    }

    addAll(warmUp, _Section.warmUp);
    addAll(strength, _Section.strength);
    addAll(challenge, _Section.challenge);
    if (all.length < 5) {
      addAll(pool, _Section.strength);
    }
    return all.take(10).toList();
  }
```

Update `_isCorrect`:

```dart
  bool _isCorrect(_WorkoutItem item) {
    final q = item.question;
    if (q.type == QuestionType.caseBased) {
      for (var i = 0; i < q.parts.length; i++) {
        final part = q.parts[i];
        if (part.type == QuestionType.numeric) {
          final input = item.partNumericControllers[i]?.text.trim().replaceAll(' ', '') ?? '';
          if (input != part.numericAnswer) return false;
        } else {
          if (item.partSelections[i] != part.correctIndex) return false;
        }
      }
      return q.parts.isNotEmpty;
    }
    if (q.type == QuestionType.numeric) {
      final input = item.numericController.text.trim().replaceAll(' ', '');
      return input == q.numericAnswer;
    }
    return item.selectedIndex == q.correctIndex;
  }
```

Update `_submit` to iterate `conceptIds` and, on a single-level completion, record level progress instead of the normal XP path:

```dart
  void _submit() {
    final item = _current;
    final correct = _isCorrect(item);
    final isFirstAttempt = item.firstAttemptCorrect == null;

    setState(() {
      item.submitted = true;
      item.wasCorrect = correct;
      if (isFirstAttempt) item.firstAttemptCorrect = correct;
    });
    if (!correct) {
      _shakeController.forward(from: 0);
    }

    if (isFirstAttempt) {
      for (final conceptId in item.question.conceptIds) {
        ref.read(studentProvider.notifier).recordAttempt(
              questionId: item.question.id,
              conceptId: conceptId,
              correct: correct,
              hintsUsed: item.hintsRevealed,
            );
      }
      if (correct) {
        ref.read(studentProvider.notifier).addXp(item.question.marks * 5);
      }
    }
  }
```

Update `_next` to branch on single-level mode:

```dart
  void _next() {
    final singleLevel = widget.singleLevelQuestion;
    if (singleLevel != null) {
      final item = _items.first;
      final chapter = Content.chapterOf(singleLevel.conceptId);
      ref.read(levelProgressProvider.notifier).completeLevel(
            chapterId: chapter.id,
            level: singleLevel.level!,
            score: (item.firstAttemptCorrect ?? false) ? 1.0 : 0.0,
          );
      Navigator.of(context).pop();
      return;
    }

    if (_index == _items.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutCompleteScreen(
            items: _items
                .map((i) => WorkoutResultItem(
                      concept: Content.conceptById(i.question.conceptId),
                      correct: i.firstAttemptCorrect ?? false,
                    ))
                .toList(),
          ),
        ),
      );
    } else {
      setState(() {
        _index++;
        _usedRetry = false;
      });
    }
  }
```

Add the import: `import '../../data/mission_state.dart';` at the top of the file.

Update the `build()` method's `QuestionCard` construction and `canSubmit` to account for case_based:

```dart
    final item = _current;
    final canSubmit = switch (item.question.type) {
      QuestionType.numeric => item.numericController.text.trim().isNotEmpty,
      QuestionType.caseBased => item.question.parts.asMap().entries.every((e) {
          final i = e.key;
          final part = e.value;
          if (part.type == QuestionType.numeric) {
            return (item.partNumericControllers[i]?.text.trim() ?? '').isNotEmpty;
          }
          return item.partSelections[i] != null;
        }),
      _ => item.selectedIndex != null,
    };
```

And in the `QuestionCard(...)` call inside `build()`, add the new params:

```dart
                        QuestionCard(
                          question: item.question,
                          selectedIndex: item.selectedIndex,
                          revealAnswer: item.submitted && item.question.type != QuestionType.numeric,
                          numericController: item.numericController,
                          numericSubmitted: item.submitted,
                          onSelect: item.submitted
                              ? (_) {}
                              : (i) => setState(() => item.selectedIndex = i),
                          partSelections: item.partSelections,
                          onSelectPart: item.submitted
                              ? null
                              : (i, opt) => setState(() => item.partSelections[i] = opt),
                          partNumericControllers: item.partNumericControllers,
                        ),
```

Also register a rebuild listener for part numeric controllers in `initState` (so `canSubmit` updates live), alongside the existing `item.numericController.addListener(...)`:

```dart
  @override
  void initState() {
    super.initState();
    _items = _buildWorkout();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    for (final item in _items) {
      item.numericController.addListener(() => setState(() {}));
      for (final c in item.partNumericControllers.values) {
        c.addListener(() => setState(() {}));
      }
    }
  }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd app && flutter test test/features/workout/workout_screen_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Run the full test suite**

Run: `cd app && flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/workout/workout_screen.dart app/test/features/workout/workout_screen_test.dart
git commit -m "feat(workout): support case_based grading, per-concept mastery, and singleLevel mode"
```

---

## Task 8: `MissionScreen`

**Files:**
- Create: `app/lib/features/mission/mission_screen.dart`
- Test: `app/test/features/mission/mission_screen_test.dart`

**Interfaces:**
- Consumes: `Content.forChapter(chapterId)` (unchanged signature, per spec), `Question.level`/`.stage` (Task 3), `levelProgressProvider` (Task 5), `WorkoutScreen.singleLevel` (Task 7).
- Produces: `MissionScreen({required String chapterId})`.

- [ ] **Step 1: Write the failing widget test**

```dart
// app/test/features/mission/mission_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/mission_state.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/mission/mission_screen.dart';

List<Question> _levels() {
  const stages = ['FOUNDATION', 'GUIDED_PRACTICE', 'SKILL_BUILDING', 'APPLICATION', 'MASTERY'];
  return List.generate(62, (i) {
    final level = i + 1;
    final stage = stages[(level - 1) ~/ 13 % stages.length];
    return Question(
      id: 'q_l$level',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.mcq,
      difficulty: 1,
      marks: 1,
      stem: 'stem $level',
      options: const ['a', 'b'],
      correctIndex: 0,
      level: level,
      stage: stage,
      solutionSteps: const [],
    );
  });
}

void main() {
  setUp(() {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(
          id: 'surface_area_volume',
          name: 'Mensuration: Surface Area and Volume',
          subject: Subject.maths,
          boardWeightMarks: 6,
          concepts: [Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: 'surface_area_volume')],
        ),
      ],
      questions: _levels(),
    ));
  });

  testWidgets('renders 62 nodes in level order with only level 1 unlocked for a fresh student', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          levelProgressProvider.overrideWith(LevelProgressNotifier.new),
        ],
        child: const MaterialApp(home: MissionScreen(chapterId: 'surface_area_volume')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mission_node_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('mission_node_62')), findsOneWidget);

    final lockedIcon = find.descendant(
      of: find.byKey(const ValueKey('mission_node_2')),
      matching: find.byIcon(Icons.lock_rounded),
    );
    expect(lockedIcon, findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd app && flutter test test/features/mission/mission_screen_test.dart`
Expected: FAIL — `package:study_gym/features/mission/mission_screen.dart` doesn't exist.

- [ ] **Step 3: Implement `mission_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/content.dart';
import '../../data/mission_state.dart';
import '../../data/models.dart';
import '../workout/workout_screen.dart';

/// The Duolingo-style level path for a mission-sequenced chapter (currently
/// only `surface_area_volume`). Groups levels by `stage`, shows lock state
/// from `levelProgressProvider`, and pushes a single-level workout on tap.
class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key, required this.chapterId});

  final String chapterId;

  static const _stageLabels = {
    'FOUNDATION': 'Foundation',
    'GUIDED_PRACTICE': 'Guided Practice',
    'SKILL_BUILDING': 'Skill Building',
    'APPLICATION': 'Application',
    'MASTERY': 'Mastery',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(levelProgressProvider);
    final levels = Content.forChapter(chapterId).where((q) => q.level != null).toList()
      ..sort((a, b) => a.level!.compareTo(b.level!));

    return Scaffold(
      appBar: AppBar(title: const Text('Mission')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space20, horizontal: AppTheme.space20),
        itemCount: levels.length,
        itemBuilder: (context, i) {
          final level = levels[i];
          final showStageHeader = i == 0 || levels[i - 1].stage != level.stage;
          final completed = progress.isCompleted(chapterId, level.level!);
          final unlocked = progress.isUnlocked(chapterId, level.level!);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showStageHeader)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space16, bottom: AppTheme.space12),
                  child: Text(
                    _stageLabels[level.stage] ?? level.stage ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              _MissionNode(
                key: ValueKey('mission_node_${level.level}'),
                level: level,
                completed: completed,
                unlocked: unlocked,
                onTap: unlocked
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => WorkoutScreen.singleLevel(level)),
                        )
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MissionNode extends StatelessWidget {
  const _MissionNode({
    super.key,
    required this.level,
    required this.completed,
    required this.unlocked,
    required this.onTap,
  });

  final Question level;
  final bool completed;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Widget icon;
    if (completed) {
      fill = AppColors.mastered;
      icon = const Icon(Icons.check_rounded, color: Colors.white);
    } else if (unlocked) {
      fill = AppColors.brand;
      icon = Text('${level.level}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800));
    } else {
      fill = AppColors.notStarted;
      icon = const Icon(Icons.lock_rounded, color: Colors.white, size: 18);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Level ${level.level}', style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd app && flutter test test/features/mission/mission_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full test suite**

Run: `cd app && flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/mission/mission_screen.dart app/test/features/mission/mission_screen_test.dart
git commit -m "feat(mission): add MissionScreen level path UI"
```

---

## Task 9: Entry point in `skill_map_screen.dart`

**Files:**
- Modify: `app/lib/features/skill_map/skill_map_screen.dart`
- Test: extend `app/test/features/mission/mission_screen_test.dart` or add `app/test/features/skill_map/skill_map_screen_test.dart`

**Interfaces:**
- Consumes: `Content.forChapter(chapter.id)` (checks any question has non-null `level`), `MissionScreen` (Task 8).
- Produces: a "Start Mission" button in `_ChapterCard`, shown only for chapters with mission content.

- [ ] **Step 1: Write the failing widget test**

```dart
// app/test/features/skill_map/skill_map_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/skill_map/skill_map_screen.dart';

void main() {
  testWidgets('shows Start Mission only for a chapter with mission-leveled questions', (tester) async {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(
          id: 'surface_area_volume',
          name: 'Mensuration: Surface Area and Volume',
          subject: Subject.maths,
          boardWeightMarks: 6,
          concepts: [Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: 'surface_area_volume')],
        ),
        Chapter(
          id: 'sequences_progressions',
          name: 'Sequences and Progressions',
          subject: Subject.maths,
          boardWeightMarks: 6,
          concepts: [Concept(id: 'c9.seq.ap_nth_term', name: 'nth term of an AP', chapterId: 'sequences_progressions')],
        ),
      ],
      questions: [
        Question(
          id: 'q_l1',
          conceptId: 'c9.sav.cuboid_cube',
          type: QuestionType.mcq,
          difficulty: 1,
          marks: 1,
          stem: 'stem',
          options: const ['a', 'b'],
          correctIndex: 0,
          level: 1,
          stage: 'FOUNDATION',
          solutionSteps: const [],
        ),
        Question(
          id: 'q_ap',
          conceptId: 'c9.seq.ap_nth_term',
          type: QuestionType.mcq,
          difficulty: 1,
          marks: 1,
          stem: 'stem',
          options: const ['a', 'b'],
          correctIndex: 0,
          solutionSteps: const [],
        ),
      ],
    ));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SkillMapScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start Mission'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd app && flutter test test/features/skill_map/skill_map_screen_test.dart`
Expected: FAIL — no "Start Mission" text exists anywhere yet.

- [ ] **Step 3: Implement the entry point**

In `app/lib/features/skill_map/skill_map_screen.dart`, add the import:

```dart
import '../mission/mission_screen.dart';
import '../../shared/widgets/chunky_button.dart';
```

In `_ChapterCard.build`, after the existing `InkWell` header block (before or after the `AnimatedCrossFade` for concepts — insert it right after the header `InkWell`, still inside the outer `Column`):

```dart
          if (Content.forChapter(chapter.id).any((q) => q.level != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ChunkyButton(
                label: 'Start Mission',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MissionScreen(chapterId: chapter.id)),
                ),
              ),
            ),
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd app && flutter test test/features/skill_map/skill_map_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full test suite**

Run: `cd app && flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/skill_map/skill_map_screen.dart app/test/features/skill_map/skill_map_screen_test.dart
git commit -m "feat(skill_map): add Start Mission entry point for chapters with mission content"
```

---

## Task 10: Grep sweep for `.conceptId` call sites (spec's flagged risk)

**Files:**
- Review only: any file matching `.conceptId` usage.

**Interfaces:**
- Consumes: nothing new — this is a verification pass over Tasks 3-9's changes.

- [ ] **Step 1: Re-run the grep the spec calls for**

Run: `grep -rn "\.conceptId\b" app/lib app/test`
Expected matches (confirmed during planning): `models.dart` (field declarations), `content.dart` (`forConcept`/`forChapter`, both still singular-keyed by design per spec §9 "no generalization" — a case_based question's own top-level `conceptId` is still its first concept, only `_submit`'s mastery recording was changed to iterate `conceptIds`), `app_state.dart`'s `weakConcepts`, `workout_screen.dart`'s `WorkoutResultItem` construction in `_next`.

- [ ] **Step 2: Confirm each site's behavior is still correct for a case_based question**

- `content.dart`'s `forConcept`/`forChapter`: unchanged, filters by singular `conceptId` — correct, since `forChapter` only needs to find the question at all (a case_based question's `conceptId` is still one of its real concepts), not enumerate every concept it touches.
- `app_state.dart`'s `weakConcepts`: reads `mastery.values`, which is now populated per-concept correctly by Task 7's `_submit` change (one `ConceptMastery` entry per concept in `conceptIds`, not just the first) — no change needed here, it already iterates whatever's in the map.
- `workout_screen.dart`'s `_next`/`WorkoutResultItem`: still uses the item's singular `conceptId` for the multi-question workout summary screen — acceptable, since `WorkoutCompleteScreen` shows one concept badge per item and a case_based question is not expected to appear in the warm-up/strength/challenge pool today (mission-only content is excluded from `Content.forConcept`'s general pool by virtue of `_ChapterCard`'s per-concept "Practice" flow using non-mission concepts primarily; if a future mission concept also gets non-mission practice questions, this is unaffected since `WorkoutScreen.singleLevel` bypasses `_next`'s normal multi-question path entirely for level playthroughs).

- [ ] **Step 3: No code change expected from this task — if the grep surfaces a call site not accounted for above, add a task-specific fix and a regression test before proceeding**

This step is a checkpoint, not a fixed diff — the "how to apply" is: if a new mismatch is found, stop and add a fix here rather than silently proceeding to Task 11.

- [ ] **Step 4: Commit (only if Step 3 required a fix; otherwise skip)**

```bash
git add -A
git commit -m "fix: address .conceptId call site missed by earlier tasks"
```

---

## Task 11: End-to-end manual verification

**Files:** none (manual QA pass).

- [ ] **Step 1: Run the full automated suite one more time**

Run: `cd app && flutter test` and `cd content && ../.venv/Scripts/python.exe -m pytest`
Expected: both green.

- [ ] **Step 2: Run the app against a local Supabase instance with the new migration + seed applied**

Run (from `backend/supabase/`): apply `20260929000000_mission_levels.sql`, then run `001_cbse_9_maths_science.sql`, `002_m9_coord_poly.sql`, `003_m9_remaining_chapters.sql`, `004_surface_area_volume_mission.sql` in order (fresh DB). Then `flutter run` the app.

- [ ] **Step 3: Manually play through level 8 (the Foundation case_based checkpoint) end-to-end**

From Skill Map → Mensuration: Surface Area and Volume → Start Mission → tap level 8 (only reachable after completing levels 1-7 in the running app, or by seeding `level_progress` rows for levels 1-7 directly for the test user first). Confirm: both numeric parts render, submit is disabled until both are filled, submitting with both correct shows "Correct!" and pops back to `MissionScreen` with level 8 now showing completed and level 9 unlocked. Confirm mastery updated for `c9.sav.cuboid_cube` (check Skill Map's concept row percentage moved).

- [ ] **Step 4: Confirm existing per-concept Practice flow is untouched**

From Skill Map, expand any non-mission chapter (e.g. Sequences and Progressions), tap "Practice" on a concept, confirm the normal warm-up/strength/challenge `WorkoutScreen` flow still works exactly as before (pushes `WorkoutCompleteScreen` at the end, not a pop-back).

- [ ] **Step 5: No commit for this task** — it's verification only. If any manual check fails, return to the relevant earlier task, fix, add/adjust a regression test, and re-commit there.

---

## Self-Review Notes

- **Spec coverage:** All 9 numbered "Changes by layer" sections map to tasks 1-9. The spec's three "Risks / open questions" are resolved: subject_id confirmed `cbse_9_maths` (Task 2), chapter/concepts confirmed absent and now seeded (Task 2), `.conceptId` call sites swept (Task 10). Testing section's four bullet points map to Tasks 3/4 (repository round-trip), 5 (unlock logic), 7 (case_based grading table), 8 (widget test), 11 (manual playthrough).
- **Status derivation deviation from spec:** the spec assumed the YAML already splits 42 live / 20 review; in fact all 62 rows currently say `status: review` in the YAML itself. Task 2's seed script instead derives live/review from presence of a `verification` block (48 verified / 14 not), matching the spec's *intent* ("unverified content needs human sign-off") rather than its literal (and incorrect) count. This is called out explicitly in Task 2 rather than left implicit.
- **Placeholder scan:** no TBD/TODO markers; every step has literal code.
- **Type consistency:** `LevelProgressRepository`/`LevelProgressNotifier`/`levelProgressProvider` names are used identically across Tasks 5, 7, 8. `Question.conceptIds`/`.parts`/`.level`/`.stage` names are identical across Tasks 3, 4, 6, 7, 8, 9. `WorkoutScreen.singleLevel` signature matches between Task 7 (definition) and Task 8 (call site).

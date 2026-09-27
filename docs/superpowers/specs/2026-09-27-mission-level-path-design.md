# Mission level path: integrating the 62-level Surface Areas & Volumes content into the app

Status: approved for implementation planning
Date: 2026-09-27

## Context

`content/questions/cbse/9/maths/surface_area_volume.yaml` holds a hand-authored,
pipeline-validated, SymPy-verified 62-level "mission" for the CBSE Class 9
Surface Areas and Volumes chapter (proof-of-concept for a Duolingo-style
level/mission design, per the founder's mission-design framework doc). Each
question carries mission-design metadata (`level` 1-62, `stage`, `purpose`,
`why_after_previous`, `prepares_for`) on top of the normal question schema.

None of this reaches a student today. The content pipeline only produces a
flat, validated question bank — there is no notion of level/mission/stage
anywhere in Supabase or the Flutter app. This spec integrates that content
into the app as an actual sequenced level path.

**Curriculum note:** the chapter's concept set (`c9.sav.cuboid_cube`,
`cylinder`, `cone`, `pyramid`, `sphere_hemisphere`, `scaling`, `units` in
`content/syllabus/cbse/9/maths.yaml`) was cross-checked against the official
2026-27 CBSE NCERT syllabus PDF (`docs/sources/cbse-2026-27-class9-maths.pdf`,
Unit V: Mensuration) and matches it. A separate curriculum doc
(`docs/curriculum/class9_maths.md`, Ch.14 "SAV") describes a different,
more granular 9-skill breakdown for this chapter that does **not** match the
official PDF — that doc has drifted from the source and is not used here.
Reconciling it is a separate, later concern, not blocking this work.

## Goals

- A student can open the Surface Areas & Volumes chapter and play through all
  62 levels in order, as a locked/unlocked/complete node path — the actual
  Duolingo-style UI the mission-design framework is validating.
- All 5 question shapes present in the content (`mcq`, `numeric`,
  `case_based` with 2-5 parts) render and grade correctly. 20 of the 62
  levels are `case_based`, which the app cannot render today — this is
  in scope, not deferred, since the mission is specifically meant to
  validate that pattern end-to-end.
- Level completion persists per student (Supabase-backed, RLS-scoped, syncs
  across devices/reinstalls — consistent with how every other piece of
  student state already works).
- Existing per-concept practice (Skill Map's "Practice" buttons, the
  warm-up/strength/challenge daily workout) is untouched. The mission path is
  an additional entry point, not a replacement.

## Non-goals

- No changes to the mastery engine's math (Elo-style update in
  `app_state.dart`) — level completion is tracked separately from concept
  mastery; a level still updates concept mastery exactly as any other
  question does today.
- No `expression` or `assertion_reason` rendering changes beyond what already
  exists — this content only uses `mcq`/`numeric`/`case_based`.
- No changes to the content pipeline or the YAML file itself — that work is
  done and validated (0 errors, 62/62 levels present, `pytest` green).
- No reconciliation of `docs/curriculum/class9_maths.md`'s SAV-001..009
  breakdown with the syllabus — flagged above, not touched here.
- No generalization to a "mission" concept for other chapters yet. This spec
  wires up one chapter's content end-to-end; generalizing the pattern (e.g. a
  `missions` table, chapter-level "has a mission" flag) is a natural
  follow-up once this proves out, not pre-built here.

## Data flow

```
surface_area_volume.yaml
  -> (new) scripts/seed_mission.py: YAML -> SQL insert rows
  -> backend/supabase/seed/004_surface_area_volume_mission.sql
  -> Supabase `questions` table (level/stage columns + body jsonb)
  -> ContentRepository.fetchAll() (extended)
  -> Content.forChapter('surface_area_volume') (unchanged signature)
  -> (new) MissionScreen: groups by stage, sorts by level, renders path
  -> tap unlocked node -> WorkoutScreen in new single-level mode
  -> on completion -> (new) level_progress table row
```

## Changes by layer

### 1. Supabase schema (new migration)

`backend/supabase/migrations/20260929000000_mission_levels.sql`:

- `alter table questions add column level smallint, add column stage text;`
  Both nullable — only mission-sequenced content sets them. Existing rows
  (quadratic_equations, coordinate geometry, etc.) are unaffected.
- `create index questions_level_idx on questions(subject_id, level) where level is not null;`
  for the mission screen's ordered fetch.
- New table:
  ```sql
  create table level_progress (
    user_id      uuid not null references profiles(id) on delete cascade,
    chapter_id   text not null references chapters(id),
    level        smallint not null,
    completed_at timestamptz not null default now(),
    score        numeric(4,2),  -- fraction correct on first attempt, 0..1
    primary key (user_id, chapter_id, level)
  );
  alter table level_progress enable row level security;
  create policy own_level_progress on level_progress
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());
  ```
- `body` jsonb for a `case_based` question gains a `parts` array, each part
  shaped like a normal question body (`stem`, `options`/`answers`, etc.) plus
  `marks`. This mirrors the YAML's existing `parts` field — no new concept,
  just carrying it into the DB row that currently only exists for
  non-case_based types.

### 2. Seeding (`content/questions/... -> SQL`)

A new one-off Python script, `content/pipeline/seed_mission.py`, reads
`surface_area_volume.yaml` and the `cbse/9/maths` syllabus, and writes
`backend/supabase/seed/004_surface_area_volume_mission.sql`: one `insert into
questions` per level (marks/difficulty/type as today, plus `level`/`stage`
columns and a `body` jsonb built from the question's fields — stem, options,
answer/answers, distractors, hints, solution_steps, and `parts` for
case_based). `concept_ids` is the question's `concepts` list (already
multi-concept aware in the YAML). `subject_id` is `cbse_9_maths_standard`... 
**(verify against the actual seeded subject_id in `001_cbse_9_maths_science.sql`
before writing the insert — do not assume the id, read it from the existing
seed file.)** `status` is `'review'` for the 20 questions that came out of
the content pipeline flagged "no machine verification" (matching the app's
trust rule: unverified content needs human sign-off before going live) and
`'live'` for the other 42. This mirrors `generate.py`'s own `status: "draft"`
convention for anything not machine-verified.

This also requires the `surface_area_volume` chapter and its 7 concepts to
exist as rows in `chapters`/`concepts` — check whether `003_m9_remaining_chapters.sql`
already seeded them (the syllabus YAML has had this chapter since the initial
commit); if not, the new seed file adds them first, following the exact
column shapes `001_cbse_9_maths_science.sql` already established.

### 3. Flutter data model (`app/lib/data/models.dart`)

- `QuestionType` gains `caseBased` (and `expression`, for registry
  completeness, even though this content doesn't use it).
- `Question` gains three fields, all with safe defaults so no existing
  construction site breaks:
  - `final int? level;`
  - `final String? stage;`
  - `final List<Question> parts;` (empty unless `type == caseBased`)
- `Question.conceptId` (singular) stays for backward compatibility with every
  existing call site, but a case_based question's "primary" concept is just
  its first concept — mastery recording for case_based iterates `concepts`
  (plural, new field) instead. Concretely: add `final List<String> conceptIds;`
  defaulting to `[conceptId]` when only the old single-id constructor arg is
  supplied, so `content_repository.dart` can pass the full list without a
  breaking rename everywhere else in the app.
- New `LevelProgress` model: `{required int level, required String chapterId,
  required DateTime completedAt, required double score}`.

### 4. `content_repository.dart`

- `fetchAll()`'s question select adds `level, stage` to the column list.
- `_questionFromRow` reads them straight onto `Question.level`/`.stage`.
- For `type == 'case_based'`: build `parts` by recursively calling
  `_questionFromRow` on each entry in `body['parts']` (each part carries its
  own `type`/`difficulty`/`marks`/`concept_ids` inside the jsonb, matching the
  YAML's part shape) instead of hitting the current `default: throw
  StateError`.

### 5. `question_card.dart`

- New branch: `if (question.type == QuestionType.caseBased) _CaseBasedParts(...)`.
- `_CaseBasedParts` renders the shared stem once (case_based's own `stem` —
  the case scenario), then each part in its own bordered sub-card: the
  part's stem, its own MCQ options or numeric input, using the *same*
  `_McqOptions`/`_NumericInput` widgets parameterized per-part rather than
  duplicating them.
- Selection state for a case_based item becomes `Map<int, dynamic>` (part
  index -> selected option index or numeric text) instead of a single
  `selectedIndex`/`numericController` — `_WorkoutItem` in `workout_screen.dart`
  needs a small shape change to carry per-part state for case_based items
  specifically (single `selectedIndex`/`numericController` stay as-is for
  non-case_based items, so this is additive, not a rewrite of the existing
  item state).

### 6. `workout_screen.dart`

- `_isCorrect` gains a case_based branch: correct only if every part's answer
  matches (mcq: part's selected index == part's answer index; numeric: part's
  typed value equals one of the part's accepted answers, same string
  comparison the existing numeric path uses).
- `_submit`'s mastery recording iterates `item.question.conceptIds` (the new
  plural field) instead of the single `conceptId`, calling
  `recordAttempt` once per concept touched — matches how a real case_based
  question in the syllabus already spans multiple concepts.
- New construction path: `WorkoutScreen.singleLevel(Question level)` (a named
  constructor or a nullable `singleLevelQuestion` param alongside the
  existing `concepts` param) that builds `_items` as exactly that one
  question, no warm-up/strength/challenge bucketing, no `Content.forConcept`
  pool lookup. On completing that one item, instead of pushing
  `WorkoutCompleteScreen`, it pops back to `MissionScreen` and calls the new
  `levelProgressProvider.notifier.completeLevel(...)`.

### 7. New `LevelProgress` state (`app/lib/data/level_progress_repository.dart`,
   a new provider in `app_state.dart` or its own `mission_state.dart`)

- `LevelProgressRepository` (same shape as `StudentRepository`): `fetchAll()`
  reads all of one chapter's `level_progress` rows for the signed-in user;
  `completeLevel(chapterId, level, score)` upserts one row.
- `levelProgressProvider` (Riverpod `NotifierProvider`): holds
  `Map<String, Set<int>>` (chapterId -> completed level numbers). Hydrated at
  startup the same way `studentProvider` is (an optional repository override,
  null-safe in tests). `isUnlocked(chapterId, level)` = level 1, or the
  previous level number is in the completed set.

### 8. New `MissionScreen` (`app/lib/features/mission/mission_screen.dart`)

- Takes `chapterId`. Reads `Content.forChapter(chapterId)`, filters to
  questions with a non-null `level`, sorts by `level`.
- Groups consecutively by `stage` for section headers (Foundation / Guided
  Practice / Skill Building / Application / Mastery), matching the YAML's own
  stage labels verbatim (title-cased for display).
- Renders a vertical scrolling path: one circular numbered node per level,
  connected by a line, color-coded via `levelProgressProvider`:
  - completed: `AppColors.mastered` fill, check icon
  - unlocked (next playable): `AppColors.brand` fill, level number
  - locked: `AppColors.notStarted`/grey, lock icon, not tappable
- Tapping an unlocked node pushes `WorkoutScreen` via the new single-level
  constructor.

### 9. Entry point (`skill_map_screen.dart`)

- `_ChapterCard` gains a conditional "Start Mission" `ChunkyButton` (only
  shown when `Content.forChapter(chapter.id)` has any question with a
  non-null `level` — i.e. only for chapters that actually have mission
  content, currently just `surface_area_volume`), pushing `MissionScreen`.
- Existing per-concept "Practice" rows are untouched.

## Testing

- `content/pipeline/tests/`: already green, untouched by this spec (no
  pipeline changes).
- New Dart unit tests:
  - `content_repository_test.dart` (or extend existing content test fixture):
    a `case_based` row round-trips through `_questionFromRow` into a
    `Question` with correctly populated `parts`.
  - `level_progress` unlock logic: level 1 always unlocked; level N+1 unlocked
    iff level N is complete; a chapter with no progress rows unlocks only
    level 1.
  - `workout_screen` grading: a case_based item is correct iff every part is
    correct (table-driven: all-correct, one-part-wrong, all-wrong).
- Widget test: `MissionScreen` renders 62 nodes in level order, grouped under
  5 stage headers, with the correct lock states given a fake
  `levelProgressProvider` override.
- Manual: play through at least one `case_based` level (e.g. L8, the
  Foundation checkpoint) end-to-end on a real/emulated device, confirming
  both parts must be answered and marks are recorded per concept.

## Risks / open questions for the implementation plan to resolve

- **Seed `subject_id` / whether `surface_area_volume` chapter rows already
  exist**: not yet confirmed — the implementation plan's first step must
  read `backend/supabase/seed/001_cbse_9_maths_science.sql` and
  `003_m9_remaining_chapters.sql` to check, rather than assume.
- **RLS on the new `level_progress` table** should be reviewed against the
  existing `concept_mastery`/`streaks` policies for consistency before
  merging the migration.
- **`Question.conceptId` vs new `conceptIds`**: confirm no other call site
  (tests, `app_state.dart`'s `weakConcepts`, etc.) assumes single-concept
  questions in a way that would misbehave silently for a case_based question
  spanning multiple concepts — grep for `.conceptId` usages as part of the
  plan's first implementation step.

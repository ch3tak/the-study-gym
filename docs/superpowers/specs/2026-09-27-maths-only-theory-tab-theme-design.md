# Maths-only app, Theory tab, and light/dark switch

Date: 2026-09-27. Status: draft for review.

This spec covers three changes shipped together, because they touch the
same screens (the bottom tabs and the chapter list):

1. **Maths only.** Remove Science and every other non-maths subject.
2. **Theory tab.** Build the app screens for the lessons that already
   exist as content, and put the lessons in the live database.
3. **Light/dark switch.** Let the student choose System, Light or Dark in
   the app.

It replaces the "Flutter data layer" and "Flutter UI" sections of
`2026-09-27-theory-content-and-tab-design.md`. That spec's content,
pipeline and database sections are already built and merged.

## What exists today, and what doesn't

| Piece | State before this work |
|---|---|
| Lesson content (7 lessons, Surface Areas & Volumes) | In the repo: `content/questions/cbse/9/maths/surface_area_volume_theory.yaml` |
| Lesson validator and seed script | In the repo, tested |
| `lessons` / `theory_progress` migration and `005` seed | In the repo. **Not applied to the live database** |
| Theory tab, lesson screen, lesson data loading in the app | **Not built** |
| Light and dark themes | Both exist (`AppTheme.light`, `AppTheme.dark`). The app follows the device setting (`ThemeMode.system`); **there's no in-app switch** |
| Science | Hard-coded in the app (`Subject { maths, science }`, the Skill Map switcher, test-builder and onboarding copy). In the live database it's `coming_soon` with 11 questions and 0 enrolments |
| Product direction | `docs/PLAN.md` already says "Math only. Permanently." The code, content and README haven't caught up |

## What the student sees after this ships

- Bottom tabs: **Today · Theory · Mission · Tests · Me**.
- No Maths/Science switcher anywhere. The Mission tab (today's Skill Map)
  opens straight into the maths chapter list.
- The Theory tab lists the chapters that have lessons (only Surface Areas
  & Volumes for now). Each chapter shows how many of its lessons have been
  read. Tapping a lesson opens it; "Mark as read" records it.
- The Me tab has an **Appearance** setting: System / Light / Dark. The
  choice is remembered on that device.
- Onboarding and the test builder talk about Maths only.

---

## Part A: Maths only

Decided with the user: full removal from the app and the repo. Class 9
only, so the app drops the subject concept entirely. Class 10 **maths**
syllabi stay in the repo for later. The non-maths subject rows in the live
database are hidden, not deleted.

### App (Flutter)

- `data/models.dart`: delete the `Subject` enum. `Chapter` loses its
  `subject` field.
- `data/content_repository.dart`: keep the existing `class_id = 'cbse_9'`
  and `status = 'live'` filters, and also filter `subjects.code = 'maths'`.
  Then the app stays maths-only whatever a database status flag says;
  that flag is how the Science switcher slipped through before. Drop the
  `subjectCode → Subject` mapping.
- `data/content.dart`: delete `forSubject()`. Screens use the full chapter
  list.
- `features/skill_map/skill_map_screen.dart`: remove `_SubjectSwitcher`
  and the `_subject` state. The screen lists every chapter. It is renamed
  in Part B.
- `features/tests/custom_test_builder_screen.dart`: remove the
  per-subject headings, leaving one chapter list. Copy changes:
  - "Pick the chapters you want to be tested on — from Maths, Science, or
    both." → "Pick the chapters you want to be tested on."
  - "Build unlimited tests from any chapter, across Maths and Science,
    whenever you want to check yourself." → "Build unlimited tests from any
    chapter, whenever you want to check yourself."
- `features/onboarding/welcome_screen.dart`: "We find exactly what you're
  weak at in Maths and\nScience, train it, and show your real progress." →
  "We find exactly what you're weak at in Maths,\ntrain it, and show your
  real progress."
- `core/theme/app_colors.dart`: remove `scienceAccent` (field, both
  palettes, `copyWith`, `lerp`).

### Content and pipeline

- Delete the non-maths syllabi:
  - `content/syllabus/cbse/9/`: `science.yaml`, `sst.yaml`, `english.yaml`,
    `hindi.yaml`
  - `content/syllabus/cbse/10/`: `science.yaml`, `sst.yaml`, `english.yaml`,
    `hindi_a.yaml`, `hindi_b.yaml`
- Delete `content/questions/cbse/9/science/`.
- `_class.yaml` for Class 9 and Class 10: keep only the maths subjects.
  In Class 10, remove the "Hindi course" choice group and keep "Maths
  level".
- `content/pipeline/subjects.py`: remove the `cbse/9/science` generation
  profile.
- Pipeline tests: remove `test_science_plan_uses_science_profile`
  (`test_generate.py`) and the science cases in `test_questions.py`.
  Where a test only used Science as "a second subject", switch it to
  `cbse/10/maths_standard`.
- `README.md`: "CBSE Class 9 Mathematics and Science" → "CBSE Class 9
  Mathematics".

### Database

- New seed `backend/supabase/seed/006_maths_only.sql`: sets every
  non-maths Class 9 subject to `status = 'hidden'`. The existing
  `read_subjects` policy (`status <> 'hidden'`) then hides them from every
  client. Rows are kept, not deleted, so nothing that references them
  breaks. It's a new file rather than an edit to `001`, which has already
  been applied to the live database.

## Part B: Theory tab

### Data layer

As in the earlier spec, unchanged apart from the subject removal:

- `Lesson` model in `data/models.dart`: `id`, `conceptId`, `title`,
  `body`, `hookKind` (`HookKind { historical, realWorld }`), `hook`,
  `tryIt` (nullable), `sortOrder`.
- `ContentRepository.fetchAll()` also loads `lessons`, and
  `ContentSnapshot` gains `List<Lesson> lessons`. A lesson whose
  `concept_id` isn't in the loaded concepts is dropped, the same way
  questions are.
- `Content` gains `lessonsForChapter(chapterId)`, ordered by
  `sortOrder`. (The earlier spec's `lessonForConcept()` is dropped;
  nothing here uses it.)
- `TheoryProgressRepository` (new, same shape as
  `LevelProgressRepository`): `fetchAll()` returns the `Set<String>` of
  lesson ids the signed-in user has read; `markRead(lessonId)` upserts
  into `theory_progress`.
- `theoryProgressProvider` (new, same shape as `levelProgressProvider`)
  exposes `isRead(lessonId)` and `readCountForChapter(chapterId)`. It's
  wired in `main.dart` with a `repositoryOverride`, like
  `LevelProgressNotifier`.

### Navigation (`core/router/app_shell.dart`)

- Tabs become **Today · Theory · Mission · Tests · Me**.
- "Skill Map" becomes "Mission": `SkillMapScreen` is renamed
  `MissionListScreen` and moved to
  `features/mission/mission_list_screen.dart`. Behaviour is otherwise
  unchanged (chapter cards, mastery rings, expanding concepts, Practice,
  Start Mission).

### `TheoryScreen` (new, `features/theory/theory_screen.dart`)

- Title "Theory".
- One card per chapter **that has at least one lesson**. Chapters with no
  lessons are not shown. Below the cards, one muted line reads: "More
  chapters coming soon."
- Each card: a ring showing lessons read / total (same look as
  `MasteryRing`, driven by `theoryProgressProvider`), the chapter name,
  and "N lessons". Tapping the card expands it inline, the same way the
  Mission chapter cards expand, to list its lessons. Each row shows the
  lesson title and a read tick.
- Tapping a lesson row pushes `LessonScreen`.
- Empty state (no lessons loaded at all): "Lessons are on their way."

### `LessonScreen` (new, `features/theory/lesson_screen.dart`)

- Title (display font).
- Body text (`MathText`).
- Hook card, styled differently from the body (tinted background,
  accent border), with a small label: "Where this shows up" for
  `real_world`, "A bit of history" for `historical`.
- If `tryIt` is present, a "Try it" card with the prompt text. No input
  and no grading.
- A "Mark as read" button (`ChunkyButton`) at the bottom. It calls
  `markRead`, then goes back to the list. If the lesson is already read,
  the button shows "Read ✓", is disabled, and doesn't write again.
- If `markRead` fails (for example, offline), show a snackbar ("Couldn't
  save — try again") and stay on the screen.

## Part C: Light/dark switch

- New dependency: `shared_preferences`. The theme is a per-device display
  choice, so it's stored on the device, not in Supabase.
- `themeModeProvider` (new, `core/theme/theme_mode.dart`): a Riverpod
  notifier holding a `ThemeMode`. It loads the saved value (key
  `theme_mode`, values `system` / `light` / `dark`) at startup, defaults to
  `system`, and saves on every change. If loading fails, it falls back to
  `system`.
- `StudyGymApp` reads `themeModeProvider` instead of the hard-coded
  `ThemeMode.system`.
- The Me tab stops being a placeholder. `MeScreen` (new,
  `features/me/me_screen.dart`) shows an **Appearance** card with a
  three-way choice: System / Light / Dark. Below it, one muted line:
  "Profile and streak history are coming soon."
- Every new screen in this spec must look right in both themes, and only
  uses colours from `context.colors`.

## Part D: Live database rollout

Applied to the live `study-gym` Supabase project, **only after the user
confirms at that step of the plan**:

1. Migration `20260930000000_theory_lessons.sql`, via the Supabase
   migration tool so it's recorded in the migration history.
2. Seed `005_surface_area_volume_theory.sql` (the 7 lessons).
3. Seed `006_maths_only.sql` (hide non-maths subjects).

Before this goes live, `seed_theory.py` changes to emit
`insert … on conflict (id) do update set …` instead of a plain insert.
Once students have read a lesson, a plain re-seed would fail, so wording
fixes couldn't ship any other way. The regenerated `005` is committed.

After applying, check: 7 lesson rows, science subject `hidden`, and a
signed-in user can read lessons (the same checks as the earlier
rolled-back run).

## Testing

- **App (TDD, `flutter test`):**
  - `content_repository_test`: parses a `lessons` row; drops a non-maths
    chapter row; drops a lesson with an unknown concept.
  - `models_test` and `test_content.dart`: updated for no `Subject`.
  - Mission list tests (renamed from the Skill Map tests): no subject
    switcher; every chapter is listed.
  - `theory_screen_test`: only chapters with lessons appear; the read
    count shows; expanding lists lessons in `sortOrder`.
  - `lesson_screen_test`: hook label per `hookKind`; `tryIt` card only
    when present; Mark as read calls the repository once; an already-read
    lesson shows a disabled "Read ✓".
  - `theme_mode_test`: defaults to System; a saved value loads; changing
    it saves it.
  - `me_screen_test`: choosing Light/Dark updates `themeModeProvider`.
  - Widget tests render in both `AppTheme.light` and `AppTheme.dark`.
  - `flow_smoke_test`: tapping each of the 5 tabs shows its screen.
- **Pipeline (`pytest`):** the suite passes after the Science removal;
  `validate` passes; `test_seed_theory` covers the `on conflict` output.
- **Manual check in the running app:** the Theory tab shows the 7 lessons
  after Part D, and switching Light/Dark in Me changes the whole app
  immediately.

CI still runs only the pipeline tests (`flutter test` isn't in CI yet).
That gap is noted here and out of scope.

## Out of scope

- Lessons for chapters other than Surface Areas & Volumes.
- Class 10 in the app (the maths syllabi stay in the repo only).
- The rest of the Me tab (profile, streak history).
- Gating Mission behind Theory, or cross-tab progress badges.
- Adding `flutter test` or a real-Postgres step to CI.

## Decisions to confirm in review

- The Theory tab shows **only chapters that have lessons**, not every
  chapter with "no lessons yet".
- The theme choice is stored **on the device**, so it doesn't follow the
  student to a second device.
- "Skill Map" is renamed **"Mission"**, as the earlier Theory spec
  decided.

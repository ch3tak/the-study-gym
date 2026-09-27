# Maths-only app, Theory tab, and light/dark switch — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every non-maths subject from the app and repo, build the Theory tab and lesson screen on top of the existing lesson content, add an in-app System/Light/Dark switch, and roll the lesson tables and seeds out to the live database.

**Architecture:** The app keeps its existing pattern: `ContentRepository` fetches everything once at startup into the static `Content` cache; per-user progress lives in a Riverpod `Notifier` backed by a repository set through a static `repositoryOverride` in `main.dart`. The row-to-model logic in `ContentRepository.fetchAll()` moves into a pure `buildSnapshot()` so it can be unit-tested without Supabase. The theme choice is a Riverpod notifier whose initial value is read from `shared_preferences` in `main()` before `runApp`, so there is no flash of the wrong theme.

**Tech Stack:** Flutter 3.47 / Dart, flutter_riverpod 2.6, supabase_flutter 2.8, shared_preferences (new direct dependency, already in `pubspec.lock` transitively); Python 3.11 pipeline with pytest; Supabase Postgres.

**Spec:** `docs/superpowers/specs/2026-09-27-maths-only-theory-tab-theme-design.md`

## Global Constraints

- Class 9 only; the app has no subject concept. Class 10 **maths** syllabi stay in the repo.
- App filters: `subjects.class_id = 'cbse_9'`, `subjects.status = 'live'`, `subjects.code = 'maths'`.
- Tabs, in order: **Today · Theory · Mission · Tests · Me**.
- Copy, verbatim:
  - Test builder intro: "Pick the chapters you want to be tested on."
  - Upgrade sheet: "Build unlimited tests from any chapter, whenever you want to check yourself."
  - Welcome: "We find exactly what you're weak at in Maths,\ntrain it, and show your real progress."
  - Theory footer: "More chapters coming soon." Theory empty state: "Lessons are on their way."
  - Hook labels: "Where this shows up" (`real_world`), "A bit of history" (`historical`).
  - Lesson button: "Mark as read"; already read: "Read ✓" (disabled). Failure snackbar: "Couldn't save — try again".
  - Me: card title "Appearance", options "System" / "Light" / "Dark", footer "Profile and streak history are coming soon."
- Theme stored with `shared_preferences`, key `theme_mode`, values `system` / `light` / `dark`, default `system`, load failure → `system`.
- New screens use only `context.colors` colours and must render in both `AppTheme.light` and `AppTheme.dark`.
- Non-maths DB subject rows are hidden (`status = 'hidden'`), never deleted. `001` is not edited.
- Live database changes (Task 9) happen **only after the user confirms at that step**.
- Commits: no Claude co-author line, no "Generated with Claude Code" footer (user's global instruction).

## Review Focus

1. **App build running against a database without the `lessons` table** (the app code lands before Task 9's migration): startup must not fail; the Theory tab shows "Lessons are on their way." → pinned in Task 4 (`fetchLessonRows` failure yields no lessons).
2. **A student with old mastery rows for a Science concept** (Science was `live` in seed 001): Today's weak-concept pickers call `Content.conceptById`, which throws for a concept that is no longer loaded → pinned in Task 3 (`weakConcepts` skips unknown concepts).
3. **Marking a lesson read while the initial progress fetch is still in flight**: the fetch result must not wipe the fresh read mark → pinned in Task 5 (hydrate merges, doesn't replace).
4. **Double-tapping "Mark as read" on a slow network**: must write once and pop once → pinned in Task 6 (button disabled while saving).
5. **A lesson row with an unexpected `hook_kind`**: skipped, not a crash of the whole content load → pinned in Task 4.

---

## File map

| File | Change |
|---|---|
| `content/syllabus/cbse/9/{science,sst,english,hindi}.yaml`, `content/syllabus/cbse/10/{science,sst,english,hindi_a,hindi_b}.yaml`, `content/questions/cbse/9/science/` | Delete |
| `content/syllabus/cbse/{9,10}/_class.yaml` | Maths subjects only |
| `content/pipeline/subjects.py` | Drop `cbse/9/science` profile |
| `content/pipeline/tests/test_{generate,questions,syllabus}.py` | Drop/replace Science tests |
| `content/pipeline/seed_theory.py`, `tests/test_seed_theory.py` | Upsert output |
| `backend/supabase/seed/005_surface_area_volume_theory.sql` | Regenerated |
| `backend/supabase/seed/006_maths_only.sql` | New |
| `README.md`, `app/pubspec.yaml` | Maths-only wording; `shared_preferences` |
| `app/lib/data/models.dart` | Drop `Subject`, `Chapter.subject`; add `HookKind`, `Lesson` |
| `app/lib/data/content_repository.dart` | Maths filter, `buildSnapshot()`, lessons |
| `app/lib/data/content.dart` | Drop `forSubject`; add lessons, `lessonsForChapter`, `conceptOrNull` |
| `app/lib/data/app_state.dart`, `features/today/today_screen.dart` | Skip unknown concepts |
| `app/lib/data/theory_progress_repository.dart`, `theory_state.dart` | New |
| `app/lib/core/theme/theme_mode.dart` | New |
| `app/lib/core/theme/app_colors.dart` | Drop `scienceAccent` |
| `app/lib/features/theory/{theory_screen,lesson_screen}.dart` | New |
| `app/lib/features/me/me_screen.dart` | New |
| `app/lib/features/skill_map/skill_map_screen.dart` → `features/mission/mission_list_screen.dart` | Rename, no switcher |
| `app/lib/features/tests/custom_test_builder_screen.dart`, `features/onboarding/welcome_screen.dart` | Copy, one list |
| `app/lib/core/router/app_shell.dart`, `app/lib/main.dart` | 5 tabs; theme + theory wiring |
| `app/test/...` | See each task |

---

### Task 1: Pipeline and content — Maths only

**Files:**
- Delete: `content/syllabus/cbse/9/{science,sst,english,hindi}.yaml`, `content/syllabus/cbse/10/{science,sst,english,hindi_a,hindi_b}.yaml`, `content/questions/cbse/9/science/golden.yaml`
- Modify: `content/syllabus/cbse/9/_class.yaml`, `content/syllabus/cbse/10/_class.yaml`, `content/pipeline/subjects.py`, `README.md`
- Test: `content/pipeline/tests/test_generate.py`, `test_questions.py`, `test_syllabus.py`

**Interfaces:** none consumed or produced by later tasks.

- [ ] **Step 1: Replace the Science-dependent tests (they are the failing tests here, because the unit rule will lose its only real syllabus)**

`test_questions.py` — replace the two science tests:

```python
def test_class9_golden_files_are_clean():
    issues = Issues()
    syl = load(syllabus_path("cbse", 9, "maths"), issues, set(REGISTRY))
    qs = load_file(QUESTIONS_ROOT / "cbse" / "9" / "maths" / "golden.yaml", issues)
    validate_bank([("golden", q) for q in qs], syl, issues)
    assert issues.errors == []


def test_numeric_without_unit_is_caught_when_the_syllabus_requires_one(syllabus, golden):
    strict = dataclasses.replace(syllabus, numeric_requires_unit=True)
    q = golden["q_quad_factorise_solve_0001"]
    assert "unit" not in q
    assert "unit: required" in messages(run(strict, q))
```

(add `import dataclasses` at the top.)

`test_syllabus.py` — replace `test_real_class9_syllabi_are_clean` and add a rule test:

```python
def test_real_class9_syllabus_is_clean():
    issues = Issues()
    syl = load(syllabus_path("cbse", 9, "maths"), issues, KNOWN)
    assert issues.errors == []
    assert all(cid.startswith("c9.") for cid in syl.concepts)


def test_numeric_requires_unit_rule_loads(tmp_path):
    syl, issues = load_text(tmp_path, BASE + "\nquestion_rules:\n  numeric_requires_unit: true\n")
    assert issues.errors == []
    assert syl.numeric_requires_unit
```

`test_generate.py` — delete `test_science_plan_uses_science_profile`.

- [ ] **Step 2: Run them**

Run: `.venv/Scripts/python.exe -m pytest content/pipeline/tests -q`
Expected: PASS (the new tests don't depend on Science; this checks they are correct before the deletions).

- [ ] **Step 3: Delete the non-maths content and profile**

```bash
git rm content/syllabus/cbse/9/{science,sst,english,hindi}.yaml \
       content/syllabus/cbse/10/{science,sst,english,hindi_a,hindi_b}.yaml \
       content/questions/cbse/9/science/golden.yaml
```

`subjects.py`: delete the whole `SubjectProfile(key="cbse/9/science", …)` entry.

`content/syllabus/cbse/9/_class.yaml`:

```yaml
# Subjects offered for CBSE Class 9. Maths only (docs/PLAN.md: "Math only. Permanently.").
schema_version: 1
board: {id: cbse, name: CBSE}
class: {grade: 9, academic_year: "2026-27"}

subjects:
  - code: maths
    name: Mathematics
    short_name: Maths
    status: live
    accent_color: "#5B5BD6"
    icon: calculate
    syllabus: maths.yaml

choice_groups: []
```

`content/syllabus/cbse/10/_class.yaml`: keep the header, `maths_standard` and `maths_basic` entries unchanged, delete the science/sst/english/hindi_a/hindi_b entries and the `Hindi course` choice group, and change the header comment to `# Subjects offered for CBSE Class 10. Maths only (docs/PLAN.md: "Math only. Permanently.").`

`README.md` line 7: "CBSE Class 9 Mathematics and Science" → "CBSE Class 9 Mathematics".

- [ ] **Step 4: Run the suite and the validator**

Run: `.venv/Scripts/python.exe -m pytest content/pipeline/tests -q && .venv/Scripts/python.exe -m content.pipeline.validate`
Expected: all pass; validator reports 0 errors and no `science` paths.

- [ ] **Step 5: Commit**

```bash
git add -A content README.md
git commit -m "chore(content): maths only — drop non-maths syllabi, science questions and profile"
```

---

### Task 2: Upsert lesson seed and `006_maths_only.sql`

**Files:**
- Modify: `content/pipeline/seed_theory.py`, `backend/supabase/seed/005_surface_area_volume_theory.sql` (regenerated)
- Create: `backend/supabase/seed/006_maths_only.sql`
- Test: `content/pipeline/tests/test_seed_theory.py`

**Interfaces:** Produces the two seed files Task 9 applies.

- [ ] **Step 1: Failing test**

```python
def test_reseeding_updates_existing_lessons_instead_of_failing():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert "on conflict (id) do update set" in sql
    for col in ("concept_id", "title", "body", "hook_kind", "hook", "try_it", "sort_order"):
        assert f"{col} = excluded.{col}" in sql
    # One statement: the conflict clause closes the values list.
    assert sql.count(";") == 3  # begin; <insert…>; commit;
```

- [ ] **Step 2: Run it** — `.venv/Scripts/python.exe -m pytest content/pipeline/tests/test_seed_theory.py -q` → FAIL (no `on conflict`).

- [ ] **Step 3: Implement** — in `generate_sql`, replace `lines.append(",\n".join(rows) + ";")` with:

```python
    lines.append(",\n".join(rows))
    # Upsert, not a plain insert: once students have read a lesson,
    # theory_progress references it, so a wording fix must update the row
    # in place rather than delete-and-reinsert.
    lines.append("on conflict (id) do update set")
    cols = ["concept_id", "title", "body", "hook_kind", "hook", "try_it", "sort_order"]
    lines.append(",\n".join(f"  {c} = excluded.{c}" for c in cols) + ";")
```

Note: lesson prose may contain `;`. If the count assertion trips on real prose it won't here — the fixture is checked. Keep the assertion on the fixture only.

- [ ] **Step 4: Regenerate and run** — `.venv/Scripts/python.exe -m content.pipeline.seed_theory && .venv/Scripts/python.exe -m pytest content/pipeline/tests -q` → PASS; `git diff backend/supabase/seed/005*` shows only the conflict clause added.

- [ ] **Step 5: Create `backend/supabase/seed/006_maths_only.sql`**

```sql
-- Maths only (docs/PLAN.md: "Math only. Permanently."). Hides every
-- non-maths Class 9 subject. The read_subjects policy (status <> 'hidden')
-- then keeps them from every client. Rows are kept, not deleted, so
-- chapters, questions and attempts that reference them stay intact.
-- A new file rather than an edit to 001, which is already applied live.
-- Safe to re-run.

begin;

update subjects
set status = 'hidden'
where class_id = 'cbse_9'
  and code <> 'maths';

commit;
```

- [ ] **Step 6: Commit**

```bash
git add content/pipeline/seed_theory.py content/pipeline/tests/test_seed_theory.py backend/supabase/seed/005_surface_area_volume_theory.sql backend/supabase/seed/006_maths_only.sql
git commit -m "feat(db): lesson seed upserts on id; add 006 seed hiding non-maths subjects"
```

---

### Task 3: App — remove the subject concept

**Files:**
- Modify: `app/lib/data/models.dart`, `app/lib/data/content_repository.dart`, `app/lib/data/content.dart`, `app/lib/data/app_state.dart`, `app/lib/features/today/today_screen.dart`, `app/lib/features/skill_map/skill_map_screen.dart`, `app/lib/features/tests/custom_test_builder_screen.dart`, `app/lib/features/onboarding/welcome_screen.dart`, `app/lib/core/theme/app_colors.dart`, `app/pubspec.yaml` (description)
- Test: `app/test/data/content_repository_test.dart`, `app/test/app_state_test.dart`, `app/test/test_content.dart`, `app/test/flow_smoke_test.dart`, `app/test/features/skill_map/skill_map_screen_test.dart`, `app/test/features/mission/mission_screen_test.dart`, `app/test/features/workout/workout_screen_test.dart`

**Interfaces:**
- Produces: `ContentRepository.buildSnapshot({required List chapterRows, required List conceptRows, required List questionRows})` → `ContentSnapshot` (Task 4 adds `lessonRows`). `Content.conceptOrNull(String id)` → `Concept?`. `Chapter` has no `subject`.

- [ ] **Step 1: Failing tests**

`content_repository_test.dart` — add:

```dart
  Map<String, dynamic> chapterRow(String id, String subjectCode) => {
        'id': id,
        'name': id,
        'board_weight': 6,
        'sort_order': 1,
        'subjects': {'class_id': 'cbse_9', 'code': subjectCode, 'status': 'live'},
      };

  test('a non-maths chapter row is dropped even if its subject is live', () {
    final snapshot = ContentRepository.forTesting().buildSnapshot(
      chapterRows: [chapterRow('surface_area_volume', 'maths'), chapterRow('motion', 'science')],
      conceptRows: [
        {'id': 'c9.sav.cuboid_cube', 'chapter_id': 'surface_area_volume', 'name': 'Cuboids'},
        {'id': 'c9.motion.speed', 'chapter_id': 'motion', 'name': 'Speed'},
      ],
      questionRows: const [],
    );
    expect(snapshot.chapters.map((c) => c.id), ['surface_area_volume']);
  });
```

`app_state_test.dart` — add:

```dart
  test('weakConcepts skips mastery rows for concepts that are no longer loaded', () {
    Content.load(const ContentSnapshot(chapters: [], questions: []));
    final state = StudentState(mastery: {
      'c9.motion.speed': ConceptMastery(conceptId: 'c9.motion.speed', masteryPercent: 10, attempts: 2),
    });
    expect(state.weakConcepts, isEmpty);
  });
```

(imports: `package:study_gym/data/content.dart`, `content_repository.dart`, `models.dart`.)

- [ ] **Step 2: Run** — `cd app && flutter test test/data/content_repository_test.dart test/app_state_test.dart` → FAIL (`buildSnapshot` undefined; `weakConcepts` throws `StateError`).

- [ ] **Step 3: Implement**

`models.dart`: delete `enum Subject` and `extension SubjectX`; delete `required this.subject` and `final Subject subject;` from `Chapter`.

`content.dart`: delete `forSubject`; update the class doc ("Maths+Science" → "Maths"); add

```dart
  /// Null when [id] isn't in the loaded content — e.g. an old mastery row
  /// for a concept whose subject is no longer served.
  static Concept? conceptOrNull(String id) {
    for (final c in chapters.expand((c) => c.concepts)) {
      if (c.id == id) return c;
    }
    return null;
  }
```

`content_repository.dart`: `fetchAll()` keeps the three queries (adding `.eq('subjects.code', 'maths')` to the chapter query, and replacing the Science comment with: "Maths only, whatever a status flag says — the code filter is what keeps a non-maths subject out, not `status`."), then `return buildSnapshot(chapterRows: chapterRows as List, conceptRows: conceptRows as List, questionRows: questionRows as List);`. Everything after the queries moves into:

```dart
  /// Turns raw rows into a snapshot. Pure (no network) so it's unit-tested
  /// directly. Re-checks `subjects.code` client-side as well as in the query.
  @visibleForTesting
  ContentSnapshot buildSnapshot({
    required List chapterRows,
    required List conceptRows,
    required List questionRows,
  }) {
    final mathsChapterRows =
        chapterRows.where((r) => (r['subjects'] as Map)['code'] == 'maths').toList();
    final validChapterIds = mathsChapterRows.map((r) => r['id'] as String).toSet();
    // … existing concept grouping, using validChapterIds …
    // … existing chapter building over mathsChapterRows, without `subject:` …
    // … existing question loop over questionRows …
    return ContentSnapshot(chapters: chapters, questions: questions);
  }
```

`app_state.dart` `weakConcepts`:

```dart
    return entries
        .map((m) => Content.conceptOrNull(m.conceptId))
        .whereType<Concept>()
        .take(3)
        .toList();
```

`today_screen.dart` `_pickWorkoutConcepts`: same `.map(Content.conceptOrNull).whereType<Concept>().take(3)` in place of `.take(3).map(Content.conceptById)`.

`skill_map_screen.dart`: delete `_subject`, the switcher `Padding` + its following `SizedBox`, and the `_SubjectSwitcher` class; `final chapters = Content.chapters;`; doc comment drops "Subject switcher pill row per §3.". Drop the `onChanged` reset of `_expandedChapterId` along with it.

`custom_test_builder_screen.dart`: intro text → `'Pick the chapters you want to be tested on.'`; replace the `for (final subject in Subject.values) ...[ … ]` block with:

```dart
                  ...Content.chapters.map((chapter) {
                    final selected = _selectedChapterIds.contains(chapter.id);
                    return _ChapterCheckTile(
                      chapter: chapter,
                      selected: selected,
                      onTap: () => setState(() {
                        selected ? _selectedChapterIds.remove(chapter.id) : _selectedChapterIds.add(chapter.id);
                      }),
                    );
                  }),
```

Upgrade sheet → `'Build unlimited tests from any chapter, whenever you want to check yourself.'`; class doc "(across subjects)" → drop. Remove the now-unused `models.dart` import only if the analyzer flags it (`_ChapterCheckTile` still uses `Chapter`).

`welcome_screen.dart`: `"We find exactly what you're weak at in Maths,\ntrain it, and show your real progress."`

`app_colors.dart`: remove `scienceAccent` from the constructor, field, both palettes, `copyWith` (param + body) and `lerp`. Comment `// Subject accents` → `// Subject accent`.

`pubspec.yaml` description → `"Study Gym: a daily practice workout for CBSE Class 9 Maths."`

Tests: delete every `subject: Subject.maths,` line (`skill_map_screen_test.dart`, `mission_screen_test.dart`, `workout_screen_test.dart`). `test_content.dart`: replace the Motion chapter and `q_speed_1` with a second maths chapter:

```dart
    Chapter(
      id: 'surface_area_volume',
      name: 'Surface Areas and Volumes',
      boardWeightMarks: 6,
      concepts: [
        Concept(id: 'c9.sav.cuboid_cube', name: 'Cuboids and cubes', chapterId: 'surface_area_volume'),
      ],
    ),
```

```dart
    Question(
      id: 'q_cube_1',
      conceptId: 'c9.sav.cuboid_cube',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 'A cube has side 6 cm. Find its volume.',
      numericAnswer: '216',
      unit: 'cm^3',
      solutionSteps: const ['V = 6 × 6 × 6 = 216 cm³'],
    ),
```

and fix its doc comment ("Maths+Science" → "Maths"). `flow_smoke_test.dart` custom-builder test: replace the Maths/Science header expectations with

```dart
    expect(find.text('Maths'), findsNothing);
    expect(find.text('Science'), findsNothing);
    expect(find.text('Sequences and Progressions'), findsOneWidget);
    expect(find.text('Surface Areas and Volumes'), findsOneWidget);
```

and in the first test drop `expect(find.text('Maths'), findsWidgets);`.

- [ ] **Step 4: Run** — `flutter analyze && flutter test` → no issues, all pass. Also `grep -rn "Subject\b\|scienceAccent\|forSubject" lib test` → no hits.

- [ ] **Step 5: Commit** — `git commit -am "feat(app): maths only — drop Subject, switcher and science copy"` (plus `git add` of any new file).

---

### Task 4: App — `Lesson` model and loading

**Files:**
- Modify: `app/lib/data/models.dart`, `app/lib/data/content_repository.dart`, `app/lib/data/content.dart`
- Test: `app/test/data/content_repository_test.dart`, `app/test/data/models_test.dart`

**Interfaces:**
- Consumes: `buildSnapshot` (Task 3).
- Produces: `enum HookKind { historical, realWorld }`; `class Lesson { id, conceptId, title, body, hookKind, hook, tryIt (String?), sortOrder (int) }`; `ContentSnapshot.lessons` (`List<Lesson>`, defaults to `const []`); `buildSnapshot(..., List lessonRows = const [])`; `Content.lessons`; `Content.lessonsForChapter(String chapterId)` → `List<Lesson>` sorted by `sortOrder`.

- [ ] **Step 1: Failing tests** (`content_repository_test.dart`)

```dart
  Map<String, dynamic> lessonRow(String id, String conceptId, {String hookKind = 'real_world', String? tryIt, int sortOrder = 1}) => {
        'id': id,
        'concept_id': conceptId,
        'title': 'Title $id',
        'body': 'Body with \$x^2\$.',
        'hook_kind': hookKind,
        'hook': 'Hook $id',
        'try_it': tryIt,
        'sort_order': sortOrder,
      };

  ContentSnapshot snapshotWithLessons(List<Map<String, dynamic>> lessonRows) =>
      ContentRepository.forTesting().buildSnapshot(
        chapterRows: [chapterRow('surface_area_volume', 'maths')],
        conceptRows: [
          {'id': 'c9.sav.cuboid_cube', 'chapter_id': 'surface_area_volume', 'name': 'Cuboids'},
        ],
        questionRows: const [],
        lessonRows: lessonRows,
      );

  test('a lessons row parses into a Lesson', () {
    final s = snapshotWithLessons([
      lessonRow('t_a', 'c9.sav.cuboid_cube', hookKind: 'historical', tryIt: 'Try this', sortOrder: 3),
    ]);
    final l = s.lessons.single;
    expect(l.id, 't_a');
    expect(l.conceptId, 'c9.sav.cuboid_cube');
    expect(l.title, 'Title t_a');
    expect(l.body, r'Body with $x^2$.');
    expect(l.hookKind, HookKind.historical);
    expect(l.hook, 'Hook t_a');
    expect(l.tryIt, 'Try this');
    expect(l.sortOrder, 3);
  });

  test('try_it is optional and real_world maps to HookKind.realWorld', () {
    final l = snapshotWithLessons([lessonRow('t_a', 'c9.sav.cuboid_cube')]).lessons.single;
    expect(l.tryIt, isNull);
    expect(l.hookKind, HookKind.realWorld);
  });

  test('a lesson whose concept is not loaded is dropped', () {
    final s = snapshotWithLessons([
      lessonRow('t_a', 'c9.sav.cuboid_cube'),
      lessonRow('t_ghost', 'c9.motion.speed'),
    ]);
    expect(s.lessons.map((l) => l.id), ['t_a']);
  });

  test('a lesson with an unknown hook_kind is skipped, not fatal', () {
    final s = snapshotWithLessons([
      lessonRow('t_a', 'c9.sav.cuboid_cube'),
      lessonRow('t_bad', 'c9.sav.cuboid_cube', hookKind: 'fun_fact'),
    ]);
    expect(s.lessons.map((l) => l.id), ['t_a']);
  });

  test('lessonsForChapter orders by sortOrder', () {
    Content.load(snapshotWithLessons([
      lessonRow('t_b', 'c9.sav.cuboid_cube', sortOrder: 2),
      lessonRow('t_a', 'c9.sav.cuboid_cube', sortOrder: 1),
    ]));
    expect(Content.lessonsForChapter('surface_area_volume').map((l) => l.id), ['t_a', 't_b']);
    expect(Content.lessonsForChapter('no_such_chapter'), isEmpty);
  });
```

- [ ] **Step 2: Run** — `flutter test test/data/content_repository_test.dart` → FAIL (no `lessonRows`, `Lesson`, `HookKind`).

- [ ] **Step 3: Implement**

`models.dart`:

```dart
enum HookKind { historical, realWorld }

/// A short theory lesson for one concept — mirrors the `lessons` table
/// (20260930000000_theory_lessons.sql).
class Lesson {
  const Lesson({
    required this.id,
    required this.conceptId,
    required this.title,
    required this.body,
    required this.hookKind,
    required this.hook,
    this.tryIt,
    required this.sortOrder,
  });

  final String id;
  final String conceptId;
  final String title;
  final String body;
  final HookKind hookKind;
  final String hook;
  final String? tryIt;
  final int sortOrder;
}
```

`content_repository.dart`:
- `ContentSnapshot` gains `this.lessons = const []` / `final List<Lesson> lessons;`.
- `buildSnapshot` gains `List lessonRows = const []`; after questions:

```dart
    final lessons = <Lesson>[];
    for (final row in lessonRows) {
      if (!validConceptIds.contains(row['concept_id'])) continue;
      final hookKind = switch (row['hook_kind']) {
        'historical' => HookKind.historical,
        'real_world' => HookKind.realWorld,
        _ => null,
      };
      if (hookKind == null) {
        debugPrint('Skipping lesson ${row['id']}: unknown hook_kind ${row['hook_kind']}');
        continue;
      }
      lessons.add(Lesson(
        id: row['id'] as String,
        conceptId: row['concept_id'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        hookKind: hookKind,
        hook: row['hook'] as String,
        tryIt: row['try_it'] as String?,
        sortOrder: (row['sort_order'] as num).toInt(),
      ));
    }
    return ContentSnapshot(chapters: chapters, questions: questions, lessons: lessons);
```

- `fetchAll()` fetches lessons after questions, tolerating a database that doesn't have the table yet:

```dart
    // Lessons are optional: a database without the lessons table (or a
    // failed fetch) gives an empty Theory tab, not a failed app start.
    List lessonRows = const [];
    try {
      lessonRows = await _client
          .from('lessons')
          .select('id, concept_id, title, body, hook_kind, hook, try_it, sort_order')
          .order('sort_order') as List;
    } on PostgrestException catch (e) {
      debugPrint('Lessons unavailable: ${e.message}');
    }
```

`content.dart`: `static List<Lesson> _lessons = const [];`, set in `load()`, getter `lessons`, and

```dart
  static List<Lesson> lessonsForChapter(String chapterId) {
    final conceptIds = chapters
        .where((c) => c.id == chapterId)
        .expand((c) => c.concepts)
        .map((c) => c.id)
        .toSet();
    return lessons.where((l) => conceptIds.contains(l.conceptId)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
```

- [ ] **Step 4: Run** — `flutter analyze && flutter test` → all pass.

- [ ] **Step 5: Commit** — `git commit -am "feat(app): load theory lessons into Content"`

---

### Task 5: App — theory progress repository and provider

**Files:**
- Create: `app/lib/data/theory_progress_repository.dart`, `app/lib/data/theory_state.dart`
- Modify: `app/lib/main.dart`
- Test: `app/test/data/theory_state_test.dart`

**Interfaces:**
- Consumes: `Content.lessonsForChapter` (Task 4).
- Produces: `TheoryProgressRepository(SupabaseClient)` with `Future<Set<String>> fetchAll()` and `Future<void> markRead(String lessonId)`; `TheoryProgressState { Set<String> readLessonIds; bool isRead(String); int readCountForChapter(String) }`; `TheoryProgressNotifier` with `static TheoryProgressRepository? repositoryOverride` and `Future<void> markRead(String lessonId)` (throws if the write fails; no-op if already read); `theoryProgressProvider`.

- [ ] **Step 1: Failing tests** (`test/data/theory_state_test.dart`)

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_progress_repository.dart';
import 'package:study_gym/data/theory_state.dart';

class FakeTheoryRepo implements TheoryProgressRepository {
  FakeTheoryRepo({Set<String>? initial, this.failWrites = false}) : _initial = initial ?? {};
  final Set<String> _initial;
  final bool failWrites;
  final writes = <String>[];
  Completer<Set<String>>? fetchGate;

  @override
  Future<Set<String>> fetchAll() => fetchGate?.future ?? Future.value(_initial);

  @override
  Future<void> markRead(String lessonId) async {
    if (failWrites) throw Exception('offline');
    writes.add(lessonId);
  }
}

Lesson lesson(String id, String conceptId, int order) => Lesson(
      id: id, conceptId: conceptId, title: id, body: 'b',
      hookKind: HookKind.realWorld, hook: 'h', sortOrder: order);

void main() {
  setUp(() {
    Content.load(ContentSnapshot(
      chapters: const [
        Chapter(id: 'sav', name: 'SAV', boardWeightMarks: 6, concepts: [
          Concept(id: 'c.cube', name: 'Cube', chapterId: 'sav'),
        ]),
      ],
      questions: const [],
      lessons: [lesson('t1', 'c.cube', 1), lesson('t2', 'c.cube', 2)],
    ));
  });
  tearDown(() => TheoryProgressNotifier.repositoryOverride = null);

  test('hydrates read lessons and counts them per chapter', () async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(initial: {'t1'});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(theoryProgressProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(theoryProgressProvider).isRead('t1'), isTrue);
    expect(c.read(theoryProgressProvider).readCountForChapter('sav'), 1);
  });

  test('markRead writes once and marks the lesson read', () async {
    final repo = FakeTheoryRepo();
    TheoryProgressNotifier.repositoryOverride = repo;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(theoryProgressProvider.notifier).markRead('t2');
    await c.read(theoryProgressProvider.notifier).markRead('t2');
    expect(repo.writes, ['t2']);
    expect(c.read(theoryProgressProvider).isRead('t2'), isTrue);
  });

  test('a failed write throws and leaves the lesson unread', () async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(failWrites: true);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await expectLater(c.read(theoryProgressProvider.notifier).markRead('t1'), throwsException);
    expect(c.read(theoryProgressProvider).isRead('t1'), isFalse);
  });

  test('a slow initial fetch does not wipe a lesson marked read meanwhile', () async {
    final repo = FakeTheoryRepo()..fetchGate = Completer<Set<String>>();
    TheoryProgressNotifier.repositoryOverride = repo;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(theoryProgressProvider);
    await c.read(theoryProgressProvider.notifier).markRead('t2');
    repo.fetchGate!.complete({'t1'});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(theoryProgressProvider).readLessonIds, {'t1', 't2'});
  });
}
```

- [ ] **Step 2: Run** — `flutter test test/data/theory_state_test.dart` → FAIL (files missing).

- [ ] **Step 3: Implement**

`theory_progress_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes the per-student `theory_progress` table. RLS scopes every
/// row to `auth.uid()` — same shape as `LevelProgressRepository`.
class TheoryProgressRepository {
  TheoryProgressRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No signed-in user — cannot read/write theory progress.');
    }
    return id;
  }

  /// Ids of every lesson the signed-in user has marked read.
  Future<Set<String>> fetchAll() async {
    final rows = await _client.from('theory_progress').select('lesson_id').eq('user_id', _userId);
    return {for (final row in rows as List) row['lesson_id'] as String};
  }

  Future<void> markRead(String lessonId) async {
    await _client.from('theory_progress').upsert({
      'user_id': _userId,
      'lesson_id': lessonId,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
```

`theory_state.dart`:

```dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content.dart';
import 'theory_progress_repository.dart';

class TheoryProgressState {
  const TheoryProgressState({this.readLessonIds = const {}});

  final Set<String> readLessonIds;

  bool isRead(String lessonId) => readLessonIds.contains(lessonId);

  int readCountForChapter(String chapterId) =>
      Content.lessonsForChapter(chapterId).where((l) => isRead(l.id)).length;
}

class TheoryProgressNotifier extends Notifier<TheoryProgressState> {
  /// Set by `main.dart`; null in tests that don't need persistence.
  static TheoryProgressRepository? repositoryOverride;

  TheoryProgressRepository? get _repo => repositoryOverride;

  @override
  TheoryProgressState build() {
    if (_repo != null) _hydrate();
    return const TheoryProgressState();
  }

  Future<void> _hydrate() async {
    try {
      final fetched = await _repo!.fetchAll();
      // Merge, don't replace: a lesson marked read while this fetch was in
      // flight must stay read.
      state = TheoryProgressState(readLessonIds: {...fetched, ...state.readLessonIds});
    } catch (e) {
      debugPrint('Could not load theory progress: $e');
    }
  }

  /// Writes first, then updates state, so a failed write (e.g. offline)
  /// throws to the caller and the lesson stays unread. No-op if already read.
  Future<void> markRead(String lessonId) async {
    if (state.isRead(lessonId)) return;
    await _repo?.markRead(lessonId);
    state = TheoryProgressState(readLessonIds: {...state.readLessonIds, lessonId});
  }
}

final theoryProgressProvider = NotifierProvider<TheoryProgressNotifier, TheoryProgressState>(
  TheoryProgressNotifier.new,
);
```

`main.dart`: after the `LevelProgressNotifier` line add
`TheoryProgressNotifier.repositoryOverride = TheoryProgressRepository(Supabase.instance.client);` with the two imports.

- [ ] **Step 4: Run** — `flutter analyze && flutter test` → all pass.

- [ ] **Step 5: Commit** — `git add lib/data/theory_* test/data/theory_state_test.dart && git commit -am "feat(app): theory progress repository and provider"`

---

### Task 6: App — `TheoryScreen` and `LessonScreen`

**Files:**
- Create: `app/lib/features/theory/theory_screen.dart`, `app/lib/features/theory/lesson_screen.dart`
- Test: `app/test/features/theory/theory_screen_test.dart`, `app/test/features/theory/lesson_screen_test.dart`, `app/test/features/theory/theory_fixtures.dart`

**Interfaces:**
- Consumes: `Content.lessonsForChapter`, `Content.chapters`, `theoryProgressProvider`, `TheoryProgressNotifier.repositoryOverride`, `MasteryRing`, `ChunkyButton`, `MathText`.
- Produces: `TheoryScreen()` and `LessonScreen({required Lesson lesson})`.

- [ ] **Step 1: Shared fixtures** (`test/features/theory/theory_fixtures.dart`)

```dart
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_progress_repository.dart';

class FakeTheoryRepo implements TheoryProgressRepository {
  FakeTheoryRepo({Set<String>? initial, this.failWrites = false}) : _initial = initial ?? {};
  final Set<String> _initial;
  final bool failWrites;
  final writes = <String>[];

  @override
  Future<Set<String>> fetchAll() async => _initial;

  @override
  Future<void> markRead(String lessonId) async {
    if (failWrites) throw Exception('offline');
    writes.add(lessonId);
  }
}

const cube = Lesson(
  id: 't_cube', conceptId: 'c.cube', title: 'Cuboids & Cubes', body: 'A cube has 6 faces.',
  hookKind: HookKind.realWorld, hook: 'Boxes are cuboids.', tryIt: 'Measure a shoebox.', sortOrder: 1);
const pyramid = Lesson(
  id: 't_pyr', conceptId: 'c.pyr', title: 'Pyramids', body: 'A pyramid has an apex.',
  hookKind: HookKind.historical, hook: 'Egyptian scrolls.', sortOrder: 2);

/// Two chapters; only 'sav' has lessons (added out of order on purpose).
void loadTheoryContent() {
  Content.load(const ContentSnapshot(
    chapters: [
      Chapter(id: 'sav', name: 'Surface Areas and Volumes', boardWeightMarks: 6, concepts: [
        Concept(id: 'c.cube', name: 'Cube', chapterId: 'sav'),
        Concept(id: 'c.pyr', name: 'Pyramid', chapterId: 'sav'),
      ]),
      Chapter(id: 'seq', name: 'Sequences and Progressions', boardWeightMarks: 6, concepts: [
        Concept(id: 'c.ap', name: 'AP', chapterId: 'seq'),
      ]),
    ],
    questions: [],
    lessons: [pyramid, cube],
  ));
}
```

(Move `FakeTheoryRepo` out of `theory_state_test.dart` too — import it from here, and give this copy the `fetchGate` field from Task 5 so there's one fake.)

- [ ] **Step 2: Failing tests**

`theory_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/theory/lesson_screen.dart';
import 'package:study_gym/features/theory/theory_screen.dart';

import 'theory_fixtures.dart';

Future<void> pumpTheory(WidgetTester tester, {ThemeData? theme}) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(theme: theme ?? AppTheme.light, home: const TheoryScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(loadTheoryContent);
  tearDown(() => TheoryProgressNotifier.repositoryOverride = null);

  testWidgets('only chapters with lessons appear, with a coming-soon footer', (tester) async {
    await pumpTheory(tester);
    expect(find.text('Theory'), findsOneWidget);
    expect(find.text('Surface Areas and Volumes'), findsOneWidget);
    expect(find.text('Sequences and Progressions'), findsNothing);
    expect(find.text('2 lessons'), findsOneWidget);
    expect(find.text('More chapters coming soon.'), findsOneWidget);
  });

  testWidgets('the ring shows lessons read out of total', (tester) async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(initial: {'t_cube'});
    await pumpTheory(tester);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('expanding lists lessons in sortOrder with read ticks', (tester) async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(initial: {'t_cube'});
    await pumpTheory(tester);
    await tester.tap(find.text('Surface Areas and Volumes'));
    await tester.pumpAndSettle();
    final cubeY = tester.getTopLeft(find.text('Cuboids & Cubes')).dy;
    final pyrY = tester.getTopLeft(find.text('Pyramids')).dy;
    expect(cubeY, lessThan(pyrY));
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('tapping a lesson opens LessonScreen', (tester) async {
    await pumpTheory(tester);
    await tester.tap(find.text('Surface Areas and Volumes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pyramids'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('no lessons at all shows the empty state', (tester) async {
    Content.load(const ContentSnapshot(chapters: [], questions: []));
    await pumpTheory(tester);
    expect(find.text('Lessons are on their way.'), findsOneWidget);
  });

  for (final (name, theme) in [('light', AppTheme.light), ('dark', AppTheme.dark)]) {
    testWidgets('renders expanded in $name theme', (tester) async {
      await pumpTheory(tester, theme: theme);
      await tester.tap(find.text('Surface Areas and Volumes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
```

`lesson_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/theory_state.dart';
import 'package:study_gym/features/theory/lesson_screen.dart';

import 'theory_fixtures.dart';

/// Pushes the lesson on top of a placeholder so "goes back" is observable.
Future<void> pumpLesson(WidgetTester tester, Lesson lesson, {ThemeData? theme}) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
            ),
            child: const Text('list'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('list'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(loadTheoryContent);
  tearDown(() => TheoryProgressNotifier.repositoryOverride = null);

  testWidgets('real_world hook label and a Try it card when present', (tester) async {
    await pumpLesson(tester, cube);
    expect(find.text('Cuboids & Cubes'), findsOneWidget);
    expect(find.text('Where this shows up'), findsOneWidget);
    expect(find.text('Try it'), findsOneWidget);
    expect(find.text('Measure a shoebox.'), findsOneWidget);
  });

  testWidgets('historical hook label and no Try it card when absent', (tester) async {
    await pumpLesson(tester, pyramid);
    expect(find.text('A bit of history'), findsOneWidget);
    expect(find.text('Try it'), findsNothing);
  });

  testWidgets('Mark as read writes once and goes back', (tester) async {
    final repo = FakeTheoryRepo();
    TheoryProgressNotifier.repositoryOverride = repo;
    await pumpLesson(tester, cube);
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();
    expect(repo.writes, ['t_cube']);
    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('an already-read lesson shows a disabled Read ✓ and never writes', (tester) async {
    final repo = FakeTheoryRepo(initial: {'t_cube'});
    TheoryProgressNotifier.repositoryOverride = repo;
    await pumpLesson(tester, cube);
    expect(find.text('Read ✓'), findsOneWidget);
    await tester.tap(find.text('Read ✓'));
    await tester.pumpAndSettle();
    expect(repo.writes, isEmpty);
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('a failed save shows a snackbar and stays', (tester) async {
    TheoryProgressNotifier.repositoryOverride = FakeTheoryRepo(failWrites: true);
    await pumpLesson(tester, cube);
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save — try again"), findsOneWidget);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('Mark as read'), findsOneWidget);
  });

  for (final (name, theme) in [('light', AppTheme.light), ('dark', AppTheme.dark)]) {
    testWidgets('renders in $name theme', (tester) async {
      await pumpLesson(tester, cube, theme: theme);
      expect(tester.takeException(), isNull);
    });
  }
}
```

- [ ] **Step 3: Run** — `flutter test test/features/theory` → FAIL (screens missing).

- [ ] **Step 4: Implement**

`lesson_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../data/theory_state.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/math_text.dart';

/// One theory lesson: title, body, a hook card, an optional "Try it"
/// prompt (no input, no grading), and "Mark as read".
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _saving = false;

  Future<void> _markRead() async {
    setState(() => _saving = true);
    try {
      await ref.read(theoryProgressProvider.notifier).markRead(widget.lesson.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save — try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final textTheme = Theme.of(context).textTheme;
    final isRead = ref.watch(theoryProgressProvider).isRead(lesson.id);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space24),
                children: [
                  Text(lesson.title, style: textTheme.headlineLarge),
                  const SizedBox(height: AppTheme.space16),
                  MathText(lesson.body, style: textTheme.bodyLarge),
                  const SizedBox(height: AppTheme.space20),
                  _HookCard(lesson: lesson),
                  if (lesson.tryIt != null) ...[
                    const SizedBox(height: AppTheme.space16),
                    _TryItCard(prompt: lesson.tryIt!),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space20),
              child: ChunkyButton(
                label: isRead ? 'Read ✓' : 'Mark as read',
                onPressed: isRead || _saving ? null : _markRead,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HookCard extends StatelessWidget {
  const _HookCard({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, icon) = switch (lesson.hookKind) {
      HookKind.realWorld => ('Where this shows up', Icons.public_rounded),
      HookKind.historical => ('A bit of history', Icons.history_edu_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
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
              Icon(icon, size: 16, color: colors.inkSoft),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: colors.inkSoft, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          MathText(lesson.hook, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink)),
        ],
      ),
    );
  }
}

class _TryItCard extends StatelessWidget {
  const _TryItCard({required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: colors.inkSoft),
              const SizedBox(width: 6),
              Text('Try it', style: TextStyle(color: colors.inkSoft, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          MathText(prompt, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

`theory_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/theory_state.dart';
import '../../shared/widgets/mastery_ring.dart';
import 'lesson_screen.dart';

/// Theory tab: one card per chapter that has lessons, with a lessons-read
/// ring; tapping expands the lesson list, tapping a lesson opens it.
class TheoryScreen extends StatefulWidget {
  const TheoryScreen({super.key});

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen> {
  String? _expandedChapterId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chapters = Content.chapters.where((c) => Content.lessonsForChapter(c.id).isNotEmpty).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, 0),
              child: Text('Theory', style: Theme.of(context).textTheme.headlineLarge),
            ),
            const SizedBox(height: AppTheme.space16),
            Expanded(
              child: chapters.isEmpty
                  ? Center(
                      child: Text(
                        'Lessons are on their way.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppTheme.space20, 0, AppTheme.space20, AppTheme.space24),
                      children: [
                        for (final chapter in chapters) ...[
                          _TheoryChapterCard(
                            chapter: chapter,
                            expanded: _expandedChapterId == chapter.id,
                            onToggle: () => setState(() {
                              _expandedChapterId = _expandedChapterId == chapter.id ? null : chapter.id;
                            }),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'More chapters coming soon.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TheoryChapterCard extends ConsumerWidget {
  const _TheoryChapterCard({required this.chapter, required this.expanded, required this.onToggle});
  final Chapter chapter;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final lessons = Content.lessonsForChapter(chapter.id);
    final progress = ref.watch(theoryProgressProvider);
    final read = progress.readCountForChapter(chapter.id);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                children: [
                  MasteryRing(
                    progress: lessons.isEmpty ? 0 : read / lessons.length,
                    size: 48,
                    strokeWidth: 5,
                    child: Text('$read/${lessons.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chapter.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          lessons.length == 1 ? '1 lesson' : '${lessons.length} lessons',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkFaint, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: colors.inkFaint),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  for (final lesson in lessons) _LessonRow(lesson: lesson, read: progress.isRead(lesson.id)),
                ],
              ),
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.read});
  final Lesson lesson;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  read ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 20,
                  color: read ? colors.mastered : colors.notStarted,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(lesson.title, style: Theme.of(context).textTheme.bodyMedium)),
                Icon(Icons.chevron_right_rounded, color: colors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

Note: `AnimatedCrossFade` keeps the collapsed lesson rows in the tree (offstage), so tests tap the chapter first; `find.text` skips offstage widgets.

- [ ] **Step 5: Run** — `flutter analyze && flutter test` → all pass.

- [ ] **Step 6: Commit** — `git add lib/features/theory test/features/theory test/data/theory_state_test.dart && git commit -m "feat(app): Theory tab screen and lesson screen"`

---

### Task 7: App — light/dark switch and Me screen

**Files:**
- Modify: `app/pubspec.yaml`, `app/lib/main.dart`
- Create: `app/lib/core/theme/theme_mode.dart`, `app/lib/features/me/me_screen.dart`
- Test: `app/test/core/theme_mode_test.dart`, `app/test/features/me/me_screen_test.dart`

**Interfaces:**
- Produces: `ThemeModeNotifier` with `static const prefsKey = 'theme_mode'`, `static ThemeMode initial`, `static Future<ThemeMode> loadSaved()`, `Future<void> setMode(ThemeMode)`; `themeModeProvider` (`NotifierProvider<ThemeModeNotifier, ThemeMode>`); `MeScreen()`.

- [ ] **Step 1: Add the dependency** — `cd app && flutter pub add shared_preferences`.

- [ ] **Step 2: Failing tests**

`test/core/theme_mode_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_gym/core/theme/theme_mode.dart';

void main() {
  setUp(() => ThemeModeNotifier.initial = ThemeMode.system);

  test('defaults to System when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ThemeModeNotifier.loadSaved(), ThemeMode.system);
  });

  test('a saved value loads', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    expect(await ThemeModeNotifier.loadSaved(), ThemeMode.dark);
  });

  test('an unrecognised saved value falls back to System', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    expect(await ThemeModeNotifier.loadSaved(), ThemeMode.system);
  });

  test('the provider starts from the loaded value', () {
    ThemeModeNotifier.initial = ThemeMode.light;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  test('changing it updates state and saves it', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(c.read(themeModeProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
```

`test/features/me/me_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_gym/core/theme/app_theme.dart';
import 'package:study_gym/core/theme/theme_mode.dart';
import 'package:study_gym/features/me/me_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeModeNotifier.initial = ThemeMode.system;
  });

  Future<ProviderContainer> pumpMe(WidgetTester tester, ThemeData theme) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: theme, home: const MeScreen()),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows the Appearance choice and the coming-soon line', (tester) async {
    await pumpMe(tester, AppTheme.light);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Profile and streak history are coming soon.'), findsOneWidget);
  });

  testWidgets('choosing Dark then Light updates themeModeProvider', (tester) async {
    final c = await pumpMe(tester, AppTheme.light);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(c.read(themeModeProvider), ThemeMode.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('renders in dark theme', (tester) async {
    await pumpMe(tester, AppTheme.dark);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 3: Run** — `flutter test test/core test/features/me` → FAIL (files missing).

- [ ] **Step 4: Implement**

`lib/core/theme/theme_mode.dart`:

```dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The student's System / Light / Dark choice. A per-device display
/// preference, so it lives in shared_preferences, not Supabase.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const prefsKey = 'theme_mode';

  /// Set by `main()` from [loadSaved] before `runApp`, so the first frame
  /// already uses the saved theme.
  static ThemeMode initial = ThemeMode.system;

  /// The saved choice, or System if there's none or it can't be read.
  static Future<ThemeMode> loadSaved() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(prefsKey);
      return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    } catch (e) {
      debugPrint('Could not load theme mode: $e');
      return ThemeMode.system;
    }
  }

  @override
  ThemeMode build() => initial;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(prefsKey, mode.name);
    } catch (e) {
      debugPrint('Could not save theme mode: $e');
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
```

`lib/features/me/me_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode.dart';

/// Me tab. Only Appearance for now; profile and streak history come later.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppTheme.space20, AppTheme.space16, AppTheme.space20, AppTheme.space24),
          children: [
            Text('Me', style: textTheme.headlineLarge),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Appearance', style: textTheme.titleMedium),
                  const SizedBox(height: AppTheme.space12),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).setMode(s.first),
                    style: SegmentedButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.inkSoft,
                      selectedBackgroundColor: colors.accent,
                      selectedForegroundColor: colors.accentInk,
                      side: BorderSide(color: colors.border),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Profile and streak history are coming soon.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}
```

`main.dart`:
- in `main()`, before `runApp`: `ThemeModeNotifier.initial = await ThemeModeNotifier.loadSaved();`
- `StudyGymApp` becomes a `ConsumerWidget`; `build(BuildContext context, WidgetRef ref)` uses `themeMode: ref.watch(themeModeProvider),`.
- import `core/theme/theme_mode.dart`.

- [ ] **Step 5: Run** — `flutter analyze && flutter test` → all pass.

- [ ] **Step 6: Commit** — `git add pubspec.yaml pubspec.lock lib/core/theme/theme_mode.dart lib/features/me test/core test/features/me && git commit -am "feat(app): in-app System/Light/Dark switch on the Me tab"`

---

### Task 8: App — Mission rename and the five-tab shell

**Files:**
- Move: `app/lib/features/skill_map/skill_map_screen.dart` → `app/lib/features/mission/mission_list_screen.dart`; `app/test/features/skill_map/skill_map_screen_test.dart` → `app/test/features/mission/mission_list_screen_test.dart`
- Modify: `app/lib/core/router/app_shell.dart`, `app/test/flow_smoke_test.dart`, `app/test/test_content.dart`

**Interfaces:**
- Consumes: `TheoryScreen` (Task 6), `MeScreen` (Task 7).
- Produces: `MissionListScreen()`.

- [ ] **Step 1: Failing tests**

`git mv` both files. In the test: import `package:study_gym/features/mission/mission_list_screen.dart`, use `MissionListScreen`, and add:

```dart
  testWidgets('lists every chapter with no subject switcher', (tester) async {
    // (same Content.load as the test above)
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(theme: AppTheme.light, home: const MissionListScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mission'), findsOneWidget);
    expect(find.text('Mensuration: Surface Area and Volume'), findsOneWidget);
    expect(find.text('Sequences and Progressions'), findsOneWidget);
    expect(find.text('Maths'), findsNothing);
    expect(find.text('Science'), findsNothing);
  });
```

(Pull the shared `Content.load(...)` into a local `loadMissionContent()` helper used by both tests.)

`test_content.dart`: add a lesson so the Theory tab has something to show in the smoke test:

```dart
  const lessons = <Lesson>[
    Lesson(
      id: 't_c9_sav_cuboid_cube',
      conceptId: 'c9.sav.cuboid_cube',
      title: 'Cuboids & Cubes',
      body: 'A cube is a cuboid with all sides equal.',
      hookKind: HookKind.realWorld,
      hook: 'Every cardboard box is a cuboid.',
      sortOrder: 1,
    ),
  ];
  return ContentSnapshot(chapters: chapters, questions: questions, lessons: lessons);
```

`flow_smoke_test.dart`: replace the Skill Map part of the first test with a walk through every tab:

```dart
    // Every tab shows its own screen.
    await tester.tap(find.text('Theory').last);
    await tester.pumpAndSettle();
    expect(find.text('1 lesson'), findsOneWidget);

    await tester.tap(find.text('Mission').last);
    await tester.pumpAndSettle();
    expect(find.text('Sequences and Progressions'), findsOneWidget);
    expect(find.text('Start Mission'), findsNothing);

    await tester.tap(find.text('Tests').last);
    await tester.pumpAndSettle();
    expect(find.text('Create a custom test'), findsOneWidget);

    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Today').last);
    await tester.pumpAndSettle();
    expect(find.text("Today's workout"), findsOneWidget);
```

and add `SharedPreferences.setMockInitialValues({});` to its `setUp` (import `package:shared_preferences/shared_preferences.dart`) plus a test that switching to Dark on Me re-themes the app:

```dart
  testWidgets('choosing Dark on the Me tab switches the whole app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
```

- [ ] **Step 2: Run** — `flutter test` → FAIL (no `MissionListScreen`, no Theory/Mission/Me tabs).

- [ ] **Step 3: Implement**

`mission_list_screen.dart`: rename `SkillMapScreen` → `MissionListScreen`, `_SkillMapScreenState` → `_MissionListScreenState`; header text `'Mission'`; doc comment: `/// Mission tab (was "Skill Map", docs/PLAN.md §3): chapters with a mastery ring, expandable concept list with status chips, "Practice" and "Start Mission" CTAs.`; fix the `mission_screen.dart` import to `'mission_screen.dart'` and `../workout/…` stays. Remove the empty `lib/features/skill_map/` and `test/features/skill_map/` directories.

`app_shell.dart`:

```dart
import '../../features/me/me_screen.dart';
import '../../features/mission/mission_list_screen.dart';
import '../../features/tests/tests_screen.dart';
import '../../features/theory/theory_screen.dart';
import '../../features/today/today_screen.dart';

/// The 5-tab bottom nav shell: Today · Theory · Mission · Tests · Me.
…
  static const _tabs = [
    _TabDef('Today', Icons.wb_sunny_rounded, Icons.wb_sunny_outlined),
    _TabDef('Theory', Icons.menu_book_rounded, Icons.menu_book_outlined),
    _TabDef('Mission', Icons.flag_rounded, Icons.outlined_flag_rounded),
    _TabDef('Tests', Icons.assignment_rounded, Icons.assignment_outlined),
    _TabDef('Me', Icons.person_rounded, Icons.person_outline_rounded),
  ];
…
        children: const [
          TodayScreen(),
          TheoryScreen(),
          MissionListScreen(),
          TestsScreen(),
          MeScreen(),
        ],
```

Delete the now-unused `_ComingSoonTab` class.

- [ ] **Step 4: Run** — `flutter analyze && flutter test` → no issues, all pass; `grep -rn "SkillMap\|skill_map\|Skill Map" lib test` → no hits.

- [ ] **Step 5: Commit** — `git add -A lib test && git commit -m "feat(app): five tabs — Theory and Me added, Skill Map renamed Mission"`

---

### Task 9: Live database rollout — **stop and get the user's confirmation first**

**Files:** none changed (applies `backend/supabase/migrations/20260930000000_theory_lessons.sql`, `backend/supabase/seed/005_surface_area_volume_theory.sql`, `backend/supabase/seed/006_maths_only.sql`).

- [ ] **Step 1: Ask the user to confirm** applying the three files to the live `study-gym` project. Do nothing below until they say yes.
- [ ] **Step 2: Pre-check** (`execute_sql`): `select version from supabase_migrations.schema_migrations order by version;` and `select to_regclass('public.lessons');` — expect the theory migration absent and `lessons` null.
- [ ] **Step 3: Migration** via `apply_migration` with name `theory_lessons` and the migration file's SQL.
- [ ] **Step 4: Seeds** via `execute_sql`: the full text of `005`, then of `006`.
- [ ] **Step 5: Verify** (`execute_sql`):

```sql
select count(*) from lessons;                                   -- 7
select code, status from subjects where class_id = 'cbse_9' order by code;  -- maths live, others hidden
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000000","role":"authenticated"}', true);
select count(*) from lessons;                                   -- 7 (authenticated can read)
select count(*) from subjects where code <> 'maths';            -- 0 (hidden from clients)
rollback;
```

Then `get_advisors` (security) — no new warnings for `lessons` / `theory_progress`.
- [ ] **Step 6: Re-run `005`** once more to prove the upsert is re-runnable (expect success, still 7 rows).

---

### Task 10: Final verification

- [ ] `cd app && flutter analyze && flutter test` — all pass.
- [ ] `.venv/Scripts/python.exe -m pytest content/pipeline/tests -q && .venv/Scripts/python.exe -m content.pipeline.validate` — all pass, 0 errors.
- [ ] Manual check (after Task 9): run the app, open Theory — 7 lessons in Surface Areas & Volumes; open one, Mark as read, tick appears, ring goes 1/7; on Me switch Light ↔ Dark and see the whole app change.
- [ ] Report state: files changed, commits, branch, what's applied live and what isn't.

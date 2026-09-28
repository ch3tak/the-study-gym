# App structure and screens: the redesign

Date: 2026-09-28. Status: draft for review.

This spec records the redesign agreed in the 28 Sep brainstorm: how the app
is organised, which tabs it has, what each screen shows, and how a chapter,
the daily practice, History and Pro fit together. It covers the structure
and screen layouts only. Colours, type and components (the visual system),
interactive lesson building blocks, new question types and History content
each get their own spec later (see "Follow-on specs").

Mockups from the brainstorm (private links, for reference):

| Page | Link |
|---|---|
| App map (all decisions) | https://claude.ai/artifact/Hem81qRZfwhNksiMGLnZKa |
| Home options | https://claude.ai/artifact/1ayDVdRHP576tU8KtUnKgm |
| Learn tab and chapter path | https://claude.ai/artifact/2ZhqpwnUg8EnUum2YE7HMU |
| Topic to trophy (lesson demo, question formats, Trial) | https://claude.ai/artifact/AjtvzNoqhMtfP77XDUdJn9 |
| History | https://claude.ai/artifact/SrZZ72jRahq34EQTA22PXw |

## Goals

- A first-time user of any age knows where to go within seconds.
- A daily student gets from opening the app to practising in one or two taps.
- The app is not "for CBSE only": anyone can use it, even though CBSE
  Class 9 is the only live course.
- Clarity comes first: every topic is taught with something the student
  can see and play with before they are asked questions.

## What exists today, and what changes

| Today | After this redesign |
|---|---|
| Tabs: Today · Theory · Mission · Tests · Me | Tabs: **Home · Learn · History · Me** |
| Theory tab lists lessons per chapter | Lessons live inside each chapter, as the first node of each topic. The Theory tab goes away. |
| Mission tab: chapter list; "Start Mission" opens the 62-level path | Learn tab: chapter list. The 62-level path becomes the **Chapter Trial**, which opens only after every topic in the chapter is done. |
| Tests tab | A **Tests** section at the end of the Learn tab |
| Today tab: 10-question workout | Home: a **5-question, about 5-minute** workout with a "Keep going" button, plus a **Puzzle of the Day** |
| No History | A **History** tab: a night-time world map of where maths happened |

## Decisions

1. **Courses organise the maths.** Each class is a course ("CBSE Class 9
   Maths"). Courses not tied to a class ("Algebra from Zero") sit alongside
   them later. Board and class stay data, as the architecture already
   requires.
2. **Join several courses, one active at a time.** A course chip at the top
   of Home and Learn switches the active course. Mastery of a shared concept
   counts in every course that uses it.
3. **Daily = two cards.** A personal Daily Workout (5 questions, about 5
   minutes, then "Keep going") that keeps the streak, and a Puzzle of the
   Day that is the same for everyone and never affects the streak.
4. **Four tabs:** Home (do), Learn (browse), History (wander), Me (you).
5. **Pro appears only where it is used,** as a small lock and "PRO" label,
   plus one Pro page in Me. No Pro tab, no banners on Home or History.
   **Learning is always free:** chapter lessons, topic nodes, the Trial, the
   daily workout, the puzzle and History are never locked.
6. **Home is "one big next step":** a hero card that changes with the day.
7. **A chapter is built from topics.** Each topic: Do you know? → interactive
   lesson → four question nodes. The Chapter Trial comes last.
8. **Lessons use just enough animation to make the idea clear,** built from
   a small library of reusable interactive building blocks.
9. **Seven question formats** in one player, all auto-graded, plus feedback
   that names the mistake and can replay the lesson's interactive.
10. **The Trial is shown as a gate with one seal per topic.** Gold trophy
    for finishing, Platinum for 90% right first time with no solutions
    viewed.
11. **History is a night-time world map.** Places glow as their stories are
    read. Coastlines only, no country borders. Maps show ancient names only;
    the story text gives the modern name.

## Onboarding

Welcome → Pick a course → Daily reminder (skippable) → Home.

- **Pick a course** lists every course. Only "CBSE Class 9 Maths" is
  selectable today. "CBSE Class 10 Maths" shows "Coming soon".
- **Account creation** is asked after the first workout ("Save your
  progress"), not up front.
- The diagnostic stays dropped, as PLAN.md already decided for the alpha.

## Home

Top bar: course chip ("Class 9 ▾") and streak.

**Hero card, before today's workout is done:** Daily Workout.
- Title "Keep your N-day streak going" (or "Start your streak" at 0).
- One line naming the topics it will train.
- "Start workout". Five questions from the existing selector (warm-up,
  weak spot, fading review), scaled from 10 to 5.
- The done screen offers **Keep going**: five more questions from the
  same selector. Free users get one workout a day; Keep going is Pro.

**Hero card, after the workout:** Continue your chapter.
- The chapter name, "Topic N of M" or "Trial level N of 62", and a
  Continue button that opens the next node directly.
- If no chapter has been started, it suggests the first chapter.

**Below the hero, in this order:**
1. **Week row:** seven day dots; today is dashed until the workout is done.
2. **Puzzle of the Day:** one problem, one attempt, the same for every user.
   Solvable with Class 8–9 maths. Result card with "Share". Never affects
   the streak.
3. **Workout done** row (only after the workout): "✓ Daily workout ·
   4 / 5 · Keep going".
4. **Needs attention** (only if any): "N topics fading · Review".

## Learn

- **Course header:** course chip and switcher sheet (your courses, "Add a
  course"), title "Learn".
- **Course progress:** a bar and one line ("1 of 15 chapters started ·
  13 levels cleared"). Exam courses later add Exam readiness here.
- **The chapter in progress** is pinned at the top.
- **Chapters grouped by the syllabus's units,** with the unit's exam marks
  ("Geometry · 25 marks"), read from `content/syllabus/cbse/9/maths.yaml`.
  Each chapter row has a progress ring and a status. Chapters with no
  content show "Soon", faded, and don't open.
- **Tests,** at the end: chapter tests, mock papers (1 free, the rest Pro),
  custom test (Pro).
- For a course not tied to a class, units become strands and the marks and
  mock papers are not shown.

## The chapter screen

Header: back to Learn, chapter name, "N of M topics done · Trial locked",
progress bar, and two buttons: **Notes** (re-read this chapter's lessons)
and **Practice** (pick a topic, see its mastery % and "why this number",
drill it). Below the buttons, the chapter's 📜 History story link when one
exists.

**Topics**, in syllabus order (a topic is a syllabus concept):
- A finished topic folds into one line: "✓ Cylinders · 4 / 4".
- The current topic is open: its **Do you know?** card, then its nodes on
  a short winding path:
  1. **▶ Learn:** the interactive lesson.
  2. **Guided** (4–5 questions).
  3. **Practice** (4–5 questions).
  4. **Spot the mistake** (4–5 questions).
  5. **Challenge** (4–5 questions).
- Later topics show as single cards ("Pyramids · lesson + 4 nodes").
- The **Do you know?** card uses the lesson's existing `hook` field
  (`real_world` or `historical`), so no new content is needed for it.
- Topics unlock in order. The Learn node opens as soon as the topic
  unlocks. Each question node opens when the one before it is passed.
- **A node is passed** when every question in it has been answered
  correctly. A wrong question comes back at the end of the node.

**The Trial gate** closes the chapter: a trophy, one seal per topic
(a broken seal for each finished topic), and "Finish all N topics to open
the Trial".

**Interim rule until topic questions exist:** a topic with no question
nodes yet counts as finished once its lesson is marked read. Its node slots
show "Questions coming soon". This keeps the Trial reachable for Surface
Area and Volume today (7 lessons exist) and switches off automatically per
topic when its questions are added.

### The Chapter Trial

- Opens when every seal is broken.
- The existing 62 levels in their five stages (Foundation, Guided
  practice, Skill building, Application, Mastery). Finished stages fold
  into one line, the current stage is a winding path, later stages are
  single cards. The last level of each stage is a checkpoint (diamond).
- Tapping a level opens a preview sheet: "Level N of 62 · stage", a short
  name (defaults to the level's topic), type and time, the level's
  `why_after_previous` text, and "Start level".
- **Gold:** all 62 levels finished. **Platinum:** finished with at least
  90% right first time and no solutions viewed.
- Unlocking stays sequential, as `level_progress` works today.

## Lessons

Every lesson has four steps:
1. **Do you know?** One real, surprising, checkable fact.
2. **Play with it.** The interactive, built from a reusable building block
   (for example the solid viewer: rotate, resize with sliders, unfold into
   its net).
3. **Three lines of theory and one worked example.**
4. **Quick check:** one question; answering it correctly completes the
   Learn node.

Until the interactive building blocks exist (see "Follow-on specs"), a
lesson shows steps 1 and 3: the `hook` as Do you know?, and the existing
lesson text (with its `try_it` prompt, if any) as the theory. The existing
"Mark as read" button completes the Learn node until the Quick check
exists.

## The question player

One player for workout, topic node, Trial level, practice, test and
puzzle. It supports seven formats:

| Format | What the student does | Grader |
|---|---|---|
| Classic | Multiple choice, or a number on the maths keypad | Existing |
| Guided steps | Fill in small answer boxes, one step at a time | Existing numeric/MCQ per step |
| Spot the mistake | Tap the wrong line in a worked solution | Existing MCQ (line index) |
| Guess first | Estimate on a slider, then give the exact answer | Existing numeric; the guess is not graded |
| Tap the diagram | Tap a length, angle, region or point | **New** |
| Put in order | Drag solution steps into order | **New** |
| Make it true | Adjust a slider until a condition holds | **New** |

**Feedback on a wrong answer** says "Not yet", names the mistake from the
distractor's misconception, and offers **See it** (replays the topic
lesson's interactive, when there is one) and **Try again**.

Only Classic is required by this spec's build. The other formats come with
their follow-on spec.

## History

History always uses its own night look, in both app themes.

- **Timeline screen:** a world map at the top (places glow when you've read
  a story there, dim otherwise), a time slider under it, topic filter chips
  (All, Geometry, Numbers, Algebra, Measurement), then eras down a line,
  each with its stories.
- **Era screen:** a close-up map of the era's region, a short intro and the
  era's stories.
- **Story reader:** a small locator map, place and date, 3–5 minutes of
  short paragraphs with one explanatory diagram, a "historians debate" note
  wherever facts are uncertain, "You'll meet this in" linking to the exact
  chapter, and a source line.
- **Map rules:** coastlines only, drawn in the app from Natural Earth
  (public domain), no country borders.
- **Place names:** maps, the timeline and era lists show only the ancient
  name ("Kusumapura"). The story text gives the modern name the first time
  the place comes up, in the form "Kusumapura (modern-day Patna)".
- **Worldwide from the start:** the first stories include China and the
  Maya, not only the Mediterranean and India.
- **Accuracy:** every story cites its source and gets checked before it
  ships. India's contributions get their full weight without exaggeration.
- **Later:** Journeys (only well-documented routes, such as India →
  Baghdad → Pisa), and a special card on Home on 22 December (National
  Mathematics Day).

## Me

- Profile and stats: topics mastered, lessons read, stories read.
- **Trophy shelf:** one Gold or Platinum trophy per chapter.
- **My mistakes:** grouped by misconception, with retry (same question for
  now).
- **Study Gym Pro:** full comparison and subscription.
- Settings: reminder, appearance (the existing System/Light/Dark switch),
  account, privacy, report a problem. Parent report later.

## Free and Pro

| Feature | Free | Pro |
|---|---|---|
| Chapter lessons, topic nodes, Trial | All | All |
| Daily Workout | 1 a day | Keep going, unlimited |
| Puzzle of the Day, History | All | All |
| Hints and solutions | Hint 1 | Full hints and step-by-step solutions |
| Topic practice (Practice button) | Daily limit | Unlimited |
| Mock papers | 1 | All, with analysis |
| Custom tests | None | Unlimited |
| Timed challenge game (later) | Maybe a taste | Likely Pro |

A lock opens a Pro sheet that explains that one feature. Payments stay out
of scope, as today's "Upgrade to Pro (demo)" is.

## Build order

This spec is too large for one implementation plan. Proposed slices, each
with its own plan:

1. **Shell, Home and Learn.** Four tabs; Home layout with the 5-question
   workout, Keep going, Continue card, week row and Needs attention; Learn
   with the course chip (one course, Class 10 "coming soon"), units, and
   the Tests section moved in from the Tests tab; the topic-based chapter
   screen with the interim rule; the Trial gate and the Trial (today's
   Mission screen, restyled into folding stages); the level preview sheet.
2. **Puzzle of the Day.** A puzzle content file (one hand-written puzzle
   per date), the Home card, one attempt per day, the share card.
3. **History screens,** together with the History content model spec (map
   renderer, timeline, era, story reader, first stories).
4. **Me:** profile stats, trophy shelf, My mistakes, Pro page.
5. **Onboarding:** course picker and the "Save your progress" prompt.

Slice 1 uses the current theme tokens (`context.colors`). The visual
system spec can then restyle everything by changing tokens.

## Follow-on specs

- **Visual system:** colour roles, type and components for the whole app,
  and History's own look; built in Figma once the Figma connection is
  authorised.
- **Interactive lessons:** the library of about ten reusable building
  blocks and the lesson format that uses them.
- **Topic questions and new formats:** the three new question types in the
  app and the content pipeline, and about 120 topic questions per chapter.
- **History content model:** what a story is, how it links to chapters, and
  how stories are written and checked.
- **Question templates** (from the earlier review): numbers that change on
  each retry.

## Changes to PLAN.md

PLAN.md still describes the old navigation (Today · Skill Map ·
Tests/Practice · Me), a 10-question workout, and no History. Once this spec
is approved, PLAN.md §3 (navigation and screens) and §5.3 (workout size)
need updating to match. That edit is not part of this spec.

## Testing

Each slice's plan defines its tests. For slice 1 at least:
- Widget test: the four tabs each show their screen.
- Home: the hero shows the workout before it's done and Continue after.
- The workout builds 5 questions; Keep going adds 5 more.
- Learn groups chapters by unit in syllabus order and pins the chapter in
  progress.
- Chapter screen: topics unlock in order; the interim rule breaks a seal
  when the lesson is read and the topic has no questions; the Trial opens
  only when every seal is broken.
- Trial: stages fold; the preview sheet shows `why_after_previous`.
- Everything renders in both light and dark themes.

## Out of scope

- Payments (Pro stays a demo flag).
- Class 10 and courses not tied to a class (designed for, not built).
- Weekly leagues, parent report, the timed challenge game.
- Anything in the follow-on specs.
- Figma files (need the Figma connection first).

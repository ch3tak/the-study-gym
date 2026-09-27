
# "Study Gym": detailed build and business plan
*Working name — no longer constrained to be subject-neutral (math is now permanent, not a wedge into other subjects); worth revisiting whether a math-forward name works better. Options to test: StudyGym, Rep, Topper Gym, Padhai Gym, MathGym. Last updated 27 Sep 2026.*

---

## 0. Context and decisions

**The idea.** Someone close to the founder is weak at maths, which sparked this. The product is **a mastery system for math, for anyone, at any age** — a student cramming for a board exam and an adult who just wants to get good at math for its own sake are both first-class users. Existing apps either lecture (video courses) or answer homework (chatbots). Neither tells a learner *exactly what they don't know*, nor trains it daily, and nothing does it for math the way Duolingo does it for language. We build a **mastery system shaped like a gym app**:

> **Diagnose → find weak concepts → daily workout → evaluate → adapt → track progress/streak → repeat**

**Mission (revised 27 Sep 2026).** Teach math to everyone, through short, playful, daily workouts — a Duolingo for math, not a curriculum-neutral "gym for every school subject." A previous version of this plan treated math as the easiest subject to launch first, with Science/Social Science/English/Hindi following on the same architecture. That framing undersold the actual ambition and tied the product's identity to the Indian board-exam system. **Math is now the permanent scope, not a beachhead.** Reasoning a high-school maths teacher would give for this: math is the one school subject that compresses into bite-sized, objectively-gradable, prerequisite-chained reps — exactly what makes Duolingo-style loops (streaks, XP, mastery bars) work. Subjective subjects (essays, literature, long-answer history) don't fit the same metaphor without a rubric-grading escape hatch, which was itself a sign those subjects didn't belong in v1's ambition.

**Two tracks, one engine.** The same mastery engine, content pipeline, question types, and workout loop serve two onboarding paths:
| | Exam track | General track |
|---|---|---|
| Who | A student preparing for a specific school board exam | Anyone learning math for its own sake — any age, no exam |
| Entry | Picks board + class (e.g. CBSE Class 10) | Picks a starting point in a global skill tree (a short placement quiz) |
| Content spine | `content/syllabus/{board}/{class}/math.yaml` | `content/syllabus/general/math_core.yaml` (strand-organized, no board/class) |
| Extra features | Board Readiness, exam-pattern mock papers, parent weekly report | None of the above — just skill tree, streaks, mastery |
| Legal/business | DPDP minor consent, India pricing/UPI, parental WhatsApp report — **only when board is India-based AND the user is a detected/declared minor** | Standard adult flow, store pricing in local/USD terms, no parent-consent flow |

Both tracks are read by the same mastery model, workout selector, and trust rules (§1, §5). "Board" and "class" are simply absent for a general-track learner — the architecture already treats them as data, not code, so this isn't a rewrite.

**Decisions made**
| Question | Decision |
|---|---|
| Subject scope | **Math only. Permanently.** Not "math first, other subjects later." The multi-subject roadmap (Science, Social Science, English, Hindi) that used to live in this plan is scrapped, not deferred — revisit only if a future, deliberate decision reopens it. |
| Audience scope | **Everyone, any age, curriculum optional** — not India-only, not students-only. Two tracks (above): exam track (board/class-based) and general track (curriculum-free skill tree). |
| Alpha scope | **CBSE Class 9 Mathematics** (2026-27 NCF syllabus; decided 26 Sep 2026, replacing "Class 10 Maths only"). The Class 10 Maths syllabus stays in the repo as a sample. Built on a subject-agnostic-in-name-only architecture: the code is generic, but math is the only subject that will ever be plugged in. Sections below that assume a Class 10 board-exam launch need revisiting. |
| Next release after alpha | **The general/curriculum-free skill tree** (v1.1, right after the CBSE alpha) — not a second school subject. See §2A and §10. |
| Board/curriculum expansion order | CBSE (alpha) → general skill tree (v1.1) → additional boards/curricula chosen by waitlist and install-geography demand data (v2+), e.g. ICSE, a state board, or a generic international "school math" pack. No second board ships until the general track has proven out. |
| Builder | Founder solo with Claude as pair-programmer, using **Flutter** |
| Budget before revenue | Bootstrapped, **under ₹50,000** |
| Priorities | 1) Great UX. 2) The app delivers what it promises: correct questions, honest mastery numbers. |
| Platform | Android first (about 95% of Indian students, and Android is also the global majority OS), iOS later from the same Flutter code |
| Alpha onboarding | **No diagnostic (S2–S4 dropped for now).** "Get started" goes straight from Welcome to the main dashboard; mastery starts at its seeded baseline and fills in from real workouts instead of a separate up-front quiz. Reasoning: it added a whole extra flow just to ask questions normal practice already answers. The screens below that describe Quick Setup and the diagnostic (S2–S4) are the target design, not what's built now — revisit only with an explicit decision to add it back, not as a side effect of some other task. |

**Why math, and only math.**
- It is the one school subject that compresses cleanly into short, gradable, gamifiable reps — the actual mechanism that makes a Duolingo-style loop work. Subjective subjects need rubric grading and confidence levels to even approximate trust; math doesn't.
- Board exams create urgency in the exam track, and parents already pay for maths tuition — a real monetization wedge that doesn't require the general track to also have one on day one.
- Answers can be graded **automatically and objectively** (SymPy), so trust is easiest to prove here, and stays true whether the learner is a CBSE student or a curious adult.
- It lets us validate the loop (diagnose → workout → mastery) once, and reuse it across every future curriculum pack or the general track, without ever needing a second grading paradigm.

**Architecture rule from day one.** No code, table, screen, or content format may assume "CBSE" or "board exam."
- Board, class, and curriculum are data, not code — but they are now **optional** data. A learner may have none of them (general track).
- Question types and graders are pluggable, but the type roster itself stays math-only (§2A) — this is a scope decision, not a technical limitation.
- Adding a new board or curriculum pack should mean **new content**, not a rewrite. Adding the general track means **new content organized by strand instead of by class**, reusing the same engine.

**The calendar drives the exam track**
- Class 10 board exam: **Feb–Mar 2027**. From 2026, CBSE also runs an optional second Class 10 exam around May, which is a second selling window. *(Verify the exact 2027 dates.)*
- Peak willingness to pay in the exam track: **Dec → Feb** (pre-boards and final revision). The general track has no equivalent seasonal spike — see §7 and §13.
- Plan: closed beta by **mid-Nov 2026**, Play Store launch plus paywall by **early Dec 2026**, for the CBSE exam track. General track follows as v1.1 (see §10).

---

## 1. Positioning and promise

**One-liner (mission-level):** *"Your daily math workout — for school, or just for the joy of it. We find exactly what you're weak at, train it playfully, and show your progress, one concept at a time."*

**Alpha one-liner (exam track, CBSE):** *"Your 15-minute daily maths workout for Class 10 boards."* The store listing is honest about what's built today.

**We are NOT:**
- a video course
- a doubt-solving chatbot
- a PDF sample-paper dump
- a school-subjects app that happens to start with math

**We ARE:** a personal trainer for math that knows your weak muscles — whether your goal is a board exam or just getting good at math.

| Gym | Maths Gym |
|---|---|
| Fitness assessment | Diagnostic / placement quiz |
| Muscle | Concept |
| Workout | Daily 10-question set |
| Reps / weight | Questions / difficulty |
| Trainer | Coach (rules + AI) |
| Body stats | Skill map + Board Readiness (exam track only) |
| Streak | Study consistency |

**North-star metric:** *weekly concepts newly mastered per active learner.* We do not optimise for minutes spent or questions answered. This applies identically to both tracks.

### Trust rules (how we "deliver what we promise")
1. **No live-generated questions.** Every question is pre-generated, machine-verified (SymPy), and sampled by a human before it reaches learners.
2. **Target ≥ 99.5% answer-key accuracy.** "Report a problem" sits on every question. Any question with 2 or more reports is auto-hidden until reviewed.
3. **Every % is explainable.** Tap it to see what it's based on, e.g. "14 questions, 11 correct, last practiced 2 days ago".
4. **"Mastered" is hard to earn.** It requires ≥ 80% predicted accuracy on 2 separate days at least 3 days apart. There is no fake progress.
5. **Board Readiness is conservative** (exam track only). It shows a range ("58–64 / 80"), never an inflated single number, and it states the coverage ("based on 9 of 14 chapters").
6. **No dark patterns.** Cancellation is clear, the trial reminder goes out 2 days before billing, there is no guilt-trip copy, and streak rest days are built in.

---

## 2A. Scope: one subject, two tracks

### Why math only, permanently
A previous version of this plan treated math as merely the first of five CBSE subjects (Maths → Science → Social Science → English → Hindi), justified by "it's the most objective, so it proves the loop first." That reasoning is actually an argument for staying math-only forever, not for expanding once trust is proven:
- Math's atomic, prerequisite-chained concepts are what make the mastery engine, the Elo-style rating, and the gym metaphor (reps, weight, muscles) work naturally. Subjects like English literature or SST long-answers don't decompose the same way — they needed a whole separate rubric-grading subsystem with confidence levels and a "self-check" fallback (removed below) just to approximate the trust bar math clears for free.
- Staying focused on one subject, but reaching every learner of that subject globally (not just one country's board exam), is a bigger and cleaner opportunity than spreading thin across five subjects in one curriculum.

**Everything below in the old §2A about Science/Social Science/English/Hindi — the subject table, the expansion order, the per-subject question types (chem_equation, diagram_label, map_point, short_answer, long_answer, photo_answer), the subject rollout calendar, and the 55k-question multi-subject content volume plan — is removed, not deferred.** If multi-subject is ever reconsidered, it needs its own fresh decision, not a resumption of this old plan.

### The general (curriculum-free) track
- **Content spine:** `content/syllabus/general/math_core.yaml`, organized by strand, not by board/class: Numbers & Arithmetic → Algebra → Geometry → Trigonometry → Statistics & Probability → (later) Calculus, Discrete Math, Recreational/Puzzle Math.
- **Onboarding fork:** "Are you studying for a school exam?" — Yes routes into the existing board/class picker (exam track). No routes into a short placement quiz (not a full 20-question diagnostic) that seeds the learner somewhere sensible in the strand tree.
- **No Board Readiness, no parent report, no exam-pattern mocks** in this track — there's no exam to be "ready" for. Its own progress framing (mastery %, streaks, skill map) carries the motivation instead.
- **Reuses, unchanged:** mastery engine, retention decay, workout selector, question types (mcq, numeric, expression, assertion_reason, case_based), content pipeline (generate → validate → critique → review → import), trust rules.
- Prerequisites can cross between the general tree and a board's syllabus where concepts genuinely overlap (e.g. CBSE quadratic equations and the general track's "Algebra: quadratics" node can share a concept id), so a learner's mastery isn't siloed if they ever switch tracks.

### Question-type registry (math-only)
Each type implements three things in the app: `render()`, `inputWidget()`, `grade()`. In the pipeline it implements `validate()`.

| Type | Grader |
|---|---|
| `mcq` / `multi_select` | Deterministic; distractor → misconception |
| `numeric` (with optional tolerance) | Deterministic |
| `expression` | Equivalence check |
| `assertion_reason` | Deterministic |
| `case_based` (container of sub-questions) | Delegates to children |

No subjective/rubric-graded types (short_answer, long_answer, photo_answer) are in scope. If handwritten photo-answer grading is ever wanted for math itself (v2+ idea), it stays deterministic-equivalence-checked against a parsed final answer, not rubric/value-point grading — that machinery was only needed for subjective subjects and is removed.

### Subject-neutral-in-name, math-only-in-practice core
| Shared across both tracks (build once) | Per curriculum pack (plug-in) |
|---|---|
| Board/class *(optional)* → syllabus/strand → concept data model | Syllabus YAML (board-based or strand-based) + misconception lists |
| Mastery engine, retention decay, workout selector | Exam blueprint (exam track only: sections, marks, weightage) |
| Skill map, Today, streaks, mock-test player (exam track) | — |
| Content pipeline stages (generate → validate → critique → review → import) | SymPy validator (shared; no per-subject validators needed) |
| Paywall, analytics | Domain-expert reviewer (a maths teacher — one role, not one per subject) |

### Curriculum/board rollout calendar
| Release | Timing | Scope |
|---|---|---|
| Alpha / launch | Nov–Dec 2026 | CBSE Class 10 Maths (exam track) |
| v1.1 | Jan 2027 | **General skill-tree track** (curriculum-free), reusing the alpha's engine and content pipeline |
| v1.2 | Feb 2027 | CBSE Class 9 Maths (for the new academic session), deepen general-track strands |
| v1.5+ | 2027, by demand | A second board/curriculum, chosen from waitlist + install-geography data (e.g. ICSE, a state board, or a generic international "school math" pack) — not pre-committed |
| v2 | 2027–28 | iOS, more general-track strands (calculus, discrete/recreational math), additional boards as demand justifies |

- The Dec 2026 launch stays CBSE-only, because the general track and any second board are each their own content-authoring effort and shouldn't be rushed alongside launch.
- The **general track is the very next release after alpha**, not a 2027 slot as the old plan had it — it was previously scheduled behind four other subjects; now it's second only to the CBSE alpha itself.

### Content volume
| Track | Chapters/strands (approx.) | Concepts | Questions target |
|---|---|---|---|
| CBSE Maths (per class) | 14 | ~150 | ~6,000 |
| General skill tree (v1) | ~8–10 strands | ~120 (overlaps with CBSE concepts where applicable) | ~4,000–5,000 |

Total content volume across both tracks for v1.1 is comparable to *one* subject's worth in the old multi-subject plan (~10-11k questions), not the ~55k the five-subject plan required — a direct benefit of staying single-subject.

---

## 2. Feature scope

### v1 (MVP, the paid launch in Dec — CBSE exam track only)
1. Onboarding with a diagnostic test
2. Skill map (chapters → concepts, colour-coded)
3. Daily workout (warm-up / strength / challenge)
4. Hint ladder and step-by-step solutions
5. Chapter and concept practice
6. Progress: mastery, streak, retention review, Board Readiness
7. Mock board papers: a full 80-mark CBSE pattern, timed, with analysis
8. Coach message after each workout (template plus light AI)
9. Parent weekly report, shareable on WhatsApp (India exam-track minors only — see §9)
10. Paywall, trial, and subscription (Play Billing)
11. Push reminders (user-chosen time)
12. Offline workouts

### v1.1 (Jan 2027): the general track
1. Onboarding fork: "studying for a school exam?" Yes/No.
2. `general/math_core.yaml` content spine and a short placement quiz (not the full 20-item diagnostic).
3. Skill map re-themed by strand instead of by board chapter, for general-track learners.
4. Same workout player, hint ladder, mastery engine, streaks — reused as-is.
5. No Board Readiness, no parent report, no exam-pattern mocks in this track.
6. Its own paywall copy and pricing shape (§7) — no exam urgency to anchor on, so this needs its own testing.

### v1.2 → v2 (2027)
- CBSE Class 9 Maths live (new academic session).
- General track grows more strands (calculus, discrete/recreational math).
- A second board/curriculum, chosen from real demand data, not pre-committed.
- "Explain differently" AI follow-up chat, scoped to one question (both tracks).
- Weekly friend leagues (opt-in, both tracks).
- iOS.

### v3+
- Further boards/curricula and countries, by demand.
- Any additional general-track content (e.g. recreational math, puzzle modules) that keeps engagement high without needing exam urgency.

---

## 3. UX specification (screen by screen)

**Design system**
- Colours:
  - One bold brand colour (e.g. energetic orange or indigo)
  - Green = mastered, amber = learning, red = weak, grey = not started
  - Light and dark themes
- Typography: Inter or Plus Jakarta Sans for UI; KaTeX fonts for maths.
- Minimum tap target 48dp, one-thumb reachable primary actions, bottom navigation.
- Motion: short (200–300ms) feedback animations, a Lottie/Rive celebration on workout completion, haptic tick on answer.
- Accessibility: font scaling respected, colour never the only signal (icons plus labels), screen-reader labels on maths (spoken LaTeX).
- Performance budget: cold start under 2.5 s on a ₹8k phone, 60fps on a 3 GB RAM device, APK under 30 MB.

### Navigation (4 tabs, no subject switcher)
- **Today**
- **Skill Map**
- **Tests** *(exam track)* / **Practice** *(general track — same tab, relabeled per track)*
- **Me**

Practice is launched from the Skill Map. There is no subject switcher — math is the only subject, so that UI element from the old plan is removed entirely. The only fork is track-level (exam vs. general), decided once at onboarding and changeable later from **Me**.

**Track-specific input widgets** all share one card layout and one submit/feedback pattern:
- Maths keypad (both tracks)
- Text answer box only where genuinely needed (none currently — kept out of scope per §2A's math-only, deterministic-grading rule)

### Screens

**S1. Welcome** (1 screen)
- Hook line, "Start free diagnostic" button, "I already have an account" link.
- **New:** a lightweight fork question — "Studying for a school exam?" Yes leads to the existing board/class Quick Setup; No leads to the general track's placement quiz.

> **S2–S4 are not built in the current alpha** (see "Alpha onboarding" in §0's decisions table). "Get started" currently skips straight to the dashboard for the CBSE exam track. Keep this spec as the target design, but don't wire it back in without an explicit decision to do so. The general-track placement flow (v1.1) is new and not yet built either.

**S2. Quick setup** (exam track, about 4 taps)
- Board (CBSE; others greyed "coming soon")
- Class (10; 9 greyed until content exists)
- Class 10 Maths asks **Standard or Basic**.
- Target (Just pass / 60+ / 75+ / 90+)
- Board exam month (auto-filled)
- Optional daily reminder time

**S2-gen. Quick setup (general track, v1.1, about 2 taps)**
- "What brings you here?" (light framing, not required): revision, curiosity, helping my kid, just for fun.
- Optional daily reminder time.
- No board, no class, no target band — none of that applies.

**S3. Diagnostic** (exam track, about 20 questions, about 12 min, skippable per question with "I don't know this yet")
- Adaptive: it starts mid-difficulty per chapter and moves up or down.
- A progress bar shows "Question 7 of ~20".
- No right/wrong feedback during the diagnostic (it reduces anxiety). Everything is revealed at the end.

**S3-gen. Placement quiz (general track, v1.1, about 10 questions, about 5 min)**
- Adaptive across strands rather than chapters; coarser-grained than the exam-track diagnostic since there's no board weighting to calibrate against.
- Seeds the learner's starting point in the strand tree; the rest fills in from real workouts, same as the exam track's alpha behavior.

**S4. Diagnostic result** (the "aha" moment, and the most important screen — exam track)
- Board Readiness range, e.g. "~41–48 / 80 today".
- Top 3 weak concepts with the likely misconception, e.g. *"Quadratics: you mix up the sign in −b/2a"*.
- Top 3 strong areas (positive framing).
- CTA: "Start my first workout".
- *Account creation is prompted here* ("Save your skill map"), using Google Sign-In in one tap or email OTP.

**S4-gen. Placement result (general track)**
- No Board Readiness — instead, a skill-tree snapshot: "Here's where you're starting" with 2–3 strands marked as a good starting point and 1–2 marked already-strong.
- Same account-creation prompt ("Save your skill map").

**S5. Today tab**
- Hero card: "Today's workout · 15 min · 10 reps" with the concept chips it will train.
- Streak flame with a week dots row (rest day shown as a moon).
- Review due: "3 concepts are fading. Quick refresh?"
- Board Readiness mini-gauge with its trend — **exam track only**; general track shows an overall skill-tree completion % instead.

**S6. Workout player** (the core UX; must feel great — identical in both tracks)
- Section header: Warm-up 🔥 / Strength 💪 / Challenge 🧠.
- Question card: LaTeX stem, optional figure (SVG), answer area.
- Answer input by type:
  - MCQ: 4 large option cards
  - Numeric/expression: the **custom maths keypad** (see below)
  - Assertion–Reason: the standard 4 CBSE options *(exam track only, since this format is CBSE-specific; general track uses MCQ/numeric/expression only)*
  - Case-based: a scrollable case plus sub-questions
- On submit:
  - **Correct:** green pulse and haptic, "+XP", a 1-line "why" (optional expand).
  - **Wrong:** a gentle shake, then options for "See hint", "Try again" (1 retry), or "Show solution".
  - The misconception message comes from the chosen distractor or a parsed numeric answer.
- Hint ladder: Hint 1 → Hint 2 → full solution (step by step, each step revealable).
- Using hints lowers the mastery gain (shown transparently).
- Timer is hidden by default (anxiety); an optional "exam mode" timer is available (exam track).

**S7. Workout complete**
- Score (8/10), XP, streak update, and per-concept mastery bars animating from old to new.
- The coach message (2–3 sentences, personalised).
- Buttons: "Share with parent" *(exam track, minor only — see §9)* and "Done". An upsell appears only if the free limit is reached.

**S8. Skill Map tab**
- List of chapters (exam track) or strands (general track), each with a ring (% concepts mastered).
- Expanding shows concepts with status chips and the last practiced date.
- Tapping a concept opens the concept detail: mastery %, "why this number", common mistakes, and "Practice 5" / "Practice 10".
- Locked-prerequisite hint: "Master *Discriminant* first to unlock *Nature of Roots* challenge questions" (soft lock, never hard).

**S9. Tests tab (exam track) / Practice tab (general track)**
- Exam track: mock board papers (Paper 1 free, the rest Pro), chapter tests, "Previous attempts".
  - **Mock test player:** full-paper navigator with sections A–E, mark-for-review, a timer (3 h or 90 min for a half paper), autosave, works offline.
  - Long answers in v1 are split into auto-gradable sub-steps (the final answer plus key intermediate values).
  - **Mock result:** marks by section and by chapter, time per section, mistakes grouped by misconception, "Your 5 fastest mark gains", "Add these to my workouts".
- General track: strand-level practice sets and cumulative "challenge rounds" instead of exam-pattern mocks — no marks/sections framing, since there's no exam.

**S10. Me tab**
- Profile, subscription status, reminder settings.
- Track switcher: "Switch to exam prep" / "Switch to general practice" (re-runs the relevant onboarding fork without losing saved mastery on shared concepts).
- Parent report settings *(shown only for exam-track minors — see §9)*.
- Data and privacy: download or delete data. Help / report a problem.

**S11. Paywall** (full screen, dismissible)
- Exam track headline tied to their data: *"You're ~18 marks away from your 75+ target. Pro gets you there."*
- General track headline: *(needs its own testing — no natural "marks away" anchor; candidates: streak-based, "X concepts from mastering Algebra," or a simple feature-comparison framing)*.
- 3 plans, with the relevant seasonal pass highlighted for the exam track. Benefits list, a 7-day trial, "Ask a parent" share link (exam track minors), restore purchase.

**S12. Parent report** (exam track, minors only — shareable image plus a web link)
- Mastery trend, sessions this week, strong and weak areas, and one actionable suggestion.
- No minute-by-minute surveillance.

### Custom maths keypad (critical, both tracks)
- **Layout:**
  - Digits, `.`, `−`
  - Fraction (a/b template), √, x², power, π
  - Variables `x y`, parentheses, `±`, `=`, backspace, and cursor ← →
- A live LaTeX preview of what they typed sits above the keypad.
- **Answer checking is equivalence-based, not string-based:**
  - Answers are parsed into a canonical form, so `1/2`, `0.5`, and `2/4` all count as correct when appropriate.
  - Numeric tolerance is set per question.
  - Implementation: parse on-device with `math_expressions` for simple forms; complex forms are precomputed as accepted-answer sets in the question data.

### Onboarding copy and tone
- Friendly older-sibling voice. Short sentences. Occasional light humour. Never shame ("Not yet" instead of "Wrong"). Tone stays consistent across both tracks; only the framing (exam urgency vs. personal curiosity) differs.

---

## 4. Content system

### 4.0 Layout for two tracks
- **Syllabus files (exam track):** `content/syllabus/{board}/{class}/math.yaml`, e.g. `cbse/10/math_standard.yaml`, `cbse/9/math.yaml`.
- **Syllabus file (general track):** `content/syllabus/general/math_core.yaml`, organized by strand instead of board/class.
- **Exam blueprints (exam track only):** `content/blueprints/{board}/{class}/math.yaml` holds sections, question types per section, marks, internal choice rules, and chapter weightage.
- **Pipeline config:** `content/pipeline/math.py` holds the allowed types, validators, generation prompt examples, and the reviewer queue — one config, since there's only one subject.
- **Shared types and validators** live under `content/pipeline/types/`, one module per question type: its schema, validator, and generation hints.

The general track follows the same content-model spine as the exam track (chapter/strand → concept → question), just without a board/class/blueprint layer above it.

### 4.1 Curriculum spine: `content/syllabus/cbse/10/math_standard.yaml`
- Source: the CBSE 2026–27 curriculum document plus the NCERT Class 10 chapter list (14 chapters): Real Numbers, Polynomials, Pair of Linear Equations, Quadratic Equations, Arithmetic Progressions, Triangles, Coordinate Geometry, Intro to Trigonometry, Applications of Trigonometry, Circles, Areas Related to Circles, Surface Areas & Volumes, Statistics, Probability.
- Each chapter holds: `id`, `name`, `board_weight_marks` (from the CBSE unit weightage), and `concepts[]`.
- Each concept holds: `id`, `name`, `description`, `prerequisites[]` (concept ids, including Class 9 ones, and general-track strand ids where they overlap), `common_misconceptions[]` (id, description, detection rule), and `question_types_allowed[]`.
- Target size: about 150 concepts. The misconception list per concept is written by hand, with Claude's help, and reviewed by the teacher.
- **Skill/concept ID convention: `{CLASS}-{CHAPTER-CODE}-{NNN}`** (e.g. `M9-COORD-003`, `M10-QUAD-012`) — a short subject+class prefix, a chapter mnemonic, a zero-padded sequence number. Decided 26 Sep 2026 while building the Class 9 Maths curriculum blueprint (see `docs/curriculum/class9_maths.md`, which is the actual curriculum content, kept as a live doc rather than duplicated here). The general track's strand-based ids follow the same shape with a `G-` prefix (e.g. `G-ALG-004`), and concepts that mirror a board concept share the underlying mastery record via an explicit alias, so a learner's progress isn't siloed by track.

### 4.2 Question model
```yaml
id: q_m9_coord_006_0142
concepts: [M9-COORD-006]
difficulty: 2          # 1 easy · 2 board-standard · 3 challenge
type: mcq | numeric | expression | assertion_reason | case_based
cbse_section: A|B|C|D|E   # exam-track questions only; omitted for general-track questions
marks: 1                  # exam-track only
stem: "What is the distance between the points (2, 3) and (5, 7)?"
figure: null | svg path
options: ["5", "7", "$\\sqrt{58}$", "9"]
answer: 0                        # or accepted_answers: ["5"] for numeric
distractors:                     # misconception mapping
  1: M9-COORD-006.added_instead_of_distance_formula
  2: M9-COORD-006.forgot_to_square_root
  3: M9-COORD-006.used_manhattan_distance
hint1: "Use the distance formula: $\\sqrt{(x_2-x_1)^2 + (y_2-y_1)^2}$."
hint2: "$x_2-x_1 = 3$, $y_2-y_1 = 4$. What is $\\sqrt{3^2+4^2}$?"
solution_steps: ["$\\sqrt{(5-2)^2+(7-3)^2}$", "$\\sqrt{9+16}$", "$\\sqrt{25} = 5$"]
verification: {sympy: "sqrt((5-2)**2+(7-3)**2)", status: pass}
review: {human: true, reviewer: T1, date: ...}
quality: {reports: 0, p_correct_observed: null, discrimination: null}
```

### 4.3 Generation pipeline (`content/pipeline/`, Python)
1. **`generate.py`**
   - For each (concept, difficulty, type), call Claude (Sonnet 5 for generation, Batch API for 50% off) with:
     - the concept, its misconceptions, board-style or general-track examples written by us, and a JSON schema
   - Each question comes back with a **SymPy verification expression**.
2. **`validate.py`** (automatic gate). It runs these checks:
   - The LaTeX parses.
   - Options are unique, and exactly 1 is correct.
   - SymPy recomputes the answer and it must match.
   - Distractors must NOT equal the answer.
   - Each distractor maps to a known misconception id.
   - Length and readability limits hold.
   - A near-duplicate check (embedding or normalised-text similarity) passes.
3. **`critique.py`.** A second-model review scores ambiguity, syllabus fit, and difficulty label. Anything below threshold goes to the human queue.
4. **Human review** (`content/review-app/`, a tiny Flutter web or Streamlit page)
   - The reviewer sees the question, approves / edits / rejects, and tags the reason.
   - Review 100% of flagged items plus a 10% random sample. If the sample error rate exceeds 1%, review the whole batch.
5. **`import.py`**: upsert approved questions to Supabase and bump the content version.
6. **Post-launch calibration.** A nightly job computes observed p-correct and discrimination per question, auto-adjusts the difficulty label, and flags questions that high-mastery students get wrong (a likely broken key).

**Volume targets**
- Beta: 1,500 questions covering all 14 CBSE Class 10 chapters.
- Launch: about 6,000 (150 concepts × about 40).
- 6 mock papers hand-assembled from the bank according to the CBSE blueprint.
- General track (v1.1): about 4,000–5,000 questions across ~120 strand concepts.

**Copyright:** original questions only. NCERT and past board papers are style references and are never copied verbatim.

**Cost:** about $30–60 in API spend per curriculum pack. Teacher reviewer is about ₹8–12k (a part-time maths teacher paid per 500 reviews).

---

## 5. Learning engine

### 5.1 Mastery model (per learner × concept), running on-device in Dart and synced
- **Elo-style ability rating:** θ (learner ability for the concept) vs β (question difficulty).
  - `p = 1 / (1 + e^{-(θ-β)})`
  - After an answer: `θ += K · w · (outcome − p)`
  - K is higher for the first ~10 attempts (fast learning), lower afterwards.
  - w discounts hinted attempts: no hint = 1.0, hint1 = 0.6, hint2 = 0.35, solution viewed = 0 gain but full penalty if wrong.
- **Displayed mastery %** = p against a reference standard question (β = difficulty 2).
- **Retention decay:** each concept has half-life h (starts at 2 days).
  - Effective mastery = `mastery × 2^(−days_since/h)` (floored).
  - Each successful spaced review doubles h (capped at 60 days); a failure halves it.
- **States:** Not started → Learning (under 50%) → Practising (50–79%) → **Mastered** (≥ 80% on 2 days at least 3 days apart) → Fading (a mastered concept whose effective mastery drops below 70%, which triggers review).
- **Prerequisite propagation:** a weak prerequisite caps how high a dependent concept's challenge difficulty goes, and it is suggested first. This works the same whether the prerequisite lives in a board syllabus or the general strand tree.
- **Explainability payload:** attempts, correct, hints used, last practiced, and the half-life, all shown in the "why this number" sheet.
- **Track-agnostic by design.** The engine only sees concepts, questions (with difficulty), and outcomes (0–1) — it has no notion of "board" or "exam," which is exactly what makes the general track a content addition rather than an engine change.

### 5.2 Diagnostic / placement algorithm
- **Exam track budget:** 20 items. Sample 1–2 concepts per chapter, weighted by board marks. Start at difficulty 2, adapt per chapter (correct → harder, wrong → easier). Rough-estimate θ for untested concepts from their chapter siblings, shown as "estimated" (a dotted ring) until practised.
- **General track budget:** about 10 items (v1.1). Sample across strands rather than board-weighted chapters, since there's no board weighting to calibrate against. Coarser than the exam-track diagnostic by design — precision fills in from real workouts, same as the exam-track alpha's approach.

### 5.3 Workout selector (10 questions, both tracks)
- **Warm-up (3):** concepts at 60–85% mastery, difficulty 1–2. Confidence first.
- **Strength (5):** score candidates by `(1 − mastery) × weight × prereqs_met × not_seen_recently`, where `weight` is board_weight in the exam track or a flat/strand-priority weight in the general track. Pick the top 2–3 concepts, with 2 questions each at their edge difficulty (p ≈ 0.6–0.7, the "desirable difficulty").
- **Challenge (2):** a case-based or difficulty-3 question in a Practising concept.
- **Review injection:** replace up to 3 slots with Fading concepts.
- **No repeats:** avoid questions seen in the last 30 days; re-serve a missed question once after 3 days (spaced retry).

### 5.4 Board Readiness (exam track only)
- `expected_marks = Σ_chapters board_weight × effective_mastery_chapter`
- Shown as a ±range that narrows as coverage grows. The range is also recalibrated from mock-paper results.
- The general track has no equivalent "readiness" number by design — its own progress framing is skill-tree completion % and streak-based motivation (§3, S5).

### 5.5 Coach messages
- **Rule engine first** (free, instant, deterministic), with about 40 templates keyed on events: a new mastered concept, a repeated misconception, the streak, a fading concept, a big jump. Templates are shared across both tracks; exam-specific ones (readiness-related) simply don't fire for general-track learners.
- **AI polish** (Pro, optional): Claude Haiku 4.5 rewrites the template plus facts into 2–3 warm sentences.
  - Strict JSON facts in, the model is told it may not invent numbers, a max of 60 words, and results are cached.
  - If the AI call fails, the template is shown instead.
- **"Explain differently"** (v1.1+, Pro): Haiku with the question, the stored solution, and the learner's wrong answer. It is constrained to reference the stored solution (no new maths claims) and cached per question and misconception.

**AI cost guardrails**
- Per-user daily cap on AI calls, and a cache keyed by content hash.
- Target average under ₹5 per Pro user per month. Free users get effectively zero AI cost.

**AI usage policy (decided 26 Sep 2026, unchanged by the scope revision).** Keep AI usage to where it's genuinely needed, not as a default answer to every feature: content generation (question authoring, §4.3), mock-exam assembly, and building a curated study plan are the cases that justify it. Day-to-day interactions — grading MCQ/numeric/assertion-reason answers, mastery updates, the workout selector, the coach's template messages — stay deterministic and rule-based, both because it's cheaper and because it's easier for learners to trust a rule than an opaque model call. Free-tier AI usage is heavily restricted (the rule-engine coach message, no "AI polish", no "explain differently"); those stay Pro-only per the table above.

---

## 6. Technical architecture

```
Flutter app (Android) ──► Supabase
 ├─ Riverpod state            ├─ Auth (Google, email OTP)
 ├─ go_router                 ├─ Postgres + RLS
 ├─ Drift (SQLite) cache      ├─ Storage (figures, share images)
 ├─ Mastery engine (Dart)     ├─ Edge Functions (TS)
 ├─ Sync queue                │    ├─ coach-message  → Claude Haiku
 └─ flutter_math_fork         │    ├─ revenuecat-webhook
                              │    ├─ parent-report (weekly cron, exam-track minors)
                              │    └─ content-pack (signed URL)
RevenueCat ◄── Play Billing   └─ pg_cron (calibration, reports)
PostHog (analytics) · Sentry (crashes) · FCM (push)
```

### Content delivery
- Questions ship as **versioned content packs** (compressed JSON per chapter/strand, about 100–300 KB each), downloaded on first use and cached in Drift. This keeps the app fast and offline, with low server cost (Supabase Storage/CDN).
- Pro-only content (mock papers, full solutions) is fetched with auth-checked signed URLs.

### Data model (Postgres)
| Table | Key columns |
|---|---|
| `boards` | id (cbse, icse, general, …), name — `general` is a pseudo-board representing the curriculum-free track |
| `classes` | id, board_id, grade (9, 10, …, or null for `general`), academic_year |
| `profiles` | id (auth uid), display_name, track (exam/general), board_id *(nullable)*, class_id *(nullable)*, target_band *(nullable)*, reminder_time, daily_minutes, parent_contact *(nullable)*, parent_consent_at *(nullable)*, is_minor, country, created_at |
| `enrollments` | user_id, board_id, class_id *(nullable for general track)*, target_band *(nullable)*, exam_date *(nullable)*, diagnostic_done_at |
| `chapters` | id, board_id, class_id *(nullable)*, name, board_weight *(nullable for general track)*, order |
| `concepts` | id, chapter_id, name, prerequisites[] (may cross board/general boundaries via alias), misconceptions jsonb |
| `questions` | id, board_id *(nullable — general-track questions aren't board-specific)*, concept_ids[], difficulty, type, section *(exam track only)*, marks *(exam track only)*, body jsonb (type-specific payload), status (live/hidden/review), content_version |
| `blueprints` | id, board_id, class_id, sections jsonb, weightage jsonb, version — **exam track only** |
| `attempts` | id, user_id, question_id, session_id, answer, correct, misconception_id, hints_used, time_ms, created_at |
| `sessions` | id, user_id, kind (diagnostic/placement/workout/practice/mock), started_at, completed_at, score, meta jsonb |
| `concept_mastery` | user_id, concept_id, theta, half_life, last_practiced, mastered_at, attempts, correct (PK user+concept) |
| `streaks` | user_id, current, longest, rest_tokens, last_active_date |
| `question_reports` | id, user_id, question_id, reason, note, status |
| `subscriptions` | user_id, product, status, expires_at, source (via RevenueCat webhook) |
| `mock_results` | session_id, section_scores jsonb, chapter_scores jsonb — **exam track only** |

Removed from the old multi-subject model: `subjects` (status/eta/accent_color — no longer needed with one subject), `subject_waitlist`, `grading_results` (rubric-grading table — no subjective grading in scope), `rubric jsonb` on `questions`.

- **RLS:** a user reads and writes only their own rows. Content tables are read-only to clients.
- **Sync:** attempts are append-only (idempotent client UUIDs). `concept_mastery` is recomputed on the device, and the server keeps the latest version by updated_at. The server can recompute from attempts if needed, because attempts are the source of truth.

### Flutter project structure (`app/lib/`)
```
core/      theme/, router/, db/ (drift), sync/, analytics/, mastery/ (pure Dart + tests),
           content_packs/, tracks/ (exam vs. general track routing/config),
           question_types/  ← plug-in registry: each type = {model, renderer, input widget, grader}
             mcq/, numeric/, expression/ (math keypad + checker), assertion_reason/, case_based/
           math_render/ (LaTeX)
features/  onboarding/ (track fork), diagnostic/, placement/ (general-track quiz), today/, workout/,
           skill_map/, concept_detail/, tests/ (mock player + results, exam track),
           practice/ (general-track practice sets), paywall/, parent_report/ (exam track), profile/, auth/
shared/    widgets/ (buttons, cards, progress rings, mastery bar, streak flame)
```

**Key packages**
- flutter_riverpod, go_router, drift, supabase_flutter, flutter_math_fork, math_expressions
- purchases_flutter (RevenueCat), posthog_flutter, sentry_flutter, firebase_messaging
- lottie or rive, share_plus, google_sign_in

### Repo layout (`e:\Mobile apps\study-gym\`)
```
app/        Flutter app
backend/    supabase/ (migrations, seed, functions/)
content/    syllabus/{board}/{class}/math.yaml, syllabus/general/math_core.yaml, blueprints/,
            pipeline/ (types/), review-app/, packs/ (build output per board or general track)
docs/       PRD, design notes, privacy policy, store listing copy
```

---

## 7. Monetisation

### Model: freemium with a subscription and a seasonal pass (exam track); a simpler recurring plan (general track — needs its own go-to-market thinking, not yet fully speced)
| Feature | Free | Pro |
|---|---|---|
| Diagnostic/placement + skill map | ✓ | ✓ exact range + plan (exam track); ✓ full strand breakdown (general) |
| Daily workout | 1/day | Unlimited + extra drills |
| Concept practice | 10 questions/day | Unlimited |
| Hints | Hint 1 | Full ladder + step-by-step solutions |
| Mock board papers (exam track) / challenge rounds (general) | 1 | All, with deep analysis |
| Coach | Template | AI-personalised + "Explain differently" |
| Parent weekly report (exam-track minors only) | — | ✓ |
| Offline packs | Current chapter/strand | All |

**Pricing** (India-tuned for the exam track; general track and international pricing are placeholders, see below).

**Exam track — Season 1** (2026–27)
- **Monthly ₹149**
- **Yearly ₹799** (≈ ₹67/mo)
- **Board Exam Pass ₹399**, valid until 31 May 2027 (covers both exam windows). This is the Dec–Feb hero offer.
- **7-day free trial** on monthly and yearly.

**General track (v1.1) — placeholder, needs testing**
- No seasonal urgency like a board exam to anchor pricing on. Likely a plain monthly/yearly (e.g. similar ₹149/mo, ₹799/yr as a starting hypothesis) with its own trial, but the actual price and paywall framing need dedicated experimentation once the track ships — **do not treat the numbers here as decided.**

**International pricing — flagged, not speced.** Store pricing in local currency/USD is needed once non-Indian users show up in meaningful numbers (from waitlist or install data). This includes its own tax/compliance considerations per country and is out of scope for this revision beyond flagging it as a v1.5+/v2 workstream (§9, §13).

**Anchor (exam track):** one month of home tuition for maths costs ₹1,500–4,000, so a whole year of Pro costs less than one tuition month.

**Future add-ons:** Class 9 + 10 bundle (exam track), a sibling/family plan, additional general-track strand packs (e.g. a "Calculus" or "Competition Math" add-on).

### Paywall moments (value first, then ask)
1. After the first workout result (motivation peak), soft and dismissible.
2. Hitting the free daily limit.
3. Tapping a locked mock paper / challenge round or a full solution.
4. The mock result screen's "5 fastest mark gains" plan (exam track).

### The parent is the payer (exam-track minors only)
- "Ask a parent" sends a WhatsApp message with a link to a small web page (hosted on Supabase or Vercel) showing the child's skill map summary, plus a pay button (Razorpay/UPI via the web, v1.1).
- Web purchases sync to the app through RevenueCat's web billing or a custom entitlement.
- This flow does not apply to general-track users or to adult exam-track users (e.g. an adult retaking a board exam).

### Revenue model (exam track, one season, rough)
| Installs | Active (D30) | Payers (3%) | Avg revenue/payer (after 15% Play fee) | Revenue |
|---|---|---|---|---|
| 10k | 2.5k | 300 | ₹420 | ₹1.3 L |
| 50k | 12k | 1,500 | ₹420 | ₹6.3 L |
| 200k | 50k | 6,000 | ₹420 | ₹25 L |

- **Costs at 50k installs:**
  - Supabase ₹2–3k/mo
  - AI about ₹5–8k/mo
  - Reviewer ₹10k/mo
- **Gross margin is healthy.** The real constraint is **distribution**.
- The general track's revenue model is unmodeled until it ships and its pricing/conversion is tested — it likely has lower urgency-driven conversion than the exam track's board-exam anchor, offset by a much larger addressable audience.

### Future revenue lines
- School and tuition-centre licences (a teacher dashboard, exam track)
- Class 9 + 10 bundle (exam track)
- Crash-course packs before exams (exam track)
- Strand add-on packs (general track, e.g. Calculus, Competition Math)
- A second board/curriculum pack, by demand

---

## 8. Go-to-market (bootstrapped)

1. **Pre-launch (Oct–Nov)**
   - Instagram and YouTube Shorts account "Board Maths in 30 seconds": post daily from misconception data, e.g. "70% of students get this sign wrong".
   - Waitlist link in bio. Target 1,000 waitlist sign-ups by launch. **Waitlist form also asks board/country and "just curious about math, not for an exam?"** — this demand signal decides the general-track's early framing and which second board/curriculum ships next (§2A).
2. **Beta cohort (Nov)**
   - 30–50 students: the founder's relative and friends, 2–3 local tuition teachers (they get the free teacher view and their students get a free Pro season).
   - Hold weekly 15-minute interviews.
3. **Launch (early Dec, exam track)**
   - Play Store with strong ASO. Title example: "Class 10 Maths – Board Prep Gym".
   - Keywords: cbse class 10 maths, sample paper, board exam, maths practice.
   - Screenshots show the skill map and the readiness score.
   - Collect ratings with an in-app review prompt after the 3rd completed workout, and only if the score is ≥ 7/10.
4. **General-track launch (Jan 2027, v1.1)**
   - Its own store listing angle and ASO keywords (e.g. "math practice", "learn math", "math skills") distinct from the exam-track's board-exam keywords.
   - Announce to the existing exam-track install base as a "no exam? try this" cross-sell, and to anyone who ticked "just curious" on the waitlist.
5. **Referral loop:** invite a friend, and both get 7 days of Pro. A share card of the workout result goes to Instagram stories.
6. **Parent loop (exam track):** a weekly WhatsApp report is organic marketing to the payer.
7. **Seasonal pushes (exam track):**
   - Pre-board week (Jan)
   - "30 days to boards" challenge (mid-Jan to Feb)
   - Second-exam window (Apr–May)
8. **Avoid paid ads** until D7 retention ≥ 20% and trial→paid ≥ 30%. After that, test ₹10–20k on Meta/YouTube with the Board Exam Pass creative (exam track) or a general-track equivalent once its funnel is proven.

---

## 9. Legal and compliance

**India-specific rules (DPDP Act, Play Families policy, UPI/parent-report flows) apply conditionally — only when the user is on an India-based board (e.g. CBSE) AND is a detected/declared minor.** They are not the global default. A general-track user, or an adult on any track, follows a standard international flow instead.

### Conditional: exam-track minors on an India-based board
- **DPDP Act 2023 plus its Rules.** For these users:
  - collect **verifiable parental consent** (a parent OTP/email confirmation flow at account creation or before the parent report)
  - no behavioural tracking or targeted ads for minors
  - minimum data (no exact age or DOB needed beyond the class), and a clear privacy notice
  - data deletion inside the app
- **Google Play:** target audience declared as 13–17 for this cohort, so Families policy considerations apply: no ad SDKs, and analytics configured compliantly for that segment. Data safety form, a privacy policy URL, and account deletion inside the app plus a web deletion link.
- **Payments:** Play Billing for in-app digital goods (a 15% service fee on subscriptions). Web/UPI checkout only via compliant flows.

### Default: general-track users and adult exam-track users (any country)
- Standard app-store terms (no minor-specific consent flow).
- Standard analytics (still privacy-respecting, but not minor-restricted).
- Store pricing in local currency/USD where available; a specific international pricing/tax-compliance plan is a flagged v1.5+/v2 workstream, not yet speced (§7).
- No parent-report feature is shown or offered.

### Applies regardless of track/country
- **Content IP:** original questions, and a trademark search on the app name before launch.
- **Business setup:** start as a sole proprietor or register an LLP/Pvt Ltd once revenue starts. GST registration when it crosses the threshold (Play handles GST on in-app sales in India, but verify with a CA). International sales tax/VAT handling is part of the flagged international-pricing workstream.
- A general age-gate at signup (or a lightweight "are you a student under 18?" toggle) determines whether the India-minor-specific consent flow triggers at all — implementation detail to work out during the general-track build.

---

## 10. Build roadmap (solo + Claude), week by week
*Week 1 starts 28 Sep 2026.*

### Phase 0: Foundations (Weeks 1–2, 28 Sep → 11 Oct)
- [ ] Set up the repo, Flutter project, Supabase project, and CI (GitHub Actions: `flutter analyze`, `flutter test`, content validation).
- [ ] Build the data model (boards/classes/enrollments, with `general` as a pseudo-board) and the question-type registry (math types only).
- [ ] Write `cbse/10/math_standard.yaml`: 14 chapters, about 150 concepts, prerequisites, misconceptions, and board weights.
- [ ] Content pipeline: `generate.py`, `validate.py` (SymPy), `critique.py`, `import.py`.
- [ ] Pilot one chapter (Quadratic Equations) end to end: 300 questions, then measure the reject rate and the human-found error rate.
- [ ] Wireframes (Figma, or quick Flutter mock screens) for S1–S12, including the S1 track fork.
- [ ] Hire or line up 1 maths teacher reviewer (part-time, paid per batch).
- [ ] Start the Instagram/Shorts account and waitlist page (with the board/country/"just curious" question).

### Phase 1: Core loop (Weeks 3–5, 12 Oct → 1 Nov)
- [ ] Design system and shared widgets (theme, cards, rings, mastery bars, streak flame).
- [ ] Maths rendering and the **custom maths keypad** plus the answer checker (with unit tests).
- [ ] Drift schema, content-pack download and caching.
- [ ] Mastery engine (pure Dart) with simulation tests.
- [ ] Onboarding (S1–S2), diagnostic (S3), and result (S4) — CBSE exam track.
- [ ] Auth (Google plus email OTP) and the sync queue to Supabase.
- [ ] Today (S5), workout player (S6), and workout complete (S7).
- [ ] Content grows to 1,500 verified questions across all chapters.

### Phase 2: Beta-ready (Weeks 6–7, 2 Nov → 15 Nov)
- [ ] Skill map (S8) and concept detail, practice mode.
- [ ] Streaks with rest days, push reminders (FCM), and review (Fading) injection.
- [ ] Report-a-question with auto-hide, and the rule-based coach.
- [ ] PostHog events and funnels, Sentry.
- [ ] Parental consent flow (India minors), privacy policy, account deletion.
- [ ] **Closed beta** on the Play internal/closed testing track with 30–50 students.

### Phase 3: Monetise and launch (Weeks 8–10, 16 Nov → 6 Dec)
- [ ] Mock test player and result analysis (S9), plus 6 assembled mock papers.
- [ ] RevenueCat plus Play Billing, paywall (S11), trial, and entitlement gating.
- [ ] Parent report (S12) as a shareable image and web link, plus a weekly cron.
- [ ] AI coach polish (Haiku) behind the Pro flag, with caching and caps.
- [ ] Content grows to about 6,000 questions. Run a calibration job on beta data.
- [ ] Store listing, screenshots, ASO, and a performance pass on a low-end device.
- [ ] **Production launch (target: first week of Dec) — CBSE exam track.**

### Phase 4: General track (Dec 2026 → Jan 2027, v1.1)
- **Dec:**
  - `general/math_core.yaml`: strand structure, ~120 concepts, prerequisites (including aliases to CBSE concepts where they overlap).
  - Onboarding track fork (S1), placement quiz (S3-gen), placement result (S4-gen).
  - Content generation for the general track (~4,000–5,000 questions), reusing the existing pipeline unchanged.
- **Jan (v1.1):**
  - General track live: Today/Skill Map/Practice re-themed per track, no Board Readiness/parent-report shown.
  - Its own paywall copy and pricing test.
  - Weekly retention/conversion review continues as in the exam track.

### Phase 5: Deepen both tracks (Feb → Jun 2027)
- CBSE Class 9 Maths live (new academic session, Feb/April per demand).
- General track grows more strands (calculus, discrete/recreational math).
- Second Class 10 exam window push (exam track).
- "Explain differently" AI follow-up chat (both tracks).
- Decide the next board/curriculum from waitlist + install-geography data — not pre-committed.

### Phase 6: Second board/curriculum, iOS (Jul → Dec 2027)
- Build whichever second board/curriculum the demand data actually supports (ICSE, a state board, or a generic international pack).
- iOS port from the same Flutter code.
- International pricing/legal workstream, if non-Indian installs justify it by this point.

### Phase 7: Expand (2028 →)
- Further boards/curricula/countries and general-track strand depth (competition math, more advanced topics), chosen by demand data each time.
- The same content pipeline applies each time: syllabus/strand YAML + (blueprint, if exam-track) + reviewer.

---

## 11. Metrics and analytics

**Event taxonomy (PostHog):** `onboarding_started`, `track_selected` (exam/general), `diagnostic_completed` / `placement_completed`, `account_created`, `workout_started`, `workout_completed`, `question_answered` (correct, hints, time), `hint_used`, `solution_viewed`, `concept_mastered`, `paywall_viewed` (trigger), `trial_started`, `purchase_completed`, `parent_report_shared` (exam-track minors), `question_reported`, `referral_sent`.

**Funnel targets**
| Metric | Target |
|---|---|
| Install → diagnostic/placement completed | ≥ 60% |
| Diagnostic/placement → account created | ≥ 70% |
| D1 / D7 / D30 retention | ≥ 40% / 20% / 10% |
| Workout completion rate | ≥ 70% |
| Paywall view → trial | ≥ 8% |
| Trial → paid | ≥ 35% |
| Install → paid (season, exam track) | 2–4% |
| Question error reports | < 0.5% of questions; < 1 per 1,000 answers |
| Crash-free sessions | ≥ 99.5% |
| Play rating | ≥ 4.5 |

General-track funnel targets are not yet set — track separately from launch and set targets once v1.1 has real data, since its retention/conversion drivers (curiosity vs. exam urgency) differ from the exam track's.

**Learning-outcome proof** (for marketing and our own honesty):
- Track the mastery gain per 10 workouts (both tracks).
- Compare mock-paper score changes over 4 weeks (exam track).
- Survey actual board results in May ("share your result, get a free year of Class 11") — exam track.
- General track: survey self-reported confidence/goal progress at 4 and 12 weeks, since there's no exam result to anchor on.

---

## 12. Budget (under ₹50k)
| Item | Cost |
|---|---|
| Google Play developer account | ~₹2,100 one-time |
| Claude API: content generation (6k CBSE questions + critique) | ~₹4–6k |
| Claude API: runtime AI (Dec–Mar) | ~₹5–10k |
| Teacher reviewer (about 2,000 reviews) | ~₹12–15k |
| Supabase (free until scale, then $25/mo) | ₹0–8k |
| Domain + landing page | ~₹1k |
| Design assets (icons, Lottie) | ₹0–3k |
| Small ad tests (only if the gates pass) | ₹0–10k |
| **Total (CBSE exam-track launch)** | **~₹30–50k** |

**General track (v1.1, funded from Season 1 revenue, not the initial budget):**
- About ₹5–8k in generation API spend (~4,000–5,000 questions).
- Reuses the same reviewer relationship (still a maths teacher, no new hire needed).

**A future second board/curriculum** (funded from revenue, timing tied to demand data, not pre-budgeted):
- About ₹5–8k in generation API spend.
- Possibly a second reviewer if the board differs enough in style (e.g. ICSE vs. CBSE), otherwise the same reviewer.

**Rule:** build the general track once the CBSE alpha ships (already the plan — v1.1). Build a second board/curriculum only when waitlist/install data justifies it, or its cost is covered by revenue.

---

## 13. Risks and mitigations
| Risk | Mitigation |
|---|---|
| Wrong answer keys destroy trust | SymPy verification, human sampling, report + auto-hide, nightly calibration flags |
| Solo founder bandwidth, missing the Dec window | Strict v1 scope (CBSE exam track only). Content pipeline runs in parallel (batch jobs overnight). Cut mock-paper analysis depth before cutting quality. |
| Typing maths on a phone is frustrating | Custom keypad, MCQ-heavy early difficulty, and equivalence-based checking |
| Students churn after exams (exam track) | Class 9 roadmap, second-exam window, yearly plan pitched as "board + next class"; the general track also gives a churned exam-track user somewhere to land post-exam instead of leaving entirely |
| Big competitors (PW, Byju's, Doubtnut, Toppr in India; Photomath, Khan Academy, Brilliant globally) | Narrow and deep: the best math *practice* experience (not videos, not answers), in both an exam-prep flavor and a curiosity-driven flavor. Misconception-level diagnosis is the edge in both. |
| Parents won't pay (exam track) | Parent report, ₹399 seasonal pass anchored against tuition fees, UPI web checkout |
| **General track has no natural urgency moment like a board exam** | Its pricing/paywall framing needs dedicated testing (§7) rather than reusing the exam track's "marks away from target" hook; lean on streaks, curiosity, and a much larger addressable audience instead of urgency. |
| **Diluting focus by running two tracks** | Both tracks share one engine, one pipeline, one question-type set — the incremental cost of the second track is content authoring, not a second product. Ship the general track only after the exam-track alpha is stable, and keep its scope (§2A) deliberately narrow (skill tree + placement quiz, no exam-specific features) rather than mirroring every exam-track feature. |
| AI cost creep | The AI is optional polish. Rules and templates as fallback, caching, per-user caps. |
| Compliance for minors (India exam track) | Parental consent flow, no ads, minimal data, deletion inside the app — scoped to the cohort it actually applies to (§9), not the whole user base. |
| International pricing/legal is unspeced | Flagged explicitly (§7, §9) as a v1.5+/v2 workstream to plan properly once non-Indian installs justify it, rather than guessing now. |
| Syllabus changes | Syllabus YAML is the single source of truth. Content versioning, and questions are tagged to concepts so they can be retired. |
| Scope creep back toward multi-subject | This plan explicitly scraps, not defers, other subjects (§0, §2A). Reopening that requires a fresh, deliberate decision — not a "while we're at it" addition. |
| Content volume for two tracks (~10-11k questions for v1.1) | Automated pipeline and batch generation, one part-time reviewer, reused across both tracks since it's all math |
| Copyright of source material | Never reproduce full prescribed texts/past papers verbatim. Use style references only. |

---

## 14. Verification plan (when building)
- **Content:**
  - CI runs `validate.py` on every content change.
  - 100% of machine-checkable answers are re-solved by SymPy, and any mismatch blocks the import.
  - Track the sampled human error rate per batch; it must stay under 1%.
- **Mastery engine:**
  - Dart unit tests with simulated students (perfect, random, weak-on-one-concept, forgetting).
  - Assert that the diagnostic/placement identifies the weak concept within its budget (20 items exam track, 10 general), that the "mastered" rule needs 2 separate days, and that decay triggers review.
  - Assert prerequisite aliasing works correctly when a concept exists in both a board syllabus and the general track.
- **Answer checker:** a table-driven test of equivalent forms (fractions, decimals, ±, surds).
- **App:**
  - `flutter analyze` and `flutter test`.
  - An integration test of onboarding → diagnostic → result → workout → complete (exam track) and onboarding → placement → result → workout → complete (general track).
  - Manual tests on a real low-end Android phone (≤ 3 GB RAM), including airplane mode for an offline workout plus sync afterwards.
- **Payments:** RevenueCat sandbox covering purchase, trial, restore, cancel, and expiry. Test entitlement gating on the internal testing track.
- **Real-world:**
  - The founder's relative plus the beta cohort use it daily for 2 weeks (exam track).
  - Check that the skill maps match what their teachers say and that mock-paper scores rise.
  - Beta gates (§11) must pass before launch spend.

---

## 15. First concrete step when building starts
1. Scaffold `e:\Mobile apps\study-gym\` (`app/`, `backend/`, `content/`, `docs/`) with the **board/class data model (with `general` as a pseudo-board) and the question-type registry** in place from the first commit.
2. Hand-write `content/syllabus/cbse/10/math_standard.yaml` for all 14 chapters (concepts, prerequisites, misconceptions, weights).
3. Build `generate.py` + `validate.py` and pilot **Quadratic Equations** (300 questions) to prove content quality before writing app code.
4. Once the CBSE alpha ships (Phase 3), immediately start `content/syllabus/general/math_core.yaml` (Phase 4) — it is the next release, not a deferred one.

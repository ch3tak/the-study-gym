
# "Study Gym": detailed build and business plan
*Working name. Options to test: StudyGym, Rep, Topper Gym, Padhai Gym. It must be subject-neutral, so no "Maths" in the brand. Last updated 26 Sep 2026.*

---

## 0. Context and decisions

**The idea.** Someone close to the founder is weak at maths, which sparked this. The product is **a mastery system for every subject a student has in their board and class**. Example: CBSE Class 9 means Maths, Science, English, Hindi, and Social Science; vocational and skill subjects are out of scope. Existing apps either lecture (video courses) or answer homework (chatbots). Neither tells a student *exactly what they don't know* in each subject, nor trains it daily. We build a **mastery system shaped like a gym app**:

> **Diagnose → find weak concepts → daily workout → evaluate → adapt → track progress/streak → repeat**

**Decisions made**
| Question | Decision |
|---|---|
| End-state scope | **All core subjects for a board + class**, starting with CBSE Classes 9–10: Maths, Science, Social Science, English, Hindi (Course A/B). Other boards and classes follow. |
| Alpha scope | **CBSE Class 9 Mathematics and Science** (2026-27 NCF syllabus; decided 26 Sep 2026, replacing "Class 10 Maths only"). The Class 10 Maths syllabus stays in the repo as a sample. Built on a subject-agnostic architecture from day one. Sections below that assume a Class 10 board-exam launch need revisiting. |
| Expansion order | Maths → Science → Social Science → English → Hindi (rationale in §2A) |
| Builder | Founder solo with Claude as pair-programmer, using **Flutter** |
| Budget before revenue | Bootstrapped, **under ₹50,000** |
| Priorities | 1) Great UX. 2) The app delivers what it promises: correct questions, honest mastery numbers, in every subject. |
| Platform | Android first (about 95% of Indian students), iOS later from the same Flutter code |

**Why maths first.**
- Board exams create urgency, and parents already pay for maths tuition.
- Maths answers can be graded **automatically and objectively**, so trust is easiest to prove there.
- It lets us validate the loop (diagnose → workout → mastery) before taking on subjects that need subjective grading.

**Architecture rule from day one.** No code, table, screen, or content format may assume "maths".
- Board, class, subject, chapter, and concept are data, not code.
- Question types and graders are pluggable per subject.
- Adding a subject should mean **new content + possibly a new question type/grader**, not a rewrite.

**The calendar drives everything**
- Class 10 board exam: **Feb–Mar 2027**. From 2026, CBSE also runs an optional second Class 10 exam around May, which is a second selling window. *(Verify the exact 2027 dates.)*
- Peak willingness to pay: **Dec → Feb** (pre-boards and final revision).
- Plan: closed beta by **mid-Nov 2026**, Play Store launch plus paywall by **early Dec 2026**.

---

## 1. Positioning and promise

**One-liner (end state):** *"Your daily study workout for every subject in your class. We find exactly what you're weak at, train it, and show your exam readiness, subject by subject."*

**Alpha one-liner:** *"Your 15-minute daily maths workout for Class 10 boards. More subjects coming."* The store listing names upcoming subjects honestly, with no vague promises. A "coming soon" subject shows its expected month.

**We are NOT:**
- a video course
- a doubt-solving chatbot
- a PDF sample-paper dump

**We ARE:** a personal trainer for your whole class syllabus that knows your weak muscles.

| Gym | Maths Gym |
|---|---|
| Fitness assessment | Diagnostic test |
| Muscle | Concept |
| Workout | Daily 10-question set |
| Reps / weight | Questions / difficulty |
| Trainer | Coach (rules + AI) |
| Body stats | Skill map + Board Readiness |
| Streak | Study consistency |

**North-star metric:** *weekly concepts newly mastered per active student.* We do not optimise for minutes spent or questions answered.

### Trust rules (how we "deliver what we promise")
1. **No live-generated questions.** Every question is pre-generated, machine-verified (SymPy), and sampled by a human before it reaches students.
2. **Target ≥ 99.5% answer-key accuracy.** "Report a problem" sits on every question. Any question with 2 or more reports is auto-hidden until reviewed.
3. **Every % is explainable.** Tap it to see what it's based on, e.g. "14 questions, 11 correct, last practiced 2 days ago".
4. **"Mastered" is hard to earn.** It requires ≥ 80% predicted accuracy on 2 separate days at least 3 days apart. There is no fake progress.
5. **Board Readiness is conservative.** It shows a range ("58–64 / 80"), never an inflated single number, and it states the coverage ("based on 9 of 14 chapters").
6. **No dark patterns.** Cancellation is clear, the trial reminder goes out 2 days before billing, there is no guilt-trip copy, and streak rest days are built in.

---

## 2A. Multi-subject strategy

### Subjects in scope (CBSE Classes 9 & 10)
| Subject | What students must do in the exam | How we assess it | Grading difficulty |
|---|---|---|---|
| **Mathematics** (Standard/Basic in Class 10) | Solve problems, show steps | MCQ, numeric/expression entry, assertion-reason, case-based, step-checks | Low: deterministic (SymPy) |
| **Science** (Physics, Chemistry, Biology) | Concepts, numericals, diagrams, reasoning, equations | MCQ, numeric (with units), chemical-equation balancing, diagram labelling, assertion-reason, case-based, short answer | Low–Medium: numericals are deterministic, short answers need a rubric |
| **Social Science** (History, Geography, Political Science, Economics) | Facts, cause-effect, map work, explain/analyse | MCQ, match-the-following, chronology ordering, **map-pointing**, source/case-based, short/long answers | Medium: facts are deterministic, long answers need a rubric |
| **English** (Language & Literature) | Reading comprehension, grammar, writing (letters, analytical paragraphs), literature | Unseen passage MCQs, grammar transformation/gap-fill, literature extract questions, **writing tasks** | Medium–High: grammar is deterministic, writing needs rubric grading |
| **Hindi** (Course A / Course B) | अपठित गद्यांश, व्याकरण, साहित्य, रचना (पत्र, अनुच्छेद) | Same shapes as English, in Devanagari | High: Hindi NLP, Devanagari input and rendering, rubric grading |

### Why this expansion order
1. **Maths** (alpha): fully objective, which proves the core loop.
2. **Science**: the second-highest board anxiety. About 70% of it reuses maths-like objective types (numericals, MCQ). It adds only units, equation balancing, and diagram labelling.
3. **Social Science**: very large, fact-heavy syllabus that suits spaced repetition (retention is our strength). It adds a map question type and ordering/matching.
4. **English**: grammar and comprehension are objective. The writing section needs the **rubric grader** (built once, then reused by Hindi).
5. **Hindi**: reuses the English framework but needs Devanagari keyboard support, Hindi fonts, and a Hindi-capable grading prompt. It needs a Hindi-teacher reviewer.

### Subject-neutral core vs subject-specific parts
| Shared across all subjects (build once) | Per subject (plug-in) |
|---|---|
| Board → Class → Subject → Chapter → Concept data model | Syllabus YAML + misconception lists |
| Mastery engine, retention decay, workout selector | Question types it needs (renderer + grader) |
| Skill map, Today, streaks, Board Readiness, mock-test player | Exam blueprint (sections, marks, weightage) |
| Content pipeline stages (generate → validate → critique → review → import) | A validator per type (SymPy for maths/physics numericals, a chemistry equation balancer, a fact-check for SST, a rubric check for writing) |
| Paywall, parent report, analytics | Domain-expert reviewer (maths/science/SST/English/Hindi teacher) |

### Question-type registry (pluggable)
Each type implements three things in the app: `render()`, `inputWidget()`, `grade()`. In the pipeline it implements `validate()`.

| Type | Subjects | Grader |
|---|---|---|
| `mcq` / `multi_select` | All | Deterministic; distractor → misconception |
| `numeric` (with optional units + tolerance) | Maths, Science | Deterministic |
| `expression` | Maths | Equivalence check |
| `assertion_reason` | Maths, Science, SST | Deterministic |
| `case_based` (container of sub-questions) | All | Delegates to children |
| `match_pairs` | Science, SST, English | Deterministic |
| `order_sequence` (chronology, process steps) | SST, Science | Deterministic |
| `fill_blank` (typed, with an accepted-answers list + fuzzy match) | English/Hindi grammar, Science terms | Deterministic + normalisation |
| `chem_equation` (balance coefficients) | Science | Deterministic |
| `diagram_label` (tap hotspots on an SVG) | Science (Biology), SST | Deterministic |
| `map_point` (tap a location on an India/world SVG map) | SST (Geography, History) | Deterministic (region hit-test) |
| `short_answer` (1–3 sentences) | Science, SST, English, Hindi | **Rubric grader** (AI + keyword checks), graded with a confidence level |
| `long_answer` / `writing_task` (letter, paragraph, analysis) | English, Hindi, SST | **Rubric grader** following the CBSE marking scheme, with a confidence level |
| `photo_answer` (handwritten upload, v2) | All | Vision model + rubric |

### Trust rules for subjective grading (keeping the promise beyond maths)
- The **CBSE-style marking scheme** is stored with the question (value points, marks per point). The AI grades *against the value points*, not by its own opinion.
- The output is structured: which value points were hit or missed, the marks awarded, a quote from the student's answer as evidence, and a confidence level.
- **Low confidence → "Self-check" mode.** Show the model answer and the value points, and let the student tick what they covered. Never show a confident wrong grade.
- Subjective questions count **less toward mastery** than objective ones until the grader's accuracy is proven. Grader accuracy is measured monthly against a teacher-graded sample of 200 answers; target ≥ 90% agreement within ±0.5 marks.
- Show "AI-graded, tap to see why" on every subjective score.
- Rubric grading is **Pro-only** because it costs money per answer. Free users get self-check mode.

### Subject rollout calendar
| Release | Timing | Subjects / classes |
|---|---|---|
| Alpha / launch | Nov–Dec 2026 | Class 10 Maths |
| v1.1 | Jan 2027 | Class 10 Science (objective types + numericals; short answers in self-check) |
| v1.2 | Feb 2027 | Class 10 Social Science (objective + map + self-check short answers) |
| v1.5 | Apr–May 2027 | Rubric grader live. Class 10 English. Class 9 Maths + Science (for the new session starting April). |
| v2 | Jun–Aug 2027 | Class 9 SST + English, Hindi (A/B) for Classes 9–10 |
| v2.5 | Sep 2027 → | **The full CBSE 9–10 core** ahead of the 2027–28 board season. Then expand to Classes 11–12 (PCM/PCB) or Classes 6–8, based on demand. |
| v3 | 2028 | Other boards (ICSE, big state boards like UP and Maharashtra), Hindi UI, regional languages |

- The Dec 2026 launch is maths-only, because building quality content for five subjects in 10 weeks while solo would break the trust rules.
- Science and SST are pushed before the Feb–Mar 2027 exams, as quick revision products.
- The **2027–28 academic year is the first "all subjects" season**, and the full-class pass (§7) becomes the main offer.

### Content volume (per class, all 5 subjects)
| Subject | Chapters (approx.) | Concepts | Questions target |
|---|---|---|---|
| Maths | 14 | ~150 | ~6,000 |
| Science | 13 | ~160 | ~6,000 |
| SST | ~22 (4 books) | ~200 | ~7,000 |
| English | 2 books + grammar + writing | ~120 | ~4,000 + writing prompts |
| Hindi | 2–3 books + व्याकरण + रचना | ~120 | ~4,000 + writing prompts |

That is about 27k questions per class. Across Classes 9 and 10 it is about 55k. This is only feasible with the automated pipeline, plus **one reviewer per subject** (a part-time, paid-per-batch teacher).

---

## 2. Feature scope

### v1 (MVP, the paid launch in Dec, maths content on the multi-subject shell)
The app ships with the **subject switcher UI already present**. Maths is active; the other subjects show "Coming Jan/Feb" with a "Notify me" button. Signups there double as demand data for which subject to build next.

1. Onboarding with a diagnostic test
2. Skill map (chapters → concepts, colour-coded)
3. Daily workout (warm-up / strength / challenge)
4. Hint ladder and step-by-step solutions
5. Chapter and concept practice
6. Progress: mastery, streak, retention review, Board Readiness
7. Mock board papers: a full 80-mark CBSE pattern, timed, with analysis
8. Coach message after each workout (template plus light AI)
9. Parent weekly report, shareable on WhatsApp
10. Paywall, trial, and subscription (Play Billing)
11. Push reminders (user-chosen time)
12. Offline workouts

### v1.x → v2 (Jan–Sep 2027)
- Subjects roll out on the §2A calendar: Science → SST → English → Hindi, then Class 9.
- New question types as each subject needs them: units, chem equations, diagram labels, maps, matching/ordering, short/long answers, writing tasks.
- Rubric grader for subjective answers (Pro), with self-check mode as the fallback.
- **Cross-subject daily plan:** one "Today" workout mixing subjects by exam date, weakness, and weight (§5.6).
- "Explain differently" AI follow-up chat, scoped to one question.
- Photo upload of a handwritten answer, AI-graded against the marking scheme (Pro+).
- Teacher/tutor class dashboard (per subject).
- Weekly friend leagues (opt-in).

### v3+
- Classes 11–12 (stream-based subject sets), Classes 6–8
- Other boards (ICSE, state boards), Hindi UI, regional languages
- iOS

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

### Navigation (4 tabs + subject switcher)
- **Today**
- **Skill Map**
- **Tests**
- **Me**

Practice is launched from the Skill Map.

**Subject switcher.** A pill row at the top of Skill Map and Tests: *All · Maths · Science · SST · English · Hindi*.
- Each subject has its own accent colour and icon, so students always know which "muscle group" they're in.
- In alpha, only Maths is active; the others show "Coming soon · Notify me".
- **Today is cross-subject** (once there's more than one subject), because a student's day spans subjects.

**Subject-specific input widgets** all share one card layout and one submit/feedback pattern, so every subject *feels* the same:
- Maths keypad
- Units picker (Science numericals)
- Chem-equation coefficient steppers
- Tap-to-label diagrams
- Zoomable map with tap-to-place pin (SST)
- Drag-to-order and match-pairs
- Text answer box with a word counter and "Self-check / Get AI grade" (English/Hindi/SST)
- Devanagari keyboard hint for Hindi (uses the system Hindi keyboard, plus a tip to enable it)

### Screens

**S1. Welcome** (1 screen)
- Hook line, "Start free diagnostic" button, "I already have an account" link.

**S2. Quick setup** (about 4 taps)
- Board (CBSE; others greyed "coming soon")
- Class (10; 9 greyed until content exists)
- Subjects: all core subjects pre-selected. Class 10 Maths asks **Standard or Basic**; Hindi asks **Course A or B**. Unavailable subjects show "Notify me".
- Target (Just pass / 60+ / 75+ / 90+), overall or per subject
- Board exam month (auto-filled)
- Optional daily reminder time

**Diagnostic with more than one subject.** One short diagnostic per subject (about 12–15 items). The student picks which subject to start with, and the others are unlocked from the Skill Map, so onboarding stays under 15 minutes.

**S3. Diagnostic** (about 20 questions, about 12 min, skippable per question with "I don't know this yet")
- Adaptive: it starts mid-difficulty per chapter and moves up or down.
- A progress bar shows "Question 7 of ~20".
- No right/wrong feedback during the diagnostic (it reduces anxiety). Everything is revealed at the end.

**S4. Diagnostic result** (the "aha" moment, and the most important screen)
- Board Readiness range, e.g. "~41–48 / 80 today".
- Top 3 weak concepts with the likely misconception, e.g. *"Quadratics: you mix up the sign in −b/2a"*.
- Top 3 strong areas (positive framing).
- CTA: "Start my first workout".
- *Account creation is prompted here* ("Save your skill map"), using Google Sign-In in one tap or email OTP.

**S5. Today tab**
- Hero card: "Today's workout · 15 min · 10 reps" with the concept chips it will train.
- Streak flame with a week dots row (rest day shown as a moon).
- Review due: "3 concepts are fading. Quick refresh?"
- Board Readiness mini-gauge with its trend.

**S6. Workout player** (the core UX; must feel great)
- Section header: Warm-up 🔥 / Strength 💪 / Challenge 🧠.
- Question card: LaTeX stem, optional figure (SVG), answer area.
- Answer input by type:
  - MCQ: 4 large option cards
  - Numeric/expression: the **custom maths keypad** (see below)
  - Assertion–Reason: the standard 4 CBSE options
  - Case-based: a scrollable case plus sub-questions
- On submit:
  - **Correct:** green pulse and haptic, "+XP", a 1-line "why" (optional expand).
  - **Wrong:** a gentle shake, then options for "See hint", "Try again" (1 retry), or "Show solution".
  - The misconception message comes from the chosen distractor or a parsed numeric answer.
- Hint ladder: Hint 1 → Hint 2 → full solution (step by step, each step revealable).
- Using hints lowers the mastery gain (shown transparently).
- Timer is hidden by default (anxiety); an optional "exam mode" timer is available.

**S7. Workout complete**
- Score (8/10), XP, streak update, and per-concept mastery bars animating from old to new.
- The coach message (2–3 sentences, personalised).
- Buttons: "Share with parent" and "Done". An upsell appears only if the free limit is reached.

**S8. Skill Map tab**
- List of chapters, each with a ring (% concepts mastered).
- Expanding a chapter shows its concepts with status chips and the last practiced date.
- Tapping a concept opens the concept detail: mastery %, "why this number", common mistakes, and "Practice 5" / "Practice 10".
- Locked-prerequisite hint: "Master *Discriminant* first to unlock *Nature of Roots* challenge questions" (soft lock, never hard).

**S9. Tests tab**
- Mock board papers (Paper 1 free, the rest Pro), chapter tests, "Previous attempts".
- **Mock test player:**
  - Full-paper navigator with sections A–E
  - Mark-for-review, and a timer (3 h, or 90 min for a half paper)
  - Autosave, and works offline
- Long answers in v1 are split into auto-gradable sub-steps (the final answer plus key intermediate values).
- **Mock result:** marks by section and by chapter, time per section, mistakes grouped by misconception, "Your 5 fastest mark gains" (the concepts with the highest weight × weakness), and "Add these to my workouts".

**S10. Me tab**
- Profile and goal, subscription status, reminder settings.
- Parent report settings (a parent's WhatsApp number or email, with consent).
- Data and privacy: download or delete data. Help / report a problem.

**S11. Paywall** (full screen, dismissible)
- Headline tied to their data: *"You're ~18 marks away from your 75+ target. Pro gets you there."*
- 3 plans, with the Board Exam Pass highlighted. Benefits list, a 7-day trial, "Ask a parent" share link (a UPI-friendly web checkout later), and restore purchase.

**S12. Parent report** (shareable image plus a web link)
- Mastery trend, sessions this week, strong and weak areas, and one actionable suggestion.
- No minute-by-minute surveillance.

### Custom maths keypad (critical)
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
- Friendly older-sibling voice. Short sentences. Occasional light humour. Never shame ("Not yet" instead of "Wrong").

---

## 4. Content system

### 4.0 Layout for many subjects
- **Syllabus files:** `content/syllabus/{board}/{class}/{subject}.yaml`, e.g. `cbse/10/maths_standard.yaml`, `cbse/10/science.yaml`, `cbse/9/hindi_a.yaml`.
- **Exam blueprints:** `content/blueprints/{board}/{class}/{subject}.yaml` holds sections, question types per section, marks, internal choice rules, and chapter weightage.
- **Per-subject pipeline config:** `content/pipeline/subjects/{subject}.py` holds the allowed types, validators, generation prompt examples, and the reviewer queue.
- **Shared types and validators** live under `content/pipeline/types/`, one module per question type: its schema, validator, and generation hints.
- **Subject quirks**
  - Science numericals are verified with SymPy + `pint` (units).
  - Chemical equations are verified by an atom-count balancer.
  - SST facts are generated only **grounded in our own curated fact sheets**, written per chapter from NCERT and reviewed by a teacher. They are never taken from the model's memory, and the critique pass checks each question against its fact sheet.
  - English and Hindi literature questions reference the prescribed texts. We store only short extracts where fair-use allows; otherwise the question is written about the text without reproducing it.
  - Hindi content is stored as Unicode Devanagari and reviewed by a Hindi teacher.

The maths example below shows the shape. Every subject follows the same spine.

### 4.1 Curriculum spine: `content/syllabus/cbse/10/maths_standard.yaml`
- Source: the CBSE 2026–27 curriculum document plus the NCERT Class 10 chapter list (14 chapters): Real Numbers, Polynomials, Pair of Linear Equations, Quadratic Equations, Arithmetic Progressions, Triangles, Coordinate Geometry, Intro to Trigonometry, Applications of Trigonometry, Circles, Areas Related to Circles, Surface Areas & Volumes, Statistics, Probability.
- Each chapter holds: `id`, `name`, `board_weight_marks` (from the CBSE unit weightage), and `concepts[]`.
- Each concept holds: `id`, `name`, `description`, `prerequisites[]` (concept ids, including Class 9 ones), `common_misconceptions[]` (id, description, detection rule), and `question_types_allowed[]`.
- Target size: about 150 concepts. The misconception list per concept is written by hand, with Claude's help, and reviewed by the teacher.

### 4.2 Question model
```yaml
id: q_quad_disc_0142
concepts: [quad.discriminant]
difficulty: 2          # 1 easy · 2 board-standard · 3 challenge
type: mcq | numeric | expression | assertion_reason | case_based
cbse_section: A|B|C|D|E
marks: 1
stem: "For what value of $k$ does $x^2 + kx + 9 = 0$ have equal roots?"
figure: null | svg path
options: ["$\\pm 6$", "$6$", "$\\pm 3$", "$9$"]
answer: 0                        # or accepted_answers: ["6","-6"] for numeric
distractors:                     # misconception mapping
  1: quad.disc.missed_negative_root
  2: quad.disc.forgot_4ac_factor
  3: quad.disc.confused_c_with_k
hint1: "Equal roots means the discriminant is ..."
hint2: "Set $b^2 - 4ac = 0$ with $a=1, b=k, c=9$."
solution_steps: ["$D = k^2 - 36$", "$k^2 - 36 = 0$", "$k = \\pm 6$"]
verification: {sympy: "solve(k**2-36, k)", status: pass}
review: {human: true, reviewer: T1, date: ...}
quality: {reports: 0, p_correct_observed: null, discrimination: null}
```

### 4.3 Generation pipeline (`content/pipeline/`, Python)
1. **`generate.py`**
   - For each (concept, difficulty, type), call Claude (Sonnet 5 for generation, Batch API for 50% off) with:
     - the concept, its misconceptions, CBSE-style examples written by us, and a JSON schema
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
- Beta: 1,500 questions covering all 14 chapters.
- Launch: about 6,000 (150 concepts × about 40).
- 6 mock papers hand-assembled from the bank according to the CBSE blueprint.

**Copyright:** original questions only. NCERT and past CBSE papers are style references and are never copied verbatim.

**Cost:** about $30–60 in API spend. Teacher reviewer is about ₹8–12k (a part-time maths teacher paid per 500 reviews).

---

## 5. Learning engine

### 5.1 Mastery model (per student × concept), running on-device in Dart and synced
- **Elo-style ability rating:** θ (student ability for the concept) vs β (question difficulty).
  - `p = 1 / (1 + e^{-(θ-β)})`
  - After an answer: `θ += K · w · (outcome − p)`
  - K is higher for the first ~10 attempts (fast learning), lower afterwards.
  - w discounts hinted attempts: no hint = 1.0, hint1 = 0.6, hint2 = 0.35, solution viewed = 0 gain but full penalty if wrong.
- **Displayed mastery %** = p against a reference board-standard question (β = difficulty 2).
- **Retention decay:** each concept has half-life h (starts at 2 days).
  - Effective mastery = `mastery × 2^(−days_since/h)` (floored).
  - Each successful spaced review doubles h (capped at 60 days); a failure halves it.
- **States:** Not started → Learning (under 50%) → Practising (50–79%) → **Mastered** (≥ 80% on 2 days at least 3 days apart) → Fading (a mastered concept whose effective mastery drops below 70%, which triggers review).
- **Prerequisite propagation:** a weak prerequisite caps how high a dependent concept's challenge difficulty goes, and it is suggested first.
- **Explainability payload:** attempts, correct, hints used, last practiced, and the half-life, all shown in the "why this number" sheet.
- **Subject-agnostic by design.** The engine only sees concepts, questions (with difficulty), and outcomes (0–1).
  - Partial credit from rubric-graded answers feeds in as a fractional outcome, multiplied by the type's trust weight.
  - Fact-heavy subjects (SST, Biology) rely more on retention decay and spaced review. Their starting half-life is set per subject in config.

### 5.2 Diagnostic algorithm
- **Budget:** 20 items.
- Sample 1–2 concepts per chapter, weighted by board marks. Start at difficulty 2, adapt per chapter (correct → harder, wrong → easier).
- Rough-estimate θ for untested concepts from their chapter siblings, shown as "estimated" (a dotted ring) until practised.

### 5.3 Workout selector (10 questions)
- **Warm-up (3):** concepts at 60–85% mastery, difficulty 1–2. Confidence first.
- **Strength (5):** score candidates by `(1 − mastery) × board_weight × prereqs_met × not_seen_recently`. Pick the top 2–3 concepts, with 2 questions each at their edge difficulty (p ≈ 0.6–0.7, the "desirable difficulty").
- **Challenge (2):** a case-based or difficulty-3 question in a Practising concept.
- **Review injection:** replace up to 3 slots with Fading concepts.
- **No repeats:** avoid questions seen in the last 30 days; re-serve a missed question once after 3 days (spaced retry).

### 5.4 Board Readiness
- `expected_marks = Σ_chapters board_weight × effective_mastery_chapter`
- Shown as a ±range that narrows as coverage grows. The range is also recalibrated from mock-paper results.

### 5.6 Cross-subject daily plan (from v1.1, when 2+ subjects are live)
- The student sets a daily time budget (15 / 30 / 45 min).
- Each subject gets a **priority score**: `(board marks at stake − expected marks) × urgency(days to that subject's exam) × fading-concept load`. Subject exam dates come from the CBSE date sheet.
- Today's plan = 1–3 mini-workouts (5–10 reps each), taken from the top-priority subjects and rotated so no subject is ignored for more than 3 days.
- The student can always override: "Only Science today".
- **Overall Readiness** = the sum of per-subject expected marks against the student's target, with per-subject bars.
- The mastery engine itself is unchanged. It is keyed by concept, and concepts belong to subjects.
- Grading weight is per question type: subjective items count at 0.5 until the grader is validated.

### 5.5 Coach messages
- **Rule engine first** (free, instant, deterministic), with about 40 templates keyed on events: a new mastered concept, a repeated misconception, the streak, a fading concept, a big jump.
- **AI polish** (Pro, optional): Claude Haiku 4.5 rewrites the template plus facts into 2–3 warm sentences.
  - Strict JSON facts in, the model is told it may not invent numbers, a max of 60 words, and results are cached.
  - If the AI call fails, the template is shown instead.
- **"Explain differently"** (v1.1, Pro): Haiku with the question, the stored solution, and the student's wrong answer. It is constrained to reference the stored solution (no new maths claims) and cached per question and misconception.

**AI cost guardrails**
- Per-user daily cap on AI calls, and a cache keyed by content hash.
- Target average under ₹5 per Pro user per month. Free users get effectively zero AI cost.

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
                              │    ├─ parent-report (weekly cron)
                              │    └─ content-pack (signed URL)
RevenueCat ◄── Play Billing   └─ pg_cron (calibration, reports)
PostHog (analytics) · Sentry (crashes) · FCM (push)
```

### Content delivery
- Questions ship as **versioned content packs** (compressed JSON per chapter, about 100–300 KB each), downloaded on first use and cached in Drift. This keeps the app fast and offline, with low server cost (Supabase Storage/CDN).
- Pro-only content (mock papers, full solutions) is fetched with auth-checked signed URLs.

### Data model (Postgres)
| Table | Key columns |
|---|---|
| `boards` | id (cbse, icse, …), name |
| `classes` | id, board_id, grade (9, 10, …), academic_year |
| `subjects` | id, class_id, code (maths_standard, maths_basic, science, sst, english, hindi_a, hindi_b), name, status (live/coming_soon), eta, accent_color |
| `profiles` | id (auth uid), display_name, board_id, class_id, target_band, reminder_time, daily_minutes, parent_contact, parent_consent_at, created_at |
| `enrollments` | user_id, subject_id, target_band, exam_date, diagnostic_done_at (one row per subject the student takes) |
| `subject_waitlist` | user_id, subject_id, created_at (the "Notify me" demand signal) |
| `chapters` | id, subject_id, name, board_weight, order |
| `concepts` | id, chapter_id, name, prerequisites[] (may cross subjects/classes), misconceptions jsonb |
| `questions` | id, subject_id, concept_ids[], difficulty, type, section, marks, body jsonb (type-specific payload), rubric jsonb (value points, for subjective types), status (live/hidden/review), content_version |
| `blueprints` | id, subject_id, sections jsonb, weightage jsonb, version |
| `grading_results` | attempt_id, grader (deterministic/rubric_ai/self_check), marks, value_points_hit jsonb, confidence, model, created_at |
| `attempts` | id, user_id, question_id, session_id, answer, correct, misconception_id, hints_used, time_ms, created_at |
| `sessions` | id, user_id, kind (diagnostic/workout/practice/mock), started_at, completed_at, score, meta jsonb |
| `concept_mastery` | user_id, concept_id, theta, half_life, last_practiced, mastered_at, attempts, correct (PK user+concept) |
| `streaks` | user_id, current, longest, rest_tokens, last_active_date |
| `question_reports` | id, user_id, question_id, reason, note, status |
| `subscriptions` | user_id, product, status, expires_at, source (via RevenueCat webhook) |
| `mock_results` | session_id, section_scores jsonb, chapter_scores jsonb |

- **RLS:** a user reads and writes only their own rows. Content tables are read-only to clients.
- **Sync:** attempts are append-only (idempotent client UUIDs). `concept_mastery` is recomputed on the device, and the server keeps the latest version by updated_at. The server can recompute from attempts if needed, because attempts are the source of truth.

### Flutter project structure (`app/lib/`)
```
core/      theme/, router/, db/ (drift), sync/, analytics/, mastery/ (pure Dart + tests),
           content_packs/, subjects/ (subject registry, colours, icons),
           question_types/  ← plug-in registry: each type = {model, renderer, input widget, grader}
             mcq/, numeric/, expression/ (math keypad + checker), assertion_reason/,
             case_based/, match_pairs/, order_sequence/, fill_blank/, chem_equation/,
             diagram_label/, map_point/, short_answer/, long_answer/ (added per subject rollout)
           math_render/ (LaTeX), devanagari/ (fonts, normalisation)
features/  onboarding/, diagnostic/, today/, workout/, skill_map/, concept_detail/,
           tests/ (mock player + results), paywall/, parent_report/, profile/, auth/
shared/    widgets/ (buttons, cards, progress rings, mastery bar, streak flame)
```

**Key packages**
- flutter_riverpod, go_router, drift, supabase_flutter, flutter_math_fork, math_expressions
- purchases_flutter (RevenueCat), posthog_flutter, sentry_flutter, firebase_messaging
- lottie or rive, share_plus, google_sign_in

### Repo layout (`e:\Mobile apps\study-gym\`)
```
app/        Flutter app
backend/    supabase/ (migrations, seed, functions/ incl. rubric-grader later)
content/    syllabus/{board}/{class}/{subject}.yaml, blueprints/, factsheets/ (SST/Science),
            pipeline/ (types/, subjects/), review-app/, packs/ (build output per subject/chapter)
docs/       PRD, design notes, privacy policy, store listing copy
```

---

## 7. Monetisation

### Model: freemium with a subscription and a seasonal pass
| Feature | Free | Pro |
|---|---|---|
| Diagnostic + skill map + Board Readiness band | ✓ | ✓ exact range + plan |
| Daily workout | 1/day | Unlimited + extra drills |
| Concept practice | 10 questions/day | Unlimited |
| Hints | Hint 1 | Full ladder + step-by-step solutions |
| Mock board papers | 1 | All (6+ at launch, more monthly) with deep analysis |
| Coach | Template | AI-personalised + "Explain differently" |
| Parent weekly report | — | ✓ |
| Offline packs | Current chapter | All |

**Pricing** (India-tuned; test with Play price experiments). **One Pro plan unlocks every live subject for the student's class.** We don't charge per subject, because it's simpler and the price goes up in value as subjects are added.

**Season 1** (2026–27, maths-first)
- **Monthly ₹149**
- **Yearly ₹799** (≈ ₹67/mo)
- **Board Exam Pass ₹399**, valid until 31 May 2027 (covers both exam windows). This is the Dec–Feb hero offer. It includes Science and SST as they launch.
- **7-day free trial** on monthly and yearly.

**Season 2 onward** (2027–28, all core subjects)
- **Monthly ₹199**
- **Full-Class Yearly ₹1,499** (all 5 subjects, all year)
- **Board Pass ₹799**
- Existing yearly subscribers keep their price (loyalty and trust).

**Anchor:** one month of home tuition for a *single* subject costs ₹1,500–4,000, so a whole year of all subjects costs less than one tuition month.

**Future add-ons:** Class 9 + 10 bundle, and a sibling/family plan (2 students).

### Paywall moments (value first, then ask)
1. After the first workout result (motivation peak), soft and dismissible.
2. Hitting the free daily limit.
3. Tapping a locked mock paper or a full solution.
4. The mock result screen's "5 fastest mark gains" plan.

### The parent is the payer
- "Ask a parent" sends a WhatsApp message with a link to a small web page (hosted on Supabase or Vercel) showing the child's skill map summary, plus a pay button (Razorpay/UPI via the web, v1.1).
- Web purchases sync to the app through RevenueCat's web billing or a custom entitlement.

### Revenue model (one season, rough)
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

### Future revenue lines
- School and tuition-centre licences (a teacher dashboard at ₹X per student per year)
- Class 9 + 10 bundle
- Crash-course packs before exams
- Science add-on

---

## 8. Go-to-market (bootstrapped)

1. **Pre-launch (Oct–Nov)**
   - Instagram and YouTube Shorts account "Board Maths in 30 seconds": post daily from misconception data, e.g. "70% of students get this sign wrong".
   - Waitlist link in bio. Target 1,000 waitlist sign-ups by launch.
2. **Beta cohort (Nov)**
   - 30–50 students: the founder's relative and friends, 2–3 local tuition teachers (they get the free teacher view and their students get a free Pro season).
   - Hold weekly 15-minute interviews.
3. **Launch (early Dec)**
   - Play Store with strong ASO. Title example: "Class 10 Maths – Board Prep Gym".
   - Keywords: cbse class 10 maths, sample paper, board exam, maths practice.
   - Screenshots show the skill map and the readiness score.
   - Collect ratings with an in-app review prompt after the 3rd completed workout, and only if the score is ≥ 7/10.
4. **Referral loop:** invite a friend, and both get 7 days of Pro. A share card of the workout result goes to Instagram stories.
5. **Parent loop:** a weekly WhatsApp report is organic marketing to the payer.
6. **Seasonal pushes:**
   - Pre-board week (Jan)
   - "30 days to boards" challenge (mid-Jan to Feb)
   - Second-exam window (Apr–May)
7. **Avoid paid ads** until D7 retention ≥ 20% and trial→paid ≥ 30%. After that, test ₹10–20k on Meta/YouTube with the Board Exam Pass creative.

---

## 9. Legal and compliance (India)
- **DPDP Act 2023 plus its Rules.** Users are minors, so:
  - collect **verifiable parental consent** (a parent OTP/email confirmation flow at account creation or before the parent report)
  - no behavioural tracking or targeted ads for minors
  - minimum data (no exact age or DOB needed beyond the class), and a clear privacy notice
  - data deletion inside the app
- **Google Play:**
  - Target audience declared as 13–17, so the Families policy considerations apply: no ad SDKs, and analytics configured compliantly.
  - Data safety form, a privacy policy URL, and account deletion inside the app plus a web deletion link.
- **Payments:** Play Billing for in-app digital goods (a 15% service fee on subscriptions). Web or UPI checkout only via compliant flows.
- **Content IP:** original questions, and a trademark search on the app name before launch.
- **Business setup:** start as a sole proprietor or register an LLP/Pvt Ltd once revenue starts. GST registration when it crosses the threshold (Play handles GST on in-app sales in India, but verify with a CA).

---

## 10. Build roadmap (solo + Claude), week by week
*Week 1 starts 28 Sep 2026.*

### Phase 0: Foundations (Weeks 1–2, 28 Sep → 11 Oct)
- [ ] Set up the repo, Flutter project, Supabase project, and CI (GitHub Actions: `flutter analyze`, `flutter test`, content validation).
- [ ] Build the multi-subject data model (boards/classes/subjects/enrollments) and the question-type registry, even though only maths types are implemented.
- [ ] Write `cbse/10/maths_standard.yaml`: 14 chapters, about 150 concepts, prerequisites, misconceptions, and board weights. Add stub subject entries for Science, SST, English, and Hindi.
- [ ] Content pipeline: `generate.py`, `validate.py` (SymPy), `critique.py`, `import.py`.
- [ ] Pilot one chapter (Quadratic Equations) end to end: 300 questions, then measure the reject rate and the human-found error rate.
- [ ] Wireframes (Figma, or quick Flutter mock screens) for S1–S12.
- [ ] Hire or line up 1 maths teacher reviewer (part-time, paid per batch).
- [ ] Start the Instagram/Shorts account and waitlist page.

### Phase 1: Core loop (Weeks 3–5, 12 Oct → 1 Nov)
- [ ] Design system and shared widgets (theme, cards, rings, mastery bars, streak flame).
- [ ] Maths rendering and the **custom maths keypad** plus the answer checker (with unit tests).
- [ ] Drift schema, content-pack download and caching.
- [ ] Mastery engine (pure Dart) with simulation tests.
- [ ] Onboarding (S1–S2), diagnostic (S3), and result (S4).
- [ ] Auth (Google plus email OTP) and the sync queue to Supabase.
- [ ] Today (S5), workout player (S6), and workout complete (S7).
- [ ] Content grows to 1,500 verified questions across all chapters.

### Phase 2: Beta-ready (Weeks 6–7, 2 Nov → 15 Nov)
- [ ] Skill map (S8) and concept detail, practice mode.
- [ ] Streaks with rest days, push reminders (FCM), and review (Fading) injection.
- [ ] Report-a-question with auto-hide, and the rule-based coach.
- [ ] PostHog events and funnels, Sentry.
- [ ] Parental consent flow, privacy policy, account deletion.
- [ ] **Closed beta** on the Play internal/closed testing track with 30–50 students.

### Phase 3: Monetise and launch (Weeks 8–10, 16 Nov → 6 Dec)
- [ ] Mock test player and result analysis (S9), plus 6 assembled mock papers.
- [ ] RevenueCat plus Play Billing, paywall (S11), trial, and entitlement gating.
- [ ] Parent report (S12) as a shareable image and web link, plus a weekly cron.
- [ ] AI coach polish (Haiku) behind the Pro flag, with caching and caps.
- [ ] Content grows to about 6,000 questions. Run a calibration job on beta data.
- [ ] Store listing, screenshots, ASO, and a performance pass on a low-end device.
- [ ] **Production launch (target: first week of Dec).**

### Phase 4: Season 1 + Science & SST (Dec 2026 → Mar 2027)
- Weekly release train, with retention and conversion reviewed every Monday.
- **Dec:**
  - Science syllabus YAML, blueprint, and fact sheets.
  - New types: `numeric` with units, `chem_equation`, `diagram_label`, `match_pairs`.
  - Science reviewer onboarded.
- **Jan (v1.1):**
  - Class 10 Science live (short answers in self-check mode).
  - Cross-subject Today plan.
  - "30 days to boards" challenge, more maths mock papers.
- **Feb (v1.2):**
  - Class 10 SST live: `map_point`, `order_sequence`, fact-sheet-grounded generation, SST reviewer.
  - Exam-mode revision workouts per subject.

### Phase 5: Rubric grader, English, Class 9 (Apr → Jun 2027)
- **Rubric grader service** (Edge Function): marking-scheme value points, structured output, confidence, and self-check fallback. Validate it against 200 teacher-graded answers per subject before counting it toward mastery.
- Class 10 English live: grammar, comprehension, literature extracts, writing tasks.
- Class 9 Maths + Science live for the new academic session (April).
- Second Class 10 exam window push. Handwritten photo grading pilot.

### Phase 6: Full core for Classes 9–10 (Jul → Sep 2027)
- **Hindi Course A/B:**
  - Devanagari rendering and normalisation, Hindi-capable grading prompts, Hindi reviewer.
  - UI stays English for now; Hindi UI comes later.
- Class 9 SST + English.
- Re-verify all content against the **2027–28 CBSE curriculum** (syllabus diff tool: which concepts were added or removed, and which questions to retire).
- Switch to Season 2 pricing (Full-Class Yearly). **The first "every subject" board season starts.**

### Phase 7: Expand (2028 →)
- Pick the next segment from waitlist and demand data: Classes 11–12 (PCM/PCB streams), Classes 6–8, ICSE, or large state boards.
- The same pipeline applies each time: syllabus YAML + blueprint + reviewer + any new question types.

---

## 11. Metrics and analytics

**Event taxonomy (PostHog):** `onboarding_started`, `diagnostic_completed`, `account_created`, `workout_started`, `workout_completed`, `question_answered` (correct, hints, time), `hint_used`, `solution_viewed`, `concept_mastered`, `paywall_viewed` (trigger), `trial_started`, `purchase_completed`, `parent_report_shared`, `question_reported`, `referral_sent`.

**Funnel targets**
| Metric | Target |
|---|---|
| Install → diagnostic completed | ≥ 60% |
| Diagnostic → account created | ≥ 70% |
| D1 / D7 / D30 retention | ≥ 40% / 20% / 10% |
| Workout completion rate | ≥ 70% |
| Paywall view → trial | ≥ 8% |
| Trial → paid | ≥ 35% |
| Install → paid (season) | 2–4% |
| Question error reports | < 0.5% of questions; < 1 per 1,000 answers |
| Crash-free sessions | ≥ 99.5% |
| Play rating | ≥ 4.5 |

**Learning-outcome proof** (for marketing and our own honesty):
- Track the mastery gain per 10 workouts.
- Compare mock-paper score changes over 4 weeks.
- Survey actual board results in May ("share your result, get a free year of Class 11").

---

## 12. Budget (under ₹50k)
| Item | Cost |
|---|---|
| Google Play developer account | ~₹2,100 one-time |
| Claude API: content generation (6k questions + critique) | ~₹4–6k |
| Claude API: runtime AI (Dec–Mar) | ~₹5–10k |
| Teacher reviewer (about 2,000 reviews) | ~₹12–15k |
| Supabase (free until scale, then $25/mo) | ₹0–8k |
| Domain + landing page | ~₹1k |
| Design assets (icons, Lottie) | ₹0–3k |
| Small ad tests (only if the gates pass) | ₹0–10k |
| **Total (maths launch)** | **~₹30–50k** |

**Each additional subject** (funded from Season 1 revenue, not the initial budget):
- About ₹5–8k in generation API spend.
- About ₹15–25k for a subject reviewer (Science/SST/English/Hindi teacher, part-time, paid per batch).
- Runtime rubric grading: about ₹0.2–0.5 per graded answer (Pro-only, with a daily cap).

**Rule:** start building a new subject only when the maths season shows the gates in §11 are met, or its cost is covered by revenue.

---

## 13. Risks and mitigations
| Risk | Mitigation |
|---|---|
| Wrong answer keys destroy trust | SymPy verification, human sampling, report + auto-hide, nightly calibration flags |
| Solo founder bandwidth, missing the Dec window | Strict v1 scope. Content pipeline runs in parallel (batch jobs overnight). Cut mock-paper analysis depth before cutting quality. |
| Typing maths on a phone is frustrating | Custom keypad, MCQ-heavy early difficulty, and equivalence-based checking |
| Students churn after exams | Class 9 + 11 roadmap, second-exam window, yearly plan pitched as "board + next class" |
| Big competitors (PW, Byju's, Doubtnut, Toppr) | Narrow and deep: the best Class 10 maths *practice* experience, not videos. Misconception-level diagnosis is the edge. |
| Parents won't pay | Parent report, ₹399 seasonal pass anchored against tuition fees, UPI web checkout |
| AI cost creep | The AI is optional polish. Rules and templates as fallback, caching, per-user caps. |
| Compliance for minors | Parental consent flow, no ads, minimal data, deletion inside the app |
| Syllabus changes | Syllabus YAML is the single source of truth. Content versioning, and questions are tagged to concepts so they can be retired. |
| Scope creep from "all subjects" | Architecture is multi-subject from day one, but content rolls out one subject at a time, and each new subject must pass its own quality gates (≥ 99.5% key accuracy, reviewer sampled). A mediocre subject is never shipped just to fill the list. |
| AI grades subjective answers wrongly | Grade against stored value points, return a confidence level, fall back to self-check, give it lower mastery weight, and run a monthly agreement audit against teacher grades |
| AI invents facts in SST/Science | Generation is grounded in our reviewed per-chapter fact sheets. The critique pass checks against them. The reviewer checks facts first. |
| Hindi quality (fonts, input, NLP) | Launch Hindi last with a dedicated Hindi reviewer. Test rendering on low-end devices. Self-check first, rubric grading later. |
| Content volume (about 55k questions for Classes 9–10) | Automated pipeline and batch generation, one part-time reviewer per subject, reuse across Class 9/10 where concepts overlap |
| Copyright of literature texts | Never reproduce full prescribed texts. Use short extracts only where permissible; otherwise write questions about the text. |

---

## 14. Verification plan (when building)
- **Content:**
  - CI runs `validate.py` on every content change.
  - 100% of machine-checkable answers are re-solved by SymPy, and any mismatch blocks the import.
  - Track the sampled human error rate per batch; it must stay under 1%.
- **Mastery engine:**
  - Dart unit tests with simulated students (perfect, random, weak-on-one-concept, forgetting).
  - Assert that the diagnostic identifies the weak concept within 20 questions, that the "mastered" rule needs 2 separate days, and that decay triggers review.
- **Answer checker:** a table-driven test of equivalent forms (fractions, decimals, ±, surds).
- **App:**
  - `flutter analyze` and `flutter test`.
  - An integration test of onboarding → diagnostic → result → workout → complete.
  - Manual tests on a real low-end Android phone (≤ 3 GB RAM), including airplane mode for an offline workout plus sync afterwards.
- **Payments:** RevenueCat sandbox covering purchase, trial, restore, cancel, and expiry. Test entitlement gating on the internal testing track.
- **Real-world:**
  - The founder's relative plus the beta cohort use it daily for 2 weeks.
  - Check that the skill maps match what their teachers say and that mock-paper scores rise.
  - Beta gates (§11) must pass before launch spend.

---

## 15. First concrete step when building starts
1. Scaffold `e:\Mobile apps\study-gym\` (`app/`, `backend/`, `content/`, `docs/`) with the **board/class/subject data model and the question-type registry** in place from the first commit.
2. Hand-write `content/syllabus/cbse/10/maths_standard.yaml` for all 14 chapters (concepts, prerequisites, misconceptions, weights). Also write stub entries for Science, SST, English, and Hindi so the subject switcher and "Notify me" work in alpha.
3. Build `generate.py` + `validate.py` and pilot **Quadratic Equations** (300 questions) to prove content quality before writing app code.

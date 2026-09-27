# the-study-gym

App that focuses on learning and understanding: a mastery system for every core subject in a student's board and class, shaped like a gym app.

> Diagnose → find weak concepts → daily workout → evaluate → adapt → track progress → repeat

The alpha covers **CBSE Class 9 Mathematics** (2026-27 syllabus). A Class 10 Maths sample syllabus is kept alongside. The architecture is subject-agnostic from day one: board, class, subject, chapter and concept are data, and question types are pluggable. The full plan lives in [docs/PLAN.md](docs/PLAN.md).

## Repo layout

| Path | What |
|---|---|
| `app/` | Flutter app (Android first). Not scaffolded yet. |
| `backend/supabase/` | Postgres migrations, seed, Edge Functions |
| `content/syllabus/{board}/{class}/{subject}.yaml` | Curriculum spine: chapters → concepts → prerequisites, misconceptions |
| `content/questions/{board}/{class}/{subject}/` | Reviewed question bank (YAML) |
| `content/pipeline/` | Generate → validate → critique → review → import (Python) |
| `docs/` | Plan, design notes, policies, store copy |

## Content pipeline quickstart

```sh
python -m venv .venv
.venv/Scripts/activate          # Windows; use .venv/bin/activate elsewhere
pip install -r content/pipeline/requirements.txt

python -m content.pipeline.validate          # validate all syllabi and questions
python -m pytest content/pipeline/tests
```

Generating questions (Batch API, needs `ANTHROPIC_API_KEY`):

```sh
python -m content.pipeline.generate plan --subject cbse/9/maths --chapter sequences_progressions --count 3 --run pilot
python -m content.pipeline.generate submit pilot
python -m content.pipeline.generate collect pilot   # re-run until the batch has ended
```

Output lands in `content/pipeline/out/<run>/` (git-ignored): `passed.yaml`, `failed.yaml`, `report.txt`. Questions reach `content/questions/` only after human review.

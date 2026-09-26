# Study Gym

A mastery system for every core subject in a student's board and class, shaped like a gym app:

> Diagnose → find weak concepts → daily workout → evaluate → adapt → track progress → repeat

The alpha covers **CBSE Class 10 Mathematics (Standard)**. The architecture is subject-agnostic from day one: board, class, subject, chapter and concept are data, and question types are pluggable. The full plan lives in [docs/PLAN.md](docs/PLAN.md).

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

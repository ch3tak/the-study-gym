"""One-off script: reads the 62-level Surface Areas & Volumes mission YAML
plus the cbse/9/maths syllabus, and writes a SQL seed file that inserts the
chapter/concepts (not yet present in any seed file) and the 62 questions
(with level/stage/parts) into Supabase.

Run (from repo root): python -m content.pipeline.seed_mission
Writes: backend/supabase/seed/004_surface_area_volume_mission.sql
"""
from __future__ import annotations

import io
import re
import sys
from pathlib import Path

# Import json early to avoid circular import with pipeline.types
import json

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


_FRACTION_RE = re.compile(r"^\s*(-?\d+)\s*/\s*(\d+)\s*$")

# Tolerance applied to an answer converted from fraction form when the YAML
# gives none: the answer is stored to 2 dp (e.g. 256/3 -> "85.33"), and 0.05
# accepts both the 2-dp form and a 1-dp rounding (85.3) of the true value.
FRACTION_TOLERANCE = 0.05


def _numeric_fields(src: dict) -> dict:
    """numericAnswer (+ tolerance) for a numeric question or part.

    The YAML's own `tolerance` (a sibling of `answers`) is carried through
    as a number. A fraction-form answer like "256/3" is converted to a
    2-dp decimal string, since the app's numeric keyboard
    (TextInputType.numberWithOptions(decimal: true)) has no "/" key on iOS
    and none guaranteed on Android — the YAML itself is left unchanged.
    """
    answer = str(src["answers"][0])
    fields: dict = {}
    tolerance = src.get("tolerance")
    match = _FRACTION_RE.match(answer)
    if match:
        value = int(match.group(1)) / int(match.group(2))
        answer = f"{value:.2f}".rstrip("0").rstrip(".")
        if tolerance is None:
            tolerance = FRACTION_TOLERANCE
    fields["numericAnswer"] = answer
    if tolerance is not None:
        fields["tolerance"] = float(tolerance)
    return fields


def _body_for_part(part: dict, question: dict) -> dict:
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
        body.update(_numeric_fields(part))
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
        body.update(_numeric_fields(question))
        body["unit"] = question.get("unit", "none")
    elif qtype == "case_based":
        body["parts"] = [_body_for_part(p, question) for p in question["parts"]]
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

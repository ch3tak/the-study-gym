"""Question-level validation shared by every type, plus bank-wide duplicate checks."""

from __future__ import annotations

import re
from difflib import SequenceMatcher
from pathlib import Path

import yaml

from .issues import Issues
from .syllabus import CONTENT_ROOT, Syllabus
from .types import REGISTRY, Context
from .types.base import check_latex

QUESTIONS_ROOT = CONTENT_ROOT / "questions"

QUESTION_ID = re.compile(r"^q_[a-z0-9_]+$")
SECTIONS = {"A", "B", "C", "D", "E"}
STATUSES = {"draft", "review", "live", "hidden"}
MAX_STEM_CHARS = 600
MAX_CASE_STEM_CHARS = 1500
NEAR_DUPLICATE_RATIO = 0.95

_COMMON_REQUIRED = {"id", "concepts", "difficulty", "type", "marks", "stem", "solution_steps"}
_COMMON_OPTIONAL = {
    "cbse_section", "figure", "hints", "verification", "review", "quality", "status",
    "level", "stage", "purpose", "why_after_previous", "prepares_for",
}
_PART_REQUIRED = {"type", "marks", "stem"}
_PART_OPTIONAL = {"id", "concepts", "difficulty", "hints", "solution_steps", "verification", "figure"}
_VERIFICATION_KEYS = {"sympy", "option_values", "tolerance", "status", "note"}
STAGES = {"FOUNDATION", "GUIDED_PRACTICE", "SKILL_BUILDING", "APPLICATION", "MASTERY"}


def validate_question(q: dict, syl: Syllabus, issues: Issues, *, where: str,
                      is_part: bool = False, parent_concepts: list[str] | None = None) -> None:
    qtype = REGISTRY.get(q.get("type"))
    if qtype is None:
        issues.error(where, f"unknown type '{q.get('type')}'")
        return

    required = (_PART_REQUIRED if is_part else _COMMON_REQUIRED) | qtype.required
    optional = (_PART_OPTIONAL if is_part else _COMMON_OPTIONAL) | qtype.optional
    if qtype.id == "case_based":
        required = required - {"solution_steps"}  # each part carries its own solution
    for key in sorted(required - q.keys()):
        issues.error(where, f"missing field '{key}'")
    for key in sorted(q.keys() - required - optional):
        issues.error(where, f"unknown field '{key}' for type '{qtype.id}'")

    if not is_part and not QUESTION_ID.match(str(q.get("id", ""))):
        issues.error(where, "id must look like 'q_<lower_snake>'")

    concepts = q.get("concepts") or parent_concepts or []
    if not is_part and not concepts:
        issues.error(where, "concepts: need at least one concept id")
    for cid in concepts:
        concept = syl.concept(cid)
        if concept is None:
            issues.error(where, f"concepts: unknown concept '{cid}'")
        elif concept.retired:
            issues.error(where, f"concepts: '{cid}' is retired")
        elif qtype.id not in concept.question_types and not is_part:
            issues.error(where, f"type '{qtype.id}' is not allowed for concept '{cid}'")

    if not is_part or "difficulty" in q:
        if q.get("difficulty") not in (1, 2, 3):
            issues.error(where, "difficulty: must be 1, 2 or 3")
    marks = q.get("marks")
    if not isinstance(marks, (int, float)) or marks <= 0:
        issues.error(where, "marks: must be a positive number")
    if "cbse_section" in q and q["cbse_section"] not in SECTIONS:
        issues.error(where, f"cbse_section: must be one of {sorted(SECTIONS)}")
    if "status" in q and q["status"] not in STATUSES:
        issues.error(where, f"status: must be one of {sorted(STATUSES)}")
    if "level" in q and (not isinstance(q["level"], int) or q["level"] < 1):
        issues.error(where, "level: must be a positive integer")
    if "stage" in q and q["stage"] not in STAGES:
        issues.error(where, f"stage: must be one of {sorted(STAGES)}")
    if "purpose" in q and (not isinstance(q["purpose"], list) or not q["purpose"]):
        issues.error(where, "purpose: must be a non-empty list of tags")

    ctx = Context(where=where, issues=issues, syllabus=syl, concepts=list(concepts))
    stem = q.get("stem")
    check_latex(stem, "stem", ctx)
    limit = MAX_CASE_STEM_CHARS if qtype.id == "case_based" else MAX_STEM_CHARS
    if isinstance(stem, str) and len(stem) > limit:
        ctx.error(f"stem: longer than {limit} characters")

    hints = q.get("hints") or []
    if len(hints) > 2:
        ctx.error("hints: at most 2 (the full solution is the third rung)")
    for i, h in enumerate(hints):
        check_latex(h, f"hints[{i}]", ctx)

    steps = q.get("solution_steps")
    if qtype.id != "case_based" and (not is_part or steps is not None):
        if not isinstance(steps, list) or not steps:
            ctx.error("solution_steps: need at least one step")
        else:
            for i, s in enumerate(steps):
                check_latex(s, f"solution_steps[{i}]", ctx)

    verification = q.get("verification") or {}
    if not isinstance(verification, dict):
        ctx.error("verification: must be a mapping")
    else:
        for key in sorted(verification.keys() - _VERIFICATION_KEYS):
            ctx.error(f"verification: unknown field '{key}'")

    qtype.validate(q, ctx)


def load_file(path: Path, issues: Issues) -> list[dict]:
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        issues.error(str(path), f"YAML parse error: {exc}")
        return []
    if not isinstance(data, dict) or not isinstance(data.get("questions"), list):
        issues.error(str(path), "file must be a mapping with a 'questions' list")
        return []
    return data["questions"]


def validate_bank(questions: list[tuple[str, dict]], syl: Syllabus, issues: Issues) -> None:
    """Validate each question, then check ids and stems across the whole set."""
    seen_ids: dict[str, str] = {}
    by_concept: dict[str, list[tuple[str, str]]] = {}
    exact: dict[str, str] = {}

    for where, q in questions:
        if not isinstance(q, dict):
            issues.error(where, "question must be a mapping")
            continue
        qid = str(q.get("id", "?"))
        qwhere = f"{where}#{qid}"
        if qid in seen_ids:
            issues.error(qwhere, f"duplicate id (also in {seen_ids[qid]})")
        seen_ids[qid] = where
        validate_question(q, syl, issues, where=qwhere)

        key = _normalise(q)
        if key in exact:
            issues.error(qwhere, f"exact duplicate of {exact[key]}")
            continue
        exact[key] = qid
        primary = (q.get("concepts") or ["?"])[0]
        for other_id, other_key in by_concept.get(primary, []):
            if SequenceMatcher(None, key, other_key).ratio() >= NEAR_DUPLICATE_RATIO:
                issues.warn(qwhere, f"near-duplicate of {other_id}")
                break
        by_concept.setdefault(primary, []).append((qid, key))

    levels = [(where, q["level"]) for where, q in questions if isinstance(q, dict) and "level" in q]
    if levels:
        seen_levels: dict[int, str] = {}
        for where, level in levels:
            if level in seen_levels:
                issues.error(where, f"level {level} duplicated (also used by {seen_levels[level]})")
            seen_levels[level] = where
        expected = set(range(1, max(seen_levels) + 1))
        missing = sorted(expected - set(seen_levels))
        if missing:
            issues.warn(questions[0][0], f"level sequence has gaps: missing {missing}")


def _normalise(q: dict) -> str:
    parts = [str(q.get("stem", ""))] + [str(o) for o in q.get("options") or []]
    parts += [str(p.get("stem", "")) for p in q.get("parts") or [] if isinstance(p, dict)]
    return " ".join(" ".join(parts).lower().split())

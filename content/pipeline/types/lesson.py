"""Theory lesson validator. Not a question type — lessons aren't part of
the question-type REGISTRY (content/pipeline/types/__init__.py) and never
go through validate_bank. This is a standalone check called by
validate.py's theory-file pass and by seed_theory.py before writing SQL.
"""

from __future__ import annotations

from .base import Context, check_latex
from ..issues import Issues
from ..syllabus import Syllabus

MAX_FIELD_CHARS = 400
ID_PREFIX = "t_"

_REQUIRED_FIELDS = {"id", "concept_id", "title", "body", "hook_kind", "hook", "sort_order"}
_OPTIONAL_FIELDS = {"try_it"}
_VALID_HOOK_KINDS = {"historical", "real_world"}


def _check_text(value: object, label: str, where: str, issues: Issues) -> bool:
    """Non-empty string with no leading/trailing whitespace. Returns False if
    the value isn't usable text, so callers can skip further checks."""
    if not isinstance(value, str) or not value.strip():
        issues.error(where, f"{label}: must be non-empty text")
        return False
    if value != value.strip():
        issues.error(where, f"{label}: has leading/trailing whitespace (use `>-`, not `>`, for folded YAML text)")
    return True


def validate_lesson(lesson: dict, syllabus: Syllabus, issues: Issues, where: str) -> None:
    missing = _REQUIRED_FIELDS - lesson.keys()
    for key in sorted(missing):
        issues.error(where, f"missing field '{key}'")
    unknown = lesson.keys() - _REQUIRED_FIELDS - _OPTIONAL_FIELDS
    for key in sorted(unknown):
        issues.error(where, f"unknown field '{key}'")
    if missing:
        return

    lesson_id = lesson["id"]
    if not isinstance(lesson_id, str) or not lesson_id.startswith(ID_PREFIX):
        issues.error(where, f"id: must start with '{ID_PREFIX}', got '{lesson_id}'")

    sort_order = lesson["sort_order"]
    if not isinstance(sort_order, int) or isinstance(sort_order, bool):
        issues.error(where, f"sort_order: must be an integer, got {sort_order!r}")

    concept_id = lesson["concept_id"]
    if concept_id not in syllabus.concepts:
        issues.error(where, f"unknown concept '{concept_id}'")

    hook_kind = lesson["hook_kind"]
    if hook_kind not in _VALID_HOOK_KINDS:
        issues.error(where, f"hook_kind: must be one of {sorted(_VALID_HOOK_KINDS)}, got '{hook_kind}'")

    # Same structural math checks as question text ($ pairs, braces, \frac).
    ctx = Context(where, issues, syllabus, [concept_id])
    for field_name in ("body", "hook", "try_it"):
        value = lesson.get(field_name)
        if value is None and field_name in _OPTIONAL_FIELDS:
            continue
        if not _check_text(value, field_name, where, issues):
            continue
        if len(value) > MAX_FIELD_CHARS:
            issues.error(where, f"{field_name}: longer than {MAX_FIELD_CHARS} characters")
        check_latex(value, field_name, ctx)

    _check_text(lesson["title"], "title", where, issues)

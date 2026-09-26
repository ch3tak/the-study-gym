from __future__ import annotations

from .base import REGISTRY, Context, QuestionType, register


@register
class CaseBased(QuestionType):
    """A case (the stem) followed by sub-questions. Each part is a full question
    of another type; its grading delegates to that type."""

    id = "case_based"
    required = frozenset({"parts"})

    def validate(self, q: dict, ctx: Context) -> None:
        # Imported here to avoid a cycle: questions.py imports the registry.
        from ..questions import validate_question

        parts = q.get("parts")
        if not isinstance(parts, list) or not 2 <= len(parts) <= 5:
            ctx.error("parts: need 2-5 sub-questions")
            return
        total = 0.0
        for i, part in enumerate(parts):
            if not isinstance(part, dict):
                ctx.error(f"parts[{i}]: must be a mapping")
                continue
            if part.get("type") == self.id:
                ctx.error(f"parts[{i}]: case_based parts cannot nest")
                continue
            if part.get("type") not in REGISTRY:
                ctx.error(f"parts[{i}]: unknown type '{part.get('type')}'")
                continue
            validate_question(part, ctx.syllabus, ctx.issues, where=f"{ctx.where}/parts[{i}]", is_part=True)
            total += float(part.get("marks", 0))
        if abs(total - float(q.get("marks", 0))) > 1e-9:
            ctx.error(f"marks: parts sum to {total}, question says {q.get('marks')}")

"""Question-type plug-in contract.

Each type declares the fields it adds to a question and a `validate()` that
checks them. The app mirrors this registry with render/input/grade per type,
so type ids and field names here are the shared contract.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import ClassVar

from ..issues import Issues
from ..syllabus import Syllabus

# Misconceptions any subject may reference, for distractors that come from
# slips rather than a concept-specific misunderstanding.
GENERIC_MISCONCEPTIONS = {
    "generic.arithmetic_slip",
    "generic.misread_question",
    "generic.unit_error",
    "generic.guess",
}


@dataclass
class Context:
    where: str
    issues: Issues
    syllabus: Syllabus
    concepts: list[str]

    def error(self, message: str) -> None:
        self.issues.error(self.where, message)

    def warn(self, message: str) -> None:
        self.issues.warn(self.where, message)

    def check_misconception(self, mid: str, label: str) -> None:
        if mid in GENERIC_MISCONCEPTIONS:
            return
        owner = self.syllabus.misconceptions.get(mid)
        if owner is None:
            self.error(f"{label}: unknown misconception '{mid}'")
        elif owner not in self.concepts:
            self.warn(f"{label}: misconception '{mid}' belongs to '{owner}', not to this question's concepts")


class QuestionType:
    id: ClassVar[str]
    required: ClassVar[frozenset[str]] = frozenset()
    optional: ClassVar[frozenset[str]] = frozenset()
    # Whether a machine check of the answer is mandatory (vs. routed to human review).
    requires_machine_verification: ClassVar[bool] = False

    def validate(self, q: dict, ctx: Context) -> None:
        raise NotImplementedError


REGISTRY: dict[str, QuestionType] = {}


def register(cls: type[QuestionType]) -> type[QuestionType]:
    if cls.id in REGISTRY:
        raise ValueError(f"question type '{cls.id}' registered twice")
    REGISTRY[cls.id] = cls()
    return cls


_DOLLAR = re.compile(r"(?<!\\)\$")


def check_latex(text: str, label: str, ctx: Context) -> None:
    """Cheap structural checks; full KaTeX rendering is checked in the review app."""
    if not isinstance(text, str) or not text.strip():
        ctx.error(f"{label}: must be non-empty text")
        return
    if len(_DOLLAR.findall(text)) % 2:
        ctx.error(f"{label}: unbalanced $ math delimiters")
    depth = 0
    for i, ch in enumerate(text):
        if ch == "{" and (i == 0 or text[i - 1] != "\\"):
            depth += 1
        elif ch == "}" and (i == 0 or text[i - 1] != "\\"):
            depth -= 1
            if depth < 0:
                break
    if depth != 0:
        ctx.error(f"{label}: unbalanced braces")
    if r"\frac" in text and not re.search(r"\\frac\s*\{[^{}]*(\{[^{}]*\}[^{}]*)*\}\s*\{", text):
        ctx.error(rf"{label}: \frac needs two brace groups")

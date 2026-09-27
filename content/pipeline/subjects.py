"""Per-subject generation profiles: the prompt rules and golden examples for each
syllabus. Adding a subject = a syllabus YAML + golden questions + a profile here."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .syllabus import CONTENT_ROOT

QUESTIONS = CONTENT_ROOT / "questions"


@dataclass(frozen=True)
class SubjectProfile:
    key: str                      # "board/class/subject"
    title: str                    # used in the system prompt
    golden: Path                  # few-shot examples
    rules: str                    # subject-specific prompt rules
    generatable: tuple[str, ...]  # types the generator may produce for this subject


_MATHS_VERIFY = (
    "- Work in degrees via pi: sin(pi/6), not sin(30).\n"
    "- \"unit\" is \"\" unless the answer is a measurement (then e.g. \"cm^2\")."
)

PROFILES = {
    p.key: p
    for p in [
        SubjectProfile(
            key="cbse/9/maths",
            title="Indian CBSE Class 9 Mathematics, 2026-27 syllabus (new NCF-SE 2023 curriculum and NCERT textbook)",
            golden=QUESTIONS / "cbse/9/maths/golden.yaml",
            rules=(
                "- Stay inside the 2026-27 Class 9 chapter list. It includes sequences and progressions (AP, GP, "
                "recursive rules, Tower of Hanoi), slope-intercept form, Heron's and Brahmagupta's formulas, pyramids, "
                "stacked bar graphs, weighted averages and empirical probability. It does NOT include zeroes of "
                "polynomials, the remainder or factor theorem, trigonometry, or the general sum of an AP (only the sum "
                "of the first n natural numbers).\n"
                "- Contributions of Indian mathematicians (Baudhayana, Aryabhata, Brahmagupta, Virahanka) are welcome "
                "where they fit the concept; never invent historical facts.\n"
                + _MATHS_VERIFY
            ),
            generatable=("mcq", "numeric", "expression", "assertion_reason"),
        ),
        SubjectProfile(
            key="cbse/10/maths_standard",
            title="Indian CBSE Class 10 Mathematics (Standard), 2026-27 syllabus",
            golden=QUESTIONS / "cbse/10/maths_standard/quadratic_equations.yaml",
            rules=(
                "- Stay inside the rationalised CBSE syllabus. Do not use topics CBSE removed (Euclid's division lemma, "
                "polynomial division algorithm, cross-multiplication, completing the square, frustums, ogives, area "
                "of a triangle by coordinates, complementary-angle identities).\n"
                + _MATHS_VERIFY
            ),
            generatable=("mcq", "numeric", "expression", "assertion_reason"),
        ),
    ]
}


def get(key: str) -> SubjectProfile:
    if key not in PROFILES:
        raise KeyError(f"no generation profile for '{key}'; add one in content/pipeline/subjects.py")
    return PROFILES[key]

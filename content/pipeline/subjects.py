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
            key="cbse/9/science",
            title="Indian CBSE Class 9 Science, 2026-27 syllabus (new NCF-SE 2023 curriculum and NCERT textbook)",
            golden=QUESTIONS / "cbse/9/science/golden.yaml",
            rules=(
                "- Stay inside the 2026-27 Class 9 chapter list: Cell, Tissues, Reproduction, Diversity, Mixtures and "
                "their separation, Structure of an Atom, Atoms and Molecules, Motion, Force and Laws of Motion, Work, "
                "Energy and Simple Machines, Sound, and Earth as a System. Gravitation, momentum and conservation of "
                "momentum are NOT in this syllabus.\n"
                "- Every fact must match the NCERT Class 9 textbook. If you are not certain a fact is correct and in "
                "the syllabus, don't use it.\n"
                "- Use SI units. Take g = 10 m/s^2 and state it in the question when needed. Use atomic masses "
                "rounded to whole numbers (H 1, C 12, N 14, O 16, Na 23, Cl 35.5, Ca 40).\n"
                "- numeric: \"unit\" is always set, e.g. \"m/s^2\", \"J\", \"%\", or \"none\" for a pure number.\n"
                "- Numerical questions: verification_sympy computes the answer from the given values with the formula. "
                "Factual or conceptual questions: set verification_sympy (and option_values) to \"\"; a teacher checks them."
            ),
            generatable=("mcq", "numeric", "assertion_reason"),
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

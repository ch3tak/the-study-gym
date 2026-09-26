from __future__ import annotations

from .. import sympy_check
from .base import Context, QuestionType, check_latex, register

MAX_OPTION_CHARS = 160


@register
class MCQ(QuestionType):
    """Single-correct multiple choice. Every wrong option maps to a misconception."""

    id = "mcq"
    required = frozenset({"options", "answer", "distractors"})

    def validate(self, q: dict, ctx: Context) -> None:
        options = q.get("options")
        if not isinstance(options, list) or len(options) != 4:
            ctx.error("options: need exactly 4 options")
            return
        for i, opt in enumerate(options):
            check_latex(opt, f"options[{i}]", ctx)
            if isinstance(opt, str) and len(opt) > MAX_OPTION_CHARS:
                ctx.error(f"options[{i}]: longer than {MAX_OPTION_CHARS} characters")
        normalised = [" ".join(str(o).split()).lower() for o in options]
        if len(set(normalised)) != len(normalised):
            ctx.error("options: duplicate options")

        answer = q.get("answer")
        if not isinstance(answer, int) or not 0 <= answer < len(options):
            ctx.error("answer: must be the index (0-3) of the correct option")
            return

        distractors = q.get("distractors") or {}
        wrong = {i for i in range(len(options)) if i != answer}
        mapped = {int(k) for k in distractors}
        if answer in mapped:
            ctx.error("distractors: the correct option must not be mapped to a misconception")
        for i in sorted(wrong - mapped):
            ctx.error(f"distractors: option {i} has no misconception")
        for k, mid in distractors.items():
            ctx.check_misconception(mid, f"distractors[{k}]")

        verify_option_values(q, ctx, answer)


def verify_option_values(q: dict, ctx: Context, answer: int) -> None:
    """If the question supplies SymPy values for its options, recompute and check them."""
    verification = q.get("verification") or {}
    expr = verification.get("sympy")
    values = verification.get("option_values")
    if not expr:
        ctx.warn("no machine verification: route to human review")
        return
    if not isinstance(values, list) or len(values) != len(q["options"]):
        ctx.error("verification.option_values: need one SymPy value per option")
        return
    try:
        expected = sympy_check.as_values(sympy_check.evaluate(expr))
        option_vals = [sympy_check.as_values(sympy_check.evaluate(v)) for v in values]
    except Exception as exc:  # noqa: BLE001 - any parse/eval failure is a content error
        ctx.error(f"verification: {exc}")
        return
    tol = float(verification.get("tolerance", 0))
    matches = [i for i, vals in enumerate(option_vals) if sympy_check.same_values(vals, expected, tol)]
    if matches != [answer]:
        if not matches:
            ctx.error(f"verification: no option equals the recomputed answer {expected}")
        elif answer not in matches:
            ctx.error(f"verification: recomputed answer matches option {matches}, not the keyed answer {answer}")
        else:
            ctx.error(f"verification: options {matches} all equal the answer")

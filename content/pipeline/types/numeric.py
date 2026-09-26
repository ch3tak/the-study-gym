from __future__ import annotations

from .. import sympy_check
from .base import Context, QuestionType, register


@register
class Numeric(QuestionType):
    """One or more numeric values typed on the keypad.

    `answers` lists every value the student must enter (usually one; two for
    "k = ±6"). `wrong_answers` maps predictable wrong values to misconceptions.
    """

    id = "numeric"
    required = frozenset({"answers"})
    optional = frozenset({"tolerance", "unit", "wrong_answers"})
    requires_machine_verification = True

    def validate(self, q: dict, ctx: Context) -> None:
        answers = q.get("answers")
        if not isinstance(answers, list) or not answers:
            ctx.error("answers: need a non-empty list")
            return
        try:
            values = [sympy_check.evaluate(str(a)) for a in answers]
        except Exception as exc:  # noqa: BLE001
            ctx.error(f"answers: {exc}")
            return
        for a, v in zip(answers, values):
            if v.free_symbols:
                ctx.error(f"answers: '{a}' is not a number")
        tol = float(q.get("tolerance", 0))
        if tol < 0:
            ctx.error("tolerance: must be >= 0")
        if ctx.syllabus.numeric_requires_unit and not str(q.get("unit", "")).strip():
            ctx.error("unit: required in this subject (use \"none\" for a dimensionless answer)")

        for wrong, mid in (q.get("wrong_answers") or {}).items():
            ctx.check_misconception(mid, f"wrong_answers[{wrong}]")
            try:
                w = sympy_check.evaluate(str(wrong))
            except Exception as exc:  # noqa: BLE001
                ctx.error(f"wrong_answers: {exc}")
                continue
            if any(sympy_check.equivalent(w, v, tol) for v in values):
                ctx.error(f"wrong_answers: '{wrong}' equals a correct answer")

        verify_values(q, ctx, values, tol)


def verify_values(q: dict, ctx: Context, values: list, tol: float) -> None:
    expr = (q.get("verification") or {}).get("sympy")
    if not expr:
        ctx.error("verification.sympy: required for this type")
        return
    try:
        recomputed = sympy_check.as_values(sympy_check.evaluate(expr))
    except Exception as exc:  # noqa: BLE001
        ctx.error(f"verification: {exc}")
        return
    if not sympy_check.same_values(recomputed, values, tol):
        ctx.error(f"verification: recomputed {recomputed} but keyed answers are {values}")

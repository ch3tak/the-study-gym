from __future__ import annotations

from .. import sympy_check
from .base import Context, QuestionType, register

FORMS = {"any", "factored", "expanded"}


@register
class Expression(QuestionType):
    """An algebraic expression, graded by equivalence (and optionally by form)."""

    id = "expression"
    required = frozenset({"answer", "variables"})
    optional = frozenset({"form", "wrong_answers"})
    requires_machine_verification = True

    def validate(self, q: dict, ctx: Context) -> None:
        variables = q.get("variables")
        if not isinstance(variables, list) or not variables:
            ctx.error("variables: need a non-empty list")
            return
        if q.get("form", "any") not in FORMS:
            ctx.error(f"form: must be one of {sorted(FORMS)}")
        try:
            answer = sympy_check.evaluate(str(q.get("answer")))
        except Exception as exc:  # noqa: BLE001
            ctx.error(f"answer: {exc}")
            return
        extra = {str(s) for s in answer.free_symbols} - set(variables)
        if extra:
            ctx.error(f"answer: uses symbols not in variables: {sorted(extra)}")

        for wrong, mid in (q.get("wrong_answers") or {}).items():
            ctx.check_misconception(mid, f"wrong_answers[{wrong}]")
            try:
                if sympy_check.equivalent(sympy_check.evaluate(str(wrong)), answer):
                    ctx.error(f"wrong_answers: '{wrong}' is equivalent to the answer")
            except Exception as exc:  # noqa: BLE001
                ctx.error(f"wrong_answers: {exc}")

        expr = (q.get("verification") or {}).get("sympy")
        if not expr:
            ctx.error("verification.sympy: required for this type")
            return
        try:
            recomputed = sympy_check.evaluate(expr)
        except Exception as exc:  # noqa: BLE001
            ctx.error(f"verification: {exc}")
            return
        if not sympy_check.equivalent(recomputed, answer):
            ctx.error(f"verification: recomputed {recomputed}, not equivalent to answer {answer}")

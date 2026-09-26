from __future__ import annotations

from .base import Context, QuestionType, check_latex, register

# The four standard CBSE options, rendered by the app; content stores only the key.
OPTIONS = {
    "a": "Both A and R are true, and R is the correct explanation of A.",
    "b": "Both A and R are true, but R is not the correct explanation of A.",
    "c": "A is true, but R is false.",
    "d": "A is false, but R is true.",
}


@register
class AssertionReason(QuestionType):
    id = "assertion_reason"
    required = frozenset({"assertion", "reason", "answer"})
    optional = frozenset({"distractors"})

    def validate(self, q: dict, ctx: Context) -> None:
        check_latex(q.get("assertion"), "assertion", ctx)
        check_latex(q.get("reason"), "reason", ctx)
        answer = q.get("answer")
        if answer not in OPTIONS:
            ctx.error(f"answer: must be one of {sorted(OPTIONS)}")
            return
        for k, mid in (q.get("distractors") or {}).items():
            if k not in OPTIONS:
                ctx.error(f"distractors: unknown option '{k}'")
            elif k == answer:
                ctx.error("distractors: the correct option must not be mapped to a misconception")
            ctx.check_misconception(mid, f"distractors[{k}]")
        if not (q.get("verification") or {}).get("sympy"):
            ctx.warn("no machine verification: route to human review")

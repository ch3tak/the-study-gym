"""Evaluate verification expressions and compare answers by mathematical equivalence.

Verification strings come from a language model, so they are parsed with a
whitelisted namespace and no builtins, and anything resembling attribute access
or dunder names is rejected before evaluation.
"""

from __future__ import annotations

import re

import sympy as sp
from sympy.parsing.sympy_parser import (
    convert_xor,
    implicit_multiplication_application,
    parse_expr,
    standard_transformations,
)

_ALLOWED = {
    name: getattr(sp, name)
    for name in [
        "Abs", "Eq", "Float", "Integer", "Rational", "S", "Symbol",
        "acos", "asin", "atan", "binomial", "ceiling", "cos", "cot", "csc",
        "divisors", "expand", "factor", "factorint", "floor", "gcd", "isprime",
        "lcm", "log", "nsimplify", "oo", "pi", "primefactors", "rad", "sec",
        "simplify", "sin", "solve", "sqrt", "summation", "tan",
    ]
}
_ALLOWED["E"] = sp.E


def positive_roots(expr, var):
    """Real positive roots, ascending. For word problems where lengths, ages or counts can't be negative."""
    return sorted(r for r in sp.solve(expr, var) if r.is_real and r > 0)


_ALLOWED["positive_roots"] = positive_roots

_FORBIDDEN = re.compile(r"__|\bimport\b|\blambda\b|\bexec\b|\beval\b|\bopen\b|\.\s*[A-Za-z_]")
_TRANSFORMS = standard_transformations + (convert_xor,)
_TRANSFORMS_IMPLICIT = _TRANSFORMS + (implicit_multiplication_application,)


class UnsafeExpression(ValueError):
    pass


def evaluate(expr: str, *, implicit_multiplication: bool = False):
    """Parse and evaluate a SymPy expression string. Unknown names become symbols."""
    if not isinstance(expr, str) or not expr.strip():
        raise ValueError("expression must be a non-empty string")
    if len(expr) > 500:
        raise UnsafeExpression("expression too long")
    if _FORBIDDEN.search(expr):
        raise UnsafeExpression(f"disallowed syntax in {expr!r}")
    global_dict = {"__builtins__": {}, **_ALLOWED}
    transforms = _TRANSFORMS_IMPLICIT if implicit_multiplication else _TRANSFORMS
    return parse_expr(expr, local_dict={}, global_dict=global_dict, transformations=transforms)


def as_values(obj) -> list:
    """Flatten a result (single value, list, tuple, set, FiniteSet) into a list of expressions."""
    if isinstance(obj, (list, tuple, set, frozenset)):
        return [sp.sympify(v) for v in obj]
    if isinstance(obj, sp.FiniteSet):
        return list(obj.args)
    if isinstance(obj, dict):
        raise ValueError("verification returned a dict; use solve(expr, var) for a list of roots")
    if isinstance(obj, (bool, sp.logic.boolalg.BooleanAtom)) or isinstance(obj, sp.Rel):
        raise ValueError("verification returned a boolean/relation, not a value")
    return [sp.sympify(obj)]


def equivalent(a, b, tolerance: float = 0.0) -> bool:
    """True if a and b are mathematically equal (within an absolute tolerance)."""
    a, b = sp.sympify(a), sp.sympify(b)
    diff = sp.simplify(a - b)
    if diff == 0:
        return True
    if diff.free_symbols:
        return False
    try:
        return abs(complex(sp.N(diff))) <= tolerance + 1e-9
    except (TypeError, ValueError):
        return False


def same_values(xs: list, ys: list, tolerance: float = 0.0) -> bool:
    """Multiset equality under `equivalent`."""
    if len(xs) != len(ys):
        return False
    remaining = list(ys)
    for x in xs:
        for i, y in enumerate(remaining):
            if equivalent(x, y, tolerance):
                del remaining[i]
                break
        else:
            return False
    return True

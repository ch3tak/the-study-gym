import pytest

from content.pipeline import sympy_check as sc


@pytest.mark.parametrize("a,b", [
    ("1/2", "0.5"),
    ("2/4", "1/2"),
    ("sqrt(8)", "2*sqrt(2)"),
    ("sqrt(3)/3", "1/sqrt(3)"),
    ("sin(pi/6)", "1/2"),
    ("(x + 1)**2", "x**2 + 2*x + 1"),
    ("22/7*7**2", "154"),
])
def test_equivalent_forms(a, b):
    assert sc.equivalent(sc.evaluate(a), sc.evaluate(b))


@pytest.mark.parametrize("a,b", [("1/3", "0.33"), ("x + 1", "x - 1"), ("sqrt(2)", "1.41")])
def test_not_equivalent(a, b):
    assert not sc.equivalent(sc.evaluate(a), sc.evaluate(b))


def test_tolerance():
    assert sc.equivalent(sc.evaluate("1/3"), sc.evaluate("0.33"), tolerance=0.01)


def test_plus_minus_sets():
    roots = sc.as_values(sc.evaluate("solve(k**2 - 36, k)"))
    assert sc.same_values(roots, sc.as_values(sc.evaluate("[6, -6]")))
    assert not sc.same_values(roots, sc.as_values(sc.evaluate("6")))


def test_positive_roots():
    assert sc.evaluate("positive_roots(x**2 + 3*x - 180, x)") == [12]


@pytest.mark.parametrize("expr", [
    "__import__('os').system('echo hi')",
    "x.__class__",
    "Symbol('x').func",
    "open('secrets.txt')",
    "lambda: 1",
])
def test_rejects_unsafe_expressions(expr):
    with pytest.raises(Exception):
        sc.evaluate(expr)


def test_no_builtins():
    with pytest.raises(Exception):
        sc.evaluate("len([1, 2])")

"""The validator's job is to stop wrong answer keys. These tests break the
golden questions in specific ways and check each break is caught."""

import copy

import pytest

from content.pipeline.issues import Issues
from content.pipeline.questions import QUESTIONS_ROOT, load_file, validate_bank
from content.pipeline.syllabus import load, syllabus_path
from content.pipeline.types import REGISTRY

GOLDEN = QUESTIONS_ROOT / "cbse" / "10" / "maths_standard" / "quadratic_equations.yaml"


@pytest.fixture(scope="module")
def syllabus():
    issues = Issues()
    syl = load(syllabus_path("cbse", 10, "maths_standard"), issues, set(REGISTRY))
    assert issues.errors == []
    return syl


@pytest.fixture
def golden():
    issues = Issues()
    qs = {q["id"]: q for q in load_file(GOLDEN, issues)}
    assert issues.errors == []
    return copy.deepcopy(qs)


def run(syllabus, *questions) -> Issues:
    issues = Issues()
    validate_bank([("test", q) for q in questions], syllabus, issues)
    return issues


def messages(issues: Issues) -> str:
    return "\n".join(i.message for i in issues.errors)


def test_golden_file_is_clean(syllabus, golden):
    assert run(syllabus, *golden.values()).errors == []


def test_mcq_wrong_key_is_caught(syllabus, golden):
    q = golden["q_quad_equal_roots_k_0001"]
    q["answer"] = 1
    q["distractors"] = {0: "quad.disc.missed_negative_root", 2: "quad.disc.forgot_4ac_factor", 3: "quad.disc.confused_c_with_k"}
    assert "not the keyed answer" in messages(run(syllabus, q))


def test_mcq_distractor_equal_to_answer_is_caught(syllabus, golden):
    q = golden["q_quad_equal_roots_k_0001"]
    q["verification"]["option_values"][3] = "[6, -6]"
    assert "all equal the answer" in messages(run(syllabus, q))


def test_mcq_unmapped_distractor_is_caught(syllabus, golden):
    q = golden["q_quad_equal_roots_k_0001"]
    del q["distractors"][2]
    assert "option 2 has no misconception" in messages(run(syllabus, q))


def test_mcq_unknown_misconception_is_caught(syllabus, golden):
    q = golden["q_quad_equal_roots_k_0001"]
    q["distractors"][3] = "quad.made_up"
    assert "unknown misconception 'quad.made_up'" in messages(run(syllabus, q))


def test_numeric_wrong_key_is_caught(syllabus, golden):
    q = golden["q_quad_factorise_solve_0001"]
    q["answers"] = ["3", "-1/2"]
    assert "recomputed" in messages(run(syllabus, q))


def test_numeric_missing_root_is_caught(syllabus, golden):
    q = golden["q_quad_factorise_solve_0001"]
    q["answers"] = ["3"]
    assert "recomputed" in messages(run(syllabus, q))


def test_numeric_wrong_answer_equal_to_answer_is_caught(syllabus, golden):
    q = golden["q_quad_discriminant_0001"]
    q["wrong_answers"]["1.0"] = "quad.disc.sign_c"
    assert "equals a correct answer" in messages(run(syllabus, q))


def test_numeric_requires_verification(syllabus, golden):
    q = golden["q_quad_discriminant_0001"]
    del q["verification"]
    assert "verification.sympy: required" in messages(run(syllabus, q))


def test_expression_wrong_key_is_caught(syllabus, golden):
    q = golden["q_quad_factorise_expr_0001"]
    q["answer"] = "(2*x + 1)*(3*x - 2)"
    q["wrong_answers"] = {}
    assert "not equivalent" in messages(run(syllabus, q))


def test_unknown_concept_is_caught(syllabus, golden):
    q = golden["q_quad_discriminant_0001"]
    q["concepts"] = ["quad.nope"]
    assert "unknown concept 'quad.nope'" in messages(run(syllabus, q))


def test_type_not_allowed_for_concept_is_caught(syllabus, golden):
    q = golden["q_quad_nature_ar_0001"]
    q["concepts"] = ["quad.word_numbers"]  # allows numeric, case_based, mcq only
    assert "not allowed for concept" in messages(run(syllabus, q))


def test_case_part_marks_must_add_up(syllabus, golden):
    q = golden["q_quad_garden_case_0001"]
    q["marks"] = 5
    assert "parts sum to 4" in messages(run(syllabus, q))


def test_case_part_wrong_key_is_caught(syllabus, golden):
    q = golden["q_quad_garden_case_0001"]
    q["parts"][2]["answers"] = ["27"]
    q["parts"][2]["wrong_answers"] = {}
    assert "recomputed" in messages(run(syllabus, q))


def test_duplicate_ids_and_stems_are_caught(syllabus, golden):
    q = golden["q_quad_discriminant_0001"]
    issues = run(syllabus, q, copy.deepcopy(q))
    assert "duplicate id" in messages(issues)
    assert "exact duplicate" in messages(issues)


def test_unbalanced_latex_is_caught(syllabus, golden):
    q = golden["q_quad_discriminant_0001"]
    q["stem"] = "Find the discriminant of $3x^2 - 5x + 2 = 0."
    assert "unbalanced $" in messages(run(syllabus, q))


def test_class9_golden_files_are_clean():
    for subject in ("maths", "science"):
        issues = Issues()
        syl = load(syllabus_path("cbse", 9, subject), issues, set(REGISTRY))
        qs = load_file(QUESTIONS_ROOT / "cbse" / "9" / subject / "golden.yaml", issues)
        validate_bank([("golden", q) for q in qs], syl, issues)
        assert issues.errors == [], subject


def test_science_numeric_without_unit_is_caught():
    issues = Issues()
    syl = load(syllabus_path("cbse", 9, "science"), issues, set(REGISTRY))
    qs = {q["id"]: q for q in load_file(QUESTIONS_ROOT / "cbse" / "9" / "science" / "golden.yaml", issues)}
    q = copy.deepcopy(qs["q_c9_acceleration_0001"])
    del q["unit"]
    assert "unit: required" in messages(run(syl, q))


def test_unknown_field_is_caught(syllabus, golden):
    q = golden["q_quad_discriminant_0001"]
    q["hint1"] = "old-style field"
    assert "unknown field 'hint1'" in messages(run(syllabus, q))

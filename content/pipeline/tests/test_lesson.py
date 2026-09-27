"""Lesson validator tests — mirrors test_questions.py's shape but for the
theory content type (not a question type, so it isn't part of REGISTRY)."""

from content.pipeline.issues import Issues
from content.pipeline.types import REGISTRY
from content.pipeline.types.lesson import MAX_FIELD_CHARS, validate_lesson
from content.pipeline.syllabus import load, syllabus_path

VALID_LESSON = {
    "id": "t_c9_sav_cuboid_cube",
    "concept_id": "c9.sav.cuboid_cube",
    "title": "Cuboids & Cubes",
    "body": "A cuboid is a box shape: two matching ends, four flat sides, every corner square.",
    "hook_kind": "real_world",
    "hook": "Packaging designers work out a box's surface area to know how much cardboard to buy.",
    "try_it": "A shoebox is 30 cm long, 20 cm wide, 15 cm tall. Roughly how much cardboard covers it?",
    "sort_order": 1,
}


def syllabus():
    issues = Issues()
    syl = load(syllabus_path("cbse", 9, "maths"), issues, set(REGISTRY))
    assert issues.errors == []
    return syl


def messages(issues: Issues) -> str:
    return "\n".join(i.message for i in issues.errors)


def test_valid_lesson_is_clean():
    issues = Issues()
    validate_lesson(VALID_LESSON, syllabus(), issues, "test")
    assert issues.errors == []


def test_unknown_concept_id_is_caught():
    lesson = dict(VALID_LESSON, concept_id="c9.sav.not_a_real_concept")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "unknown concept" in messages(issues)


def test_missing_required_field_is_caught():
    lesson = dict(VALID_LESSON)
    del lesson["hook"]
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "missing field 'hook'" in messages(issues)


def test_invalid_hook_kind_is_caught():
    lesson = dict(VALID_LESSON, hook_kind="anecdote")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "hook_kind" in messages(issues)


def test_body_over_length_cap_is_caught():
    lesson = dict(VALID_LESSON, body="x" * (MAX_FIELD_CHARS + 1))
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "body" in messages(issues) and "characters" in messages(issues)


def test_hook_over_length_cap_is_caught():
    lesson = dict(VALID_LESSON, hook="x" * (MAX_FIELD_CHARS + 1))
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "hook" in messages(issues) and "characters" in messages(issues)


def test_unbalanced_dollar_in_body_is_caught():
    lesson = dict(VALID_LESSON, body="The area is $l \\times b square units.")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "math delimiters" in messages(issues)


def test_unbalanced_dollar_in_hook_is_caught():
    lesson = dict(VALID_LESSON, hook="A pyramid's base is $ 230 m wide.")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "math delimiters" in messages(issues)


def test_unbalanced_dollar_in_try_it_is_caught():
    lesson = dict(VALID_LESSON, try_it="If $l = 2 what is the area?")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "math delimiters" in messages(issues)


def test_try_it_is_optional():
    lesson = dict(VALID_LESSON)
    del lesson["try_it"]
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert issues.errors == []


def test_try_it_over_length_cap_is_caught():
    lesson = dict(VALID_LESSON, try_it="x" * (MAX_FIELD_CHARS + 1))
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "try_it" in messages(issues) and "characters" in messages(issues)


def test_id_without_t_prefix_is_caught():
    lesson = dict(VALID_LESSON, id="c9_sav_cuboid_cube")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "id: must start with 't_'" in messages(issues)


def test_non_integer_sort_order_is_caught():
    lesson = dict(VALID_LESSON, sort_order="1")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "sort_order" in messages(issues)


def test_trailing_newline_from_folded_yaml_is_caught():
    # A YAML `>` block (instead of `>-`) leaves a trailing "\n" on the value.
    lesson = dict(VALID_LESSON, body=VALID_LESSON["body"] + "\n")
    issues = Issues()
    validate_lesson(lesson, syllabus(), issues, "test")
    assert "body" in messages(issues) and "whitespace" in messages(issues)

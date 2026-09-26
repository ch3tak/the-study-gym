import textwrap

from content.pipeline.issues import Issues
from content.pipeline.syllabus import load, syllabus_path
from content.pipeline.types import REGISTRY

KNOWN = set(REGISTRY)


def load_text(tmp_path, body: str, name: str = "demo.yaml"):
    path = tmp_path / name
    path.write_text(textwrap.dedent(body), encoding="utf-8")
    issues = Issues()
    return load(path, issues, KNOWN), issues


BASE = """
schema_version: 1
board: cbse
class: 10
subject: demo
name: Demo
status: live
total_marks: 10
units:
  - {id: u, name: U, marks: 10}
chapters:
  - id: ch
    name: Chapter
    unit: u
    board_weight_marks: 10
    default_question_types: [mcq]
    concepts:
      - id: d.a
        name: A
        description: First.
        prerequisites: []
        misconceptions:
          - id: d.a.m
            description: "x"
            detect: "y"
      - id: d.b
        name: B
        description: Second.
        prerequisites: [d.a]
        misconceptions: []
"""


def test_real_maths_syllabus_is_clean():
    issues = Issues()
    syl = load(syllabus_path("cbse", 10, "maths_standard"), issues, KNOWN)
    assert issues.errors == []
    assert len(syl.concepts) >= 120
    assert syl.concept("quad.discriminant").chapter_id == "quadratic_equations"


def test_minimal_syllabus_loads(tmp_path):
    syl, issues = load_text(tmp_path, BASE)
    assert issues.errors == []
    assert syl.misconceptions == {"d.a.m": "d.a"}


def test_unknown_prerequisite(tmp_path):
    _, issues = load_text(tmp_path, BASE.replace("prerequisites: [d.a]", "prerequisites: [d.zzz]"))
    assert any("unknown prerequisite 'd.zzz'" in i.message for i in issues.errors)


def test_prerequisite_cycle(tmp_path):
    body = BASE.replace("prerequisites: []\n        misconceptions:\n          - id: d.a.m",
                        "prerequisites: [d.b]\n        misconceptions:\n          - id: d.a.m")
    _, issues = load_text(tmp_path, body)
    assert any("cycle" in i.message for i in issues.errors)


def test_unit_weight_mismatch(tmp_path):
    _, issues = load_text(tmp_path, BASE.replace("board_weight_marks: 10", "board_weight_marks: 7"))
    assert any("sum to 7" in i.message for i in issues.errors)


def test_flow_mapping_comma_split_is_caught(tmp_path):
    # An unquoted comma in a flow mapping silently creates an extra key.
    body = BASE.replace(
        'id: d.a.m\n            description: "x"\n            detect: "y"',
        "{id: d.a.m, description: swaps HCF, LCM, detect: y}",
    )
    _, issues = load_text(tmp_path, body)
    assert any("unknown field" in i.message for i in issues.errors)


def test_subject_must_match_filename(tmp_path):
    _, issues = load_text(tmp_path, BASE, name="other.yaml")
    assert any("must match file name" in i.message for i in issues.errors)

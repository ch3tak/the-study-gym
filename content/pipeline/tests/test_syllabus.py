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


def test_real_class9_syllabus_is_clean():
    issues = Issues()
    syl = load(syllabus_path("cbse", 9, "maths"), issues, KNOWN)
    assert issues.errors == []
    assert all(cid.startswith("c9.") for cid in syl.concepts)


def test_numeric_requires_unit_rule_loads(tmp_path):
    syl, issues = load_text(tmp_path, BASE + "\nquestion_rules:\n  numeric_requires_unit: true\n")
    assert issues.errors == []
    assert syl.numeric_requires_unit


def test_cross_references_across_all_syllabi():
    from content.pipeline.validate import load_all_syllabi

    issues = Issues()
    syllabi = load_all_syllabi(issues)
    assert issues.errors == []
    c10 = syllabi[("cbse", 10, "maths_standard")]
    assert "c9.iden.standard" in c10.external_concepts


def test_duplicate_concept_across_syllabi(tmp_path):
    from content.pipeline.syllabus import check_cross_references

    a, _ = load_text(tmp_path, BASE, name="demo.yaml")
    other = tmp_path / "other"
    other.mkdir()
    b, _ = load_text(other, BASE.replace("subject: demo", "subject: demo2"), name="demo2.yaml")
    issues = Issues()
    check_cross_references([a, b], issues)
    assert any("also used in" in i.message for i in issues.errors)


def test_unresolved_external_concept(tmp_path):
    from content.pipeline.syllabus import check_cross_references

    body = BASE.replace("chapters:", "external_concepts:\n  - {id: c8.nothing, name: Missing}\nchapters:")
    syl, issues = load_text(tmp_path, body)
    assert issues.errors == []
    check_cross_references([syl], issues)
    assert any("not found in any syllabus" in i.message for i in issues.errors)

    pending, issues = load_text(tmp_path, body.replace("name: Missing}", "name: Missing, pending: true}"))
    check_cross_references([pending], issues)
    assert issues.errors == []


def test_subject_must_match_filename(tmp_path):
    _, issues = load_text(tmp_path, BASE, name="other.yaml")
    assert any("must match file name" in i.message for i in issues.errors)

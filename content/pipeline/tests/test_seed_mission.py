import re
from pathlib import Path

from content.pipeline.seed_mission import FRACTION_TOLERANCE, _numeric_fields, generate_sql

FIXTURE_YAML = Path(__file__).parent / "fixtures" / "mini_mission.yaml"
FIXTURE_SYLLABUS = Path(__file__).parent / "fixtures" / "mini_syllabus.yaml"


def test_chapter_and_concepts_precede_questions():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    chapter_pos = sql.index("insert into chapters")
    concepts_pos = sql.index("insert into concepts")
    questions_pos = sql.index("insert into questions")
    assert chapter_pos < concepts_pos < questions_pos
    assert "'surface_area_volume'" in sql
    assert "'c9.sav.cuboid_cube'" in sql


def test_uses_confirmed_subject_id():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert "'cbse_9_maths'" in sql
    assert "cbse_9_maths_standard" not in sql


REAL_MISSION_YAML = Path(__file__).resolve().parents[2] / "questions/cbse/9/maths/surface_area_volume.yaml"
REAL_SYLLABUS_YAML = Path(__file__).resolve().parents[2] / "syllabus/cbse/9/maths.yaml"


def test_numeric_tolerance_is_carried_into_body():
    fields = _numeric_fields({"answers": ["487.67"], "tolerance": 0.1})
    assert fields == {"numericAnswer": "487.67", "tolerance": 0.1}


def test_numeric_without_tolerance_has_no_tolerance_key():
    assert _numeric_fields({"answers": ["216"]}) == {"numericAnswer": "216"}


def test_fraction_answer_is_converted_to_decimal_with_tolerance():
    fields = _numeric_fields({"answers": ["256/3"]})
    assert fields == {"numericAnswer": "85.33", "tolerance": FRACTION_TOLERANCE}


def test_real_mission_sql_has_tolerances_and_no_fraction_answers():
    sql = generate_sql(REAL_MISSION_YAML, REAL_SYLLABUS_YAML)
    assert '"numericAnswer": "487.67", "tolerance": 0.1' in sql
    assert '"numericAnswer": "85.33", "tolerance": 0.05' in sql
    assert not re.search(r'"numericAnswer": "-?\d+/\d+"', sql)


def test_why_after_previous_is_carried_into_body():
    sql = generate_sql(REAL_MISSION_YAML, REAL_SYLLABUS_YAML)
    assert (
        '"whyAfterPrevious": "First level of the mission: establishes the l/b/h labelling '
        'every later formula depends on."'
    ) in sql

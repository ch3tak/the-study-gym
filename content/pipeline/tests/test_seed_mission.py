import re
from pathlib import Path

from pipeline.seed_mission import generate_sql

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

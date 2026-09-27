from pathlib import Path

import pytest
import yaml

from content.pipeline.seed_theory import generate_sql

FIXTURE_YAML = Path(__file__).parent / "fixtures" / "mini_theory.yaml"
# Real syllabus, not fixtures/mini_syllabus.yaml: seed_theory runs the full
# syllabus.load(), which mini_syllabus.yaml (a raw-YAML fixture for
# seed_mission) doesn't satisfy.
FIXTURE_SYLLABUS = Path(__file__).resolve().parents[2] / "syllabus/cbse/9/maths.yaml"


def test_generates_insert_into_lessons():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert "insert into lessons" in sql
    assert "'t_mini_cuboid_cube'" in sql
    assert "'c9.sav.cuboid_cube'" in sql


def test_wraps_in_transaction():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert sql.strip().startswith("-- Generated")
    assert "begin;" in sql
    assert sql.strip().endswith("commit;")


def test_hook_kind_and_try_it_are_carried_through():
    sql = generate_sql(FIXTURE_YAML, FIXTURE_SYLLABUS)
    assert "'historical'" in sql
    assert "Nile flood" in sql
    assert "Roughly how much cardboard" in sql


def test_duplicate_ids_refuse_to_seed(tmp_path):
    data = yaml.safe_load(FIXTURE_YAML.read_text(encoding="utf-8"))
    data["lessons"].append(dict(data["lessons"][0]))
    dup = tmp_path / "dup_theory.yaml"
    dup.write_text(yaml.safe_dump(data), encoding="utf-8")
    with pytest.raises(ValueError, match="duplicate lesson id"):
        generate_sql(dup, FIXTURE_SYLLABUS)


REAL_THEORY_YAML = Path(__file__).resolve().parents[2] / "questions/cbse/9/maths/surface_area_volume_theory.yaml"
REAL_SYLLABUS_YAML = Path(__file__).resolve().parents[2] / "syllabus/cbse/9/maths.yaml"


def test_real_theory_file_generates_seven_lessons():
    sql = generate_sql(REAL_THEORY_YAML, REAL_SYLLABUS_YAML)
    # Count row openers, not "(" — the column list and lesson prose
    # (e.g. "(the apex)") contain parentheses too.
    assert sql.count("\n  ('t_") == 7

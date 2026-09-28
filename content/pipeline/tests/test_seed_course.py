import re
from pathlib import Path

import pytest

from content.pipeline.seed_course import _text_literal, generate_sql

ROOT = Path(__file__).resolve().parents[2]
SYLLABUS = ROOT / "syllabus/cbse/9/maths.yaml"
MISSION = ROOT / "questions/cbse/9/maths/surface_area_volume.yaml"

UNIT_ROW = re.compile(r"^  \('(cbse_9_maths\.[a-z_]+)', 'cbse_9_maths', '(?:[^']|'')*', [\d.]+, (\d+)\)", re.M)
CHAPTER_ROW = re.compile(
    r"^  \('([a-z_]+)', 'cbse_9_maths', '(?:[^']|'')*', [\d.]+, (\d+), 'cbse_9_maths\.([a-z_]+)'\)", re.M
)


def sql() -> str:
    return generate_sql(SYLLABUS, MISSION)


def test_units_are_namespaced_ordered_and_carry_marks():
    s = sql()
    assert "('cbse_9_maths.number_system', 'cbse_9_maths', 'Number System', 7, 1)" in s
    assert "('cbse_9_maths.geometry', 'cbse_9_maths', 'Geometry', 25, 4)" in s
    assert [int(m[1]) for m in UNIT_ROW.findall(s)] == [1, 2, 3, 4, 5, 6]


def test_units_are_inserted_before_chapters():
    s = sql()
    assert s.index("insert into units") < s.index("insert into chapters")


def test_every_syllabus_chapter_is_upserted_once_in_syllabus_order():
    rows = CHAPTER_ROW.findall(sql())
    assert len(rows) == 15
    assert [int(r[1]) for r in rows] == list(range(1, 16))
    assert [r[0] for r in rows][:3] == ["num", "poly", "sequences_progressions"]


def test_legacy_chapter_ids_are_kept():
    s = sql()
    assert "  ('coord', 'cbse_9_maths', 'Coordinate Geometry', 4, 6, 'cbse_9_maths.coordinate_geometry')" in s
    assert "  ('coordinate_geometry'," not in s
    assert "  ('surface_area_volume', 'cbse_9_maths'," in s


def test_new_chapters_are_created_so_learn_can_show_them_as_soon():
    ids = [r[0] for r in CHAPTER_ROW.findall(sql())]
    for new in ["linear_equations", "euclid_geometry", "lines_angles", "triangles", "quadrilaterals", "statistics"]:
        assert new in ids


def test_seed_is_idempotent():
    s = sql()
    assert s.count("on conflict (id) do update set") == 2
    assert "insert into questions" not in s


def test_every_trial_level_gets_why_after_previous_verbatim():
    s = sql()
    updates = re.findall(r"^update questions set body = body \|\| jsonb_build_object\('whyAfterPrevious', \$wap\$", s, re.M)
    assert len(updates) == 62
    assert "$l=b=h$" in s  # LaTeX kept as written


def test_text_literal_refuses_its_own_tag():
    with pytest.raises(ValueError):
        _text_literal("a $wap$ b")

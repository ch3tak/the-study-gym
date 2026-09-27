"""validate.py's theory-file pass: *_theory.yaml files are validated as
lessons (ids unique across every file), and never fed to the question-bank
validator."""

import yaml

from content.pipeline import validate
from content.pipeline.issues import Issues

LESSON = {
    "id": "t_c9_sav_cuboid_cube",
    "concept_id": "c9.sav.cuboid_cube",
    "title": "Cuboids & Cubes",
    "body": "A cuboid is a box shape with six rectangular faces.",
    "hook_kind": "real_world",
    "hook": "Packaging designers add up a box's face areas to size the cardboard.",
    "sort_order": 1,
}


def write_theory(root, name, lessons):
    subject_dir = root / "cbse" / "9" / "maths"
    subject_dir.mkdir(parents=True, exist_ok=True)
    (subject_dir / name).write_text(yaml.safe_dump({"lessons": lessons}), encoding="utf-8")


def point_at(monkeypatch, root):
    monkeypatch.setattr(validate, "QUESTIONS_ROOT", root)
    monkeypatch.setattr(validate, "THEORY_ROOT", root)


def test_duplicate_lesson_id_across_files_is_caught(tmp_path, monkeypatch):
    point_at(monkeypatch, tmp_path)
    write_theory(tmp_path, "a_theory.yaml", [LESSON])
    write_theory(tmp_path, "b_theory.yaml", [LESSON])
    issues = Issues()
    syllabi = validate.load_all_syllabi(issues)

    count = validate.validate_theory_files(syllabi, issues)

    assert count == 2
    assert any("duplicate lesson id 't_c9_sav_cuboid_cube'" in i.message for i in issues.errors)


def test_theory_file_is_not_validated_as_a_question_bank(tmp_path, monkeypatch, capsys):
    point_at(monkeypatch, tmp_path)
    write_theory(tmp_path, "surface_area_volume_theory.yaml", [LESSON])

    exit_code = validate.main(["-q"])

    out = capsys.readouterr().out
    assert "'questions' list" not in out
    assert "0 questions, 1 lessons: 0 errors" in out
    assert exit_code == 0


def test_theory_file_passed_explicitly_is_validated_as_lessons(tmp_path, monkeypatch, capsys):
    point_at(monkeypatch, tmp_path)
    write_theory(tmp_path, "surface_area_volume_theory.yaml", [LESSON])
    theory_file = tmp_path / "cbse" / "9" / "maths" / "surface_area_volume_theory.yaml"

    exit_code = validate.main(["-q", str(theory_file)])

    out = capsys.readouterr().out
    assert "'questions' list" not in out
    assert "0 questions, 1 lessons: 0 errors" in out
    assert exit_code == 0

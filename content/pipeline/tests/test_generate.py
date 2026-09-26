"""Offline tests for generate.py: request building and result conversion. No API calls."""

import json

from content.pipeline import generate


def test_iter_cells_respects_allowed_types():
    raw = generate.load_raw_syllabus("cbse", 10, "maths_standard")
    cells = list(generate.iter_cells(raw, ["quadratic_equations"], ["assertion_reason"], [2]))
    concepts = {c["id"] for _, c, _, _ in cells}
    assert "quad.nature_of_roots" in concepts
    assert "quad.word_numbers" not in concepts  # allows numeric, case_based, mcq only


def test_output_schema_is_strict():
    schema = generate.output_schema("mcq")
    item = schema["properties"]["questions"]["items"]
    assert item["additionalProperties"] is False
    assert set(item["required"]) == set(item["properties"])


def test_plan_writes_requests(tmp_path, monkeypatch):
    monkeypatch.setattr(generate, "OUT_ROOT", tmp_path)
    rc = generate.main(["plan", "--subject", "cbse/10/maths_standard", "--chapter", "quadratic_equations",
                        "--types", "mcq", "--difficulty", "2", "--count", "3", "--run", "t"])
    assert rc == 0
    lines = (tmp_path / "t" / "requests.jsonl").read_text(encoding="utf-8").splitlines()
    first = json.loads(lines[0])
    assert first["params"]["model"] == "claude-sonnet-5"
    assert "Write 3 mcq questions at difficulty 2" in first["params"]["messages"][0]["content"]
    assert len({json.loads(l)["custom_id"] for l in lines}) == len(lines)


def test_every_profile_has_syllabus_and_golden_examples():
    from content.pipeline import subjects
    from content.pipeline.syllabus import syllabus_path

    for key, profile in subjects.PROFILES.items():
        board, grade, code = key.split("/")
        assert syllabus_path(board, int(grade), code).exists(), key
        assert profile.golden.exists(), key
        assert set(profile.generatable) <= set(generate.GENERATABLE), key


def test_science_plan_uses_science_profile(tmp_path, monkeypatch):
    monkeypatch.setattr(generate, "OUT_ROOT", tmp_path)
    rc = generate.main(["plan", "--subject", "cbse/9/science", "--chapter", "motion", "--run", "s"])
    assert rc == 0
    reqs = [json.loads(l) for l in (tmp_path / "s" / "requests.jsonl").read_text(encoding="utf-8").splitlines()]
    assert {r["meta"]["type"] for r in reqs} <= {"mcq", "numeric", "assertion_reason"}
    system = reqs[0]["params"]["system"][0]["text"]
    assert "Class 9 Science" in system and "Gravitation" in system
    assert all(len(r["custom_id"]) <= 64 for r in reqs)


def test_custom_id_is_capped():
    cid = generate.custom_id_for("c9." + "x" * 80, "assertion_reason", 3)
    assert len(cid) <= 64
    assert cid != generate.custom_id_for("c9." + "x" * 81, "assertion_reason", 3)


def test_to_question_round_trips_through_validator():
    item = {
        "stem": "For what value of $k$ does $x^2 - kx + 16 = 0$ have equal roots?",
        "options": ["$\\pm 8$", "$8$", "$\\pm 4$", "$16$"],
        "answer": 0,
        "distractors": [
            {"option_index": 1, "misconception_id": "quad.disc.missed_negative_root"},
            {"option_index": 2, "misconception_id": "quad.disc.forgot_4ac_factor"},
            {"option_index": 3, "misconception_id": "quad.disc.confused_c_with_k"},
        ],
        "option_values": ["[-8, 8]", "8", "[-4, 4]", "16"],
        "verification_sympy": "solve(k**2 - 4*16, k)",
        "hints": ["Equal roots means $D = 0$."],
        "solution_steps": ["$k^2 - 64 = 0$", "$k = \\pm 8$"],
    }
    good = generate.to_question(item, concept="quad.find_k_equal_roots", type="mcq", difficulty=2)
    bad = generate.to_question({**item, "answer": 1,
                                "distractors": [{"option_index": 0, "misconception_id": "generic.guess"},
                                                *item["distractors"][1:]]},
                               concept="quad.find_k_equal_roots", type="mcq", difficulty=2)
    passed, failed, report = generate.triage([good, bad], "cbse/10/maths_standard")
    assert [q["id"] for q in passed] == [good["id"]]
    assert [q["id"] for q in failed] == [bad["id"]]
    assert good["cbse_section"] == "A" and good["status"] == "draft"

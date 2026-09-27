"""Automatic content gate. Run from the repo root:

    python -m content.pipeline.validate                 # every syllabus + the whole question bank
    python -m content.pipeline.validate FILE [FILE...]  # specific question files (e.g. a generated batch)

Exits non-zero on any error. Warnings mean "route to human review".
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml

from .issues import Issues
from .questions import QUESTIONS_ROOT, load_file, validate_bank
from .syllabus import CONTENT_ROOT, SYLLABUS_ROOT, Syllabus, check_cross_references, load, syllabus_path
from .types import REGISTRY
from .types.lesson import validate_lesson

REPO_ROOT = CONTENT_ROOT.parent


def rel(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(REPO_ROOT)).replace("\\", "/")
    except ValueError:
        return str(path)


def validate_class_files(issues: Issues) -> None:
    for class_file in sorted(SYLLABUS_ROOT.glob("*/*/_class.yaml")):
        data = yaml.safe_load(class_file.read_text(encoding="utf-8"))
        codes = set()
        for s in data.get("subjects", []):
            codes.add(s["code"])
            if not (class_file.parent / s["syllabus"]).exists():
                issues.error(rel(class_file), f"subject '{s['code']}' points at missing {s['syllabus']}")
            if s.get("status") == "coming_soon" and not s.get("eta"):
                issues.error(rel(class_file), f"coming_soon subject '{s['code']}' needs an eta")
        for group in data.get("choice_groups", []):
            for code in group["options"]:
                if code not in codes:
                    issues.error(rel(class_file), f"choice group '{group['label']}' names unknown subject '{code}'")


def load_all_syllabi(issues: Issues) -> dict[tuple[str, int, str], Syllabus]:
    known = set(REGISTRY)
    result = {}
    for path in sorted(SYLLABUS_ROOT.glob("*/*/*.yaml")):
        if path.name.startswith("_"):
            continue
        syl = load(path, issues, known)
        if syl:
            result[(syl.board, syl.grade, syl.subject)] = syl
    check_cross_references(list(result.values()), issues)
    return result


THEORY_ROOT = QUESTIONS_ROOT  # theory files live alongside question files, named *_theory.yaml


def is_theory_file(path: Path) -> bool:
    return path.name.endswith("_theory.yaml")


def validate_theory_files(
    syllabi: dict[tuple[str, int, str], Syllabus], issues: Issues, extra: list[Path] | None = None
) -> int:
    """Validate every theory file under THEORY_ROOT, plus any named in `extra`."""
    total = 0
    # One set across every file: lessons.id is a table-wide primary key.
    seen_ids: dict[str, str] = {}
    paths = {p.resolve() for p in THEORY_ROOT.glob("*/*/*/**/*_theory.yaml")} | {p.resolve() for p in extra or []}
    for path in sorted(paths):
        key = subject_of(path)
        if key is None or key not in syllabi:
            issues.error(rel(path), "can't resolve subject for theory file (expected board/class/subject layout)")
            continue
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        lessons = data.get("lessons") if isinstance(data, dict) else None
        if not isinstance(lessons, list):
            issues.error(rel(path), "theory file must have a top-level 'lessons:' list")
            continue
        for lesson in lessons:
            if not isinstance(lesson, dict):
                issues.error(rel(path), f"lesson entry is not a mapping: {lesson!r}")
                continue
            lesson_id = lesson.get("id", "<no id>")
            where = f"{rel(path)}:{lesson_id}"
            if lesson_id in seen_ids:
                issues.error(where, f"duplicate lesson id '{lesson_id}' (first seen in {seen_ids[lesson_id]})")
            else:
                seen_ids[lesson_id] = rel(path)
            validate_lesson(lesson, syllabi[key], issues, where)
            total += 1
    return total


def subject_of(question_file: Path) -> tuple[str, int, str] | None:
    """content/questions/{board}/{class}/{subject}/<file>.yaml -> (board, class, subject)."""
    try:
        board, grade, subject = question_file.resolve().relative_to(QUESTIONS_ROOT).parts[:3]
        return board, int(grade), subject
    except (ValueError, IndexError):
        return None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("files", nargs="*", type=Path, help="question files to check (default: whole bank)")
    parser.add_argument("--subject", help="board/class/subject for files outside content/questions, e.g. cbse/10/maths_standard")
    parser.add_argument("-q", "--quiet", action="store_true", help="hide warnings")
    args = parser.parse_args(argv)

    issues = Issues()
    syllabi = load_all_syllabi(issues)
    validate_class_files(issues)

    # Theory files share directories with question banks but go to the theory pass.
    if args.files:
        files = [f for f in args.files if not is_theory_file(f)]
        theory_files = [f for f in args.files if is_theory_file(f)]
    else:
        files = sorted(p for p in QUESTIONS_ROOT.glob("*/*/*/**/*.yaml") if not is_theory_file(p))
        theory_files = []
    groups: dict[tuple[str, int, str], list[tuple[str, dict]]] = {}
    for f in files:
        if args.subject:
            board, grade, subject = args.subject.split("/")
            key = (board, int(grade), subject)
        else:
            key = subject_of(f)
        if key is None:
            issues.error(rel(f), "can't tell the subject; pass --subject board/class/subject")
            continue
        if key not in syllabi:
            issues.error(rel(f), f"no syllabus at {rel(syllabus_path(*key))}")
            continue
        groups.setdefault(key, []).extend((rel(f), q) for q in load_file(f, issues))

    total = 0
    for key, questions in groups.items():
        total += len(questions)
        validate_bank(questions, syllabi[key], issues)
    lessons = validate_theory_files(syllabi, issues, theory_files)

    shown = issues.errors if args.quiet else issues.items
    for issue in shown:
        print(issue)
    concepts = sum(len(s.concepts) for s in syllabi.values())
    print(
        f"\n{len(syllabi)} syllabi ({concepts} concepts), {total} questions, {lessons} lessons: "
        f"{len(issues.errors)} errors, {len(issues.warnings)} warnings"
    )
    return 1 if issues.errors else 0


if __name__ == "__main__":
    sys.exit(main())

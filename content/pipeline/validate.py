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
from .syllabus import CONTENT_ROOT, SYLLABUS_ROOT, Syllabus, load, syllabus_path
from .types import REGISTRY

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
    return result


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

    files = args.files or sorted(QUESTIONS_ROOT.glob("*/*/*/**/*.yaml"))
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

    shown = issues.errors if args.quiet else issues.items
    for issue in shown:
        print(issue)
    concepts = sum(len(s.concepts) for s in syllabi.values())
    print(
        f"\n{len(syllabi)} syllabi ({concepts} concepts), {total} questions: "
        f"{len(issues.errors)} errors, {len(issues.warnings)} warnings"
    )
    return 1 if issues.errors else 0


if __name__ == "__main__":
    sys.exit(main())

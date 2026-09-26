"""Load and validate syllabus files: content/syllabus/{board}/{class}/{subject}.yaml."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

import yaml

from .issues import Issues, check_keys

CONTENT_ROOT = Path(__file__).resolve().parents[1]
SYLLABUS_ROOT = CONTENT_ROOT / "syllabus"

CONCEPT_ID = re.compile(r"^[a-z0-9]+(\.[a-z0-9_]+)+$")
SLUG = re.compile(r"^[a-z0-9_]+$")
STATUSES = {"live", "coming_soon", "hidden"}

_TOP_REQUIRED = {"schema_version", "board", "class", "subject", "name", "status", "total_marks", "chapters"}
_TOP_OPTIONAL = {"academic_year", "default_half_life_days", "sources", "units", "external_concepts", "question_rules"}
_QUESTION_RULES = {"numeric_requires_unit"}
_EXTERNAL_KEYS = {"id", "name", "pending"}
_CHAPTER_REQUIRED = {"id", "name", "board_weight_marks", "concepts"}
_CHAPTER_OPTIONAL = {"unit", "board_weight_is_estimate", "default_question_types", "verify", "chapter_number"}
_CONCEPT_REQUIRED = {"id", "name", "description", "prerequisites", "misconceptions"}
_CONCEPT_OPTIONAL = {"question_types_allowed", "verify", "retired"}
_MISCONCEPTION_KEYS = {"id", "description", "detect"}


@dataclass
class Concept:
    id: str
    chapter_id: str
    question_types: list[str]
    misconception_ids: list[str]
    retired: bool = False


@dataclass
class Syllabus:
    path: Path
    board: str
    grade: int
    subject: str
    status: str
    name: str = ""
    numeric_requires_unit: bool = False
    concepts: dict[str, Concept] = field(default_factory=dict)
    # Prerequisites from other syllabi (usually an earlier class). id -> pending:
    # pending ones point at a syllabus we haven't authored yet.
    external_concepts: dict[str, bool] = field(default_factory=dict)
    misconceptions: dict[str, str] = field(default_factory=dict)  # misconception id -> concept id

    @property
    def where(self) -> str:
        return f"content/syllabus/{self.board}/{self.grade}/{self.subject}.yaml"

    def concept(self, concept_id: str) -> Concept | None:
        return self.concepts.get(concept_id)


def syllabus_path(board: str, grade: int, subject: str) -> Path:
    return SYLLABUS_ROOT / board / str(grade) / f"{subject}.yaml"


def load(path: Path, issues: Issues, known_types: set[str]) -> Syllabus | None:
    where = str(path.relative_to(CONTENT_ROOT.parent)) if path.is_relative_to(CONTENT_ROOT.parent) else str(path)
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        issues.error(where, f"YAML parse error: {exc}")
        return None
    if not isinstance(data, dict):
        issues.error(where, "top level must be a mapping")
        return None

    check_keys(data, where, issues, required=_TOP_REQUIRED, optional=_TOP_OPTIONAL)
    if data.get("schema_version") != 1:
        issues.error(where, "schema_version must be 1")
    if data.get("subject") != path.stem:
        issues.error(where, f"subject '{data.get('subject')}' must match file name '{path.stem}'")
    if data.get("status") not in STATUSES:
        issues.error(where, f"status must be one of {sorted(STATUSES)}")

    syl = Syllabus(
        path=path,
        board=str(data.get("board")),
        grade=int(data.get("class", 0)),
        subject=str(data.get("subject")),
        status=str(data.get("status")),
        name=str(data.get("name", "")),
    )
    rules = data.get("question_rules") or {}
    check_keys(rules, f"{where}#question_rules", issues, required=set(), optional=_QUESTION_RULES)
    syl.numeric_requires_unit = bool(rules.get("numeric_requires_unit", False))
    for ext in data.get("external_concepts") or []:
        check_keys(ext, f"{where}#external_concepts", issues, required={"id", "name"}, optional=_EXTERNAL_KEYS)
        syl.external_concepts[ext.get("id", "")] = bool(ext.get("pending", False))

    units = {u["id"]: u["marks"] for u in data.get("units") or []}
    if units and sum(units.values()) != data.get("total_marks"):
        issues.error(where, f"unit marks sum to {sum(units.values())}, expected total_marks {data.get('total_marks')}")

    chapters = data.get("chapters") or []
    if syl.status == "live" and not chapters:
        issues.error(where, "a live subject needs at least one chapter")

    unit_totals: dict[str, float] = {}
    chapter_ids: set[str] = set()
    prereqs: dict[str, list[str]] = {}

    for ch in chapters:
        cw = f"{where}#{ch.get('id', '?')}"
        check_keys(ch, cw, issues, required=_CHAPTER_REQUIRED, optional=_CHAPTER_OPTIONAL)
        cid = ch.get("id", "")
        if not SLUG.match(str(cid)):
            issues.error(cw, "chapter id must be lower_snake_case")
        if cid in chapter_ids:
            issues.error(cw, "duplicate chapter id")
        chapter_ids.add(cid)
        if units:
            if ch.get("unit") not in units:
                issues.error(cw, f"unknown unit '{ch.get('unit')}'")
            else:
                unit_totals[ch["unit"]] = unit_totals.get(ch["unit"], 0) + ch.get("board_weight_marks", 0)
        default_types = ch.get("default_question_types") or []

        for c in ch.get("concepts") or []:
            kw = f"{where}#{c.get('id', '?')}"
            check_keys(c, kw, issues, required=_CONCEPT_REQUIRED, optional=_CONCEPT_OPTIONAL)
            concept_id = c.get("id", "")
            if not CONCEPT_ID.match(str(concept_id)):
                issues.error(kw, "concept id must look like 'prefix.name'")
            if concept_id in syl.concepts:
                issues.error(kw, "duplicate concept id")
            if not str(c.get("description", "")).strip():
                issues.error(kw, "empty description")

            types = c.get("question_types_allowed") or default_types
            if not types:
                issues.error(kw, "no question types (set question_types_allowed or chapter default_question_types)")
            for t in types:
                if t not in known_types:
                    issues.error(kw, f"unknown question type '{t}'")

            mis_ids = []
            for m in c.get("misconceptions") or []:
                if not isinstance(m, dict):
                    issues.error(kw, f"misconception must be a mapping, got {m!r}")
                    continue
                check_keys(m, f"{kw}/{m.get('id', '?')}", issues, required=_MISCONCEPTION_KEYS)
                mid = m.get("id", "")
                if mid in syl.misconceptions:
                    issues.error(kw, f"duplicate misconception id '{mid}'")
                syl.misconceptions[mid] = concept_id
                mis_ids.append(mid)
            if not mis_ids and not c.get("retired"):
                issues.warn(kw, "no misconceptions listed")

            prereqs[concept_id] = list(c.get("prerequisites") or [])
            syl.concepts[concept_id] = Concept(
                id=concept_id,
                chapter_id=cid,
                question_types=list(types),
                misconception_ids=mis_ids,
                retired=bool(c.get("retired", False)),
            )

    for unit_id, marks in units.items():
        got = unit_totals.get(unit_id, 0)
        if chapters and abs(got - marks) > 1e-9:
            issues.error(where, f"chapter weights in unit '{unit_id}' sum to {got}, expected {marks}")

    for concept_id, reqs in prereqs.items():
        for r in reqs:
            if r == concept_id:
                issues.error(f"{where}#{concept_id}", "concept lists itself as a prerequisite")
            elif r not in syl.concepts and r not in syl.external_concepts:
                issues.error(f"{where}#{concept_id}", f"unknown prerequisite '{r}'")
    for cycle in _find_cycles(prereqs):
        issues.error(where, "prerequisite cycle: " + " -> ".join(cycle))

    return syl


def check_cross_references(syllabi: list[Syllabus], issues: Issues) -> None:
    """Checks that need every syllabus at once: ids are global keys in the
    database, and external prerequisites must point at real concepts."""
    concept_owner: dict[str, Syllabus] = {}
    misconception_owner: dict[str, Syllabus] = {}
    for syl in syllabi:
        for cid in syl.concepts:
            if cid in concept_owner:
                issues.error(syl.where, f"concept id '{cid}' also used in {concept_owner[cid].where}")
            concept_owner[cid] = syl
        for mid in syl.misconceptions:
            if mid in misconception_owner:
                issues.error(syl.where, f"misconception id '{mid}' also used in {misconception_owner[mid].where}")
            misconception_owner[mid] = syl

    for syl in syllabi:
        for ext_id, pending in syl.external_concepts.items():
            owner = concept_owner.get(ext_id)
            if owner is syl:
                issues.error(syl.where, f"external concept '{ext_id}' is defined in this same syllabus")
            elif owner is None and not pending:
                issues.error(syl.where, f"external concept '{ext_id}' not found in any syllabus (mark it pending: true if its class isn't authored yet)")
            elif owner is not None and pending:
                issues.error(syl.where, f"external concept '{ext_id}' now exists in {owner.where}; drop pending: true")


def _find_cycles(graph: dict[str, list[str]]) -> list[list[str]]:
    WHITE, GREY, BLACK = 0, 1, 2
    color = {n: WHITE for n in graph}
    cycles: list[list[str]] = []
    stack: list[str] = []

    def visit(n: str) -> None:
        color[n] = GREY
        stack.append(n)
        for m in graph.get(n, []):
            if m not in graph:
                continue
            if color[m] == GREY:
                cycles.append(stack[stack.index(m):] + [m])
            elif color[m] == WHITE:
                visit(m)
        stack.pop()
        color[n] = BLACK

    for n in graph:
        if color[n] == WHITE:
            visit(n)
    return cycles

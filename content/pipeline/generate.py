"""Generate draft questions with Claude via the Message Batches API (50% cheaper, async).

Three steps, each resumable. Run from the repo root:

    # 1. Build requests (no API key needed; inspect out/<run>/requests.jsonl)
    python -m content.pipeline.generate plan --chapter quadratic_equations --count 5

    # 2. Submit the batch (needs ANTHROPIC_API_KEY)
    python -m content.pipeline.generate submit <run>

    # 3. Fetch results once the batch has ended, convert, and validate
    python -m content.pipeline.generate collect <run>

`collect` writes out/<run>/passed.yaml (no errors; may still carry review
warnings) and out/<run>/failed.yaml with the validator report. Nothing is ever
written into content/questions/ directly; that happens after human review.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path

import yaml

from . import subjects
from .issues import Issues
from .questions import validate_bank
from .subjects import SubjectProfile
from .syllabus import load, syllabus_path
from .types import GENERIC_MISCONCEPTIONS, REGISTRY

MODEL = "claude-sonnet-5"
OUT_ROOT = Path(__file__).resolve().parent / "out"
DEFAULT_SUBJECT = "cbse/9/maths"

# Types the generator can produce at all (per-subject lists live in subjects.py).
# case_based is assembled by hand for now.
GENERATABLE = ("mcq", "numeric", "expression", "assertion_reason")
DIFFICULTY_LABEL = {1: "easy (direct recall or one step)", 2: "exam-standard", 3: "challenge (multi-step)"}

# ---------------------------------------------------------------------------
# Output schemas (structured outputs). Map-shaped fields are arrays here and
# converted back in `to_question`, since JSON object keys can't be integers.
# ---------------------------------------------------------------------------

_STR = {"type": "string"}
_STRS = {"type": "array", "items": _STR}
_MAPPED_WRONG = {
    "type": "array",
    "items": {
        "type": "object",
        "properties": {"value": _STR, "misconception_id": _STR},
        "required": ["value", "misconception_id"],
        "additionalProperties": False,
    },
}
_COMMON = {"stem": _STR, "hints": _STRS, "solution_steps": _STRS, "verification_sympy": _STR}

_TYPE_PROPS = {
    "mcq": {
        "options": _STRS,
        "answer": {"type": "integer"},
        "distractors": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {"option_index": {"type": "integer"}, "misconception_id": _STR},
                "required": ["option_index", "misconception_id"],
                "additionalProperties": False,
            },
        },
        "option_values": _STRS,
    },
    "numeric": {"answers": _STRS, "tolerance": {"type": "number"}, "unit": _STR, "wrong_answers": _MAPPED_WRONG},
    "expression": {
        "answer": _STR,
        "variables": _STRS,
        "form": {"type": "string", "enum": ["any", "factored", "expanded"]},
        "wrong_answers": _MAPPED_WRONG,
    },
    "assertion_reason": {"assertion": _STR, "reason": _STR, "answer": {"type": "string", "enum": ["a", "b", "c", "d"]}},
}


def output_schema(qtype: str) -> dict:
    props = {**_COMMON, **_TYPE_PROPS[qtype]}
    item = {"type": "object", "properties": props, "required": sorted(props), "additionalProperties": False}
    return {
        "type": "object",
        "properties": {"questions": {"type": "array", "items": item}},
        "required": ["questions"],
        "additionalProperties": False,
    }


# ---------------------------------------------------------------------------
# Prompts. The system prompt is identical across a run so it caches.
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """You write practice questions for {title}.
Students use them in a daily practice app. A single wrong answer key destroys their trust, so correctness beats variety.

Rules:
- Original questions only, in the style of CBSE exam papers. Never copy NCERT or past-paper questions.
- Stay strictly inside the concept you are given.
- Indian context where a situation is used (rupees, metres, school, cricket, festivals). Simple English; short sentences.
- Maths in LaTeX between single $ signs, e.g. "$x^2 - 5x + 6 = 0$". Escape nothing extra; the JSON encoder handles backslashes.
- Use "hints" for at most 2 progressive hints that don't give the answer away. "solution_steps" is a short worked solution, one step per item.
- Every wrong MCQ option must come from a specific misconception in the list you are given (use its id). Use "generic.arithmetic_slip" or "generic.misread_question" only when no listed misconception fits.

Subject rules:
{rules}

Machine verification (a checker recomputes your answer with SymPy and rejects mismatches):
- "verification_sympy" is ONE SymPy expression that computes the answer from the question's numbers. Use plain SymPy: solve, sqrt, Rational, pi, sin, cos, tan, factor, expand, simplify, gcd, lcm, factorint, positive_roots(expr, var) (real positive roots, for lengths/ages/counts). Use ** for powers and * for multiplication. No imports, no attribute access, no lambdas.
- mcq: "option_values" gives each option as a SymPy value in the same order (a list like "[-6, 6]" for ±6). Exactly one option must equal the verification result. If the question is conceptual and can't be computed, set verification_sympy and every option_value to "".
- numeric: "answers" lists every value the student must enter (usually one). "wrong_answers" maps predictable wrong values to misconception ids. tolerance is 0 unless the answer is a rounded decimal.
- expression: "answer" is SymPy syntax, e.g. "(2*x - 1)*(x + 3)"; "variables" lists its symbols.
- assertion_reason: answer uses the standard CBSE key: a = both true and R explains A; b = both true, R doesn't explain A; c = A true, R false; d = A false, R true. Set verification_sympy to "".

Before writing each question, solve it yourself and check the key. If you can't make a question you are sure of, return fewer questions.

Reference examples in our format (YAML shown for readability; you answer in the JSON schema):
{examples}"""


def system_prompt(profile: SubjectProfile) -> str:
    return SYSTEM_PROMPT.format(
        title=profile.title, rules=profile.rules, examples=profile.golden.read_text(encoding="utf-8")
    )


def user_prompt(concept: dict, chapter_name: str, qtype: str, difficulty: int, count: int) -> str:
    misconceptions = "\n".join(f"  - {m['id']}: {m['description']}" for m in concept["misconceptions"])
    generic = ", ".join(sorted(GENERIC_MISCONCEPTIONS))
    return (
        f"Chapter: {chapter_name}\n"
        f"Concept id: {concept['id']}\n"
        f"Concept: {concept['name']}: {concept['description']}\n"
        f"Known misconceptions:\n{misconceptions or '  (none listed)'}\n"
        f"Generic misconceptions also allowed: {generic}\n\n"
        f"Write {count} {qtype} questions at difficulty {difficulty}: {DIFFICULTY_LABEL[difficulty]}.\n"
        "Vary the numbers, the surface situation and which misconception each question targets."
    )


# ---------------------------------------------------------------------------
# plan / submit / collect
# ---------------------------------------------------------------------------

def load_raw_syllabus(board: str, grade: int, subject: str) -> dict:
    return yaml.safe_load(syllabus_path(board, grade, subject).read_text(encoding="utf-8"))


def iter_cells(raw: dict, chapter_ids: list[str], types: list[str], difficulties: list[int]):
    """Yield (chapter, concept, type, difficulty) for every allowed combination."""
    for ch in raw["chapters"]:
        if chapter_ids and ch["id"] not in chapter_ids:
            continue
        for c in ch["concepts"]:
            if c.get("retired"):
                continue
            allowed = c.get("question_types_allowed") or ch.get("default_question_types") or []
            for t in types:
                if t in allowed:
                    for d in difficulties:
                        yield ch, c, t, d


def custom_id_for(concept_id: str, qtype: str, difficulty: int) -> str:
    """Batch custom_ids must match ^[a-zA-Z0-9_-]{1,64}$."""
    cid = f"{concept_id}--{qtype}--{difficulty}".replace(".", "-")
    if len(cid) > 64:
        cid = cid[:55] + "-" + hashlib.sha1(cid.encode()).hexdigest()[:8]
    return cid


def cmd_plan(args) -> int:
    try:
        profile = subjects.get(args.subject)
    except KeyError as exc:
        print(exc, file=sys.stderr)
        return 2
    board, grade, subject = args.subject.split("/")
    raw = load_raw_syllabus(board, int(grade), subject)
    known = {ch["id"] for ch in raw["chapters"]}
    for cid in args.chapter:
        if cid not in known:
            print(f"unknown chapter '{cid}'", file=sys.stderr)
            return 2

    run = args.run or datetime.now().strftime("%Y%m%d-%H%M%S")
    run_dir = OUT_ROOT / run
    run_dir.mkdir(parents=True, exist_ok=True)
    system = system_prompt(profile)
    types = [t for t in (args.types or profile.generatable) if t in profile.generatable]
    n = 0
    with (run_dir / "requests.jsonl").open("w", encoding="utf-8") as f:
        for ch, c, t, d in iter_cells(raw, args.chapter, types, args.difficulty):
            custom_id = custom_id_for(c["id"], t, d)
            params = {
                "model": MODEL,
                "max_tokens": 16000,
                "thinking": {"type": "adaptive"},
                "output_config": {"effort": args.effort, "format": {"type": "json_schema", "schema": output_schema(t)}},
                "system": [{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
                "messages": [{"role": "user", "content": user_prompt(c, ch["name"], t, d, args.count)}],
            }
            meta = {"concept": c["id"], "type": t, "difficulty": d}
            f.write(json.dumps({"custom_id": custom_id, "meta": meta, "params": params}, ensure_ascii=False) + "\n")
            n += 1
    (run_dir / "run.json").write_text(json.dumps({"subject": args.subject, "requests": n}, indent=2), encoding="utf-8")
    print(f"planned {n} requests x {args.count} questions -> {run_dir}")
    return 0


def cmd_submit(args) -> int:
    import anthropic
    from anthropic.types.message_create_params import MessageCreateParamsNonStreaming
    from anthropic.types.messages.batch_create_params import Request

    run_dir = OUT_ROOT / args.run
    info = json.loads((run_dir / "run.json").read_text(encoding="utf-8"))
    if info.get("batch_id"):
        print(f"already submitted as {info['batch_id']}")
        return 0
    lines = [json.loads(l) for l in (run_dir / "requests.jsonl").read_text(encoding="utf-8").splitlines() if l]
    client = anthropic.Anthropic()
    batch = client.messages.batches.create(
        requests=[Request(custom_id=r["custom_id"], params=MessageCreateParamsNonStreaming(**r["params"])) for r in lines]
    )
    info["batch_id"] = batch.id
    (run_dir / "run.json").write_text(json.dumps(info, indent=2), encoding="utf-8")
    print(f"submitted {len(lines)} requests as batch {batch.id} ({batch.processing_status})")
    return 0


def cmd_collect(args) -> int:
    import anthropic

    run_dir = OUT_ROOT / args.run
    info = json.loads((run_dir / "run.json").read_text(encoding="utf-8"))
    metas = {}
    for line in (run_dir / "requests.jsonl").read_text(encoding="utf-8").splitlines():
        if line:
            r = json.loads(line)
            metas[r["custom_id"]] = r["meta"]

    client = anthropic.Anthropic()
    batch = client.messages.batches.retrieve(info["batch_id"])
    if batch.processing_status != "ended":
        c = batch.request_counts
        print(f"batch {batch.id} is {batch.processing_status}: {c.processing} processing, {c.succeeded} succeeded")
        return 3

    questions: list[dict] = []
    failures: list[str] = []
    # Results arrive in any order; key by custom_id.
    for result in client.messages.batches.results(batch.id):
        meta = metas[result.custom_id]
        if result.result.type != "succeeded":
            failures.append(f"{result.custom_id}: {result.result.type}")
            continue
        msg = result.result.message
        if msg.stop_reason != "end_turn":
            failures.append(f"{result.custom_id}: stop_reason={msg.stop_reason}")
            continue
        text = next((b.text for b in msg.content if b.type == "text"), "")
        try:
            items = json.loads(text)["questions"]
        except (json.JSONDecodeError, KeyError) as exc:
            failures.append(f"{result.custom_id}: bad JSON ({exc})")
            continue
        questions += [to_question(item, **meta) for item in items]

    passed, failed, report = triage(questions, info["subject"])
    dump(run_dir / "passed.yaml", passed)
    dump(run_dir / "failed.yaml", failed)
    (run_dir / "report.txt").write_text("\n".join(failures + report) + "\n", encoding="utf-8")
    print(f"{len(questions)} generated: {len(passed)} passed, {len(failed)} failed, {len(failures)} request failures")
    print(f"see {run_dir / 'report.txt'}")
    return 0


# ---------------------------------------------------------------------------
# Conversion and triage (pure functions, unit-tested)
# ---------------------------------------------------------------------------

MARKS = {"mcq": {1: 1, 2: 1, 3: 1}, "assertion_reason": {1: 1, 2: 1, 3: 1},
         "numeric": {1: 1, 2: 2, 3: 3}, "expression": {1: 1, 2: 2, 3: 3}}
SECTION = {1: "A", 2: "B", 3: "C"}


def to_question(item: dict, *, concept: str, type: str, difficulty: int) -> dict:
    """Convert one structured-output item to our question YAML shape."""
    marks = MARKS[type][difficulty]
    digest = hashlib.sha1(json.dumps(item, sort_keys=True).encode()).hexdigest()[:8]
    q: dict = {
        "id": f"q_{concept.replace('.', '_')}_{digest}",
        "concepts": [concept],
        "difficulty": difficulty,
        "type": type,
        "cbse_section": SECTION[marks],
        "marks": marks,
        "stem": item["stem"],
    }
    if type == "mcq":
        q["options"] = item["options"]
        q["answer"] = item["answer"]
        q["distractors"] = {d["option_index"]: d["misconception_id"] for d in item["distractors"]}
    elif type == "numeric":
        q["answers"] = item["answers"]
        if item.get("tolerance"):
            q["tolerance"] = item["tolerance"]
        if item.get("unit"):
            q["unit"] = item["unit"]
        if item.get("wrong_answers"):
            q["wrong_answers"] = {w["value"]: w["misconception_id"] for w in item["wrong_answers"]}
    elif type == "expression":
        q["answer"] = item["answer"]
        q["variables"] = item["variables"]
        q["form"] = item["form"]
        if item.get("wrong_answers"):
            q["wrong_answers"] = {w["value"]: w["misconception_id"] for w in item["wrong_answers"]}
    elif type == "assertion_reason":
        q["assertion"] = item["assertion"]
        q["reason"] = item["reason"]
        q["answer"] = item["answer"]
    if item.get("hints"):
        q["hints"] = item["hints"]
    q["solution_steps"] = item["solution_steps"]
    verification = {}
    if item.get("verification_sympy"):
        verification["sympy"] = item["verification_sympy"]
        if type == "mcq":
            verification["option_values"] = item["option_values"]
    if verification:
        q["verification"] = verification
    q["status"] = "draft"
    q["review"] = {"generated_by": MODEL, "human": False}
    return q


def triage(questions: list[dict], subject: str) -> tuple[list[dict], list[dict], list[str]]:
    """Validate a generated set; split into passed (no errors) and failed."""
    board, grade, code = subject.split("/")
    issues = Issues()
    syl = load(syllabus_path(board, int(grade), code), issues, set(REGISTRY))
    per_q = Issues()
    validate_bank([("generated", q) for q in questions], syl, per_q)
    bad_ids = {i.where.split("#", 1)[1].split("/", 1)[0] for i in per_q.errors}
    passed = [q for q in questions if q["id"] not in bad_ids]
    failed = [q for q in questions if q["id"] in bad_ids]
    report = [str(i) for i in per_q.items]
    return passed, failed, report


def dump(path: Path, questions: list[dict]) -> None:
    path.write_text(yaml.safe_dump({"questions": questions}, allow_unicode=True, sort_keys=False, width=110),
                    encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("plan", help="build batch requests")
    p.add_argument("--subject", default=DEFAULT_SUBJECT, choices=sorted(subjects.PROFILES))
    p.add_argument("--chapter", action="append", default=[], help="chapter id (repeatable; default all)")
    p.add_argument("--types", nargs="+", choices=GENERATABLE, help="default: every type the subject supports")
    p.add_argument("--difficulty", nargs="+", type=int, default=[1, 2, 3], choices=[1, 2, 3])
    p.add_argument("--count", type=int, default=5, help="questions per request")
    p.add_argument("--effort", default="high", choices=["low", "medium", "high", "xhigh", "max"])
    p.add_argument("--run", help="run name (default: timestamp)")
    p.set_defaults(func=cmd_plan)

    s = sub.add_parser("submit", help="submit a planned run as a batch")
    s.add_argument("run")
    s.set_defaults(func=cmd_submit)

    c = sub.add_parser("collect", help="fetch results, convert and validate")
    c.add_argument("run")
    c.set_defaults(func=cmd_collect)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())

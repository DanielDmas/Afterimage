#!/usr/bin/env python3
"""dlgc — the Dialogue DSL compiler (foundation_blueprints.md §4.1):
"Plain text, one file per NPC per scene-context, compiled to graph JSON."
Compiled output is a build artifact (tech_guidelines.md §5.1: "never
hand-edited, never committed") — this script is meant to be run at build/CI
time, its JSON never checked in.

Grammar (v0 — see docs/dev_log.md's Pass 15 entry for what's deliberately
out of scope):

    # a comment
    START node_id

    == node_id ==
    speaker: Line of text.
    speaker[stance]: Line with a stance tag (procedural/warm/pressing/...).
    drift: "The misheard version of the immediately preceding line." [intent]
    +claim.some_id
    +claim.some_id(subject, predicate, object)

    choice "Choice text" [stance] -> target_node
    choice "Choice text" [stance] -> target_node if <predicate>

    -> target_node
    -> END

<predicate> is a compact text form of foundation_blueprints.md §2's
predicate language, e.g. `trustAtLeast(npc.doubek, 40)`,
`all(flag(saw_x), not(hasClaim(claim.y)))`. It compiles to exactly the JSON
shape src/core/predicate.gd's PredicateEvaluator already expects:
{"op": ..., "args": {...}}. The per-operator argument NAMES below must stay
in sync with predicate.gd's own OPERATOR_SPECS — there is no shared source
of truth between the two languages (Python here, GDScript there), the same
kind of cross-language spec duplication src/core/prng.gd's Python reference
already lives with, documented rather than silently assumed.
"""

import json
import re
import sys
from pathlib import Path

DLG_VERSION = 1

# Mirrors src/core/predicate.gd's OPERATOR_SPECS argument order/names.
# Combinators (all/any/not) are handled separately - they take nested
# predicates, not scalar args.
OPERATOR_ARG_NAMES = {
    "hasClaim": ["id"],
    "claimAsserted": ["id"],  # optional trailing "mode" arg
    "trustAtLeast": ["npc", "n"],
    "suspicionAtLeast": ["target", "n"],
    "mindBand": ["variable", "band"],
    "dayAfter": ["day"],
    "dayBefore": ["day"],
    "missionDone": ["id"],
    "flag": ["name"],
    "flagValue": ["name", "value"],
    "killsAtLeast": ["context", "n"],
    "witnessed": ["eventTag"],
    "grounded": ["ref"],
    "coverBlownTo": [],  # optional "faction" arg
    "endingGate": ["family"],
    "itemHeld": ["id"],
    "relationshipAtLeast": ["npc", "tier"],
}
COMBINATORS = {"all", "any", "not"}

NODE_HEADER_RE = re.compile(r"^==\s*(?P<id>[a-zA-Z0-9_.]+)\s*==$")
SPEAKER_LINE_RE = re.compile(
    r"^(?P<speaker>[a-zA-Z0-9_.]+)(\[(?P<stance>[a-zA-Z0-9_]+)\])?:\s*(?P<text>.*)$"
)
DRIFT_RE = re.compile(r'^drift:\s*"(?P<text>[^"]*)"\s*(\[(?P<intent>[a-zA-Z0-9_]+)\])?$')
CLAIM_GRANT_RE = re.compile(
    r"^\+(?P<id>claim\.[a-zA-Z0-9_.]+)(\((?P<structured>[^)]*)\))?$"
)
CHOICE_RE = re.compile(
    r'^choice\s+"(?P<text>[^"]*)"\s*(\[(?P<stance>[a-zA-Z0-9_]+)\])?\s*->\s*'
    r"(?P<target>[a-zA-Z0-9_.]+)(\s+if\s+(?P<guard>.+))?$"
)
GOTO_RE = re.compile(r"^->\s*(?P<target>[a-zA-Z0-9_.]+)$")
START_RE = re.compile(r"^START\s+(?P<id>[a-zA-Z0-9_.]+)$")


class DlgSyntaxError(Exception):
    pass


def parse_predicate(text: str) -> dict:
    """Parses a compact predicate expression into predicate.gd's JSON shape."""
    text = text.strip()
    match = re.match(r"^(?P<op>[a-zA-Z]+)\((?P<inner>.*)\)$", text)
    if not match:
        raise DlgSyntaxError(f"malformed predicate expression: {text!r}")
    op = match.group("op")
    inner = match.group("inner")
    args_text = _split_top_level_args(inner)

    if op in COMBINATORS:
        if op == "not":
            if len(args_text) != 1:
                raise DlgSyntaxError(f"not() takes exactly one predicate: {text!r}")
            return {"op": "not", "args": {"predicate": parse_predicate(args_text[0])}}
        return {"op": op, "args": {"predicates": [parse_predicate(a) for a in args_text]}}

    if op not in OPERATOR_ARG_NAMES:
        raise DlgSyntaxError(f"unknown predicate operator: {op!r}")

    arg_names = OPERATOR_ARG_NAMES[op]
    if len(args_text) < len(arg_names):
        raise DlgSyntaxError(
            f"{op}() expects at least {len(arg_names)} arg(s), got {len(args_text)}: {text!r}"
        )
    args = {}
    for name, raw in zip(arg_names, args_text):
        args[name] = _parse_scalar(raw)
    return {"op": op, "args": args}


def _split_top_level_args(inner: str) -> list:
    """Splits on top-level commas only, respecting nested parens (for
    combinator predicates whose args are themselves predicate calls)."""
    inner = inner.strip()
    if not inner:
        return []
    parts = []
    depth = 0
    current = []
    for ch in inner:
        if ch == "(":
            depth += 1
            current.append(ch)
        elif ch == ")":
            depth -= 1
            current.append(ch)
        elif ch == "," and depth == 0:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
    parts.append("".join(current).strip())
    return parts


def _parse_scalar(raw: str):
    raw = raw.strip()
    if raw.isdigit() or (raw.startswith("-") and raw[1:].isdigit()):
        return int(raw)
    if raw in ("true", "false"):
        return raw == "true"
    if raw.startswith('"') and raw.endswith('"'):
        return raw[1:-1]
    return raw  # bare identifier (npc.doubek, flag names, etc.) -> string


def _parse_structured_claim(structured: str) -> dict:
    parts = _split_top_level_args(structured)
    if len(parts) != 3:
        raise DlgSyntaxError(f"structured claim grant needs exactly 3 args: ({structured})")
    return {
        "subject": _parse_scalar(parts[0]),
        "predicate": _parse_scalar(parts[1]),
        "object": _parse_scalar(parts[2]),
    }


def compile_source(source: str) -> dict:
    nodes = {}
    start_node = None
    current_node_id = None
    current_node = None

    for raw_line in source.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue

        start_match = START_RE.match(line)
        if start_match:
            start_node = start_match.group("id")
            continue

        header_match = NODE_HEADER_RE.match(line)
        if header_match:
            current_node_id = header_match.group("id")
            current_node = {"lines": [], "choices": [], "claim_grants": [], "goto": None}
            nodes[current_node_id] = current_node
            continue

        if current_node is None:
            raise DlgSyntaxError(f"content outside any node: {line!r}")

        drift_match = DRIFT_RE.match(line)
        if drift_match:
            if not current_node["lines"]:
                raise DlgSyntaxError(f"drift: with no preceding line in node {current_node_id!r}")
            current_node["lines"][-1]["drift"] = {
                "text": drift_match.group("text"),
                "intent": drift_match.group("intent") or "doubt",
            }
            continue

        claim_match = CLAIM_GRANT_RE.match(line)
        if claim_match:
            grant = {"id": claim_match.group("id")}
            structured = claim_match.group("structured")
            if structured is not None:
                grant.update(_parse_structured_claim(structured))
            current_node["claim_grants"].append(grant)
            continue

        choice_match = CHOICE_RE.match(line)
        if choice_match:
            choice = {
                "text": choice_match.group("text"),
                "stance": choice_match.group("stance"),
                "target": choice_match.group("target"),
                "guard": None,
            }
            guard_text = choice_match.group("guard")
            if guard_text:
                choice["guard"] = parse_predicate(guard_text)
            current_node["choices"].append(choice)
            continue

        goto_match = GOTO_RE.match(line)
        if goto_match:
            current_node["goto"] = goto_match.group("target")
            continue

        speaker_match = SPEAKER_LINE_RE.match(line)
        if speaker_match:
            current_node["lines"].append(
                {
                    "speaker": speaker_match.group("speaker"),
                    "stance": speaker_match.group("stance"),
                    "text": speaker_match.group("text"),
                    "drift": None,
                }
            )
            continue

        raise DlgSyntaxError(f"unrecognized line in node {current_node_id!r}: {line!r}")

    if start_node is None:
        raise DlgSyntaxError("missing START directive")
    if start_node not in nodes:
        raise DlgSyntaxError(f"START node {start_node!r} not defined")

    return {"dlg_version": DLG_VERSION, "start_node": start_node, "nodes": nodes}


REPO_ROOT = Path(__file__).resolve().parent.parent
DIALOGUE_DIR = REPO_ROOT / "content" / "dialogue"


def check_all() -> int:
    """CI mode (no positional arg): compiles every content/dialogue/*.dlg
    file and reports pass/fail per file, without printing any JSON (the
    compiled graph is a build artifact, never committed - this mode only
    proves every committed .dlg source is syntactically valid)."""
    dlg_files = sorted(DIALOGUE_DIR.glob("*.dlg"))
    if not dlg_files:
        print(f"dlgc: no .dlg files found under {DIALOGUE_DIR}", file=sys.stderr)
        return 1

    failures = []
    for path in dlg_files:
        try:
            compile_source(path.read_text())
        except DlgSyntaxError as e:
            failures.append(f"{path.relative_to(REPO_ROOT)}: {e}")

    if failures:
        print("dlgc: FAILED")
        for f in failures:
            print(f"  - {f}")
        return 1

    print(f"dlgc: OK ({len(dlg_files)} scene(s) compiled)")
    return 0


def main() -> int:
    if len(sys.argv) == 1:
        return check_all()
    if len(sys.argv) != 2:
        print("usage: dlgc.py [path/to/scene.dlg]", file=sys.stderr)
        return 1
    path = Path(sys.argv[1])
    try:
        graph = compile_source(path.read_text())
    except DlgSyntaxError as e:
        print(f"dlgc: {path}: {e}", file=sys.stderr)
        return 1
    print(json.dumps(graph, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())

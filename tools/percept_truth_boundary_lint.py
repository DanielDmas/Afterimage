#!/usr/bin/env python3
"""Static check: nothing under src/percept/ references a src/sim/ class
by name (master_plan.md §5.2's non-negotiable architecture boundary:
"PerceptRenderer has read-only access to TruthSim ... nothing in the
percept path can mutate truth"). GDScript's global class_name mechanism
means sim-layer classes (TruthSim, Actor, ...) are usable from anywhere
without an explicit import statement, so a plain "import" scan wouldn't
catch a violation - this scans for the class names themselves as
whole-word identifiers in percept-side *code*. Comment lines and inline
comments are stripped first, so a doc comment that merely *mentions* a
sim class name for explanation (several already do, deliberately) is not
a false positive.

The denylist is derived from every `class_name X` declaration found
under src/sim/ at scan time, not hardcoded - it stays correct
automatically as the sim layer grows in later passes, with zero ongoing
maintenance here.

Usage: python3 tools/percept_truth_boundary_lint.py
Exit code 0 = no violations. Nonzero = at least one, printed as
"path:line: message".
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SIM_DIR = REPO_ROOT / "src" / "sim"
PERCEPT_DIR = REPO_ROOT / "src" / "percept"

_CLASS_NAME_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)")


def _strip_comment(line: str) -> str:
    """Strips a full-line or trailing '#' comment. Does not special-case
    a '#' inside a string literal - not a concern for this codebase's
    actual content, and simplicity here is worth more than handling a
    case that doesn't occur (see module doc's scope)."""
    idx = line.find("#")
    return line if idx == -1 else line[:idx]


def find_sim_class_names(sim_dir: Path) -> set:
    names = set()
    for path in sorted(sim_dir.rglob("*.gd")):
        for line in path.read_text().splitlines():
            match = _CLASS_NAME_RE.match(line)
            if match:
                names.add(match.group(1))
    return names


def find_violations(percept_dir: Path, forbidden_names: set) -> list:
    violations = []
    patterns = {name: re.compile(r"\b" + re.escape(name) + r"\b") for name in forbidden_names}
    for path in sorted(percept_dir.rglob("*.gd")):
        for line_no, raw_line in enumerate(path.read_text().splitlines(), start=1):
            code = _strip_comment(raw_line)
            for name, pattern in patterns.items():
                if pattern.search(code):
                    rel = path.relative_to(REPO_ROOT)
                    violations.append(
                        "{}:{}: references forbidden truth-layer class '{}'".format(rel, line_no, name)
                    )
    return violations


def main() -> int:
    if not PERCEPT_DIR.is_dir():
        print("percept_truth_boundary_lint: {} does not exist yet, nothing to check".format(PERCEPT_DIR))
        return 0

    forbidden = find_sim_class_names(SIM_DIR)
    if not forbidden:
        print(
            "percept_truth_boundary_lint: no class_name declarations found under src/sim/"
            " - suspicious, failing closed"
        )
        return 1

    violations = find_violations(PERCEPT_DIR, forbidden)
    if violations:
        print("percept_truth_boundary_lint: FAILED")
        for v in violations:
            print("  {}".format(v))
        return 1

    print(
        "percept_truth_boundary_lint: OK ({} forbidden truth-layer class names checked, 0 violations)".format(
            len(forbidden)
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

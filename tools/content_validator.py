#!/usr/bin/env python3
"""Content validator v0 (tech_guidelines.md D7/§5.1, roadmap.md M4's fuller
"Content validator v1" is a later, richer pass): validates every mission
package under content/missions/*/mission.json against
tools/schemas/mission.schema.json.

Deliberately hand-rolled rather than depending on a third-party jsonschema
library: this project keeps CI dependencies minimal (see
tools/percept_truth_boundary_lint.py, also stdlib-only), and the JSON-Schema
subset actually used by mission.schema.json (type, required, properties,
additionalProperties, enum, minimum, maximum, pattern, items) is small
enough to implement directly and keep versioned alongside the schema itself.

Scope explicitly NOT covered here (deferred to roadmap.md M4's "Content
validator v1 (IDs, reachability, calendar lint)" AC, "seeded broken content
fails CI"):
  - Cross-file ID resolution (tech_guidelines §5.2) — there is exactly one
    ID field in the v1 schema (a mission's own id) and nothing yet
    references another mission's ID, so there is nothing to resolve.
  - Fairness Charter validation (FairnessAuditor, Pass 12) — that class
    lives in GDScript and validates live op-shaped objects; running it
    against raw deck JSON is a content-pipeline integration step for a
    later pass once dramatic_intent/fairness_tags are added to the deck
    schema (a versioned schema migration, per D7 - not silently bolted on
    here).
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = REPO_ROOT / "tools" / "schemas" / "mission.schema.json"
MISSIONS_DIR = REPO_ROOT / "content" / "missions"


def validate_against_schema(instance: object, schema: dict, path: str = "$") -> list:
    """Returns a list of human-readable violation strings; empty means
    valid. Implements only the JSON-Schema draft-07 keywords
    mission.schema.json actually uses - not a general-purpose validator."""
    violations = []

    schema_type = schema.get("type")
    if schema_type is not None and not _matches_type(instance, schema_type):
        violations.append(f"{path}: expected type '{schema_type}', got {type(instance).__name__}")
        return violations  # further checks assume the type already matches

    if schema_type == "object":
        violations.extend(_validate_object(instance, schema, path))
    elif schema_type == "array":
        violations.extend(_validate_array(instance, schema, path))
    elif schema_type == "string":
        violations.extend(_validate_string(instance, schema, path))
    elif schema_type in ("integer", "number"):
        violations.extend(_validate_number(instance, schema, path))

    enum = schema.get("enum")
    if enum is not None and instance not in enum:
        violations.append(f"{path}: value {instance!r} is not one of {enum!r}")

    return violations


def _matches_type(instance: object, schema_type: str) -> bool:
    if schema_type == "object":
        return isinstance(instance, dict)
    if schema_type == "array":
        return isinstance(instance, list)
    if schema_type == "string":
        return isinstance(instance, str)
    if schema_type == "integer":
        # bool is a subclass of int in Python; JSON booleans must not pass
        # as integers, matching JSON Schema's own type distinction.
        return isinstance(instance, int) and not isinstance(instance, bool)
    if schema_type == "number":
        return isinstance(instance, (int, float)) and not isinstance(instance, bool)
    if schema_type == "boolean":
        return isinstance(instance, bool)
    return True


def _validate_object(instance: dict, schema: dict, path: str) -> list:
    violations = []
    for required_key in schema.get("required", []):
        if required_key not in instance:
            violations.append(f"{path}: missing required property '{required_key}'")

    properties = schema.get("properties", {})
    if schema.get("additionalProperties") is False:
        for key in instance:
            if key not in properties:
                violations.append(f"{path}: unexpected property '{key}'")

    for key, sub_schema in properties.items():
        if key in instance:
            violations.extend(validate_against_schema(instance[key], sub_schema, f"{path}.{key}"))

    return violations


def _validate_array(instance: list, schema: dict, path: str) -> list:
    violations = []
    item_schema = schema.get("items")
    if item_schema is not None:
        for i, item in enumerate(instance):
            violations.extend(validate_against_schema(item, item_schema, f"{path}[{i}]"))
    return violations


def _validate_string(instance: str, schema: dict, path: str) -> list:
    violations = []
    pattern = schema.get("pattern")
    if pattern is not None and re.match(pattern, instance) is None:
        violations.append(f"{path}: value {instance!r} does not match pattern '{pattern}'")
    return violations


def _validate_number(instance, schema: dict, path: str) -> list:
    violations = []
    minimum = schema.get("minimum")
    if minimum is not None and instance < minimum:
        violations.append(f"{path}: value {instance!r} is below minimum {minimum!r}")
    maximum = schema.get("maximum")
    if maximum is not None and instance > maximum:
        violations.append(f"{path}: value {instance!r} exceeds maximum {maximum!r}")
    return violations


def find_mission_files(missions_dir: Path) -> list:
    return sorted(missions_dir.glob("*/mission.json"))


def main() -> int:
    if not SCHEMA_PATH.exists():
        print(f"content_validator: schema not found at {SCHEMA_PATH}", file=sys.stderr)
        return 1
    schema = json.loads(SCHEMA_PATH.read_text())

    if not MISSIONS_DIR.exists():
        print(f"content_validator: no missions directory at {MISSIONS_DIR}", file=sys.stderr)
        return 1

    mission_files = find_mission_files(MISSIONS_DIR)
    if not mission_files:
        print("content_validator: no mission.json files found under content/missions/", file=sys.stderr)
        return 1

    all_violations = []
    for mission_file in mission_files:
        rel_path = mission_file.relative_to(REPO_ROOT)
        try:
            instance = json.loads(mission_file.read_text())
        except json.JSONDecodeError as e:
            all_violations.append(f"{rel_path}: invalid JSON ({e})")
            continue
        violations = validate_against_schema(instance, schema)
        for v in violations:
            all_violations.append(f"{rel_path} {v}")

    if all_violations:
        print("content_validator: FAILED")
        for v in all_violations:
            print(f"  - {v}")
        return 1

    print(f"content_validator: OK ({len(mission_files)} mission package(s) validated)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

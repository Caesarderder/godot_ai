#!/usr/bin/env python3
"""Validate Caesar Loop schemas, examples, and protocol cross-links."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / "schemas"
TEMPLATES = ROOT / "assets" / "templates"

EXAMPLES = {
    "run-spec.json": "run-spec.schema.json",
    "host-capabilities.json": "host-capabilities.schema.json",
    "progress.json": "progress.schema.json",
    "evidence.json": "evidence.schema.json",
    "finding.json": "finding.schema.json",
    "iteration-result.json": "iteration-result.schema.json",
}

WHOLE_GAME_DIMENSION_IDS = {
    "assets_modeling",
    "materials_shaders_lighting",
    "motion_vfx",
    "ui_ux",
    "interaction_camera_physics",
    "gameplay_levels_ai",
    "balance_economy_progression",
    "narrative_content",
    "audio",
    "learning_replay",
    "accessibility_localization",
    "correctness_data_lifecycle",
    "performance_stability",
}


class ValidationError(Exception):
    pass


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"{path}: {exc}") from exc


def resolve_pointer(document: Any, pointer: str) -> Any:
    value = document
    for part in pointer.lstrip("#/").split("/"):
        if not part:
            continue
        value = value[part.replace("~1", "/").replace("~0", "~")]
    return value


def resolve_ref(ref: str, schema: dict[str, Any], schema_path: Path) -> tuple[dict[str, Any], Path]:
    if ref.startswith("#"):
        return resolve_pointer(schema, ref), schema_path
    target_name, _, pointer = ref.partition("#")
    target_path = (schema_path.parent / target_name).resolve()
    if SCHEMAS.resolve() not in target_path.parents:
        raise ValidationError(f"{schema_path}: external ref escapes schemas: {ref}")
    target = load_json(target_path)
    return (resolve_pointer(target, f"#{pointer}") if pointer else target), target_path


def matches_type(value: Any, expected: str) -> bool:
    checks = {
        "object": lambda item: isinstance(item, dict),
        "array": lambda item: isinstance(item, list),
        "string": lambda item: isinstance(item, str),
        "integer": lambda item: isinstance(item, int) and not isinstance(item, bool),
        "number": lambda item: isinstance(item, (int, float)) and not isinstance(item, bool),
        "boolean": lambda item: isinstance(item, bool),
        "null": lambda item: item is None,
    }
    return checks[expected](value)


def validate(
    value: Any,
    schema: dict[str, Any],
    schema_path: Path,
    location: str = "$",
    root_schema: dict[str, Any] | None = None,
    root_path: Path | None = None,
) -> None:
    if root_schema is None:
        root_schema = schema
    if root_path is None:
        root_path = schema_path
    if "$ref" in schema:
        ref = schema["$ref"]
        if ref.startswith("#"):
            target = resolve_pointer(root_schema, ref)
            validate(value, target, root_path, location, root_schema, root_path)
        else:
            target, target_path = resolve_ref(ref, schema, schema_path)
            target_root = load_json(target_path)
            validate(value, target, target_path, location, target_root, target_path)
        return

    for item_schema in schema.get("allOf", []):
        validate(value, item_schema, schema_path, location, root_schema, root_path)

    if "if" in schema:
        condition_matches = True
        try:
            validate(value, schema["if"], schema_path, location, root_schema, root_path)
        except ValidationError:
            condition_matches = False
        branch = schema.get("then") if condition_matches else schema.get("else")
        if branch is not None:
            validate(value, branch, schema_path, location, root_schema, root_path)

    if "const" in schema and value != schema["const"]:
        raise ValidationError(f"{location}: expected constant {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        raise ValidationError(f"{location}: {value!r} not in enum")

    expected = schema.get("type")
    if expected:
        allowed = expected if isinstance(expected, list) else [expected]
        if not any(matches_type(value, item) for item in allowed):
            raise ValidationError(f"{location}: expected type {allowed}, got {type(value).__name__}")

    if isinstance(value, dict):
        required = schema.get("required", [])
        missing = [key for key in required if key not in value]
        if missing:
            raise ValidationError(f"{location}: missing required keys {missing}")
        properties = schema.get("properties", {})
        additional = schema.get("additionalProperties", True)
        for key, item in value.items():
            if key in properties:
                validate(
                    item,
                    properties[key],
                    schema_path,
                    f"{location}.{key}",
                    root_schema,
                    root_path,
                )
            elif isinstance(additional, dict):
                validate(item, additional, schema_path, f"{location}.{key}", root_schema, root_path)
            elif additional is False:
                raise ValidationError(f"{location}: unexpected key {key!r}")

    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            raise ValidationError(f"{location}: too few items")
        if "maxItems" in schema and len(value) > schema["maxItems"]:
            raise ValidationError(f"{location}: too many items")
        if schema.get("uniqueItems") and len({json.dumps(item, sort_keys=True) for item in value}) != len(value):
            raise ValidationError(f"{location}: duplicate items")
        prefix = schema.get("prefixItems", [])
        for index, item_schema in enumerate(prefix):
            if index < len(value):
                validate(
                    value[index],
                    item_schema,
                    schema_path,
                    f"{location}[{index}]",
                    root_schema,
                    root_path,
                )
        items = schema.get("items")
        if isinstance(items, dict):
            for index, item in enumerate(value[len(prefix) :], start=len(prefix)):
                validate(item, items, schema_path, f"{location}[{index}]", root_schema, root_path)
        elif items is False and len(value) > len(prefix):
            raise ValidationError(f"{location}: additional array items are forbidden")

    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            raise ValidationError(f"{location}: string is too short")
        if "pattern" in schema and not re.search(schema["pattern"], value):
            raise ValidationError(f"{location}: value does not match {schema['pattern']!r}")

    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            raise ValidationError(f"{location}: value below minimum")
        if "maximum" in schema and value > schema["maximum"]:
            raise ValidationError(f"{location}: value above maximum")


def validate_cross_links(run_spec: dict[str, Any]) -> None:
    scenario_ids = {item["scenario_id"] for item in run_spec["scenarios"]}
    scenario_map = {item["scenario_id"]: item for item in run_spec["scenarios"]}
    gate_ids = {item["gate_id"] for item in run_spec["quality_gates"]}
    strict_variant = run_spec.get("contract_variant") == "caesar-awesome"
    if strict_variant and "quality_dimensions" not in run_spec:
        raise ValidationError(
            "caesar-awesome RunSpec requires the complete whole-game quality ledger"
        )
    dimension_ids: set[str] = set()
    covered_gates: set[str] = set()
    for dimension in run_spec.get("quality_dimensions", []):
        dimension_id = dimension["dimension_id"]
        if dimension_id in dimension_ids:
            raise ValidationError(f"duplicate quality dimension: {dimension_id}")
        dimension_ids.add(dimension_id)
        linked_gates = set(dimension["gate_ids"])
        unknown = linked_gates - gate_ids
        if unknown:
            raise ValidationError(
                f"quality dimension {dimension_id} references unknown gates: {sorted(unknown)}"
            )
        if dimension["applicability"] == "not_applicable" and linked_gates:
            raise ValidationError(
                f"not-applicable quality dimension {dimension_id} must not reference gates"
            )
        covered_gates.update(linked_gates)
    if strict_variant and dimension_ids != WHOLE_GAME_DIMENSION_IDS:
        raise ValidationError(
            "quality dimensions must account for the complete whole-game ledger: "
            f"missing={sorted(WHOLE_GAME_DIMENSION_IDS - dimension_ids)}, "
            f"unknown={sorted(dimension_ids - WHOLE_GAME_DIMENSION_IDS)}"
        )
    required_gates = {
        item["gate_id"] for item in run_spec["quality_gates"] if item["required"]
    }
    if strict_variant and (missing := required_gates - covered_gates):
        raise ValidationError(
            f"required gates are missing from quality dimensions: {sorted(missing)}"
        )
    for gate in run_spec["quality_gates"]:
        unknown = set(gate["scenario_ids"]) - scenario_ids
        if unknown:
            raise ValidationError(f"gate {gate['gate_id']} references unknown scenarios: {sorted(unknown)}")
        if (
            gate["required"]
            and gate["grader"] in ("model", "mixed")
            and gate.get("independent_critic") is not True
        ):
            raise ValidationError(
                f"required {gate['grader']} gate {gate['gate_id']} must set "
                "independent_critic=true"
            )
    for scenario in run_spec["scenarios"]:
        unknown = set(scenario["gate_ids"]) - gate_ids
        if unknown:
            raise ValidationError(
                f"scenario {scenario['scenario_id']} references unknown gates: {sorted(unknown)}"
            )
        stimulus_ids = {item["stimulus_id"] for item in scenario["stimulus"]}
        observation_ids = {item["observation_id"] for item in scenario["observations"]}
        case_ids: set[str] = set()
        for case in scenario["coverage_matrix"]:
            if case["case_id"] in case_ids:
                raise ValidationError(
                    f"scenario {scenario['scenario_id']} has duplicate case_id {case['case_id']}"
                )
            case_ids.add(case["case_id"])
            unknown_stimuli = set(case["stimulus_ids"]) - stimulus_ids
            unknown_observations = set(case["observation_ids"]) - observation_ids
            if unknown_stimuli or unknown_observations:
                raise ValidationError(
                    f"scenario {scenario['scenario_id']} coverage {case['case_id']} "
                    f"has unknown stimuli={sorted(unknown_stimuli)} "
                    f"observations={sorted(unknown_observations)}"
                )
        if scenario["scenario_kind"] == "focused_feature":
            if scenario["setup"]["execution_surface"] != "dedicated_test_scene":
                raise ValidationError(
                    f"focused scenario {scenario['scenario_id']} must use dedicated_test_scene"
                )
            if scenario["execution_policy"]["preferred_mode"] != "single_run_matrix":
                raise ValidationError(
                    f"focused scenario {scenario['scenario_id']} must prefer single_run_matrix"
                )
        elif scenario["setup"]["execution_surface"] != "main_scene":
            raise ValidationError(
                f"integration scenario {scenario['scenario_id']} must use main_scene"
            )
    integration_ids = set(run_spec["integration_policy"]["scenario_ids"])
    unknown_integration = integration_ids - scenario_ids
    wrong_kind = {
        scenario_id
        for scenario_id in integration_ids & scenario_ids
        if scenario_map[scenario_id]["scenario_kind"] != "whole_path_integration"
    }
    if unknown_integration or wrong_kind:
        raise ValidationError(
            "integration_policy must reference whole_path_integration scenarios: "
            f"unknown={sorted(unknown_integration)}, wrong_kind={sorted(wrong_kind)}"
        )
    focused = {
        item["scenario_id"]
        for item in run_spec["scenarios"]
        if item["scenario_kind"] == "focused_feature"
    }
    if not focused:
        raise ValidationError("RunSpec requires at least one focused_feature scenario")


def validate_markdown_links() -> None:
    markdown_files = [
        ROOT / "SKILL.md",
        *sorted((ROOT / "commands").rglob("*.md")),
        *sorted((ROOT / "profiles").rglob("*.md")),
        *sorted((ROOT / "references").rglob("*.md")),
    ]
    pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
    for path in markdown_files:
        text = path.read_text(encoding="utf-8")
        for target in pattern.findall(text):
            if target.startswith(("http://", "https://", "#")):
                continue
            relative = target.split("#", 1)[0]
            if relative and not (path.parent / relative).resolve().exists():
                raise ValidationError(f"{path}: broken local link {target}")


def validate_instance(path: Path, schema_name: str) -> dict[str, Any]:
    value = load_json(path)
    schema_path = SCHEMAS / schema_name
    schema = load_json(schema_path)
    validate(value, schema, schema_path)
    return value


LEDGER_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
OPEN_FINDING_STATES = {"open", "in_progress", "blocked"}
TERMINAL_STATES = {
    "completed",
    "blocked",
    "human_required",
    "capability_unavailable",
    "budget_exhausted",
    "no_material_progress",
    "regression_limit",
    "user_stopped",
    "failed",
}


def is_independent_child_critic_evidence(evidence: dict[str, Any]) -> bool:
    grader = evidence.get("grader", {})
    return (
        evidence.get("evidence_type") == "model_critique"
        and grader.get("kind") == "model"
        and grader.get("independence") == "independent"
        and bool(str(grader.get("agent_thread_id", "")).strip())
    )


def evidence_set_satisfies_gate(
    gate: dict[str, Any], records: list[dict[str, Any]]
) -> bool:
    grader = gate["grader"]
    kinds = {record.get("grader", {}).get("kind") for record in records}
    if grader == "mixed":
        return bool(kinds.intersection({"code", "runtime", "diff"})) and any(
            is_independent_child_critic_evidence(record) for record in records
        )
    if grader == "model":
        return any(is_independent_child_critic_evidence(record) for record in records)
    return grader in kinds


def validate_ledger_id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not LEDGER_ID_RE.fullmatch(value):
        raise ValidationError(f"{label}: invalid ledger id {value!r}")
    return value


def validate_run_dir(run_dir: Path) -> None:
    run_dir = run_dir.resolve()
    run_spec_path = run_dir / "run-spec.json"
    progress_path = run_dir / "progress.json"
    run_spec = validate_instance(run_spec_path, "run-spec.schema.json")
    progress = validate_instance(progress_path, "progress.schema.json")
    validate_cross_links(run_spec)
    run_id = run_spec["run_id"]
    if progress["run_id"] != run_id:
        raise ValidationError("RunSpec and Progress run_id do not match")
    if run_spec.get("contract_variant") == "caesar-awesome":
        if "continuation_anchor" not in progress:
            raise ValidationError(
                "caesar-awesome Progress requires continuation_anchor; update the "
                "RunSpec through loop-spec to migrate a legacy run"
            )
        expected_anchor = {
            "goal": run_spec["goal"],
            "scope": run_spec["constraints"]["scope"],
            "in_scope_dimensions": sorted(
                dimension["dimension_id"]
                for dimension in run_spec["quality_dimensions"]
                if dimension["applicability"] == "in_scope"
            ),
        }
        for key, expected in expected_anchor.items():
            if progress["continuation_anchor"][key] != expected:
                raise ValidationError(
                    f"Progress.continuation_anchor.{key} drifted from RunSpec"
                )
    gate_ids = {item["gate_id"] for item in run_spec["quality_gates"]}
    gate_states = set(progress["gate_status"])
    if gate_states != gate_ids:
        raise ValidationError(
            "Progress gate_status must exactly match RunSpec gates: "
            f"missing={sorted(gate_ids - gate_states)}, unknown={sorted(gate_states - gate_ids)}"
        )
    if not set(progress["frozen_gates"]) <= gate_ids:
        raise ValidationError("Progress frozen_gates references unknown gates")

    artifact_specs = (
        ("evidence", "evidence.schema.json"),
        ("findings", "finding.schema.json"),
        ("iterations", "iteration-result.schema.json"),
    )
    counts: dict[str, int] = {}
    ledgers: dict[str, dict[str, dict[str, Any]]] = {}
    for directory, schema_name in artifact_specs:
        paths = sorted((run_dir / directory).glob("*.json"))
        counts[directory] = len(paths)
        ledgers[directory] = {}
        for path in paths:
            value = validate_instance(path, schema_name)
            if value["run_id"] != run_id:
                raise ValidationError(f"{path}: run_id does not match {run_id}")
            if "gate_id" in value and value["gate_id"] not in gate_ids:
                raise ValidationError(f"{path}: unknown gate_id {value['gate_id']}")
            if directory == "evidence":
                artifact_id = validate_ledger_id(value["evidence_id"], f"{path}: evidence_id")
            elif directory == "findings":
                artifact_id = validate_ledger_id(value["finding_id"], f"{path}: finding_id")
            else:
                artifact_id = f"iteration-{value['iteration']:04d}"
            if path.stem != artifact_id:
                raise ValidationError(
                    f"{path}: filename must exactly match artifact identity {artifact_id}.json"
                )
            if artifact_id in ledgers[directory]:
                raise ValidationError(f"{path}: duplicate artifact identity {artifact_id}")
            ledgers[directory][artifact_id] = value

    evidence = ledgers["evidence"]
    findings = ledgers["findings"]
    iterations = ledgers["iterations"]
    gate_map = {gate["gate_id"]: gate for gate in run_spec["quality_gates"]}
    scenario_ids = {scenario["scenario_id"] for scenario in run_spec["scenarios"]}
    scenario_map = {scenario["scenario_id"]: scenario for scenario in run_spec["scenarios"]}
    for evidence_id, item in evidence.items():
        gate = gate_map[item["gate_id"]]
        if item["scenario_id"] not in scenario_ids:
            raise ValidationError(
                f"Evidence {evidence_id} references unknown scenario {item['scenario_id']}"
            )
        if item["scenario_id"] not in gate["scenario_ids"]:
            raise ValidationError(
                f"Evidence {evidence_id} scenario is not linked to gate {item['gate_id']}"
            )
        if item["claim"] != gate["claim"]:
            raise ValidationError(
                f"Evidence {evidence_id} claim does not match gate {item['gate_id']}"
            )
        scenario = scenario_map[item["scenario_id"]]
        expected_cases = {case["case_id"] for case in scenario["coverage_matrix"]}
        actual_cases = {case["case_id"] for case in item["case_results"]}
        if len(actual_cases) != len(item["case_results"]) or actual_cases != expected_cases:
            raise ValidationError(
                f"Evidence {evidence_id} case coverage must exactly match scenario "
                f"{item['scenario_id']}: missing={sorted(expected_cases - actual_cases)}, "
                f"unknown={sorted(actual_cases - expected_cases)}"
            )
        required_manifest = set(scenario["execution_policy"]["artifact_manifest"])
        actual_manifest = set(item["artifact_manifest"])
        if item["result"] in ("pass", "directional") and not required_manifest <= actual_manifest:
            raise ValidationError(
                f"Evidence {evidence_id} lacks required artifact manifest items: "
                f"{sorted(required_manifest - actual_manifest)}"
            )
        if item["result"] == "pass" and any(
            case["result"] != "pass" for case in item["case_results"]
        ):
            raise ValidationError(
                f"Evidence {evidence_id} cannot pass while a coverage case did not pass"
            )
    progress_evidence = [
        validate_ledger_id(item, "Progress.evidence_ledger")
        for item in progress["evidence_ledger"]
    ]
    progress_findings = [
        validate_ledger_id(item, "Progress.open_findings")
        for item in progress["open_findings"]
    ]
    if set(progress_evidence) != set(evidence):
        raise ValidationError(
            "Progress.evidence_ledger must exactly match Evidence files: "
            f"missing={sorted(set(evidence) - set(progress_evidence))}, "
            f"dangling={sorted(set(progress_evidence) - set(evidence))}"
        )
    actual_open = {
        finding_id
        for finding_id, finding in findings.items()
        if finding["status"] in OPEN_FINDING_STATES
    }
    if set(progress_findings) != actual_open:
        raise ValidationError(
            "Progress.open_findings must exactly match open Finding files: "
            f"missing={sorted(actual_open - set(progress_findings))}, "
            f"dangling={sorted(set(progress_findings) - actual_open)}"
        )
    for gate_id in progress["frozen_gates"]:
        if progress["gate_status"][gate_id] != "pass":
            raise ValidationError(f"frozen gate {gate_id} must have pass status")
    for gate_id, status in progress["gate_status"].items():
        passing = [
            item
            for item in evidence.values()
            if item["gate_id"] == gate_id
            and item["valid_through_revision"] == progress["revision"]
            and item["result"] == "pass"
            and item["freshness"] == "current"
        ]
        if status == "pass" and not passing:
            raise ValidationError(
                f"passing gate {gate_id} lacks current passing Evidence at "
                f"revision {progress['revision']}"
            )
        if status == "pass" and not evidence_set_satisfies_gate(
            gate_map[gate_id], passing
        ):
            raise ValidationError(
                f"passing gate {gate_id} lacks a grader-matching Evidence set; "
                "mixed gates require deterministic and independent child-agent evidence"
            )
    for finding_id, finding in findings.items():
        for evidence_id in finding["evidence_ids"]:
            validate_ledger_id(evidence_id, f"Finding {finding_id}.evidence_ids")
            if evidence_id not in evidence:
                raise ValidationError(
                    f"Finding {finding_id} references missing Evidence {evidence_id}"
                )
    ordered_iterations = sorted(
        (value["iteration"], value) for value in iterations.values()
    )
    if [number for number, _value in ordered_iterations] != list(
        range(1, len(ordered_iterations) + 1)
    ):
        raise ValidationError("Iteration files must form one contiguous sequence starting at 1")
    if progress["iteration"] != len(ordered_iterations):
        raise ValidationError(
            f"Progress.iteration={progress['iteration']} does not match "
            f"Iteration files={len(ordered_iterations)}"
        )
    for number, iteration in ordered_iterations:
        for evidence_id in iteration["evidence_ids"]:
            validate_ledger_id(evidence_id, f"Iteration {number}.evidence_ids")
            if evidence_id not in evidence:
                raise ValidationError(
                    f"Iteration {number} references missing Evidence {evidence_id}"
                )
        for finding_id in (*iteration["resolved_findings"], *iteration["new_findings"]):
            validate_ledger_id(finding_id, f"Iteration {number}.finding_ids")
            if finding_id not in findings:
                raise ValidationError(
                    f"Iteration {number} references missing Finding {finding_id}"
                )
        unresolved = [
            finding_id
            for finding_id in iteration["resolved_findings"]
            if findings[finding_id]["status"] in OPEN_FINDING_STATES
        ]
        if unresolved:
            raise ValidationError(
                f"Iteration {number} claims still-open findings are resolved: {unresolved}"
            )

    if progress["state"] == "completed":
        required = {
            gate["gate_id"] for gate in run_spec["quality_gates"] if gate["required"]
        }
        not_passed = sorted(
            gate_id
            for gate_id in required
            if progress["gate_status"].get(gate_id) != "pass"
        )
        if not_passed or progress_findings:
            raise ValidationError(
                "completed run violates gate/finding invariants: "
                f"not_passed={not_passed}, open_findings={progress_findings}"
            )
        for gate_id in sorted(required):
            if not any(
                item["gate_id"] == gate_id
                and item["valid_through_revision"] == progress["revision"]
                and item["result"] == "pass"
                and item["freshness"] == "current"
                for item in evidence.values()
            ):
                raise ValidationError(
                    f"completed run lacks current passing Evidence for {gate_id} "
                    f"at revision {progress['revision']}"
                )
        integration_scenarios = set(run_spec["integration_policy"]["scenario_ids"])
        covered_integration = {
            item["scenario_id"]
            for item in evidence.values()
            if item["scenario_id"] in integration_scenarios
            and item["valid_through_revision"] == progress["revision"]
            and item["result"] == "pass"
            and item["freshness"] == "current"
        }
        if covered_integration != integration_scenarios:
            raise ValidationError(
                "completed run lacks current passing integration Evidence for scenarios: "
                f"{sorted(integration_scenarios - covered_integration)}"
            )

    host_path = run_dir / "host-capabilities.json"
    if host_path.exists():
        validate_instance(host_path, "host-capabilities.schema.json")
    print(
        f"Caesar Loop run validation: OK ({run_id}; "
        f"evidence={counts['evidence']}, findings={counts['findings']}, "
        f"iterations={counts['iterations']})"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--run-dir",
        type=Path,
        help="Validate a Caesar Loop run directory after validating the protocol bundle.",
    )
    args = parser.parse_args()
    required_docs = [
        ROOT / "SKILL.md",
        ROOT / "references" / "loop-guide.md",
        ROOT / "references" / "protocol.md",
        ROOT / "references" / "test-scenario-authoring.md",
    ]
    for path in required_docs:
        if not path.is_file():
            raise ValidationError(f"missing required protocol file: {path}")
    validate_markdown_links()

    for schema_path in sorted(SCHEMAS.glob("*.schema.json")):
        schema = load_json(schema_path)
        if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
            raise ValidationError(f"{schema_path}: unsupported or missing $schema")
        if not schema.get("$id") or schema.get("type") != "object":
            raise ValidationError(f"{schema_path}: missing $id or object root")

    for example_name, schema_name in EXAMPLES.items():
        example_path = TEMPLATES / example_name
        schema_path = SCHEMAS / schema_name
        example = load_json(example_path)
        schema = load_json(schema_path)
        validate(example, schema, schema_path)
        if example_name == "run-spec.json":
            validate_cross_links(example)
        print(f"OK {example_path.relative_to(ROOT)}")

    print(f"Caesar Loop protocol validation: OK ({len(list(SCHEMAS.glob('*.schema.json')))} schemas)")
    if args.run_dir:
        validate_run_dir(args.run_dir)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidationError as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        raise SystemExit(1)

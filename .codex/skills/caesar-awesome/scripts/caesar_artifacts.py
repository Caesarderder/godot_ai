#!/usr/bin/env python3
"""Deterministic writer for Caesar knowledge nodes and Loop v2 artifacts."""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path.cwd().resolve()
SKILL_ROOT = Path(__file__).resolve().parents[1]
LOOP_ROOT = SKILL_ROOT
LOOP_VALIDATOR = SKILL_ROOT / "scripts" / "validate_loop_protocol.py"
SCHEMAS = SKILL_ROOT / "schemas"
DOCS_LINT = ROOT / "tools" / "docs_lint.py"
SCHEMA_VERSION = "caesar-loop/v2"
RUN_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]+$")
ARTIFACT_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
KM_ID_RE = re.compile(r"^[a-z][a-z0-9-]*\.[a-z0-9][a-z0-9.-]*$")

ACTIVE_STATES = (
    "draft",
    "scenario_authoring",
    "baselining",
    "slice_building",
    "unit_looping",
    "integrating",
    "player_validating",
    "completion_review",
)
NON_SUCCESS_TERMINAL_STATES = (
    "blocked",
    "human_required",
    "capability_unavailable",
    "budget_exhausted",
    "no_material_progress",
    "regression_limit",
    "user_stopped",
    "failed",
)
TERMINAL_STATES = ("completed", *NON_SUCCESS_TERMINAL_STATES)
NEXT_STATE = {
    "draft": "scenario_authoring",
    "scenario_authoring": "baselining",
    "baselining": "slice_building",
    "slice_building": "unit_looping",
    "unit_looping": "integrating",
    "integrating": ("unit_looping", "player_validating", "completion_review"),
    "player_validating": ("unit_looping", "completion_review"),
    "completion_review": ("unit_looping", "completed"),
}


class ArtifactError(RuntimeError):
    pass


def now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def local_date() -> str:
    return datetime.now().astimezone().date().isoformat()


def repo_path(raw: str | Path, *, must_exist: bool = False) -> Path:
    path = Path(raw)
    path = path if path.is_absolute() else ROOT / path
    resolved = path.resolve()
    try:
        resolved.relative_to(ROOT)
    except ValueError as exc:
        raise ArtifactError(f"path must stay inside repository: {raw}") from exc
    if must_exist and not resolved.exists():
        raise ArtifactError(f"path does not exist: {resolved}")
    return resolved


def rel(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def load_json(path: Path, label: str = "JSON") -> dict[str, Any]:
    if not path.is_file():
        raise ArtifactError(f"missing {label}: {path}")
    if path.stat().st_size > 2_000_000:
        raise ArtifactError(f"{label} exceeds 2MB: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ArtifactError(f"invalid {label}: {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ArtifactError(f"{label} root must be an object: {path}")
    return value


def atomic_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(content, encoding="utf-8")
    temporary.replace(path)


def atomic_json(path: Path, value: dict[str, Any]) -> None:
    atomic_text(path, json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def run_command(command: list[str], label: str) -> None:
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=False)
    if result.returncode:
        detail = (result.stderr or result.stdout).strip()
        raise ArtifactError(f"{label} failed: {detail}")
    if result.stdout.strip():
        print(result.stdout.strip())


def loop_validator_module():
    spec = importlib.util.spec_from_file_location("caesar_loop_validator", LOOP_VALIDATOR)
    if spec is None or spec.loader is None:
        raise ArtifactError(f"cannot load validator: {LOOP_VALIDATOR}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def validate_value(value: dict[str, Any], schema_name: str) -> None:
    module = loop_validator_module()
    schema_path = SCHEMAS / schema_name
    schema = module.load_json(schema_path)
    try:
        module.validate(value, schema, schema_path)
    except module.ValidationError as exc:
        raise ArtifactError(f"{schema_name}: {exc}") from exc


def validate_run(run_dir: Path) -> None:
    run_command(
        [sys.executable, str(LOOP_VALIDATOR), "--run-dir", str(run_dir)],
        "Caesar Loop validation",
    )


def rollback_write(paths: dict[Path, bytes | None], operation) -> None:
    try:
        operation()
    except Exception:
        for path, previous in paths.items():
            if previous is None:
                path.unlink(missing_ok=True)
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(previous)
        raise


def snapshot(*paths: Path) -> dict[Path, bytes | None]:
    return {path: path.read_bytes() if path.is_file() else None for path in paths}


def single_line(value: Any, name: str) -> str:
    text = str(value).strip()
    if not text or "\n" in text or "\r" in text:
        raise ArtifactError(f"{name} must be a non-empty single line")
    return text


def artifact_id(value: Any, name: str) -> str:
    value = single_line(value, name)
    if not ARTIFACT_ID_RE.fullmatch(value):
        raise ArtifactError(f"{name} must match {ARTIFACT_ID_RE.pattern}")
    return value


def ledger_path(run_dir: Path, directory: str, value: Any, name: str) -> Path:
    identifier = artifact_id(value, name)
    path = (run_dir / directory / f"{identifier}.json").resolve()
    try:
        path.relative_to((run_dir / directory).resolve())
    except ValueError as exc:
        raise ArtifactError(f"{name} escapes its ledger directory") from exc
    return path


def require_active(progress: dict[str, Any], operation: str) -> None:
    if progress["state"] in TERMINAL_STATES:
        raise ArtifactError(
            f"{operation} is forbidden after terminal state {progress['state']}; "
            "terminal runs are immutable"
        )


def string_list(value: Any, name: str, *, non_empty: bool = False) -> list[str]:
    if not isinstance(value, list) or (non_empty and not value):
        raise ArtifactError(f"{name} must be {'a non-empty ' if non_empty else 'an '}array")
    return [single_line(item, name) for item in value]


def render_node(spec: dict[str, Any]) -> str:
    required = (
        "km_id",
        "km_type",
        "domain",
        "status",
        "owner",
        "source_of_truth",
        "validated_by",
        "tags",
        "related",
        "title",
        "body",
    )
    missing = [key for key in required if key not in spec]
    if missing:
        raise ArtifactError(f"node spec missing keys: {missing}")
    km_id = single_line(spec["km_id"], "km_id")
    km_type = single_line(spec["km_type"], "km_type")
    if not KM_ID_RE.fullmatch(km_id) or km_id.split(".", 1)[0] != km_type:
        raise ArtifactError("km_id is invalid or does not match km_type")
    scalar = {
        "domain": single_line(spec["domain"], "domain"),
        "status": single_line(spec["status"], "status"),
        "owner": single_line(spec["owner"], "owner"),
        "title": single_line(spec["title"], "title"),
    }
    body = spec["body"]
    if not isinstance(body, str) or not body.strip():
        raise ArtifactError("body must be a non-empty string")
    lists = {
        key: string_list(spec[key], key, non_empty=key in ("source_of_truth", "validated_by", "tags"))
        for key in ("source_of_truth", "validated_by", "tags", "related")
    }
    lines = [
        "---",
        f"km_id: {km_id}",
        f"km_type: {km_type}",
        f"domain: {scalar['domain']}",
        f"status: {scalar['status']}",
        f"owner: {scalar['owner']}",
        f"last_verified: {local_date()}",
    ]
    for key in ("source_of_truth", "validated_by", "tags", "related"):
        lines.append(f"{key}:")
        lines.extend(f"  - {item}" for item in lists[key])
    lines.extend(("---", "", f"# {scalar['title']}", "", body.strip(), ""))
    return "\n".join(lines)


def emit_template(args: argparse.Namespace) -> None:
    path = repo_path(args.output)
    if path.exists():
        raise ArtifactError(f"template output already exists: {path}")
    if path.suffix != ".json":
        raise ArtifactError("template output must use .json")
    if args.kind == "node":
        value = {
            "km_id": "reference.replace-me",
            "km_type": "reference",
            "domain": "workflow",
            "status": "draft",
            "owner": "maintainers",
            "source_of_truth": ["replace-with-repository-path"],
            "validated_by": ["command:python3 tools/docs_lint.py"],
            "tags": ["workflow:replace-me"],
            "related": [],
            "title": "Replace Me",
            "body": "Replace with durable Markdown facts.",
        }
    else:
        template_name = {
            "run-spec": "run-spec.json",
            "host": "host-capabilities.json",
            "evidence": "evidence.json",
            "finding": "finding.json",
            "iteration": "iteration-result.json",
        }[args.kind]
        value = load_json(LOOP_ROOT / "assets" / "templates" / template_name, f"{args.kind} template")
    atomic_json(path, value)
    print(f"template emitted: {rel(path)} ({args.kind})")


def node_upsert(args: argparse.Namespace) -> None:
    path = repo_path(args.path)
    if path.suffix != ".md" or ROOT / "docs" not in (path, *path.parents):
        raise ArtifactError("managed knowledge nodes must be Markdown under docs/")
    spec = load_json(repo_path(args.spec, must_exist=True), "node spec")
    if path.exists():
        expected = getattr(args, "expect_km_id", None)
        actual = extract_km_id(path)
        if not expected:
            raise ArtifactError("updating an existing node requires --expect-km-id")
        if expected != actual or spec.get("km_id") != actual:
            raise ArtifactError(
                f"managed node identity is immutable: existing={actual}, "
                f"expected={expected}, input={spec.get('km_id')}"
            )
    content = render_node(spec)
    previous = snapshot(path)

    def operation() -> None:
        atomic_text(path, content)
        run_command([sys.executable, str(DOCS_LINT)], "docs lint")

    rollback_write(previous, operation)
    print(f"node upserted: {rel(path)} ({spec['km_id']})")


def extract_km_id(path: Path) -> str:
    match = re.search(r"^km_id:\s*(\S+)\s*$", path.read_text(encoding="utf-8"), re.MULTILINE)
    if not match:
        raise ArtifactError(f"cannot find km_id: {path}")
    return match.group(1)


def node_remove(args: argparse.Namespace) -> None:
    path = repo_path(args.path, must_exist=True)
    if path.suffix != ".md" or ROOT / "docs" not in (path, *path.parents):
        raise ArtifactError("managed knowledge nodes must be Markdown under docs/")
    actual = extract_km_id(path)
    if actual != args.expect_km_id:
        raise ArtifactError(f"km_id mismatch: expected {args.expect_km_id}, found {actual}")
    if args.confirm != f"delete:{actual}":
        raise ArtifactError(f"confirmation must equal delete:{actual}")
    if not args.reason.strip():
        raise ArtifactError("deletion reason is required")
    inbound: list[str] = []
    patterns = (f"  - {actual}", f"[KM:{actual}]")
    for candidate in sorted((ROOT / "docs").rglob("*.md")):
        if candidate.resolve() == path:
            continue
        text = candidate.read_text(encoding="utf-8")
        if any(pattern in text for pattern in patterns):
            inbound.append(rel(candidate))
    if inbound:
        raise ArtifactError(f"node has inbound references: {inbound}")
    previous = snapshot(path)

    def operation() -> None:
        path.unlink()
        run_command([sys.executable, str(DOCS_LINT)], "docs lint")

    rollback_write(previous, operation)
    print(f"node removed: {rel(path)} ({actual}); reason={args.reason.strip()}")


def normalized_run_spec(payload: dict[str, Any]) -> dict[str, Any]:
    result = dict(payload)
    result["schema_version"] = SCHEMA_VERSION
    result["contract_variant"] = "caesar-awesome"
    validate_value(result, "run-spec.schema.json")
    return result


def in_scope_dimensions(run_spec: dict[str, Any]) -> list[str]:
    return sorted(
        dimension["dimension_id"]
        for dimension in run_spec.get("quality_dimensions", [])
        if dimension["applicability"] == "in_scope"
    )


def continuation_anchor(
    run_spec: dict[str, Any], next_action: str, *, updated_at: str | None = None
) -> dict[str, Any]:
    return {
        "goal": run_spec["goal"],
        "scope": list(run_spec["constraints"]["scope"]),
        "in_scope_dimensions": in_scope_dimensions(run_spec),
        "next_action": single_line(next_action, "next_action"),
        "updated_at": updated_at or now(),
    }


def initial_progress(run_spec: dict[str, Any], revision: str) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "run_id": run_spec["run_id"],
        "state": "draft",
        "revision": single_line(revision, "revision"),
        "iteration": 0,
        "active_work_unit": None,
        "frozen_gates": [],
        "gate_status": {gate["gate_id"]: "pending" for gate in run_spec["quality_gates"]},
        "open_findings": [],
        "evidence_ledger": [],
        "continuation_anchor": continuation_anchor(
            run_spec,
            "Audit host capabilities and author the first required Test Scenario.",
        ),
        "decisions": [
            {
                "at": now(),
                "decision": "Run initialized through caesar-awesome managed artifact tool.",
                "evidence_ids": [],
            }
        ],
    }


def loop_init(args: argparse.Namespace) -> None:
    run_dir = repo_path(args.run_dir)
    if run_dir.exists() and any(run_dir.iterdir()):
        raise ArtifactError(f"run directory is not empty: {run_dir}")
    run_spec = normalized_run_spec(load_json(repo_path(args.spec, must_exist=True), "RunSpec input"))
    if not RUN_ID_RE.fullmatch(run_spec["run_id"]):
        raise ArtifactError("invalid run_id")
    for candidate in ROOT.rglob("run-spec.json"):
        candidate_dir = candidate.parent.resolve()
        if candidate_dir == run_dir.resolve():
            continue
        if not (candidate_dir / "progress.json").is_file() or not all(
            (candidate_dir / name).is_dir()
            for name in ("evidence", "findings", "iterations")
        ):
            continue
        try:
            existing = load_json(candidate, "existing RunSpec")
        except ArtifactError:
            continue
        if existing.get("run_id") == run_spec["run_id"]:
            raise ArtifactError(
                f"run_id already exists at {rel(candidate_dir)}: {run_spec['run_id']}"
            )
    progress = initial_progress(run_spec, args.revision)
    validate_value(progress, "progress.schema.json")
    created = not run_dir.exists()
    initial_entries = set(run_dir.iterdir()) if run_dir.exists() else set()
    try:
        run_dir.mkdir(parents=True, exist_ok=True)
        for directory in ("evidence", "findings", "iterations"):
            (run_dir / directory).mkdir()
        atomic_json(run_dir / "run-spec.json", run_spec)
        atomic_json(run_dir / "progress.json", progress)
        validate_run(run_dir)
    except Exception:
        if created:
            shutil.rmtree(run_dir, ignore_errors=True)
        else:
            for path in sorted(
                (item for item in run_dir.iterdir() if item not in initial_entries),
                reverse=True,
            ):
                if path.is_dir():
                    shutil.rmtree(path)
                else:
                    path.unlink(missing_ok=True)
        raise
    print(f"loop initialized: {rel(run_dir)} ({run_spec['run_id']})")


def run_files(run_dir_raw: str) -> tuple[Path, dict[str, Any], dict[str, Any]]:
    run_dir = repo_path(run_dir_raw, must_exist=True)
    run_spec = load_json(run_dir / "run-spec.json", "RunSpec")
    progress = load_json(run_dir / "progress.json", "Progress")
    if run_spec.get("run_id") != progress.get("run_id"):
        raise ArtifactError("RunSpec and Progress run_id mismatch")
    return run_dir, run_spec, progress


def loop_spec(args: argparse.Namespace) -> None:
    run_dir, old_spec, progress = run_files(args.run_dir)
    require_active(progress, "loop-spec")
    if old_spec["run_id"] != args.expect_run_id:
        raise ArtifactError("expect-run-id mismatch")
    if args.extend:
        extension = load_json(repo_path(args.extend, must_exist=True), "RunSpec extension")
        allowed_keys = {
            "scenarios",
            "quality_gates",
            "ownership",
            "dimension_gate_bindings",
        }
        unknown_keys = sorted(set(extension) - allowed_keys)
        if unknown_keys:
            raise ArtifactError(
                f"RunSpec extension contains unsupported keys: {unknown_keys}"
            )
        candidate = json.loads(json.dumps(old_spec))
        for key in ("scenarios", "quality_gates", "ownership"):
            additions = extension.get(key, [])
            if not isinstance(additions, list):
                raise ArtifactError(f"RunSpec extension {key} must be an array")
            if key == "scenarios":
                identity_key = "scenario_id"
            elif key == "quality_gates":
                identity_key = "gate_id"
            else:
                identity_key = None
            if identity_key:
                existing_ids = {item[identity_key] for item in candidate[key]}
                addition_ids = [item.get(identity_key) for item in additions if isinstance(item, dict)]
                duplicate_ids = sorted(
                    item_id for item_id in addition_ids if item_id in existing_ids
                )
                repeated_ids = sorted(
                    {item_id for item_id in addition_ids if addition_ids.count(item_id) > 1}
                )
                if duplicate_ids or repeated_ids:
                    raise ArtifactError(
                        f"RunSpec extension cannot replace or repeat {identity_key}: "
                        f"{sorted(set(duplicate_ids + repeated_ids))}"
                    )
            candidate[key].extend(additions)
        bindings = extension.get("dimension_gate_bindings", {})
        if not isinstance(bindings, dict):
            raise ArtifactError("RunSpec extension dimension_gate_bindings must be an object")
        dimensions = {
            item["dimension_id"]: item for item in candidate["quality_dimensions"]
        }
        known_gate_ids = {item["gate_id"] for item in candidate["quality_gates"]}
        for dimension_id, gate_ids in bindings.items():
            if dimension_id not in dimensions:
                raise ArtifactError(f"unknown quality dimension binding: {dimension_id}")
            if not isinstance(gate_ids, list) or not all(
                isinstance(gate_id, str) for gate_id in gate_ids
            ):
                raise ArtifactError(
                    f"quality dimension binding {dimension_id} must be an array of gate IDs"
                )
            unknown_gate_ids = sorted(set(gate_ids) - known_gate_ids)
            if unknown_gate_ids:
                raise ArtifactError(
                    f"quality dimension binding references unknown gates: {unknown_gate_ids}"
                )
            dimensions[dimension_id]["gate_ids"] = list(dict.fromkeys(
                [*dimensions[dimension_id]["gate_ids"], *gate_ids]
            ))
        candidate = normalized_run_spec(candidate)
    else:
        candidate = normalized_run_spec(
            load_json(repo_path(args.spec, must_exist=True), "RunSpec input")
        )
    if candidate["run_id"] != old_spec["run_id"]:
        raise ArtifactError("run_id is immutable")
    old_gates = set(progress["gate_status"])
    new_gates = {gate["gate_id"] for gate in candidate["quality_gates"]}
    removed = old_gates - new_gates
    protected = removed & (
        set(progress["frozen_gates"])
        | {gate for gate, state in progress["gate_status"].items() if state != "pending"}
    )
    if protected:
        raise ArtifactError(f"cannot remove evaluated or frozen gates: {sorted(protected)}")
    old_gate_map = {item["gate_id"]: item for item in old_spec["quality_gates"]}
    new_gate_map = {item["gate_id"]: item for item in candidate["quality_gates"]}
    changed_evaluated = sorted(
        gate_id
        for gate_id in old_gates & new_gates
        if old_gate_map[gate_id] != new_gate_map[gate_id]
        and progress["gate_status"][gate_id] not in ("pending", "stale")
    )
    old_scenarios = {item["scenario_id"]: item for item in old_spec["scenarios"]}
    new_scenarios = {item["scenario_id"]: item for item in candidate["scenarios"]}
    changed_scenarios = {
        scenario_id
        for scenario_id in set(old_scenarios) | set(new_scenarios)
        if old_scenarios.get(scenario_id) != new_scenarios.get(scenario_id)
    }
    for gate_id in old_gates & new_gates:
        referenced = set(old_gate_map[gate_id]["scenario_ids"]) | set(
            new_gate_map[gate_id]["scenario_ids"]
        )
        if (
            referenced & changed_scenarios
            and progress["gate_status"][gate_id] not in ("pending", "stale")
        ):
            changed_evaluated.append(gate_id)
    if changed_evaluated:
        raise ArtifactError(
            "mark evaluated gates/evidence stale before changing their contract: "
            f"{sorted(set(changed_evaluated))}"
        )
    progress["gate_status"] = {
        gate: progress["gate_status"].get(gate, "pending") for gate in sorted(new_gates)
    }
    previous_next_action = progress.get("continuation_anchor", {}).get(
        "next_action",
        progress.get("active_work_unit") or "Re-audit the upgraded RunSpec and select one bounded gap.",
    )
    progress["continuation_anchor"] = continuation_anchor(
        candidate, previous_next_action
    )
    progress["decisions"].append(
        {"at": now(), "decision": single_line(args.reason, "reason"), "evidence_ids": []}
    )
    paths = snapshot(run_dir / "run-spec.json", run_dir / "progress.json")

    def operation() -> None:
        atomic_json(run_dir / "run-spec.json", candidate)
        atomic_json(run_dir / "progress.json", progress)
        validate_run(run_dir)

    rollback_write(paths, operation)
    print(f"loop spec updated: {rel(run_dir)} ({candidate['run_id']})")


def host_set(args: argparse.Namespace) -> None:
    run_dir, _run_spec, progress = run_files(args.run_dir)
    require_active(progress, "host-set")
    payload = load_json(repo_path(args.input, must_exist=True), "HostCapabilities input")
    payload["schema_version"] = SCHEMA_VERSION
    payload["observed_at"] = payload.get("observed_at") or now()
    validate_value(payload, "host-capabilities.schema.json")
    path = run_dir / "host-capabilities.json"
    progress["decisions"].append(
        {"at": now(), "decision": single_line(args.reason, "reason"), "evidence_ids": []}
    )
    validate_value(progress, "progress.schema.json")
    paths = snapshot(path, run_dir / "progress.json")

    def operation() -> None:
        atomic_json(path, payload)
        atomic_json(run_dir / "progress.json", progress)
        validate_run(run_dir)

    rollback_write(paths, operation)
    print(f"host capabilities updated: {rel(path)}")


def revision_set(args: argparse.Namespace) -> None:
    run_dir, run_spec, progress = run_files(args.run_dir)
    require_active(progress, "revision-set")
    revision = single_line(args.revision, "revision")
    if revision == progress["revision"]:
        raise ArtifactError("revision-set requires a different revision")
    known_gates = set(progress["gate_status"])
    requested_gates = set(getattr(args, "affected_gate_id", []) or [])
    if getattr(args, "all_gates", False):
        requested_gates = known_gates
    if not requested_gates:
        raise ArtifactError(
            "revision-set requires --affected-gate-id or explicit --all-gates; "
            "do not invalidate unrelated evidence by default"
        )
    integration_scenarios = set(run_spec["integration_policy"]["scenario_ids"])
    integration_gates = {
        gate["gate_id"]
        for gate in run_spec["quality_gates"]
        if integration_scenarios.intersection(gate["scenario_ids"])
    }
    requested_gates.update(integration_gates)
    unknown_gates = requested_gates - known_gates
    if unknown_gates:
        raise ArtifactError(f"revision-set references unknown gates: {sorted(unknown_gates)}")
    evidence_paths: list[Path] = []
    evidence_values: list[tuple[Path, dict[str, Any]]] = []
    affected_gates: set[str] = set()
    carried_gates: set[str] = set()
    for evidence_id in progress["evidence_ledger"]:
        path = ledger_path(run_dir, "evidence", evidence_id, "evidence_id")
        evidence = load_json(path, "Evidence")
        if evidence["freshness"] == "current":
            if evidence["gate_id"] in requested_gates:
                evidence["freshness"] = "stale"
                affected_gates.add(evidence["gate_id"])
            else:
                evidence["valid_through_revision"] = revision
                carried_gates.add(evidence["gate_id"])
            validate_value(evidence, "evidence.schema.json")
            evidence_paths.append(path)
            evidence_values.append((path, evidence))
    for gate_id in requested_gates:
        progress["gate_status"][gate_id] = "stale"
        if gate_id in progress["frozen_gates"]:
            progress["frozen_gates"].remove(gate_id)
    progress["revision"] = revision
    progress["decisions"].append(
        {
            "at": now(),
            "decision": (
                f"{single_line(args.reason, 'reason')} "
                f"Affected gates={sorted(requested_gates)}; "
                f"carried gates={sorted(carried_gates)}."
            ),
            "evidence_ids": sorted(progress["evidence_ledger"]),
        }
    )
    validate_value(progress, "progress.schema.json")
    progress_path = run_dir / "progress.json"
    paths = snapshot(progress_path, *evidence_paths)

    def operation() -> None:
        for path, evidence in evidence_values:
            atomic_json(path, evidence)
        atomic_json(progress_path, progress)
        validate_run(run_dir)

    rollback_write(paths, operation)
    print(
        f"revision updated: {revision}; affected gates={sorted(affected_gates)}, "
        f"carried gates={sorted(carried_gates)}"
    )


def valid_transition(current: str, target: str) -> bool:
    if target in NON_SUCCESS_TERMINAL_STATES and current in ACTIVE_STATES:
        return True
    allowed = NEXT_STATE.get(current)
    return target == allowed or isinstance(allowed, tuple) and target in allowed


def evidence_records(run_dir: Path, progress: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        evidence_id: load_json(
            ledger_path(run_dir, "evidence", evidence_id, "evidence_id"),
            "Evidence",
        )
        for evidence_id in progress["evidence_ledger"]
    }


def gate_requires_independent_critic(gate: dict[str, Any]) -> bool:
    return bool(
        gate.get(
            "independent_critic",
            gate.get("grader") in ("model", "mixed"),
        )
    )


def uncovered_in_scope_dimensions(run_spec: dict[str, Any]) -> list[str]:
    required_gates = {
        gate["gate_id"] for gate in run_spec.get("quality_gates", []) if gate["required"]
    }
    return sorted(
        dimension["dimension_id"]
        for dimension in run_spec.get("quality_dimensions", [])
        if dimension["applicability"] == "in_scope"
        and not required_gates.intersection(dimension["gate_ids"])
    )


def is_independent_child_critic_evidence(evidence: dict[str, Any]) -> bool:
    grader = evidence.get("grader", {})
    return (
        evidence.get("evidence_type") == "model_critique"
        and grader.get("kind") == "model"
        and grader.get("independence") == "independent"
        and bool(str(grader.get("agent_thread_id", "")).strip())
    )


def evidence_ids(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    return list(value)


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


def transition_guard(
    run_dir: Path,
    run_spec: dict[str, Any],
    progress: dict[str, Any],
    target: str,
    revision: str,
    supplied_evidence: list[str],
) -> None:
    if revision != progress["revision"]:
        raise ArtifactError(
            "change revision before transition by staling and re-collecting affected evidence; "
            "a state transition cannot silently relabel the run"
        )
    records = evidence_records(run_dir, progress)
    for evidence_id in supplied_evidence:
        if evidence_id not in records:
            raise ArtifactError(f"transition references missing Evidence: {evidence_id}")
    current = {
        evidence_id: item
        for evidence_id, item in records.items()
        if item["valid_through_revision"] == revision and item["freshness"] == "current"
    }
    required_gates = {
        gate["gate_id"] for gate in run_spec["quality_gates"] if gate["required"]
    }

    if target == "scenario_authoring" and not (run_dir / "host-capabilities.json").is_file():
        raise ArtifactError("scenario_authoring requires a recorded HostCapabilities audit")
    if target == "baselining":
        placeholders = []
        for scenario in run_spec["scenarios"]:
            commands = (
                scenario.get("fast_review_route", {}).get("command", ""),
                scenario.get("strict_regression_route", {}).get("command", ""),
            )
            if (
                not scenario.get("reset")
                or any(
                    not command.strip()
                    or "project-specific" in command.lower()
                    or "replace-with" in command.lower()
                    for command in commands
                )
            ):
                placeholders.append(scenario["scenario_id"])
        covered_scenarios = {
            item["scenario_id"]
            for evidence_id, item in current.items()
            if evidence_id in supplied_evidence
            and item["result"] in ("pass", "directional")
        }
        required_scenarios = {
            scenario_id
            for gate in run_spec["quality_gates"]
            if gate["required"]
            for scenario_id in gate["scenario_ids"]
            if next(
                scenario
                for scenario in run_spec["scenarios"]
                if scenario["scenario_id"] == scenario_id
            )["scenario_kind"]
            == "focused_feature"
        }
        if placeholders or not required_scenarios <= covered_scenarios:
            raise ArtifactError(
                "baselining requires non-placeholder scenario routes and current validation "
                f"Evidence for every required scenario: placeholders={placeholders}, "
                f"missing_evidence={sorted(required_scenarios - covered_scenarios)}"
            )
    if target == "slice_building":
        covered = {item["gate_id"] for item in current.values()}
        if not required_gates <= covered:
            raise ArtifactError(
                "slice_building requires a current baseline or explicit unavailable Evidence "
                f"record for every required gate: {sorted(required_gates - covered)}"
            )
    if target == "unit_looping":
        playable = [
            item
            for item in current.values()
            if item["gate_id"] in required_gates
            and item["result"] == "pass"
            and item["evidence_type"] in ("build", "test", "runtime_state")
        ]
        if not playable:
            raise ArtifactError(
                "unit_looping requires current passing build/test/runtime evidence "
                "that the real playable path boots"
            )
    if target == "integrating":
        if progress["iteration"] < 1:
            raise ArtifactError("integrating requires at least one recorded IterationResult")
        if progress["active_work_unit"]:
            raise ArtifactError("integrating requires the active work unit to be closed")
        if any(status == "pending" for status in progress["gate_status"].values()):
            raise ArtifactError("integrating requires every gate to be evaluated")
    if target in ("player_validating", "completion_review"):
        automated = {
            gate["gate_id"]
            for gate in run_spec["quality_gates"]
            if gate["required"] and gate["grader"] != "human"
        }
        not_passed = sorted(
            gate_id for gate_id in automated if progress["gate_status"][gate_id] != "pass"
        )
        if not_passed:
            raise ArtifactError(
                f"{target} requires integrated automated/runtime gates to pass: {not_passed}"
            )
        if target == "completion_review":
            required_human = [
                gate["gate_id"]
                for gate in run_spec["quality_gates"]
                if gate["required"] and gate["grader"] == "human"
            ]
            if progress["state"] == "integrating" and required_human:
                raise ArtifactError(
                    "completion_review cannot bypass required human gates; "
                    f"use player_validating first: {required_human}"
                )
            if progress["state"] == "player_validating":
                unevaluated_human = [
                    gate_id
                    for gate_id in required_human
                    if progress["gate_status"][gate_id]
                    not in ("pass", "human_required", "unsupported")
                ]
                if unevaluated_human:
                    raise ArtifactError(
                        "completion_review requires target-player Evidence or an explicit "
                        f"unavailable result: {unevaluated_human}"
                    )


def completion_guard(
    run_spec: dict[str, Any], progress: dict[str, Any], run_dir: Path | None = None
) -> None:
    uncovered = uncovered_in_scope_dimensions(run_spec)
    if uncovered:
        raise ArtifactError(
            "completed requires a required gate for every in-scope quality "
            f"dimension: {uncovered}"
        )
    required = {gate["gate_id"] for gate in run_spec["quality_gates"] if gate["required"]}
    not_passed = sorted(gate for gate in required if progress["gate_status"].get(gate) != "pass")
    if not_passed:
        raise ArtifactError(f"completed requires all required gates pass: {not_passed}")
    if progress["open_findings"]:
        raise ArtifactError(f"completed requires no open findings: {progress['open_findings']}")
    if not progress["evidence_ledger"]:
        raise ArtifactError("completed requires current evidence ledger")
    if run_dir is not None:
        for gate_id in sorted(required):
            matches = []
            for evidence_id in progress["evidence_ledger"]:
                evidence = current_evidence(run_dir, evidence_id)
                if (
                    evidence["gate_id"] == gate_id
                    and evidence["valid_through_revision"] == progress["revision"]
                    and evidence["result"] == "pass"
                    and evidence["freshness"] == "current"
                ):
                    matches.append(evidence_id)
            if not matches:
                raise ArtifactError(
                    f"completed requires current passing evidence for {gate_id} "
                    f"at revision {progress['revision']}"
                )
            gate = next(
                item for item in run_spec["quality_gates"] if item["gate_id"] == gate_id
            )
            matching_records = [
                current_evidence(run_dir, evidence_id) for evidence_id in matches
            ]
            if not evidence_set_satisfies_gate(gate, matching_records):
                raise ArtifactError(
                    "completed requires a grader-matching Evidence set for "
                    f"{gate_id}; mixed gates require deterministic and independent "
                    "child-agent model evidence"
                )
        integration_scenarios = set(run_spec["integration_policy"]["scenario_ids"])
        covered_integration = set()
        for evidence_id in progress["evidence_ledger"]:
            evidence = current_evidence(run_dir, evidence_id)
            if (
                evidence["scenario_id"] in integration_scenarios
                and evidence["valid_through_revision"] == progress["revision"]
                and evidence["result"] == "pass"
                and evidence["freshness"] == "current"
            ):
                covered_integration.add(evidence["scenario_id"])
        if covered_integration != integration_scenarios:
            raise ArtifactError(
                "completed requires one current passing integration checkpoint for every "
                f"integration scenario: {sorted(integration_scenarios - covered_integration)}"
            )


def loop_transition(args: argparse.Namespace) -> None:
    run_dir, run_spec, progress = run_files(args.run_dir)
    current, target = progress["state"], args.state
    if not valid_transition(current, target):
        raise ArtifactError(f"invalid state transition: {current} -> {target}")
    revision = single_line(args.revision, "revision")
    transition_guard(
        run_dir, run_spec, progress, target, revision, args.evidence_id
    )
    if target == "completed":
        completion_guard(run_spec, progress, run_dir)
    progress["state"] = target
    progress["revision"] = revision
    progress["active_work_unit"] = args.active_unit
    progress["continuation_anchor"] = continuation_anchor(
        run_spec,
        args.active_unit or args.reason,
    )
    progress["decisions"].append(
        {"at": now(), "decision": single_line(args.reason, "reason"), "evidence_ids": args.evidence_id}
    )
    validate_value(progress, "progress.schema.json")
    paths = snapshot(run_dir / "progress.json")
    rollback_write(
        paths,
        lambda: (atomic_json(run_dir / "progress.json", progress), validate_run(run_dir)),
    )
    print(f"loop transitioned: {current} -> {target} ({rel(run_dir)})")


def work_unit_close(args: argparse.Namespace) -> None:
    """Close the current bounded work unit after its completion candidate is recorded."""
    run_dir, run_spec, progress = run_files(args.run_dir)
    require_active(progress, "work-unit-close")
    if progress["state"] != "unit_looping":
        raise ArtifactError("work-unit-close requires state=unit_looping")
    active_unit = str(progress.get("active_work_unit") or "").strip()
    if not active_unit:
        raise ArtifactError("work-unit-close requires a current active_work_unit")
    if progress["iteration"] < 1:
        raise ArtifactError("work-unit-close requires a recorded IterationResult")
    iteration_path = run_dir / "iterations" / f"iteration-{progress['iteration']:04d}.json"
    iteration = load_json(iteration_path, "IterationResult")
    if iteration.get("work_unit") != active_unit:
        raise ArtifactError(
            "latest IterationResult must belong to the current active_work_unit"
        )
    if iteration.get("status") != "completion_candidate":
        raise ArtifactError(
            "work-unit-close requires latest IterationResult status=completion_candidate"
        )
    if progress["open_findings"]:
        raise ArtifactError("work-unit-close requires no open Findings")
    progress["active_work_unit"] = None
    progress["continuation_anchor"] = continuation_anchor(
        run_spec,
        single_line(args.next_action or args.reason, "next action"),
    )
    progress["decisions"].append(
        {
            "at": now(),
            "decision": single_line(args.reason, "reason"),
            "evidence_ids": list(iteration.get("evidence_ids", [])),
        }
    )
    validate_value(progress, "progress.schema.json")
    paths = snapshot(run_dir / "progress.json")
    rollback_write(
        paths,
        lambda: (atomic_json(run_dir / "progress.json", progress), validate_run(run_dir)),
    )
    print(f"work unit closed: {active_unit} ({rel(run_dir)})")


def artifact_config(kind: str) -> tuple[str, str, str | None]:
    return {
        "evidence": ("evidence", "evidence.schema.json", "evidence_id"),
        "finding": ("findings", "finding.schema.json", "finding_id"),
        "iteration": ("iterations", "iteration-result.schema.json", None),
    }[kind]


def artifact_add(args: argparse.Namespace) -> None:
    run_dir, run_spec, progress = run_files(args.run_dir)
    require_active(progress, "artifact-add")
    payload = load_json(repo_path(args.input, must_exist=True), f"{args.kind} input")
    payload["schema_version"] = SCHEMA_VERSION
    payload["run_id"] = run_spec["run_id"]
    if args.kind == "evidence":
        payload["valid_through_revision"] = payload["revision"]
    directory, schema_name, id_key = artifact_config(args.kind)
    validate_value(payload, schema_name)
    if payload.get("gate_id") not in (None, *progress["gate_status"]):
        raise ArtifactError(f"unknown gate_id: {payload.get('gate_id')}")
    scenario_ids = {item["scenario_id"] for item in run_spec["scenarios"]}
    if args.kind == "evidence":
        artifact_id(payload["evidence_id"], "evidence_id")
        if payload["scenario_id"] not in scenario_ids:
            raise ArtifactError(f"unknown scenario_id: {payload['scenario_id']}")
        gate = next(
            item for item in run_spec["quality_gates"] if item["gate_id"] == payload["gate_id"]
        )
        if payload["scenario_id"] not in gate["scenario_ids"]:
            raise ArtifactError("Evidence scenario is not linked to its gate")
        if payload["claim"] != gate["claim"]:
            raise ArtifactError("Evidence claim must exactly match the current gate claim")
        if payload["freshness"] == "current" and payload["revision"] != progress["revision"]:
            raise ArtifactError("current Evidence revision must match Progress.revision")
    if args.kind == "finding":
        artifact_id(payload["finding_id"], "finding_id")
        missing_evidence = [
            item
            for item in payload["evidence_ids"]
            if not ledger_path(run_dir, "evidence", item, "evidence_id").is_file()
        ]
        if missing_evidence:
            raise ArtifactError(f"Finding references missing evidence: {missing_evidence}")
    if args.kind == "iteration":
        missing_evidence = [
            item
            for item in payload["evidence_ids"]
            if not ledger_path(run_dir, "evidence", item, "evidence_id").is_file()
        ]
        missing_findings = [
            item
            for item in (*payload["resolved_findings"], *payload["new_findings"])
            if not ledger_path(run_dir, "findings", item, "finding_id").is_file()
        ]
        if missing_evidence or missing_findings:
            raise ArtifactError(
                "Iteration references missing ledgers: "
                f"evidence={missing_evidence}, findings={missing_findings}"
            )
        unresolved = [
            item
            for item in payload["resolved_findings"]
            if load_json(
                ledger_path(run_dir, "findings", item, "finding_id"), "Finding"
            )["status"]
            in ("open", "in_progress", "blocked")
        ]
        not_open = [
            item
            for item in payload["new_findings"]
            if load_json(
                ledger_path(run_dir, "findings", item, "finding_id"), "Finding"
            )["status"]
            not in ("open", "in_progress", "blocked")
        ]
        if unresolved or not_open:
            raise ArtifactError(
                "Iteration finding claims disagree with Finding ledger: "
                f"still_open_resolved={unresolved}, closed_new={not_open}"
            )
    if args.kind == "iteration":
        artifact_name = f"iteration-{payload['iteration']:04d}"
        if payload["iteration"] != progress["iteration"] + 1:
            raise ArtifactError("iteration must increment Progress.iteration by exactly one")
        progress["iteration"] = payload["iteration"]
    else:
        artifact_name = payload[id_key]  # type: ignore[index]
    artifact_path = run_dir / directory / f"{artifact_name}.json"
    if artifact_path.exists():
        raise ArtifactError(f"append-only artifact already exists: {artifact_path}")
    if args.kind == "evidence":
        progress["evidence_ledger"].append(payload["evidence_id"])
    elif args.kind == "finding" and payload["status"] in ("open", "in_progress", "blocked"):
        progress["open_findings"].append(payload["finding_id"])
    validate_value(progress, "progress.schema.json")
    paths = snapshot(artifact_path, run_dir / "progress.json")

    def operation() -> None:
        atomic_json(artifact_path, payload)
        atomic_json(run_dir / "progress.json", progress)
        validate_run(run_dir)

    rollback_write(paths, operation)
    print(f"{args.kind} appended: {rel(artifact_path)}")


def current_evidence(run_dir: Path, evidence_id: str) -> dict[str, Any]:
    return load_json(
        ledger_path(run_dir, "evidence", evidence_id, "evidence_id"), "Evidence"
    )


def gate_set(args: argparse.Namespace) -> None:
    run_dir, run_spec, progress = run_files(args.run_dir)
    require_active(progress, "gate-set")
    if args.gate_id not in progress["gate_status"]:
        raise ArtifactError(f"unknown gate_id: {args.gate_id}")
    gate = next(item for item in run_spec["quality_gates"] if item["gate_id"] == args.gate_id)
    supplied_evidence_ids = evidence_ids(args.evidence_id)
    if args.status == "pass":
        if not supplied_evidence_ids:
            raise ArtifactError("passing a gate requires --evidence-id")
        required = {
            "run_id": run_spec["run_id"],
            "gate_id": args.gate_id,
            "valid_through_revision": progress["revision"],
            "result": "pass",
            "freshness": "current",
        }
        records = []
        for evidence_id in supplied_evidence_ids:
            evidence = current_evidence(run_dir, evidence_id)
            mismatch = {
                key: value for key, value in required.items() if evidence.get(key) != value
            }
            if mismatch:
                raise ArtifactError(
                    f"evidence {evidence_id} cannot pass gate; required values: {mismatch}"
                )
            records.append(evidence)
        if not evidence_set_satisfies_gate(gate, records):
            raise ArtifactError(
                f"passing {gate['grader']} gate requires a grader-matching Evidence set; "
                "mixed gates require deterministic code/runtime/diff evidence and "
                "independent child-agent model_critique evidence"
            )
        if gate.get("freeze_on_pass", True) and args.gate_id not in progress["frozen_gates"]:
            progress["frozen_gates"].append(args.gate_id)
    elif args.gate_id in progress["frozen_gates"] and args.status != "stale":
        raise ArtifactError("frozen gate may only become stale before re-evaluation")
    if args.status == "stale" and args.gate_id in progress["frozen_gates"]:
        progress["frozen_gates"].remove(args.gate_id)
    progress["gate_status"][args.gate_id] = args.status
    progress["decisions"].append(
        {
            "at": now(),
            "decision": single_line(args.reason, "reason"),
            "evidence_ids": supplied_evidence_ids,
        }
    )
    validate_value(progress, "progress.schema.json")
    paths = snapshot(run_dir / "progress.json")
    rollback_write(
        paths,
        lambda: (atomic_json(run_dir / "progress.json", progress), validate_run(run_dir)),
    )
    print(f"gate updated: {args.gate_id}={args.status}")


def evidence_stale(args: argparse.Namespace) -> None:
    run_dir, run_spec, progress = run_files(args.run_dir)
    require_active(progress, "evidence-stale")
    path = ledger_path(run_dir, "evidence", args.evidence_id, "evidence_id")
    evidence = load_json(path, "Evidence")
    if evidence["run_id"] != run_spec["run_id"]:
        raise ArtifactError("Evidence run_id mismatch")
    if evidence["freshness"] == "stale":
        raise ArtifactError("Evidence is already stale")
    evidence["freshness"] = "stale"
    gate_id = evidence["gate_id"]
    progress["gate_status"][gate_id] = "stale"
    if gate_id in progress["frozen_gates"]:
        progress["frozen_gates"].remove(gate_id)
    progress["decisions"].append(
        {
            "at": now(),
            "decision": single_line(args.reason, "reason"),
            "evidence_ids": [args.evidence_id],
        }
    )
    validate_value(evidence, "evidence.schema.json")
    validate_value(progress, "progress.schema.json")
    paths = snapshot(path, run_dir / "progress.json")

    def operation() -> None:
        atomic_json(path, evidence)
        atomic_json(run_dir / "progress.json", progress)
        validate_run(run_dir)

    rollback_write(paths, operation)
    print(f"evidence marked stale: {args.evidence_id}; gate={gate_id}")


def finding_set(args: argparse.Namespace) -> None:
    run_dir, run_spec, progress = run_files(args.run_dir)
    require_active(progress, "finding-set")
    path = ledger_path(run_dir, "findings", args.finding_id, "finding_id")
    finding = load_json(path, "Finding")
    if finding["run_id"] != run_spec["run_id"]:
        raise ArtifactError("Finding run_id mismatch")
    old_status = finding["status"]
    if args.status == "resolved":
        if not args.evidence_id:
            raise ArtifactError("resolved Finding requires --evidence-id")
        acceptance_evidence = []
        for evidence_id in args.evidence_id:
            evidence = current_evidence(run_dir, evidence_id)
            if (
                evidence["gate_id"] != finding["gate_id"]
                or evidence["valid_through_revision"] != progress["revision"]
                or evidence["result"] != "pass"
                or evidence["freshness"] != "current"
            ):
                raise ArtifactError(
                    "resolved Finding requires current passing Evidence for the "
                    f"same gate carried through the current revision: {evidence_id}"
                )
            acceptance_evidence.append(evidence_id)
        finding["evidence_ids"] = list(
            dict.fromkeys([*finding["evidence_ids"], *acceptance_evidence])
        )
    finding["status"] = args.status
    if args.blocked_by is not None:
        finding["blocked_by"] = args.blocked_by
    if args.next_change is not None:
        finding["next_change"] = args.next_change
    open_states = ("open", "in_progress", "blocked")
    open_ids = set(progress["open_findings"])
    if args.status in open_states:
        open_ids.add(args.finding_id)
    else:
        open_ids.discard(args.finding_id)
    progress["open_findings"] = sorted(open_ids)
    progress["decisions"].append(
        {
            "at": now(),
            "decision": single_line(args.reason, "reason"),
            "evidence_ids": args.evidence_id or finding["evidence_ids"],
        }
    )
    validate_value(finding, "finding.schema.json")
    validate_value(progress, "progress.schema.json")
    paths = snapshot(path, run_dir / "progress.json")

    def operation() -> None:
        atomic_json(path, finding)
        atomic_json(run_dir / "progress.json", progress)
        validate_run(run_dir)

    rollback_write(paths, operation)
    print(f"finding updated: {args.finding_id} {old_status}->{args.status}")


def sync(args: argparse.Namespace) -> None:
    run_dir = repo_path(args.run_dir, must_exist=True)
    validate_run(run_dir)
    command = [
        sys.executable,
        str(SKILL_ROOT / "scripts" / "workbench_hq.py"),
        "loop-sync",
        "--run-dir",
        str(run_dir),
    ]
    if args.task:
        command.extend(("--task", args.task))
    run_command(command, "Workbench loop-sync")
    print(f"loop synced: {rel(run_dir)}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    template = sub.add_parser("template", help="Emit a fixed JSON input template without overwriting.")
    template.add_argument(
        "--kind",
        required=True,
        choices=("node", "run-spec", "host", "evidence", "finding", "iteration"),
    )
    template.add_argument("--output", required=True)
    template.set_defaults(handler=emit_template)

    node = sub.add_parser("node-upsert", help="Create or replace a fixed-format docs node.")
    node.add_argument("--path", required=True)
    node.add_argument("--spec", required=True, help="JSON node specification.")
    node.add_argument("--expect-km-id", help="Required exact identity when updating an existing node.")
    node.set_defaults(handler=node_upsert)

    remove = sub.add_parser("node-remove", help="Delete an unreferenced docs node with exact confirmation.")
    remove.add_argument("--path", required=True)
    remove.add_argument("--expect-km-id", required=True)
    remove.add_argument("--reason", required=True)
    remove.add_argument("--confirm", required=True)
    remove.set_defaults(handler=node_remove)

    init = sub.add_parser("loop-init", help="Create a validated Loop run and Progress ledger.")
    init.add_argument("--run-dir", required=True)
    init.add_argument("--spec", required=True, help="RunSpec JSON; schema_version is tool-owned.")
    init.add_argument("--revision", required=True)
    init.set_defaults(handler=loop_init)

    spec = sub.add_parser("loop-spec", help="Update or safely extend RunSpec without changing run_id or protected gates.")
    spec.add_argument("--run-dir", required=True)
    spec_input = spec.add_mutually_exclusive_group(required=True)
    spec_input.add_argument("--spec", help="Complete replacement RunSpec input.")
    spec_input.add_argument(
        "--extend",
        help="Append-only JSON containing new scenarios, quality_gates, or ownership entries.",
    )
    spec.add_argument("--expect-run-id", required=True)
    spec.add_argument("--reason", required=True)
    spec.set_defaults(handler=loop_spec)

    host = sub.add_parser("host-set", help="Create or replace validated HostCapabilities.")
    host.add_argument("--run-dir", required=True)
    host.add_argument("--input", required=True)
    host.add_argument("--reason", required=True)
    host.set_defaults(handler=host_set)

    revision = sub.add_parser(
        "revision-set",
        help="Change revision, staling only declared affected gates and carrying unrelated Evidence.",
    )
    revision.add_argument("--run-dir", required=True)
    revision.add_argument("--revision", required=True)
    revision.add_argument("--reason", required=True)
    revision.add_argument(
        "--affected-gate-id",
        action="append",
        default=[],
        help="Gate invalidated by the changed surface; repeat for the exact impact set.",
    )
    revision.add_argument(
        "--all-gates",
        action="store_true",
        help="Explicitly invalidate every gate for a genuinely global change.",
    )
    revision.set_defaults(handler=revision_set)

    transition = sub.add_parser("loop-transition", help="Apply one legal Caesar Loop state transition.")
    transition.add_argument("--run-dir", required=True)
    transition.add_argument("--state", required=True, choices=(*ACTIVE_STATES, *TERMINAL_STATES))
    transition.add_argument("--revision", required=True)
    transition.add_argument("--active-unit")
    transition.add_argument("--reason", required=True)
    transition.add_argument("--evidence-id", action="append", default=[])
    transition.set_defaults(handler=loop_transition)

    close_unit = sub.add_parser(
        "work-unit-close",
        help="Close the active work unit after a completion-candidate IterationResult.",
    )
    close_unit.add_argument("--run-dir", required=True)
    close_unit.add_argument("--reason", required=True)
    close_unit.add_argument("--next-action")
    close_unit.set_defaults(handler=work_unit_close)

    artifact = sub.add_parser("artifact-add", help="Append Evidence, Finding, or IterationResult.")
    artifact.add_argument("--run-dir", required=True)
    artifact.add_argument("--kind", required=True, choices=("evidence", "finding", "iteration"))
    artifact.add_argument("--input", required=True)
    artifact.set_defaults(handler=artifact_add)

    gate = sub.add_parser("gate-set", help="Set one gate; pass requires current matching evidence.")
    gate.add_argument("--run-dir", required=True)
    gate.add_argument("--gate-id", required=True)
    gate.add_argument(
        "--status",
        required=True,
        choices=("pending", "pass", "fail", "stale", "not_run", "human_required", "unsupported"),
    )
    gate.add_argument("--evidence-id", action="append", default=[])
    gate.add_argument("--reason", required=True)
    gate.set_defaults(handler=gate_set)

    stale = sub.add_parser("evidence-stale", help="Mark Evidence and its gate stale without deletion.")
    stale.add_argument("--run-dir", required=True)
    stale.add_argument("--evidence-id", required=True)
    stale.add_argument("--reason", required=True)
    stale.set_defaults(handler=evidence_stale)

    finding = sub.add_parser("finding-set", help="Update a Finding while preserving its ledger record.")
    finding.add_argument("--run-dir", required=True)
    finding.add_argument("--finding-id", required=True)
    finding.add_argument(
        "--status",
        required=True,
        choices=("open", "in_progress", "resolved", "accepted_risk", "blocked", "rejected"),
    )
    finding.add_argument("--blocked-by")
    finding.add_argument("--next-change")
    finding.add_argument(
        "--evidence-id",
        action="append",
        default=[],
        help="Current passing acceptance Evidence; required when status=resolved.",
    )
    finding.add_argument("--reason", required=True)
    finding.set_defaults(handler=finding_set)

    validate_parser = sub.add_parser("validate", help="Validate a complete Loop run.")
    validate_parser.add_argument("--run-dir", required=True)
    validate_parser.set_defaults(handler=lambda args: validate_run(repo_path(args.run_dir, must_exist=True)))

    sync_parser = sub.add_parser("sync", help="Validate and project Loop state into docs/HQ/HTML.")
    sync_parser.add_argument("--run-dir", required=True)
    sync_parser.add_argument("--task")
    sync_parser.set_defaults(handler=sync)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    args.handler(args)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ArtifactError, OSError, KeyError, ValueError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        raise SystemExit(1)

#!/usr/bin/env python3
"""Focused tests for Caesar Awesome managed artifact invariants."""

from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).with_name("caesar_artifacts.py")
SPEC = importlib.util.spec_from_file_location("caesar_artifacts", SCRIPT)
assert SPEC and SPEC.loader
artifacts = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(artifacts)


class ManagedArtifactTests(unittest.TestCase):
    def init_run(self, temp_dir: Path, revision: str = "test-revision") -> Path:
        run_dir = temp_dir / "run"
        artifacts.loop_init(
            Namespace(
                run_dir=str(run_dir),
                spec=str(
                    artifacts.LOOP_ROOT / "assets" / "templates" / "run-spec.json"
                ),
                revision=revision,
            )
        )
        return run_dir

    def evidence_input(
        self,
        temp_dir: Path,
        *,
        evidence_id: str = "ev_example_001",
        gate_id: str = "gate_weapon_function",
        revision: str = "test-revision",
        result: str = "pass",
    ) -> Path:
        payload = json.loads(
            (
                artifacts.LOOP_ROOT / "assets" / "templates" / "evidence.json"
            ).read_text(encoding="utf-8")
        )
        run_spec = json.loads(
            (
                artifacts.LOOP_ROOT / "assets" / "templates" / "run-spec.json"
            ).read_text(encoding="utf-8")
        )
        gate = next(item for item in run_spec["quality_gates"] if item["gate_id"] == gate_id)
        scenario = next(
            item
            for item in run_spec["scenarios"]
            if item["scenario_id"] in gate["scenario_ids"]
        )
        case_result = "pass" if result == "pass" else result
        payload.update(
            evidence_id=evidence_id,
            gate_id=gate_id,
            claim=gate["claim"],
            scenario_id=scenario["scenario_id"],
            execution_id=f"{scenario['scenario_id']}_{evidence_id}",
            revision=revision,
            valid_through_revision=revision,
            result=result,
            freshness="current",
            case_results=[
                {
                    "case_id": case["case_id"],
                    "result": case_result,
                    "assertions": ["test assertion result"],
                    "artifacts": ["test artifact"],
                }
                for case in scenario["coverage_matrix"]
            ],
            artifact_manifest=scenario["execution_policy"]["artifact_manifest"],
        )
        if gate.get("independent_critic"):
            payload["evidence_type"] = "model_critique"
            payload["grader"] = {
                "kind": "model",
                "name": "independent-test-critic",
                "version": "1",
                "independence": "independent",
                "agent_thread_id": "critic-thread-1",
            }
        path = temp_dir / f"{evidence_id}-input.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_node_render_owns_frontmatter_and_date(self) -> None:
        rendered = artifacts.render_node(
            {
                "km_id": "reference.managed-example",
                "km_type": "reference",
                "domain": "workflow",
                "status": "active",
                "owner": "maintainers",
                "source_of_truth": ["README.md"],
                "validated_by": ["command:python3 tools/docs_lint.py"],
                "tags": ["workflow:task-routing"],
                "related": ["map.workflows"],
                "title": "Managed Example",
                "body": "Tool-owned body.",
            }
        )
        self.assertIn("km_id: reference.managed-example", rendered)
        self.assertIn("last_verified:", rendered)
        self.assertIn("# Managed Example", rendered)

    def test_invalid_node_id_is_rejected(self) -> None:
        with self.assertRaises(artifacts.ArtifactError):
            artifacts.render_node(
                {
                    "km_id": "workflow.Wrong",
                    "km_type": "workflow",
                    "domain": "workflow",
                    "status": "active",
                    "owner": "maintainers",
                    "source_of_truth": ["README.md"],
                    "validated_by": ["command:test"],
                    "tags": ["workflow:test"],
                    "related": [],
                    "title": "Wrong",
                    "body": "Wrong.",
                }
            )

    def test_state_machine_rejects_skips(self) -> None:
        self.assertTrue(artifacts.valid_transition("draft", "scenario_authoring"))
        self.assertFalse(artifacts.valid_transition("draft", "unit_looping"))
        self.assertFalse(artifacts.valid_transition("draft", "completed"))
        self.assertTrue(artifacts.valid_transition("unit_looping", "human_required"))
        self.assertTrue(artifacts.valid_transition("completion_review", "unit_looping"))

    def test_completed_guard_requires_evidence_and_passed_gates(self) -> None:
        run_spec = {"quality_gates": [{"gate_id": "gate_a", "required": True}]}
        progress = {
            "gate_status": {"gate_a": "pending"},
            "open_findings": [],
            "evidence_ledger": [],
        }
        with self.assertRaises(artifacts.ArtifactError):
            artifacts.completion_guard(run_spec, progress)

    def test_initial_progress_derives_gate_map(self) -> None:
        run_spec = {
            "run_id": "managed_run",
            "goal": "Keep the managed run anchored.",
            "constraints": {"scope": ["managed test scope"]},
            "quality_dimensions": [],
            "quality_gates": [{"gate_id": "gate_a"}, {"gate_id": "gate_b"}],
        }
        progress = artifacts.initial_progress(run_spec, "rev-1")
        self.assertEqual({"gate_a": "pending", "gate_b": "pending"}, progress["gate_status"])
        self.assertEqual("draft", progress["state"])
        self.assertEqual("Keep the managed run anchored.", progress["continuation_anchor"]["goal"])

    def test_loop_spec_append_only_extension_adds_new_scenario_and_gate(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = self.init_run(temp_dir)
            current = json.loads((run_dir / "run-spec.json").read_text(encoding="utf-8"))
            scenario = json.loads(json.dumps(current["scenarios"][0]))
            scenario["scenario_id"] = "scenario_extension_test"
            gate = json.loads(json.dumps(current["quality_gates"][0]))
            gate["gate_id"] = "gate_extension_test"
            gate["scenario_ids"] = ["scenario_extension_test"]
            scenario["gate_ids"] = ["gate_extension_test"]
            extension_path = temp_dir / "extension.json"
            dimension_id = next(
                item["dimension_id"]
                for item in current["quality_dimensions"]
                if "gate_weapon_function" in item["gate_ids"]
            )
            extension_path.write_text(
                json.dumps({
                    "scenarios": [scenario],
                    "quality_gates": [gate],
                    "dimension_gate_bindings": {
                        dimension_id: ["gate_extension_test"],
                    },
                }),
                encoding="utf-8",
            )
            artifacts.loop_spec(
                Namespace(
                    run_dir=str(run_dir),
                    spec=None,
                    extend=str(extension_path),
                    expect_run_id=current["run_id"],
                    reason="Append a bounded test unit.",
                )
            )
            updated = json.loads((run_dir / "run-spec.json").read_text(encoding="utf-8"))
            progress = json.loads((run_dir / "progress.json").read_text(encoding="utf-8"))
            self.assertIn(
                "scenario_extension_test",
                {item["scenario_id"] for item in updated["scenarios"]},
            )
            self.assertEqual("pending", progress["gate_status"]["gate_extension_test"])
            with self.assertRaisesRegex(artifacts.ArtifactError, "cannot replace"):
                artifacts.loop_spec(
                    Namespace(
                        run_dir=str(run_dir),
                        spec=None,
                        extend=str(extension_path),
                        expect_run_id=current["run_id"],
                        reason="Duplicate IDs must fail.",
                    )
                )

    def test_work_unit_close_clears_only_matching_completion_candidate(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            run_dir = self.init_run(Path(directory))
            progress_path = run_dir / "progress.json"
            progress = json.loads(progress_path.read_text(encoding="utf-8"))
            progress.update(
                state="unit_looping",
                iteration=1,
                active_work_unit="factory HUD hierarchy",
            )
            progress_path.write_text(json.dumps(progress), encoding="utf-8")
            iteration = {
                "schema_version": artifacts.SCHEMA_VERSION,
                "run_id": "example_weapon_fixture",
                "iteration": 1,
                "work_unit": "factory HUD hierarchy",
                "status": "completion_candidate",
                "changed_files": ["project-a/game/scripts/ui/factory_screen.gd"],
                "evidence_ids": [],
                "resolved_findings": [],
                "new_findings": [],
                "failed_checks": [],
                "rejected_approaches": [],
                "next_action": "Run integration.",
                "blocker": None,
            }
            iteration_path = run_dir / "iterations" / "iteration-0001.json"
            iteration_path.write_text(json.dumps(iteration), encoding="utf-8")

            artifacts.work_unit_close(
                Namespace(
                    run_dir=str(run_dir),
                    reason="Focused candidate accepted.",
                    next_action="Run integration.",
                )
            )

            closed = json.loads(progress_path.read_text(encoding="utf-8"))
            self.assertIsNone(closed["active_work_unit"])
            self.assertEqual("Run integration.", closed["continuation_anchor"]["next_action"])

    def test_work_unit_close_rejects_unverified_iteration(self) -> None:
        progress = {
            "state": "unit_looping",
            "active_work_unit": "factory HUD hierarchy",
            "iteration": 1,
        }
        with patch.object(artifacts, "run_files", return_value=(Path("run"), {}, progress)):
            with patch.object(
                artifacts,
                "load_json",
                return_value={
                    "work_unit": "factory HUD hierarchy",
                    "status": "verification_requested",
                },
            ):
                with self.assertRaisesRegex(artifacts.ArtifactError, "completion_candidate"):
                    artifacts.work_unit_close(
                        Namespace(
                            run_dir="run",
                            reason="Not verified.",
                            next_action=None,
                        )
                    )

    def test_completion_rejects_uncovered_in_scope_dimension(self) -> None:
        run_spec = {
            "quality_dimensions": [
                {
                    "dimension_id": "audio",
                    "applicability": "in_scope",
                    "gate_ids": [],
                }
            ],
            "quality_gates": [{"gate_id": "gate_a", "required": True}],
        }
        progress = {
            "gate_status": {"gate_a": "pass"},
            "open_findings": [],
            "evidence_ledger": ["ev_a"],
        }
        with self.assertRaisesRegex(artifacts.ArtifactError, "in-scope quality"):
            artifacts.completion_guard(run_spec, progress)

    def test_independent_gate_rejects_self_review_evidence(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = self.init_run(temp_dir)
            evidence_path = self.evidence_input(
                temp_dir,
                evidence_id="ev_self_review",
                gate_id="gate_weapon_presentation",
            )
            payload = json.loads(evidence_path.read_text(encoding="utf-8"))
            payload["grader"] = {
                "kind": "model",
                "name": "maker-self-review",
                "version": "1",
                "independence": "non_independent",
            }
            evidence_path.write_text(json.dumps(payload), encoding="utf-8")
            artifacts.artifact_add(
                Namespace(run_dir=str(run_dir), kind="evidence", input=str(evidence_path))
            )
            with self.assertRaisesRegex(artifacts.ArtifactError, "independent child-agent"):
                artifacts.gate_set(
                    Namespace(
                        run_dir=str(run_dir),
                        gate_id="gate_weapon_presentation",
                        status="pass",
                        evidence_id="ev_self_review",
                        reason="Self review must not close the gate.",
                    )
                )

    def test_run_validation_rejects_continuation_anchor_drift(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            run_dir = self.init_run(Path(directory))
            progress_path = run_dir / "progress.json"
            progress = json.loads(progress_path.read_text(encoding="utf-8"))
            progress["continuation_anchor"]["goal"] = "A chat-derived replacement goal."
            progress_path.write_text(json.dumps(progress), encoding="utf-8")
            with self.assertRaisesRegex(artifacts.ArtifactError, "drifted from RunSpec"):
                artifacts.validate_run(run_dir)

    def test_atomic_json_is_stable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "value.json"
            artifacts.atomic_json(path, {"b": 2, "a": 1})
            self.assertEqual({"a": 1, "b": 2}, json.loads(path.read_text(encoding="utf-8")))
            self.assertTrue(path.read_text(encoding="utf-8").endswith("\n"))

    def test_template_emit_refuses_overwrite(self) -> None:
        with tempfile.TemporaryDirectory(dir=artifacts.ROOT) as directory:
            path = Path(directory) / "node.json"
            artifacts.emit_template(Namespace(kind="node", output=str(path)))
            value = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual("reference.replace-me", value["km_id"])
            with self.assertRaises(artifacts.ArtifactError):
                artifacts.emit_template(Namespace(kind="node", output=str(path)))

    def test_loop_init_generates_valid_progress_and_ledgers(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            run_dir = Path(directory) / "run"
            artifacts.loop_init(
                Namespace(
                    run_dir=str(run_dir),
                    spec=str(
                        artifacts.LOOP_ROOT
                        / "assets"
                        / "templates"
                        / "run-spec.json"
                    ),
                    revision="test-revision",
                )
            )
            progress = json.loads((run_dir / "progress.json").read_text(encoding="utf-8"))
            self.assertEqual("draft", progress["state"])
            self.assertEqual(
                {
                    "gate_weapon_function",
                    "gate_weapon_presentation",
                    "gate_weapon_integration",
                },
                set(progress["gate_status"]),
            )
            for name in ("evidence", "findings", "iterations"):
                self.assertTrue((run_dir / name).is_dir())

    def test_node_upsert_and_remove_use_lint_and_exact_identity(self) -> None:
        parent = artifacts.ROOT / "docs"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            node_path = temp_dir / "managed-example.md"
            spec_path = temp_dir / "node-spec.json"
            slug = "".join(
                character if character.isalnum() or character == "-" else "-"
                for character in temp_dir.name.lower()
            )
            km_id = f"reference.managed-{slug}"
            spec_path.write_text(
                json.dumps(
                    {
                        "km_id": km_id,
                        "km_type": "reference",
                        "domain": "workflow",
                        "status": "active",
                        "owner": "maintainers",
                        "source_of_truth": ["README.md"],
                        "validated_by": ["command:python3 tools/docs_lint.py"],
                        "tags": ["workflow:task-routing"],
                        "related": ["map.workflows"],
                        "title": "Managed Example",
                        "body": "Generated through the managed writer.",
                    }
                ),
                encoding="utf-8",
            )
            with patch.object(artifacts, "run_command"):
                artifacts.node_upsert(
                    Namespace(path=str(node_path), spec=str(spec_path), expect_km_id=None)
                )
            self.assertTrue(node_path.is_file())
            with patch.object(artifacts, "run_command"), self.assertRaises(
                artifacts.ArtifactError
            ):
                artifacts.node_upsert(
                    Namespace(
                        path=str(node_path),
                        spec=str(spec_path),
                        expect_km_id=None,
                    )
                )
            with patch.object(artifacts, "run_command"):
                artifacts.node_upsert(
                    Namespace(
                        path=str(node_path),
                        spec=str(spec_path),
                        expect_km_id=km_id,
                    )
                )
            with patch.object(artifacts, "run_command"):
                artifacts.node_remove(
                    Namespace(
                        path=str(node_path),
                        expect_km_id=km_id,
                        reason="Test cleanup",
                        confirm=f"delete:{km_id}",
                    )
                )
            self.assertFalse(node_path.exists())

    def test_gate_pass_without_evidence_is_rejected(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            run_dir = Path(directory) / "run"
            artifacts.loop_init(
                Namespace(
                    run_dir=str(run_dir),
                    spec=str(
                        artifacts.LOOP_ROOT
                        / "assets"
                        / "templates"
                        / "run-spec.json"
                    ),
                    revision="test-revision",
                )
            )
            with self.assertRaises(artifacts.ArtifactError):
                artifacts.gate_set(
                    Namespace(
                        run_dir=str(run_dir),
                        gate_id="gate_weapon_function",
                        status="pass",
                        evidence_id=None,
                        reason="Invalid pass attempt",
                    )
                )

    def test_evidence_append_can_pass_matching_gate(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = temp_dir / "run"
            artifacts.loop_init(
                Namespace(
                    run_dir=str(run_dir),
                    spec=str(
                        artifacts.LOOP_ROOT
                        / "assets"
                        / "templates"
                        / "run-spec.json"
                    ),
                    revision="test-revision",
                )
            )
            evidence_path = self.evidence_input(temp_dir, result="pass")
            evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
            artifacts.artifact_add(
                Namespace(
                    run_dir=str(run_dir),
                    kind="evidence",
                    input=str(evidence_path),
                )
            )
            artifacts.gate_set(
                Namespace(
                    run_dir=str(run_dir),
                    gate_id="gate_weapon_function",
                    status="pass",
                    evidence_id=evidence["evidence_id"],
                    reason="Matching strict evidence passed.",
                )
            )
            progress = json.loads((run_dir / "progress.json").read_text(encoding="utf-8"))
            self.assertEqual("pass", progress["gate_status"]["gate_weapon_function"])
            self.assertIn("gate_weapon_function", progress["frozen_gates"])

    def test_host_capabilities_are_schema_validated(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = temp_dir / "run"
            artifacts.loop_init(
                Namespace(
                    run_dir=str(run_dir),
                    spec=str(
                        artifacts.LOOP_ROOT
                        / "assets"
                        / "templates"
                        / "run-spec.json"
                    ),
                    revision="test-revision",
                )
            )
            host = json.loads(
                (
                    artifacts.LOOP_ROOT
                    / "assets"
                    / "templates"
                    / "host-capabilities.json"
                ).read_text(encoding="utf-8")
            )
            host.pop("observed_at", None)
            host_path = temp_dir / "host-input.json"
            host_path.write_text(json.dumps(host), encoding="utf-8")
            artifacts.host_set(
                Namespace(
                    run_dir=str(run_dir),
                    input=str(host_path),
                    reason="Observed test capabilities.",
                )
            )
            written = json.loads(
                (run_dir / "host-capabilities.json").read_text(encoding="utf-8")
            )
            self.assertEqual(artifacts.SCHEMA_VERSION, written["schema_version"])
            self.assertTrue(written["observed_at"])

    def test_completion_cannot_relabel_old_evidence_revision(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = self.init_run(temp_dir, "rev-1")
            progress_path = run_dir / "progress.json"
            progress = json.loads(progress_path.read_text(encoding="utf-8"))
            progress["state"] = "completion_review"
            progress_path.write_text(json.dumps(progress), encoding="utf-8")
            with self.assertRaisesRegex(artifacts.ArtifactError, "cannot silently relabel"):
                artifacts.loop_transition(
                    Namespace(
                        run_dir=str(run_dir),
                        state="completed",
                        revision="rev-2",
                        active_unit=None,
                        reason="Must not relabel.",
                        evidence_id=[],
                    )
                )

    def test_terminal_run_rejects_managed_mutation(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = self.init_run(temp_dir)
            progress_path = run_dir / "progress.json"
            progress = json.loads(progress_path.read_text(encoding="utf-8"))
            progress["state"] = "completed"
            progress_path.write_text(json.dumps(progress), encoding="utf-8")
            with self.assertRaisesRegex(artifacts.ArtifactError, "terminal runs are immutable"):
                artifacts.artifact_add(
                    Namespace(
                        run_dir=str(run_dir),
                        kind="evidence",
                        input=str(self.evidence_input(temp_dir)),
                    )
                )

    def test_path_traversal_ledger_id_is_rejected(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = self.init_run(temp_dir)
            (temp_dir / "decoy.json").write_text("{}", encoding="utf-8")
            finding = json.loads(
                (
                    artifacts.LOOP_ROOT / "assets" / "templates" / "finding.json"
                ).read_text(encoding="utf-8")
            )
            finding["finding_id"] = "finding_traversal"
            finding["evidence_ids"] = ["../../decoy"]
            finding_path = temp_dir / "finding.json"
            finding_path.write_text(json.dumps(finding), encoding="utf-8")
            with self.assertRaisesRegex(artifacts.ArtifactError, "does not match"):
                artifacts.artifact_add(
                    Namespace(
                        run_dir=str(run_dir),
                        kind="finding",
                        input=str(finding_path),
                    )
                )

    def test_validator_rejects_dangling_progress_ledgers(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            run_dir = self.init_run(Path(directory))
            progress_path = run_dir / "progress.json"
            progress = json.loads(progress_path.read_text(encoding="utf-8"))
            progress["evidence_ledger"] = ["ev_missing"]
            progress["open_findings"] = ["finding_missing"]
            progress_path.write_text(json.dumps(progress), encoding="utf-8")
            with self.assertRaisesRegex(artifacts.ArtifactError, "must exactly match"):
                artifacts.validate_run(run_dir)

    def test_resolved_finding_requires_current_passing_acceptance_evidence(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = self.init_run(temp_dir)
            evidence_path = self.evidence_input(temp_dir, result="fail")
            artifacts.artifact_add(
                Namespace(run_dir=str(run_dir), kind="evidence", input=str(evidence_path))
            )
            finding = json.loads(
                (
                    artifacts.LOOP_ROOT / "assets" / "templates" / "finding.json"
                ).read_text(encoding="utf-8")
            )
            finding_path = temp_dir / "finding.json"
            finding_path.write_text(json.dumps(finding), encoding="utf-8")
            artifacts.artifact_add(
                Namespace(run_dir=str(run_dir), kind="finding", input=str(finding_path))
            )
            with self.assertRaisesRegex(artifacts.ArtifactError, "current passing Evidence"):
                artifacts.finding_set(
                    Namespace(
                        run_dir=str(run_dir),
                        finding_id=finding["finding_id"],
                        status="resolved",
                        blocked_by=None,
                        next_change=None,
                        evidence_id=["ev_example_001"],
                        reason="Failed evidence cannot resolve.",
                    )
                )

    def test_failed_init_cleans_preexisting_empty_directory(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = temp_dir / "empty-run"
            run_dir.mkdir()
            bad_spec = json.loads(
                (
                    artifacts.LOOP_ROOT / "assets" / "templates" / "run-spec.json"
                ).read_text(encoding="utf-8")
            )
            bad_spec["quality_gates"][0]["scenario_ids"] = ["scenario_missing"]
            spec_path = temp_dir / "bad-spec.json"
            spec_path.write_text(json.dumps(bad_spec), encoding="utf-8")
            with self.assertRaises(artifacts.ArtifactError):
                artifacts.loop_init(
                    Namespace(
                        run_dir=str(run_dir),
                        spec=str(spec_path),
                        revision="test-revision",
                    )
                )
            self.assertEqual([], list(run_dir.iterdir()))

    def test_focused_scenario_must_use_dedicated_test_scene(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            bad_spec = json.loads(
                (
                    artifacts.LOOP_ROOT / "assets" / "templates" / "run-spec.json"
                ).read_text(encoding="utf-8")
            )
            bad_spec["scenarios"][0]["setup"]["execution_surface"] = "main_scene"
            spec_path = temp_dir / "bad-focused-spec.json"
            spec_path.write_text(json.dumps(bad_spec), encoding="utf-8")
            with self.assertRaisesRegex(artifacts.ArtifactError, "dedicated_test_scene"):
                artifacts.loop_init(
                    Namespace(
                        run_dir=str(temp_dir / "run"),
                        spec=str(spec_path),
                        revision="test-revision",
                    )
                )

    def test_coverage_matrix_rejects_unknown_observation(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            bad_spec = json.loads(
                (
                    artifacts.LOOP_ROOT / "assets" / "templates" / "run-spec.json"
                ).read_text(encoding="utf-8")
            )
            bad_spec["scenarios"][0]["coverage_matrix"][0]["observation_ids"] = [
                "missing_observation"
            ]
            spec_path = temp_dir / "bad-coverage-spec.json"
            spec_path.write_text(json.dumps(bad_spec), encoding="utf-8")
            with self.assertRaisesRegex(artifacts.ArtifactError, "unknown stimuli"):
                artifacts.loop_init(
                    Namespace(
                        run_dir=str(temp_dir / "run"),
                        spec=str(spec_path),
                        revision="test-revision",
                    )
                )

    def test_revision_set_requires_explicit_impact_set(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            run_dir = self.init_run(Path(directory), "rev-1")
            with self.assertRaisesRegex(artifacts.ArtifactError, "affected-gate-id"):
                artifacts.revision_set(
                    Namespace(
                        run_dir=str(run_dir),
                        revision="rev-2",
                        reason="Unscoped change.",
                        affected_gate_id=[],
                        all_gates=False,
                    )
                )

    def test_scenario_authoring_requires_capability_audit(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            run_dir = self.init_run(Path(directory))
            with self.assertRaisesRegex(artifacts.ArtifactError, "HostCapabilities"):
                artifacts.loop_transition(
                    Namespace(
                        run_dir=str(run_dir),
                        state="scenario_authoring",
                        revision="test-revision",
                        active_unit="author scenario",
                        reason="Missing capability audit.",
                        evidence_id=[],
                    )
                )

    def test_revision_set_stales_only_affected_gate_and_carries_unrelated_evidence(self) -> None:
        parent = artifacts.ROOT / "docs" / "workbench"
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            temp_dir = Path(directory)
            run_dir = self.init_run(temp_dir, "rev-1")
            evidence_path = self.evidence_input(temp_dir, revision="rev-1")
            artifacts.artifact_add(
                Namespace(run_dir=str(run_dir), kind="evidence", input=str(evidence_path))
            )
            artifacts.gate_set(
                Namespace(
                    run_dir=str(run_dir),
                    gate_id="gate_weapon_function",
                    status="pass",
                    evidence_id="ev_example_001",
                    reason="Initial revision passed.",
                )
            )
            carried_path = self.evidence_input(
                temp_dir,
                evidence_id="ev_presentation_001",
                gate_id="gate_weapon_presentation",
                revision="rev-1",
            )
            artifacts.artifact_add(
                Namespace(run_dir=str(run_dir), kind="evidence", input=str(carried_path))
            )
            deterministic_path = self.evidence_input(
                temp_dir,
                evidence_id="ev_presentation_runtime_001",
                gate_id="gate_weapon_presentation",
                revision="rev-1",
            )
            deterministic = json.loads(deterministic_path.read_text(encoding="utf-8"))
            deterministic["evidence_type"] = "runtime_state"
            deterministic["grader"] = {
                "kind": "runtime",
                "name": "deterministic-test-fixture",
                "version": "1",
                "independence": "not_applicable",
            }
            deterministic_path.write_text(json.dumps(deterministic), encoding="utf-8")
            artifacts.artifact_add(
                Namespace(
                    run_dir=str(run_dir),
                    kind="evidence",
                    input=str(deterministic_path),
                )
            )
            artifacts.gate_set(
                Namespace(
                    run_dir=str(run_dir),
                    gate_id="gate_weapon_presentation",
                    status="pass",
                    evidence_id=["ev_presentation_runtime_001", "ev_presentation_001"],
                    reason="Unrelated presentation evidence passed.",
                )
            )
            artifacts.revision_set(
                Namespace(
                    run_dir=str(run_dir),
                    revision="rev-2",
                    reason="Candidate implementation changed.",
                    affected_gate_id=["gate_weapon_function"],
                    all_gates=False,
                )
            )
            progress = json.loads(
                (run_dir / "progress.json").read_text(encoding="utf-8")
            )
            evidence = json.loads(
                (run_dir / "evidence" / "ev_example_001.json").read_text(
                    encoding="utf-8"
                )
            )
            carried = json.loads(
                (run_dir / "evidence" / "ev_presentation_001.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual("rev-2", progress["revision"])
            self.assertEqual("stale", progress["gate_status"]["gate_weapon_function"])
            self.assertNotIn("gate_weapon_function", progress["frozen_gates"])
            self.assertEqual("stale", evidence["freshness"])
            self.assertEqual("pass", progress["gate_status"]["gate_weapon_presentation"])
            self.assertIn("gate_weapon_presentation", progress["frozen_gates"])
            self.assertEqual("current", carried["freshness"])
            self.assertEqual("rev-1", carried["revision"])
            self.assertEqual("rev-2", carried["valid_through_revision"])


if __name__ == "__main__":
    unittest.main()

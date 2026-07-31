#!/usr/bin/env python3
"""Focused tests for Workbench human-validation contracts."""

from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("workbench_hq.py")
SPEC = importlib.util.spec_from_file_location("workbench_hq", MODULE_PATH)
assert SPEC and SPEC.loader
workbench = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(workbench)


def validation_spec() -> dict:
    return {
        "validation_id": "ui-learning-v1",
        "title": "UI learning",
        "run_id": "run-1",
        "gate_id": "gate-human",
        "participant_target": 5,
        "pass_threshold": 4,
        "instructions": ["Do not coach."],
        "tasks": [
            {
                "task_id": "battle",
                "title": "Battle",
                "prompt": "Explain the screen.",
                "dimensions": ["goal", "risk", "action"],
            }
        ],
    }


def validation_session() -> dict:
    return {
        "validation_id": "ui-learning-v1",
        "participant_id": "P01",
        "device": "phone",
        "browser": "browser",
        "task_results": [
            {
                "task_id": "battle",
                "answers": {"goal": "win", "risk": "health", "action": "attack"},
                "timings_seconds": {"goal": 1.2, "risk": 1.5, "action": 1.8},
                "wrong_taps": 0,
                "needed_help": False,
                "obstruction": "",
            }
        ],
    }


class HumanValidationTests(unittest.TestCase):
    def test_spec_round_trip_fence(self) -> None:
        spec = workbench.validate_human_validation_spec(validation_spec())
        content = """---
km_id: test
---
```board #project
## 待办
```
```status #hq
state: building
```
```chat #team
- 2026-01-01T00:00:00Z @test (agent): ready
```
"""
        updated = workbench.upsert_human_validation_fence(content, spec)
        parsed = workbench.human_validation_specs(updated)
        self.assertEqual(parsed["ui-learning-v1"]["tasks"][0]["task_id"], "battle")
        workbench.validate_hq(updated)

    def test_rejects_duplicate_task_and_unsafe_participant(self) -> None:
        spec = validation_spec()
        spec["tasks"].append(dict(spec["tasks"][0]))
        with self.assertRaisesRegex(RuntimeError, "无效或重复"):
            workbench.validate_human_validation_spec(spec)
        with self.assertRaisesRegex(RuntimeError, "participant_id"):
            workbench.validate_human_validation_session(
                {**validation_session(), "participant_id": "../escape"},
                workbench.validate_human_validation_spec(validation_spec()),
            )

    def test_session_is_saved_below_validation_directory(self) -> None:
        spec = workbench.validate_human_validation_spec(validation_spec())
        original = workbench.HUMAN_VALIDATION_DIR
        try:
            with tempfile.TemporaryDirectory(dir=workbench.ROOT) as directory:
                workbench.HUMAN_VALIDATION_DIR = Path(directory)
                path = workbench.save_human_validation_session(validation_session(), spec)
                self.assertTrue(path.is_file())
                self.assertEqual(path.parent.name, "sessions")
                summaries = workbench.human_validation_session_summaries("ui-learning-v1")
                self.assertEqual(summaries[0]["participant_id"], "P01")
                self.assertTrue(summaries[0]["passed_two_second"])
        finally:
            workbench.HUMAN_VALIDATION_DIR = original

    def test_template_contains_interactive_validation_renderer(self) -> None:
        template = workbench.TEMPLATE.read_text(encoding="utf-8")
        self.assertIn("function validationView", template)
        self.assertIn("/api/validation-session", template)
        self.assertIn('p.kind==="validation"?validationView(p)', template)
        self.assertIn('role="tablist"', template)
        self.assertIn("function switchTab", template)
        self.assertIn('localStorage.getItem("caesar-workbench-tab")', template)
        self.assertIn("function chooseFeedback", template)
        self.assertIn("👍 满意", template)
        self.assertIn('last?"提交反馈":"下一个 →"', template)
        self.assertIn("await submitValidation(id)", template)
        self.assertNotIn("✓ 反馈完成", template)

    def test_accepts_simple_feedback_session(self) -> None:
        spec = workbench.validate_human_validation_spec(validation_spec())
        session = {
            "validation_id": "ui-learning-v1",
            "participant_id": "feedback-1",
            "device": "browser",
            "browser": "test",
            "feedback_results": [
                {"task_id": "battle", "verdict": "revise", "note": "Too busy"}
            ],
        }
        normalized = workbench.validate_human_validation_session(session, spec)
        self.assertEqual(normalized["schema_version"], "caesar-human-feedback-session/v1")


if __name__ == "__main__":
    unittest.main()

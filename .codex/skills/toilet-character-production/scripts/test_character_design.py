#!/usr/bin/env python3

from __future__ import annotations

import copy
import importlib.util
import json
import unittest
from pathlib import Path


SKILL_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = SKILL_ROOT.parents[2]
PROJECT_ROOT = REPO_ROOT / "project-a"
MODULE_SPEC = importlib.util.spec_from_file_location(
    "character_design",
    SKILL_ROOT / "scripts" / "character_design.py",
)
assert MODULE_SPEC is not None and MODULE_SPEC.loader is not None
character_design = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(character_design)


class CharacterDesignTests(unittest.TestCase):
    def setUp(self) -> None:
        self.example = json.loads(
            (SKILL_ROOT / "assets" / "magnetic-conductor.example.json").read_text(
                encoding="utf-8"
            )
        )

    def test_snapshot_reads_current_roster_and_stage_curve(self) -> None:
        result = character_design.snapshot(PROJECT_ROOT)
        self.assertEqual(len(result["roster"]), 8)
        self.assertEqual(len(result["stage_curve"]), 25)
        self.assertEqual(result["stage_curve"][-1]["recommended_power"], 16500)
        self.assertEqual(
            next(row for row in result["roster"] if row["archetype_id"] == "saw")[
                "power"
            ]["1"],
            2294,
        )

    def test_example_is_valid_and_power_is_derived(self) -> None:
        result = character_design.validate(PROJECT_ROOT, self.example)
        self.assertTrue(result["ok"], result)
        self.assertEqual(result["derived"]["power"], {"1": 1419, "2": 1736, "3": 2053})
        self.assertEqual(self.example["acquisition"]["duplicate_fragments"], 30)

    def test_rejects_stale_duplicate_fragment_value(self) -> None:
        invalid = copy.deepcopy(self.example)
        invalid["acquisition"]["duplicate_fragments"] = 15
        result = character_design.validate(PROJECT_ROOT, invalid)
        self.assertFalse(result["ok"])
        self.assertIn(
            "A duplicate_fragments must match current recruit rule: 30",
            result["errors"],
        )

    def test_rejects_random_character_as_mandatory_boss_solution(self) -> None:
        invalid = copy.deepcopy(self.example)
        invalid["encounters"]["boss_soft_counter"]["fallbacks"] = []
        result = character_design.validate(PROJECT_ROOT, invalid)
        self.assertFalse(result["ok"])
        self.assertIn(
            "encounters.boss_soft_counter.fallbacks must name at least one existing alternative",
            result["errors"],
        )

    def test_rejects_encounter_before_acquisition(self) -> None:
        invalid = copy.deepcopy(self.example)
        invalid["acquisition"]["available_after_stage"] = "stage_3_1"
        result = character_design.validate(PROJECT_ROOT, invalid)
        self.assertFalse(result["ok"])
        self.assertTrue(
            any("occurs before character availability" in error for error in result["errors"])
        )


if __name__ == "__main__":
    unittest.main()

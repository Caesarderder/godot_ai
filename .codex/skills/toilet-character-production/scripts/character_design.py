#!/usr/bin/env python3
"""Snapshot current roster/stage facts and validate a proposed character spec."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


ATTRS = ("hp", "attack", "defense", "speed_milli", "crit_bp")
STAR_BP = {1: 10000, 2: 13000, 3: 16000}
RARITY_BP = {"B": 10000, "A": 10000, "S": 14000}
VALID_BRANCHES = {"ordinary", "heavy", "flying", "special"}
VALID_FACTIONS = {"快攻破城", "钢铁防线", "远程轰炸", "干扰增殖"}
STAGE_PATTERN = re.compile(r"^stage_([1-5])_([1-9]|1[0-2])$")


def _text(project: Path, relative: str) -> str:
    path = project / relative
    if not path.is_file():
        raise FileNotFoundError(f"required project source not found: {path}")
    return path.read_text(encoding="utf-8")


def _quoted_list(value: str) -> list[str]:
    return re.findall(r'"([^"]+)"', value)


def _class_stats(source: str) -> dict[str, dict[str, int]]:
    result: dict[str, dict[str, int]] = {}
    for class_id, body in re.findall(r'"(guardian|fighter|ranger|arcanist)"\s*:\s*\{([^}]+)\}', source):
        stats = {key: int(value) for key, value in re.findall(r'"([^"]+)"\s*:\s*(\d+)', body)}
        if all(key in stats for key in ATTRS):
            result[class_id] = {key: stats[key] for key in ATTRS}
    return result


def _recipes(source: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for body in re.findall(r'\{("recipe_id":\s*"[^}]+)\}', source):
        row = dict(re.findall(r'"([^"]+)"\s*:\s*"([^"]*)"', body))
        if "recipe_id" in row:
            rows.append(row)
    return rows


def _mapping(source: str, constant: str) -> dict[str, str]:
    match = re.search(rf"const {constant}:\s*Dictionary\s*=\s*\{{(.*?)\n\}}", source, re.S)
    if not match:
        return {}
    return dict(re.findall(r'"([^"]+)"\s*:\s*"([^"]+)"', match.group(1)))


def _star_effects(source: str) -> dict[str, dict[int, str]]:
    match = re.search(r"const STAR_EFFECTS:\s*Dictionary\s*=\s*\{(.*?)\n\}", source, re.S)
    if not match:
        return {}
    result: dict[str, dict[int, str]] = {}
    for archetype, body in re.findall(r'"([^"]+)"\s*:\s*\{([^}]+)\}', match.group(1)):
        result[archetype] = {int(star): copy for star, copy in re.findall(r'(\d+)\s*:\s*"([^"]+)"', body)}
    return result


def _recommended_power(stage_source: str) -> list[int]:
    match = re.search(r"const RECOMMENDED_POWER:\s*Array\[int\]\s*=\s*\[(.*?)\]", stage_source, re.S)
    if match:
        return [int(value) for value in re.findall(r"\d+", match.group(1))]
    def values(constant: str) -> list[int]:
        current = re.search(
            rf"const {constant}:\s*Array\[int\]\s*=\s*\[(.*?)\]",
            stage_source,
            re.S,
        )
        return [] if not current else [
            int(value) for value in re.findall(r"\d+", current.group(1))
        ]
    starts = values("CHAPTER_POWER_START")
    finishes = values("CHAPTER_POWER_END")
    legacy = values("LEGACY_RECOMMENDED_POWER")
    if len(starts) != 5 or len(finishes) != 5 or len(legacy) < 5:
        return []
    powers: list[int] = []
    for chapter in range(1, 6):
        for stage in range(1, 13):
            if chapter == 1 and stage <= 5:
                powers.append(legacy[stage - 1])
                continue
            if chapter == 1:
                powers.append([6800, 7050, 7300, 7800, 7950, 8200, 9000][stage - 6])
                continue
            start = starts[chapter - 1]
            finish = finishes[chapter - 1]
            value = start + (finish - start) * (stage - 1) // 11
            if stage == 6:
                value += (finish - start) * 8 // 100
            elif stage == 9:
                value += (finish - start) * 5 // 100
            elif stage == 12:
                value += (finish - start) * 10 // 100
            powers.append(value)
    return powers


def _recommendation_counts(stage_source: str, recipe_rows: list[dict[str, str]]) -> dict[str, dict[str, int]]:
    counts = {row["archetype_id"]: {"recommended": 0, "fallback": 0} for row in recipe_rows}
    for block in re.finditer(r'"stage_[1-5]_(?:[1-9]|1[0-2])"\s*:\s*\{(.*?)\n\t\t\}', stage_source, re.S):
        body = block.group(1)
        for kind in ("recommended", "fallback"):
            match = re.search(rf'"{kind}"\s*:\s*\[([^\]]*)\]', body)
            if not match:
                continue
            for recipe_id in _quoted_list(match.group(1)):
                for row in recipe_rows:
                    if row["recipe_id"] == recipe_id:
                        counts[row["archetype_id"]][kind] += 1
    return counts


def combat_power(stats: dict[str, int], rating: str, star: int) -> int:
    multiplier = STAR_BP[star] * RARITY_BP[rating]
    hp = stats["hp"] * multiplier // 100_000_000
    attack = stats["attack"] * multiplier // 100_000_000
    defense = stats["defense"] * multiplier // 100_000_000
    return (
        hp * 3
        + attack * 20
        + defense * 10
        + stats["speed_milli"] // 500
        + stats["crit_bp"] // 10
    )


def snapshot(project: Path) -> dict:
    hero_source = _text(project, "game/scripts/domain/recruitment/hero_generator.gd")
    catalog_source = _text(project, "game/scripts/domain/factory/factory_catalog.gd")
    faction_source = _text(project, "game/scripts/domain/content/faction_catalog.gd")
    stage_source = _text(project, "game/scripts/domain/content/stage_catalog.gd")
    classes = _class_stats(hero_source)
    recipe_rows = _recipes(catalog_source)
    factions = _mapping(faction_source, "FACTIONS")
    effects = _star_effects(faction_source)
    counts = _recommendation_counts(stage_source, recipe_rows)
    roster = []
    for row in recipe_rows:
        archetype = row["archetype_id"]
        class_id = row["class_id"]
        rating = row["rating"]
        stats = classes[class_id]
        roster.append({
            **{key: row[key] for key in ("recipe_id", "display_name", "workshop", "rating", "archetype_id", "class_id")},
            "faction": factions.get(archetype, "独立战术"),
            "base_stats": stats,
            "power": {str(star): combat_power(stats, rating, star) for star in (1, 2, 3)},
            "star_effects": effects.get(archetype, {}),
            "stage_usage": counts.get(archetype, {"recommended": 0, "fallback": 0}),
        })
    powers = _recommended_power(stage_source)
    return {
        "project_root": str(project),
        "roster": roster,
        "classes": classes,
        "stage_curve": [
            {"stage_id": f"stage_{index // 12 + 1}_{index % 12 + 1}", "recommended_power": value}
            for index, value in enumerate(powers)
        ],
        "known_factions": sorted(VALID_FACTIONS),
        "evidence": {
            "roster_and_power": "derived from current code",
            "skill_effectiveness": "not represented by displayed CP",
            "player_preference": "unknown without representative playtest",
        },
    }


def _stage_index(stage_id: str) -> int:
    match = STAGE_PATTERN.fullmatch(stage_id)
    if not match:
        return -1
    return (int(match.group(1)) - 1) * 12 + int(match.group(2)) - 1


def validate(project: Path, spec: dict) -> dict:
    current = snapshot(project)
    errors: list[str] = []
    warnings: list[str] = []
    required = (
        "archetype_id", "display_name", "rating", "class_id", "branch", "faction",
        "tactical_verb", "player_promise", "base_stats", "active_skill", "acquisition",
        "encounters", "narrative", "nearest_peers", "evidence_labels",
    )
    for key in required:
        if key not in spec:
            errors.append(f"missing required field: {key}")
    if errors:
        return {"ok": False, "errors": errors, "warnings": warnings}
    existing = {row["archetype_id"]: row for row in current["roster"]}
    archetype_id = str(spec["archetype_id"])
    if not re.fullmatch(r"[a-z][a-z0-9_]*", archetype_id):
        errors.append("archetype_id must be lower_snake_case")
    existing_row = existing.get(archetype_id)
    rating = str(spec["rating"])
    class_id = str(spec["class_id"])
    if rating not in RARITY_BP:
        errors.append("rating must be B, A, or S")
    if class_id not in current["classes"]:
        errors.append(f"unknown class_id: {class_id}")
    if str(spec["branch"]) not in VALID_BRANCHES:
        errors.append("branch must be ordinary, heavy, flying, or special")
    if str(spec["faction"]) not in VALID_FACTIONS:
        errors.append("faction must reuse a current faction unless the project contract explicitly adds one")
    stats = spec["base_stats"]
    if not isinstance(stats, dict) or any(not isinstance(stats.get(key), int) or stats.get(key, 0) <= 0 for key in ATTRS):
        errors.append(f"base_stats must contain positive integers: {', '.join(ATTRS)}")
    if existing_row is not None:
        implemented_identity = {
            "display_name": str(existing_row.get("display_name", "")),
            "rating": str(existing_row.get("rating", "")),
            "class_id": str(existing_row.get("class_id", "")),
            "branch": str(existing_row.get("workshop", "")),
            "faction": str(existing_row.get("faction", "")),
        }
        for key, implemented_value in implemented_identity.items():
            if str(spec.get(key, "")) != implemented_value:
                errors.append(
                    f"implemented {archetype_id} {key} mismatch: "
                    f"spec={spec.get(key, '')} runtime={implemented_value}"
                )
        if isinstance(stats, dict) and stats != existing_row.get("base_stats", {}):
            errors.append(
                f"implemented {archetype_id} base_stats mismatch: "
                f"spec={stats} runtime={existing_row.get('base_stats', {})}"
            )
    power = {}
    if not errors:
        power = {star: combat_power(stats, rating, star) for star in (1, 2, 3)}
        same_rating = [row["power"]["1"] for row in current["roster"] if row["rating"] == rating]
        if same_rating:
            low = min(same_rating) * 85 // 100
            high = max(same_rating) * 115 // 100
            if not low <= power[1] <= high:
                errors.append(f"1-star CP {power[1]} is outside current {rating} peer envelope {low}..{high}")
        if rating == "S":
            non_s_two = [row["power"]["2"] for row in current["roster"] if row["rating"] in ("B", "A")]
            if non_s_two and power[1] < min(non_s_two) * 95 // 100:
                errors.append("S 1-star CP is below the accepted B/A 2-star competitive floor")
    skill = spec["active_skill"]
    for key in ("skill_id", "display_name", "one_star", "two_star", "three_star", "timing", "weakness"):
        if not isinstance(skill, dict) or not str(skill.get(key, "")).strip():
            errors.append(f"active_skill.{key} is required")
    if isinstance(skill, dict):
        star_copies = [str(skill.get(key, "")).strip() for key in ("one_star", "two_star", "three_star")]
        if len(set(star_copies)) != 3:
            errors.append("one_star, two_star, and three_star must describe distinct behaviors")
        for key in ("two_star", "three_star"):
            if re.fullmatch(r".*(提升|增加|提高)\s*\d+%.*", str(skill.get(key, ""))):
                warnings.append(f"active_skill.{key} looks percentage-only; require a qualitative behavior change")
    acquisition = spec["acquisition"]
    unlock_stage = str(acquisition.get("available_after_stage", "")) if isinstance(acquisition, dict) else ""
    unlock_index = _stage_index(unlock_stage)
    if unlock_index < 0:
        errors.append("acquisition.available_after_stage must be stage_1_1..stage_5_12")
    expected_fragments = {"B": 20, "A": 30, "S": 40}.get(rating)
    if isinstance(acquisition, dict) and int(acquisition.get("duplicate_fragments", -1)) != expected_fragments:
        errors.append(f"{rating} duplicate_fragments must match current recruit rule: {expected_fragments}")
    encounters = spec["encounters"]
    order = ("safe_intro", "combination_test", "spotlight", "boss_soft_counter")
    prior = unlock_index
    for key in order:
        encounter = encounters.get(key, {}) if isinstance(encounters, dict) else {}
        stage_id = str(encounter.get("stage_id", ""))
        index = _stage_index(stage_id)
        if index < 0:
            errors.append(f"encounters.{key}.stage_id must be stage_1_1..stage_5_12")
        elif index < unlock_index:
            errors.append(f"encounters.{key} occurs before character availability")
        elif index < prior:
            errors.append("encounter teaching order must be monotonic")
        prior = max(prior, index)
        for field in ("demand", "feedback"):
            if not str(encounter.get(field, "")).strip():
                errors.append(f"encounters.{key}.{field} is required")
        fallbacks = encounter.get("fallbacks", [])
        if not isinstance(fallbacks, list) or not fallbacks:
            errors.append(f"encounters.{key}.fallbacks must name at least one existing alternative")
        else:
            for fallback in fallbacks:
                if fallback not in existing:
                    errors.append(f"encounters.{key} unknown fallback: {fallback}")
    if not str(spec["tactical_verb"]).strip() or str(spec["tactical_verb"]) in {"输出", "增伤", "更强"}:
        errors.append("tactical_verb must describe an observable battle action")
    if str(spec["tactical_verb"]) not in str(spec["player_promise"]):
        warnings.append("player_promise should name the tactical verb explicitly")
    peers = spec["nearest_peers"]
    if not isinstance(peers, list) or len(peers) < 2:
        errors.append("nearest_peers must name at least two existing roles")
    else:
        for peer in peers:
            if peer not in existing:
                errors.append(f"unknown nearest peer: {peer}")
    labels = spec["evidence_labels"]
    if not isinstance(labels, dict) or labels.get("player_desirability") != "unknown":
        errors.append("player_desirability must remain unknown until representative playtest evidence exists")
    for key in ("origin", "silhouette", "battle_sound", "alliance_response"):
        if not isinstance(spec["narrative"], dict) or not str(spec["narrative"].get(key, "")).strip():
            errors.append(f"narrative.{key} is required")
    return {
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
        "derived": {
            "power": {str(key): value for key, value in power.items()},
            "rating": rating,
            "class_id": class_id,
            "availability_index": unlock_index,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("snapshot", "validate"):
        command = sub.add_parser(name)
        command.add_argument("--project-root", type=Path, required=True)
        if name == "validate":
            command.add_argument("--spec", type=Path, required=True)
    args = parser.parse_args()
    project = args.project_root.resolve()
    if args.command == "snapshot":
        result = snapshot(project)
    else:
        result = validate(project, json.loads(args.spec.read_text(encoding="utf-8")))
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if args.command == "snapshot" or result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())

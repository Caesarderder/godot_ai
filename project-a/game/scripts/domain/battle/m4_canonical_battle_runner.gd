class_name M4CanonicalBattleRunner
extends RefCounted

const BaseRunner := preload("res://game/scripts/domain/battle/canonical_battle_runner.gd")


static func materialize(scenario: Dictionary, run_seed: int, apply_intervention: bool) -> Dictionary:
	var is_equipment: bool = scenario["intervention"] != null and scenario["intervention"]["type"] == "equip_item"
	var snapshot: Dictionary = BaseRunner.materialize(scenario, run_seed, apply_intervention and not is_equipment)
	if is_equipment:
		snapshot["equipment_bonus"] = int(scenario["intervention"]["equipment_bonus"]) if apply_intervention else 0
	return snapshot


static func run(snapshot: Dictionary) -> BattleResult:
	if int(snapshot.get("equipment_bonus", 0)) == 0:
		return BaseRunner.run(snapshot)
	var equipped := snapshot.duplicate(true)
	var carry_id: String = equipped["active_hero_ids"][0]
	equipped["combat_stats"][carry_id]["attack"] += int(equipped["equipment_bonus"])
	equipped.erase("equipment_bonus")
	return BaseRunner.run(equipped)


static func validate_formation_only(before: Dictionary, after: Dictionary) -> bool:
	return BaseRunner.validate_formation_only(before, after)


static func recipe_hash(snapshot: Dictionary) -> String:
	return BaseRunner.recipe_hash(snapshot)


static func stage_snapshot_hash(scenario: Dictionary) -> String:
	return BaseRunner.stage_snapshot_hash(scenario)


static func validate_equipment_only(before: Dictionary, after: Dictionary) -> bool:
	if int(before.get("equipment_bonus", 0)) == int(after.get("equipment_bonus", 0)):
		return false
	var before_without := before.duplicate(true)
	var after_without := after.duplicate(true)
	before_without.erase("equipment_bonus")
	after_without.erase("equipment_bonus")
	return before_without == after_without

class_name CanonicalBattleRunner
extends RefCounted

const StableSeedScript := preload("res://game/scripts/domain/battle/stable_seed.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/heroes/hero_generator.gd")
const FormationReducerScript := preload("res://game/scripts/domain/formation/formation_reducer.gd")
const Session := preload("res://game/scripts/domain/battle/battle_session.gd")
const Unit := preload("res://game/scripts/domain/battle/battle_unit.gd")


static func materialize(scenario: Dictionary, run_seed: int, apply_intervention: bool) -> Dictionary:
	var stage_id := str(scenario["stage_id"])
	var battle_seed := StableSeedScript.signed_seed(
		StableSeedScript.battle_parts("content-v1", stage_id, 0, str(run_seed))
	)
	var roster: Array[Dictionary] = HeroGeneratorScript.generate_roster(run_seed, 8)
	var roster_ids: Array[String] = []
	for hero in roster:
		roster_ids.append(hero["id"])
	var slots := {
		"front_1": roster_ids[0], "front_2": roster_ids[1],
		"back_1": roster_ids[2], "back_2": roster_ids[3],
	}
	if apply_intervention:
		var intervention: Dictionary = scenario["intervention"]
		var indices: Array = intervention["slots_from_roster_indices"]
		var command := {"type": "set_formation", "slots": {}}
		for slot_index in FormationReducerScript.SLOT_ORDER.size():
			command["slots"][FormationReducerScript.SLOT_ORDER[slot_index]] = roster_ids[int(indices[slot_index])]
		var formation_state := FormationReducerScript.reduce({"slots": slots}, command, roster_ids)
		slots = formation_state["slots"]
	var roll_hex := StableSeedScript.sha256_hex(
		StableSeedScript.battle_parts("content-v1", stage_id, 0, str(run_seed))
	).substr(0, 8)
	var roll := int(roll_hex.hex_to_int() % 1000)
	var cutoffs: Array = scenario["hero_recipe_cutoffs"]
	var carry_attack := int(cutoffs[0]["attack"])
	for band in cutoffs:
		if roll >= int(band["minimum_roll"]):
			carry_attack = int(band["attack"])
	var combat_stats: Dictionary = {}
	for index in 8:
		var hero_id := roster_ids[index]
		combat_stats[hero_id] = {
			"hp": 10, "attack": 1, "speed": 20_000,
		}
	combat_stats[roster_ids[0]] = {"hp": 10, "attack": carry_attack, "speed": int(scenario["carry_speed"])}
	combat_stats[roster_ids[1]] = {"hp": 100, "attack": 1, "speed": 20_000}
	return {
		"content_version": "content-v1", "content_hash": scenario["content_hash"],
		"stage_id": stage_id, "stage_snapshot_hash": scenario["stage_snapshot_hash"], "attempt": 0,
		"run_seed": run_seed, "battle_seed": battle_seed, "roster": roster,
		"active_hero_ids": roster_ids.slice(0, 4), "formation": slots,
		"combat_stats": combat_stats, "enemy": scenario["enemy_snapshot"].duplicate(true),
	}


static func run(snapshot: Dictionary) -> BattleResult:
	var slot_names: Array[String] = FormationReducerScript.SLOT_ORDER
	var units: Array[BattleUnit] = []
	for slot_index in slot_names.size():
		var hero_id: String = snapshot["formation"][slot_names[slot_index]]
		var stats: Dictionary = snapshot["combat_stats"][hero_id]
		units.append(Unit.new(hero_id, 0, slot_index, stats["speed"], stats["hp"], stats["attack"]))
	var enemy: Dictionary = snapshot["enemy"]
	units.append(Unit.new("zz-enemy", 1, 0, enemy["speed"], enemy["hp"], enemy["attack"]))
	return _run_units(int(snapshot["battle_seed"]), units)


static func recipe_hash(snapshot: Dictionary) -> String:
	return BattleResult._sha256(BattleResult._canonical(snapshot))


static func stage_snapshot_hash(scenario: Dictionary) -> String:
	var snapshot := {
		"stage_id": scenario["stage_id"], "enemy_snapshot": scenario["enemy_snapshot"],
		"carry_speed": scenario["carry_speed"],
		"hero_recipe_cutoffs": scenario["hero_recipe_cutoffs"],
	}
	return BattleResult._sha256(BattleResult._canonical(snapshot))


static func validate_formation_only(before: Dictionary, after: Dictionary) -> bool:
	if before["formation"] == after["formation"]:
		return false
	var before_without := before.duplicate(true)
	var after_without := after.duplicate(true)
	before_without.erase("formation")
	after_without.erase("formation")
	return before_without == after_without


static func _run_units(seed_value: int, units: Array[BattleUnit]) -> BattleResult:
	var rng := DeterministicBattleRng.new(seed_value)
	var events: Array = []
	var tick_index := 0
	var guard := 0
	while guard < 2_000:
		guard += 1
		tick_index += 1
		for unit in units:
			if unit.is_alive():
				unit.action_meter += unit.speed
		var ready: Array[BattleUnit] = []
		for unit in units:
			if unit.is_alive() and unit.action_meter >= BattleUnit.ACTION_THRESHOLD:
				ready.append(unit)
		ready.sort_custom(_acts_before)
		for actor in ready:
			if not actor.is_alive():
				continue
			actor.action_meter -= BattleUnit.ACTION_THRESHOLD
			var targets := _live_targets(units, actor.team)
			if targets.is_empty():
				break
			targets.sort_custom(_targets_before)
			var front_slot: int = targets[0].slot
			var tied: Array[BattleUnit] = []
			for target in targets:
				if target.slot == front_slot:
					tied.append(target)
			var selected := tied[rng.choose_index(tied.size())]
			selected.hp = maxi(0, selected.hp - actor.attack)
			events.append([tick_index, actor.unit_id, selected.unit_id, actor.attack, selected.hp])
		var result := _finish_result_if_complete(units, events, rng, tick_index)
		if result != null:
			return result
	assert(false, "canonical battle exceeded tick guard")
	return BattleResult.new(-1, tick_index, [], events, rng.next_int(0, 9_999))


static func _acts_before(a: BattleUnit, b: BattleUnit) -> bool:
	var a_overflow := a.action_meter - BattleUnit.ACTION_THRESHOLD
	var b_overflow := b.action_meter - BattleUnit.ACTION_THRESHOLD
	if a_overflow != b_overflow:
		return a_overflow > b_overflow
	if a.speed != b.speed:
		return a.speed > b.speed
	if a.slot != b.slot:
		return a.slot < b.slot
	return a.unit_id < b.unit_id


static func _targets_before(a: BattleUnit, b: BattleUnit) -> bool:
	if a.slot != b.slot:
		return a.slot < b.slot
	return a.unit_id < b.unit_id


static func _live_targets(units: Array[BattleUnit], actor_team: int) -> Array[BattleUnit]:
	var targets: Array[BattleUnit] = []
	for candidate in units:
		if candidate.is_alive() and candidate.team != actor_team:
			targets.append(candidate)
	return targets


static func _finish_result_if_complete(
	units: Array[BattleUnit], events: Array, rng: DeterministicBattleRng, tick_index: int
) -> BattleResult:
	var alive_teams: Dictionary = {}
	for unit in units:
		if unit.is_alive():
			alive_teams[unit.team] = true
	if alive_teams.size() > 1:
		return null
	var winner := -1 if alive_teams.is_empty() else int(alive_teams.keys()[0])
	var snapshots: Array = []
	for unit in units:
		snapshots.append(unit.snapshot())
	snapshots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["unit_id"] < b["unit_id"]
	)
	return BattleResult.new(winner, tick_index, snapshots, events, rng.next_int(0, 9_999))

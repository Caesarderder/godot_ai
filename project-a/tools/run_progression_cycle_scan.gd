extends SceneTree

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const CombatPowerScript := preload("res://game/scripts/domain/progression/combat_power.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const HeroProgressionScript := preload("res://game/scripts/domain/progression/hero_progression.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")
const NewPlayerWelfareServiceScript := preload("res://game/scripts/domain/meta/new_player_welfare_service.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

const RUN_SEEDS: Array[int] = [20260721, 20260722, 20260723, 20260724, 20260725, 20260726, 20260727]
const CYCLE_STAGES: Array[Array] = [
	["stage_2_1", "stage_2_2", "stage_2_3", "stage_2_4", "stage_2_5"],
	["stage_2_5", "stage_3_1", "stage_3_2", "stage_3_3", "stage_3_4", "stage_3_5"],
]

var failures: Array[String] = []


func _init() -> void:
	for run_seed in RUN_SEEDS:
		_scan_seed(run_seed)
	if failures.is_empty():
		print("PROGRESSION CYCLE SCAN PASS: %d seeds, 4-win then 5-win growth cycles" % RUN_SEEDS.size())
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROGRESSION CYCLE SCAN FAIL: %d issue(s)" % failures.size())
	quit(1)


func _scan_seed(run_seed: int) -> void:
	var state: RefCounted = _post_chapter_one_state(run_seed)
	var welfare_claim := NewPlayerWelfareServiceScript.claim(state)
	if not bool(welfare_claim.get("ok", false)):
		failures.append("seed %d could not claim new-player welfare" % run_seed)
	var case_open := NewPlayerWelfareServiceScript.open_logistics_case(state)
	if not bool(case_open.get("ok", false)):
		failures.append("seed %d could not open smuggled logistics case" % run_seed)
	var welfare_target: RefCounted = null
	for hero in state.roster:
		if int(hero.star) == 1:
			welfare_target = hero
			break
	if welfare_target == null:
		failures.append("seed %d has no one-star welfare target" % run_seed)
	else:
		var welfare_core := NewPlayerWelfareServiceScript.use_star_core(
			state,
			String(welfare_target.hero_id)
		)
		if not bool(welfare_core.get("ok", false)):
			failures.append("seed %d could not use contraband star core" % run_seed)
	for cycle_index in CYCLE_STAGES.size():
		var growth_actions := _spend_greedily(state)
		if growth_actions <= 0:
			failures.append("seed %d cycle %d has no affordable permanent growth" % [run_seed, cycle_index + 1])
		var remaining_growth := _first_affordable_growth(state)
		if not remaining_growth.is_empty():
			failures.append(
				"seed %d cycle %d greedy spending left affordable growth: %s"
				% [run_seed, cycle_index + 1, remaining_growth]
			)
		var cycle_rows: Array[Dictionary] = []
		for stage_index in CYCLE_STAGES[cycle_index].size():
			var stage_id := String(CYCLE_STAGES[cycle_index][stage_index])
			var row := _simulate(state, stage_id)
			cycle_rows.append(row)
			var expected_wins := 5
			var expected := "victory"
			if stage_index < expected_wins and String(row["outcome"]) != expected:
				failures.append(
					"seed %d cycle %d %s expected %s, got %s (CP %d / recommended %d)"
					% [
						run_seed,
						cycle_index + 1,
						stage_id,
						expected,
						String(row["outcome"]),
						int(row["cp"]),
						int(row["recommended"]),
					]
				)
			if cycle_index == 0 and stage_id == "stage_2_5" and String(row["outcome"]) == "defeat":
				if (
					int(row["stage_reached"]) < 2
					or int(row["structures_destroyed"]) < 3
					or int(row["ticks"]) < 225
					or int(row["final_target_hp_ratio_bp"]) >= 9700
				):
					failures.append(
						"seed %d first Boss wall must reach and visibly damage the core, got stage %d, %d structures, %d ticks, %dbp target HP"
						% [
							run_seed,
							int(row["stage_reached"]),
							int(row["structures_destroyed"]),
							int(row["ticks"]),
							int(row["final_target_hp_ratio_bp"]),
						]
					)
			if String(row["outcome"]) == "victory":
				_grant_conservative_first_clear(state, stage_id)
		print(JSON.stringify({
			"seed": run_seed,
			"cycle": cycle_index + 1,
			"growth_actions": growth_actions,
			"rows": cycle_rows,
			"coins_after": int(state.economy.toilet_coins),
			"materials_after": state.factory.materials,
			"shards_after": int(state.economy.hero_shards),
			"chips_after": int(state.economy.skill_chips),
		}))


func _post_chapter_one_state(run_seed: int) -> RefCounted:
	var state: RefCounted = GameStateScript.create_new(run_seed, 1000, false)
	var assault: RefCounted = HeroGeneratorScript.generate_archetype(run_seed, 1, "assault", "fighter")
	var armored: RefCounted = HeroGeneratorScript.generate_archetype(run_seed, 2, "armored", "guardian")
	assault.star = 2
	state.roster.append(assault)
	state.roster.append(armored)
	state.formation.slots["troop_1"] = assault.hero_id
	state.formation.slots["troop_2"] = armored.hero_id
	state.economy.toilet_coins = 600
	state.economy.industrial_tech = 28
	state.economy.hero_shards = 12
	state.economy.skill_chips = 3
	state.meta_progression.hero_fragments = {
		"assault": 40,
		"armored": 40,
	}
	state.factory.materials = {"porcelain": 216, "parts": 145, "sludge": 113}
	state.factory.facilities["research_lab"] = 1
	state.stage_progress = {
		"highest_unlocked_stage": "stage_2_1",
		"cleared_stages": [
			"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
		],
	}
	return state


func _spend_greedily(state: RefCounted) -> int:
	var actions := 0
	while true:
		var acted := false
		for current_star in [1, 2]:
			for hero_id in _growth_priority_ids(state):
				var hero: RefCounted = state.hero_by_id(String(hero_id))
				if int(hero.star) != current_star:
					continue
				var result := LogisticsServiceScript.upgrade_star(state, String(hero_id))
				if bool(result.get("ok", false)):
					actions += 1
					acted = true
					break
			if acted:
				break
		if acted:
			continue
		var has_three_star := false
		for hero_id in state.formation.hero_ids():
			if int(state.hero_by_id(String(hero_id)).star) >= 3:
				has_three_star = true
				break
		if has_three_star:
			for hero_id in _growth_priority_ids(state):
				var result := LogisticsServiceScript.research_active_skill(state, String(hero_id))
				if bool(result.get("ok", false)):
					actions += 1
					acted = true
					break
		if acted:
			continue
		var ordered_heroes: Array[RefCounted] = []
		for hero_id in state.formation.hero_ids():
			ordered_heroes.append(state.hero_by_id(String(hero_id)))
		ordered_heroes.sort_custom(func(left: RefCounted, right: RefCounted) -> bool:
			if int(left.level) == int(right.level):
				return String(left.hero_id) < String(right.hero_id)
			return int(left.level) < int(right.level)
		)
		for hero in ordered_heroes:
			var result := LogisticsServiceScript.upgrade_hero(state, String(hero.hero_id))
			if bool(result.get("ok", false)):
				actions += 1
				acted = true
				break
		if acted:
			continue
		if not acted:
			break
	return actions


func _growth_priority_ids(state: RefCounted) -> Array[String]:
	var values: Array[String] = []
	for archetype_id in ["assault", "armored", "gman"]:
		for hero_id in state.formation.hero_ids():
			var hero: RefCounted = state.hero_by_id(String(hero_id))
			if String(hero.archetype_id) == archetype_id:
				values.append(String(hero_id))
	return values


func _first_affordable_growth(state: RefCounted) -> String:
	for hero_id in state.formation.hero_ids():
		var stable_id := String(hero_id)
		var star_probe: RefCounted = state.deep_clone()
		if bool(LogisticsServiceScript.upgrade_star(star_probe, stable_id).get("ok", false)):
			return "star:%s" % stable_id
		var level_probe: RefCounted = state.deep_clone()
		if bool(LogisticsServiceScript.upgrade_hero(level_probe, stable_id).get("ok", false)):
			return "level:%s" % stable_id
		var skill_probe: RefCounted = state.deep_clone()
		if bool(LogisticsServiceScript.research_active_skill(skill_probe, stable_id).get("ok", false)):
			return "skill:%s" % stable_id
	return ""


func _grant_conservative_first_clear(state: RefCounted, stage_id: String) -> void:
	# The production settlement randomizes each material and coin reward by -20%..+20%.
	# Use the exact lower bound here so every passing route survives the least generous ledger.
	var reward := StageCatalogScript.reward_for(stage_id, "victory")
	state.economy.toilet_coins += int(int(reward.get("gold", 0)) * 80 / 100)
	state.economy.industrial_tech += 4
	state.economy.grant(StageCatalogScript.breakthrough_reward(stage_id, false))
	state.factory.grant({
		"porcelain": int(int(reward.get("porcelain", 0)) * 80 / 100),
		"parts": int(int(reward.get("parts", 0)) * 80 / 100),
		"sludge": int(int(reward.get("sludge", 0)) * 80 / 100),
	})
	for hero_id in state.formation.hero_ids():
		var hero: RefCounted = state.hero_by_id(String(hero_id))
		hero.xp = mini(320, int(hero.xp) + 30)


func _simulate(state: RefCounted, stage_id: String) -> Dictionary:
	var snapshots := _snapshots(state)
	var session: RefCounted = BattleSessionScript.new()
	var stage_config := StageCatalogScript.stage(stage_id)
	session.start(snapshots, stage_id, stage_config)
	var safety := 0
	var last_snapshot: Dictionary = session.snapshot()
	while not session.is_finished and safety < 10000:
		var snapshot := session.snapshot() as Dictionary
		last_snapshot = snapshot
		for unit_value in snapshot.get("units", []):
			var unit := unit_value as Dictionary
			if (
				not bool(unit.get("temporary", false))
				and bool(unit.get("alive", false))
				and int(unit.get("energy", 0)) >= BattleSessionScript.SKILL_COST
			):
				session.request_skill(StringName(String(unit.get("unit_id", ""))))
		session.advance_tick()
		safety += 1
	var final_target_hp_ratio_bp := 10000
	var final_structure_id := String(stage_config.get("final_structure_id", "alliance_core"))
	for structure_value in last_snapshot.get("structures", []):
		var structure := structure_value as Dictionary
		if String(structure.get("structure_id", "")) != final_structure_id:
			continue
		final_target_hp_ratio_bp = int(
			int(structure.get("hp", 0))
			* 10000
			/ maxi(1, int(structure.get("max_hp", 1)))
		)
		break
	return {
		"stage_id": stage_id,
		"outcome": String(session.result.get("outcome", "timeout")),
		"ticks": int(session.result.get("ticks", safety)),
		"stage_reached": int(session.result.get("stage_reached", -1)),
		"structures_destroyed": int(session.result.get("structures_destroyed", 0)),
		"final_target_hp_ratio_bp": final_target_hp_ratio_bp,
		"cp": CombatPowerScript.snapshots_power(snapshots),
		"recommended": int(StageCatalogScript.stage(stage_id).get("recommended_power", 0)),
	}


func _snapshots(state: RefCounted) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for slot in state.formation.hero_ids().size():
		var hero: RefCounted = state.hero_by_id(String(state.formation.hero_ids()[slot]))
		var stats := HeroProgressionScript.derived_battle_stats(hero)
		values.append({
			"hero_id": hero.hero_id,
			"display_name": hero.display_name,
			"archetype_id": hero.archetype_id,
			"class_id": hero.class_id,
			"star": hero.star,
			"max_hp": int(stats["hp"]),
			"attack": int(stats["attack"]),
			"defense": int(stats["defense"]),
			"speed_milli": int(stats["speed_milli"]),
			"crit_bp": int(stats["crit_bp"]),
			"slot": slot,
			"skill_id": FactoryCatalogScript.active_skill_for_archetype(hero.archetype_id),
			"skill_level": int(hero.active_skill_level),
			"auto_skill": false,
		})
	return values

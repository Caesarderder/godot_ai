extends SceneTree

const BattleSession := preload("res://game/scripts/domain/battle/battle_session.gd")
const CombatPower := preload("res://game/scripts/domain/progression/combat_power.gd")
const FactoryCatalog := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactoryService := preload("res://game/scripts/domain/factory/factory_service.gd")
const GameState := preload("res://game/scripts/state/game_state.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")

const RUN_SEEDS: Array[int] = [20260721, 20260722, 20260723, 20260724, 20260725, 20260726, 20260727]
const STAGES: Array[String] = ["stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5"]


func _init() -> void:
	var rows: Array[Dictionary] = []
	var failures: Array[String] = []
	for run_seed in RUN_SEEDS:
		var state: RefCounted = GameState.create_new(run_seed, 1000)
		var snapshots := _snapshots(state)
		var starter_max_hp := -1
		var starter_attack := -1
		for stage_id in STAGES:
			var row := _simulate(run_seed, snapshots, stage_id)
			row["scenario"] = "starter"
			rows.append(row)
			if stage_id in ["stage_1_1", "stage_1_2", "stage_1_3"]:
				if starter_max_hp < 0:
					starter_max_hp = int(row["initial_max_hp"])
					starter_attack = int(row["initial_attack"])
				elif int(row["initial_max_hp"]) != starter_max_hp or int(row["initial_attack"]) != starter_attack:
					failures.append("%s seed %d must not override starter G-Toilet stats by stage" % [stage_id, run_seed])
			var outcome := String(row["outcome"])
			if stage_id in ["stage_1_1", "stage_1_2", "stage_1_3"] and outcome != "victory":
				failures.append("%s seed %d should clear with the starter legion" % [stage_id, run_seed])
			if stage_id == "stage_1_1" and (int(row["ticks"]) < 200 or int(row["ticks"]) > 300):
				failures.append("stage_1_1 seed %d should finish in 40-60 seconds, got %d ticks" % [run_seed, int(row["ticks"])])
			if stage_id == "stage_1_3":
				var final_hp := int(row["final_gman_hp"])
				var max_hp := maxi(1, int(row["final_gman_max_hp"]))
				if final_hp <= 0 or final_hp * 5 > max_hp * 2:
					failures.append("stage_1_3 seed %d should leave starter G-Toilet alive at 40%% health or less" % run_seed)
				if int(row["ticks"]) < 250 or int(row["ticks"]) > 350:
					failures.append("stage_1_3 seed %d should finish in 50-70 seconds, got %d ticks" % [run_seed, int(row["ticks"])])
			if stage_id in ["stage_1_4", "stage_1_5"] and outcome == "victory":
				failures.append("%s seed %d should preserve the intended first growth wall" % [stage_id, run_seed])
			var ratio := float(row["cp"]) / float(maxi(1, int(row["recommended"])))
			if stage_id in ["stage_1_1", "stage_1_2", "stage_1_3"] and (ratio < 0.95 or ratio > 1.10):
				failures.append("%s seed %d should display in the target capability band" % [stage_id, run_seed])
			if stage_id == "stage_1_4" and ratio >= 0.85:
				failures.append("stage_1_4 seed %d solo G-Toilet should display as underpowered" % run_seed)
		var reinforced := _reinforced_snapshots(state)
		var reinforced_row := _simulate(run_seed, reinforced, "stage_1_4")
		reinforced_row["scenario"] = "two_blueprint_reinforcement"
		rows.append(reinforced_row)
		if String(reinforced_row["outcome"]) != "victory":
			failures.append("stage_1_4 seed %d should clear after both blueprint heroes deploy" % run_seed)
		var solo_wall_row: Dictionary = {}
		for candidate in rows:
			if int(candidate.get("seed", -1)) == run_seed \
					and String(candidate.get("scenario", "")) == "starter" \
					and String(candidate.get("stage_id", "")) == "stage_1_4":
				solo_wall_row = candidate
				break
		var solo_death_ratio := float(solo_wall_row.get("ticks", 0)) / float(maxi(1, int(reinforced_row["ticks"])))
		if solo_death_ratio < 0.40 or solo_death_ratio > 0.65:
			failures.append("stage_1_4 seed %d should kill solo G-Toilet around the midpoint, ratio %.2f" % [run_seed, solo_death_ratio])
		var reinforced_ratio := float(reinforced_row["cp"]) / float(maxi(1, int(reinforced_row["recommended"])))
		if reinforced_ratio < 0.95 or reinforced_ratio > 1.10:
			failures.append("stage_1_4 seed %d reinforced CP should match the displayed capability band" % run_seed)
		var boss_probe := _simulate(run_seed, reinforced, "stage_1_5")
		boss_probe["scenario"] = "two_blueprint_boss_probe"
		rows.append(boss_probe)
		# The authored onboarding gate requires a visible growth choice before
		# this battle can start. The ungated probe is diagnostic only: rare
		# high-roll clears are acceptable as long as both chosen growth routes
		# remain reliable below.
		for hero_id in state.formation.hero_ids():
			var growth_state: RefCounted = state.deep_clone()
			var upgrade := preload("res://game/scripts/domain/factory/logistics_service.gd").upgrade_hero(growth_state, String(hero_id))
			if bool(upgrade.get("ok", false)):
				var growth_probe := _simulate(run_seed, _snapshots(growth_state), "stage_1_5")
				growth_probe["scenario"] = "boss_probe_one_level"
				growth_probe["upgraded_hero_id"] = String(hero_id)
				growth_probe["power_gain"] = int((upgrade.get("event", {}) as Dictionary).get("power_gain", 0))
				rows.append(growth_probe)
		var team_growth_state: RefCounted = state.deep_clone()
		var team_upgrades := 0
		for hero_id in team_growth_state.formation.hero_ids():
			var team_upgrade := preload("res://game/scripts/domain/factory/logistics_service.gd").upgrade_hero(team_growth_state, String(hero_id))
			if bool(team_upgrade.get("ok", false)):
				team_upgrades += 1
		var team_growth_probe := _simulate(run_seed, _snapshots(team_growth_state), "stage_1_5")
		team_growth_probe["scenario"] = "boss_probe_team_level"
		team_growth_probe["upgrade_count"] = team_upgrades
		rows.append(team_growth_probe)
		for hero_id in state.formation.hero_ids():
			var star_state: RefCounted = state.deep_clone()
			star_state.economy.hero_shards = 4
			var star_upgrade := preload("res://game/scripts/domain/factory/logistics_service.gd").upgrade_star(star_state, String(hero_id))
			if bool(star_upgrade.get("ok", false)):
				var star_probe := _simulate(run_seed, _snapshots(star_state), "stage_1_5")
				var upgraded_hero: RefCounted = star_state.hero_by_id(String(hero_id))
				var upgraded_archetype := String(upgraded_hero.archetype_id)
				star_probe["scenario"] = "boss_probe_one_star"
				star_probe["upgraded_hero_id"] = String(hero_id)
				star_probe["upgraded_archetype"] = upgraded_archetype
				rows.append(star_probe)
				if upgraded_archetype in ["assault", "armored"] \
						and (
							String(star_probe["outcome"]) != "victory"
							or int(star_probe["ticks"]) < 350
							or int(star_probe["ticks"]) > 600
						):
					failures.append("stage_1_5 seed %d %s star route should clear in 70-120 seconds" % [run_seed, upgraded_archetype])
	if failures.is_empty():
		var starter_powers: Array[int] = []
		for row in rows:
			if String(row["stage_id"]) == "stage_1_1":
				starter_powers.append(int(row["cp"]))
			print(JSON.stringify(row))
		print("FIRST CHAPTER BALANCE SCAN PASS: %d deterministic battles, starter CP %d-%d" % [
			rows.size(),
			starter_powers.min(),
			starter_powers.max(),
		])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	for row in rows:
		print(JSON.stringify(row))
	print("FIRST CHAPTER BALANCE SCAN FAIL: %d issue(s)" % failures.size())
	quit(1)


func _snapshots(state: RefCounted) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for slot in state.formation.hero_ids().size():
		var hero: RefCounted = state.hero_by_id(String(state.formation.hero_ids()[slot]))
		var stats := HeroProgression.derived_battle_stats(hero)
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
			"skill_id": FactoryCatalog.active_skill_for_archetype(hero.archetype_id),
			"skill_level": int(hero.active_skill_level),
			"auto_skill": true,
		})
	return values


func _reinforced_snapshots(state: RefCounted) -> Array[Dictionary]:
	state.factory.facilities["research_lab"] = 1
	var now_unix := 1000
	for recipe_id in ["ordinary.assault", "heavy.armored"]:
		state.factory.blueprints.erase(recipe_id)
		state.factory.discovered_blueprints[recipe_id] = true
		var research := FactoryService.unlock_foundational_blueprint(state, recipe_id, now_unix)
		if not bool(research.get("ok", false)):
			push_error("Could not start foundational research for %s: %s" % [
				recipe_id,
				String(research.get("error", "UNKNOWN")),
			])
			continue
		var completes_at_unix := int((research.get("event", {}) as Dictionary).get("completes_at_unix", now_unix))
		var claim := FactoryService.claim_foundational_blueprint(state, completes_at_unix)
		if not bool(claim.get("ok", false)):
			push_error("Could not claim foundational research for %s: %s" % [
				recipe_id,
				String(claim.get("error", "UNKNOWN")),
			])
			continue
		var hero_id := String((claim.get("event", {}) as Dictionary).get("hero_id", ""))
		if hero_id.is_empty() or not state.formation.assign_next_troop(hero_id):
			push_error("Could not deploy foundational hero for %s" % recipe_id)
		now_unix = completes_at_unix + 1
	return _snapshots(state)


func _simulate(run_seed: int, snapshots: Array[Dictionary], stage_id: String) -> Dictionary:
	var session: RefCounted = BattleSession.new()
	var config := StageCatalog.stage(stage_id)
	session.start(snapshots, stage_id, config)
	var initial_units: Array = session.snapshot().get("units", [])
	var initial_gman: Dictionary = initial_units[0] if not initial_units.is_empty() else {}
	var safety := 0
	while not session.is_finished and safety < 10000:
		session.advance_tick()
		safety += 1
	var result: Dictionary = session.result
	return {
		"seed": run_seed,
		"stage_id": stage_id,
		"cp": CombatPower.snapshots_power(snapshots),
		"recommended": int(config.get("recommended_power", 0)),
		"initial_max_hp": int(initial_gman.get("max_hp", 0)),
		"initial_attack": int(initial_gman.get("attack", 0)),
		"outcome": String(result.get("outcome", "timeout")),
		"final_gman_hp": int(result.get("gman_hp", 0)),
		"final_gman_max_hp": int(result.get("gman_max_hp", 0)),
		"ticks": int(result.get("ticks", safety)),
		"dead": (result.get("dead_unit_ids", []) as Array).size(),
		"ally_damage": int(result.get("ally_damage_taken", 0)),
		"troop_damage": int(result.get("troop_damage_taken", 0)),
		"reason": String(result.get("reason", "")),
	}

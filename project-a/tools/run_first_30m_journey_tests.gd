extends SceneTree

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroProgressionScript := preload("res://game/scripts/domain/progression/hero_progression.gd")
const OnboardingServiceScript := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")
const SaveManagerCoreScript := preload("res://game/scripts/persistence/save_manager.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

const RUN_SEEDS: Array[int] = [20260721, 20260722, 20260723, 20260724, 20260725, 20260726, 20260727]
const GROWTH_ROUTES: Array[String] = ["ordinary.assault", "heavy.armored"]
const SESSION_LIMIT_SECONDS := 30 * 60
const INTERACTION_SECONDS := 8

var failures: Array[String] = []
var command_serial := 0


func _init() -> void:
	for run_seed in RUN_SEEDS:
		for growth_route in GROWTH_ROUTES:
			_run_seed_journey(run_seed, growth_route)
	if failures.is_empty():
		print("FIRST_30M_JOURNEY_TESTS_OK: %d clean-save economic journeys" % (RUN_SEEDS.size() * GROWTH_ROUTES.size()))
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FIRST_30M_JOURNEY_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _run_seed_journey(run_seed: int, growth_route: String) -> void:
	var route_slug := growth_route.replace(".", "_")
	var save_path := "user://first_30m_journey_%d_%s.json" % [run_seed, route_slug]
	var manager: RefCounted = SaveManagerCoreScript.new(save_path)
	manager.delete_local_save()
	var state: RefCounted = GameStateScript.create_new(run_seed, 1000, false)
	var executor: RefCounted = CommandExecutorScript.new(state, manager.save_state)
	var clock := 1000
	var battle_seconds := 0

	var opening := _battle_and_settle(executor, "stage_1_1", clock)
	clock += int(opening.get("seconds", 0)) + INTERACTION_SECONDS
	battle_seconds += int(opening.get("seconds", 0))
	_expect_outcome(run_seed, "stage_1_1", opening, "victory")

	for stage_id in ["stage_1_2", "stage_1_3"]:
		var result := _battle_and_settle(executor, stage_id, clock)
		clock += int(result.get("seconds", 0)) + INTERACTION_SECONDS
		battle_seconds += int(result.get("seconds", 0))
		_expect_outcome(run_seed, stage_id, result, "victory")

	var wall := _battle_and_settle(executor, "stage_1_4", clock)
	clock += int(wall.get("seconds", 0)) + INTERACTION_SECONDS
	battle_seconds += int(wall.get("seconds", 0))
	_expect_outcome(run_seed, "stage_1_4 first attempt", wall, "defeat")

	var construction := _command(executor, "construct_facility", {
		"facility_id": "research_lab",
		"now_unix": clock,
		"grid_x": 2,
		"grid_z": 1,
	}, clock)
	_expect_ok(run_seed, construction, "research lab construction starts without injected currency")
	var construction_done := int((construction.get("event", {}) as Dictionary).get("completes_at_unix", clock))
	clock = construction_done
	_expect_ok(run_seed, _command(executor, "claim_facility_work", {"now_unix": clock}, clock), "research lab completes")
	clock += INTERACTION_SECONDS

	var breakthrough := _command(executor, "claim_research_breakthrough", {}, clock)
	_expect_ok(run_seed, breakthrough, "research breakthrough ten-pull resolves exactly once")
	var researched_hero_ids: Dictionary = {}
	for item_value in (breakthrough.get("event", {}) as Dictionary).get("results", []):
		var item := item_value as Dictionary
		if String(item.get("kind", "")) != "hero":
			continue
		var recipe_id := String(item.get("recipe_id", ""))
		if not recipe_id.is_empty():
			researched_hero_ids[recipe_id] = String(item.get("hero_id", ""))
	clock += INTERACTION_SECONDS

	_expect_ok(run_seed, _command(executor, "assign_formation_slot", {
		"slot": "troop_1",
		"hero_id": String(researched_hero_ids.get("ordinary.assault", "")),
	}, clock), "assault hero joins the formation")
	clock += INTERACTION_SECONDS
	_expect_ok(run_seed, _command(executor, "assign_formation_slot", {
		"slot": "troop_2",
		"hero_id": String(researched_hero_ids.get("heavy.armored", "")),
	}, clock), "armored hero joins the formation")
	clock += INTERACTION_SECONDS

	var revenge := _battle_and_settle(executor, "stage_1_4", clock)
	clock += int(revenge.get("seconds", 0)) + INTERACTION_SECONDS
	battle_seconds += int(revenge.get("seconds", 0))
	_expect_outcome(run_seed, "stage_1_4 revenge", revenge, "victory")

	var growth_hero_id := String(researched_hero_ids.get(growth_route, ""))
	var star_upgrade := _command(executor, "upgrade_hero_star", {"hero_id": growth_hero_id}, clock)
	_expect_ok(run_seed, star_upgrade, "%s two-star route is affordable from the real ledger" % growth_route)
	clock += INTERACTION_SECONDS

	var boss := _battle_and_settle(executor, "stage_1_5", clock)
	clock += int(boss.get("seconds", 0)) + INTERACTION_SECONDS
	battle_seconds += int(boss.get("seconds", 0))
	_expect_outcome(run_seed, "stage_1_5 %s route" % growth_route, boss, "victory")

	var snapshot := OnboardingServiceScript.snapshot(executor.state)
	_check(run_seed, bool(snapshot.get("finished", false)), "seven-action onboarding reaches its durable finished state")
	_check(run_seed, clock - 1000 <= SESSION_LIMIT_SECONDS, "modeled journey remains within 30 minutes")
	_check(run_seed, int(executor.state.economy.toilet_coins) >= 0, "coin ledger never needs injected currency")
	for material_id in ["porcelain", "parts", "sludge"]:
		_check(run_seed, int(executor.state.factory.materials.get(material_id, -1)) >= 0, "%s ledger stays non-negative" % material_id)
	var loaded: Dictionary = manager.load_state()
	_check(run_seed, bool(loaded.get("ok", false)), "final first-session save reloads")
	if bool(loaded.get("ok", false)):
		var loaded_snapshot := OnboardingServiceScript.snapshot(loaded["state"])
		_check(run_seed, bool(loaded_snapshot.get("finished", false)), "first-session completion survives save reload")
		_check(run_seed, int(loaded["state"].revision) == int(executor.state.revision), "save revision matches the final command")
	print(JSON.stringify({
		"seed": run_seed,
		"growth_route": growth_route,
		"elapsed_seconds": clock - 1000,
		"battle_seconds": battle_seconds,
		"coins_after": int(executor.state.economy.toilet_coins),
		"materials_after": executor.state.factory.materials,
		"revision": int(executor.state.revision),
	}))
	manager.delete_local_save()


func _battle_and_settle(executor: RefCounted, stage_id: String, now_unix: int) -> Dictionary:
	var session: RefCounted = BattleSessionScript.new()
	session.start(_snapshots(executor.state), stage_id, StageCatalogScript.stage(stage_id))
	var safety := 0
	while not session.is_finished and safety < 10000:
		session.advance_tick()
		safety += 1
	if not session.is_finished:
		return {"outcome": "timeout", "seconds": 2000, "settlement_ok": false}
	var runtime := session.result as Dictionary
	var settlement := _command(executor, "settle_battle", {
		"battle_id": "first30-%s-%d" % [stage_id, command_serial],
		"stage_id": stage_id,
		"outcome": String(runtime.get("outcome", "defeat")),
		"ticks": maxi(1, int(runtime.get("ticks", 1))),
		"deployed_unit_ids": (runtime.get("deployed_unit_ids", []) as Array).duplicate(),
		"dead_unit_ids": (runtime.get("dead_unit_ids", []) as Array).duplicate(),
	}, now_unix)
	return {
		"outcome": String(runtime.get("outcome", "defeat")),
		"seconds": int(ceil(float(runtime.get("ticks", 1)) / BattleSessionScript.TICKS_PER_SECOND)),
		"settlement_ok": bool(settlement.get("ok", false)),
		"settlement_error": String(settlement.get("error", "")),
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
			"max_hp": int(stats["max_hp"]),
			"attack": maxi(int(stats["physical_atk"]), int(stats["magic_atk"])),
			"defense": int(stats["defense"]),
			"speed_milli": int(stats["speed_milli"]),
			"crit_bp": int(stats["crit_bp"]),
			"slot": slot,
			"skill_id": FactoryCatalogScript.active_skill_for_archetype(hero.archetype_id),
			"skill_level": int(hero.active_skill_level),
			"auto_skill": true,
		})
	return values


func _command(executor: RefCounted, type: String, payload: Dictionary, now_unix: int) -> Dictionary:
	command_serial += 1
	return executor.execute({
		"command_id": "first30-command-%d" % command_serial,
		"type": type,
		"payload": payload,
		"business_key": "first30-business-%d" % command_serial,
		"expected_revision": executor.state.revision,
		"requested_at": now_unix,
	})


func _expect_outcome(run_seed: int, stage_label: String, result: Dictionary, expected: String) -> void:
	_check(run_seed, String(result.get("outcome", "")) == expected, "%s outcome is %s" % [stage_label, expected])
	_check(run_seed, bool(result.get("settlement_ok", false)), "%s settlement succeeds: %s" % [stage_label, result.get("settlement_error", "")])


func _expect_ok(run_seed: int, result: Dictionary, message: String) -> void:
	_check(run_seed, bool(result.get("ok", false)), "%s: %s" % [message, result.get("error", "")])


func _check(run_seed: int, condition: bool, message: String) -> void:
	if not condition:
		failures.append("seed %d: %s" % [run_seed, message])

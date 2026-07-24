extends SceneTree

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

var failures: Array[String] = []
var save_calls: int = 0


func _init() -> void:
	_test_new_save_starts_with_eight_heroes_and_six_unit_formation()
	_test_factory_start_claim_consumes_materials_and_uses_monotonic_ids()
	_test_three_matching_armored_heroes_merge_into_two_star_and_keep_formation_valid()
	_test_actual_formation_runs_battle_and_settlement_rewards_are_exact_once()
	_test_first_loss_growth_retry_victory_path()
	if failures.is_empty():
		print("LIFECYCLE TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LIFECYCLE TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _test_new_save_starts_with_eight_heroes_and_six_unit_formation() -> void:
	var state: RefCounted = GameStateScript.create_new(20260724, 1000)
	_eq(state.roster.size(), 8, "new save starts with eight heroes for factory/cultivation onboarding")
	_eq(state.formation.hero_ids().size(), 6, "new save has six formation slots")
	_ok(state.validate().is_empty(), "new save formation references valid roster heroes")


func _test_factory_start_claim_consumes_materials_and_uses_monotonic_ids() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(20260724, 1000), Callable(self, "_record_save_success"))
	var initial_ids: Array[String] = executor.state.roster_ids()
	var sequence_before: int = executor.state.factory.next_hero_sequence
	var materials_before: Dictionary = executor.state.factory.materials.duplicate(true)
	var start := _exec_ok(executor, "life-factory-start", "start_production", {"recipe_id": "ordinary.assault", "now_unix": 2000}, "life:factory:start")
	_eq(start["event"]["completes_at_unix"], 2005, "ordinary assault production completes after five seconds")
	_eq(executor.state.factory.materials["porcelain"], int(materials_before["porcelain"]) - 20, "starting production deducts porcelain immediately")
	_eq(executor.state.factory.materials["parts"], int(materials_before["parts"]) - 8, "starting production deducts parts immediately")
	_eq(executor.state.factory.materials["sludge"], int(materials_before["sludge"]) - 4, "starting production deducts sludge immediately")
	var claim := _exec_ok(executor, "life-factory-claim", "claim_production", {"order_id": "production_000001", "now_unix": 2005}, "life:factory:claim")
	var claimed_hero_id := String(claim["event"]["hero_id"])
	_ok(not initial_ids.has(claimed_hero_id), "claimed factory hero is permanent and not an existing starter id")
	_ok(String(claimed_hero_id).begins_with("hero_%04d_" % sequence_before), "claimed factory hero uses monotonic hero sequence")
	_eq(executor.state.roster.size(), 9, "claim adds exactly one permanent hero to roster")
	_eq(executor.state.factory.production_queue.size(), 0, "claim removes completed production order")


func _test_three_matching_armored_heroes_merge_into_two_star_and_keep_formation_valid() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(20260724, 1000), Callable(self, "_record_save_success"))
	var armored_ids := _hero_ids_by_archetype(executor.state, "armored")
	_eq(armored_ids.size(), 3, "starter roster exposes immediate three-armored cultivation path")
	var merge := _exec_ok(executor, "life-merge-armored", "merge_heroes", {"hero_ids": armored_ids}, "life:merge:armored")
	_eq(merge["event"]["star"], 2, "three matching one-star armored heroes produce a two-star hero")
	_eq(executor.state.roster.size(), 6, "three-to-one cultivation reduces roster by two")
	_ok(executor.state.formation.hero_ids().has(String(merge["event"]["hero_id"])), "merged hero remains deployed when a consumed hero was in formation")
	_ok(executor.state.validate().is_empty(), "cultivation keeps all six formation slots valid")


func _test_actual_formation_runs_battle_and_settlement_rewards_are_exact_once() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(20260724, 1000), Callable(self, "_record_save_success"))
	var armored_ids := _hero_ids_by_archetype(executor.state, "armored")
	_exec_ok(executor, "life-merge-before-battle", "merge_heroes", {"hero_ids": armored_ids}, "life:battle:merge")
	var snapshots := _build_battle_snapshots(executor.state)
	_eq(snapshots.size(), 6, "battle snapshot is built from the actual six-slot formation")
	var battle_result := _run_battle(snapshots)
	_ok(["victory", "defeat", "timeout"].has(String(battle_result["outcome"])), "actual formation battle resolves to a settlement outcome")
	var materials_before: Dictionary = executor.state.factory.materials.duplicate(true)
	var gold_before: int = executor.state.economy.gold
	var books_before: int = executor.state.economy.xp_books
	var settlement_payload := {
		"battle_id": "life-battle-0001",
		"outcome": String(battle_result["outcome"]),
		"ticks": int(battle_result["ticks"]),
	}
	var settlement := _exec_ok(executor, "life-settle-battle", "settle_battle", settlement_payload, "life:battle:0001")
	var reward: Dictionary = settlement["event"]["reward"]
	_assert_reward_delta(executor.state, materials_before, gold_before, books_before, reward, "first settlement applies reward once")
	var replay := executor.execute(_env_with_revision("life-settle-battle", "settle_battle", settlement_payload, "life:battle:0001", executor.state.revision - 1))
	_eq(replay, settlement, "replayed settlement returns original receipt")
	_assert_reward_delta(executor.state, materials_before, gold_before, books_before, reward, "replayed settlement does not duplicate reward")


func _test_first_loss_growth_retry_victory_path() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(20260725, 1000), Callable(self, "_record_save_success"))
	var power_before := _formation_power(executor.state)
	var first_result := _run_battle(_build_battle_snapshots(executor.state))
	_ok(String(first_result["outcome"]) != "victory", "ungrown starter squad loses or times out first battle")
	var settle := _exec_ok(
		executor,
		"life-first-loss-settle",
		"settle_battle",
		{"battle_id": "life-first-loss-0001", "outcome": String(first_result["outcome"]), "ticks": maxi(1, int(first_result["ticks"]))},
		"life:first-loss:0001"
	)
	_ok((settle["event"]["unlocked_blueprints"] as Array).has("heavy.armored"), "first loss unlocks heavy counterplay blueprint")
	_exec_ok(executor, "life-retry-produce-armored", "start_production", {"recipe_id": "heavy.armored", "now_unix": 1100}, "life:retry:produce:armored")
	var produced := _exec_ok(executor, "life-retry-claim-armored", "claim_production", {"order_id": "production_000001", "now_unix": 1112}, "life:retry:claim:armored")
	var produced_id := String(produced["event"]["hero_id"])
	var armored_ids := _hero_ids_by_archetype(executor.state, "armored")
	_ok(armored_ids.has(produced_id), "first-loss blueprint is used to produce a permanent armored counterplay hero")
	var merge_inputs: Array[String] = [armored_ids[0], armored_ids[1], produced_id]
	var merge := _exec_ok(executor, "life-retry-merge-armored", "merge_heroes", {"hero_ids": merge_inputs}, "life:retry:merge")
	var merged_id := String(merge["event"]["hero_id"])
	_eq(HeroProgression.skill_tier(executor.state.hero_by_id(merged_id)), 2, "three-to-one growth changes the armored active skill to tier two")
	_exec_ok(executor, "life-retry-train-merged", "train_hero", {"hero_id": merged_id, "book_count": 2}, "life:retry:train:merged")
	var repair_id := _hero_ids_by_archetype(executor.state, "repair")[0]
	_exec_ok(executor, "life-retry-train-repair", "train_hero", {"hero_id": repair_id, "book_count": 2}, "life:retry:train:repair")
	var reserves: Array[String] = _formation_fill_ids(executor.state, [merged_id, repair_id])
	var payload := {
		"front_left": merged_id,
		"front_center": repair_id,
		"front_right": reserves[0],
		"back_left": reserves[1],
		"back_center": reserves[2],
		"back_right": reserves[3],
	}
	_exec_ok(executor, "life-retry-formation", "set_formation", payload, "life:retry:formation")
	for hero_id in executor.state.formation.hero_ids():
		_exec_ok(executor, "life-auto-%s" % hero_id, "set_auto_skill_preference", {"hero_id": hero_id, "enabled": true}, "life:auto:%s" % hero_id)
	_ok(_formation_power(executor.state) > power_before, "production, merge, training, and reformation create a measurable combat-stat delta")
	var retry_result := _run_battle(_build_battle_snapshots(executor.state))
	_eq(retry_result["outcome"], "victory", "after merge/training/reformation/auto preferences, retry is deterministic victory")
	var materials_before: Dictionary = executor.state.factory.materials.duplicate(true)
	var gold_before: int = executor.state.economy.gold
	var books_before: int = executor.state.economy.xp_books
	var victory_settlement := _exec_ok(
		executor,
		"life-retry-victory-settle",
		"settle_battle",
		{"battle_id": "life-retry-victory-0001", "outcome": "victory", "ticks": int(retry_result["ticks"])},
		"life:retry:victory:0001"
	)
	_assert_reward_delta(executor.state, materials_before, gold_before, books_before, victory_settlement["event"]["reward"], "retry victory settlement applies rewards")
	_ok((executor.state.stage_progress["cleared_stages"] as Array).has("stage_1_1"), "retry victory persistently clears the challenged stage")
	_ok((victory_settlement["event"]["unlocked_blueprints"] as Array).has("special.parasite"), "core clear unlocks the capstone parasite blueprint")


func _run_battle(snapshots: Array[Dictionary]) -> Dictionary:
	var session: RefCounted = BattleSessionScript.new()
	session.start(snapshots)
	for hero in snapshots:
		if bool(hero.get("auto_skill_enabled", false)):
			session.set_auto_skill(StringName(String(hero["hero_id"])), true)
	while not session.is_finished:
		session.advance_tick()
	return session.result.duplicate(true)


func _build_battle_snapshots(state: RefCounted) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	var hero_ids: Array[String] = state.formation.hero_ids()
	for slot_index in 6:
		var hero: RefCounted = state.hero_by_id(hero_ids[slot_index])
		var stats: Dictionary = HeroProgression.derived_battle_stats(hero)
		snapshots.append({
			"hero_id": hero.hero_id,
			"display_name": hero.display_name,
			"archetype_id": hero.archetype_id,
			"class_id": hero.class_id,
			"star": hero.star,
			"max_hp": int(stats["max_hp"]),
			"attack": maxi(int(stats["physical_atk"]), int(stats["magic_atk"])),
			"defense": int(stats["defense"]),
			"slot": slot_index,
			"auto_skill_enabled": bool(hero.auto_skill_enabled),
			"skill_id": FactoryCatalogScript.active_skill_for_archetype(hero.archetype_id),
		})
	return snapshots


func _hero_ids_by_archetype(state: RefCounted, archetype_id: String) -> Array[String]:
	var ids: Array[String] = []
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			ids.append(String(hero.hero_id))
	return ids


func _formation_fill_ids(state: RefCounted, pinned: Array[String]) -> Array[String]:
	var ids: Array[String] = []
	for hero in state.roster:
		var hero_id := String(hero.hero_id)
		if not pinned.has(hero_id):
			ids.append(hero_id)
	return ids


func _formation_power(state: RefCounted) -> int:
	var total := 0
	for hero_id in state.formation.hero_ids():
		var hero: RefCounted = state.hero_by_id(hero_id)
		var stats: Dictionary = HeroProgression.derived_battle_stats(hero)
		total += int(stats["max_hp"]) + maxi(int(stats["physical_atk"]), int(stats["magic_atk"])) * 4 + int(stats["defense"]) * 2
	return total


func _assert_reward_delta(state: RefCounted, materials_before: Dictionary, gold_before: int, books_before: int, reward: Dictionary, message: String) -> void:
	_eq(state.economy.gold, gold_before + int(reward["gold"]), "%s: gold delta" % message)
	_eq(state.economy.xp_books, books_before + int(reward["xp_books"]), "%s: xp book delta" % message)
	_eq(state.factory.materials["porcelain"], int(materials_before["porcelain"]) + int(reward["porcelain"]), "%s: porcelain delta" % message)
	_eq(state.factory.materials["parts"], int(materials_before["parts"]) + int(reward["parts"]), "%s: parts delta" % message)
	_eq(state.factory.materials["sludge"], int(materials_before["sludge"]) + int(reward["sludge"]), "%s: sludge delta" % message)


func _exec_ok(executor: RefCounted, command_id: String, command_type: String, payload: Dictionary, business_key: String) -> Dictionary:
	var result: Dictionary = executor.execute(_env(command_id, command_type, payload, business_key, executor))
	_ok(bool(result.get("ok", false)), "command %s succeeds: %s" % [command_id, str(result)])
	return result


func _env(command_id: String, command_type: String, payload: Dictionary, business_key: String, executor: RefCounted) -> Dictionary:
	return _env_with_revision(command_id, command_type, payload, business_key, executor.state.revision)


func _env_with_revision(command_id: String, command_type: String, payload: Dictionary, business_key: String, expected_revision: int) -> Dictionary:
	return {
		"command_id": command_id,
		"type": command_type,
		"payload": payload,
		"business_key": business_key,
		"expected_revision": expected_revision,
		"requested_at": 0,
	}


func _record_save_success(_state: RefCounted) -> bool:
	save_calls += 1
	return true


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

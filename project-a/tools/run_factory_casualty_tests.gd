extends SceneTree

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_failure_settlement_is_lossless()
	_test_victory_uses_toilet_coins_only()
	_test_schema_v6_round_trip()
	_test_retreat_and_s_unique_rule()
	_test_legacy_v5_migrates_to_v6()
	_test_endless_frontier_continuation()
	if failures.is_empty():
		print("FACTORY_COMPATIBILITY_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FACTORY_COMPATIBILITY_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_failure_settlement_is_lossless() -> void:
	var state: RefCounted = GameStateScript.create_new(901, 100)
	var deployed: Array[String] = state.formation.hero_ids()
	var disabled: Array[String] = [deployed[0]]
	var readiness_before: Dictionary = {}
	for hero_id in deployed:
		readiness_before[hero_id] = int(state.hero_by_id(hero_id).readiness)
	var coins_before := int(state.economy.toilet_coins)
	var materials_before: Dictionary = state.factory.materials.duplicate(true)
	var executor: RefCounted = CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var settle: Dictionary = executor.execute({
		"type": "settle_battle",
		"command_id": "casualty-defeat-1",
		"business_key": "battle:casualty-defeat-1",
		"expected_revision": 0,
		"payload": {
			"battle_id": "casualty-defeat-1",
			"stage_id": "stage_1_1",
			"outcome": "defeat",
			"ticks": 40,
			"deployed_unit_ids": deployed,
			"dead_unit_ids": disabled,
		},
	})
	_expect(bool(settle.get("ok", false)), "defeat casualty settlement should succeed")
	for hero_id in disabled:
		_expect(executor.state.hero_by_id(hero_id) != null, "disabled permanent hero must remain owned: %s" % hero_id)
		_expect(int(executor.state.hero_by_id(hero_id).readiness) == int(readiness_before[hero_id]), "disabled hero must return fully ready after lossless settlement")
	_expect(int(executor.state.economy.toilet_coins) == coins_before, "defeat must grant zero toilet coins")
	_expect(executor.state.factory.materials == materials_before, "defeat must grant zero manufacturing materials")
	_expect(executor.state.formation.hero_ids() == deployed, "defeat must preserve permanent formation identities")
	_expect((settle.get("event", {}) as Dictionary).get("dead_unit_ids", []) == [], "lossless settlement must expose no persistent dead units")
	_expect((settle.get("event", {}) as Dictionary).get("damage_manifest", {}) == {}, "lossless settlement must expose no repair manifest")

	var replay: Dictionary = executor.execute({
		"type": "settle_battle",
		"command_id": "casualty-defeat-1",
		"business_key": "battle:casualty-defeat-1",
		"expected_revision": 0,
		"payload": {
			"battle_id": "casualty-defeat-1",
			"stage_id": "stage_1_1",
			"outcome": "defeat",
			"ticks": 40,
			"deployed_unit_ids": deployed,
			"dead_unit_ids": disabled,
		},
	})
	_expect(bool(replay.get("ok", false)), "identical settlement replay should return durable receipt")
	_expect(executor.state.revision == 1, "settlement replay must not mutate current state")


func _test_victory_uses_toilet_coins_only() -> void:
	var state: RefCounted = GameStateScript.create_new(902, 100)
	var executor: RefCounted = CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var coins_before := int(state.economy.toilet_coins)
	var legacy_gold_before := int(state.economy.gold)
	var settle: Dictionary = executor.execute({
		"type": "settle_battle",
		"command_id": "casualty-victory-1",
		"business_key": "battle:casualty-victory-1",
		"expected_revision": 0,
		"payload": {
			"battle_id": "casualty-victory-1",
			"stage_id": "stage_1_1",
			"outcome": "victory",
			"ticks": 25,
			"deployed_unit_ids": state.formation.hero_ids(),
			"dead_unit_ids": [],
		},
	})
	_expect(bool(settle.get("ok", false)), "victory settlement should succeed")
	_expect(int(executor.state.economy.toilet_coins) > coins_before, "victory must grant toilet coins")
	_expect(int(executor.state.economy.gold) == legacy_gold_before, "victory must not grant legacy gold")
	_expect((settle.get("event", {}) as Dictionary).get("unlocked_blueprints", []) == [], "stage must not drop blueprints")


func _test_blueprint_pity_duplicate_and_model_tech() -> void:
	var state: RefCounted = GameStateScript.create_new(903, 100)
	state.economy.toilet_gems = 320
	state.pity["s_pity_count"] = 99
	var executor: RefCounted = CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var first: Dictionary = executor.execute({
		"type": "draw_blueprints",
		"command_id": "draw-pity-first",
		"business_key": "draw:pity:first",
		"expected_revision": 0,
		"payload": {"count": 1, "target_s_recipe_id": "special.parasite", "pool_id": "standard_s"},
	})
	_expect(bool(first.get("ok", false)), "100th draw should succeed")
	_expect(bool(executor.state.factory.blueprints.get("special.parasite", false)), "100th draw should grant targeted S blueprint")
	_expect(int(executor.state.pity["s_pity_count"]) == 0, "S blueprint should reset hard pity")
	executor.state.pity["s_pity_count"] = 99
	var second: Dictionary = executor.execute({
		"type": "draw_blueprints",
		"command_id": "draw-pity-duplicate",
		"business_key": "draw:pity:duplicate",
		"expected_revision": 1,
		"payload": {"count": 1, "target_s_recipe_id": "special.parasite", "pool_id": "standard_s"},
	})
	_expect(bool(second.get("ok", false)), "duplicate S draw should succeed")
	_expect(int(executor.state.factory.blueprint_data.get("special.parasite", 0)) == 40, "duplicate S blueprint should convert to blueprint data")
	executor.state.factory.blueprint_data["ordinary.assault"] = 10
	executor.state.economy.toilet_coins = 200
	var upgraded: Dictionary = executor.execute({
		"type": "upgrade_model_tech",
		"command_id": "tech-assault-2",
		"business_key": "tech:ordinary.assault:2",
		"expected_revision": 2,
		"payload": {"recipe_id": "ordinary.assault"},
	})
	_expect(bool(upgraded.get("ok", false)), "model tech upgrade should succeed with exact costs")
	_expect(int(executor.state.factory.model_tech_stars["ordinary.assault"]) == 2, "model tech should reach two stars")
	for unit in executor.state.roster:
		if String(unit.archetype_id) == "assault":
			_expect(int(unit.star) == 2, "model star should project to every owned instance")


func _test_schema_v6_round_trip() -> void:
	var state: RefCounted = GameStateScript.create_new(904, 100)
	state.economy.hero_shards = 12
	var decoded: Dictionary = SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(state))
	_expect(bool(decoded.get("ok", false)), "schema v10 save should round-trip")
	if bool(decoded.get("ok", false)):
		var loaded: RefCounted = decoded["state"]
		_expect(int(loaded.schema_version) == 10, "round-trip should preserve schema v10")
		_expect(int(loaded.economy.hero_shards) == 12, "round-trip should preserve legion data")


func _test_retreat_and_s_unique_rule() -> void:
	var state: RefCounted = GameStateScript.create_new(905, 100)
	var s_one: RefCounted = HeroGeneratorScript.generate_archetype(905, 1, "parasite", "arcanist")
	var s_two: RefCounted = HeroGeneratorScript.generate_archetype(905, 2, "parasite", "arcanist")
	state.roster.append(s_one)
	state.roster.append(s_two)
	var executor: RefCounted = CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var invalid_s: Dictionary = executor.execute({
		"type": "set_formation",
		"command_id": "formation-two-s",
		"business_key": "",
		"expected_revision": 0,
		"payload": {
			"commander": s_one.hero_id,
			"troop_1": s_two.hero_id,
			"troop_2": "",
			"troop_3": "",
			"troop_4": "",
			"troop_5": "",
			"troop_6": "",
		},
	})
	_expect(not bool(invalid_s.get("ok", false)), "same S model must not occupy two formation slots")

	var session: RefCounted = BattleSessionScript.new()
	session.start([{
		"hero_id": state.roster[0].hero_id,
		"display_name": state.roster[0].display_name,
		"archetype_id": "assault",
		"class_id": "fighter",
		"star": 1,
		"max_hp": 100,
		"attack": 20,
		"defense": 10,
		"speed_milli": 1000,
		"crit_bp": 0,
		"slot": 0,
		"skill_id": "plunger_charge",
		"auto_skill": false,
	}])
	_expect(session.retreat(), "active battle should allow retreat")
	_expect(String(session.result.get("outcome", "")) == "retreat", "retreat should produce explicit retreat outcome")
	_expect((session.result.get("dead_unit_ids", []) as Array).is_empty(), "retreat should preserve living units")


func _test_scrap_recovery_prevents_dead_save() -> void:
	var state: RefCounted = GameStateScript.create_new(906, 100)
	state.roster.clear()
	for slot in state.formation.slots.keys():
		state.formation.slots[slot] = ""
	state.factory.materials = {"porcelain": 0, "parts": 0, "sludge": 0}
	var executor: RefCounted = CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var recovered: Dictionary = executor.execute({
		"type": "claim_scrap_recovery",
		"command_id": "scrap-recovery-empty-1",
		"business_key": "scrap-recovery:empty:1",
		"expected_revision": 0,
		"payload": {},
	})
	_expect(bool(recovered.get("ok", false)), "empty inventory should be able to claim minimum scrap recovery")
	var assault_cost := {"porcelain": 20, "parts": 8, "sludge": 4}
	_expect(executor.state.factory.can_spend(assault_cost), "scrap recovery should fund exactly one basic unit")
	var blocked: Dictionary = executor.execute({
		"type": "claim_scrap_recovery",
		"command_id": "scrap-recovery-empty-2",
		"business_key": "scrap-recovery:empty:2",
		"expected_revision": 1,
		"payload": {},
	})
	_expect(not bool(blocked.get("ok", false)), "recovery must not become repeatable victory income while materials remain")


func _test_milestone_blueprint_and_gem_source() -> void:
	var state: RefCounted = GameStateScript.create_new(907, 100)
	state.stage_progress["cleared_stages"] = ["stage_1_5"]
	var executor: RefCounted = CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var refresh: Dictionary = executor.execute({
		"type": "refresh_quests",
		"command_id": "refresh-milestone-quests",
		"business_key": "",
		"expected_revision": 0,
		"payload": {},
	})
	_expect(bool(refresh.get("ok", false)), "milestone quest refresh should succeed")
	var tickets_before := int(executor.state.economy.recruit_tickets)
	var claim: Dictionary = executor.execute({
		"type": "claim_quest",
		"command_id": "claim-stage-1-5-milestone",
		"business_key": "quest:major.stage_1_5",
		"expected_revision": 1,
		"payload": {"quest_id": "major.stage_1_5", "generation": 0, "request_id": "major-stage-1-5-claim"},
	})
	_expect(bool(claim.get("ok", false)), "chapter milestone quest should be claimable")
	_expect(int(executor.state.economy.recruit_tickets) == tickets_before + 1, "chapter milestone should grant one recruit ticket")
	_expect(bool(executor.state.factory.blueprints.get("ordinary.sonic", false)), "chapter milestone should grant deterministic non-S blueprint")


func _test_legacy_v5_migrates_to_v6() -> void:
	var legacy: Dictionary = GameStateScript.create_new(908, 100).to_dict()
	legacy["schema_version"] = 5
	legacy["content_version"] = "gman-siege-v5"
	(legacy["economy"] as Dictionary).erase("toilet_coins")
	(legacy["economy"] as Dictionary).erase("toilet_gems")
	(legacy["economy"] as Dictionary)["gold"] = 321
	(legacy["factory"] as Dictionary).erase("blueprint_data")
	(legacy["factory"] as Dictionary).erase("model_tech_stars")
	for key in ["blueprint_draw_count", "s_pity_count", "pool_id", "target_s_recipe_id"]:
		(legacy["pity"] as Dictionary).erase(key)
	var migrated: Dictionary = SaveCodecScript.decode(legacy)
	_expect(bool(migrated.get("ok", false)), "legacy schema v5 should migrate instead of forcing save deletion")
	if bool(migrated.get("ok", false)):
		var state: RefCounted = migrated["state"]
		_expect(int(state.schema_version) == 10, "legacy migration should produce schema v10")
		_expect(int(state.economy.toilet_coins) == 321, "legacy gold should convert to toilet coins")


func _test_endless_frontier_continuation() -> void:
	var endless_one := StageCatalogScript.stage("endless_1")
	var endless_two := StageCatalogScript.stage("endless_2")
	_expect(not endless_one.is_empty(), "endless frontier should generate its first stage")
	_expect(String(endless_one.get("next_stage_id", "")) == "endless_2", "endless stage should point to the next deterministic stage")
	_expect(int(endless_two.get("power_bp", 0)) > int(endless_one.get("power_bp", 0)), "endless difficulty should increase monotonically")
	_expect((endless_one.get("reward_defeat", {}) as Dictionary) == {"gold": 0}, "endless defeat reward must remain zero")
	var state: RefCounted = GameStateScript.create_new(909, 100)
	state.stage_progress["highest_unlocked_stage"] = "stage_5_5"
	var executor: RefCounted = CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var settlement: Dictionary = executor.execute({
		"type": "settle_battle",
		"command_id": "unlock-endless-one",
		"business_key": "battle:unlock-endless-one",
		"expected_revision": 0,
		"payload": {
			"battle_id": "unlock-endless-one",
			"stage_id": "stage_5_5",
			"outcome": "victory",
			"ticks": 50,
			"deployed_unit_ids": state.formation.hero_ids(),
			"dead_unit_ids": [],
		},
	})
	_expect(bool(settlement.get("ok", false)), "final authored victory should settle")
	_expect(String(executor.state.stage_progress["highest_unlocked_stage"]) == "endless_1", "final authored victory should unlock endless frontier")
	_expect(bool(settlement["event"].get("campaign_completed", false)), "final authored victory emits the campaign-completed event")
	_expect(bool(settlement["event"].get("first_campaign_completion", false)), "first final victory is marked as the first campaign completion")
	var replay_completion: Dictionary = executor.execute({
		"type": "settle_battle",
		"command_id": "replay-final-stage",
		"business_key": "battle:replay-final-stage",
		"expected_revision": 1,
		"payload": {
			"battle_id": "replay-final-stage",
			"stage_id": "stage_5_5",
			"outcome": "victory",
			"ticks": 55,
			"deployed_unit_ids": executor.state.formation.hero_ids(),
			"dead_unit_ids": [],
		},
	})
	_expect(bool(replay_completion.get("ok", false)), "final authored stage remains replayable")
	_expect(bool(replay_completion["event"].get("campaign_completed", false)), "final replay still routes to the epilogue")
	_expect(not bool(replay_completion["event"].get("first_campaign_completion", true)), "final replay does not duplicate first-completion status")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

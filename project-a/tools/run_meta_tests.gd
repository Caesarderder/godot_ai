extends SceneTree

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroStateScript := preload("res://game/scripts/state/hero_state.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const CommandFingerprintScript := preload("res://game/scripts/commands/command_fingerprint.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const SaveManagerCore := preload("res://game/scripts/persistence/save_manager.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactoryService := preload("res://game/scripts/domain/factory/factory_service.gd")
const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const SalvageCatalogScript := preload("res://game/scripts/domain/economy/salvage_catalog.gd")
const GoldShopCatalogScript := preload("res://game/scripts/domain/economy/gold_shop_catalog.gd")
const QuestCatalogScript := preload("res://game/scripts/domain/quest/quest_catalog.gd")
const WarMeritTrackScript := preload("res://game/scripts/domain/quest/war_merit_track.gd")
const AchievementCatalogScript := preload("res://game/scripts/domain/achievement/achievement_catalog.gd")
const AchievementServiceScript := preload("res://game/scripts/domain/achievement/achievement_service.gd")

var failures: Array[String] = []
var save_calls: int = 0


class FakeBootstrapSaveManager:
	extends RefCounted

	var load_result: Dictionary = {"ok": false, "error": "SAVE_NOT_FOUND"}
	var saved_states: Array[Dictionary] = []
	var save_result: bool = true
	var delete_calls: int = 0

	func load_state() -> Dictionary:
		return load_result

	func save_state(state: RefCounted) -> bool:
		saved_states.append(state.to_dict())
		return save_result

	func delete_local_save() -> Dictionary:
		delete_calls += 1
		return {"ok": true, "removed": ["fake-primary", "fake-backup"]}


func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("META TESTS PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("META TESTS FAIL: %d failure(s)" % failures.size())
		quit(1)


func _run_all() -> void:
	_test_new_game_contract()
	_test_seeded_hero_generation()
	_test_progression_clamp_bulk_equivalence()
	_test_war_merit_reward_track()
	_test_fingerprint_and_idempotency()
	_test_no_save_callback_rejects_commands()
	_test_revision_contract()
	_test_save_failure_does_not_swap()
	_test_save_codec_roundtrip_and_strict_values()
	_test_save_manager_atomic_roundtrip()
	_test_save_export_import_contract()
	_test_save_manager_deletes_all_local_candidates()
	_test_save_manager_missing_main_valid_bak()
	_test_game_bootstrap_contract()


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])


func _test_new_game_contract() -> void:
	var state := GameStateScript.create_new(12345, 100)
	_eq(state.schema_version, 11, "new game uses the character-fragment schema v11 envelope")
	_eq(state.content_version, "toilet-factory-slg-v3-factions", "new game uses the faction-progression contract")
	_eq(state.roster.size(), 1, "new game grants only permanent G-Man")
	_eq(state.economy.toilet_coins, 20, "new game starts with only 20 toilet coins")
	_eq(state.economy.toilet_gems, 0, "new game starts without premium currency")
	_eq(state.economy.xp_books, 0, "new game keeps retired xp books empty")
	_eq(state.economy.forge_stones, 0, "new game starts with zero forge stones")
	_eq(state.economy.recruit_tickets, 0, "new game has no implicit recruitment tickets")
	_eq(state.formation.hero_ids(), state.roster_ids(), "new game deploys only permanent G-Man")
	_eq(state.factory.materials, {"porcelain": 30, "parts": 0, "sludge": 0}, "new game starts with exactly one research-lab budget")
	_eq(state.factory.discovered_blueprints, {}, "new game starts without discovered blueprints")
	_eq(state.factory.blueprints.size(), 4, "compatibility data preserves four hidden legacy blueprints")
	_eq(state.factory.blueprint_research, {}, "new game starts without active Doctor research")
	_eq(state.achievements, {"progress": {}, "completed": {}, "claimed": {}, "event_keys": {}, "counters": {}}, "new game starts with empty achievement state")
	_ok(state.validate().is_empty(), "new game invariants pass")


func _test_gold_shop_transactions() -> void:
	_eq(GoldShopCatalogScript.validate_definitions(), [], "gold shop catalog definitions are valid")
	_eq(GoldShopCatalogScript.all().size(), 5, "gold shop exposes five deterministic offers")
	var state := GameStateScript.create_new(31001, 0)
	var executor := CommandExecutorScript.new(state, Callable(self, "_record_save_success"))
	var gold_before := int(executor.state.economy.gold)
	var books_before := int(executor.state.economy.xp_books)
	var first := _exec_ok(
		executor,
		"shop-buy-1",
		"purchase_gold_shop",
		{"request_id": "shop-request-1", "offer_id": "training_book"},
		"shop-business-1"
	)
	_eq(first["event"]["gold_cost"], 90, "training book shop offer costs ninety gold")
	_eq(executor.state.economy.gold, gold_before - 90, "shop purchase debits gold once")
	_eq(executor.state.economy.xp_books, books_before + 1, "shop purchase grants the catalog item")
	_ok((executor.state.receipt_ledgers["durable"] as Dictionary).has("gold_shop:shop-request-1"), "shop purchase writes durable receipt")
	_exec_ok(
		executor,
		"shop-buy-replay",
		"purchase_gold_shop",
		{"request_id": "shop-request-1", "offer_id": "training_book"},
		"shop-business-replay"
	)
	_eq(executor.state.economy.gold, gold_before - 90, "same shop request does not debit twice")
	_eq(executor.state.economy.xp_books, books_before + 1, "same shop request does not grant twice")
	var mismatch := executor.execute(_env(
		"shop-buy-mismatch",
		"purchase_gold_shop",
		{"request_id": "shop-request-1", "offer_id": "parts_crate"},
		"shop-business-mismatch",
		executor
	))
	_eq(mismatch["error"], "SHOP_REQUEST_ID_REUSE_MISMATCH", "shop request id cannot be reused for another offer")
	executor.state.economy.gold = 0
	var materials_before: Dictionary = executor.state.factory.materials.duplicate(true)
	var ledger_before := (executor.state.receipt_ledgers["durable"] as Dictionary).duplicate(true)
	var insufficient := executor.execute(_env(
		"shop-buy-poor",
		"purchase_gold_shop",
		{"request_id": "shop-request-poor", "offer_id": "mixed_factory_cache"},
		"shop-business-poor",
		executor
	))
	_eq(insufficient["error"], "NOT_ENOUGH_GOLD", "shop rejects insufficient gold")
	_eq(executor.state.factory.materials, materials_before, "failed shop purchase grants no materials")
	_eq(executor.state.receipt_ledgers["durable"], ledger_before, "failed shop purchase writes no durable receipt")


func _test_war_merit_reward_track() -> void:
	var state := GameStateScript.create_new(31002, 0)
	var executor := CommandExecutorScript.new(state, Callable(self, "_record_save_success"))
	_eq(WarMeritTrackScript.reached_level(executor.state), 1, "fresh campaign starts at war merit level one")
	_eq(WarMeritTrackScript.claimable_count(executor.state), 1, "level one starter merit reward is claimable")
	var coins_before := int(executor.state.economy.toilet_coins)
	var first := _exec_ok(
		executor,
		"merit-claim-1",
		"claim_war_merit_reward",
		{"request_id": "merit-request-1", "level": 1},
		"merit-business-1"
	)
	_eq(first["event"]["reward"], WarMeritTrackScript.reward_for_level(1), "war merit claim uses canonical level reward")
	_eq(executor.state.economy.toilet_coins, coins_before + 10, "level one merit reward grants toilet coins")
	_eq(WarMeritTrackScript.claimable_count(executor.state), 0, "claimed merit level leaves no duplicate claim")
	var duplicate := executor.execute(_env(
		"merit-claim-duplicate",
		"claim_war_merit_reward",
		{"request_id": "merit-request-new", "level": 1},
		"merit-business-duplicate",
		executor
	))
	_eq(duplicate["error"], "MERIT_REWARD_ALREADY_CLAIMED", "same merit level cannot be claimed with a new request")
	var locked := executor.execute(_env(
		"merit-claim-locked",
		"claim_war_merit_reward",
		{"request_id": "merit-request-5-locked", "level": 5},
		"merit-business-5-locked",
		executor
	))
	_eq(locked["error"], "MERIT_LEVEL_NOT_REACHED", "future merit level reward stays locked")
	executor.state.inventory["items"][QuestCatalogScript.WAR_MERIT_ITEM_ID] = 640
	_eq(WarMeritTrackScript.reached_level(executor.state), 5, "cumulative merit reaches level five at the canonical threshold")
	_eq(WarMeritTrackScript.claimable_count(executor.state), 4, "all newly reached unclaimed merit levels become claimable")
	var tickets_before := int(executor.state.economy.recruit_tickets)
	_exec_ok(
		executor,
		"merit-claim-5",
		"claim_war_merit_reward",
		{"request_id": "merit-request-5", "level": 5},
		"merit-business-5"
	)
	_eq(executor.state.economy.recruit_tickets, tickets_before, "fifth merit level does not create a fifth resource")
	var decoded := SaveCodecScript.decode(SaveCodecScript.encode(executor.state))
	_ok(bool(decoded.get("ok", false)), "merit reward state survives strict save codec")
	if bool(decoded.get("ok", false)):
		var restored: RefCounted = decoded["state"]
		_ok(WarMeritTrackScript.is_claimed(restored, 1) and WarMeritTrackScript.is_claimed(restored, 5), "save/load preserves claimed merit levels")
		_ok((restored.receipt_ledgers["durable"] as Dictionary).has("war_merit_reward:merit-request-5"), "save/load preserves merit reward receipt")


func _test_seeded_hero_generation() -> void:
	var state_a := GameStateScript.create_new(98765, 0)
	var state_b := GameStateScript.create_new(98765, 999)
	var state_c := GameStateScript.create_new(98766, 0)
	var archetypes: Array[String] = []
	for hero in state_a.roster:
		archetypes.append(hero.archetype_id)
	_eq(archetypes, ["gman"], "starter roster contains only permanent G-Man")
	_eq(state_a.roster[0].display_name, "G-Man 指挥官", "starter commander has the canonical display name")
	_eq(state_a.roster[0].to_dict(), state_b.roster[0].to_dict(), "same run seed is stable and ignores save_id/time")
	_ok(state_a.roster[0].to_dict() != state_c.roster[0].to_dict(), "different run seed changes generated hero")
	_ok(HeroGenerator.GIVEN_NAMES.size() * HeroGenerator.FAMILY_NAMES.size() >= 40, "name pool has at least 40 combinations")
	_eq(HeroGenerator.TRAIT_IDS.size(), 8, "trait pool has eight traits")
	_eq(HeroGenerator.APTITUDE_WEIGHT_BP, {"B": 8000, "A": 1800, "S": 200}, "active role rating weights use only B/A/S")
	_eq(HeroGenerator.ACTIVE_APTITUDE_IDS, ["B", "A", "S"], "new roles cannot roll the retired C rating")
	for hero in state_a.roster:
		if String(hero.archetype_id) == "gman":
			continue
		for key in HeroStateScript.ATTR_KEYS:
			var baseline := int(HeroGenerator.CLASS_BASE_STATS[hero.class_id][key])
			var delta := int(hero.base_stats[key]) - baseline
			var extent := int(HeroGenerator.STAT_VARIANCE[key])
			_ok(delta >= -extent and delta <= extent, "L1 five-stat variance stays bounded for %s.%s" % [hero.hero_id, key])


func _test_recruit_four_to_eight_and_ticket_cost() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(222, 0), Callable(self, "_record_save_success"))
	_exec_ok(executor, "grant-1", "grant_resources", {"resources": {"recruit_tickets": 4}}, "seed-recruit-grant")
	for index in 4:
		_exec_ok(executor, "recruit-%d" % index, "recruit_hero", {}, "recruit-%d" % index)
	_eq(executor.state.roster.size(), 12, "four recruit commands grow roster from eight to twelve")
	_eq(executor.state.economy.recruit_tickets, 0, "four recruit commands deduct four tickets")


func _test_progression_clamp_bulk_equivalence() -> void:
	var bulk: RefCounted = HeroGenerator.generate_hero(333, 4)
	var step: RefCounted = bulk.deep_clone()
	HeroProgression.train_with_books(bulk, 999)
	for _index in 999:
		HeroProgression.train_with_books(step, 1)
	_eq(bulk.level, 5, "bulk training clamps to L5")
	_eq(bulk.xp, 320, "bulk training clamps XP to 320")
	_eq(step.to_dict(), bulk.to_dict(), "incremental and bulk training produce identical hero state")
	var stats := HeroProgression.derived_battle_stats(bulk)
	_eq(stats["hp"], int(bulk.base_stats["hp"]), "one-star derived HP equals authoritative HP")
	_eq(stats["attack"], int(bulk.base_stats["attack"]), "one-star derived attack equals authoritative attack")
	_eq(stats["defense"], int(bulk.base_stats["defense"]), "one-star derived defense equals authoritative defense")
	_eq(stats["speed_milli"], int(bulk.base_stats["speed_milli"]), "speed is not multiplied by star")
	_eq(stats["crit_bp"], int(bulk.base_stats["crit_bp"]), "crit is not multiplied by star")
	_eq(HeroProgression.active_skill_id(bulk), FactoryCatalogScript.active_skill_for_archetype(bulk.archetype_id), "hero progression uses the factory catalog canonical active skill")
	_eq(HeroProgression.skill_tier(bulk), 1, "one-star hero uses skill tier 1")
	bulk.star = 2
	_eq(HeroProgression.skill_tier(bulk), 2, "two-star hero upgrades to skill tier 2")
	bulk.star = 3
	_eq(HeroProgression.skill_tier(bulk), 3, "three-star hero upgrades to skill tier 3")


func _test_formation_validation() -> void:
	var state := GameStateScript.create_new(444, 0)
	var executor := CommandExecutorScript.new(state, Callable(self, "_record_save_success"))
	var ids := state.roster_ids()
	var valid_payload := {
		"front_left": ids[1],
		"front_center": ids[4],
		"front_right": ids[0],
		"back_left": ids[2],
		"back_center": ids[5],
		"back_right": ids[3],
	}
	_exec_ok(executor, "formation-valid", "set_formation", valid_payload, "formation-valid")
	var duplicate_payload := valid_payload.duplicate(true)
	duplicate_payload["back_right"] = duplicate_payload["front_left"]
	var duplicate := executor.execute(_env("formation-dup", "set_formation", duplicate_payload, "formation-dup", executor))
	_ok(not bool(duplicate["ok"]), "duplicate formation hero is rejected")
	var missing_payload := valid_payload.duplicate(true)
	missing_payload["back_right"] = "missing"
	var missing := executor.execute(_env("formation-missing", "set_formation", missing_payload, "formation-missing", executor))
	_ok(not bool(missing["ok"]), "missing formation hero is rejected")


func _test_battle_settlement() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(445, 0), Callable(self, "_record_save_success"))
	var gold_before: int = executor.state.economy.gold
	var books_before: int = executor.state.economy.xp_books
	var opening_hero: RefCounted = executor.state.hero_by_id(
		String(executor.state.formation.hero_ids()[0])
	)
	var opening_hero_id := String(opening_hero.hero_id)
	var opening_xp_before := int(opening_hero.xp)
	var victory := _exec_ok(
		executor,
		"battle-win-1",
		"settle_battle",
		{"battle_id": "battle-win-1", "outcome": "victory", "ticks": 77},
		"battle:battle-win-1"
	)
	_eq(victory["event"]["reward"], {"gold": 80, "xp_books": 0, "porcelain": 24, "parts": 16, "sludge": 12}, "opening victory reward is owned by domain reducer")
	_eq(executor.state.economy.gold, gold_before + 80, "victory grants fixed gold")
	_eq(executor.state.economy.xp_books, books_before, "opening victory does not accelerate Gman with a training book")
	_eq(victory["event"]["hero_xp_each"], 30, "victory reports the exact per-hero battle experience")
	_eq(victory["event"]["hero_xp_recipients"], 1, "victory reports how many deployed heroes gained experience")
	_ok(bool(victory["event"]["first_victory"]), "first clear is explicit in the durable settlement event")
	_eq(
		int(executor.state.hero_by_id(opening_hero_id).xp),
		opening_xp_before + 30,
		"reported victory experience matches permanent hero state"
	)
	_eq(executor.state.attempt_counters["stage_1_1"], 1, "victory records attempt")
	_ok(executor.state.stage_progress["cleared_stages"].has("stage_1_1"), "victory clears stage 1-1")
	var replay := executor.execute(_env_with_revision(
		"battle-win-1",
		"settle_battle",
		{"battle_id": "battle-win-1", "outcome": "victory", "ticks": 77},
		"battle:battle-win-1",
		0
	))
	_eq(replay, victory, "battle settlement is idempotent")
	_eq(executor.state.economy.gold, gold_before + 80, "idempotent settlement does not duplicate reward")
	var repeat_victory := _exec_ok(
		executor,
		"battle-win-repeat",
		"settle_battle",
		{"battle_id": "battle-win-repeat", "outcome": "victory", "ticks": 78},
		"battle:battle-win-repeat"
	)
	_eq(repeat_victory["event"]["reward_tier"], "repeat_victory", "cleared-stage farming is labeled as repeat victory")
	_ok(not bool(repeat_victory["event"]["first_victory"]), "repeat clear cannot masquerade as a new proof milestone")
	_eq(repeat_victory["event"]["reward"], {"gold": 24, "xp_books": 0, "porcelain": 7, "parts": 4, "sludge": 3}, "repeat victory grants only thirty-percent materials and no books")
	var timeout_rejected := executor.execute(_env(
		"battle-timeout-rejected",
		"settle_battle",
		{"battle_id": "battle-timeout-rejected", "outcome": "timeout", "ticks": 180},
		"battle:battle-timeout-rejected",
		executor
	))
	_ok(not bool(timeout_rejected.get("ok", false)), "battle settlement rejects the removed timeout outcome")
	var defeat_executor := CommandExecutorScript.new(GameStateScript.create_new(4453, 0), Callable(self, "_record_save_success"))
	var defeat := _exec_ok(defeat_executor, "battle-defeat-1", "settle_battle", {"battle_id": "battle-defeat-1", "outcome": "defeat", "ticks": 40}, "battle:battle-defeat-1")
	_eq(defeat["event"]["reward"]["xp_books"], 2, "defeat grants training books for first retry growth")
	_eq(defeat["event"]["hero_xp_each"], 8, "lossless defeat still reports its smaller participation experience")
	var repeat_defeat := _exec_ok(defeat_executor, "battle-defeat-2", "settle_battle", {"battle_id": "battle-defeat-2", "outcome": "defeat", "ticks": 41}, "battle:battle-defeat-2")
	_eq(repeat_defeat["event"]["reward_tier"], "repeat_defeat", "second failure is identified as repeat defeat")
	_eq(repeat_defeat["event"]["reward"], {"gold": 0, "xp_books": 0, "porcelain": 0, "parts": 0, "sludge": 0}, "repeat defeat cannot generate infinite resources")
	var invalid := executor.execute(_env(
		"battle-invalid",
		"settle_battle",
		{"battle_id": "battle-invalid", "outcome": "draw", "ticks": 1},
		"battle:battle-invalid",
		executor
	))
	_ok(not bool(invalid["ok"]), "invalid battle outcome is rejected")


func _test_stage_specific_battle_settlement() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(4454, 0), Callable(self, "_record_save_success"))
	var stage_id := "stage_1_2"
	var victory := _exec_ok(
		executor,
		"battle-stage-1-2",
		"settle_battle",
		{"battle_id": "battle-stage-1-2", "stage_id": stage_id, "outcome": "victory", "ticks": 88},
		"battle:battle-stage-1-2"
	)
	_eq(victory["event"]["stage_id"], stage_id, "settlement event reports real stage id")
	_eq(executor.state.attempt_counters[stage_id], 1, "settlement records attempt on real stage id")
	_ok(executor.state.stage_progress["cleared_stages"].has(stage_id), "settlement clears real stage id")
	_eq(executor.state.stage_progress["highest_unlocked_stage"], StageCatalogScript.next_stage_id(stage_id), "victory unlocks the next stage")
	_eq(victory["event"]["reward"], StageCatalogScript.reward_for(stage_id, "victory"), "stage-specific settlement uses catalog reward")
	var invalid := executor.execute(_env(
		"battle-unknown-stage",
		"settle_battle",
		{"battle_id": "battle-unknown-stage", "stage_id": "stage_9_9", "outcome": "victory", "ticks": 1},
		"battle:unknown-stage",
		executor
	))
	_ok(not bool(invalid["ok"]), "unknown settlement stage is rejected")


func _test_alliance_scrap_first_clear_and_exchange() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(4455, 0), Callable(self, "_record_save_success"))
	var first_clear := _exec_ok(
		executor,
		"scrap-stage-1-2",
		"settle_battle",
		{"battle_id": "scrap-stage-1-2", "stage_id": "stage_1_2", "outcome": "victory", "ticks": 80},
		"scrap:battle:stage-1-2"
	)
	_eq(first_clear["event"]["alliance_scrap_granted"], 5, "first normal-stage victory grants five alliance scrap")
	_eq(executor.state.inventory["items"][SalvageCatalogScript.ITEM_ID], 5, "normal first clear writes alliance scrap into inventory items")
	_ok((first_clear["event"]["alliance_scrap_receipt"] as Dictionary).has("fingerprint"), "first clear returns durable wallet receipt")
	var repeat_clear := _exec_ok(
		executor,
		"scrap-stage-1-2-repeat",
		"settle_battle",
		{"battle_id": "scrap-stage-1-2-repeat", "stage_id": "stage_1_2", "outcome": "victory", "ticks": 81},
		"scrap:battle:stage-1-2-repeat"
	)
	_eq(repeat_clear["event"]["alliance_scrap_granted"], 0, "repeat victory does not grant duplicate alliance scrap")
	_eq(executor.state.inventory["items"][SalvageCatalogScript.ITEM_ID], 5, "repeat victory does not mutate alliance scrap balance")
	var boss_clear := _exec_ok(
		executor,
		"scrap-stage-1-5",
		"settle_battle",
		{"battle_id": "scrap-stage-1-5", "stage_id": "stage_1_5", "outcome": "victory", "ticks": 120},
		"scrap:battle:stage-1-5"
	)
	_eq(boss_clear["event"]["alliance_scrap_granted"], 15, "first boss victory grants fifteen alliance scrap")
	_eq(executor.state.inventory["items"][SalvageCatalogScript.ITEM_ID], 20, "boss first clear stacks alliance scrap")
	var porcelain_before: int = executor.state.factory.materials["porcelain"]
	var exchange := _exec_ok(
		executor,
		"scrap-exchange-porcelain",
		"exchange_salvage",
		{"request_id": "wallet:req:porcelain", "offer_id": "porcelain_resupply"},
		"wallet:req:porcelain"
	)
	_eq(exchange["event"]["type"], "salvage_exchanged", "exchange emits stable salvage event")
	_eq(exchange["event"]["cost"], 8, "porcelain resupply costs eight alliance scrap")
	_eq(executor.state.inventory["items"][SalvageCatalogScript.ITEM_ID], 12, "exchange deducts alliance scrap once")
	_eq(executor.state.factory.materials["porcelain"], porcelain_before + 40, "exchange grants porcelain atomically")
	_ok((exchange["event"]["ledger_receipt"] as Dictionary).has("fingerprint"), "exchange returns durable ledger receipt")
	var replay := _exec_ok(
		executor,
		"scrap-exchange-porcelain-replay",
		"exchange_salvage",
		{"request_id": "wallet:req:porcelain", "offer_id": "porcelain_resupply"},
		"wallet:req:porcelain-replay"
	)
	_eq(replay["event"]["idempotent"], true, "same wallet request id and fingerprint is idempotent")
	_eq(executor.state.inventory["items"][SalvageCatalogScript.ITEM_ID], 12, "wallet replay does not deduct again")
	_eq(executor.state.factory.materials["porcelain"], porcelain_before + 40, "wallet replay does not grant again")
	var request_conflict := executor.execute(_env(
		"scrap-exchange-conflict",
		"exchange_salvage",
		{"request_id": "wallet:req:porcelain", "offer_id": "mixed_parts"},
		"wallet:req:porcelain-conflict",
		executor
	))
	_eq(request_conflict["error"], "WALLET_REQUEST_ID_REUSE_MISMATCH", "same wallet request id with different fingerprint is rejected")
	var ledger_before: Dictionary = (executor.state.receipt_ledgers["durable"] as Dictionary).duplicate(true)
	var low_balance := executor.execute(_env(
		"scrap-exchange-low",
		"exchange_salvage",
		{"request_id": "wallet:req:training-low", "offer_id": "training_cache"},
		"wallet:req:training-low",
		executor
	))
	_eq(low_balance["error"], "NOT_ENOUGH_ALLIANCE_SCRAP", "exchange rejects insufficient alliance scrap")
	_eq(executor.state.receipt_ledgers["durable"], ledger_before, "insufficient exchange writes no wallet ledger receipt")
	var mixed := _exec_ok(
		executor,
		"scrap-exchange-mixed",
		"exchange_salvage",
		{"request_id": "wallet:req:mixed", "offer_id": "mixed_parts"},
		"wallet:req:mixed"
	)
	_eq(executor.state.inventory["items"][SalvageCatalogScript.ITEM_ID], 0, "mixed parts exchange spends remaining alliance scrap")
	_eq(mixed["event"]["grant"], {"factory": {"parts": 28, "sludge": 20}, "economy": {}}, "mixed parts grant contract is stable")
	var training_executor := CommandExecutorScript.new(GameStateScript.create_new(4456, 0), Callable(self, "_record_save_success"))
	training_executor.state.inventory["items"][SalvageCatalogScript.ITEM_ID] = 15
	var training_gold_before: int = training_executor.state.economy.gold
	var training_books_before: int = training_executor.state.economy.xp_books
	var training := _exec_ok(
		training_executor,
		"scrap-exchange-training",
		"exchange_salvage",
		{"request_id": "wallet:req:training", "offer_id": "training_cache"},
		"wallet:req:training"
	)
	_eq(training["event"]["cost"], 15, "training cache costs fifteen alliance scrap")
	_eq(training_executor.state.inventory["items"][SalvageCatalogScript.ITEM_ID], 0, "training cache spends all provided alliance scrap")
	_eq(training_executor.state.economy.gold, training_gold_before + 120, "training cache grants gold")
	_eq(training_executor.state.economy.xp_books, training_books_before + 2, "training cache grants xp books")
	var unknown_offer := executor.execute(_env(
		"scrap-exchange-unknown",
		"exchange_salvage",
		{"request_id": "wallet:req:unknown", "offer_id": "unknown_offer"},
		"wallet:req:unknown",
		executor
	))
	_eq(unknown_offer["error"], "UNKNOWN_SALVAGE_OFFER", "unknown salvage offer is rejected")
	var invalid_request_type := executor.execute(_env(
		"scrap-exchange-invalid-request",
		"exchange_salvage",
		{"request_id": 1, "offer_id": "porcelain_resupply"},
		"wallet:req:invalid-request",
		executor
	))
	_ok(String(invalid_request_type["error"]).contains("request_id"), "non-string wallet request id is rejected")
	var invalid_offer_type := executor.execute(_env(
		"scrap-exchange-invalid-offer",
		"exchange_salvage",
		{"request_id": "wallet:req:invalid-offer", "offer_id": 1},
		"wallet:req:invalid-offer",
		executor
	))
	_ok(String(invalid_offer_type["error"]).contains("offer_id"), "non-string salvage offer id is rejected")
	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(executor.state))
	_ok(bool(decoded.get("ok", false)), "wallet ledger state save/load decodes")
	if bool(decoded.get("ok", false)):
		var restored: RefCounted = decoded["state"]
		_eq(restored.inventory["items"][SalvageCatalogScript.ITEM_ID], 0, "save/load preserves alliance scrap balance")
		_ok((restored.receipt_ledgers["durable"] as Dictionary).has("wallet:req:porcelain"), "save/load preserves durable exchange ledger")


func _test_quest_system_contracts() -> void:
	_eq(QuestCatalogScript.validate_definitions(), [], "quest definitions are valid")
	_eq(QuestCatalogScript.major_quests().size(), 25, "quest catalog maps all 25 campaign stages to major quests")
	for stage_id in StageCatalogScript.all_stage_ids():
		var quest := QuestCatalogScript.major_quest(stage_id)
		_eq(String(quest["quest_id"]), "major.%s" % stage_id, "major quest id is stable for %s" % stage_id)
		_eq(String(quest.get("tier", "")), "major", "campaign first-clear is labeled as a major quest")
		var reward := quest["reward"] as Dictionary
		var is_boss := int(StageCatalogScript.stage(stage_id).get("stage_in_chapter", 0)) == 5
		_eq(reward, {"merit": 120 if is_boss else 40, "gold": 30 if is_boss else 10, "xp_books": 1 if is_boss else 0}, "major quest reward is conservative for %s" % stage_id)
		for key in reward.keys():
			_ok(["merit", "gold", "xp_books"].has(String(key)), "major rewards do not include blueprints or power multipliers")
	for template in QuestCatalogScript.MINOR_TEMPLATES:
		var minor_reward := (template as Dictionary).get("reward", {}) as Dictionary
		_ok(int(minor_reward.get("merit", 0)) <= 20, "minor quest merit stays below the major-quest floor")
		_ok(int(minor_reward.get("gold", 0)) <= 5, "minor quest gold remains a light feedback reward")
		_eq(int(minor_reward.get("xp_books", 0)), 0, "minor quests never grant scarce training books")
	_eq(QuestCatalogScript.validate_reward_definition({"merit": 1, "blueprint": 1}, "bad")[0], "bad reward has unknown key blueprint", "quest reward validator rejects unknown reward keys")
	_ok(not QuestCatalogScript.validate_reward_definition({"merit": -1}, "bad").is_empty(), "quest reward validator rejects negative reward values")
	_ok(not QuestCatalogScript.validate_reward_definition({"merit": "1"}, "bad").is_empty(), "quest reward validator rejects non-int reward values")
	_eq(QuestCatalogScript.rank_for_merit(0), 1, "war merit rank starts at one")
	_eq(QuestCatalogScript.rank_for_merit(100), 2, "war merit rank uses first 100 requirement")
	_eq(QuestCatalogScript.rank_for_merit(1_000_000), 30, "war merit display rank is capped at thirty")

	var executor := CommandExecutorScript.new(GameStateScript.create_new(4457, 0), Callable(self, "_record_save_success"))
	var refresh := _exec_ok(executor, "quest-refresh-1", "refresh_quests", {}, "quest:refresh:1")
	_eq((refresh["event"]["active_minor_quests"] as Array).size(), 3, "refresh initializes exactly three minor quest slots")
	_eq((executor.state.quests["active"]["minor_slots"] as Array).size(), 3, "quest active state stores three minor slots")
	var initial_slots := executor.state.quests["active"]["minor_slots"] as Array
	_eq(String((initial_slots[0] as Dictionary)["event_type"]), "battle_settled", "slot 0 starts with battle settled minor")
	_eq(String((initial_slots[1] as Dictionary)["outcome"]), "victory", "slot 1 starts with victory minor")
	_eq(String((initial_slots[2] as Dictionary)["event_type"]), "production_started", "slot 2 starts with production-start minor")
	var gold_before_battle: int = executor.state.economy.gold
	_exec_ok(
		executor,
		"quest-battle-1-1",
		"settle_battle",
		{"battle_id": "quest-battle-1-1", "stage_id": "stage_1_1", "outcome": "victory", "ticks": 90},
		"quest:battle:1-1"
	)
	_ok((executor.state.quests["completed"] as Dictionary).has("major.stage_1_1"), "first victory completes matching major quest")
	_ok((executor.state.quests["completed"] as Dictionary).has(String((initial_slots[0] as Dictionary)["quest_id"])), "battle event completes battle minor")
	_ok((executor.state.quests["completed"] as Dictionary).has(String((initial_slots[1] as Dictionary)["quest_id"])), "victory event completes victory minor")
	_eq(int((executor.state.inventory["items"] as Dictionary).get(QuestCatalogScript.WAR_MERIT_ITEM_ID, 0)), 0, "completed quests do not grant war merit before claim")
	_eq(executor.state.economy.gold, gold_before_battle + 80, "completed major quest does not grant gold before claim")
	var claim_major := _exec_ok(
		executor,
		"quest-claim-major",
		"claim_quest",
		{"quest_id": "major.stage_1_1", "generation": 0, "request_id": "quest:req:major:1-1"},
		"quest:req:major:1-1"
	)
	_eq(claim_major["event"]["reward"], {"merit": 40, "gold": 10, "xp_books": 0}, "claiming normal major grants quest reward")
	_eq(executor.state.inventory["items"][QuestCatalogScript.WAR_MERIT_ITEM_ID], 40, "claim writes war merit into inventory items")
	var replay_major := _exec_ok(
		executor,
		"quest-claim-major-replay",
		"claim_quest",
		{"quest_id": "major.stage_1_1", "generation": 0, "request_id": "quest:req:major:1-1"},
		"quest:req:major:1-1-replay"
	)
	_eq(replay_major["event"]["idempotent"], true, "same quest claim request id replays idempotently")
	_eq(executor.state.inventory["items"][QuestCatalogScript.WAR_MERIT_ITEM_ID], 40, "quest claim replay does not duplicate merit")
	var request_conflict := executor.execute(_env(
		"quest-claim-conflict",
		"claim_quest",
		{"quest_id": String((initial_slots[0] as Dictionary)["quest_id"]), "generation": 0, "request_id": "quest:req:major:1-1"},
		"quest:req:conflict",
		executor
	))
	_eq(request_conflict["error"], "QUEST_REQUEST_ID_REUSE_MISMATCH", "same quest request id with different fingerprint is rejected")
	var duplicate_claim := executor.execute(_env(
		"quest-claim-duplicate",
		"claim_quest",
		{"quest_id": "major.stage_1_1", "generation": 0, "request_id": "quest:req:major:1-1-duplicate"},
		"quest:req:major:1-1-duplicate",
		executor
	))
	_eq(duplicate_claim["error"], "QUEST_ALREADY_CLAIMED", "claimed quest cannot be claimed again with a new request id")
	var tampered_state := GameStateScript.create_new(4459, 0)
	tampered_state.quests["completed"]["major.stage_1_2"] = {
		"quest_id": "major.stage_1_2",
		"kind": "major",
		"generation": 0,
		"reward": {"merit": 999999, "gold": 999999, "xp_books": 999999},
	}
	var tampered_executor := CommandExecutorScript.new(tampered_state, Callable(self, "_record_save_success"))
	var tampered_claim := tampered_executor.execute(_env(
		"quest-claim-tampered",
		"claim_quest",
		{"quest_id": "major.stage_1_2", "generation": 0, "request_id": "quest:req:tampered"},
		"quest:req:tampered",
		tampered_executor
	))
	_eq(tampered_claim["error"], "QUEST_REWARD_DEFINITION_MISMATCH", "claim rejects save-tampered rewards that differ from catalog")
	_eq(int((tampered_executor.state.inventory["items"] as Dictionary).get(QuestCatalogScript.WAR_MERIT_ITEM_ID, 0)), 0, "tampered quest claim grants no merit")
	var minor_quest_id := String((initial_slots[2] as Dictionary)["quest_id"])
	var start := _exec_ok(executor, "quest-start-production", "start_production", {"recipe_id": "ordinary.assault", "now_unix": 1000}, "quest:prod:start")
	_eq(start["event"]["type"], "production_started", "production start still emits original event")
	_ok((executor.state.quests["completed"] as Dictionary).has(minor_quest_id), "production_started event completes matching minor")
	var claim_minor := _exec_ok(
		executor,
		"quest-claim-minor-production-started",
		"claim_quest",
		{"quest_id": minor_quest_id, "generation": 0, "request_id": "quest:req:minor:prod-start"},
		"quest:req:minor:prod-start"
	)
	_eq(int((claim_minor["event"]["replacement_minor_quest"] as Dictionary)["generation"]), 1, "minor claim deterministically increments generation and refills slot")
	_eq(String((claim_minor["event"]["replacement_minor_quest"] as Dictionary)["event_type"]), "production_claimed", "slot refill follows deterministic template rotation")
	_exec_ok(executor, "quest-start-production-b", "start_production", {"recipe_id": "ordinary.sonic", "now_unix": 1000}, "quest:prod:start:b")
	var ready_claim := _exec_ok(executor, "quest-claim-ready-batch", "claim_ready_productions", {"now_unix": 1007}, "quest:prod:claim-ready")
	_eq((ready_claim["event"]["claimed"] as Array).size(), 2, "batch ready production claims two orders")
	var replacement_id := String((claim_minor["event"]["replacement_minor_quest"] as Dictionary)["quest_id"])
	_ok((executor.state.quests["completed"] as Dictionary).has(replacement_id), "batch ready production advances production_claimed minor by claimed count")
	var completed_before_refresh: Dictionary = (executor.state.quests["completed"] as Dictionary).duplicate(true)
	_exec_ok(executor, "quest-refresh-no-progress", "refresh_quests", {}, "quest:refresh:no-progress")
	_eq(executor.state.quests["completed"], completed_before_refresh, "refresh event does not progress or alter already completed quests")
	var bad_generation := executor.execute(_env(
		"quest-claim-bad-generation",
		"claim_quest",
		{"quest_id": replacement_id, "generation": 0, "request_id": "quest:req:bad-generation"},
		"quest:req:bad-generation",
		executor
	))
	_eq(bad_generation["error"], "QUEST_GENERATION_MISMATCH", "claim rejects out-of-order generation")
	var old_state := GameStateScript.create_new(4458, 0)
	old_state.stage_progress["cleared_stages"] = ["stage_1_2", "stage_1_5"]
	old_state.quests = {"active": {}, "completed": {}, "claimed": {}}
	var old_executor := CommandExecutorScript.new(old_state, Callable(self, "_record_save_success"))
	_exec_ok(old_executor, "quest-old-refresh", "refresh_quests", {}, "quest:old:refresh")
	_ok((old_executor.state.quests["completed"] as Dictionary).has("major.stage_1_2"), "refresh backfills old cleared normal stage major")
	_ok((old_executor.state.quests["completed"] as Dictionary).has("major.stage_1_5"), "refresh backfills old cleared boss stage major")
	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(old_executor.state))
	_ok(bool(decoded.get("ok", false)), "quest state save/load decodes")
	if bool(decoded.get("ok", false)):
		var restored: RefCounted = decoded["state"]
		_ok((restored.quests["completed"] as Dictionary).has("major.stage_1_5"), "save/load preserves refreshed quest completion")


func _test_achievement_system_contracts() -> void:
	_eq(AchievementCatalogScript.validate_definitions(), [], "achievement definitions are valid")
	_eq(AchievementCatalogScript.all().size(), 24, "achievement catalog exposes the audited permanent 24 achievements")
	for definition in AchievementCatalogScript.all():
		var tier := String((definition as Dictionary).get("tier", ""))
		_ok(["major", "minor"].has(tier), "achievement declares major or minor tier")
		for forbidden in ["daily", "weekly", "season", "starts_at", "ends_at", "expires_at", "reset_at"]:
			_ok(not (definition as Dictionary).has(forbidden), "achievement definition has no FOMO field %s" % forbidden)
		var reward := (definition as Dictionary)["reward"] as Dictionary
		for key in reward.keys():
			_ok(["merit", "gold", "xp_books"].has(String(key)), "achievement rewards do not include blueprints, power multipliers, scrap, or paid keys")
			_ok(typeof(reward[key]) == TYPE_INT and int(reward[key]) >= 0, "achievement reward values are non-negative integers")
		if tier == "minor":
			_eq(int(reward.get("xp_books", 0)), 0, "small achievements do not grant scarce training books")
	_ok(int(AchievementCatalogScript.definition("ach.factory.claim_6").get("target", 0)) == 9, "opening factory achievement follows the nine-unit reinforcement contract")
	_ok(not AchievementCatalogScript.ids().has("ach.campaign.clear_15"), "removed audit item clear_15 is absent")
	_ok(not AchievementCatalogScript.ids().has("ach.boss.destroy_3"), "removed audit item destroy_3 is absent")
	_ok(not AchievementCatalogScript.ids().has("factory.claim_18"), "removed audit item factory.claim_18 is absent")
	_ok(not AchievementCatalogScript.ids().has("training.use_3"), "removed audit item training.use_3 is absent")

	var executor := CommandExecutorScript.new(GameStateScript.create_new(4460, 0), Callable(self, "_record_save_success"))
	var refresh := _exec_ok(executor, "ach-refresh-1", "refresh_achievements", {}, "ach:refresh:1")
	_eq((refresh["event"]["completed_achievements"] as Array), [], "fresh save starts with no pre-completed achievement")
	_eq(int((executor.state.inventory["items"] as Dictionary).get(QuestCatalogScript.WAR_MERIT_ITEM_ID, 0)), 0, "completed achievement does not grant reward before claim")
	var gold_before_battle: int = executor.state.economy.gold
	_exec_ok(
		executor,
		"ach-battle-1-1",
		"settle_battle",
		{"battle_id": "ach-battle-1-1", "stage_id": "stage_1_1", "outcome": "victory", "ticks": 90},
		"ach:battle:1-1"
	)
	_ok((executor.state.achievements["completed"] as Dictionary).has("ach.campaign.clear_1"), "victory event completes first-clear achievement")
	_eq(executor.state.economy.gold, gold_before_battle + 80, "completion grants no achievement gold before claim")
	var claim_first_clear := _exec_ok(
		executor,
		"ach-claim-first-clear",
		"claim_achievement",
		{"achievement_id": "ach.campaign.clear_1", "generation": 0, "request_id": "ach:req:first-clear"},
		"ach:req:first-clear"
	)
	_eq(claim_first_clear["event"]["reward"], AchievementCatalogScript.reward_for("ach.campaign.clear_1"), "achievement claim uses catalog reward")
	_eq(executor.state.inventory["items"][QuestCatalogScript.WAR_MERIT_ITEM_ID], 30, "achievement claim grants war merit once")
	var claim_replay := _exec_ok(
		executor,
		"ach-claim-first-clear-replay",
		"claim_achievement",
		{"achievement_id": "ach.campaign.clear_1", "generation": 0, "request_id": "ach:req:first-clear"},
		"ach:req:first-clear-replay"
	)
	_eq(claim_replay["event"]["idempotent"], true, "same achievement claim request id replays idempotently")
	_eq(executor.state.inventory["items"][QuestCatalogScript.WAR_MERIT_ITEM_ID], 30, "achievement claim replay does not duplicate merit")
	var claim_conflict := executor.execute(_env(
		"ach-claim-conflict",
		"claim_achievement",
		{"achievement_id": "ach.boss.destroy_1", "generation": 0, "request_id": "ach:req:first-clear"},
		"ach:req:conflict",
		executor
	))
	_eq(claim_conflict["error"], "ACHIEVEMENT_REQUEST_ID_REUSE_MISMATCH", "same achievement request id with different fingerprint is rejected")
	var bad_generation := executor.execute(_env(
		"ach-claim-bad-generation",
		"claim_achievement",
		{"achievement_id": "ach.campaign.clear_1", "generation": 1, "request_id": "ach:req:bad-generation"},
		"ach:req:bad-generation",
		executor
	))
	_ok(String(bad_generation["error"]).contains("generation"), "achievement generation is fixed at zero")
	var start_a := _exec_ok(executor, "ach-start-a", "start_production", {"recipe_id": "ordinary.assault", "now_unix": 1000}, "ach:prod:start:a")
	_eq(start_a["event"]["type"], "production_started", "production start event contract is unchanged")
	_exec_ok(executor, "ach-start-b", "start_production", {"recipe_id": "ordinary.sonic", "now_unix": 1000}, "ach:prod:start:b")
	_exec_ok(executor, "ach-start-c", "start_production", {"recipe_id": "flying.rocket", "now_unix": 1000}, "ach:prod:start:c")
	_ok((executor.state.achievements["completed"] as Dictionary).has("ach.factory.start_3"), "three production events complete factory start milestone")
	var ready_claim := _exec_ok(executor, "ach-claim-ready-batch", "claim_ready_productions", {"now_unix": 1011}, "ach:prod:claim-ready")
	_eq((ready_claim["event"]["claimed"] as Array).size(), 3, "batch production claim reports the exact claimed amount")
	_eq(int(executor.state.achievements["counters"]["production_claimed"]), 3, "batch event increments progress by its payload amount")
	var duplicate_completed := AchievementServiceScript.apply_event(executor.state, ready_claim["event"], "ach-claim-ready-batch")
	_eq(duplicate_completed, [], "duplicate source event key is ignored")
	_eq(int(executor.state.achievements["counters"]["production_claimed"]), 3, "duplicate event cannot inflate progress")
	var tampered_state := GameStateScript.create_new(4461, 0)
	tampered_state.achievements["completed"]["ach.campaign.clear_5"] = {
		"achievement_id": "ach.campaign.clear_5",
		"generation": 0,
		"metric": "cleared_stages",
		"value": 5,
		"target": 5,
		"reward": {"merit": 999999, "gold": 999999, "xp_books": 999999},
	}
	var tampered_executor := CommandExecutorScript.new(tampered_state, Callable(self, "_record_save_success"))
	var tampered_claim := tampered_executor.execute(_env(
		"ach-claim-tampered",
		"claim_achievement",
		{"achievement_id": "ach.campaign.clear_5", "generation": 0, "request_id": "ach:req:tampered"},
		"ach:req:tampered",
		tampered_executor
	))
	_eq(tampered_claim["error"], "ACHIEVEMENT_REWARD_MISMATCH", "achievement claim rejects tampered stored rewards")
	_eq(int((tampered_executor.state.inventory["items"] as Dictionary).get(QuestCatalogScript.WAR_MERIT_ITEM_ID, 0)), 0, "tampered achievement claim grants no merit")
	var old_state := GameStateScript.create_new(4462, 0)
	old_state.stage_progress["cleared_stages"] = StageCatalogScript.all_stage_ids()
	for index in 3:
		old_state.command_receipts["legacy-start-%d" % index] = {"result": {"event": {"type": "production_started"}}}
	old_state.command_receipts["legacy-ready"] = {"result": {"event": {"type": "ready_productions_claimed", "claimed": [
		{"order_id": "a"}, {"order_id": "b"}, {"order_id": "c"},
		{"order_id": "d"}, {"order_id": "e"}, {"order_id": "f"},
	]}}}
	for index in 5:
		var offer_id: String = ["materials", "gold", "xp_books"][index % 3]
		old_state.receipt_ledgers["durable"]["legacy-exchange-%d" % index] = {
			"kind": "exchange_salvage",
			"request_id": "legacy-exchange-%d" % index,
			"offer_id": offer_id,
		}
	old_state.inventory["items"][QuestCatalogScript.WAR_MERIT_ITEM_ID] = 20140
	var old_executor := CommandExecutorScript.new(old_state, Callable(self, "_record_save_success"))
	_exec_ok(old_executor, "ach-old-refresh", "refresh_achievements", {}, "ach:old:refresh")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.campaign.clear_25"), "refresh backfills clear_25 from reliable cleared_stages")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.boss.destroy_5"), "refresh backfills boss count from reliable cleared_stages")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.boss.last_gate"), "refresh backfills final stage clear")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.factory.start_3"), "refresh backfills production_started from command receipts")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.factory.claim_6"), "refresh backfills exact batch production count from command receipts")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.salvage.exchange_5"), "refresh counts unique durable salvage exchanges")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.salvage.clean_recycler"), "refresh backfills all three salvage offer kinds")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.merit.rank_30"), "refresh backfills capped rank metric from war merit")
	_ok((old_executor.state.achievements["completed"] as Dictionary).has("ach.merit.after_cap_1000"), "refresh backfills post-cap merit milestone")
	var completed_before_refresh: Dictionary = (old_executor.state.achievements["completed"] as Dictionary).duplicate(true)
	_exec_ok(old_executor, "ach-refresh-no-self-progress", "refresh_achievements", {}, "ach:refresh:no-self-progress")
	_eq(old_executor.state.achievements["completed"], completed_before_refresh, "refresh_achievements does not self-progress")
	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(old_executor.state))
	_ok(bool(decoded.get("ok", false)), "achievement state save/load decodes")
	if bool(decoded.get("ok", false)):
		var restored: RefCounted = decoded["state"]
		_ok((restored.achievements["completed"] as Dictionary).has("ach.campaign.clear_25"), "save/load preserves achievement completion")


func _test_auto_skill_preference_command() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(4451, 0), Callable(self, "_record_save_success"))
	var hero_id := String(executor.state.roster[0].hero_id)
	_eq(executor.state.roster[0].auto_skill_enabled, false, "auto skill starts disabled")
	var enabled := _exec_ok(executor, "auto-on-1", "set_auto_skill_preference", {"hero_id": hero_id, "enabled": true}, "auto:%s" % hero_id)
	_eq(enabled["event"], {"type": "auto_skill_preference_changed", "hero_id": hero_id, "enabled": true}, "auto preference command emits stable UI event")
	_eq(executor.state.hero_by_id(hero_id).auto_skill_enabled, true, "auto preference persists on hero state")
	var replay := executor.execute(_env_with_revision("auto-on-1", "set_auto_skill_preference", {"hero_id": hero_id, "enabled": true}, "auto:%s" % hero_id, 0))
	_eq(replay, enabled, "auto preference command is idempotent")
	var missing := executor.execute(_env("auto-missing", "set_auto_skill_preference", {"hero_id": "missing", "enabled": true}, "auto:missing", executor))
	_eq(missing["error"], "HERO_NOT_FOUND", "auto preference rejects missing hero")
	var path := "user://meta_auto_skill_roundtrip.json"
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	var manager := SaveManagerCore.new(path)
	_ok(manager.save_state(executor.state), "enabled auto preference is written through the real save manager")
	var loaded := manager.load_state()
	_ok(bool(loaded.get("ok", false)), "enabled auto preference reloads from disk")
	if bool(loaded.get("ok", false)):
		var loaded_state: RefCounted = loaded["state"]
		_eq(loaded_state.hero_by_id(hero_id).auto_skill_enabled, true, "auto preference remains enabled after save/load roundtrip")
		var heroes: Array[Dictionary] = []
		for index in 6:
			var hero_data: Dictionary = loaded_state.roster[index].to_dict()
			hero_data["slot"] = index
			heroes.append(hero_data)
		var session: RefCounted = BattleSessionScript.new()
		session.start(heroes)
		var loaded_unit: Dictionary = (session.snapshot()["units"] as Array)[0]
		_eq(bool(loaded_unit["auto_skill"]), true, "reloaded hero preference enters the battle snapshot")
		var auto_cast := false
		while not session.is_finished and not auto_cast:
			for event in session.advance_tick():
				auto_cast = auto_cast or (event["type"] == &"skill_used" and String(event["unit_id"]) == hero_id)
		_ok(auto_cast, "reloaded auto preference actually casts the hero skill")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func _test_factory_catalog_and_production() -> void:
	var recipes := FactoryCatalogScript.recipes()
	_eq(recipes.size(), 8, "factory exposes eight production recipes")
	_eq(FactoryCatalogScript.recipe("ordinary.assault")["display_name"], "冲锋马桶人", "catalog exposes stable display fields")
	var executor := CommandExecutorScript.new(GameStateScript.create_new(446, 0), Callable(self, "_record_save_success"))
	var before: Dictionary = executor.state.factory.materials.duplicate(true)
	var locked := executor.execute(_env("factory-locked", "start_production", {"recipe_id": "heavy.armored", "now_unix": 90}, "factory:locked", executor))
	_eq(locked["error"], "BLUEPRINT_LOCKED", "advanced production requires blueprint unlock")
	var started := _exec_ok(executor, "factory-start-1", "start_production", {"recipe_id": "ordinary.assault", "now_unix": 100}, "factory:start:1")
	_eq(started["event"], {"type": "production_started", "order_id": "production_000001", "recipe_id": "ordinary.assault", "completes_at_unix": 105}, "start event has stable UI contract")
	_eq(executor.state.factory.materials["porcelain"], int(before["porcelain"]) - 20, "starting production consumes porcelain once")
	var start_replay := executor.execute(_env_with_revision("factory-start-1", "start_production", {"recipe_id": "ordinary.assault", "now_unix": 100}, "factory:start:1", 0))
	_eq(start_replay, started, "start production replay returns original receipt before revision check")
	_eq(executor.state.factory.production_queue.size(), 1, "start replay does not duplicate order")
	var early := executor.execute(_env("factory-early-1", "claim_production", {"order_id": "production_000001", "now_unix": 104}, "factory:claim:early", executor))
	_eq(early["error"], "PRODUCTION_NOT_READY", "unfinished production cannot be claimed")
	var roster_before: int = executor.state.roster.size()
	var claimed := _exec_ok(executor, "factory-claim-1", "claim_production", {"order_id": "production_000001", "now_unix": 105}, "factory:claim:1")
	_eq(claimed["event"]["type"], "production_claimed", "claim emits production_claimed")
	_eq(executor.state.roster.size(), roster_before + 1, "claim creates one permanent hero")
	_eq(executor.state.factory.production_queue.size(), 0, "claim removes completed order")
	var claim_replay := executor.execute(_env_with_revision("factory-claim-1", "claim_production", {"order_id": "production_000001", "now_unix": 105}, "factory:claim:1", 1))
	_eq(claim_replay, claimed, "claim replay returns original receipt")
	_eq(executor.state.roster.size(), roster_before + 1, "claim replay does not duplicate hero")


func _test_blueprint_unlocks_and_offline_claim() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(4461, 1000), Callable(self, "_record_save_success"))
	_eq(FactoryService.blueprint_status(executor.state).size(), 8, "blueprint status exposes all recipes to UI")
	var defeat := _exec_ok(executor, "unlock-defeat-1", "settle_battle", {"battle_id": "unlock-defeat-1", "outcome": "defeat", "ticks": 66}, "unlock:defeat:1")
	_eq(defeat["event"]["unlocked_blueprints"], ["flying.rocket", "heavy.armored"], "first defeat unlocks anti-wall factory options")
	_ok(bool(executor.state.factory.blueprints.get("heavy.armored", false)), "heavy blueprint is now unlocked")
	_exec_ok(executor, "offline-start-a", "start_production", {"recipe_id": "ordinary.assault", "now_unix": 2000}, "offline:start:a")
	_exec_ok(executor, "offline-start-b", "start_production", {"recipe_id": "ordinary.sonic", "now_unix": 2000}, "offline:start:b")
	var summary_early := FactoryService.offline_summary(executor.state, 2004)
	_eq(summary_early["ready_count"], 0, "offline summary reports no ready orders before absolute completion time")
	var summary_ready := FactoryService.offline_summary(executor.state, 2007)
	_eq(summary_ready["ready_count"], 2, "offline summary reports ready orders after absolute completion time")
	var roster_before: int = executor.state.roster.size()
	var claim_ready := _exec_ok(executor, "offline-claim-ready", "claim_ready_productions", {"now_unix": 2007}, "offline:claim:ready")
	_eq((claim_ready["event"]["claimed"] as Array).size(), 2, "claim_ready_productions claims every ready offline order")
	_eq(executor.state.roster.size(), roster_before + 2, "offline claim adds permanent produced heroes")
	_eq(executor.state.factory.production_queue.size(), 0, "offline claim clears ready orders")


func _test_three_to_one_merge() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(447, 0), Callable(self, "_record_save_success"))
	var armored_ids: Array[String] = []
	for hero in executor.state.roster:
		if hero.archetype_id == "armored":
			armored_ids.append(hero.hero_id)
	_eq(armored_ids.size(), 3, "starter roster has three matching armored heroes")
	var merged := _exec_ok(executor, "merge-1", "merge_heroes", {"hero_ids": armored_ids}, "merge:armored:1")
	_eq(merged["event"]["type"], "heroes_merged", "merge emits heroes_merged")
	_eq(merged["event"]["star"], 2, "three one-star heroes create one two-star hero")
	_eq(executor.state.roster.size(), 6, "three-to-one merge reduces roster by two")
	_ok(executor.state.formation.hero_ids().has(String(merged["event"]["hero_id"])), "formation reference follows merged hero")
	_ok(executor.state.validate().is_empty(), "merged state preserves invariants")
	var ids_after_merge: Array[String] = executor.state.roster_ids()
	_exec_ok(executor, "post-merge-start", "start_production", {"recipe_id": "ordinary.assault", "now_unix": 200}, "post-merge:start")
	var claim := _exec_ok(executor, "post-merge-claim", "claim_production", {"order_id": "production_000001", "now_unix": 205}, "post-merge:claim")
	_ok(not ids_after_merge.has(String(claim["event"]["hero_id"])), "monotonic hero sequence prevents ID reuse after merge")


func _test_fingerprint_and_idempotency() -> void:
	var fp_a := CommandFingerprintScript.build("grant_resources", {"b": 1, "a": [true, null, "x"]}, "k")
	var fp_b := CommandFingerprintScript.build("grant_resources", {"a": [true, null, "x"], "b": 1}, "k")
	_eq(fp_a["fingerprint"], fp_b["fingerprint"], "dictionary key order does not affect fingerprint")
	var fp_bad := CommandFingerprintScript.build("grant_resources", {"bad": 1.5}, "k")
	_ok(not bool(fp_bad["ok"]), "float payload is rejected")

	var executor := CommandExecutorScript.new(GameStateScript.create_new(555, 0), Callable(self, "_record_save_success"))
	var first := _exec_ok(executor, "idem-1", "grant_resources", {"resources": {"toilet_coins": 10}}, "same-business")
	var revision_after_first: int = executor.state.revision
	var second := executor.execute(_env_with_revision("idem-1", "grant_resources", {"resources": {"toilet_coins": 10}}, "same-business", 0))
	_eq(second, first, "same command id and fingerprint returns original receipt")
	_eq(executor.state.revision, revision_after_first, "idempotent replay does not mutate state")
	var mismatch_id := executor.execute(_env("idem-1", "grant_resources", {"resources": {"toilet_coins": 11}}, "same-business-2", executor))
	_eq(mismatch_id["error"], "COMMAND_ID_REUSE_MISMATCH", "same command id different fingerprint is rejected")
	var mismatch_business := executor.execute(_env("idem-2", "grant_resources", {"resources": {"toilet_coins": 11}}, "same-business", executor))
	_eq(mismatch_business["error"], "BUSINESS_KEY_REUSE_MISMATCH", "same business key different fingerprint is rejected")


func _test_no_save_callback_rejects_commands() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(556, 0))
	var result := executor.execute(_env("no-save", "grant_resources", {"resources": {"toilet_coins": 1}}, "no-save", executor))
	_eq(result["error"], "SAVE_UNAVAILABLE", "commands require explicit save callback")


func _test_revision_contract() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(557, 0), Callable(self, "_record_save_success"))
	_exec_ok(executor, "rev-1", "grant_resources", {"resources": {"toilet_coins": 1}}, "rev-1")
	var stale := executor.execute(_env_with_revision("rev-2", "grant_resources", {"resources": {"toilet_coins": 1}}, "rev-2", 0))
	_eq(stale["error"], "STALE_REVISION", "new command with old revision is rejected")


func _test_payload_schema_rejections() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(558, 0), Callable(self, "_record_save_success"))
	var unknown_resource := executor.execute(_env("bad-resource", "grant_resources", {"resources": {"diamonds": 1}}, "bad-resource", executor))
	_eq(unknown_resource["error"], "UNKNOWN_RESOURCE_KEY", "unknown resource key rejected")
	var string_amount := executor.execute(_env("string-resource", "grant_resources", {"resources": {"toilet_coins": "1"}}, "string-resource", executor))
	_eq(string_amount["error"], "RESOURCE_AMOUNT_MUST_BE_INT", "stringified int resource rejected")
	var negative_amount := executor.execute(_env("negative-resource", "grant_resources", {"resources": {"toilet_coins": -1}}, "negative-resource", executor))
	_eq(negative_amount["error"], "RESOURCE_AMOUNT_MUST_NOT_BE_NEGATIVE", "negative grant rejected")
	var extra_key := executor.execute(_env("extra-train", "train_hero", {"hero_id": "x", "book_count": 1, "extra": 1}, "extra-train", executor))
	_ok(String(extra_key["error"]).contains("payload keys mismatch"), "extra command payload key rejected")


func _test_save_failure_does_not_swap() -> void:
	var state := GameStateScript.create_new(666, 0)
	var executor := CommandExecutorScript.new(state, Callable(self, "_save_failure"))
	var before: Dictionary = executor.state.to_dict()
	var result := executor.execute(_env("fail-save", "grant_resources", {"resources": {"toilet_coins": 100}}, "fail-save", executor))
	_eq(result["error"], "SAVE_FAILED", "save failure rejects durable operation")
	_eq(executor.state.to_dict(), before, "save failure does not swap live state")


func _test_save_codec_roundtrip_and_strict_values() -> void:
	var state := GameStateScript.create_new(777, 0)
	var text := SaveCodecScript.to_json_text(state)
	var decoded := SaveCodecScript.from_json_text(text)
	_ok(bool(decoded["ok"]), "save codec roundtrip decodes: %s" % str(decoded))
	if bool(decoded["ok"]):
		var restored: RefCounted = decoded["state"]
		_eq(restored.to_dict(), state.to_dict(), "save codec roundtrip preserves state")
	var illegal := state.to_dict()
	illegal["bad_float"] = 1.25
	var illegal_decoded := SaveCodecScript.decode(illegal)
	_ok(not bool(illegal_decoded["ok"]), "save codec rejects unknown top-level key")
	var direct_float := state.to_dict()
	direct_float["run_seed"] = 1.0
	var direct_float_decoded := SaveCodecScript.decode(direct_float)
	_ok(not bool(direct_float_decoded["ok"]), "direct dictionary integral float is rejected")
	var string_int := state.to_dict()
	string_int["economy"]["gold"] = "250"
	var string_int_decoded := SaveCodecScript.decode(string_int)
	_ok(not bool(string_int_decoded["ok"]), "stringified int is rejected")
	var invalid_enum := state.to_dict()
	invalid_enum["roster"][0]["class_id"] = "bard"
	var invalid_enum_decoded := SaveCodecScript.decode(invalid_enum)
	_ok(not bool(invalid_enum_decoded["ok"]), "invalid class enum rejected")
	var unknown_nested := state.to_dict()
	unknown_nested["roster"][0]["unknown"] = 1
	var unknown_nested_decoded := SaveCodecScript.decode(unknown_nested)
	_ok(not bool(unknown_nested_decoded["ok"]), "unknown nested hero key rejected")
	var invalid := state.to_dict()
	invalid["economy"]["gold"] = -1
	var invalid_decoded := SaveCodecScript.decode(invalid)
	_ok(not bool(invalid_decoded["ok"]), "save codec rejects invariant violations")


func _test_strict_v1_to_v2_migration() -> void:
	var source := GameStateScript.create_new(778, 0).to_dict()
	var v1 := source.duplicate(true)
	v1["schema_version"] = 1
	v1["content_version"] = "meta-core-v1"
	v1.erase("factory")
	v1.erase("auto_skill_preferences")
	v1.erase("achievements")
	while (v1["roster"] as Array).size() > 4:
		(v1["roster"] as Array).pop_back()
	for hero_data in v1["roster"]:
		hero_data.erase("archetype_id")
		hero_data.erase("star")
		hero_data.erase("auto_skill_enabled")
	var legacy_roster := v1["roster"] as Array
	v1["formation"] = {
		"front_left": legacy_roster[0]["hero_id"],
		"front_right": legacy_roster[1]["hero_id"],
		"back_left": legacy_roster[2]["hero_id"],
		"back_right": legacy_roster[3]["hero_id"],
	}
	var migrated := SaveCodecScript.decode(v1)
	_ok(bool(migrated["ok"]), "strict legacy v1 save migrates: %s" % str(migrated))
	if bool(migrated["ok"]):
		var state: RefCounted = migrated["state"]
		_eq(state.schema_version, 4, "migration writes schema v4")
		_eq(state.roster.size(), 8, "migration preserves four legacy heroes and adds four starter templates")
		_eq(state.formation.hero_ids().size(), 6, "migration creates six-slot formation")
		_eq(state.factory.next_hero_sequence, 9, "migration initializes monotonic hero sequence")
		_eq(state.roster[0].auto_skill_enabled, false, "migration initializes auto skill preference")
		_ok(state.validate().is_empty(), "migrated state validates")
	var polluted := v1.duplicate(true)
	polluted["unexpected"] = 1
	var rejected := SaveCodecScript.decode(polluted)
	_ok(not bool(rejected["ok"]), "v1 migration rejects unknown legacy fields before transforming")


func _test_v2_to_v3_factory_migration_and_strictness() -> void:
	var v2 := GameStateScript.create_new(779, 1000).to_dict()
	v2["schema_version"] = 2
	v2["content_version"] = "factory-siege-v2"
	v2.erase("auto_skill_preferences")
	v2.erase("achievements")
	for hero_data in v2["roster"]:
		(hero_data as Dictionary).erase("auto_skill_enabled")
	v2["factory"]["materials"] = {"porcelain": 77, "parts": 66, "sludge": 55}
	v2["factory"]["blueprints"]["flying.rocket"] = true
	v2["factory"]["production_queue"] = [{
		"order_id": "production_000006",
		"recipe_id": "ordinary.assault",
		"started_at_unix": 1000,
		"completes_at_unix": 1005,
	}]
	v2["factory"]["next_sequence"] = 7
	v2["factory"]["next_hero_sequence"] = 12
	var migrated := SaveCodecScript.decode(v2)
	_ok(bool(migrated.get("ok", false)), "strict v2 save migrates to v3: %s" % str(migrated))
	if bool(migrated.get("ok", false)):
		var state: RefCounted = migrated["state"]
		_eq(state.schema_version, 4, "v2 migration writes schema v4")
		_eq(state.factory.materials, {"porcelain": 77, "parts": 66, "sludge": 55}, "v2 migration preserves factory materials")
		_ok(bool(state.factory.blueprints.get("flying.rocket", false)), "v2 migration preserves unlocked blueprints")
		_eq(state.factory.production_queue.size(), 1, "v2 migration preserves active production orders")
		_eq(state.factory.next_sequence, 7, "v2 migration preserves order sequence")
		_eq(state.factory.next_hero_sequence, 12, "v2 migration preserves hero sequence")
	var unknown_blueprint := GameStateScript.create_new(780, 1000).to_dict()
	unknown_blueprint["factory"]["blueprints"]["unknown.recipe"] = true
	_ok(not bool(SaveCodecScript.decode(unknown_blueprint).get("ok", false)), "schema v3 rejects unknown blueprint recipe IDs")
	var unknown_order := GameStateScript.create_new(781, 1000).to_dict()
	unknown_order["factory"]["production_queue"] = [{
		"order_id": "production_000001",
		"recipe_id": "unknown.recipe",
		"started_at_unix": 1000,
		"completes_at_unix": 1001,
	}]
	_ok(not bool(SaveCodecScript.decode(unknown_order).get("ok", false)), "schema v3 rejects unknown production recipe IDs")
	var queue_overflow := GameStateScript.create_new(782, 1000).to_dict()
	queue_overflow["factory"]["production_queue"] = []
	for index in 4:
		queue_overflow["factory"]["production_queue"].append({
			"order_id": "production_%06d" % (index + 1),
			"recipe_id": "ordinary.assault",
			"started_at_unix": 1000,
			"completes_at_unix": 1005,
		})
	_ok(not bool(SaveCodecScript.decode(queue_overflow).get("ok", false)), "schema v3 rejects production queues above three slots")


func _test_save_manager_atomic_roundtrip() -> void:
	var path := "user://meta_core_test_save.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if FileAccess.file_exists(path + ".tmp"):
		DirAccess.remove_absolute(path + ".tmp")
	if FileAccess.file_exists(path + ".bak"):
		DirAccess.remove_absolute(path + ".bak")
	var manager := SaveManagerCore.new(path)
	var state := GameStateScript.create_new(888, 0)
	_ok(manager.save_state(state), "save manager writes valid save")
	var loaded := manager.load_state()
	_ok(bool(loaded["ok"]), "save manager loads valid save: %s" % str(loaded))
	if bool(loaded["ok"]):
		var loaded_state: RefCounted = loaded["state"]
		_eq(loaded_state.to_dict(), state.to_dict(), "save manager roundtrip preserves state")
	DirAccess.remove_absolute(path)
	if FileAccess.file_exists(path + ".bak"):
		DirAccess.remove_absolute(path + ".bak")


func _test_save_export_import_contract() -> void:
	var path := "user://meta_core_import_test.json"
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	var manager := SaveManagerCore.new(path)
	var original := GameStateScript.create_new(890, 100)
	original.revision = 3
	_ok(manager.save_state(original), "import contract starts from a durable original save")
	var exported: Dictionary = manager.export_state(original)
	_ok(bool(exported.get("ok", false)), "save export produces validated JSON")
	_ok(int(exported.get("byte_count", 0)) > 0, "save export reports a positive byte count")
	var parsed: Dictionary = manager.parse_import_text(String(exported.get("text", "")))
	_ok(bool(parsed.get("ok", false)), "exported JSON passes the import validation pipeline")
	if bool(parsed.get("ok", false)):
		_eq((parsed["state"] as RefCounted).to_dict(), original.to_dict(), "import preview preserves the complete state")
	var invalid := manager.parse_import_text("{\"schema_version\":8}")
	_ok(not bool(invalid.get("ok", false)), "invalid import is rejected before publication")
	var loaded_after_invalid := manager.load_state()
	_ok(bool(loaded_after_invalid.get("ok", false)), "invalid import leaves the current durable save readable")
	if bool(loaded_after_invalid.get("ok", false)):
		_eq((loaded_after_invalid["state"] as RefCounted).to_dict(), original.to_dict(), "invalid import does not mutate the current save")
	var oversized := manager.parse_import_text("x".repeat(SaveManagerCore.MAX_SAVE_BYTES + 1))
	_eq(oversized.get("error"), "SAVE_TOO_LARGE", "oversized import is rejected before JSON parsing")

	var replacement := GameStateScript.create_new(891, 200)
	replacement.revision = 9
	replacement.stage_progress["cleared_stages"] = ["stage_1_1"]
	replacement.stage_progress["highest_unlocked_stage"] = "stage_1_2"
	var replacement_export := manager.export_state(replacement)
	var replacement_parse := manager.parse_import_text(String(replacement_export.get("text", "")))
	_ok(bool(replacement_parse.get("ok", false)), "replacement backup validates")
	if bool(replacement_parse.get("ok", false)):
		var published := manager.publish_imported_state(replacement_parse["state"])
		_ok(bool(published.get("ok", false)), "validated replacement publishes atomically")
		var restored := manager.load_state()
		_ok(bool(restored.get("ok", false)), "published replacement reloads")
		if bool(restored.get("ok", false)):
			_eq((restored["state"] as RefCounted).to_dict(), replacement.to_dict(), "published replacement becomes the durable authority")

	var game_script := preload("res://game/scripts/autoloads/game.gd")
	var game_node: Node = game_script.new()
	_eq(game_node.bootstrap_with_manager(manager, 1, 1), "loaded", "game bootstraps from the imported replacement")
	var incompatible := replacement.to_dict()
	incompatible["content_version"] = "legacy-incompatible-content"
	var incompatible_text := JSON.stringify(incompatible)
	var rejected_preview: Dictionary = game_node.preview_local_save_import(manager, incompatible_text)
	_eq(rejected_preview.get("error"), "SAVE_IMPORT_INCOMPATIBLE_CONTENT", "game rejects a schema-valid backup from another content contract")
	_eq(game_node.current_state().content_version, "toilet-factory-slg-v3-factions", "rejected content import leaves the live state unchanged")
	game_node.free()
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func _test_save_manager_missing_main_valid_bak() -> void:
	var path := "user://meta_core_missing_main.json"
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	var state := GameStateScript.create_new(889, 0)
	var bak := FileAccess.open(path + ".bak", FileAccess.WRITE)
	bak.store_string(SaveCodecScript.to_json_text(state))
	bak.close()
	var manager := SaveManagerCore.new(path)
	var loaded := manager.load_state()
	_ok(bool(loaded["ok"]), "save manager recovers when main is missing and bak is valid")
	if bool(loaded["ok"]):
		var recovered: RefCounted = loaded["state"]
		_eq(recovered.to_dict(), state.to_dict(), "valid bak recovery preserves state")
	DirAccess.remove_absolute(path + ".bak")


func _test_save_manager_deletes_all_local_candidates() -> void:
	var path := "user://meta_core_delete_test.json"
	for suffix in ["", ".tmp", ".bak"]:
		var file := FileAccess.open(path + suffix, FileAccess.WRITE)
		file.store_string("{}")
		file.close()
	var manager := SaveManagerCore.new(path)
	var deleted: Dictionary = manager.delete_local_save()
	_ok(bool(deleted.get("ok", false)), "save manager deletes local save candidates")
	_eq((deleted.get("removed", []) as Array).size(), 3, "delete reports primary, backup, and temporary files")
	for suffix in ["", ".tmp", ".bak"]:
		_ok(not FileAccess.file_exists(path + suffix), "delete removes save candidate %s" % suffix)
	var repeated: Dictionary = manager.delete_local_save()
	_ok(bool(repeated.get("ok", false)), "deleting an already empty slot is idempotent")


func _test_game_bootstrap_contract() -> void:
	var game_script := preload("res://game/scripts/autoloads/game.gd")
	var game_node: Node = game_script.new()
	var existing_state := GameStateScript.create_new(990, 12)
	var valid_manager := FakeBootstrapSaveManager.new()
	valid_manager.load_result = {"ok": true, "state": existing_state}
	_eq(game_node.bootstrap_with_manager(valid_manager, 1, 1), "loaded", "bootstrap loads valid save")
	_eq(game_node.current_state().to_dict(), existing_state.to_dict(), "bootstrap uses loaded state")
	_eq(valid_manager.saved_states.size(), 0, "loading valid save does not overwrite")

	var missing_manager := FakeBootstrapSaveManager.new()
	_eq(game_node.bootstrap_with_manager(missing_manager, 991, 13), "created", "bootstrap creates when save is missing")
	_eq(missing_manager.saved_states.size(), 1, "bootstrap saves new game before ready")
	_eq(game_node.current_state().run_seed, 991, "bootstrap created state uses requested seed")

	var corrupt_manager := FakeBootstrapSaveManager.new()
	corrupt_manager.load_result = {"ok": false, "error": "unsupported schema_version"}
	_eq(game_node.bootstrap_with_manager(corrupt_manager, 992, 14), "created", "bootstrap destructively replaces an obsolete schema")
	_eq(corrupt_manager.delete_calls, 1, "obsolete schema deletes its local save candidates")
	_eq(corrupt_manager.saved_states.size(), 1, "obsolete schema writes one fresh Gman save")
	_eq(game_node.current_state().roster.size(), 1, "obsolete schema replacement starts with only permanent G-Man")
	game_node.free()


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


func _save_failure(_state: RefCounted) -> bool:
	return false

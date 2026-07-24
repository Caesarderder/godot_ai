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

var failures: Array[String] = []
var save_calls: int = 0


class FakeBootstrapSaveManager:
	extends RefCounted

	var load_result: Dictionary = {"ok": false, "error": "SAVE_NOT_FOUND"}
	var saved_states: Array[Dictionary] = []
	var save_result: bool = true

	func load_state() -> Dictionary:
		return load_result

	func save_state(state: RefCounted) -> bool:
		saved_states.append(state.to_dict())
		return save_result


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
	_test_recruit_four_to_eight_and_ticket_cost()
	_test_progression_clamp_bulk_equivalence()
	_test_formation_validation()
	_test_battle_settlement()
	_test_auto_skill_preference_command()
	_test_factory_catalog_and_production()
	_test_blueprint_unlocks_and_offline_claim()
	_test_three_to_one_merge()
	_test_fingerprint_and_idempotency()
	_test_no_save_callback_rejects_commands()
	_test_revision_contract()
	_test_payload_schema_rejections()
	_test_save_failure_does_not_swap()
	_test_save_codec_roundtrip_and_strict_values()
	_test_strict_v1_to_v2_migration()
	_test_v2_to_v3_factory_migration_and_strictness()
	_test_save_manager_atomic_roundtrip()
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
	_eq(state.schema_version, 3, "new game uses schema v3")
	_eq(state.roster.size(), 8, "new game starts with six deployed heroes and two reserves")
	_eq(state.economy.gold, 250, "new game starts with 250 gold")
	_eq(state.economy.xp_books, 2, "new game starts with two xp books")
	_eq(state.economy.forge_stones, 0, "new game starts with zero forge stones")
	_eq(state.economy.recruit_tickets, 0, "new game has no implicit recruitment tickets")
	_eq(state.formation.hero_ids().size(), 6, "new game formation has six slots")
	_eq(state.factory.materials, {"porcelain": 120, "parts": 100, "sludge": 80}, "new game has playable factory materials")
	_eq(state.factory.blueprints, {"ordinary.assault": true, "ordinary.sonic": true}, "new game starts with basic ordinary-workshop blueprints only")
	_ok(state.validate().is_empty(), "new game invariants pass")


func _test_seeded_hero_generation() -> void:
	var state_a := GameStateScript.create_new(98765, 0)
	var state_b := GameStateScript.create_new(98765, 999)
	var state_c := GameStateScript.create_new(98766, 0)
	var archetypes: Array[String] = []
	for hero in state_a.roster:
		archetypes.append(hero.archetype_id)
	_eq(archetypes, ["assault", "armored", "assault", "sonic", "repair", "parasite", "armored", "armored"], "starter roster supports battle and immediate merge")
	_eq(state_a.roster[0].to_dict(), state_b.roster[0].to_dict(), "same run seed is stable and ignores save_id/time")
	_ok(state_a.roster[0].to_dict() != state_c.roster[0].to_dict(), "different run seed changes generated hero")
	_ok(HeroGenerator.GIVEN_NAMES.size() * HeroGenerator.FAMILY_NAMES.size() >= 40, "name pool has at least 40 combinations")
	_eq(HeroGenerator.TRAIT_IDS.size(), 8, "trait pool has eight traits")
	_eq(HeroGenerator.APTITUDE_WEIGHT_BP, {"C": 4000, "B": 3500, "A": 2000, "S": 500}, "aptitude weights match configured default")
	for hero in state_a.roster:
		for key in HeroStateScript.ATTR_KEYS:
			var baseline := int(HeroGenerator.CLASS_BASE_STATS[hero.class_id][key])
			var delta := int(hero.base_stats[key]) - baseline
			_ok(delta >= -1 and delta <= 1, "L1 variance is -1/0/+1 for %s.%s" % [hero.hero_id, key])


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
	_eq(stats["max_hp"], 50 + int(bulk.base_stats["vig"]) * 10, "derived max_hp formula")
	_eq(stats["defense"], HeroProgression.class_armor(bulk.class_id) + int(bulk.base_stats["vig"]) * 2, "derived defense formula")
	_eq(stats["physical_atk"], int(bulk.base_stats["str"]) * 3, "derived physical attack formula")
	_eq(stats["magic_atk"], int(bulk.base_stats["int"]) * 3, "derived magic attack formula")
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
	var victory := _exec_ok(
		executor,
		"battle-win-1",
		"settle_battle",
		{"battle_id": "battle-win-1", "outcome": "victory", "ticks": 77},
		"battle:battle-win-1"
	)
	_eq(victory["event"]["reward"], {"gold": 80, "xp_books": 1, "porcelain": 24, "parts": 16, "sludge": 12}, "victory reward is owned by domain reducer")
	_eq(executor.state.economy.gold, gold_before + 80, "victory grants fixed gold")
	_eq(executor.state.economy.xp_books, books_before + 1, "victory grants fixed xp book")
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
	var timeout_executor := CommandExecutorScript.new(GameStateScript.create_new(4452, 0), Callable(self, "_record_save_success"))
	var timeout_materials: Dictionary = timeout_executor.state.factory.materials.duplicate(true)
	var timeout := _exec_ok(
		timeout_executor,
		"battle-timeout-1",
		"settle_battle",
		{"battle_id": "battle-timeout-1", "outcome": "timeout", "ticks": 300},
		"battle:battle-timeout-1"
	)
	_eq(timeout["event"]["reward"], {"gold": 6, "xp_books": 2, "porcelain": 4, "parts": 3, "sludge": 2}, "timeout grants bounded salvage and retry training books")
	_eq(timeout_executor.state.factory.materials["porcelain"], int(timeout_materials["porcelain"]) + 4, "timeout salvage prevents factory deadlock")
	_ok((timeout["event"]["unlocked_blueprints"] as Array).has("heavy.armored"), "first timeout unlocks counterplay heavy blueprint")
	var defeat_executor := CommandExecutorScript.new(GameStateScript.create_new(4453, 0), Callable(self, "_record_save_success"))
	var defeat := _exec_ok(defeat_executor, "battle-defeat-1", "settle_battle", {"battle_id": "battle-defeat-1", "outcome": "defeat", "ticks": 40}, "battle:battle-defeat-1")
	_eq(defeat["event"]["reward"]["xp_books"], 2, "defeat grants training books for first retry growth")
	var invalid := executor.execute(_env(
		"battle-invalid",
		"settle_battle",
		{"battle_id": "battle-invalid", "outcome": "draw", "ticks": 1},
		"battle:battle-invalid",
		executor
	))
	_ok(not bool(invalid["ok"]), "invalid battle outcome is rejected")


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
	var first := _exec_ok(executor, "idem-1", "grant_resources", {"resources": {"gold": 10}}, "same-business")
	var revision_after_first: int = executor.state.revision
	var second := executor.execute(_env_with_revision("idem-1", "grant_resources", {"resources": {"gold": 10}}, "same-business", 0))
	_eq(second, first, "same command id and fingerprint returns original receipt")
	_eq(executor.state.revision, revision_after_first, "idempotent replay does not mutate state")
	var mismatch_id := executor.execute(_env("idem-1", "grant_resources", {"resources": {"gold": 11}}, "same-business-2", executor))
	_eq(mismatch_id["error"], "COMMAND_ID_REUSE_MISMATCH", "same command id different fingerprint is rejected")
	var mismatch_business := executor.execute(_env("idem-2", "grant_resources", {"resources": {"gold": 11}}, "same-business", executor))
	_eq(mismatch_business["error"], "BUSINESS_KEY_REUSE_MISMATCH", "same business key different fingerprint is rejected")


func _test_no_save_callback_rejects_commands() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(556, 0))
	var result := executor.execute(_env("no-save", "grant_resources", {"resources": {"gold": 1}}, "no-save", executor))
	_eq(result["error"], "SAVE_UNAVAILABLE", "commands require explicit save callback")


func _test_revision_contract() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(557, 0), Callable(self, "_record_save_success"))
	_exec_ok(executor, "rev-1", "grant_resources", {"resources": {"gold": 1}}, "rev-1")
	var stale := executor.execute(_env_with_revision("rev-2", "grant_resources", {"resources": {"gold": 1}}, "rev-2", 0))
	_eq(stale["error"], "STALE_REVISION", "new command with old revision is rejected")


func _test_payload_schema_rejections() -> void:
	var executor := CommandExecutorScript.new(GameStateScript.create_new(558, 0), Callable(self, "_record_save_success"))
	var unknown_resource := executor.execute(_env("bad-resource", "grant_resources", {"resources": {"diamonds": 1}}, "bad-resource", executor))
	_eq(unknown_resource["error"], "UNKNOWN_RESOURCE_KEY", "unknown resource key rejected")
	var string_amount := executor.execute(_env("string-resource", "grant_resources", {"resources": {"gold": "1"}}, "string-resource", executor))
	_eq(string_amount["error"], "RESOURCE_AMOUNT_MUST_BE_INT", "stringified int resource rejected")
	var negative_amount := executor.execute(_env("negative-resource", "grant_resources", {"resources": {"gold": -1}}, "negative-resource", executor))
	_eq(negative_amount["error"], "RESOURCE_AMOUNT_MUST_NOT_BE_NEGATIVE", "negative grant rejected")
	var extra_key := executor.execute(_env("extra-train", "train_hero", {"hero_id": "x", "book_count": 1, "extra": 1}, "extra-train", executor))
	_ok(String(extra_key["error"]).contains("payload keys mismatch"), "extra command payload key rejected")


func _test_save_failure_does_not_swap() -> void:
	var state := GameStateScript.create_new(666, 0)
	var executor := CommandExecutorScript.new(state, Callable(self, "_save_failure"))
	var before: Dictionary = executor.state.to_dict()
	var result := executor.execute(_env("fail-save", "grant_resources", {"resources": {"gold": 100}}, "fail-save", executor))
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
		_eq(state.schema_version, 3, "migration writes schema v3")
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
		_eq(state.schema_version, 3, "v2 migration writes schema v3")
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
	_eq(game_node.bootstrap_with_manager(corrupt_manager, 992, 14), "load_failed:unsupported schema_version", "bootstrap does not overwrite corrupt save")
	_eq(corrupt_manager.saved_states.size(), 0, "corrupt save is not silently overwritten")
	var blocked_result: Dictionary = game_node.execute_command({
		"command_id": "blocked-after-corrupt",
		"type": "grant_resources",
		"payload": {"resources": {"gold": 1}},
		"business_key": "blocked-after-corrupt",
		"expected_revision": game_node.current_state().revision,
		"requested_at": 0,
	})
	_eq(blocked_result["error"], "SAVE_LOAD_FAILED", "command after corrupt bootstrap is blocked")
	_eq(corrupt_manager.saved_states.size(), 0, "blocked command after corrupt bootstrap does not save")
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

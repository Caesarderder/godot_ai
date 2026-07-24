class_name CommandExecutor
extends RefCounted

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const FormationService := preload("res://game/scripts/domain/formation/formation_service.gd")
const FactoryService := preload("res://game/scripts/domain/factory/factory_service.gd")
const CommandClassRegistryScript := preload("res://game/scripts/commands/command_class_registry.gd")
const CommandFingerprintScript := preload("res://game/scripts/commands/command_fingerprint.gd")

var state: RefCounted = GameStateScript.create_new()
var save_callback: Callable = Callable()


func _init(initial_state: RefCounted = null, injected_save_callback: Callable = Callable()) -> void:
	if initial_state != null:
		state = initial_state
	save_callback = injected_save_callback


func execute(envelope: Dictionary) -> Dictionary:
	var command_type := String(envelope.get("type", ""))
	var command_id := String(envelope.get("command_id", ""))
	var business_key := String(envelope.get("business_key", ""))
	var payload: Variant = envelope.get("payload", {})
	if command_id.is_empty():
		return _error("COMMAND_ID_REQUIRED")
	if envelope.has("class"):
		return _error("COMMAND_CLASS_OVERRIDE_REJECTED")
	if not CommandClassRegistryScript.has_command(command_type):
		return _error("UNKNOWN_COMMAND")
	var payload_error := _validate_payload(command_type, payload)
	if not payload_error.is_empty():
		return _error(payload_error)
	var fp_result := CommandFingerprintScript.build(command_type, payload, business_key)
	if not bool(fp_result["ok"]):
		return _error(String(fp_result["error"]))
	var fingerprint := String(fp_result["fingerprint"])
	if state.command_receipts.has(command_id):
		var old_command_receipt := state.command_receipts[command_id] as Dictionary
		if String(old_command_receipt["fingerprint"]) != fingerprint:
			return _error("COMMAND_ID_REUSE_MISMATCH")
		return (old_command_receipt["result"] as Dictionary).duplicate(true)
	if not business_key.is_empty() and state.business_receipts.has(business_key):
		var old_business_receipt := state.business_receipts[business_key] as Dictionary
		if String(old_business_receipt["fingerprint"]) != fingerprint:
			return _error("BUSINESS_KEY_REUSE_MISMATCH")
		return (old_business_receipt["result"] as Dictionary).duplicate(true)
	if not envelope.has("expected_revision") or typeof(envelope["expected_revision"]) != TYPE_INT:
		return _error("EXPECTED_REVISION_REQUIRED")
	if int(envelope["expected_revision"]) != int(state.revision):
		return _error("STALE_REVISION")
	if not save_callback.is_valid():
		return _error("SAVE_UNAVAILABLE")

	var candidate: RefCounted = state.deep_clone()
	var event: Dictionary = _apply_reducer(candidate, command_type, payload)
	if not bool(event.get("ok", false)):
		return _error(String(event.get("error", "COMMAND_FAILED")))
	var invariant_errors: Array[String] = candidate.validate()
	if not invariant_errors.is_empty():
		return _error("INVARIANT_FAILED: %s" % "; ".join(invariant_errors))
	candidate.revision += 1
	var result := {
		"ok": true,
		"command_id": command_id,
		"type": command_type,
		"state_revision": candidate.revision,
		"event": event.get("event", {}),
	}
	var receipt := {
		"command_id": command_id,
		"business_key": business_key,
		"type": command_type,
		"class": CommandClassRegistryScript.command_class(command_type),
		"fingerprint": fingerprint,
		"canonical_payload": String(fp_result["canonical_payload"]),
		"result": result.duplicate(true),
	}
	candidate.command_receipts[command_id] = receipt
	if not business_key.is_empty():
		candidate.business_receipts[business_key] = receipt
	if not _save_candidate(candidate):
		return _error("SAVE_FAILED")
	state = candidate
	return result


func _apply_reducer(candidate: RefCounted, command_type: String, payload: Variant) -> Dictionary:
	var data := payload as Dictionary
	match command_type:
		"grant_resources":
			candidate.economy.grant(data.get("resources", {}) as Dictionary)
			return {"ok": true, "event": {"type": "resources_granted"}}
		"settle_battle":
			var battle_id := String(data.get("battle_id", ""))
			var outcome := String(data.get("outcome", ""))
			var ticks := int(data.get("ticks", 0))
			var reward := {"gold": 0, "xp_books": 0, "porcelain": 0, "parts": 0, "sludge": 0}
			if outcome == "victory":
				reward = {"gold": 80, "xp_books": 1, "porcelain": 24, "parts": 16, "sludge": 12}
				var cleared: Array = candidate.stage_progress.get("cleared_stages", [])
				if not cleared.has("stage_1_1"):
					cleared.append("stage_1_1")
				candidate.stage_progress["cleared_stages"] = cleared
			elif outcome == "defeat":
				reward = {"gold": 12, "xp_books": 2, "porcelain": 8, "parts": 5, "sludge": 4}
			elif outcome == "timeout":
				reward = {"gold": 6, "xp_books": 2, "porcelain": 4, "parts": 3, "sludge": 2}
			candidate.economy.grant({"gold": reward["gold"], "xp_books": reward["xp_books"]})
			candidate.factory.grant({"porcelain": reward["porcelain"], "parts": reward["parts"], "sludge": reward["sludge"]})
			candidate.attempt_counters["stage_1_1"] = int(candidate.attempt_counters.get("stage_1_1", 0)) + 1
			var unlocked_blueprints := FactoryService.apply_battle_unlocks(candidate, outcome, int(candidate.attempt_counters["stage_1_1"]))
			return {
				"ok": true,
				"event": {
					"type": "battle_settled",
					"battle_id": battle_id,
					"outcome": outcome,
					"ticks": ticks,
					"reward": reward,
					"unlocked_blueprints": unlocked_blueprints,
				},
			}
		"start_production":
			return FactoryService.start_production(candidate, String(data["recipe_id"]), int(data["now_unix"]))
		"claim_production":
			return FactoryService.claim_production(candidate, String(data["order_id"]), int(data["now_unix"]))
		"claim_ready_productions":
			return FactoryService.claim_ready_productions(candidate, int(data["now_unix"]))
		"merge_heroes":
			var hero_ids: Array[String] = []
			for hero_id in data["hero_ids"]:
				hero_ids.append(String(hero_id))
			return FactoryService.merge_heroes(candidate, hero_ids)
		"recruit_hero":
			if candidate.economy.recruit_tickets < 1:
				return {"ok": false, "error": "NOT_ENOUGH_RECRUIT_TICKETS"}
			candidate.economy.recruit_tickets -= 1
			var hero: RefCounted = HeroGenerator.generate_hero(candidate.run_seed, candidate.allocate_hero_index())
			candidate.roster.append(hero)
			return {"ok": true, "event": {"type": "hero_recruited", "hero_id": hero.hero_id}}
		"train_hero":
			var hero_id := String(data.get("hero_id", ""))
			var book_count := int(data.get("book_count", 0))
			if book_count <= 0:
				return {"ok": false, "error": "BOOK_COUNT_REQUIRED"}
			var hero: RefCounted = candidate.hero_by_id(hero_id)
			if hero == null:
				return {"ok": false, "error": "HERO_NOT_FOUND"}
			var gold_cost := book_count * HeroProgression.GOLD_PER_BOOK
			if candidate.economy.xp_books < book_count:
				return {"ok": false, "error": "NOT_ENOUGH_XP_BOOKS"}
			if candidate.economy.gold < gold_cost:
				return {"ok": false, "error": "NOT_ENOUGH_GOLD"}
			candidate.economy.xp_books -= book_count
			candidate.economy.gold -= gold_cost
			HeroProgression.train_with_books(hero, book_count)
			return {
				"ok": true,
				"event": {
					"type": "hero_trained",
					"hero_id": hero_id,
					"book_count": book_count,
					"gold_cost": gold_cost,
					"level": hero.level,
					"xp": hero.xp,
				},
			}
		"set_formation":
			var formation := FormationService.build_from_payload(data)
			var errors: Array[String] = formation.validate(candidate.roster_ids())
			if not errors.is_empty():
				return {"ok": false, "error": "INVALID_FORMATION: %s" % "; ".join(errors)}
			candidate.formation = formation
			return {"ok": true, "event": {"type": "formation_changed"}}
		"set_auto_skill_preference":
			var hero_id := String(data["hero_id"])
			var hero: RefCounted = candidate.hero_by_id(hero_id)
			if hero == null:
				return {"ok": false, "error": "HERO_NOT_FOUND"}
			hero.auto_skill_enabled = bool(data["enabled"])
			candidate.auto_skill_preferences[hero_id] = hero.auto_skill_enabled
			return {"ok": true, "event": {"type": "auto_skill_preference_changed", "hero_id": hero_id, "enabled": hero.auto_skill_enabled}}
		_:
			return {"ok": false, "error": "UNKNOWN_COMMAND"}


func _save_candidate(candidate: RefCounted) -> bool:
	if save_callback.is_valid():
		return bool(save_callback.call(candidate))
	return false


func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}


func _validate_payload(command_type: String, payload: Variant) -> String:
	if typeof(payload) != TYPE_DICTIONARY:
		return "PAYLOAD_MUST_BE_DICTIONARY"
	var data := payload as Dictionary
	match command_type:
		"grant_resources":
			var error := _exact_keys(data, ["resources"], "grant_resources")
			if not error.is_empty():
				return error
			if typeof(data["resources"]) != TYPE_DICTIONARY:
				return "grant_resources.resources must be dictionary"
			var resources := data["resources"] as Dictionary
			for key in resources.keys():
				if typeof(key) != TYPE_STRING:
					return "grant_resources resource keys must be strings"
				if not ["gold", "recruit_tickets", "xp_books", "forge_stones"].has(String(key)):
					return "UNKNOWN_RESOURCE_KEY"
				if typeof(resources[key]) != TYPE_INT:
					return "RESOURCE_AMOUNT_MUST_BE_INT"
				if int(resources[key]) < 0:
					return "RESOURCE_AMOUNT_MUST_NOT_BE_NEGATIVE"
			return ""
		"recruit_hero":
			return _exact_keys(data, [], "recruit_hero")
		"settle_battle":
			var battle_error := _exact_keys(data, ["battle_id", "outcome", "ticks"], "settle_battle")
			if not battle_error.is_empty():
				return battle_error
			if typeof(data["battle_id"]) != TYPE_STRING or String(data["battle_id"]).is_empty():
				return "settle_battle.battle_id must be non-empty string"
			if typeof(data["outcome"]) != TYPE_STRING or not ["victory", "defeat", "timeout"].has(String(data["outcome"])):
				return "settle_battle.outcome must be victory, defeat, or timeout"
			if typeof(data["ticks"]) != TYPE_INT or int(data["ticks"]) <= 0 or int(data["ticks"]) > 300:
				return "settle_battle.ticks must be int 1..300"
			return ""
		"start_production":
			var start_error := _exact_keys(data, ["recipe_id", "now_unix"], "start_production")
			if not start_error.is_empty():
				return start_error
			if typeof(data["recipe_id"]) != TYPE_STRING or String(data["recipe_id"]).is_empty():
				return "start_production.recipe_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "start_production.now_unix must be non-negative int"
			return ""
		"claim_production":
			var claim_error := _exact_keys(data, ["order_id", "now_unix"], "claim_production")
			if not claim_error.is_empty():
				return claim_error
			if typeof(data["order_id"]) != TYPE_STRING or String(data["order_id"]).is_empty():
				return "claim_production.order_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_production.now_unix must be non-negative int"
			return ""
		"claim_ready_productions":
			var claim_ready_error := _exact_keys(data, ["now_unix"], "claim_ready_productions")
			if not claim_ready_error.is_empty():
				return claim_ready_error
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_ready_productions.now_unix must be non-negative int"
			return ""
		"merge_heroes":
			var merge_error := _exact_keys(data, ["hero_ids"], "merge_heroes")
			if not merge_error.is_empty():
				return merge_error
			if typeof(data["hero_ids"]) != TYPE_ARRAY or (data["hero_ids"] as Array).size() != 3:
				return "merge_heroes.hero_ids must contain exactly three entries"
			for hero_id in data["hero_ids"]:
				if typeof(hero_id) != TYPE_STRING or String(hero_id).is_empty():
					return "merge_heroes.hero_ids entries must be non-empty strings"
			return ""
		"train_hero":
			var train_error := _exact_keys(data, ["hero_id", "book_count"], "train_hero")
			if not train_error.is_empty():
				return train_error
			if typeof(data["hero_id"]) != TYPE_STRING:
				return "train_hero.hero_id must be string"
			if typeof(data["book_count"]) != TYPE_INT:
				return "train_hero.book_count must be int"
			if int(data["book_count"]) <= 0:
				return "train_hero.book_count must be positive"
			return ""
		"set_formation":
			var slots: Array[String] = ["front_left", "front_center", "front_right", "back_left", "back_center", "back_right"]
			var formation_error := _exact_keys(data, slots, "set_formation")
			if not formation_error.is_empty():
				return formation_error
			for slot in slots:
				if typeof(data[slot]) != TYPE_STRING:
					return "set_formation.%s must be string" % slot
			return ""
		"set_auto_skill_preference":
			var auto_error := _exact_keys(data, ["hero_id", "enabled"], "set_auto_skill_preference")
			if not auto_error.is_empty():
				return auto_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "set_auto_skill_preference.hero_id must be non-empty string"
			if typeof(data["enabled"]) != TYPE_BOOL:
				return "set_auto_skill_preference.enabled must be bool"
			return ""
		_:
			return "UNKNOWN_COMMAND"


func _exact_keys(data: Dictionary, expected: Array[String], label: String) -> String:
	var actual: Array[String] = []
	for key in data.keys():
		if typeof(key) != TYPE_STRING:
			return "%s keys must be strings" % label
		actual.append(String(key))
	actual.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	if actual != sorted_expected:
		return "%s payload keys mismatch" % label
	return ""

class_name AchievementService
extends RefCounted

const AchievementCatalogScript := preload("res://game/scripts/domain/achievement/achievement_catalog.gd")
const QuestCatalogScript := preload("res://game/scripts/domain/quest/quest_catalog.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")


static func refresh_achievements(state: RefCounted) -> Dictionary:
	var definition_errors := AchievementCatalogScript.validate_definitions()
	if not definition_errors.is_empty():
		return {"ok": false, "error": "ACHIEVEMENT_DEFINITION_INVALID: %s" % "; ".join(definition_errors)}
	_ensure_state(state)
	_backfill_reliable_counters(state)
	var completed_now := _evaluate_completions(state)
	return {"ok": true, "event": {"type": "achievements_refreshed", "completed_achievements": completed_now, "progress": (state.achievements["progress"] as Dictionary).duplicate(true)}}


static func apply_event(state: RefCounted, event: Dictionary, source_event_key: String = "") -> Array[String]:
	_ensure_state(state)
	if String(event.get("type", "")) == "achievements_refreshed":
		return []
	if not source_event_key.is_empty():
		var event_keys := state.achievements["event_keys"] as Dictionary
		if event_keys.has(source_event_key):
			return []
		event_keys[source_event_key] = true
	_apply_counter_event(state, event)
	return _evaluate_completions(state)


static func claim_achievement(state: RefCounted, achievement_id: String, generation: int, request_id: String) -> Dictionary:
	if request_id.is_empty():
		return {"ok": false, "error": "ACHIEVEMENT_REQUEST_ID_REQUIRED"}
	if achievement_id.is_empty():
		return {"ok": false, "error": "ACHIEVEMENT_ID_REQUIRED"}
	if generation != AchievementCatalogScript.MAX_GENERATION:
		return {"ok": false, "error": "ACHIEVEMENT_GENERATION_MISMATCH"}
	_ensure_state(state)
	var definition := AchievementCatalogScript.definition(achievement_id)
	if definition.is_empty():
		return {"ok": false, "error": "UNKNOWN_ACHIEVEMENT"}
	var durable := _durable_ledger(state)
	var fingerprint := _fingerprint({"kind": "claim_achievement", "achievement_id": achievement_id, "generation": generation})
	if durable.has(request_id):
		var old_receipt := durable[request_id] as Dictionary
		if String(old_receipt.get("fingerprint", "")) != fingerprint:
			return {"ok": false, "error": "ACHIEVEMENT_REQUEST_ID_REUSE_MISMATCH"}
		var replay_event := (old_receipt.get("event", {}) as Dictionary).duplicate(true)
		replay_event["idempotent"] = true
		return {"ok": true, "event": replay_event}
	var completed := state.achievements["completed"] as Dictionary
	var claimed := state.achievements["claimed"] as Dictionary
	if claimed.has(achievement_id):
		return {"ok": false, "error": "ACHIEVEMENT_ALREADY_CLAIMED"}
	if not completed.has(achievement_id):
		return {"ok": false, "error": "ACHIEVEMENT_NOT_COMPLETED"}
	var record := completed[achievement_id] as Dictionary
	var canonical_reward := (definition.get("reward", {}) as Dictionary).duplicate(true)
	if record.get("reward", {}) != canonical_reward:
		return {"ok": false, "error": "ACHIEVEMENT_REWARD_MISMATCH"}
	var reward_error := _validate_reward(canonical_reward)
	if not reward_error.is_empty():
		return {"ok": false, "error": reward_error}
	_grant_reward(state, canonical_reward)
	completed.erase(achievement_id)
	claimed[achievement_id] = {"achievement_id": achievement_id, "generation": generation, "request_id": request_id, "reward": canonical_reward.duplicate(true)}
	var event := {
		"type": "achievement_claimed",
		"achievement_id": achievement_id,
		"generation": generation,
		"request_id": request_id,
		"reward": canonical_reward.duplicate(true),
		"war_merit": _war_merit(state),
		"war_merit_rank": QuestCatalogScript.rank_for_merit(_war_merit(state)),
		"idempotent": false,
	}
	durable[request_id] = {"request_id": request_id, "fingerprint": fingerprint, "event": event.duplicate(true)}
	return {"ok": true, "event": event}


static func _ensure_state(state: RefCounted) -> void:
	var achievements_value: Variant = state.get("achievements")
	if typeof(achievements_value) != TYPE_DICTIONARY:
		state.set("achievements", {"progress": {}, "completed": {}, "claimed": {}, "event_keys": {}, "counters": {}})
	var achievements := state.get("achievements") as Dictionary
	for key in ["progress", "completed", "claimed", "event_keys", "counters"]:
		if not achievements.has(key) or typeof(achievements[key]) != TYPE_DICTIONARY:
			achievements[key] = {}
	state.set("achievements", achievements)


static func _backfill_reliable_counters(state: RefCounted) -> void:
	var counters := state.achievements["counters"] as Dictionary
	_set_counter(counters, "cleared_stages", (state.stage_progress.get("cleared_stages", []) as Array).size())
	var boss_count := 0
	var has_finale := 0
	for stage_id in state.stage_progress.get("cleared_stages", []):
		var config := StageCatalogScript.stage(String(stage_id))
		if int(config.get("stage_in_chapter", 0)) == StageCatalogScript.BOSS_STAGE_NUMBER:
			boss_count += 1
		if String(stage_id) == "stage_5_12":
			has_finale = 1
	_set_counter(counters, "boss_clears", boss_count)
	_set_counter(counters, "stage_5_12_cleared", has_finale)
	_set_counter(counters, "first_victory_salvage_earned", boss_count * 15 + (int(counters.get("cleared_stages", 0)) - boss_count) * 5)
	_set_counter(counters, "archetype_count", _archetype_count(state))
	_set_counter(counters, "max_hero_level", _max_hero_level(state))
	_set_counter(counters, "formation_level_3_count", _formation_level_count(state, 3))
	_set_counter(counters, "roster_star_2_count", _roster_star_count(state, 2))
	_set_counter(counters, "roster_star_3_count", _roster_star_count(state, 3))
	_set_counter(counters, "war_merit", _war_merit(state))
	_set_counter(counters, "war_merit_rank", QuestCatalogScript.rank_for_merit(_war_merit(state)))
	_backfill_from_receipts(state, counters)


static func _backfill_from_receipts(state: RefCounted, counters: Dictionary) -> void:
	var started := 0
	var claimed := 0
	var exchange_request_ids: Dictionary = {}
	var offer_ids := (counters.get("salvage_offer_ids", {}) as Dictionary).duplicate(true) if typeof(counters.get("salvage_offer_ids", {})) == TYPE_DICTIONARY else {}
	for command_id in state.command_receipts:
		var receipt: Dictionary = state.command_receipts[command_id] as Dictionary
		var result := (receipt as Dictionary).get("result", {}) as Dictionary
		var event := result.get("event", {}) as Dictionary
		match String(event.get("type", "")):
			"production_started":
				started += 1
			"production_claimed":
				claimed += 1
			"ready_productions_claimed":
				claimed += (event.get("claimed", []) as Array).size()
			"salvage_exchanged":
				exchange_request_ids[String(event.get("request_id", command_id))] = true
				offer_ids[String(event.get("offer_id", ""))] = true
	var durable := _durable_ledger(state)
	for ledger_key in durable:
		var receipt: Dictionary = durable[ledger_key] as Dictionary
		var data := receipt as Dictionary
		if String(data.get("kind", "")) == "exchange_salvage":
			exchange_request_ids[String(data.get("request_id", ledger_key))] = true
			offer_ids[String(data.get("offer_id", ""))] = true
	_set_counter(counters, "production_started", started)
	_set_counter(counters, "production_claimed", claimed)
	_set_counter(counters, "salvage_exchange_count", exchange_request_ids.size())
	counters["salvage_offer_ids"] = offer_ids
	_set_counter(counters, "salvage_offer_kinds", offer_ids.size())


static func _apply_counter_event(state: RefCounted, event: Dictionary) -> void:
	_backfill_reliable_counters(state)
	var counters := state.achievements["counters"] as Dictionary
	match String(event.get("type", "")):
		"production_started":
			_set_counter(counters, "production_started", int(counters.get("production_started", 0)) + 1)
		"production_claimed":
			_set_counter(counters, "production_claimed", int(counters.get("production_claimed", 0)) + 1)
		"ready_productions_claimed":
			_set_counter(counters, "production_claimed", int(counters.get("production_claimed", 0)) + (event.get("claimed", []) as Array).size())
		"salvage_exchanged":
			_set_counter(counters, "salvage_exchange_count", int(counters.get("salvage_exchange_count", 0)) + 1)
			var offer_ids := counters.get("salvage_offer_ids", {}) as Dictionary
			offer_ids[String(event.get("offer_id", ""))] = true
			counters["salvage_offer_ids"] = offer_ids
			_set_counter(counters, "salvage_offer_kinds", offer_ids.size())
		"quest_claimed", "achievement_claimed":
			_set_counter(counters, "war_merit", _war_merit(state))
			_set_counter(counters, "war_merit_rank", QuestCatalogScript.rank_for_merit(_war_merit(state)))


static func _evaluate_completions(state: RefCounted) -> Array[String]:
	_backfill_reliable_counters(state)
	var completed_now: Array[String] = []
	var completed := state.achievements["completed"] as Dictionary
	var claimed := state.achievements["claimed"] as Dictionary
	var progress := state.achievements["progress"] as Dictionary
	var counters := state.achievements["counters"] as Dictionary
	for definition in AchievementCatalogScript.all():
		var achievement_id := String(definition["achievement_id"])
		var metric := String(definition["metric"])
		var target := int(definition["target"])
		var value := mini(target, int(counters.get(metric, 0)))
		progress[achievement_id] = {"achievement_id": achievement_id, "generation": 0, "value": value, "target": target}
		if value >= target and not completed.has(achievement_id) and not claimed.has(achievement_id):
			completed[achievement_id] = {
				"achievement_id": achievement_id,
				"generation": 0,
				"metric": metric,
				"value": value,
				"target": target,
				"reward": (definition.get("reward", {}) as Dictionary).duplicate(true),
			}
			completed_now.append(achievement_id)
	return completed_now


static func _set_counter(counters: Dictionary, key: String, value: int) -> void:
	counters[key] = maxi(int(counters.get(key, 0)), value)


static func _grant_reward(state: RefCounted, reward: Dictionary) -> void:
	_ensure_inventory(state)
	var items := state.inventory["items"] as Dictionary
	items[QuestCatalogScript.WAR_MERIT_ITEM_ID] = int(items.get(QuestCatalogScript.WAR_MERIT_ITEM_ID, 0)) + int(reward.get("merit", 0))
	if int(reward.get("gold", 0)) > 0:
		state.economy.grant({"gold": int(reward["gold"])})
	if int(reward.get("xp_books", 0)) > 0:
		state.economy.grant({"xp_books": int(reward["xp_books"])})


static func _validate_reward(reward: Dictionary) -> String:
	for key in reward.keys():
		if typeof(key) != TYPE_STRING or not ["merit", "gold", "xp_books"].has(String(key)):
			return "ACHIEVEMENT_REWARD_UNKNOWN_KEY"
		if typeof(reward[key]) != TYPE_INT:
			return "ACHIEVEMENT_REWARD_AMOUNT_MUST_BE_INT"
		if int(reward[key]) < 0:
			return "ACHIEVEMENT_REWARD_AMOUNT_MUST_NOT_BE_NEGATIVE"
	return ""


static func _war_merit(state: RefCounted) -> int:
	_ensure_inventory(state)
	return int((state.inventory["items"] as Dictionary).get(QuestCatalogScript.WAR_MERIT_ITEM_ID, 0))


static func _ensure_inventory(state: RefCounted) -> void:
	if not state.inventory.has("items") or typeof(state.inventory["items"]) != TYPE_DICTIONARY:
		state.inventory["items"] = {}


static func _durable_ledger(state: RefCounted) -> Dictionary:
	if not state.receipt_ledgers.has("durable") or typeof(state.receipt_ledgers["durable"]) != TYPE_DICTIONARY:
		state.receipt_ledgers["durable"] = {}
	return state.receipt_ledgers["durable"] as Dictionary


static func _archetype_count(state: RefCounted) -> int:
	var seen: Dictionary = {}
	for hero in state.roster:
		seen[String(hero.archetype_id)] = true
	return seen.size()


static func _max_hero_level(state: RefCounted) -> int:
	var value := 0
	for hero in state.roster:
		value = maxi(value, int(hero.level))
	return value


static func _formation_level_count(state: RefCounted, min_level: int) -> int:
	var count := 0
	for hero_id in state.formation.hero_ids():
		var hero: RefCounted = state.hero_by_id(hero_id)
		if hero != null and int(hero.level) >= min_level:
			count += 1
	return count


static func _roster_star_count(state: RefCounted, min_star: int) -> int:
	var count := 0
	for hero in state.roster:
		if int(hero.star) >= min_star:
			count += 1
	return count


static func _fingerprint(payload: Variant) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(_canonical(payload).to_utf8_buffer())
	return ctx.finish().hex_encode()


static func _canonical(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if bool(value) else "false"
		TYPE_INT:
			return str(int(value))
		TYPE_STRING:
			return JSON.stringify(String(value))
		TYPE_ARRAY:
			var array_parts: Array[String] = []
			for item in value:
				array_parts.append(_canonical(item))
			return "[" + ",".join(array_parts) + "]"
		TYPE_DICTIONARY:
			var dict := value as Dictionary
			var keys: Array[String] = []
			for key in dict.keys():
				keys.append(String(key))
			keys.sort()
			var dict_parts: Array[String] = []
			for key in keys:
				dict_parts.append("%s:%s" % [JSON.stringify(key), _canonical(dict[key])])
			return "{" + ",".join(dict_parts) + "}"
		_:
			return JSON.stringify(str(value))

class_name QuestService
extends RefCounted

const QuestCatalogScript := preload("res://game/scripts/domain/quest/quest_catalog.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")


static func refresh_quests(state: RefCounted) -> Dictionary:
	var definition_errors := QuestCatalogScript.validate_definitions()
	if not definition_errors.is_empty():
		return {"ok": false, "error": "QUEST_DEFINITION_INVALID: %s" % "; ".join(definition_errors)}
	_ensure_quest_state(state)
	var completed_now: Array[String] = []
	for stage_id in state.stage_progress.get("cleared_stages", []):
		var quest_id := QuestCatalogScript.major_quest_id(String(stage_id))
		if not state.quests["completed"].has(quest_id) and not state.quests["claimed"].has(quest_id):
			state.quests["completed"][quest_id] = _completion_record(QuestCatalogScript.major_quest(String(stage_id)))
			completed_now.append(quest_id)
	return {"ok": true, "event": {"type": "quests_refreshed", "completed_quests": completed_now, "active_minor_quests": _active_minor_slots(state)}}


static func apply_event(state: RefCounted, event: Dictionary) -> Array[Dictionary]:
	_ensure_quest_state(state)
	var event_type := String(event.get("type", ""))
	if ["quests_refreshed", "quest_claimed"].has(event_type):
		return []
	var changes: Array[Dictionary] = []
	if event_type == "battle_settled" and String(event.get("outcome", "")) == "victory":
		var stage_id := String(event.get("stage_id", StageCatalogScript.DEFAULT_STAGE_ID))
		var major_id := QuestCatalogScript.major_quest_id(stage_id)
		if not state.quests["completed"].has(major_id) and not state.quests["claimed"].has(major_id):
			state.quests["completed"][major_id] = _completion_record(QuestCatalogScript.major_quest(stage_id))
			changes.append({"quest_id": major_id, "completed": true})
	var amount := _event_amount(event)
	if amount <= 0:
		return changes
	var slots := state.quests["active"].get("minor_slots", []) as Array
	for index in slots.size():
		var slot := slots[index] as Dictionary
		if _minor_matches(slot, event):
			var old_progress := int(slot.get("progress", 0))
			var target := int(slot.get("target", 1))
			slot["progress"] = mini(target, old_progress + amount)
			slots[index] = slot
			changes.append({"quest_id": String(slot.get("quest_id", "")), "progress": int(slot["progress"]), "target": target})
			if int(slot["progress"]) >= target and not state.quests["completed"].has(String(slot["quest_id"])):
				state.quests["completed"][String(slot["quest_id"])] = _completion_record(slot)
				changes.append({"quest_id": String(slot["quest_id"]), "completed": true})
	state.quests["active"]["minor_slots"] = slots
	return changes


static func claim_quest(state: RefCounted, quest_id: String, generation: int, request_id: String) -> Dictionary:
	if request_id.is_empty():
		return {"ok": false, "error": "QUEST_REQUEST_ID_REQUIRED"}
	if quest_id.is_empty():
		return {"ok": false, "error": "QUEST_ID_REQUIRED"}
	if generation < 0:
		return {"ok": false, "error": "QUEST_GENERATION_MUST_NOT_BE_NEGATIVE"}
	_ensure_quest_state(state)
	var completed := state.quests["completed"] as Dictionary
	var claimed := state.quests["claimed"] as Dictionary
	var durable := _durable_ledger(state)
	var fingerprint := _fingerprint({"kind": "claim_quest", "quest_id": quest_id, "generation": generation})
	if durable.has(request_id):
		var old_receipt := durable[request_id] as Dictionary
		if String(old_receipt.get("fingerprint", "")) != fingerprint:
			return {"ok": false, "error": "QUEST_REQUEST_ID_REUSE_MISMATCH"}
		var replay_event := (old_receipt.get("event", {}) as Dictionary).duplicate(true)
		replay_event["idempotent"] = true
		return {"ok": true, "event": replay_event}
	if claimed.has(quest_id):
		return {"ok": false, "error": "QUEST_ALREADY_CLAIMED"}
	if not completed.has(quest_id):
		return {"ok": false, "error": "QUEST_NOT_COMPLETED"}
	var record := completed[quest_id] as Dictionary
	if int(record.get("generation", -1)) != generation:
		return {"ok": false, "error": "QUEST_GENERATION_MISMATCH"}
	var reward := record.get("reward", {}) as Dictionary
	var reward_error := _validate_reward_instance(reward)
	if not reward_error.is_empty():
		return {"ok": false, "error": reward_error}
	var canonical_reward := _canonical_reward_for_record(quest_id, record)
	if canonical_reward.is_empty() or _canonical(reward) != _canonical(canonical_reward):
		return {"ok": false, "error": "QUEST_REWARD_DEFINITION_MISMATCH"}
	_grant_reward(state, canonical_reward)
	completed.erase(quest_id)
	claimed[quest_id] = {"quest_id": quest_id, "generation": generation, "request_id": request_id, "reward": canonical_reward.duplicate(true)}
	var replacement: Dictionary = {}
	if String(record.get("kind", "")) == "minor":
		replacement = _replace_minor_slot(state, int(record.get("slot", -1)), quest_id)
	var event := {
		"type": "quest_claimed",
		"quest_id": quest_id,
		"generation": generation,
		"request_id": request_id,
		"reward": canonical_reward.duplicate(true),
		"war_merit": _war_merit(state),
		"war_merit_rank": QuestCatalogScript.rank_for_merit(_war_merit(state)),
		"replacement_minor_quest": replacement,
		"idempotent": false,
	}
	var receipt := {"request_id": request_id, "fingerprint": fingerprint, "event": event.duplicate(true)}
	durable[request_id] = receipt
	return {"ok": true, "event": event}


static func _ensure_quest_state(state: RefCounted) -> void:
	if typeof(state.quests) != TYPE_DICTIONARY:
		state.quests = {}
	if not state.quests.has("active") or typeof(state.quests["active"]) != TYPE_DICTIONARY:
		state.quests["active"] = {}
	if not state.quests.has("completed") or typeof(state.quests["completed"]) != TYPE_DICTIONARY:
		state.quests["completed"] = {}
	if not state.quests.has("claimed") or typeof(state.quests["claimed"]) != TYPE_DICTIONARY:
		state.quests["claimed"] = {}
	var active := state.quests["active"] as Dictionary
	if not active.has("minor_generation") or typeof(active["minor_generation"]) != TYPE_INT:
		active["minor_generation"] = 0
	if not active.has("minor_slots") or typeof(active["minor_slots"]) != TYPE_ARRAY or (active["minor_slots"] as Array).size() != QuestCatalogScript.MINOR_SLOT_COUNT:
		var slots: Array[Dictionary] = []
		for slot in QuestCatalogScript.MINOR_SLOT_COUNT:
			slots.append(QuestCatalogScript.make_minor_slot(slot, int(active["minor_generation"])))
		active["minor_slots"] = slots


static func _active_minor_slots(state: RefCounted) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for slot in state.quests["active"].get("minor_slots", []):
		values.append((slot as Dictionary).duplicate(true))
	return values


static func _completion_record(definition: Dictionary) -> Dictionary:
	return {
		"quest_id": String(definition.get("quest_id", "")),
		"kind": String(definition.get("kind", "")),
		"slot": int(definition.get("slot", -1)),
		"generation": int(definition.get("generation", 0)),
		"stage_id": String(definition.get("stage_id", "")),
		"template_id": String(definition.get("template_id", "")),
		"reward": (definition.get("reward", {}) as Dictionary).duplicate(true),
	}


static func _canonical_reward_for_record(quest_id: String, record: Dictionary) -> Dictionary:
	var kind := String(record.get("kind", ""))
	if kind == "major" or quest_id.begins_with("major."):
		var stage_id := String(record.get("stage_id", ""))
		if stage_id.is_empty() and quest_id.begins_with("major."):
			stage_id = quest_id.trim_prefix("major.")
		var definition := QuestCatalogScript.major_quest(stage_id)
		if String(definition.get("quest_id", "")) != quest_id:
			return {}
		return (definition.get("reward", {}) as Dictionary).duplicate(true)
	if kind == "minor" or quest_id.begins_with("minor."):
		var definition := QuestCatalogScript.make_minor_slot(int(record.get("slot", -1)), int(record.get("generation", -1)))
		if String(definition.get("quest_id", "")) != quest_id:
			return {}
		return (definition.get("reward", {}) as Dictionary).duplicate(true)
	return {}


static func _minor_matches(slot: Dictionary, event: Dictionary) -> bool:
	if int(slot.get("progress", 0)) >= int(slot.get("target", 1)):
		return false
	var slot_event := String(slot.get("event_type", ""))
	var actual_event := String(event.get("type", ""))
	if slot_event == "production_claimed" and actual_event == "ready_productions_claimed":
		return true
	if slot_event != actual_event:
		return false
	var required_outcome := String(slot.get("outcome", ""))
	if not required_outcome.is_empty() and String(event.get("outcome", "")) != required_outcome:
		return false
	return true


static func _event_amount(event: Dictionary) -> int:
	if String(event.get("type", "")) == "ready_productions_claimed":
		return (event.get("claimed", []) as Array).size()
	return 1


static func _replace_minor_slot(state: RefCounted, slot: int, old_quest_id: String) -> Dictionary:
	if slot < 0:
		return {}
	var active := state.quests["active"] as Dictionary
	active["minor_generation"] = int(active.get("minor_generation", 0)) + 1
	var replacement := QuestCatalogScript.make_minor_slot(slot, int(active["minor_generation"]))
	var slots := active.get("minor_slots", []) as Array
	for index in slots.size():
		var entry := slots[index] as Dictionary
		if String(entry.get("quest_id", "")) == old_quest_id or int(entry.get("slot", -1)) == slot:
			slots[index] = replacement
			break
	active["minor_slots"] = slots
	return replacement.duplicate(true)


static func _grant_reward(state: RefCounted, reward: Dictionary) -> void:
	_ensure_inventory(state)
	var items := state.inventory["items"] as Dictionary
	items[QuestCatalogScript.WAR_MERIT_ITEM_ID] = int(items.get(QuestCatalogScript.WAR_MERIT_ITEM_ID, 0)) + int(reward.get("merit", 0))
	if int(reward.get("gold", 0)) > 0:
		state.economy.grant({"gold": int(reward["gold"])})
	if int(reward.get("xp_books", 0)) > 0:
		state.economy.grant({"xp_books": int(reward["xp_books"])})


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


static func _validate_reward_instance(reward: Dictionary) -> String:
	for key in reward.keys():
		if typeof(key) != TYPE_STRING or not ["merit", "gold", "xp_books"].has(String(key)):
			return "QUEST_REWARD_UNKNOWN_KEY"
		if typeof(reward[key]) != TYPE_INT:
			return "QUEST_REWARD_AMOUNT_MUST_BE_INT"
		if int(reward[key]) < 0:
			return "QUEST_REWARD_AMOUNT_MUST_NOT_BE_NEGATIVE"
	return ""


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

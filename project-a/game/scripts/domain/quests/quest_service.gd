class_name QuestService
extends RefCounted

const Catalog := preload("res://game/scripts/domain/quests/quest_catalog.gd")


static func create_default() -> Dictionary:
	var quests: Dictionary = {}
	var definitions: Dictionary = Catalog.definitions()
	for quest_id: String in definitions:
		var definition: Dictionary = definitions[quest_id]
		quests[quest_id] = {
			"category": definition["category"],
			"event_type": definition["event_type"],
			"target": definition["target"],
			"progress": 0,
			"terminal": false,
			"claimed": false,
			"consumed_event_ids": [],
		}
	return {"quests": quests}


static func claim_reward(quest_state: Dictionary, quest_id: String) -> Dictionary:
	var unchanged := quest_state.duplicate(true)
	var quests: Dictionary = quest_state.get("quests", {})
	var definitions: Dictionary = Catalog.definitions()
	if not quests.has(quest_id) or not definitions.has(quest_id):
		return _claim_failure("UNKNOWN_QUEST", unchanged)
	var quest: Dictionary = quests[quest_id]
	if bool(quest.get("claimed", false)):
		return _claim_failure("ALREADY_CLAIMED", unchanged)
	if not bool(quest.get("terminal", false)):
		return _claim_failure("QUEST_INCOMPLETE", unchanged)
	var updated := quest_state.duplicate(true)
	updated["quests"][quest_id]["claimed"] = true
	return {
		"ok": true,
		"code": "OK",
		"quest_state": updated,
		"reward": definitions[quest_id]["reward"].duplicate(true),
	}


static func can_start_stage(stage_id: String, _quest_state: Dictionary) -> bool:
	return not stage_id.is_empty()


static func _claim_failure(code: String, quest_state: Dictionary) -> Dictionary:
	return {"ok": false, "code": code, "quest_state": quest_state, "reward": {}}

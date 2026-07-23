class_name QuestCatalog
extends RefCounted


static func definitions() -> Dictionary:
	var result: Dictionary = {}
	var major_events: Array[String] = [
		"battle_won", "formation_changed", "item_equipped", "item_enhanced", "facility_upgraded",
	]
	for index: int in 5:
		var quest_id := "major-%02d" % (index + 1)
		result[quest_id] = _definition(quest_id, "major", major_events[index], 1, {
			"gold": 100 + index * 25,
		})
	var minor_events: Array[String] = [
		"battle_started", "battle_won", "hero_recruited", "hero_trained",
		"formation_changed", "item_dropped", "item_equipped", "item_enhanced",
		"facility_upgraded", "offline_settled", "gold_earned", "forge_stone_earned",
		"recruit_ticket_earned", "xp_book_earned", "stage_started", "stage_completed",
	]
	for index: int in 16:
		var quest_id := "minor-%02d" % (index + 1)
		result[quest_id] = _definition(quest_id, "minor", minor_events[index], 1, {
			"gold": 25,
		})
	return result


static func _definition(
	quest_id: String, category: String, event_type: String, target: int, reward: Dictionary
) -> Dictionary:
	return {
		"id": quest_id,
		"category": category,
		"event_type": event_type,
		"target": target,
		"reward": reward,
	}


class_name NotificationSummary
extends RefCounted


static func derive(state: RefCounted, now_unix: int) -> Dictionary:
	if state == null:
		return _empty()
	var factory_ready := 0
	if state.get("factory") != null:
		for order_value in state.factory.production_queue:
			if typeof(order_value) != TYPE_DICTIONARY:
				continue
			if int((order_value as Dictionary).get("completes_at_unix", 0)) <= now_unix:
				factory_ready += 1
	var quest_claimable := _unclaimed_count(state.get("quests"))
	var achievement_claimable := _unclaimed_count(state.get("achievements"))
	return {
		"factory_ready": factory_ready,
		"quest_claimable": quest_claimable,
		"achievement_claimable": achievement_claimable,
		"goal_claimable": quest_claimable + achievement_claimable,
		"total": factory_ready + quest_claimable + achievement_claimable,
	}


static func _unclaimed_count(bucket_value: Variant) -> int:
	if typeof(bucket_value) != TYPE_DICTIONARY:
		return 0
	var bucket := bucket_value as Dictionary
	var completed := bucket.get("completed", {}) as Dictionary
	var claimed := bucket.get("claimed", {}) as Dictionary
	var count := 0
	for item_id in completed:
		if not claimed.has(item_id):
			count += 1
	return count


static func _empty() -> Dictionary:
	return {
		"factory_ready": 0,
		"quest_claimable": 0,
		"achievement_claimable": 0,
		"goal_claimable": 0,
		"total": 0,
	}

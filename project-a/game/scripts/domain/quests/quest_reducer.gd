class_name QuestReducer
extends RefCounted


static func reduce(quest_state: Dictionary, events: Array) -> Dictionary:
	var result := quest_state.duplicate(true)
	var quests: Dictionary = result.get("quests", {})
	for event_variant: Variant in events:
		if not event_variant is Dictionary:
			continue
		var event: Dictionary = event_variant
		var event_id := str(event.get("event_id", ""))
		var event_type := str(event.get("type", ""))
		if event_id.is_empty() or event_type.is_empty():
			continue
		for quest_id: String in quests:
			var quest: Dictionary = quests[quest_id]
			if bool(quest.get("terminal", false)):
				continue
			if str(quest.get("event_type", "")) != event_type:
				continue
			var consumed: Array = quest.get("consumed_event_ids", [])
			if consumed.has(event_id):
				continue
			consumed.append(event_id)
			quest.consumed_event_ids = consumed
			var amount: int = maxi(0, int(event.get("amount", 1)))
			var target: int = maxi(0, int(quest.get("target", 0)))
			quest.progress = mini(
				target,
				maxi(0, int(quest.get("progress", 0))) + amount
			)
			if target > 0 and quest.progress >= target:
				quest.terminal = true
			quests[quest_id] = quest
	result.quests = quests
	return result

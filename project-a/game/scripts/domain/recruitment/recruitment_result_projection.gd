class_name RecruitmentResultProjection
extends RefCounted


const RECRUIT_COMMANDS: Array[String] = [
	"signal_recruit",
	"claim_faction_signal",
]


static func latest_results(state: RefCounted) -> Array[Dictionary]:
	var event := latest_event(state)
	var latest: Array[Dictionary] = []
	for value in event.get("results", []):
		if typeof(value) == TYPE_DICTIONARY:
			latest.append((value as Dictionary).duplicate(true))
	return latest


static func latest_event(state: RefCounted) -> Dictionary:
	return _latest_event(state, RECRUIT_COMMANDS)


static func latest_event_for_command(state: RefCounted, command_type: String) -> Dictionary:
	if command_type.is_empty():
		return {}
	var command_types: Array[String] = [command_type]
	return _latest_event(state, command_types)


static func _latest_event(state: RefCounted, command_types: Array[String]) -> Dictionary:
	var latest_revision := -1
	var latest: Dictionary = {}
	if state == null:
		return latest
	for receipt_value in state.command_receipts.values():
		if typeof(receipt_value) != TYPE_DICTIONARY:
			continue
		var receipt := receipt_value as Dictionary
		if not command_types.has(String(receipt.get("type", ""))):
			continue
		var result := receipt.get("result", {}) as Dictionary
		if not bool(result.get("ok", false)):
			continue
		var revision := int(result.get("state_revision", -1))
		var event := result.get("event", {}) as Dictionary
		var values := event.get("results", []) as Array
		if values.is_empty() or revision <= latest_revision:
			continue
		latest_revision = revision
		latest = event.duplicate(true)
	return latest

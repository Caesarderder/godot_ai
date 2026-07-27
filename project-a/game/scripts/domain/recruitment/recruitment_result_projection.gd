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


static func selected_faction_core(state: RefCounted) -> String:
	var selected := ""
	var latest_revision := -1
	if state == null:
		return selected
	for receipt_value in state.command_receipts.values():
		if typeof(receipt_value) != TYPE_DICTIONARY:
			continue
		var receipt := receipt_value as Dictionary
		if String(receipt.get("type", "")) != "choose_faction_core":
			continue
		var result := receipt.get("result", {}) as Dictionary
		if not bool(result.get("ok", false)):
			continue
		var revision := int(result.get("state_revision", -1))
		var event := result.get("event", {}) as Dictionary
		var archetype_id := String(event.get("archetype_id", ""))
		if not archetype_id.is_empty() and revision > latest_revision:
			selected = archetype_id
			latest_revision = revision
	if not selected.is_empty():
		return selected
	var faction_event := latest_event_for_command(state, "claim_faction_signal")
	# Saves created before explicit core choice keep their established faction.
	if not bool(faction_event.get("requires_core_choice", false)):
		return String(faction_event.get("guaranteed_duplicate_archetype", ""))
	return ""


static func faction_core_candidates(state: RefCounted) -> Array[String]:
	var candidates: Array[String] = []
	var event := latest_event_for_command(state, "claim_faction_signal")
	for value in event.get("faction_core_candidates", []):
		var archetype_id := String(value)
		if not archetype_id.is_empty() and not candidates.has(archetype_id):
			candidates.append(archetype_id)
	if candidates.is_empty():
		var legacy := String(event.get("guaranteed_duplicate_archetype", ""))
		if not legacy.is_empty():
			candidates.append(legacy)
	return candidates


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

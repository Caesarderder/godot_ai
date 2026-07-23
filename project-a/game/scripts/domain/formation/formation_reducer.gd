class_name FormationReducer
extends RefCounted


const SLOT_ORDER: Array[String] = ["front_1", "front_2", "back_1", "back_2"]


static func validate(slots: Dictionary, roster_ids: Array[String]) -> Dictionary:
	var errors: Array[String] = []
	var assigned: Array[String] = []
	for slot: String in SLOT_ORDER:
		var hero_id: String = str(slots.get(slot, ""))
		if hero_id.is_empty():
			errors.append("missing_slot:%s" % slot)
		elif not roster_ids.has(hero_id):
			errors.append("unknown_hero:%s" % hero_id)
		elif assigned.has(hero_id):
			errors.append("duplicate_hero:%s" % hero_id)
		else:
			assigned.append(hero_id)
	for key: Variant in slots.keys():
		if not SLOT_ORDER.has(str(key)):
			errors.append("unknown_slot:%s" % str(key))
	return {"valid": errors.is_empty(), "errors": errors}


static func set_formation(state: Dictionary, slots: Dictionary, roster_ids: Array[String]) -> Dictionary:
	var result: Dictionary = state.duplicate(true)
	if not bool(validate(slots, roster_ids).valid):
		return result
	result["slots"] = slots.duplicate(true)
	return result


static func reduce(state: Dictionary, command: Dictionary, roster_ids: Array[String]) -> Dictionary:
	if str(command.get("type", "")) != "set_formation":
		return state.duplicate(true)
	var slots_variant: Variant = command.get("slots", {})
	if not slots_variant is Dictionary:
		return state.duplicate(true)
	return set_formation(state, slots_variant, roster_ids)


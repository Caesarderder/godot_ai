class_name FormationService
extends RefCounted

const FormationStateScript := preload("res://game/scripts/state/formation_state.gd")


static func build_from_payload(payload: Dictionary) -> RefCounted:
	var formation := FormationStateScript.new()
	for slot in FormationStateScript.SLOTS:
		formation.slots[slot] = String(payload.get(slot, ""))
	return formation


static func assign_slot(state: RefCounted, slot: String, hero_id: String) -> Dictionary:
	if not FormationStateScript.ACTIVE_SLOTS.has(slot):
		return {"ok": false, "error": "FORMATION_SLOT_INVALID"}
	if state.hero_by_id(hero_id) == null:
		return {"ok": false, "error": "HERO_NOT_FOUND"}
	var current_id := String(state.formation.slots.get(slot, ""))
	if current_id == hero_id:
		return {"ok": false, "error": "HERO_ALREADY_IN_FORMATION_SLOT"}
	var previous_slot := ""
	for candidate_slot in FormationStateScript.ACTIVE_SLOTS:
		if String(state.formation.slots.get(candidate_slot, "")) == hero_id:
			previous_slot = candidate_slot
			break
	if not previous_slot.is_empty():
		state.formation.slots[previous_slot] = current_id
	state.formation.slots[slot] = hero_id
	var errors: Array[String] = state.formation.validate(state.roster_ids())
	if not errors.is_empty():
		return {"ok": false, "error": "INVALID_FORMATION: %s" % "; ".join(errors)}
	return {"ok": true, "event": {
		"type": "formation_slot_assigned",
		"slot": slot,
		"hero_id": hero_id,
		"replaced_hero_id": current_id,
		"swapped_from_slot": previous_slot,
	}}

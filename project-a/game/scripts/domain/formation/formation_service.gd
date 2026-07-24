class_name FormationService
extends RefCounted

const FormationStateScript := preload("res://game/scripts/state/formation_state.gd")


static func build_from_payload(payload: Dictionary) -> RefCounted:
	var formation := FormationStateScript.new()
	for slot in FormationStateScript.SLOTS:
		formation.slots[slot] = String(payload.get(slot, ""))
	return formation

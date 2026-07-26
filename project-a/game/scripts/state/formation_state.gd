class_name FormationState
extends RefCounted

const SLOTS: Array[String] = ["commander", "troop_1", "troop_2", "troop_3", "troop_4", "troop_5", "troop_6"]
const ACTIVE_SLOTS: Array[String] = ["commander", "troop_1", "troop_2", "troop_3", "troop_4", "troop_5"]
const TROOP_SLOTS: Array[String] = ["troop_1", "troop_2", "troop_3", "troop_4", "troop_5"]

var slots: Dictionary = {
	"commander": "",
	"troop_1": "",
	"troop_2": "",
	"troop_3": "",
	"troop_4": "",
	"troop_5": "",
	"troop_6": "",
}


static func from_heroes(hero_ids: Array[String]) -> FormationState:
	var formation := FormationState.new()
	for index in ACTIVE_SLOTS.size():
		formation.slots[ACTIVE_SLOTS[index]] = hero_ids[index] if index < hero_ids.size() else ""
	return formation


func deep_clone() -> FormationState:
	return FormationState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return slots.duplicate(true)


static func from_dict(data: Dictionary) -> FormationState:
	var formation := FormationState.new()
	for slot in ACTIVE_SLOTS:
		formation.slots[slot] = String(data.get(slot, ""))
	return formation


func hero_ids() -> Array[String]:
	var ids: Array[String] = []
	for slot in SLOTS:
		var hero_id := String(slots[slot])
		if not hero_id.is_empty():
			ids.append(hero_id)
	return ids


func validate(roster_ids: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	if not String(slots.get("troop_6", "")).is_empty():
		errors.append("formation supports at most six active units")
	var seen: Dictionary = {}
	for slot in SLOTS:
		var hero_id := String(slots.get(slot, ""))
		if hero_id.is_empty():
			continue
		if not roster_ids.has(hero_id):
			errors.append("%s references missing hero_id %s" % [slot, hero_id])
		elif seen.has(hero_id):
			errors.append("%s duplicates hero_id %s" % [slot, hero_id])
		seen[hero_id] = true
	return errors


func assign_next_troop(hero_id: String) -> bool:
	for slot in TROOP_SLOTS:
		if String(slots.get(slot, "")).is_empty():
			slots[slot] = hero_id
			return true
	return false

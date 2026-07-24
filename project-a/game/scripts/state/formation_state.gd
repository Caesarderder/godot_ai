class_name FormationState
extends RefCounted

const SLOTS: Array[String] = ["front_left", "front_center", "front_right", "back_left", "back_center", "back_right"]

var slots: Dictionary = {
	"front_left": "",
	"front_center": "",
	"front_right": "",
	"back_left": "",
	"back_center": "",
	"back_right": "",
}


static func from_heroes(hero_ids: Array[String]) -> FormationState:
	var formation := FormationState.new()
	for index in SLOTS.size():
		formation.slots[SLOTS[index]] = hero_ids[index] if index < hero_ids.size() else ""
	return formation


func deep_clone() -> FormationState:
	return FormationState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return slots.duplicate(true)


static func from_dict(data: Dictionary) -> FormationState:
	var formation := FormationState.new()
	for slot in SLOTS:
		formation.slots[slot] = String(data.get(slot, ""))
	return formation


func hero_ids() -> Array[String]:
	var ids: Array[String] = []
	for slot in SLOTS:
		ids.append(String(slots[slot]))
	return ids


func validate(roster_ids: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for slot in SLOTS:
		var hero_id := String(slots.get(slot, ""))
		if hero_id.is_empty():
			errors.append("%s requires a hero_id" % slot)
		elif not roster_ids.has(hero_id):
			errors.append("%s references missing hero_id %s" % [slot, hero_id])
		elif seen.has(hero_id):
			errors.append("%s duplicates hero_id %s" % [slot, hero_id])
		seen[hero_id] = true
	return errors

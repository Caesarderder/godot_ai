class_name CampService
extends RefCounted

const Definitions := preload("res://game/scripts/domain/camp/camp_definitions.gd")


static func create_default() -> Dictionary:
	var camp: Dictionary = {}
	for facility_id: String in Definitions.FACILITY_IDS:
		camp[facility_id] = {"level": 1}
	return camp


static func upgrade(camp: Dictionary, facility_id: String, gold: int) -> Dictionary:
	var unchanged := camp.duplicate(true)
	if not Definitions.FACILITY_IDS.has(facility_id) or not camp.has(facility_id):
		return _failure("UNKNOWN_FACILITY", unchanged, gold)
	var level := int(camp[facility_id].get("level", 1))
	if level >= Definitions.MAX_LEVEL:
		return _failure("MAX_LEVEL", unchanged, gold)
	var next_level := level + 1
	var cost := int(Definitions.UPGRADE_COSTS[next_level])
	if gold < cost:
		return _failure("INSUFFICIENT_GOLD", unchanged, gold)
	var upgraded := camp.duplicate(true)
	upgraded[facility_id]["level"] = next_level
	return {
		"ok": true,
		"code": "OK",
		"camp": upgraded,
		"gold": gold - cost,
		"spent": cost,
	}


static func _failure(code: String, camp: Dictionary, gold: int) -> Dictionary:
	return {"ok": false, "code": code, "camp": camp, "gold": gold, "spent": 0}


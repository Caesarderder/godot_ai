class_name EquipmentService
extends RefCounted

const EconomyService := preload("res://game/scripts/domain/progression/economy_service.gd")

const MAX_ENHANCEMENT: int = 5
const GOLD_COSTS: Array[int] = [80, 140, 220, 320, 460]
const FORGE_STONE_COSTS: Array[int] = [1, 2, 3, 4, 5]


static func equip(state: Dictionary, hero_id: String, item_id: String) -> Dictionary:
	var unchanged := state.duplicate(true)
	if not _items(state).has(item_id):
		return _failure("UNKNOWN_ITEM", unchanged)
	if not _roster(state).has(hero_id):
		return _failure("UNKNOWN_HERO", unchanged)
	if _is_equipped_by_another_hero(state, hero_id, item_id):
		return _failure("ITEM_ALREADY_EQUIPPED", unchanged)

	var item: Dictionary = _items(state)[item_id]
	var slot := String(item.get("slot", ""))
	if slot.is_empty():
		return _failure("UNKNOWN_SLOT", unchanged)
	var updated := state.duplicate(true)
	var hero: Dictionary = updated["roster"][hero_id]
	if not hero.has("equipment") or not (hero["equipment"] is Dictionary):
		hero["equipment"] = {}
	hero["equipment"][slot] = item_id
	return {
		"ok": true,
		"code": "OK",
		"state": updated,
		"events": [{"type": "item_equipped", "hero_id": hero_id, "item_id": item_id, "slot": slot}],
	}


static func unequip(state: Dictionary, hero_id: String, slot: String) -> Dictionary:
	var unchanged := state.duplicate(true)
	if not _roster(state).has(hero_id):
		return _failure("UNKNOWN_HERO", unchanged)
	var updated := state.duplicate(true)
	var equipment: Dictionary = updated["roster"][hero_id].get("equipment", {})
	equipment.erase(slot)
	updated["roster"][hero_id]["equipment"] = equipment
	return {
		"ok": true,
		"code": "OK",
		"state": updated,
		"events": [{"type": "item_unequipped", "hero_id": hero_id, "slot": slot}],
	}


static func enhance(state: Dictionary, item_id: String) -> Dictionary:
	var unchanged := state.duplicate(true)
	if not _items(state).has(item_id):
		return _failure("UNKNOWN_ITEM", unchanged)
	var item: Dictionary = _items(state)[item_id]
	var current_level := int(item.get("enhancement", 0))
	if current_level >= MAX_ENHANCEMENT:
		return _failure("MAX_ENHANCEMENT", unchanged)

	var cost := {
		"gold": -GOLD_COSTS[current_level],
		"forge_stones": -FORGE_STONE_COSTS[current_level],
	}
	var economy_result := EconomyService.apply_delta(state.get("economy", {}), cost)
	if not bool(economy_result.ok):
		return _failure("INSUFFICIENT_RESOURCES", unchanged)

	var updated := state.duplicate(true)
	updated["economy"] = economy_result.economy
	updated["inventory"]["items"][item_id]["enhancement"] = current_level + 1
	return {
		"ok": true,
		"code": "OK",
		"state": updated,
		"events": [{
			"type": "item_enhanced",
			"item_id": item_id,
			"enhancement": current_level + 1,
			"cost": {"gold": -cost.gold, "forge_stones": -cost.forge_stones},
		}],
	}


static func _items(state: Dictionary) -> Dictionary:
	var inventory: Dictionary = state.get("inventory", {})
	return inventory.get("items", {})


static func _roster(state: Dictionary) -> Dictionary:
	return state.get("roster", {})


static func _is_equipped_by_another_hero(state: Dictionary, hero_id: String, item_id: String) -> bool:
	for candidate_id: String in _roster(state):
		if candidate_id == hero_id:
			continue
		var equipment: Dictionary = _roster(state)[candidate_id].get("equipment", {})
		for slot: String in equipment:
			if String(equipment[slot]) == item_id:
				return true
	return false


static func _failure(code: String, state: Dictionary) -> Dictionary:
	return {"ok": false, "code": code, "state": state, "events": []}

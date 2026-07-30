class_name ItemShop
extends RefCounted

const CATALOG := {
	"pulse_lens": {"name": "Pulse Lens", "cost": 350, "attack": 12, "ability_power": 18},
	"wardens_plate": {"name": "Warden's Plate", "cost": 400, "health": 180, "armor": 16},
	"swift_coil": {"name": "Swift Coil", "cost": 300, "move_speed": 28, "cooldown": 6},
}

static func quote(item_id: String) -> Dictionary:
	return CATALOG.get(item_id, {}).duplicate(true)

static func buy(item_id: String, gold: int) -> Dictionary:
	var item := quote(item_id)
	if item.is_empty():
		return {"ok": false, "reason": "UNKNOWN_ITEM", "gold": gold}
	if gold < int(item.cost):
		return {"ok": false, "reason": "INSUFFICIENT_GOLD", "gold": gold}
	return {"ok": true, "gold": gold - int(item.cost), "item": item}

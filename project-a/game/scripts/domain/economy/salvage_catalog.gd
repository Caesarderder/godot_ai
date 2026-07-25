class_name SalvageCatalog
extends RefCounted

const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

const ITEM_ID: String = "alliance_scrap"

const OFFERS: Dictionary = {
	"porcelain_resupply": {
		"offer_id": "porcelain_resupply",
		"cost": 8,
		"grant": {"factory": {"porcelain": 40}, "economy": {}},
		"reason": "salvage_exchange_porcelain_resupply",
	},
	"mixed_parts": {
		"offer_id": "mixed_parts",
		"cost": 12,
		"grant": {"factory": {"parts": 28, "sludge": 20}, "economy": {}},
		"reason": "salvage_exchange_mixed_parts",
	},
	"training_cache": {
		"offer_id": "training_cache",
		"cost": 15,
		"grant": {"factory": {}, "economy": {"gold": 120, "xp_books": 2}},
		"reason": "salvage_exchange_training_cache",
	},
}


static func has_offer(offer_id: String) -> bool:
	return OFFERS.has(offer_id)


static func offer(offer_id: String) -> Dictionary:
	return (OFFERS.get(offer_id, {}) as Dictionary).duplicate(true)


static func stage_victory_salvage(stage_id: String) -> int:
	var config := StageCatalogScript.stage(stage_id)
	if config.is_empty():
		return 0
	return 15 if int(config.get("stage_in_chapter", 0)) == 5 else 5

class_name GoldShopCatalog
extends RefCounted

const OFFERS: Array[Dictionary] = [
	{
		"offer_id": "training_book",
		"display_name": "训练书补给",
		"description": "补齐下一次培养所需训练书。",
		"gold_cost": 90,
		"economy_grant": {"xp_books": 1},
		"factory_grant": {},
	},
	{
		"offer_id": "porcelain_crate",
		"display_name": "瓷片补给箱",
		"description": "用于普通与重装单位生产。",
		"gold_cost": 80,
		"economy_grant": {},
		"factory_grant": {"porcelain": 25},
	},
	{
		"offer_id": "parts_crate",
		"display_name": "机械零件箱",
		"description": "用于飞行、重装与特殊生产。",
		"gold_cost": 100,
		"economy_grant": {},
		"factory_grant": {"parts": 25},
	},
	{
		"offer_id": "sludge_crate",
		"display_name": "能量污泥箱",
		"description": "用于技能型和特殊单位生产。",
		"gold_cost": 100,
		"economy_grant": {},
		"factory_grant": {"sludge": 25},
	},
	{
		"offer_id": "mixed_factory_cache",
		"display_name": "工厂混合补给",
		"description": "均衡补充三类生产材料。",
		"gold_cost": 160,
		"economy_grant": {},
		"factory_grant": {"porcelain": 20, "parts": 12, "sludge": 12},
	},
]


static func all() -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for offer in OFFERS:
		values.append(offer.duplicate(true))
	return values


static func offer(offer_id: String) -> Dictionary:
	for value in OFFERS:
		if String(value["offer_id"]) == offer_id:
			return value.duplicate(true)
	return {}


static func has_offer(offer_id: String) -> bool:
	return not offer(offer_id).is_empty()


static func validate_definitions() -> Array[String]:
	var errors: Array[String] = []
	var seen := {}
	for value in OFFERS:
		var offer_id := String(value.get("offer_id", ""))
		if offer_id.is_empty() or seen.has(offer_id):
			errors.append("shop offer id must be unique and non-empty")
		seen[offer_id] = true
		if int(value.get("gold_cost", 0)) <= 0:
			errors.append("%s gold cost must be positive" % offer_id)
		var economy_grant := value.get("economy_grant", {}) as Dictionary
		for key in economy_grant:
			if not ["xp_books"].has(String(key)) or typeof(economy_grant[key]) != TYPE_INT or int(economy_grant[key]) <= 0:
				errors.append("%s has invalid economy grant" % offer_id)
		var factory_grant := value.get("factory_grant", {}) as Dictionary
		for key in factory_grant:
			if not ["porcelain", "parts", "sludge"].has(String(key)) or typeof(factory_grant[key]) != TYPE_INT or int(factory_grant[key]) <= 0:
				errors.append("%s has invalid factory grant" % offer_id)
		if economy_grant.is_empty() and factory_grant.is_empty():
			errors.append("%s must grant something" % offer_id)
	return errors

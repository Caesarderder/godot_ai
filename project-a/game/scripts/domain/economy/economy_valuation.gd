class_name EconomyValuation
extends RefCounted

## All values use milli-gold (1 gold = 1000) so the economy has one exact,
## integer pricing basis without relying on floating-point rounding.

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const MILLI_GOLD_PER_GOLD: int = 1000
const RESOURCE_VALUE_MILLI_GOLD: Dictionary = {
	"gold": 1000,
	"xp_books": 60000,
	"porcelain": 3200,
	"parts": 4000,
	"sludge": 4000,
	"salvage": 16000,
	# Merit is a progression score, not a spendable resource. Its value is
	# intentionally low and must not be used as a paid-currency exchange rate.
	"merit": 500,
}
const BLUEPRINT_RARITY_BP: Dictionary = {
	"common": 10000,
	"rare": 14000,
	"epic": 19000,
	"legendary": 26000,
}
const BLUEPRINT_BATCH_EQUIVALENT: int = 4
const RESEARCH_SECOND_VALUE_MILLI_GOLD: int = 2000


static func resource_value_milli_gold(resource_id: String) -> int:
	return int(RESOURCE_VALUE_MILLI_GOLD.get(resource_id, 0))


static func resource_value_gold(resource_id: String) -> int:
	return rounded_gold(resource_value_milli_gold(resource_id))


static func bundle_value_milli_gold(bundle: Dictionary) -> int:
	var total: int = 0
	for resource_value in bundle.keys():
		var resource_id := String(resource_value)
		total += int(bundle[resource_value]) * resource_value_milli_gold(resource_id)
	return total


static func bundle_value_gold(bundle: Dictionary) -> int:
	return rounded_gold(bundle_value_milli_gold(bundle))


static func recipe_cost_milli_gold(recipe_id: String) -> int:
	var recipe := FactoryCatalogScript.recipe(recipe_id)
	if recipe.is_empty():
		return 0
	return bundle_value_milli_gold(recipe.get("cost", {}) as Dictionary)


static func recipe_cost_gold(recipe_id: String) -> int:
	return rounded_gold(recipe_cost_milli_gold(recipe_id))


static func blueprint_value_milli_gold(recipe_id: String) -> int:
	var recipe := FactoryCatalogScript.recipe(recipe_id)
	if recipe.is_empty():
		return 0
	var rarity_bp := int(BLUEPRINT_RARITY_BP.get(String(recipe.get("rarity", "common")), 10000))
	var batch_value := recipe_cost_milli_gold(recipe_id) * BLUEPRINT_BATCH_EQUIVALENT
	var research_time_value := int(recipe.get("duration_seconds", 0)) * RESEARCH_SECOND_VALUE_MILLI_GOLD
	return int((batch_value + research_time_value) * rarity_bp / 10000)


static func blueprint_value_gold(recipe_id: String) -> int:
	return rounded_gold(blueprint_value_milli_gold(recipe_id))


static func rounded_gold(milli_gold: int) -> int:
	return int((maxi(0, milli_gold) + 500) / MILLI_GOLD_PER_GOLD)


static func audit_table() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for resource_id_value in RESOURCE_VALUE_MILLI_GOLD.keys():
		var resource_id := String(resource_id_value)
		rows.append({
			"kind": "resource",
			"id": resource_id,
			"value_milli_gold": resource_value_milli_gold(resource_id),
			"value_gold": resource_value_gold(resource_id),
		})
	for recipe in FactoryCatalogScript.recipes():
		var recipe_id := String(recipe["recipe_id"])
		rows.append({
			"kind": "blueprint",
			"id": recipe_id,
			"value_milli_gold": blueprint_value_milli_gold(recipe_id),
			"value_gold": blueprint_value_gold(recipe_id),
		})
	return rows

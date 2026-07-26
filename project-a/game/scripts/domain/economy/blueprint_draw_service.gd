class_name BlueprintDrawService
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const SINGLE_COST: int = 160
const TEN_COST: int = 1440
const S_PITY: int = 100
const S_RATE_BP: int = 50
const BLUEPRINT_RATE_BP: int = 650
const DEFAULT_POOL_ID: String = "standard_s"
const DEFAULT_TARGET_S: String = "special.parasite"
const MATERIAL_REWARDS: Array[Dictionary] = [
	{"porcelain": 24, "parts": 8, "sludge": 4},
	{"porcelain": 8, "parts": 24, "sludge": 6},
	{"porcelain": 6, "parts": 8, "sludge": 24},
	{"porcelain": 12, "parts": 12, "sludge": 12},
]
const NON_S_BLUEPRINTS: Array[String] = [
	"ordinary.assault", "flying.rocket", "heavy.armored", "special.repair",
]


static func draw(state: RefCounted, count: int, target_s_recipe_id: String = DEFAULT_TARGET_S, pool_id: String = DEFAULT_POOL_ID) -> Dictionary:
	if count != 1 and count != 10:
		return {"ok": false, "error": "DRAW_COUNT_MUST_BE_ONE_OR_TEN"}
	if not FactoryCatalogScript.has_recipe(target_s_recipe_id):
		return {"ok": false, "error": "TARGET_BLUEPRINT_NOT_FOUND"}
	if String(FactoryCatalogScript.recipe(target_s_recipe_id).get("rarity", "")) != "legendary":
		return {"ok": false, "error": "TARGET_BLUEPRINT_MUST_BE_S_RARITY"}
	var cost := SINGLE_COST if count == 1 else TEN_COST
	if state.economy.toilet_gems < cost:
		return {"ok": false, "error": "NOT_ENOUGH_TOILET_GEMS"}
	state.economy.toilet_gems -= cost
	state.pity["pool_id"] = pool_id
	state.pity["target_s_recipe_id"] = target_s_recipe_id
	var results: Array[Dictionary] = []
	for _index in count:
		results.append(_draw_once(state, target_s_recipe_id, pool_id))
	return {
		"ok": true,
		"event": {
			"type": "blueprint_draw_completed",
			"count": count,
			"cost": cost,
			"pool_id": pool_id,
			"target_s_recipe_id": target_s_recipe_id,
			"results": results,
			"s_pity_count": int(state.pity["s_pity_count"]),
		},
	}


static func _draw_once(state: RefCounted, target_s_recipe_id: String, pool_id: String) -> Dictionary:
	var draw_index := int(state.pity.get("blueprint_draw_count", 0)) + 1
	state.pity["blueprint_draw_count"] = draw_index
	var pity_count := int(state.pity.get("s_pity_count", 0)) + 1
	var roll := _stable_roll(state.run_seed, pool_id, draw_index, "rarity")
	if pity_count >= S_PITY or roll < S_RATE_BP:
		state.pity["s_pity_count"] = 0
		return _grant_blueprint(state, target_s_recipe_id, true)
	state.pity["s_pity_count"] = pity_count
	if roll < BLUEPRINT_RATE_BP:
		var recipe_id := NON_S_BLUEPRINTS[_stable_roll(state.run_seed, pool_id, draw_index, "blueprint") % NON_S_BLUEPRINTS.size()]
		return _grant_blueprint(state, recipe_id, false)
	var material_reward := MATERIAL_REWARDS[_stable_roll(state.run_seed, pool_id, draw_index, "material") % MATERIAL_REWARDS.size()].duplicate(true)
	state.factory.grant(material_reward)
	return {"kind": "materials", "materials": material_reward}


static func _grant_blueprint(state: RefCounted, recipe_id: String, is_s: bool) -> Dictionary:
	if bool(state.factory.blueprints.get(recipe_id, false)):
		var duplicate_data := 40 if is_s else 10
		state.factory.blueprint_data[recipe_id] = int(state.factory.blueprint_data.get(recipe_id, 0)) + duplicate_data
		return {"kind": "blueprint_data", "recipe_id": recipe_id, "amount": duplicate_data, "is_s": is_s}
	state.factory.blueprints[recipe_id] = true
	state.factory.model_tech_stars[recipe_id] = int(state.factory.model_tech_stars.get(recipe_id, 1))
	return {"kind": "complete_blueprint", "recipe_id": recipe_id, "is_s": is_s}


static func _stable_roll(run_seed: int, pool_id: String, draw_index: int, salt: String) -> int:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(("%d|%s|%d|%s" % [run_seed, pool_id, draw_index, salt]).to_utf8_buffer())
	var bytes := context.finish()
	return ((int(bytes[0]) << 8) + int(bytes[1])) % 10000

class_name SignalRecruitService
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const MetaCatalogScript := preload("res://game/scripts/domain/meta/meta_catalog.gd")

const S_RATE_BP: int = 200
const A_RATE_BP: int = 1800
const S_PITY: int = 60
const A_PITY: int = 10
const TARGET_S: String = "parasite"
const POOLS: Dictionary = {
	"B": ["assault", "rocket", "repair"],
	"A": ["sonic", "armored", "bomber"],
	"S": ["parasite", "saw"],
}
const DUPLICATE_DATA: Dictionary = {"B": 2, "A": 8, "S": 24}


static func recruit(state: RefCounted, count: int, target_archetype: String = TARGET_S) -> Dictionary:
	if not bool(MetaCatalogScript.unlocks(state)["recruitment"]):
		return {"ok": false, "error": "SIGNAL_RECRUIT_LOCKED"}
	if count != 1 and count != 10:
		return {"ok": false, "error": "RECRUIT_COUNT_MUST_BE_ONE_OR_TEN"}
	if state.economy.recruit_tickets < count:
		return {"ok": false, "error": "NOT_ENOUGH_RECRUIT_TICKETS"}
	if not (POOLS["S"] as Array).has(target_archetype):
		return {"ok": false, "error": "RECRUIT_TARGET_INVALID"}
	state.economy.recruit_tickets -= count
	var results: Array[Dictionary] = []
	for _index in count:
		results.append(_draw_once(state, target_archetype))
	return {
		"ok": true,
		"event": {
			"type": "signal_recruit_resolved",
			"count": count,
			"target_archetype": target_archetype,
			"results": results,
			"s_pity": state.meta_progression.recruit_s_pity,
			"a_pity": state.meta_progression.recruit_a_pity,
			"target_guaranteed": state.meta_progression.recruit_target_guaranteed,
		},
	}


static func _draw_once(state: RefCounted, target_archetype: String) -> Dictionary:
	var meta: RefCounted = state.meta_progression
	meta.recruit_draw_count += 1
	meta.recruit_s_pity += 1
	meta.recruit_a_pity += 1
	var rarity_roll := _stable_roll(state.run_seed, meta.recruit_pool_id, meta.recruit_draw_count, "rarity")
	var rarity := "B"
	if meta.recruit_s_pity >= S_PITY or rarity_roll < S_RATE_BP:
		rarity = "S"
	elif meta.recruit_a_pity >= A_PITY or rarity_roll < S_RATE_BP + A_RATE_BP:
		rarity = "A"
	if rarity == "S":
		meta.recruit_s_pity = 0
		meta.recruit_a_pity = 0
	elif rarity == "A":
		meta.recruit_a_pity = 0
	var archetype_id := _pick_archetype(state, rarity, target_archetype)
	var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
	return grant_design(state, String(recipe.get("recipe_id", "")), rarity, int(DUPLICATE_DATA[rarity]))


static func _pick_archetype(state: RefCounted, rarity: String, target_archetype: String) -> String:
	var meta: RefCounted = state.meta_progression
	if rarity == "S":
		if meta.recruit_target_guaranteed:
			meta.recruit_target_guaranteed = false
			return target_archetype
		var target_roll := _stable_roll(state.run_seed, meta.recruit_pool_id, meta.recruit_draw_count, "target")
		if target_roll < 5000:
			return target_archetype
		meta.recruit_target_guaranteed = true
		var off_targets: Array = (POOLS["S"] as Array).filter(func(value: Variant) -> bool: return String(value) != target_archetype)
		return String(off_targets[_stable_roll(state.run_seed, meta.recruit_pool_id, meta.recruit_draw_count, "pick") % off_targets.size()])
	var values := POOLS[rarity] as Array
	return String(values[_stable_roll(state.run_seed, meta.recruit_pool_id, meta.recruit_draw_count, "pick") % values.size()])


static func grant_design(
	state: RefCounted,
	recipe_id: String,
	rarity: String,
	duplicate_data_amount: int
) -> Dictionary:
	var recipe := FactoryCatalogScript.recipe(recipe_id)
	var archetype_id := String(recipe.get("archetype_id", ""))
	if recipe.is_empty():
		return {"rarity": rarity, "kind": "invalid_blueprint", "recipe_id": recipe_id}
	if (
		bool(state.factory.discovered_blueprints.get(recipe_id, false))
		or bool(state.factory.blueprints.get(recipe_id, false))
	):
		state.economy.hero_shards += duplicate_data_amount
		return {
			"rarity": rarity,
			"archetype_id": archetype_id,
			"recipe_id": recipe_id,
			"kind": "legion_data",
			"amount": duplicate_data_amount,
		}
	state.factory.discovered_blueprints[recipe_id] = true
	return {
		"rarity": rarity,
		"archetype_id": archetype_id,
		"recipe_id": recipe_id,
		"kind": "blueprint",
	}


static func _stable_roll(run_seed: int, pool_id: String, draw_index: int, salt: String) -> int:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(("%d|%s|%d|%s" % [run_seed, pool_id, draw_index, salt]).to_utf8_buffer())
	var bytes := context.finish()
	return ((int(bytes[0]) << 8) + int(bytes[1])) % 10000

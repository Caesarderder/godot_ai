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
	"B": ["assault", "rocket", "repair", "anchor_bastion", "phase_tunneler", "ram_breaker", "mortar", "bulwark", "swarm_beacon"],
	"A": ["sonic", "armored", "bomber", "signal_purifier", "magnetic_conductor", "smoke_screen", "interceptor", "crusher", "drain_engine"],
	"S": ["parasite", "saw", "protocol_weaver", "echo_mimic", "chronolock"],
}
const FACTION_CORE_POOLS: Dictionary = {
	"B": ["assault", "rocket", "repair"],
	"A": ["sonic", "armored", "bomber"],
}
const DUPLICATE_FRAGMENTS: Dictionary = {"B": 20, "A": 30, "S": 40}
# Compatibility alias for authored onboarding cards. The value now means
# archetype-specific fragments, never shared legion data.
const DUPLICATE_DATA: Dictionary = DUPLICATE_FRAGMENTS


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


static func recruit_free_faction_ten(
	state: RefCounted,
	target_archetype: String = TARGET_S
) -> Dictionary:
	if not bool(MetaCatalogScript.unlocks(state)["recruitment"]):
		return {"ok": false, "error": "SIGNAL_RECRUIT_LOCKED"}
	if not (POOLS["S"] as Array).has(target_archetype):
		return {"ok": false, "error": "RECRUIT_TARGET_INVALID"}
	var results: Array[Dictionary] = []
	var candidate_rarity := _faction_core_rarity(state)
	var first_candidate := _draw_forced_new_design(state, [], candidate_rarity)
	results.append(first_candidate)
	var second_candidate := _draw_forced_new_design(
		state,
		[String(first_candidate.get("archetype_id", ""))],
		candidate_rarity
	)
	results.append(second_candidate)
	results.append(_draw_guaranteed_duplicate(state, first_candidate, target_archetype))
	results.append(_draw_guaranteed_duplicate(state, second_candidate, target_archetype))
	for _index in 5:
		results.append(_draw_once(state, target_archetype))
	results.append(_draw_forced_minimum_a(state, target_archetype))
	var core_candidates: Array[String] = [
		String(first_candidate.get("archetype_id", "")),
		String(second_candidate.get("archetype_id", "")),
	]
	return {
		"ok": true,
		"event": {
			"type": "foundational_signal_resolved",
			"count": 10,
			"target_archetype": target_archetype,
			"results": results,
			"s_pity": state.meta_progression.recruit_s_pity,
			"a_pity": state.meta_progression.recruit_a_pity,
			"target_guaranteed": state.meta_progression.recruit_target_guaranteed,
			"guaranteed_duplicate_archetype": core_candidates[0],
			"faction_core_candidates": core_candidates,
			"faction_core_rating": candidate_rarity,
			"requires_core_choice": true,
			"pity_advanced": true,
		},
	}


static func _draw_forced_new_design(
	state: RefCounted,
	excluded_archetypes: Array[String],
	rarity: String
) -> Dictionary:
	var available: Array[Dictionary] = []
	for archetype_value in FACTION_CORE_POOLS.get(rarity, POOLS[rarity]):
		var archetype_id := String(archetype_value)
		if excluded_archetypes.has(archetype_id):
			continue
		var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
		var recipe_id := String(recipe.get("recipe_id", ""))
		if (
			not bool(state.factory.discovered_blueprints.get(recipe_id, false))
			and not bool(state.factory.blueprints.get(recipe_id, false))
		):
			available.append({
				"archetype_id": archetype_id,
				"recipe_id": recipe_id,
				"rarity": rarity,
			})
	if available.is_empty():
		var core_pool := FACTION_CORE_POOLS.get(rarity, POOLS[rarity]) as Array
		var fallback_archetype := String(core_pool[0])
		for archetype_value in core_pool:
			var archetype_id := String(archetype_value)
			if not excluded_archetypes.has(archetype_id):
				fallback_archetype = archetype_id
				break
		var fallback_recipe := FactoryCatalogScript.recipe_for_archetype(fallback_archetype)
		available.append({
			"archetype_id": fallback_archetype,
			"recipe_id": String(fallback_recipe.get("recipe_id", "")),
			"rarity": rarity,
		})
	var meta: RefCounted = state.meta_progression
	meta.recruit_draw_count += 1
	meta.recruit_s_pity += 1
	meta.recruit_a_pity += 1
	var pick_index := _stable_roll(
		state.run_seed,
		meta.recruit_pool_id,
		meta.recruit_draw_count,
		"faction-core-choice"
	) % available.size()
	var selected := available[pick_index]
	var selected_rarity := String(selected.get("rarity", "B"))
	if selected_rarity == "S":
		meta.recruit_s_pity = 0
		meta.recruit_a_pity = 0
	elif selected_rarity == "A":
		meta.recruit_a_pity = 0
	return grant_design(
		state,
		String(selected.get("recipe_id", "")),
		selected_rarity,
		int(DUPLICATE_FRAGMENTS.get(selected_rarity, 20))
	)


static func _faction_core_rarity(state: RefCounted) -> String:
	var preferred := (
		"A"
		if _stable_roll(
			state.run_seed,
			state.meta_progression.recruit_pool_id,
			state.meta_progression.recruit_draw_count,
			"faction-core-rating"
		) % 2 == 0
		else "B"
	)
	if _new_design_count(state, preferred) >= 2:
		return preferred
	var alternative := "B" if preferred == "A" else "A"
	if _new_design_count(state, alternative) >= 2:
		return alternative
	return preferred


static func _new_design_count(state: RefCounted, rarity: String) -> int:
	var count := 0
	for archetype_value in FACTION_CORE_POOLS.get(rarity, POOLS[rarity]):
		var recipe := FactoryCatalogScript.recipe_for_archetype(String(archetype_value))
		var recipe_id := String(recipe.get("recipe_id", ""))
		if (
			not bool(state.factory.discovered_blueprints.get(recipe_id, false))
			and not bool(state.factory.blueprints.get(recipe_id, false))
		):
			count += 1
	return count


static func _draw_guaranteed_duplicate(
	state: RefCounted,
	duplicate_source: Dictionary,
	target_archetype: String
) -> Dictionary:
	var meta: RefCounted = state.meta_progression
	meta.recruit_draw_count += 1
	meta.recruit_s_pity += 1
	meta.recruit_a_pity += 1
	var duplicate_rarity := String(duplicate_source.get("rarity", "B"))
	var duplicate_result := grant_design(
		state,
		String(duplicate_source.get("recipe_id", "")),
		duplicate_rarity,
		int(DUPLICATE_FRAGMENTS.get(duplicate_rarity, 20))
	)
	# The tenth response advances the same hard pity as every ticket draw. If it
	# reaches 60, preserve the promised matching fragments and attach the S pity
	# result to this response instead of silently delaying the guarantee.
	if meta.recruit_s_pity >= S_PITY:
		meta.recruit_s_pity = 0
		meta.recruit_a_pity = 0
		var s_archetype := _pick_archetype(state, "S", target_archetype)
		var s_recipe := FactoryCatalogScript.recipe_for_archetype(s_archetype)
		duplicate_result["pity_bonus"] = grant_design(
			state,
			String(s_recipe.get("recipe_id", "")),
			"S",
			int(DUPLICATE_FRAGMENTS["S"])
		)
	return duplicate_result


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
	return grant_design(state, String(recipe.get("recipe_id", "")), rarity, int(DUPLICATE_FRAGMENTS[rarity]))


static func _draw_forced_rarity(
	state: RefCounted,
	rarity: String,
	target_archetype: String
) -> Dictionary:
	var meta: RefCounted = state.meta_progression
	meta.recruit_draw_count += 1
	meta.recruit_s_pity += 1
	meta.recruit_a_pity += 1
	if rarity == "S":
		meta.recruit_s_pity = 0
		meta.recruit_a_pity = 0
	elif rarity == "A":
		meta.recruit_a_pity = 0
	var archetype_id := _pick_archetype(state, rarity, target_archetype)
	var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
	return grant_design(
		state,
		String(recipe.get("recipe_id", "")),
		rarity,
		int(DUPLICATE_FRAGMENTS[rarity])
	)


static func _draw_forced_minimum_a(state: RefCounted, target_archetype: String) -> Dictionary:
	if int(state.meta_progression.recruit_s_pity) + 1 >= S_PITY:
		return _draw_forced_rarity(state, "S", target_archetype)
	return _draw_forced_rarity(state, "A", target_archetype)


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
		var fragments := state.meta_progression.hero_fragments as Dictionary
		fragments[archetype_id] = int(fragments.get(archetype_id, 0)) + duplicate_data_amount
		return {
			"rarity": rarity,
			"archetype_id": archetype_id,
			"recipe_id": recipe_id,
			"kind": "hero_fragments",
			"amount": duplicate_data_amount,
			"balance": int(fragments[archetype_id]),
		}
	state.factory.discovered_blueprints[recipe_id] = true
	return {
		"rarity": rarity,
		"archetype_id": archetype_id,
		"recipe_id": recipe_id,
		"kind": "blueprint",
	}


static func _stable_roll(run_seed: int, pool_id: String, draw_index: int, salt: String) -> int:
	var nonce := 0
	while true:
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(
			("%d|%s|%d|%s|%d" % [run_seed, pool_id, draw_index, salt, nonce]).to_utf8_buffer()
		)
		var bytes := context.finish()
		var value := (
			(int(bytes[0]) << 24)
			| (int(bytes[1]) << 16)
			| (int(bytes[2]) << 8)
			| int(bytes[3])
		)
		# Largest multiple of 10_000 below 2^32. Rejection sampling keeps
		# the published basis-point weights exact.
		if value < 4_294_960_000:
			return value % 10000
		nonce += 1
	return 0

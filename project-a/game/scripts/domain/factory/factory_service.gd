class_name FactoryService
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const DEBUG_RESEARCH_SECONDS: int = 5


static func start_production(state: RefCounted, recipe_id: String, now_unix: int) -> Dictionary:
	var recipe := FactoryCatalogScript.recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "error": "RECIPE_NOT_FOUND"}
	if not bool(state.factory.blueprints.get(recipe_id, false)):
		return {"ok": false, "error": "BLUEPRINT_LOCKED"}
	if state.factory.production_queue.size() >= 3:
		return {"ok": false, "error": "PRODUCTION_QUEUE_FULL"}
	var cost := recipe["cost"] as Dictionary
	if not state.factory.can_spend(cost):
		return {"ok": false, "error": "NOT_ENOUGH_FACTORY_MATERIALS"}
	state.factory.spend(cost)
	var sequence: int = state.factory.next_sequence
	state.factory.next_sequence += 1
	var order_id := "production_%06d" % sequence
	var completes_at_unix := now_unix + int(recipe["duration_seconds"])
	state.factory.production_queue.append({
		"order_id": order_id,
		"recipe_id": recipe_id,
		"started_at_unix": now_unix,
		"completes_at_unix": completes_at_unix,
	})
	return {
		"ok": true,
		"event": {
			"type": "production_started",
			"order_id": order_id,
			"recipe_id": recipe_id,
			"completes_at_unix": completes_at_unix,
		},
	}


static func start_blueprint_research(state: RefCounted, recipe_id: String, now_unix: int) -> Dictionary:
	if not FactoryCatalogScript.has_recipe(recipe_id):
		return {"ok": false, "error": "RECIPE_NOT_FOUND"}
	if bool(state.factory.blueprints.get(recipe_id, false)):
		return {"ok": false, "error": "BLUEPRINT_ALREADY_RESEARCHED"}
	if not bool(state.factory.discovered_blueprints.get(recipe_id, false)):
		return {"ok": false, "error": "BLUEPRINT_NOT_DISCOVERED"}
	if not state.factory.blueprint_research.is_empty():
		return {"ok": false, "error": "BLUEPRINT_RESEARCH_BUSY"}
	var completes_at_unix := now_unix + DEBUG_RESEARCH_SECONDS
	state.factory.blueprint_research = {
		"recipe_id": recipe_id,
		"started_at_unix": now_unix,
		"completes_at_unix": completes_at_unix,
	}
	return {
		"ok": true,
		"event": {
			"type": "blueprint_research_started",
			"recipe_id": recipe_id,
			"completes_at_unix": completes_at_unix,
		},
	}


static func claim_blueprint_research(state: RefCounted, now_unix: int) -> Dictionary:
	if state.factory.blueprint_research.is_empty():
		return {"ok": false, "error": "NO_BLUEPRINT_RESEARCH"}
	if now_unix < blueprint_research_completes_at(state.factory.blueprint_research):
		return {"ok": false, "error": "BLUEPRINT_RESEARCH_NOT_READY"}
	var recipe_id := String(state.factory.blueprint_research.get("recipe_id", ""))
	state.factory.blueprints[recipe_id] = true
	state.factory.discovered_blueprints.erase(recipe_id)
	state.factory.blueprint_research = {}
	return {
		"ok": true,
		"event": {
			"type": "blueprint_research_claimed",
			"recipe_id": recipe_id,
		},
	}


static func claim_production(state: RefCounted, order_id: String, now_unix: int) -> Dictionary:
	var order_index := -1
	for index in state.factory.production_queue.size():
		if String(state.factory.production_queue[index]["order_id"]) == order_id:
			order_index = index
			break
	if order_index < 0:
		return {"ok": false, "error": "PRODUCTION_ORDER_NOT_FOUND"}
	var order := state.factory.production_queue[order_index] as Dictionary
	if now_unix < int(order["completes_at_unix"]):
		return {"ok": false, "error": "PRODUCTION_NOT_READY"}
	var recipe_id := String(order["recipe_id"])
	var recipe := FactoryCatalogScript.recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "error": "RECIPE_NOT_FOUND"}
	var hero: RefCounted = HeroGenerator.generate_archetype(
		state.run_seed,
		state.allocate_hero_index(),
		String(recipe["archetype_id"]),
		String(recipe["class_id"])
	)
	hero.star = int(state.factory.model_tech_stars.get(recipe_id, 1))
	hero.level = 1
	hero.xp = 0
	state.roster.append(hero)
	state.factory.production_queue.remove_at(order_index)
	return {
		"ok": true,
		"event": {
			"type": "production_claimed",
			"order_id": order_id,
			"recipe_id": recipe_id,
			"hero_id": hero.hero_id,
			"unit_id": hero.hero_id,
		},
	}


static func claim_ready_productions(state: RefCounted, now_unix: int) -> Dictionary:
	var ready_order_ids: Array[String] = []
	for order in state.factory.production_queue:
		if now_unix >= int(order.get("completes_at_unix", 0)):
			ready_order_ids.append(String(order.get("order_id", "")))
	if ready_order_ids.is_empty():
		return {"ok": false, "error": "NO_READY_PRODUCTIONS"}
	var claimed: Array[Dictionary] = []
	for order_id in ready_order_ids:
		var result := claim_production(state, order_id, now_unix)
		if not bool(result.get("ok", false)):
			return result
		claimed.append((result["event"] as Dictionary).duplicate(true))
	return {
		"ok": true,
		"event": {
			"type": "ready_productions_claimed",
			"claimed": claimed,
		},
	}


static func ready_orders(state: RefCounted, now_unix: int) -> Array[Dictionary]:
	var ready: Array[Dictionary] = []
	for order in state.factory.production_queue:
		var entry := order as Dictionary
		if now_unix >= int(entry.get("completes_at_unix", 0)):
			ready.append(entry.duplicate(true))
	return ready


static func offline_summary(state: RefCounted, now_unix: int) -> Dictionary:
	var ready := ready_orders(state, now_unix)
	var next_ready_unix := 0
	for order in state.factory.production_queue:
		var completes_at_unix := int((order as Dictionary).get("completes_at_unix", 0))
		if completes_at_unix > now_unix and (next_ready_unix == 0 or completes_at_unix < next_ready_unix):
			next_ready_unix = completes_at_unix
	return {
		"now_unix": now_unix,
		"ready_count": ready.size(),
		"ready_order_ids": ready.map(func(order: Dictionary) -> String: return String(order["order_id"])),
		"next_ready_unix": next_ready_unix,
	}


static func apply_battle_unlocks(state: RefCounted, outcome: String, attempt_count: int, stage_id: String = StageCatalogScript.DEFAULT_STAGE_ID) -> Array[String]:
	var unlocked: Array[String] = []
	if (
		outcome == "victory"
		and stage_id == "stage_2_12"
		and not bool(state.factory.eligible_facilities.get("coin_mint", false))
	):
		state.factory.eligible_facilities["coin_mint"] = true
		unlocked.append("coin_mint")
	return unlocked


static func unlock_foundational_blueprint(
	state: RefCounted,
	recipe_id: String = FactoryStateScript.FOUNDATIONAL_BLUEPRINT_ID,
	now_unix: int = 0
) -> Dictionary:
	if int(state.factory.facilities.get("research_lab", 0)) <= 0:
		return {"ok": false, "error": "RESEARCH_LAB_LOCKED"}
	if not FactoryCatalogScript.has_recipe(recipe_id):
		return {"ok": false, "error": "RECIPE_NOT_FOUND"}
	if not bool(state.factory.discovered_blueprints.get(recipe_id, false)):
		return {"ok": false, "error": "BLUEPRINT_NOT_DISCOVERED"}
	if bool(state.factory.blueprints.get(recipe_id, false)):
		return {"ok": false, "error": "BLUEPRINT_ALREADY_RESEARCHED"}
	if not state.factory.blueprint_research.is_empty():
		return {"ok": false, "error": "BLUEPRINT_RESEARCH_BUSY"}
	var completes_at_unix := now_unix + DEBUG_RESEARCH_SECONDS
	state.factory.blueprint_research = {
		"recipe_id": recipe_id,
		"started_at_unix": now_unix,
		"completes_at_unix": completes_at_unix,
	}
	return {"ok": true, "event": {
		"type": "blueprint_research_started",
		"recipe_id": recipe_id,
		"completes_at_unix": completes_at_unix,
	}}


static func claim_foundational_blueprint(state: RefCounted, now_unix: int) -> Dictionary:
	if state.factory.blueprint_research.is_empty():
		return {"ok": false, "error": "NO_BLUEPRINT_RESEARCH"}
	if now_unix < blueprint_research_completes_at(state.factory.blueprint_research):
		return {"ok": false, "error": "BLUEPRINT_RESEARCH_NOT_READY"}
	var recipe_id := String(state.factory.blueprint_research.get("recipe_id", ""))
	var recipe := FactoryCatalogScript.recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "error": "RECIPE_NOT_FOUND"}
	state.factory.blueprint_research = {}
	state.factory.blueprints[recipe_id] = true
	state.factory.discovered_blueprints.erase(recipe_id)
	state.factory.model_tech_stars[recipe_id] = 1
	var hero: RefCounted = _hero_for_archetype(state, String(recipe["archetype_id"]))
	var newly_researched := hero == null
	if newly_researched:
		var hero_index: int = state.allocate_hero_index()
		hero = HeroGenerator.generate_archetype(
			state.run_seed,
			hero_index,
			String(recipe["archetype_id"]),
			String(recipe["class_id"])
		)
		hero.aptitude_id = String(recipe.get("rating", "B"))
		hero.display_name = String(recipe["display_name"])
		state.roster.append(hero)
	if FactoryStateScript.FOUNDATIONAL_BLUEPRINT_IDS.has(recipe_id):
		var tutorial_fragments := 20 if String(recipe.get("rating", "B")) == "B" else 30
		var archetype_id := String(recipe["archetype_id"])
		state.meta_progression.hero_fragments[archetype_id] = maxi(
			tutorial_fragments,
			int(state.meta_progression.hero_fragments.get(archetype_id, 0))
		)
	return {"ok": true, "event": {
		"type": (
			"foundational_blueprint_unlocked"
			if FactoryStateScript.FOUNDATIONAL_BLUEPRINT_IDS.has(recipe_id)
			else "blueprint_research_claimed"
		),
		"recipe_id": recipe_id,
		"hero_id": hero.hero_id,
		"display_name": hero.display_name,
		"rating": String(recipe.get("rating", "B")),
		"newly_researched": newly_researched,
		"tutorial_fragments": int(
			state.meta_progression.hero_fragments.get(String(recipe["archetype_id"]), 0)
		),
	}}


static func blueprint_research_completes_at(research: Dictionary) -> int:
	var stored_completion := int(research.get("completes_at_unix", 0))
	var started_at := int(research.get("started_at_unix", stored_completion))
	return mini(stored_completion, started_at + DEBUG_RESEARCH_SECONDS)


static func _hero_for_archetype(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null


static func _first_free_facility_cell(state: RefCounted) -> Array[int]:
	var occupied: Dictionary = {}
	for facility_id in state.factory.facility_placements:
		if int(state.factory.facilities.get(facility_id, 0)) <= 0:
			continue
		var placement := state.factory.facility_placements[facility_id] as Array
		if placement.size() == 2:
			occupied["%d:%d" % [int(placement[0]), int(placement[1])]] = true
	if not occupied.has("2:1"):
		return [2, 1]
	for z in range(-2, 3):
		for x in range(-2, 3):
			var key := "%d:%d" % [x, z]
			if not occupied.has(key):
				return [x, z]
	return []


static func blueprint_status(state: RefCounted) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for recipe in FactoryCatalogScript.recipes():
		var recipe_id := String(recipe["recipe_id"])
		rows.append({
			"recipe_id": recipe_id,
			"display_name": String(recipe["display_name"]),
			"unlocked": bool(state.factory.blueprints.get(recipe_id, false)),
			"discovered": bool(state.factory.discovered_blueprints.get(recipe_id, false)),
			"unlock_hint": _unlock_hint(recipe_id),
		})
	return rows


static func upgrade_model_tech(state: RefCounted, recipe_id: String) -> Dictionary:
	if not bool(state.factory.blueprints.get(recipe_id, false)):
		return {"ok": false, "error": "BLUEPRINT_LOCKED"}
	var current_star := int(state.factory.model_tech_stars.get(recipe_id, 1))
	if current_star >= 3:
		return {"ok": false, "error": "MODEL_TECH_MAX_STAR"}
	var data_cost := 10 if current_star == 1 else 30
	var coin_cost := 200 if current_star == 1 else 600
	if int(state.factory.blueprint_data.get(recipe_id, 0)) < data_cost:
		return {"ok": false, "error": "NOT_ENOUGH_BLUEPRINT_DATA"}
	if state.economy.toilet_coins < coin_cost:
		return {"ok": false, "error": "NOT_ENOUGH_TOILET_COINS"}
	state.factory.blueprint_data[recipe_id] = int(state.factory.blueprint_data.get(recipe_id, 0)) - data_cost
	state.economy.toilet_coins -= coin_cost
	state.factory.model_tech_stars[recipe_id] = current_star + 1
	for hero in state.roster:
		if String(hero.archetype_id) == String(FactoryCatalogScript.recipe(recipe_id).get("archetype_id", "")):
			hero.star = current_star + 1
	return {
		"ok": true,
		"event": {
			"type": "model_tech_upgraded",
			"recipe_id": recipe_id,
			"star": current_star + 1,
			"blueprint_data_cost": data_cost,
			"toilet_coin_cost": coin_cost,
		},
	}


static func merge_heroes(state: RefCounted, hero_ids: Array[String]) -> Dictionary:
	if hero_ids.size() != 3:
		return {"ok": false, "error": "MERGE_REQUIRES_THREE_HEROES"}
	var unique: Dictionary = {}
	var heroes: Array[RefCounted] = []
	for hero_id in hero_ids:
		if unique.has(hero_id):
			return {"ok": false, "error": "MERGE_HERO_IDS_MUST_BE_UNIQUE"}
		unique[hero_id] = true
		var hero: RefCounted = state.hero_by_id(hero_id)
		if hero == null:
			return {"ok": false, "error": "HERO_NOT_FOUND"}
		heroes.append(hero)
	var exemplar: RefCounted = heroes[0]
	if exemplar.star >= 5:
		return {"ok": false, "error": "HERO_ALREADY_MAX_STAR"}
	for hero in heroes:
		if hero.archetype_id != exemplar.archetype_id or hero.star != exemplar.star:
			return {"ok": false, "error": "MERGE_HEROES_MUST_MATCH"}
	var merged: RefCounted = exemplar.deep_clone()
	merged.hero_id = HeroGenerator.merged_hero_id(state.run_seed, state.allocate_hero_index(), hero_ids)
	merged.star += 1
	merged.display_name = "%s ★%d" % [HeroGenerator.archetype_display_name(merged.archetype_id), merged.star]
	var vacated_slots: Array[String] = []
	for slot in state.formation.slots:
		if hero_ids.has(String(state.formation.slots[slot])):
			if String(slot) == "commander":
				return {"ok": false, "error": "MERGE_CANNOT_CONSUME_COMMANDER"}
			vacated_slots.append(String(slot))
			state.formation.slots[slot] = ""
	for hero_id in hero_ids:
		for index in range(state.roster.size() - 1, -1, -1):
			if state.roster[index].hero_id == hero_id:
				state.roster.remove_at(index)
				break
	state.roster.append(merged)
	if not vacated_slots.is_empty():
		state.formation.slots[vacated_slots.pop_front()] = merged.hero_id
	var deployed_ids: Array[String] = state.formation.hero_ids()
	for slot in vacated_slots:
		var replacement_id := ""
		for candidate in state.roster:
			var candidate_id := String(candidate.hero_id)
			if not deployed_ids.has(candidate_id):
				replacement_id = candidate_id
				break
		if replacement_id.is_empty():
			return {"ok": false, "error": "MERGE_WOULD_EMPTY_FORMATION_SLOT"}
		state.formation.slots[slot] = replacement_id
		deployed_ids.append(replacement_id)
	var consumed := hero_ids.duplicate()
	consumed.sort()
	return {
		"ok": true,
		"event": {
			"type": "heroes_merged",
			"consumed_hero_ids": consumed,
			"hero_id": merged.hero_id,
			"star": merged.star,
		},
	}


static func _unlock_hint(recipe_id: String) -> String:
	if FactoryStateScript.STARTING_BLUEPRINTS.has(recipe_id):
		return "初始普通车间"
	if FactoryStateScript.FIRST_FAILURE_UNLOCKS.has(recipe_id):
		return "第 4 关炮台防线失败后获得图纸，再交给马桶博士研究"
	if FactoryStateScript.FIRST_VICTORY_UNLOCKS.has(recipe_id):
		return "后续关卡胜利后获得图纸，再交给马桶博士研究"
	if FactoryStateScript.CORE_CLEAR_UNLOCKS.has(recipe_id):
		return "摧毁联盟核心后获得图纸，再交给马桶博士研究"
	return "未知蓝图"

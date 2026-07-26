class_name LogisticsService
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")
const CombatPowerScript := preload("res://game/scripts/domain/progression/combat_power.gd")
const HeroProgressionScript := preload("res://game/scripts/domain/progression/hero_progression.gd")

const FACILITY_IDS: Array[String] = [
	"command_center",
	"porcelain_plant",
	"parts_workshop",
	"energy_station",
	"repair_center",
	"research_lab",
]
const FACILITY_BUILD_COSTS: Dictionary = {
	"porcelain_plant": 30,
	"parts_workshop": 40,
	"energy_station": 35,
	"repair_center": 55,
	"research_lab": 70,
}
const OUTPUT_PER_MINUTE: Dictionary = {
	"porcelain": 6,
	"parts": 3,
	"sludge": 4,
}
const RESOURCE_BY_FACILITY: Dictionary = {
	"porcelain_plant": "porcelain",
	"parts_workshop": "parts",
	"energy_station": "sludge",
}
const MAX_OFFLINE_SECONDS: int = 12 * 60 * 60
const FACILITY_BUILD_SECONDS: Dictionary = {
	"porcelain_plant": 30,
	"parts_workshop": 45,
	"energy_station": 40,
	"repair_center": 60,
	"research_lab": 75,
}
const STAR_COSTS: Dictionary = {
	2: {"hero_shards": 4, "skill_chips": 0, "materials": {"porcelain": 18, "parts": 10, "sludge": 8}},
	3: {"hero_shards": 8, "skill_chips": 2, "materials": {"porcelain": 36, "parts": 24, "sludge": 20}},
}
const SPECIALTY_FACILITY: Dictionary = {
	"gman": "command_center",
	"assault": "porcelain_plant",
	"rocket": "parts_workshop",
	"repair": "repair_center",
}


static func claim_output(state: RefCounted, now_unix: int) -> Dictionary:
	var output := {"porcelain": 0, "parts": 0, "sludge": 0}
	var elapsed_max := 0
	for facility_id in RESOURCE_BY_FACILITY.keys():
		var preview := facility_output_preview(state, String(facility_id), now_unix)
		var material_id := String(preview.get("material_id", ""))
		var amount := int(preview.get("amount", 0))
		if amount <= 0:
			continue
		output[material_id] = amount
		elapsed_max = maxi(elapsed_max, int(preview.get("elapsed_seconds", 0)))
		state.factory.facility_output_anchors[facility_id] = now_unix
	if elapsed_max <= 0:
		return {"ok": false, "error": "NO_FACTORY_OUTPUT_READY"}
	var before := (state.factory.materials as Dictionary).duplicate(true)
	state.factory.grant(output)
	var accepted := {"porcelain": 0, "parts": 0, "sludge": 0}
	var overflow := {"porcelain": 0, "parts": 0, "sludge": 0}
	for material_id in output.keys():
		accepted[material_id] = int(state.factory.materials.get(material_id, 0)) - int(before.get(material_id, 0))
		overflow[material_id] = maxi(0, int(output[material_id]) - int(accepted[material_id]))
	state.factory.logistics_anchor_unix = now_unix
	return {
		"ok": true,
		"event": {
			"type": "factory_output_claimed",
			"facility_id": "all",
			"elapsed_seconds": elapsed_max,
				"materials": accepted,
				"produced": output,
				"overflow": overflow,
			"request_id": "factory-output:%d" % now_unix,
		},
	}


static func claim_facility_output(state: RefCounted, facility_id: String, now_unix: int) -> Dictionary:
	if not RESOURCE_BY_FACILITY.has(facility_id):
		return {"ok": false, "error": "FACILITY_HAS_NO_OUTPUT"}
	var preview := facility_output_preview(state, facility_id, now_unix)
	var amount := int(preview.get("amount", 0))
	if amount <= 0:
		return {"ok": false, "error": "NO_FACTORY_OUTPUT_READY"}
	var material_id := String(preview["material_id"])
	var output := {material_id: amount}
	var before := int(state.factory.materials.get(material_id, 0))
	state.factory.grant(output)
	var accepted := int(state.factory.materials.get(material_id, 0)) - before
	var overflow := maxi(0, amount - accepted)
	state.factory.facility_output_anchors[facility_id] = now_unix
	state.factory.logistics_anchor_unix = now_unix
	return {"ok": true, "event": {
		"type": "factory_output_claimed",
		"facility_id": facility_id,
		"elapsed_seconds": int(preview["elapsed_seconds"]),
		"materials": {material_id: accepted},
		"produced": output,
		"overflow": {material_id: overflow},
		"request_id": "facility-output:%s:%d" % [facility_id, now_unix],
	}}


static func facility_output_preview(state: RefCounted, facility_id: String, now_unix: int) -> Dictionary:
	if not RESOURCE_BY_FACILITY.has(facility_id):
		return {}
	if int(state.factory.facilities.get(facility_id, 0)) <= 0:
		return {
			"facility_id": facility_id,
			"material_id": String(RESOURCE_BY_FACILITY[facility_id]),
			"elapsed_seconds": 0,
			"amount": 0,
		}
	var anchor := int(state.factory.facility_output_anchors.get(
		facility_id,
		state.factory.logistics_anchor_unix
	))
	if anchor <= 0:
		anchor = now_unix - 300
	var elapsed := clampi(now_unix - anchor, 0, MAX_OFFLINE_SECONDS)
	var material_id := String(RESOURCE_BY_FACILITY[facility_id])
	return {
		"facility_id": facility_id,
		"material_id": material_id,
		"elapsed_seconds": elapsed,
		"amount": 0 if elapsed <= 0 else _facility_output(state, elapsed, material_id, facility_id),
	}


static func _facility_output(state: RefCounted, elapsed: int, material_id: String, facility_id: String) -> int:
	var per_minute := rate_per_minute(state, material_id)
	var base := float(elapsed) * float(per_minute) / 60.0
	return maxi(1, int(floor(base)))


static func rate_per_minute(state: RefCounted, material_id: String) -> float:
	if not OUTPUT_PER_MINUTE.has(material_id):
		return 0.0
	var facility_id := ""
	for candidate in RESOURCE_BY_FACILITY.keys():
		if String(RESOURCE_BY_FACILITY[candidate]) == material_id:
			facility_id = String(candidate)
			break
	if facility_id.is_empty():
		return 0.0
	var level := int(state.factory.facilities.get(facility_id, 0))
	if level <= 0:
		return 0.0
	var specialty_multiplier := 1.0
	for hero in state.roster:
		if String(hero.assigned_facility_id) == facility_id:
			specialty_multiplier += 0.2
	return float(int(OUTPUT_PER_MINUTE[material_id]) * level) * specialty_multiplier


static func seconds_until_full(state: RefCounted, material_id: String) -> int:
	var remaining := maxi(
		0,
		int(state.factory.capacities.get(material_id, 0)) - int(state.factory.materials.get(material_id, 0))
	)
	var per_second := rate_per_minute(state, material_id) / 60.0
	if remaining <= 0:
		return 0
	if per_second <= 0.0:
		return -1
	return int(ceil(float(remaining) / per_second))


static func upgrade_hero(state: RefCounted, hero_id: String) -> Dictionary:
	var hero: RefCounted = state.hero_by_id(hero_id)
	if hero == null:
		return {"ok": false, "error": "HERO_NOT_FOUND"}
	if int(hero.level) >= 5:
		return {"ok": false, "error": "HERO_LEVEL_CAP_REACHED"}
	var cost := hero_upgrade_cost(hero)
	var next_level := int(cost["target_level"])
	var coin_cost := int(cost["coin_cost"])
	var material_cost := cost["materials"] as Dictionary
	if int(state.economy.toilet_coins) < coin_cost:
		return {"ok": false, "error": "NOT_ENOUGH_TOILET_COINS"}
	if not state.factory.can_spend(material_cost):
		return {"ok": false, "error": "NOT_ENOUGH_FACTORY_MATERIALS"}
	state.economy.toilet_coins -= coin_cost
	state.factory.spend(material_cost)
	var power_before := CombatPowerScript.hero_power(hero)
	if not HeroProgressionScript.upgrade_to_level(hero, next_level):
		return {"ok": false, "error": "HERO_LEVEL_UPGRADE_FAILED"}
	var power_after := CombatPowerScript.hero_power(hero)
	return {
		"ok": true,
		"event": {
			"type": "hero_upgraded",
			"hero_id": hero_id,
			"level": next_level,
			"coin_cost": coin_cost,
			"material_cost": material_cost,
			"power_before": power_before,
			"power_after": power_after,
			"power_gain": power_after - power_before,
		},
	}


static func hero_upgrade_cost(hero: RefCounted) -> Dictionary:
	if hero == null or int(hero.level) >= 5:
		return {}
	var target_level := int(hero.level) + 1
	return {
		"target_level": target_level,
		"coin_cost": 30 * target_level,
		"materials": {
			"porcelain": 8 * target_level,
			"parts": 4 * target_level,
			"sludge": 3 * target_level,
		},
	}


static func upgrade_star(state: RefCounted, hero_id: String) -> Dictionary:
	var hero: RefCounted = state.hero_by_id(hero_id)
	if hero == null:
		return {"ok": false, "error": "HERO_NOT_FOUND"}
	var target_star := int(hero.star) + 1
	if target_star > 3:
		return {"ok": false, "error": "HERO_STAR_CAP_REACHED"}
	var cost := STAR_COSTS[target_star] as Dictionary
	var materials := cost["materials"] as Dictionary
	var shard_cost := int(cost["hero_shards"])
	var archetype_id := String(hero.archetype_id)
	var available_data := int(state.meta_progression.hero_data.get(archetype_id, 0))
	var data_spent := mini(shard_cost, available_data)
	var universal_spent := shard_cost - data_spent
	if int(state.economy.hero_shards) < universal_spent:
		return {"ok": false, "error": "NOT_ENOUGH_HERO_SHARDS"}
	if int(state.economy.skill_chips) < int(cost["skill_chips"]):
		return {"ok": false, "error": "NOT_ENOUGH_SKILL_CHIPS"}
	if not state.factory.can_spend(materials):
		return {"ok": false, "error": "NOT_ENOUGH_FACTORY_MATERIALS"}
	if data_spent > 0:
		state.meta_progression.hero_data[archetype_id] = available_data - data_spent
	state.economy.hero_shards -= universal_spent
	state.economy.skill_chips -= int(cost["skill_chips"])
	state.factory.spend(materials)
	hero.star = target_star
	var unlock_id := "%s_%s" % [String(hero.archetype_id), "passive" if target_star == 2 else "mastery"]
	if not hero.skill_ids.has(unlock_id):
		hero.skill_ids.append(unlock_id)
	return {"ok": true, "event": {
		"type": "hero_star_upgraded",
		"hero_id": hero_id,
		"archetype_id": archetype_id,
		"star": target_star,
		"unlock_id": unlock_id,
		"cost": {
			"hero_data": data_spent,
			"universal_hero_shards": universal_spent,
			"skill_chips": int(cost["skill_chips"]),
			"materials": materials.duplicate(true),
		},
	}}


static func research_active_skill(state: RefCounted, hero_id: String) -> Dictionary:
	var quote := active_skill_research_quote(state, hero_id)
	if not bool(quote.get("ok", false)):
		return {"ok": false, "error": String(quote.get("error", "ACTIVE_SKILL_RESEARCH_UNAVAILABLE"))}
	var hero: RefCounted = state.hero_by_id(hero_id)
	var target_level := int(quote["target_level"])
	var cost := quote["cost"] as Dictionary
	var material_cost := cost["materials"] as Dictionary
	state.economy.industrial_tech -= int(cost["industrial_tech"])
	state.economy.skill_chips -= int(cost["skill_chips"])
	state.economy.toilet_coins -= int(cost["toilet_coins"])
	state.factory.spend(material_cost)
	hero.active_skill_level = target_level
	return {"ok": true, "event": {
		"type": "active_skill_researched",
		"hero_id": hero_id,
		"skill_id": FactoryCatalogScript.active_skill_for_archetype(String(hero.archetype_id)),
		"skill_level": target_level,
		"industrial_tech_cost": int(cost["industrial_tech"]),
		"skill_chip_cost": int(cost["skill_chips"]),
		"coin_cost": int(cost["toilet_coins"]),
		"material_cost": material_cost.duplicate(true),
		"skill_power_bp": 10000 + (target_level - 1) * 2000,
	}}


static func active_skill_research_quote(state: RefCounted, hero_id: String) -> Dictionary:
	var hero: RefCounted = state.hero_by_id(hero_id)
	if hero == null:
		return {"ok": false, "error": "HERO_NOT_FOUND"}
	var target_level := int(hero.active_skill_level) + 1
	if target_level > 3:
		return {"ok": false, "error": "ACTIVE_SKILL_LEVEL_CAP_REACHED"}
	var cost := {
		"toilet_coins": 80 if target_level == 2 else 160,
		"industrial_tech": 6 if target_level == 2 else 12,
		"skill_chips": 1 if target_level == 2 else 2,
		"materials": {
			"porcelain": 24 if target_level == 2 else 48,
			"parts": 16 if target_level == 2 else 32,
			"sludge": 20 if target_level == 2 else 40,
		},
	}
	var lab_level := int(state.factory.facilities.get("research_lab", 1))
	if target_level > lab_level + 1:
		return {
			"ok": false,
			"error": "RESEARCH_LAB_LEVEL_TOO_LOW",
			"target_level": target_level,
			"cost": cost,
			"lab_level": lab_level,
		}
	var error := ""
	if int(state.economy.industrial_tech) < int(cost["industrial_tech"]):
		error = "NOT_ENOUGH_INDUSTRIAL_TECH"
	elif int(state.economy.skill_chips) < int(cost["skill_chips"]):
		error = "NOT_ENOUGH_SKILL_CHIPS"
	elif int(state.economy.toilet_coins) < int(cost["toilet_coins"]):
		error = "NOT_ENOUGH_TOILET_COINS"
	elif not state.factory.can_spend(cost["materials"] as Dictionary):
		error = "NOT_ENOUGH_FACTORY_MATERIALS"
	return {
		"ok": error.is_empty(),
		"error": error,
		"target_level": target_level,
		"cost": cost,
		"lab_level": lab_level,
	}


static func assign_specialist(state: RefCounted, hero_id: String, facility_id: String) -> Dictionary:
	var hero: RefCounted = state.hero_by_id(hero_id)
	if hero == null:
		return {"ok": false, "error": "HERO_NOT_FOUND"}
	if facility_id not in FACILITY_IDS:
		return {"ok": false, "error": "FACILITY_NOT_FOUND"}
	if int(hero.star) < 2:
		return {"ok": false, "error": "SPECIALTY_REQUIRES_TWO_STARS"}
	var specialty := String(SPECIALTY_FACILITY.get(String(hero.archetype_id), "energy_station"))
	if facility_id != specialty:
		return {"ok": false, "error": "SPECIALTY_FACILITY_MISMATCH"}
	for other in state.roster:
		if String(other.assigned_facility_id) == facility_id:
			other.assigned_facility_id = ""
	hero.assigned_facility_id = facility_id
	return {"ok": true, "event": {
		"type": "hero_specialist_assigned",
		"hero_id": hero_id,
		"facility_id": facility_id,
		"production_bonus_bp": 2000,
	}}


static func upgrade_facility(state: RefCounted, facility_id: String, now_unix: int) -> Dictionary:
	if facility_id not in FACILITY_IDS:
		return {"ok": false, "error": "FACILITY_NOT_FOUND"}
	var current := int(state.factory.facilities.get(facility_id, 0))
	if current <= 0:
		return {"ok": false, "error": "FACILITY_NOT_BUILT"}
	if current >= 3:
		return {"ok": false, "error": "FACILITY_LEVEL_CAP_REACHED"}
	if not state.factory.facility_work.is_empty():
		return {"ok": false, "error": "FACILITY_WORK_BUSY"}
	var tech_cost := 2 * current
	var coin_cost := 40 * current
	var material_cost := {
		"porcelain": 20 * current,
		"parts": 12 * current,
		"sludge": 16 * current,
	}
	if int(state.economy.industrial_tech) < tech_cost:
		return {"ok": false, "error": "NOT_ENOUGH_INDUSTRIAL_TECH"}
	if int(state.economy.toilet_coins) < coin_cost:
		return {"ok": false, "error": "NOT_ENOUGH_TOILET_COINS"}
	if not state.factory.can_spend(material_cost):
		return {"ok": false, "error": "NOT_ENOUGH_FACTORY_MATERIALS"}
	state.economy.industrial_tech -= tech_cost
	state.economy.toilet_coins -= coin_cost
	state.factory.spend(material_cost)
	var duration_seconds := 60 * current
	state.factory.facility_work = {
		"work_type": "upgrade",
		"facility_id": facility_id,
		"started_at_unix": now_unix,
		"completes_at_unix": now_unix + duration_seconds,
		"target_level": current + 1,
		"grid_x": 0,
		"grid_z": 0,
	}
	return {
		"ok": true,
		"event": {
			"type": "facility_work_started",
			"work_type": "upgrade",
			"facility_id": facility_id,
			"target_level": current + 1,
			"completes_at_unix": now_unix + duration_seconds,
			"tech_cost": tech_cost,
			"coin_cost": coin_cost,
			"material_cost": material_cost,
		},
	}


static func construct_facility(
	state: RefCounted,
	facility_id: String,
	now_unix: int,
	grid_x: int,
	grid_z: int
) -> Dictionary:
	if not FACILITY_BUILD_COSTS.has(facility_id):
		return {"ok": false, "error": "FACILITY_NOT_CONSTRUCTIBLE"}
	if int(state.factory.facilities.get(facility_id, 0)) > 0:
		return {"ok": false, "error": "FACILITY_ALREADY_BUILT"}
	if not state.factory.facility_work.is_empty():
		return {"ok": false, "error": "FACILITY_WORK_BUSY"}
	if facility_id == "research_lab" and not bool(state.factory.eligible_facilities.get("research_lab", false)):
		return {"ok": false, "error": "FACILITY_NOT_ELIGIBLE"}
	if abs(grid_x) > 2 or abs(grid_z) > 2:
		return {"ok": false, "error": "FACILITY_GRID_CELL_OUT_OF_BOUNDS"}
	for placed_facility_id in state.factory.facility_placements:
		if int(state.factory.facilities.get(placed_facility_id, 0)) <= 0:
			continue
		var occupied_cell := state.factory.facility_placements[placed_facility_id] as Array
		if occupied_cell.size() == 2 and int(occupied_cell[0]) == grid_x and int(occupied_cell[1]) == grid_z:
			return {"ok": false, "error": "FACILITY_GRID_CELL_OCCUPIED"}
	var coin_cost := int(FACILITY_BUILD_COSTS[facility_id])
	if int(state.economy.toilet_coins) < coin_cost:
		return {"ok": false, "error": "NOT_ENOUGH_TOILET_COINS"}
	state.economy.toilet_coins -= coin_cost
	var duration_seconds := int(FACILITY_BUILD_SECONDS[facility_id])
	state.factory.facility_work = {
		"work_type": "construction",
		"facility_id": facility_id,
		"started_at_unix": now_unix,
		"completes_at_unix": now_unix + duration_seconds,
		"target_level": 1,
		"grid_x": grid_x,
		"grid_z": grid_z,
	}
	return {
		"ok": true,
		"event": {
			"type": "facility_work_started",
			"work_type": "construction",
			"facility_id": facility_id,
			"grid_x": grid_x,
			"grid_z": grid_z,
			"target_level": 1,
			"coin_cost": coin_cost,
			"completes_at_unix": now_unix + duration_seconds,
		},
	}


static func claim_facility_work(state: RefCounted, now_unix: int) -> Dictionary:
	if state.factory.facility_work.is_empty():
		return {"ok": false, "error": "NO_FACILITY_WORK"}
	var work := state.factory.facility_work as Dictionary
	if now_unix < int(work.get("completes_at_unix", 0)):
		return {"ok": false, "error": "FACILITY_WORK_NOT_READY"}
	var facility_id := String(work["facility_id"])
	var work_type := String(work["work_type"])
	var target_level := int(work["target_level"])
	state.factory.facilities[facility_id] = target_level
	var discovered_blueprints: Array[String] = []
	if work_type == "construction":
		state.factory.facility_placements[facility_id] = [int(work["grid_x"]), int(work["grid_z"])]
		if facility_id == "research_lab":
			discovered_blueprints = state.factory.discover_blueprints(
				FactoryStateScript.FOUNDATIONAL_BLUEPRINT_IDS
			)
		if RESOURCE_BY_FACILITY.has(facility_id):
			# A newly commissioned producer exposes one real minute of output immediately.
			# This teaches the collect loop without turning the first session into a wait gate.
			state.factory.facility_output_anchors[facility_id] = now_unix - 60
	state.factory.facility_work = {}
	state.factory.refresh_capacities()
	return {"ok": true, "event": {
		"type": "facility_constructed" if work_type == "construction" else "facility_upgraded",
		"work_type": work_type,
		"facility_id": facility_id,
		"level": target_level,
		"completed_at_unix": now_unix,
		"discovered_blueprints": discovered_blueprints,
	}}


static func apply_battle_damage(state: RefCounted, deployed_ids: Array, disabled_ids: Array, outcome: String) -> Dictionary:
	# 战斗内 HP 仍决定当局胜负，但不会再写入任何跨局伤损。
	# 保留这个兼容入口，让旧 battle receipt 可安全重放而不制造损失。
	for value in deployed_ids:
		var hero_id := String(value)
		var hero: RefCounted = state.hero_by_id(hero_id)
		if hero == null:
			continue
		hero.readiness = 100
		hero.injury_flags.clear()
	return {}

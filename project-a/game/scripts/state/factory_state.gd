class_name FactoryState
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const MATERIAL_KEYS: Array[String] = ["porcelain", "parts", "sludge"]
const STARTING_BLUEPRINTS: Array[String] = []
const FIRST_FAILURE_UNLOCKS: Array[String] = ["ordinary.assault", "heavy.armored"]
const FOUNDATIONAL_BLUEPRINT_IDS: Array[String] = ["ordinary.assault", "heavy.armored"]
const FOUNDATIONAL_BLUEPRINT_ID: String = "ordinary.assault"
const FIRST_VICTORY_UNLOCKS: Array[String] = ["flying.bomber", "heavy.saw", "special.repair"]
const CORE_CLEAR_UNLOCKS: Array[String] = ["special.parasite"]

var materials: Dictionary = {"porcelain": 0, "parts": 0, "sludge": 0}
var capacities: Dictionary = {"porcelain": 2160, "parts": 2160, "sludge": 2160}
var discovered_blueprints: Dictionary = {}
var blueprints: Dictionary = {}
var blueprint_data: Dictionary = {}
var model_tech_stars: Dictionary = {}
var blueprint_research: Dictionary = {}
var production_queue: Array[Dictionary] = []
var next_sequence: int = 1
var next_hero_sequence: int = 2
var eligible_facilities: Dictionary = {"research_lab": true}
var facilities: Dictionary = {
	"command_center": 1,
	"porcelain_plant": 1,
	"parts_workshop": 1,
	"energy_station": 1,
	"repair_center": 1,
	"research_lab": 1,
}
var facility_placements: Dictionary = {
	"command_center": [0, -1],
	"porcelain_plant": [-2, -1],
	"parts_workshop": [2, -1],
	"energy_station": [-2, 1],
	"repair_center": [0, 1],
	"research_lab": [2, 1],
}
var logistics_anchor_unix: int = 0
var facility_output_anchors: Dictionary = {
	"porcelain_plant": 0,
	"parts_workshop": 0,
	"energy_station": 0,
}
var repair_orders: Array[Dictionary] = []
var next_repair_sequence: int = 1
var facility_work: Dictionary = {}


static func create_starting(include_built_facilities: bool = true) -> FactoryState:
	var factory := FactoryState.new()
	if not include_built_facilities:
		factory.facilities = {
			"command_center": 1,
			"porcelain_plant": 0,
			"parts_workshop": 0,
			"energy_station": 0,
			"repair_center": 0,
			"research_lab": 0,
		}
		factory.facility_placements = {"command_center": [0, -1]}
	# 新档先建设研究所；首批两张设计图纸分别由 1-2、1-3 首通获得。
	factory.eligible_facilities = {"research_lab": true}
	# v9 将工业库存归并到 porcelain 兼容槽；parts/sludge 只保留旧存档结构。
	factory.materials = {"porcelain": 112, "parts": 0, "sludge": 0}
	factory.discovered_blueprints = {}
	factory.blueprints = (
		{"ordinary.assault": true, "flying.rocket": true, "heavy.armored": true, "special.repair": true}
		if include_built_facilities
		else {}
	)
	factory.blueprint_data = {}
	factory.model_tech_stars = {
		"ordinary.assault": 1,
		"flying.rocket": 1,
		"heavy.armored": 1,
		"special.repair": 1,
	}
	for recipe_id in STARTING_BLUEPRINTS:
		factory.blueprints[recipe_id] = true
	factory.refresh_capacities()
	return factory


func deep_clone() -> FactoryState:
	return FactoryState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {
		"materials": materials.duplicate(true),
		"capacities": capacities.duplicate(true),
		"discovered_blueprints": discovered_blueprints.duplicate(true),
		"blueprints": blueprints.duplicate(true),
		"blueprint_data": blueprint_data.duplicate(true),
		"model_tech_stars": model_tech_stars.duplicate(true),
		"blueprint_research": blueprint_research.duplicate(true),
		"production_queue": production_queue.duplicate(true),
		"next_sequence": next_sequence,
		"next_hero_sequence": next_hero_sequence,
		"eligible_facilities": eligible_facilities.duplicate(true),
		"facilities": facilities.duplicate(true),
		"facility_placements": facility_placements.duplicate(true),
		"logistics_anchor_unix": logistics_anchor_unix,
		"facility_output_anchors": facility_output_anchors.duplicate(true),
		"repair_orders": repair_orders.duplicate(true),
		"next_repair_sequence": next_repair_sequence,
		"facility_work": facility_work.duplicate(true),
	}


static func from_dict(data: Dictionary) -> FactoryState:
	var factory := FactoryState.new()
	factory.materials = {}
	var material_data := data.get("materials", {}) as Dictionary
	for key in MATERIAL_KEYS:
		factory.materials[key] = int(material_data.get(key, 0))
	factory.discovered_blueprints = (data.get("discovered_blueprints", {}) as Dictionary).duplicate(true)
	factory.blueprints = (data.get("blueprints", {}) as Dictionary).duplicate(true)
	factory.blueprint_data = (data.get("blueprint_data", {}) as Dictionary).duplicate(true)
	factory.model_tech_stars = (data.get("model_tech_stars", {}) as Dictionary).duplicate(true)
	factory.blueprint_research = (data.get("blueprint_research", {}) as Dictionary).duplicate(true)
	factory.production_queue = []
	for entry in data.get("production_queue", []):
		factory.production_queue.append((entry as Dictionary).duplicate(true))
	factory.next_sequence = int(data.get("next_sequence", 1))
	factory.next_hero_sequence = int(data.get("next_hero_sequence", 2))
	factory.eligible_facilities = (data.get("eligible_facilities", {}) as Dictionary).duplicate(true)
	factory.facilities = (data.get("facilities", {
		"command_center": 1,
		"porcelain_plant": 1,
		"parts_workshop": 1,
		"energy_station": 1,
		"repair_center": 1,
		"research_lab": 1,
	}) as Dictionary).duplicate(true)
	factory.facility_placements = (data.get("facility_placements", {}) as Dictionary).duplicate(true)
	if factory.facility_placements.is_empty():
		var legacy_placements := {
			"command_center": [0, -1],
			"porcelain_plant": [-2, -1],
			"parts_workshop": [2, -1],
			"energy_station": [-2, 1],
			"repair_center": [0, 1],
			"research_lab": [2, 1],
		}
		for facility_id in legacy_placements:
			if int(factory.facilities.get(facility_id, 0)) > 0:
				factory.facility_placements[facility_id] = legacy_placements[facility_id]
	factory.capacities = (data.get("capacities", {}) as Dictionary).duplicate(true)
	if factory.capacities.is_empty():
		factory.refresh_capacities()
	factory.logistics_anchor_unix = int(data.get("logistics_anchor_unix", 0))
	factory.facility_output_anchors = (data.get("facility_output_anchors", {
		"porcelain_plant": factory.logistics_anchor_unix,
		"parts_workshop": factory.logistics_anchor_unix,
		"energy_station": factory.logistics_anchor_unix,
	}) as Dictionary).duplicate(true)
	# 旧存档中的等待维修订单在迁移时直接作废；资源此前已经扣除，不再二次扣款。
	factory.repair_orders = []
	factory.next_repair_sequence = int(data.get("next_repair_sequence", 1))
	factory.facility_work = (data.get("facility_work", {}) as Dictionary).duplicate(true)
	return factory


func can_spend(cost: Dictionary) -> bool:
	for key in MATERIAL_KEYS:
		if int(materials.get(key, 0)) < int(cost.get(key, 0)):
			return false
	return true


func spend(cost: Dictionary) -> void:
	for key in MATERIAL_KEYS:
		materials[key] = int(materials.get(key, 0)) - int(cost.get(key, 0))


func grant(reward: Dictionary) -> void:
	for key in MATERIAL_KEYS:
		if reward.has(key):
			var current := int(materials.get(key, 0))
			var headroom := maxi(0, int(capacities.get(key, 0)) - current)
			materials[key] = current + mini(headroom, maxi(0, int(reward[key])))


func refresh_capacities() -> void:
	capacities = capacities_for_facilities(facilities)
	for key in MATERIAL_KEYS:
		# A v8 conversion may legitimately exceed the new pooled capacity.
		# Preserve that balance and let later spending bring it below the cap.
		if key == "porcelain" and int(materials.get(key, 0)) > int(capacities[key]):
			continue
		materials[key] = mini(int(materials.get(key, 0)), int(capacities[key]))


static func capacities_for_facilities(facility_levels: Dictionary) -> Dictionary:
	var active_line_levels := 0
	for facility_id in ["porcelain_plant", "parts_workshop", "energy_station"]:
		active_line_levels += maxi(0, int(facility_levels.get(facility_id, 0)))
	var industrial_capacity := maxi(2160, active_line_levels * 2160)
	return {
		"porcelain": industrial_capacity,
		# Compatibility slots must stay valid for strict legacy save decoding.
		"parts": 2160,
		"sludge": 2160,
	}


func unlock_blueprints(recipe_ids: Array[String]) -> Array[String]:
	var unlocked: Array[String] = []
	for recipe_id in recipe_ids:
		if not bool(blueprints.get(recipe_id, false)):
			blueprints[recipe_id] = true
			unlocked.append(recipe_id)
	return unlocked


func validate() -> Array[String]:
	var errors: Array[String] = []
	for key in MATERIAL_KEYS:
		if int(materials.get(key, -1)) < 0:
			errors.append("factory.materials.%s must not be negative" % key)
		if int(capacities.get(key, 0)) <= 0:
			errors.append("factory.capacities.%s must be positive" % key)
		elif key != "porcelain" and int(materials.get(key, 0)) > int(capacities[key]):
			errors.append("factory.materials.%s exceeds capacity" % key)
	if next_sequence < 1:
		errors.append("factory.next_sequence must be positive")
	if next_hero_sequence < 1:
		errors.append("factory.next_hero_sequence must be positive")
	for eligible_facility_id in eligible_facilities:
		if not facilities.has(String(eligible_facility_id)) or not bool(eligible_facilities[eligible_facility_id]):
			errors.append("factory.eligible_facilities contains invalid entry")
	if production_queue.size() > 3:
		errors.append("factory.production_queue exceeds three slots")
	for facility_id in ["command_center", "porcelain_plant", "parts_workshop", "energy_station", "repair_center", "research_lab"]:
		var facility_level := int(facilities.get(facility_id, 0))
		var minimum_level := 1 if facility_id == "command_center" else 0
		if facility_level < minimum_level or facility_level > 3:
			errors.append("factory.facilities.%s must be %d..3" % [facility_id, minimum_level])
		if facility_level > 0:
			if not facility_placements.has(facility_id):
				errors.append("factory.facility_placements.%s is required" % facility_id)
			else:
				var placement := facility_placements[facility_id] as Array
				if placement.size() != 2 or abs(int(placement[0])) > 2 or abs(int(placement[1])) > 2:
					errors.append("factory.facility_placements.%s is outside the build grid" % facility_id)
	var occupied_cells: Dictionary = {}
	for placed_facility_id in facility_placements:
		if int(facilities.get(placed_facility_id, 0)) <= 0:
			continue
		var occupied_cell := facility_placements[placed_facility_id] as Array
		if occupied_cell.size() != 2:
			continue
		var occupied_key := "%d:%d" % [int(occupied_cell[0]), int(occupied_cell[1])]
		if occupied_cells.has(occupied_key):
			errors.append("factory facility placement overlaps at %s" % occupied_key)
		occupied_cells[occupied_key] = placed_facility_id
	if logistics_anchor_unix < 0:
		errors.append("factory.logistics_anchor_unix must not be negative")
	for facility_id in ["porcelain_plant", "parts_workshop", "energy_station"]:
		if int(facility_output_anchors.get(facility_id, -1)) < 0:
			errors.append("factory.facility_output_anchors.%s must be non-negative" % facility_id)
	if next_repair_sequence < 1:
		errors.append("factory.next_repair_sequence must be positive")
	if not facility_work.is_empty():
		var work_type := String(facility_work.get("work_type", ""))
		var work_facility_id := String(facility_work.get("facility_id", ""))
		if work_type not in ["construction", "upgrade"]:
			errors.append("factory.facility_work has invalid work_type")
		if work_facility_id not in ["command_center", "porcelain_plant", "parts_workshop", "energy_station", "repair_center", "research_lab"]:
			errors.append("factory.facility_work has invalid facility_id")
		if int(facility_work.get("completes_at_unix", -1)) < int(facility_work.get("started_at_unix", 0)):
			errors.append("factory.facility_work completion precedes start")
		if int(facility_work.get("target_level", 0)) < 1 or int(facility_work.get("target_level", 0)) > 3:
			errors.append("factory.facility_work has invalid target_level")
		if work_type == "construction":
			var work_x := int(facility_work.get("grid_x", 99))
			var work_z := int(facility_work.get("grid_z", 99))
			if abs(work_x) > 2 or abs(work_z) > 2:
				errors.append("factory.facility_work construction is outside the build grid")
	var repair_ids: Dictionary = {}
	var repair_heroes: Dictionary = {}
	for order in repair_orders:
		var order_id := String(order.get("order_id", ""))
		var hero_id := String(order.get("hero_id", ""))
		if order_id.is_empty() or repair_ids.has(order_id):
			errors.append("factory repair order_id is missing or duplicated")
		if hero_id.is_empty() or repair_heroes.has(hero_id):
			errors.append("factory repair hero_id is missing or duplicated")
		repair_ids[order_id] = true
		repair_heroes[hero_id] = true
		if int(order.get("completes_at_unix", -1)) < int(order.get("started_at_unix", 0)):
			errors.append("factory repair completion precedes start")
	for recipe_id in blueprints.keys():
		if not FactoryCatalogScript.has_recipe(String(recipe_id)):
			errors.append("factory.blueprints contains unknown recipe %s" % String(recipe_id))
	for recipe_id in blueprint_data.keys():
		if not FactoryCatalogScript.has_recipe(String(recipe_id)) or int(blueprint_data[recipe_id]) < 0:
			errors.append("factory.blueprint_data invalid for %s" % String(recipe_id))
	for recipe_id in model_tech_stars.keys():
		var star := int(model_tech_stars[recipe_id])
		if not FactoryCatalogScript.has_recipe(String(recipe_id)) or star < 1 or star > 3:
			errors.append("factory.model_tech_stars invalid for %s" % String(recipe_id))
	for recipe_id in discovered_blueprints.keys():
		if not FactoryCatalogScript.has_recipe(String(recipe_id)):
			errors.append("factory.discovered_blueprints contains unknown recipe %s" % String(recipe_id))
	if not blueprint_research.is_empty():
		var research_recipe_id := String(blueprint_research.get("recipe_id", ""))
		if not FactoryCatalogScript.has_recipe(research_recipe_id):
			errors.append("factory.blueprint_research contains unknown recipe")
		if int(blueprint_research.get("completes_at_unix", -1)) < int(blueprint_research.get("started_at_unix", 0)):
			errors.append("factory blueprint research completion precedes start")
	var order_ids: Dictionary = {}
	for entry in production_queue:
		var order_id := String(entry.get("order_id", ""))
		var recipe_id := String(entry.get("recipe_id", ""))
		if order_id.is_empty():
			errors.append("factory order_id is required")
		elif order_ids.has(order_id):
			errors.append("duplicate factory order_id %s" % order_id)
		order_ids[order_id] = true
		if not FactoryCatalogScript.has_recipe(recipe_id):
			errors.append("factory order contains unknown recipe %s" % recipe_id)
		if int(entry.get("completes_at_unix", -1)) < int(entry.get("started_at_unix", 0)):
			errors.append("factory order completion precedes start")
	return errors


func discover_blueprints(recipe_ids: Array[String]) -> Array[String]:
	var discovered: Array[String] = []
	for recipe_id in recipe_ids:
		if bool(blueprints.get(recipe_id, false)) or bool(discovered_blueprints.get(recipe_id, false)):
			continue
		discovered_blueprints[recipe_id] = true
		discovered.append(recipe_id)
	return discovered

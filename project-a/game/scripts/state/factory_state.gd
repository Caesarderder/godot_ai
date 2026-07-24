class_name FactoryState
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const MATERIAL_KEYS: Array[String] = ["porcelain", "parts", "sludge"]
const STARTING_BLUEPRINTS: Array[String] = ["ordinary.assault", "ordinary.sonic"]
const FIRST_FAILURE_UNLOCKS: Array[String] = ["flying.rocket", "heavy.armored"]
const FIRST_VICTORY_UNLOCKS: Array[String] = ["flying.bomber", "heavy.saw", "special.repair"]
const CORE_CLEAR_UNLOCKS: Array[String] = ["special.parasite"]

var materials: Dictionary = {"porcelain": 0, "parts": 0, "sludge": 0}
var blueprints: Dictionary = {}
var production_queue: Array[Dictionary] = []
var next_sequence: int = 1
var next_hero_sequence: int = 9


static func create_starting() -> FactoryState:
	var factory := FactoryState.new()
	factory.materials = {"porcelain": 120, "parts": 100, "sludge": 80}
	factory.blueprints = {}
	for recipe_id in STARTING_BLUEPRINTS:
		factory.blueprints[recipe_id] = true
	return factory


func deep_clone() -> FactoryState:
	return FactoryState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {
		"materials": materials.duplicate(true),
		"blueprints": blueprints.duplicate(true),
		"production_queue": production_queue.duplicate(true),
		"next_sequence": next_sequence,
		"next_hero_sequence": next_hero_sequence,
	}


static func from_dict(data: Dictionary) -> FactoryState:
	var factory := FactoryState.new()
	factory.materials = {}
	var material_data := data.get("materials", {}) as Dictionary
	for key in MATERIAL_KEYS:
		factory.materials[key] = int(material_data.get(key, 0))
	factory.blueprints = (data.get("blueprints", {}) as Dictionary).duplicate(true)
	factory.production_queue = []
	for entry in data.get("production_queue", []):
		factory.production_queue.append((entry as Dictionary).duplicate(true))
	factory.next_sequence = int(data.get("next_sequence", 1))
	factory.next_hero_sequence = int(data.get("next_hero_sequence", 9))
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
			materials[key] = int(materials.get(key, 0)) + int(reward[key])


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
	if next_sequence < 1:
		errors.append("factory.next_sequence must be positive")
	if next_hero_sequence < 1:
		errors.append("factory.next_hero_sequence must be positive")
	if production_queue.size() > 3:
		errors.append("factory.production_queue exceeds three slots")
	for recipe_id in blueprints.keys():
		if not FactoryCatalogScript.has_recipe(String(recipe_id)):
			errors.append("factory.blueprints contains unknown recipe %s" % String(recipe_id))
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

class_name GameState
extends RefCounted

const HeroStateScript := preload("res://game/scripts/state/hero_state.gd")
const EconomyStateScript := preload("res://game/scripts/state/economy_state.gd")
const FormationStateScript := preload("res://game/scripts/state/formation_state.gd")
const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")

var schema_version: int = 4
var content_version: String = "factory-siege-v4"
var save_id: String = ""
var run_seed: int = 0
var revision: int = 0
var roster: Array[RefCounted] = []
var inventory: Dictionary = {"items": {}}
var formation: RefCounted = FormationStateScript.new()
var economy: RefCounted = EconomyStateScript.new()
var factory: RefCounted = FactoryStateScript.new()
var camp: Dictionary = {"tavern_level": 1, "blacksmith_level": 1, "training_ground_level": 1}
var quests: Dictionary = {"active": {}, "completed": {}, "claimed": {}}
var pity: Dictionary = {"qualifying_drops_since_blue": 0, "guaranteed_blue_consumed": false}
var stage_progress: Dictionary = {"highest_unlocked_stage": "stage_1_1", "cleared_stages": []}
var auto_skill_preferences: Dictionary = {}
var attempt_counters: Dictionary = {}
var receipt_ledgers: Dictionary = {"durable": {}, "reversible": {}}
var command_receipts: Dictionary = {}
var business_receipts: Dictionary = {}
var achievements: Dictionary = {"progress": {}, "completed": {}, "claimed": {}, "event_keys": {}, "counters": {}}
var saved_at_unix: int = 0
var last_seen_wall_unix: int = 0
var last_settled_unix: int = 0
var offline_anchor_unix: int = 0


static func create_new(run_seed_value: int = 20260723, now_unix: int = 0) -> GameState:
	var state := GameState.new()
	state.save_id = "local-save-v1"
	state.run_seed = run_seed_value
	state.economy = EconomyStateScript.create_starting()
	state.factory = FactoryStateScript.create_starting()
	state.roster = HeroGenerator.create_initial_roster(run_seed_value)
	var hero_ids: Array[String] = []
	for hero in state.roster:
		hero_ids.append(hero.hero_id)
	state.formation = FormationStateScript.from_heroes(hero_ids)
	state.saved_at_unix = now_unix
	state.last_seen_wall_unix = now_unix
	state.last_settled_unix = 0
	state.offline_anchor_unix = now_unix
	return state


func deep_clone() -> GameState:
	return GameState.from_dict(to_dict())


func hero_by_id(hero_id: String) -> RefCounted:
	for hero in roster:
		if hero.hero_id == hero_id:
			return hero
	return null


func roster_ids() -> Array[String]:
	var ids: Array[String] = []
	for hero in roster:
		ids.append(hero.hero_id)
	return ids


func next_hero_index() -> int:
	return factory.next_hero_sequence - 1


func allocate_hero_index() -> int:
	var index: int = factory.next_hero_sequence - 1
	factory.next_hero_sequence += 1
	return index


func to_dict() -> Dictionary:
	var roster_data: Array = []
	for hero in roster:
		roster_data.append(hero.to_dict())
	return {
		"schema_version": schema_version,
		"content_version": content_version,
		"save_id": save_id,
		"run_seed": run_seed,
		"revision": revision,
		"roster": roster_data,
		"inventory": inventory.duplicate(true),
		"formation": formation.to_dict(),
		"economy": economy.to_dict(),
		"factory": factory.to_dict(),
		"camp": camp.duplicate(true),
		"quests": quests.duplicate(true),
		"pity": pity.duplicate(true),
		"stage_progress": stage_progress.duplicate(true),
		"auto_skill_preferences": auto_skill_preferences.duplicate(true),
		"attempt_counters": attempt_counters.duplicate(true),
		"receipt_ledgers": receipt_ledgers.duplicate(true),
		"command_receipts": command_receipts.duplicate(true),
		"business_receipts": business_receipts.duplicate(true),
		"achievements": achievements.duplicate(true),
		"saved_at_unix": saved_at_unix,
		"last_seen_wall_unix": last_seen_wall_unix,
		"last_settled_unix": last_settled_unix,
		"offline_anchor_unix": offline_anchor_unix,
	}


static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.schema_version = int(data.get("schema_version", 4))
	state.content_version = String(data.get("content_version", "factory-siege-v4"))
	state.save_id = String(data.get("save_id", ""))
	state.run_seed = int(data.get("run_seed", 0))
	state.revision = int(data.get("revision", 0))
	state.roster = []
	for hero_data in data.get("roster", []):
		state.roster.append(HeroStateScript.from_dict(hero_data as Dictionary))
	state.inventory = (data.get("inventory", {"items": {}}) as Dictionary).duplicate(true)
	state.formation = FormationStateScript.from_dict(data.get("formation", {}))
	state.economy = EconomyStateScript.from_dict(data.get("economy", {}))
	state.factory = FactoryStateScript.from_dict(data.get("factory", {}))
	state.camp = (data.get("camp", {}) as Dictionary).duplicate(true)
	state.quests = (data.get("quests", {}) as Dictionary).duplicate(true)
	state.pity = (data.get("pity", {}) as Dictionary).duplicate(true)
	state.stage_progress = (data.get("stage_progress", {}) as Dictionary).duplicate(true)
	state.auto_skill_preferences = (data.get("auto_skill_preferences", {}) as Dictionary).duplicate(true)
	state.attempt_counters = (data.get("attempt_counters", {}) as Dictionary).duplicate(true)
	state.receipt_ledgers = (data.get("receipt_ledgers", {}) as Dictionary).duplicate(true)
	state.command_receipts = (data.get("command_receipts", {}) as Dictionary).duplicate(true)
	state.business_receipts = (data.get("business_receipts", {}) as Dictionary).duplicate(true)
	state.achievements = (data.get("achievements", {"progress": {}, "completed": {}, "claimed": {}, "event_keys": {}, "counters": {}}) as Dictionary).duplicate(true)
	state.saved_at_unix = int(data.get("saved_at_unix", 0))
	state.last_seen_wall_unix = int(data.get("last_seen_wall_unix", 0))
	state.last_settled_unix = int(data.get("last_settled_unix", 0))
	state.offline_anchor_unix = int(data.get("offline_anchor_unix", 0))
	return state


func validate() -> Array[String]:
	var errors: Array[String] = []
	if schema_version != 4:
		errors.append("unsupported schema_version")
	if content_version.is_empty():
		errors.append("content_version is required")
	if save_id.is_empty():
		errors.append("save_id is required")
	if roster.size() < 6:
		errors.append("roster requires at least 6 heroes")
	var seen: Dictionary = {}
	for hero in roster:
		errors.append_array(hero.validate())
		if seen.has(hero.hero_id):
			errors.append("duplicate hero_id %s" % hero.hero_id)
		seen[hero.hero_id] = true
	errors.append_array(formation.validate(roster_ids()))
	errors.append_array(economy.validate())
	errors.append_array(factory.validate())
	var achievements_error := _validate_achievements()
	if not achievements_error.is_empty():
		errors.append(achievements_error)
	if revision < 0:
		errors.append("revision must not be negative")
	return errors


func _validate_achievements() -> String:
	if typeof(achievements) != TYPE_DICTIONARY:
		return "achievements must be dictionary"
	var expected: Array[String] = ["progress", "completed", "claimed", "event_keys", "counters"]
	var actual: Array[String] = []
	for key in achievements.keys():
		if typeof(key) != TYPE_STRING:
			return "achievements has non-string key"
		actual.append(String(key))
	actual.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	if actual != sorted_expected:
		return "achievements keys mismatch"
	for key in expected:
		if typeof(achievements[key]) != TYPE_DICTIONARY:
			return "achievements.%s must be dictionary" % key
	return ""

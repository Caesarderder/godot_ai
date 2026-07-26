class_name GameState
extends RefCounted

const HeroStateScript := preload("res://game/scripts/state/hero_state.gd")
const EconomyStateScript := preload("res://game/scripts/state/economy_state.gd")
const FormationStateScript := preload("res://game/scripts/state/formation_state.gd")
const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const OnboardingServiceScript := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")
const MetaProgressionStateScript := preload("res://game/scripts/state/meta_progression_state.gd")

var schema_version: int = 8
var content_version: String = "toilet-factory-slg-v2"
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
var pity: Dictionary = {
	"qualifying_drops_since_blue": 0,
	"guaranteed_blue_consumed": false,
	"blueprint_draw_count": 0,
	"s_pity_count": 0,
	"pool_id": "standard_s",
	"target_s_recipe_id": "special.parasite",
}
var stage_progress: Dictionary = {"highest_unlocked_stage": "stage_1_1", "cleared_stages": []}
var auto_skill_preferences: Dictionary = {}
var attempt_counters: Dictionary = {}
var receipt_ledgers: Dictionary = {"durable": {}, "reversible": {}}
var command_receipts: Dictionary = {}
var business_receipts: Dictionary = {}
var achievements: Dictionary = {"progress": {}, "completed": {}, "claimed": {}, "event_keys": {}, "counters": {}}
var onboarding: Dictionary = OnboardingServiceScript.default_state()
var meta_progression: RefCounted = MetaProgressionStateScript.create_starting()
var saved_at_unix: int = 0
var last_seen_wall_unix: int = 0
var last_settled_unix: int = 0
var offline_anchor_unix: int = 0


static func create_new(
	run_seed_value: int = 20260723,
	now_unix: int = 0,
	include_built_facilities: bool = true
) -> GameState:
	var state := GameState.new()
	state.save_id = "local-save-v1"
	state.run_seed = run_seed_value
	state.economy = EconomyStateScript.create_starting()
	state.factory = FactoryStateScript.create_starting(include_built_facilities)
	state.roster = HeroGenerator.create_initial_roster(run_seed_value)
	var hero_ids: Array[String] = []
	for hero in state.roster:
		hero_ids.append(hero.hero_id)
	state.formation = FormationStateScript.from_heroes(hero_ids)
	state.saved_at_unix = now_unix
	state.last_seen_wall_unix = now_unix
	state.last_settled_unix = 0
	state.offline_anchor_unix = now_unix
	state.factory.logistics_anchor_unix = maxi(0, now_unix - 300)
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
	var index: int = maxi(factory.next_hero_sequence - 1, roster.size())
	factory.next_hero_sequence = index + 2
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
		"onboarding": onboarding.duplicate(true),
		"meta_progression": meta_progression.to_dict(),
		"saved_at_unix": saved_at_unix,
		"last_seen_wall_unix": last_seen_wall_unix,
		"last_settled_unix": last_settled_unix,
		"offline_anchor_unix": offline_anchor_unix,
	}


static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.schema_version = int(data.get("schema_version", 8))
	# 缺少合同版本的存档必须按 legacy 处理，不能因为默认值而伪装成新玩法存档。
	state.content_version = String(data.get("content_version", "legacy-unknown"))
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
	state.onboarding = (data.get("onboarding", OnboardingServiceScript.default_state()) as Dictionary).duplicate(true)
	state.meta_progression = MetaProgressionStateScript.from_dict(data.get("meta_progression", {}))
	OnboardingServiceScript.normalize(state)
	state.saved_at_unix = int(data.get("saved_at_unix", 0))
	state.last_seen_wall_unix = int(data.get("last_seen_wall_unix", 0))
	state.last_settled_unix = int(data.get("last_settled_unix", 0))
	state.offline_anchor_unix = int(data.get("offline_anchor_unix", 0))
	return state


func validate() -> Array[String]:
	var errors: Array[String] = []
	if schema_version != 8:
		errors.append("unsupported schema_version")
	if content_version.is_empty():
		errors.append("content_version is required")
	if save_id.is_empty():
		errors.append("save_id is required")
	var seen: Dictionary = {}
	for hero in roster:
		errors.append_array(hero.validate())
		if seen.has(hero.hero_id):
			errors.append("duplicate hero_id %s" % hero.hero_id)
		seen[hero.hero_id] = true
	errors.append_array(formation.validate(roster_ids()))
	errors.append_array(_validate_formation_model_limits())
	errors.append_array(economy.validate())
	errors.append_array(factory.validate())
	var achievements_error := _validate_achievements()
	if not achievements_error.is_empty():
		errors.append(achievements_error)
	var onboarding_error := OnboardingServiceScript.validate(onboarding)
	if not onboarding_error.is_empty():
		errors.append(onboarding_error)
	errors.append_array(meta_progression.validate())
	if revision < 0:
		errors.append("revision must not be negative")
	return errors


func _validate_formation_model_limits() -> Array[String]:
	var errors: Array[String] = []
	var s_model_counts: Dictionary = {}
	for hero_id in formation.hero_ids():
		var hero: RefCounted = hero_by_id(hero_id)
		if hero == null:
			continue
		var recipe := FactoryCatalogScript.recipe_for_archetype(String(hero.archetype_id))
		if String(recipe.get("rarity", "")) != "legendary":
			continue
		var model_id := String(recipe.get("recipe_id", hero.archetype_id))
		s_model_counts[model_id] = int(s_model_counts.get(model_id, 0)) + 1
		if int(s_model_counts[model_id]) > 1:
			errors.append("S rarity model %s may appear only once in formation" % model_id)
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

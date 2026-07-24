class_name SaveCodec
extends RefCounted

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")

const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")

const CURRENT_SCHEMA_VERSION: int = 3
const GAME_KEYS: Array[String] = [
	"schema_version", "content_version", "save_id", "run_seed", "revision",
	"roster", "inventory", "formation", "economy", "factory", "camp", "quests", "pity",
	"stage_progress", "auto_skill_preferences", "attempt_counters", "receipt_ledgers", "command_receipts",
	"business_receipts", "saved_at_unix", "last_seen_wall_unix",
	"last_settled_unix", "offline_anchor_unix"
]
const HERO_KEYS: Array[String] = [
	"hero_id", "display_name", "class_id", "archetype_id", "star", "aptitude_id", "trait_ids",
	"skill_ids", "auto_skill_enabled", "equipment_by_slot", "level", "xp", "base_stats",
	"stat_remainders", "seed_token"
]
const FORMATION_KEYS: Array[String] = ["front_left", "front_center", "front_right", "back_left", "back_center", "back_right"]
const ECONOMY_KEYS: Array[String] = ["gold", "recruit_tickets", "xp_books", "forge_stones"]
const FACTORY_KEYS: Array[String] = ["materials", "blueprints", "production_queue", "next_sequence", "next_hero_sequence"]
const PRODUCTION_KEYS: Array[String] = ["order_id", "recipe_id", "started_at_unix", "completes_at_unix"]
const ATTR_KEYS: Array[String] = ["vig", "str", "agi", "int"]
const EQUIPMENT_SLOT_KEYS: Array[String] = ["weapon", "armor", "accessory"]
const V1_GAME_KEYS: Array[String] = [
	"schema_version", "content_version", "save_id", "run_seed", "revision",
	"roster", "inventory", "formation", "economy", "camp", "quests", "pity",
	"stage_progress", "attempt_counters", "receipt_ledgers", "command_receipts",
	"business_receipts", "saved_at_unix", "last_seen_wall_unix",
	"last_settled_unix", "offline_anchor_unix"
]
const V1_HERO_KEYS: Array[String] = [
	"hero_id", "display_name", "class_id", "aptitude_id", "trait_ids",
	"skill_ids", "equipment_by_slot", "level", "xp", "base_stats",
	"stat_remainders", "seed_token"
]
const V2_GAME_KEYS: Array[String] = [
	"schema_version", "content_version", "save_id", "run_seed", "revision",
	"roster", "inventory", "formation", "economy", "factory", "camp", "quests", "pity",
	"stage_progress", "attempt_counters", "receipt_ledgers", "command_receipts",
	"business_receipts", "saved_at_unix", "last_seen_wall_unix",
	"last_settled_unix", "offline_anchor_unix"
]
const V2_HERO_KEYS: Array[String] = [
	"hero_id", "display_name", "class_id", "archetype_id", "star", "aptitude_id", "trait_ids",
	"skill_ids", "equipment_by_slot", "level", "xp", "base_stats",
	"stat_remainders", "seed_token"
]
const V1_FORMATION_KEYS: Array[String] = ["front_left", "front_right", "back_left", "back_right"]


static func encode(state: RefCounted) -> Dictionary:
	return state.to_dict()


static func to_json_text(state: RefCounted) -> String:
	return JSON.stringify(encode(state), "\t", true)


static func from_json_text(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		return {"ok": false, "error": "invalid json"}
	var normalized := _normalize_json_numbers(parsed)
	if not bool(normalized.get("ok", false)):
		return normalized
	parsed = normalized["value"]
	return decode(parsed)


static func _validate_no_forbidden_types(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return ""
		TYPE_FLOAT:
			return "save data must not contain floats"
		TYPE_ARRAY:
			for item in value:
				var item_error := _validate_no_forbidden_types(item)
				if not item_error.is_empty():
					return item_error
			return ""
		TYPE_DICTIONARY:
			var dict := value as Dictionary
			for key in dict.keys():
				if typeof(key) != TYPE_STRING:
					return "save dictionary keys must be strings"
				var child_error := _validate_no_forbidden_types(dict[key])
				if not child_error.is_empty():
					return child_error
			return ""
		_:
			return "save data contains unsupported type %s" % type_string(typeof(value))


static func decode(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "save root must be a dictionary"}
	var dict := data as Dictionary
	var primitive_error := _validate_no_forbidden_types(dict)
	if not primitive_error.is_empty():
		return {"ok": false, "error": primitive_error}
	if not dict.has("schema_version") or typeof(dict["schema_version"]) != TYPE_INT:
		return {"ok": false, "error": "schema_version must be int"}
	if int(dict["schema_version"]) == 1:
		var v1_error := _validate_v1_game_schema(dict)
		if not v1_error.is_empty():
			return {"ok": false, "error": v1_error}
		dict = _migrate_v1_to_v2(dict)
	if int(dict["schema_version"]) == 2:
		var v2_error := _validate_v2_game_schema(dict)
		if not v2_error.is_empty():
			return {"ok": false, "error": v2_error}
		dict = _migrate_v2_to_v3(dict)
	var schema_error := _validate_game_schema(dict)
	if not schema_error.is_empty():
		return {"ok": false, "error": schema_error}
	var state := GameStateScript.from_dict(dict)
	var errors := state.validate()
	if not errors.is_empty():
		return {"ok": false, "error": "; ".join(errors)}
	return {"ok": true, "state": state}


static func _normalize_json_numbers(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_FLOAT:
			var float_value := float(value)
			if float_value != floorf(float_value):
				return {"ok": false, "error": "save json contains non-integer number"}
			return {"ok": true, "value": int(float_value)}
		TYPE_ARRAY:
			var array_result: Array = []
			for item in value:
				var item_result := _normalize_json_numbers(item)
				if not bool(item_result.get("ok", false)):
					return item_result
				array_result.append(item_result["value"])
			return {"ok": true, "value": array_result}
		TYPE_DICTIONARY:
			var dict := value as Dictionary
			var dict_result: Dictionary = {}
			for key in dict.keys():
				if typeof(key) != TYPE_STRING:
					return {"ok": false, "error": "save dictionary keys must be strings"}
				var child_result := _normalize_json_numbers(dict[key])
				if not bool(child_result.get("ok", false)):
					return child_result
				dict_result[key] = child_result["value"]
			return {"ok": true, "value": dict_result}
		_:
			return {"ok": true, "value": value}


static func _validate_game_schema(data: Dictionary) -> String:
	var key_error := _exact_keys(data, GAME_KEYS, "GameState")
	if not key_error.is_empty():
		return key_error
	for key in ["schema_version", "run_seed", "revision", "saved_at_unix", "last_seen_wall_unix", "last_settled_unix", "offline_anchor_unix"]:
		if typeof(data[key]) != TYPE_INT:
			return "%s must be int" % key
	for key in ["content_version", "save_id"]:
		if typeof(data[key]) != TYPE_STRING:
			return "%s must be string" % key
	if int(data["schema_version"]) != CURRENT_SCHEMA_VERSION:
		return "unsupported schema_version"
	if typeof(data["roster"]) != TYPE_ARRAY:
		return "roster must be array"
	if (data["roster"] as Array).size() < 6:
		return "v2 roster requires at least 6 heroes"
	for hero_data in data["roster"]:
		if typeof(hero_data) != TYPE_DICTIONARY:
			return "hero must be dictionary"
		var hero_error := _validate_hero_schema(hero_data as Dictionary)
		if not hero_error.is_empty():
			return hero_error
	var formation_error := _validate_string_dict(data["formation"], FORMATION_KEYS, "Formation")
	if not formation_error.is_empty():
		return formation_error
	var economy_error := _validate_int_dict(data["economy"], ECONOMY_KEYS, "Economy")
	if not economy_error.is_empty():
		return economy_error
	var factory_error := _validate_factory_schema(data["factory"])
	if not factory_error.is_empty():
		return factory_error
	var placeholder_error := _validate_placeholders(data)
	if not placeholder_error.is_empty():
		return placeholder_error
	return ""


static func _validate_hero_schema(data: Dictionary) -> String:
	var key_error := _exact_keys(data, HERO_KEYS, "HeroState")
	if not key_error.is_empty():
		return key_error
	for key in ["hero_id", "display_name", "class_id", "archetype_id", "aptitude_id", "seed_token"]:
		if typeof(data[key]) != TYPE_STRING:
			return "HeroState.%s must be string" % key
	if not HeroGenerator.CLASS_IDS.has(String(data["class_id"])):
		return "HeroState.class_id invalid"
	if not HeroGenerator.APTITUDE_IDS.has(String(data["aptitude_id"])):
		return "HeroState.aptitude_id invalid"
	if not HeroGenerator.ARCHETYPE_IDS.has(String(data["archetype_id"])):
		return "HeroState.archetype_id invalid"
	for key in ["level", "xp", "star"]:
		if typeof(data[key]) != TYPE_INT:
			return "HeroState.%s must be int" % key
	for key in ["trait_ids", "skill_ids"]:
		if typeof(data[key]) != TYPE_ARRAY:
			return "HeroState.%s must be array" % key
		for id_value in data[key]:
			if typeof(id_value) != TYPE_STRING:
				return "HeroState.%s entries must be string" % key
			if key == "trait_ids" and not HeroGenerator.TRAIT_IDS.has(String(id_value)):
				return "HeroState.trait_ids invalid"
	var equipment_error := _validate_string_dict(data["equipment_by_slot"], EQUIPMENT_SLOT_KEYS, "HeroState.equipment_by_slot")
	if not equipment_error.is_empty():
		return equipment_error
	var base_error := _validate_int_dict(data["base_stats"], ATTR_KEYS, "HeroState.base_stats")
	if not base_error.is_empty():
		return base_error
	return _validate_int_dict(data["stat_remainders"], ATTR_KEYS, "HeroState.stat_remainders")


static func _validate_factory_schema(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "Factory must be dictionary"
	var factory := value as Dictionary
	var key_error := _exact_keys(factory, FACTORY_KEYS, "Factory")
	if not key_error.is_empty():
		return key_error
	var materials_error := _validate_int_dict(factory["materials"], FactoryStateScript.MATERIAL_KEYS, "Factory.materials")
	if not materials_error.is_empty():
		return materials_error
	if typeof(factory["blueprints"]) != TYPE_DICTIONARY:
		return "Factory.blueprints must be dictionary"
	for key in (factory["blueprints"] as Dictionary).keys():
		if typeof(key) != TYPE_STRING or typeof(factory["blueprints"][key]) != TYPE_BOOL:
			return "Factory.blueprints entries must be string to bool"
	if typeof(factory["production_queue"]) != TYPE_ARRAY:
		return "Factory.production_queue must be array"
	for entry in factory["production_queue"]:
		if typeof(entry) != TYPE_DICTIONARY:
			return "Factory production entry must be dictionary"
		var entry_dict := entry as Dictionary
		var entry_error := _exact_keys(entry_dict, PRODUCTION_KEYS, "Factory.production")
		if not entry_error.is_empty():
			return entry_error
		for key in ["order_id", "recipe_id"]:
			if typeof(entry_dict[key]) != TYPE_STRING:
				return "Factory.production.%s must be string" % key
		for key in ["started_at_unix", "completes_at_unix"]:
			if typeof(entry_dict[key]) != TYPE_INT:
				return "Factory.production.%s must be int" % key
	if typeof(factory["next_sequence"]) != TYPE_INT:
		return "Factory.next_sequence must be int"
	if typeof(factory["next_hero_sequence"]) != TYPE_INT:
		return "Factory.next_hero_sequence must be int"
	return ""


static func _validate_v1_game_schema(data: Dictionary) -> String:
	var key_error := _exact_keys(data, V1_GAME_KEYS, "GameStateV1")
	if not key_error.is_empty():
		return key_error
	for key in ["schema_version", "run_seed", "revision", "saved_at_unix", "last_seen_wall_unix", "last_settled_unix", "offline_anchor_unix"]:
		if typeof(data[key]) != TYPE_INT:
			return "%s must be int" % key
	for key in ["content_version", "save_id"]:
		if typeof(data[key]) != TYPE_STRING:
			return "%s must be string" % key
	if int(data["schema_version"]) != 1:
		return "unsupported schema_version"
	if typeof(data["roster"]) != TYPE_ARRAY:
		return "roster must be array"
	if (data["roster"] as Array).size() < 4:
		return "v1 roster requires at least 4 heroes"
	for hero_data in data["roster"]:
		if typeof(hero_data) != TYPE_DICTIONARY:
			return "hero must be dictionary"
		var hero_error := _validate_v1_hero_schema(hero_data as Dictionary)
		if not hero_error.is_empty():
			return hero_error
	var formation_error := _validate_string_dict(data["formation"], V1_FORMATION_KEYS, "FormationV1")
	if not formation_error.is_empty():
		return formation_error
	var economy_error := _validate_int_dict(data["economy"], ECONOMY_KEYS, "Economy")
	if not economy_error.is_empty():
		return economy_error
	var placeholder_data := data.duplicate(true)
	placeholder_data["auto_skill_preferences"] = {}
	return _validate_placeholders(placeholder_data)


static func _validate_v2_game_schema(data: Dictionary) -> String:
	var key_error := _exact_keys(data, V2_GAME_KEYS, "GameStateV2")
	if not key_error.is_empty():
		return key_error
	for key in ["schema_version", "run_seed", "revision", "saved_at_unix", "last_seen_wall_unix", "last_settled_unix", "offline_anchor_unix"]:
		if typeof(data[key]) != TYPE_INT:
			return "%s must be int" % key
	for key in ["content_version", "save_id"]:
		if typeof(data[key]) != TYPE_STRING:
			return "%s must be string" % key
	if int(data["schema_version"]) != 2:
		return "unsupported schema_version"
	if typeof(data["roster"]) != TYPE_ARRAY:
		return "roster must be array"
	if (data["roster"] as Array).size() < 6:
		return "v2 roster requires at least 6 heroes"
	for hero_data in data["roster"]:
		if typeof(hero_data) != TYPE_DICTIONARY:
			return "hero must be dictionary"
		var hero_error := _validate_v2_hero_schema(hero_data as Dictionary)
		if not hero_error.is_empty():
			return hero_error
	var formation_error := _validate_string_dict(data["formation"], FORMATION_KEYS, "FormationV2")
	if not formation_error.is_empty():
		return formation_error
	var economy_error := _validate_int_dict(data["economy"], ECONOMY_KEYS, "Economy")
	if not economy_error.is_empty():
		return economy_error
	var factory_error := _validate_factory_schema(data["factory"])
	if not factory_error.is_empty():
		return factory_error
	var placeholder_data := data.duplicate(true)
	placeholder_data["auto_skill_preferences"] = {}
	var placeholder_error := _validate_placeholders(placeholder_data)
	if not placeholder_error.is_empty():
		return placeholder_error
	return ""


static func _validate_v2_hero_schema(data: Dictionary) -> String:
	var key_error := _exact_keys(data, V2_HERO_KEYS, "HeroStateV2")
	if not key_error.is_empty():
		return key_error
	var migrated := data.duplicate(true)
	migrated["auto_skill_enabled"] = false
	return _validate_hero_schema(migrated)


static func _validate_v1_hero_schema(data: Dictionary) -> String:
	var key_error := _exact_keys(data, V1_HERO_KEYS, "HeroStateV1")
	if not key_error.is_empty():
		return key_error
	var migrated := data.duplicate(true)
	migrated["archetype_id"] = _legacy_archetype(String(data["class_id"]))
	migrated["star"] = 1
	migrated["auto_skill_enabled"] = false
	return _validate_hero_schema(migrated)


static func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["schema_version"] = 2
	migrated["content_version"] = "factory-siege-v2"
	var roster := migrated["roster"] as Array
	for hero_data in roster:
		hero_data["archetype_id"] = _legacy_archetype(String(hero_data["class_id"]))
		hero_data["star"] = 1
		hero_data.erase("auto_skill_enabled")
	var run_seed := int(migrated["run_seed"])
	for index in range(roster.size(), 8):
		var generated: Dictionary = HeroGenerator.generate_archetype(
			run_seed,
			index,
			HeroGenerator.INITIAL_ARCHETYPES[index],
			HeroGenerator.INITIAL_CLASSES[index]
		).to_dict()
		generated.erase("auto_skill_enabled")
		roster.append(generated)
	var old_formation := migrated["formation"] as Dictionary
	migrated["formation"] = {
		"front_left": String(old_formation["front_left"]),
		"front_center": String(roster[4]["hero_id"]),
		"front_right": String(old_formation["front_right"]),
		"back_left": String(old_formation["back_left"]),
		"back_center": String(roster[5]["hero_id"]),
		"back_right": String(old_formation["back_right"]),
	}
	var factory := FactoryStateScript.create_starting()
	factory.next_hero_sequence = roster.size() + 1
	migrated["factory"] = factory.to_dict()
	return migrated


static func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["schema_version"] = 3
	migrated["content_version"] = "factory-siege-v3"
	migrated["auto_skill_preferences"] = {}
	for hero_data in migrated["roster"]:
		(hero_data as Dictionary)["auto_skill_enabled"] = false
	var factory := FactoryStateScript.create_starting()
	var old_factory := migrated["factory"] as Dictionary
	factory.materials = (old_factory["materials"] as Dictionary).duplicate(true)
	factory.production_queue = []
	for entry in old_factory["production_queue"]:
		factory.production_queue.append((entry as Dictionary).duplicate(true))
	factory.next_sequence = int(old_factory["next_sequence"])
	factory.next_hero_sequence = int(old_factory["next_hero_sequence"])
	var old_blueprints := old_factory["blueprints"] as Dictionary
	for recipe_id in old_blueprints.keys():
		if bool(old_blueprints[recipe_id]):
			factory.blueprints[String(recipe_id)] = true
	migrated["factory"] = factory.to_dict()
	return migrated


static func _legacy_archetype(class_id: String) -> String:
	match class_id:
		"guardian":
			return "armored"
		"fighter":
			return "assault"
		"ranger":
			return "rocket"
		"arcanist":
			return "sonic"
		_:
			return "assault"


static func _validate_placeholders(data: Dictionary) -> String:
	var dict_keys: Array[String] = ["inventory", "camp", "quests", "pity", "stage_progress", "auto_skill_preferences", "attempt_counters", "receipt_ledgers", "command_receipts", "business_receipts"]
	for key in dict_keys:
		if typeof(data[key]) != TYPE_DICTIONARY:
			return "%s must be dictionary" % key
	var inventory_error := _exact_keys(data["inventory"] as Dictionary, ["items"], "inventory")
	if not inventory_error.is_empty():
		return inventory_error
	var camp_error := _validate_int_dict(data["camp"], ["tavern_level", "blacksmith_level", "training_ground_level"], "camp")
	if not camp_error.is_empty():
		return camp_error
	var quest_error := _validate_dict_dict(data["quests"], ["active", "completed", "claimed"], "quests")
	if not quest_error.is_empty():
		return quest_error
	var pity := data["pity"] as Dictionary
	var pity_error := _exact_keys(pity, ["qualifying_drops_since_blue", "guaranteed_blue_consumed"], "pity")
	if not pity_error.is_empty():
		return pity_error
	if typeof(pity["qualifying_drops_since_blue"]) != TYPE_INT or typeof(pity["guaranteed_blue_consumed"]) != TYPE_BOOL:
		return "pity field types invalid"
	var progress := data["stage_progress"] as Dictionary
	var progress_error := _exact_keys(progress, ["highest_unlocked_stage", "cleared_stages"], "stage_progress")
	if not progress_error.is_empty():
		return progress_error
	if typeof(progress["highest_unlocked_stage"]) != TYPE_STRING or typeof(progress["cleared_stages"]) != TYPE_ARRAY:
		return "stage_progress field types invalid"
	for hero_id in (data["auto_skill_preferences"] as Dictionary).keys():
		if typeof(hero_id) != TYPE_STRING or typeof((data["auto_skill_preferences"] as Dictionary)[hero_id]) != TYPE_BOOL:
			return "auto_skill_preferences must be string to bool"
	return _validate_dict_dict(data["receipt_ledgers"], ["durable", "reversible"], "receipt_ledgers")


static func _validate_string_dict(value: Variant, keys: Array[String], label: String) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "%s must be dictionary" % label
	var dict := value as Dictionary
	var key_error := _exact_keys(dict, keys, label)
	if not key_error.is_empty():
		return key_error
	for key in keys:
		if typeof(dict[key]) != TYPE_STRING:
			return "%s.%s must be string" % [label, key]
	return ""


static func _validate_int_dict(value: Variant, keys: Array[String], label: String) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "%s must be dictionary" % label
	var dict := value as Dictionary
	var key_error := _exact_keys(dict, keys, label)
	if not key_error.is_empty():
		return key_error
	for key in keys:
		if typeof(dict[key]) != TYPE_INT:
			return "%s.%s must be int" % [label, key]
	return ""


static func _validate_dict_dict(value: Variant, keys: Array[String], label: String) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "%s must be dictionary" % label
	var dict := value as Dictionary
	var key_error := _exact_keys(dict, keys, label)
	if not key_error.is_empty():
		return key_error
	for key in keys:
		if typeof(dict[key]) != TYPE_DICTIONARY:
			return "%s.%s must be dictionary" % [label, key]
	return ""


static func _exact_keys(dict: Dictionary, expected: Array[String], label: String) -> String:
	var actual: Array[String] = []
	for key in dict.keys():
		if typeof(key) != TYPE_STRING:
			return "%s has non-string key" % label
		actual.append(String(key))
	actual.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	if actual != sorted_expected:
		return "%s keys mismatch expected=%s actual=%s" % [label, str(sorted_expected), str(actual)]
	return ""

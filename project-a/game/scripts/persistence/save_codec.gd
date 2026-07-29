class_name SaveCodec
extends RefCounted

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")

const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const CURRENT_SCHEMA_VERSION: int = 11
const GAME_KEYS: Array[String] = [
	"schema_version", "content_version", "save_id", "run_seed", "revision",
	"roster", "inventory", "formation", "economy", "factory", "camp", "quests", "pity",
	"stage_progress", "auto_skill_preferences", "attempt_counters", "receipt_ledgers", "command_receipts",
	"business_receipts", "achievements", "saved_at_unix", "last_seen_wall_unix",
	"last_settled_unix", "offline_anchor_unix", "onboarding", "meta_progression"
]
const ACHIEVEMENT_KEYS: Array[String] = ["progress", "completed", "claimed", "event_keys", "counters"]
const HERO_KEYS: Array[String] = [
	"hero_id", "display_name", "class_id", "archetype_id", "star", "aptitude_id", "trait_ids",
	"skill_ids", "auto_skill_enabled", "equipment_by_slot", "level", "xp", "base_stats",
	"stat_remainders", "seed_token", "readiness", "injury_flags", "assigned_facility_id", "active_skill_level"
]
const FORMATION_KEYS: Array[String] = ["commander", "troop_1", "troop_2", "troop_3", "troop_4", "troop_5", "troop_6"]
const ECONOMY_KEYS: Array[String] = ["toilet_coins", "toilet_gems", "gold", "recruit_tickets", "xp_books", "forge_stones", "industrial_tech", "skill_chips", "hero_shards"]
const FACTORY_KEYS: Array[String] = ["materials", "capacities", "discovered_blueprints", "blueprints", "blueprint_data", "model_tech_stars", "blueprint_research", "production_queue", "next_sequence", "next_hero_sequence", "eligible_facilities", "facilities", "facility_placements", "logistics_anchor_unix", "facility_output_anchors", "repair_orders", "next_repair_sequence", "facility_work"]
const PRODUCTION_KEYS: Array[String] = ["order_id", "recipe_id", "started_at_unix", "completes_at_unix"]
const REPAIR_ORDER_KEYS: Array[String] = ["order_id", "hero_id", "started_at_unix", "completes_at_unix", "target_readiness"]
const BLUEPRINT_RESEARCH_KEYS: Array[String] = ["recipe_id", "started_at_unix", "completes_at_unix"]
const FACILITY_WORK_KEYS: Array[String] = ["work_type", "facility_id", "started_at_unix", "completes_at_unix", "target_level", "grid_x", "grid_z"]
const ATTR_KEYS: Array[String] = ["hp", "attack", "defense", "speed_milli", "crit_bp"]
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
const V3_GAME_KEYS: Array[String] = [
	"schema_version", "content_version", "save_id", "run_seed", "revision",
	"roster", "inventory", "formation", "economy", "factory", "camp", "quests", "pity",
	"stage_progress", "auto_skill_preferences", "attempt_counters", "receipt_ledgers", "command_receipts",
	"business_receipts", "saved_at_unix", "last_seen_wall_unix",
	"last_settled_unix", "offline_anchor_unix"
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
	if not [5, 6, 7, 8, 9, 10, CURRENT_SCHEMA_VERSION].has(int(dict["schema_version"])):
		return {"ok": false, "error": "存档版本不受支持；请清除本地存档后重新开始Gman战役"}
	if int(dict["schema_version"]) == 8:
		var migration_input_error := _validate_v8_resource_migration_inputs(dict)
		if not migration_input_error.is_empty():
			return {"ok": false, "error": migration_input_error}
	dict = _upgrade_legacy_v5_factory_loop(dict)
	_normalize_direct_research_lab_eligibility(dict)
	var schema_error := _validate_game_schema(dict)
	if not schema_error.is_empty():
		return {"ok": false, "error": schema_error}
	var state := GameStateScript.from_dict(dict)
	_refresh_roster_display_names(state)
	var errors := state.validate()
	if not errors.is_empty():
		return {"ok": false, "error": "; ".join(errors)}
	return {"ok": true, "state": state}


static func _refresh_roster_display_names(state: RefCounted) -> void:
	for hero in state.roster:
		var persisted_name := String(hero.display_name)
		if persisted_name.is_empty():
			continue
		var archetype_id := String(hero.archetype_id)
		var current_name := HeroGenerator.archetype_display_name(archetype_id)
		var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
		if not recipe.is_empty():
			current_name = String(recipe.get("display_name", current_name))
		for separator in [" · ", " ★"]:
			var suffix_at := persisted_name.find(separator)
			if suffix_at >= 0:
				current_name += persisted_name.substr(suffix_at)
				break
		hero.display_name = current_name


static func _normalize_direct_research_lab_eligibility(data: Dictionary) -> void:
	if typeof(data.get("factory")) != TYPE_DICTIONARY:
		return
	var factory := data["factory"] as Dictionary
	if typeof(factory.get("facilities")) != TYPE_DICTIONARY:
		return
	var facilities := factory["facilities"] as Dictionary
	if typeof(facilities.get("research_lab")) != TYPE_INT or int(facilities["research_lab"]) != 0:
		return
	if typeof(factory.get("eligible_facilities")) != TYPE_DICTIONARY:
		return
	(factory["eligible_facilities"] as Dictionary)["research_lab"] = true


static func _upgrade_legacy_v5_factory_loop(data: Dictionary) -> Dictionary:
	var upgraded := data.duplicate(true)
	var source_schema := int(data.get("schema_version", 0))
	var was_legacy_v5 := source_schema == 5
	upgraded["schema_version"] = source_schema
	if was_legacy_v5:
		upgraded["content_version"] = "toilet-factory-siege-v6"
	if not upgraded.has("meta_progression"):
		upgraded["meta_progression"] = {
			"commander_xp": 0, "commander_claimed_levels": {}, "daily_generation": 0, "weekly_generation": 0,
			"daily_key": "", "weekly_key": "", "missions": {}, "mission_claims": {},
			"season_id": "season_1", "season_merit": 0, "pass_claimed_levels": {},
			"achievement_progress": {}, "achievement_claimed": {}, "event_keys": {},
			"recruit_draw_count": 0, "recruit_s_pity": 0, "recruit_a_pity": 0,
			"recruit_target_guaranteed": false, "recruit_pool_id": "signal_standard_1",
			"hero_data": {},
			"hero_fragments": {},
		}
	elif not (upgraded["meta_progression"] as Dictionary).has("commander_claimed_levels"):
		(upgraded["meta_progression"] as Dictionary)["commander_claimed_levels"] = {}
	if not upgraded.has("onboarding"):
		upgraded["onboarding"] = {"catalog_version": 2, "active_index": 0, "progress": {}, "completed": {}, "claimed": {}, "event_keys": {}}
	elif not (upgraded["onboarding"] as Dictionary).has("catalog_version"):
		(upgraded["onboarding"] as Dictionary)["catalog_version"] = 0
	for hero_value in upgraded.get("roster", []):
		var hero := hero_value as Dictionary
		hero["readiness"] = int(hero.get("readiness", 100))
		hero["injury_flags"] = (hero.get("injury_flags", []) as Array).duplicate()
		hero["assigned_facility_id"] = String(hero.get("assigned_facility_id", ""))
		hero["active_skill_level"] = int(hero.get("active_skill_level", 1))
	var economy := (upgraded.get("economy", {}) as Dictionary).duplicate(true)
	if not economy.has("toilet_coins"):
		economy["toilet_coins"] = int(economy.get("gold", 0))
	if not economy.has("toilet_gems"):
		economy["toilet_gems"] = 0
	economy["industrial_tech"] = int(economy.get("industrial_tech", 0))
	economy["skill_chips"] = int(economy.get("skill_chips", 0))
	economy["hero_shards"] = int(economy.get("hero_shards", 0))
	upgraded["economy"] = economy
	var factory := (upgraded.get("factory", {}) as Dictionary).duplicate(true)
	if not factory.has("facility_work"):
		factory["facility_work"] = {}
	if not factory.has("blueprint_data"):
		factory["blueprint_data"] = {}
	if not factory.has("model_tech_stars"):
		var stars: Dictionary = {}
		for recipe_id in (factory.get("blueprints", {}) as Dictionary).keys():
			if bool((factory["blueprints"] as Dictionary)[recipe_id]):
				stars[String(recipe_id)] = 1
		factory["model_tech_stars"] = stars
	factory["facilities"] = (factory.get("facilities", {
		"command_center": 1,
		"porcelain_plant": 1,
		"parts_workshop": 1,
		"energy_station": 1,
		"repair_center": 1,
		"research_lab": 1,
		"coin_mint": 0,
	}) as Dictionary).duplicate(true)
	if not (factory["facilities"] as Dictionary).has("coin_mint"):
		(factory["facilities"] as Dictionary)["coin_mint"] = 0
	factory["eligible_facilities"] = (factory.get("eligible_facilities", {}) as Dictionary).duplicate(true)
	if not factory.has("facility_placements"):
		var legacy_placements := {
			"command_center": [0, -1],
			"porcelain_plant": [-2, -1],
			"parts_workshop": [2, -1],
			"energy_station": [-2, 1],
			"repair_center": [0, 1],
			"research_lab": [2, 1],
		}
		factory["facility_placements"] = {}
		for facility_id in legacy_placements:
			if int((factory["facilities"] as Dictionary).get(facility_id, 0)) > 0:
				(factory["facility_placements"] as Dictionary)[facility_id] = legacy_placements[facility_id]
	factory["logistics_anchor_unix"] = int(factory.get("logistics_anchor_unix", upgraded.get("last_seen_wall_unix", 0)))
	factory["facility_output_anchors"] = (factory.get("facility_output_anchors", {
		"porcelain_plant": factory["logistics_anchor_unix"],
		"parts_workshop": factory["logistics_anchor_unix"],
		"energy_station": factory["logistics_anchor_unix"],
		"coin_mint": factory["logistics_anchor_unix"],
	}) as Dictionary).duplicate(true)
	if not (factory["facility_output_anchors"] as Dictionary).has("coin_mint"):
		(factory["facility_output_anchors"] as Dictionary)["coin_mint"] = factory["logistics_anchor_unix"]
	factory["repair_orders"] = (factory.get("repair_orders", []) as Array).duplicate(true)
	factory["next_repair_sequence"] = int(factory.get("next_repair_sequence", 1))
	if not factory.has("capacities"):
		factory["capacities"] = FactoryStateScript.from_dict(factory).capacities.duplicate(true)
	upgraded["factory"] = factory
	var pity := (upgraded.get("pity", {}) as Dictionary).duplicate(true)
	pity["blueprint_draw_count"] = int(pity.get("blueprint_draw_count", 0))
	pity["s_pity_count"] = int(pity.get("s_pity_count", 0))
	pity["pool_id"] = String(pity.get("pool_id", "standard_s"))
	pity["target_s_recipe_id"] = String(pity.get("target_s_recipe_id", "special.parasite"))
	upgraded["pity"] = pity
	if was_legacy_v5:
		upgraded["quests"] = {"active": {}, "completed": {}, "claimed": {}}
		upgraded["achievements"] = {"progress": {}, "completed": {}, "claimed": {}, "event_keys": {}, "counters": {}}
	if source_schema < 9:
		upgraded = _migrate_v8_resources_to_v9(upgraded)
	if source_schema < 10:
		upgraded = _migrate_v9_hero_stats_to_v10(upgraded)
	if source_schema < CURRENT_SCHEMA_VERSION:
		upgraded = _migrate_v10_factions_to_v11(upgraded)
	return upgraded


static func _migrate_v8_resources_to_v9(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["schema_version"] = 9

	var economy := (migrated.get("economy", {}) as Dictionary).duplicate(true)
	var factory := (migrated.get("factory", {}) as Dictionary).duplicate(true)
	var materials := (factory.get("materials", {}) as Dictionary).duplicate(true)
	var meta := (migrated.get("meta_progression", {}) as Dictionary).duplicate(true)

	var weighted_materials := (
		2 * int(materials.get("porcelain", 0))
		+ 4 * int(materials.get("parts", 0))
		+ 3 * int(materials.get("sludge", 0))
	)
	var industrial_materials := (
		int(round(float(weighted_materials) / 4.0))
		+ 3 * int(economy.get("industrial_tech", 0))
	)
	var legion_data := (
		int(economy.get("hero_shards", 0))
		+ 4 * int(economy.get("skill_chips", 0))
		+ _sum_int_values(factory.get("blueprint_data", {}))
		+ _sum_int_values(meta.get("hero_data", {}))
	)
	var converted_tickets := int(economy.get("toilet_gems", 0)) / 10

	economy["recruit_tickets"] = int(economy.get("recruit_tickets", 0)) + converted_tickets
	economy["hero_shards"] = legion_data
	economy["toilet_gems"] = 0
	economy["gold"] = 0
	economy["xp_books"] = 0
	economy["forge_stones"] = 0
	economy["industrial_tech"] = 0
	economy["skill_chips"] = 0

	factory["materials"] = {
		"porcelain": industrial_materials,
		"parts": 0,
		"sludge": 0,
	}
	factory["blueprint_data"] = {}
	var normalized_factory := FactoryStateScript.from_dict(factory)
	normalized_factory.refresh_capacities()
	factory["capacities"] = normalized_factory.capacities.duplicate(true)

	meta["hero_data"] = {}
	migrated["economy"] = economy
	migrated["factory"] = factory
	migrated["meta_progression"] = meta
	return migrated


static func _migrate_v9_hero_stats_to_v10(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	for hero_value in migrated.get("roster", []):
		var hero := hero_value as Dictionary
		var legacy := hero.get("base_stats", {}) as Dictionary
		var vig := int(legacy.get("vig", 0))
		var str_stat := int(legacy.get("str", 0))
		var agi := int(legacy.get("agi", 0))
		var int_stat := int(legacy.get("int", 0))
		hero["base_stats"] = {
			"hp": 50 + vig * 10,
			"attack": maxi(str_stat, int_stat) * 3,
			"defense": _legacy_class_armor(String(hero.get("class_id", ""))) + vig * 2,
			"speed_milli": 60000 + agi * 4000,
			"crit_bp": clampi(500 + agi * 50, 0, 5000),
		}
		hero["stat_remainders"] = {
			"hp": 0, "attack": 0, "defense": 0, "speed_milli": 0, "crit_bp": 0,
		}
	migrated["schema_version"] = 10
	return migrated


static func _migrate_v10_factions_to_v11(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var meta := (migrated.get("meta_progression", {}) as Dictionary).duplicate(true)
	meta["hero_fragments"] = (meta.get("hero_fragments", {}) as Dictionary).duplicate(true)
	migrated["meta_progression"] = meta
	migrated["schema_version"] = CURRENT_SCHEMA_VERSION
	migrated["content_version"] = "toilet-factory-slg-v3-factions"
	return migrated


static func _legacy_class_armor(class_id: String) -> int:
	match class_id:
		"guardian":
			return 12
		"fighter":
			return 8
		"ranger":
			return 5
		"arcanist":
			return 3
		_:
			return 0


static func _validate_v8_resource_migration_inputs(data: Dictionary) -> String:
	if typeof(data.get("economy")) != TYPE_DICTIONARY:
		return "Economy must be dictionary"
	var economy := data["economy"] as Dictionary
	for key in ECONOMY_KEYS:
		if not economy.has(key) or typeof(economy[key]) != TYPE_INT:
			return "Economy.%s must be int" % key
		if int(economy[key]) < 0:
			return "Economy.%s must not be negative" % key
	if typeof(data.get("factory")) != TYPE_DICTIONARY:
		return "Factory must be dictionary"
	var factory := data["factory"] as Dictionary
	if typeof(factory.get("materials")) != TYPE_DICTIONARY:
		return "Factory.materials must be dictionary"
	var materials := factory["materials"] as Dictionary
	for key in FactoryStateScript.MATERIAL_KEYS:
		if not materials.has(key) or typeof(materials[key]) != TYPE_INT:
			return "Factory.materials.%s must be int" % key
		if int(materials[key]) < 0:
			return "Factory.materials.%s must not be negative" % key
	var blueprint_data_error := _validate_non_negative_int_values(
		factory.get("blueprint_data"),
		"Factory.blueprint_data"
	)
	if not blueprint_data_error.is_empty():
		return blueprint_data_error
	for recipe_id in (factory["blueprint_data"] as Dictionary).keys():
		if not FactoryCatalogScript.has_recipe(String(recipe_id)):
			return "Factory.blueprint_data contains unknown recipe %s" % String(recipe_id)
	if typeof(data.get("meta_progression")) != TYPE_DICTIONARY:
		return "meta_progression must be dictionary"
	var hero_data: Variant = (data["meta_progression"] as Dictionary).get("hero_data")
	var hero_data_error := _validate_non_negative_int_values(
		hero_data,
		"meta_progression.hero_data"
	)
	if not hero_data_error.is_empty():
		return hero_data_error
	for archetype_id in (hero_data as Dictionary).keys():
		if (
			FactoryCatalogScript.archetype(String(archetype_id)).is_empty()
			and not FactoryCatalogScript.has_recipe(String(archetype_id))
		):
			return "meta_progression.hero_data contains unknown archetype %s" % String(archetype_id)
	return ""


static func _validate_non_negative_int_values(value: Variant, label: String) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "%s must be dictionary" % label
	for entry in (value as Dictionary).values():
		if typeof(entry) != TYPE_INT:
			return "%s values must be int" % label
		if int(entry) < 0:
			return "%s values must not be negative" % label
	return ""


static func _validate_v9_consolidated_resources(data: Dictionary) -> String:
	var economy := data["economy"] as Dictionary
	for key in ["toilet_gems", "gold", "xp_books", "forge_stones", "industrial_tech", "skill_chips"]:
		if int(economy[key]) != 0:
			return "Economy.%s must be zero in schema v9" % key
	var factory := data["factory"] as Dictionary
	var materials := factory["materials"] as Dictionary
	for key in ["parts", "sludge"]:
		if int(materials[key]) != 0:
			return "Factory.materials.%s must be zero in schema v9" % key
	if not (factory["blueprint_data"] as Dictionary).is_empty():
		return "Factory.blueprint_data must be empty in schema v9"
	if not ((data["meta_progression"] as Dictionary)["hero_data"] as Dictionary).is_empty():
		return "meta_progression.hero_data must be empty in schema v9"
	var expected_capacities := FactoryStateScript.capacities_for_facilities(
		factory["facilities"] as Dictionary
	)
	if factory["capacities"] != expected_capacities:
		return "Factory.capacities must match active resource line levels in schema v9"
	return ""


static func _sum_int_values(value: Variant) -> int:
	if typeof(value) != TYPE_DICTIONARY:
		return 0
	var total := 0
	for entry in (value as Dictionary).values():
		total += int(entry)
	return total


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
	var achievements_error := _validate_achievements_schema(data["achievements"])
	if not achievements_error.is_empty():
		return achievements_error
	if typeof(data["onboarding"]) != TYPE_DICTIONARY:
		return "onboarding must be dictionary"
	var onboarding := data["onboarding"] as Dictionary
	var onboarding_key_error := _exact_keys(onboarding, ["catalog_version", "active_index", "progress", "completed", "claimed", "event_keys"], "onboarding")
	if not onboarding_key_error.is_empty():
		return onboarding_key_error
	if typeof(onboarding["active_index"]) != TYPE_INT:
		return "onboarding.active_index must be int"
	if typeof(onboarding["catalog_version"]) != TYPE_INT:
		return "onboarding.catalog_version must be int"
	for key in ["progress", "completed", "claimed", "event_keys"]:
		if typeof(onboarding[key]) != TYPE_DICTIONARY:
			return "onboarding.%s must be dictionary" % key
	var meta_error := _validate_meta_progression_schema(data["meta_progression"])
	if not meta_error.is_empty():
		return meta_error
	return _validate_v9_consolidated_resources(data)


static func _validate_meta_progression_schema(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "meta_progression must be dictionary"
	var meta := value as Dictionary
	var keys: Array[String] = [
		"commander_xp", "commander_claimed_levels", "daily_generation", "weekly_generation", "daily_key", "weekly_key",
		"missions", "mission_claims", "season_id", "season_merit", "pass_claimed_levels",
		"achievement_progress", "achievement_claimed", "event_keys", "recruit_draw_count",
		"recruit_s_pity", "recruit_a_pity", "recruit_target_guaranteed", "recruit_pool_id",
		"hero_data", "hero_fragments",
	]
	var key_error := _exact_keys(meta, keys, "meta_progression")
	if not key_error.is_empty():
		return key_error
	for key in ["commander_xp", "daily_generation", "weekly_generation", "season_merit", "recruit_draw_count", "recruit_s_pity", "recruit_a_pity"]:
		if typeof(meta[key]) != TYPE_INT:
			return "meta_progression.%s must be int" % key
	for key in ["daily_key", "weekly_key", "season_id", "recruit_pool_id"]:
		if typeof(meta[key]) != TYPE_STRING:
			return "meta_progression.%s must be string" % key
	if typeof(meta["recruit_target_guaranteed"]) != TYPE_BOOL:
		return "meta_progression.recruit_target_guaranteed must be bool"
	for key in ["commander_claimed_levels", "missions", "mission_claims", "pass_claimed_levels", "achievement_progress", "achievement_claimed", "event_keys", "hero_data", "hero_fragments"]:
		if typeof(meta[key]) != TYPE_DICTIONARY:
			return "meta_progression.%s must be dictionary" % key
	for archetype_id_value in (meta["hero_fragments"] as Dictionary):
		if typeof(archetype_id_value) != TYPE_STRING:
			return "meta_progression.hero_fragments keys must be strings"
		var archetype_id := String(archetype_id_value)
		if FactoryCatalogScript.recipe_for_archetype(archetype_id).is_empty():
			return "meta_progression.hero_fragments contains unknown archetype %s" % archetype_id
		if (
			typeof((meta["hero_fragments"] as Dictionary)[archetype_id_value]) != TYPE_INT
			or int((meta["hero_fragments"] as Dictionary)[archetype_id_value]) < 0
		):
			return "meta_progression.hero_fragments values must be non-negative integers"
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
	for key in ["level", "xp", "star", "active_skill_level"]:
		if typeof(data[key]) != TYPE_INT:
			return "HeroState.%s must be int" % key
	if typeof(data["readiness"]) != TYPE_INT:
		return "HeroState.readiness must be int"
	if typeof(data["injury_flags"]) != TYPE_ARRAY:
		return "HeroState.injury_flags must be array"
	for flag in data["injury_flags"]:
		if typeof(flag) != TYPE_STRING:
			return "HeroState.injury_flags entries must be string"
	if typeof(data["assigned_facility_id"]) != TYPE_STRING:
		return "HeroState.assigned_facility_id must be string"
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
	var capacities_error := _validate_int_dict(factory["capacities"], ["porcelain", "parts", "sludge"], "Factory.capacities")
	if not capacities_error.is_empty():
		return capacities_error
	for dict_key in ["blueprint_data", "model_tech_stars"]:
		if typeof(factory[dict_key]) != TYPE_DICTIONARY:
			return "Factory.%s must be dictionary" % dict_key
		for key in (factory[dict_key] as Dictionary).keys():
			if typeof(key) != TYPE_STRING or typeof(factory[dict_key][key]) != TYPE_INT:
				return "Factory.%s entries must be string to int" % dict_key
	if typeof(factory["discovered_blueprints"]) != TYPE_DICTIONARY:
		return "Factory.discovered_blueprints must be dictionary"
	for key in (factory["discovered_blueprints"] as Dictionary).keys():
		if typeof(key) != TYPE_STRING or typeof(factory["discovered_blueprints"][key]) != TYPE_BOOL:
			return "Factory.discovered_blueprints entries must be string to bool"
	if typeof(factory["blueprint_research"]) != TYPE_DICTIONARY:
		return "Factory.blueprint_research must be dictionary"
	var research := factory["blueprint_research"] as Dictionary
	if not research.is_empty():
		var research_error := _exact_keys(research, BLUEPRINT_RESEARCH_KEYS, "Factory.blueprint_research")
		if not research_error.is_empty():
			return research_error
		if typeof(research["recipe_id"]) != TYPE_STRING:
			return "Factory.blueprint_research.recipe_id must be string"
		for key in ["started_at_unix", "completes_at_unix"]:
			if typeof(research[key]) != TYPE_INT:
				return "Factory.blueprint_research.%s must be int" % key
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
	if typeof(factory["eligible_facilities"]) != TYPE_DICTIONARY:
		return "Factory.eligible_facilities must be dictionary"
	for facility_id in (factory["eligible_facilities"] as Dictionary):
		if typeof(facility_id) != TYPE_STRING or not (factory["facilities"] as Dictionary).has(facility_id):
			return "Factory.eligible_facilities contains unknown facility"
		if typeof(factory["eligible_facilities"][facility_id]) != TYPE_BOOL or not bool(factory["eligible_facilities"][facility_id]):
			return "Factory.eligible_facilities entries must be true"
	var facilities_error := _validate_int_dict(factory["facilities"], [
		"command_center", "porcelain_plant", "parts_workshop",
		"energy_station", "repair_center", "research_lab", "coin_mint"
	], "Factory.facilities")
	if not facilities_error.is_empty():
		return facilities_error
	if typeof(factory["facility_placements"]) != TYPE_DICTIONARY:
		return "Factory.facility_placements must be dictionary"
	var occupied_cells: Dictionary = {}
	for facility_id in (factory["facility_placements"] as Dictionary):
		if typeof(facility_id) != TYPE_STRING or not (factory["facilities"] as Dictionary).has(facility_id):
			return "Factory.facility_placements contains unknown facility"
		var placement: Variant = factory["facility_placements"][facility_id]
		if typeof(placement) != TYPE_ARRAY or (placement as Array).size() != 2:
			return "Factory.facility_placements entries must be two-int arrays"
		if typeof(placement[0]) != TYPE_INT or typeof(placement[1]) != TYPE_INT:
			return "Factory.facility_placements coordinates must be ints"
		if abs(int(placement[0])) > 2 or abs(int(placement[1])) > 2:
			return "Factory.facility_placements coordinate is outside grid"
		var cell_key := "%d:%d" % [int(placement[0]), int(placement[1])]
		if occupied_cells.has(cell_key):
			return "Factory.facility_placements cells must be unique"
		occupied_cells[cell_key] = facility_id
	for facility_id in (factory["facilities"] as Dictionary):
		if int(factory["facilities"][facility_id]) > 0 and not (factory["facility_placements"] as Dictionary).has(facility_id):
			return "Factory.facility_placements missing built facility"
	if typeof(factory["logistics_anchor_unix"]) != TYPE_INT:
		return "Factory.logistics_anchor_unix must be int"
	var anchors_error := _validate_int_dict(factory["facility_output_anchors"], [
		"porcelain_plant", "parts_workshop", "energy_station", "coin_mint"
	], "Factory.facility_output_anchors")
	if not anchors_error.is_empty():
		return anchors_error
	if typeof(factory["next_repair_sequence"]) != TYPE_INT:
		return "Factory.next_repair_sequence must be int"
	if typeof(factory["repair_orders"]) != TYPE_ARRAY:
		return "Factory.repair_orders must be array"
	for entry in factory["repair_orders"]:
		if typeof(entry) != TYPE_DICTIONARY:
			return "Factory repair entry must be dictionary"
		var repair := entry as Dictionary
		var repair_error := _exact_keys(repair, REPAIR_ORDER_KEYS, "Factory.repair_order")
		if not repair_error.is_empty():
			return repair_error
		for key in ["order_id", "hero_id"]:
			if typeof(repair[key]) != TYPE_STRING:
				return "Factory.repair_order.%s must be string" % key
		for key in ["started_at_unix", "completes_at_unix", "target_readiness"]:
			if typeof(repair[key]) != TYPE_INT:
				return "Factory.repair_order.%s must be int" % key
	if typeof(factory["facility_work"]) != TYPE_DICTIONARY:
		return "Factory.facility_work must be dictionary"
	var facility_work := factory["facility_work"] as Dictionary
	if not facility_work.is_empty():
		var work_error := _exact_keys(facility_work, FACILITY_WORK_KEYS, "Factory.facility_work")
		if not work_error.is_empty():
			return work_error
		for key in ["work_type", "facility_id"]:
			if typeof(facility_work[key]) != TYPE_STRING:
				return "Factory.facility_work.%s must be string" % key
		for key in ["started_at_unix", "completes_at_unix", "target_level", "grid_x", "grid_z"]:
			if typeof(facility_work[key]) != TYPE_INT:
				return "Factory.facility_work.%s must be int" % key
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


static func _validate_v3_game_schema(data: Dictionary) -> String:
	var key_error := _exact_keys(data, V3_GAME_KEYS, "GameStateV3")
	if not key_error.is_empty():
		return key_error
	for key in ["schema_version", "run_seed", "revision", "saved_at_unix", "last_seen_wall_unix", "last_settled_unix", "offline_anchor_unix"]:
		if typeof(data[key]) != TYPE_INT:
			return "%s must be int" % key
	for key in ["content_version", "save_id"]:
		if typeof(data[key]) != TYPE_STRING:
			return "%s must be string" % key
	if int(data["schema_version"]) != 3:
		return "unsupported schema_version"
	if typeof(data["roster"]) != TYPE_ARRAY:
		return "roster must be array"
	if (data["roster"] as Array).size() < 6:
		return "v3 roster requires at least 6 heroes"
	for hero_data in data["roster"]:
		if typeof(hero_data) != TYPE_DICTIONARY:
			return "hero must be dictionary"
		var hero_error := _validate_hero_schema(hero_data as Dictionary)
		if not hero_error.is_empty():
			return hero_error
	var formation_error := _validate_string_dict(data["formation"], FORMATION_KEYS, "FormationV3")
	if not formation_error.is_empty():
		return formation_error
	var economy_error := _validate_int_dict(data["economy"], ECONOMY_KEYS, "Economy")
	if not economy_error.is_empty():
		return economy_error
	var factory_error := _validate_factory_schema(data["factory"])
	if not factory_error.is_empty():
		return factory_error
	return _validate_placeholders(data)


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


static func _migrate_v3_to_v4(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["schema_version"] = 4
	migrated["content_version"] = "factory-siege-v4"
	migrated["achievements"] = {"progress": {}, "completed": {}, "claimed": {}, "event_keys": {}, "counters": {}}
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
	var pity_error := _exact_keys(pity, ["qualifying_drops_since_blue", "guaranteed_blue_consumed", "blueprint_draw_count", "s_pity_count", "pool_id", "target_s_recipe_id"], "pity")
	if not pity_error.is_empty():
		return pity_error
	if typeof(pity["qualifying_drops_since_blue"]) != TYPE_INT or typeof(pity["guaranteed_blue_consumed"]) != TYPE_BOOL:
		return "pity field types invalid"
	for key in ["blueprint_draw_count", "s_pity_count"]:
		if typeof(pity[key]) != TYPE_INT or int(pity[key]) < 0:
			return "pity.%s must be non-negative int" % key
	for key in ["pool_id", "target_s_recipe_id"]:
		if typeof(pity[key]) != TYPE_STRING or String(pity[key]).is_empty():
			return "pity.%s must be non-empty string" % key
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


static func _validate_achievements_schema(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "achievements must be dictionary"
	return _validate_dict_dict(value, ACHIEVEMENT_KEYS, "achievements")


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

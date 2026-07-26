class_name HeroState
extends RefCounted

const ATTR_KEYS: Array[String] = ["vig", "str", "agi", "int"]

var hero_id: String = ""
var display_name: String = ""
var class_id: String = ""
var archetype_id: String = "assault"
var star: int = 1
var aptitude_id: String = ""
var trait_ids: Array[String] = []
var skill_ids: Array[String] = []
var active_skill_level: int = 1
var auto_skill_enabled: bool = false
var equipment_by_slot: Dictionary = {"weapon": "", "armor": "", "accessory": ""}
var level: int = 1
var xp: int = 0
var readiness: int = 100
var injury_flags: Array[String] = []
var assigned_facility_id: String = ""
var base_stats: Dictionary = {"vig": 0, "str": 0, "agi": 0, "int": 0}
var stat_remainders: Dictionary = {"vig": 0, "str": 0, "agi": 0, "int": 0}
var seed_token: String = ""


func deep_clone() -> HeroState:
	return HeroState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {
		"hero_id": hero_id,
		"display_name": display_name,
		"class_id": class_id,
		"archetype_id": archetype_id,
		"star": star,
		"aptitude_id": aptitude_id,
		"trait_ids": trait_ids.duplicate(),
		"skill_ids": skill_ids.duplicate(),
		"active_skill_level": active_skill_level,
		"auto_skill_enabled": auto_skill_enabled,
		"equipment_by_slot": equipment_by_slot.duplicate(true),
		"level": level,
		"xp": xp,
		"readiness": readiness,
		"injury_flags": injury_flags.duplicate(),
		"assigned_facility_id": assigned_facility_id,
		"base_stats": base_stats.duplicate(true),
		"stat_remainders": stat_remainders.duplicate(true),
		"seed_token": seed_token,
	}


static func from_dict(data: Dictionary) -> HeroState:
	var hero := HeroState.new()
	hero.hero_id = String(data.get("hero_id", ""))
	hero.display_name = String(data.get("display_name", ""))
	hero.class_id = String(data.get("class_id", ""))
	hero.archetype_id = String(data.get("archetype_id", "assault"))
	hero.star = int(data.get("star", 1))
	hero.aptitude_id = String(data.get("aptitude_id", ""))
	hero.trait_ids = []
	for trait_id_value in data.get("trait_ids", []):
		hero.trait_ids.append(String(trait_id_value))
	hero.skill_ids = []
	for skill_id_value in data.get("skill_ids", []):
		hero.skill_ids.append(String(skill_id_value))
	hero.active_skill_level = clampi(int(data.get("active_skill_level", 1)), 1, 3)
	hero.auto_skill_enabled = bool(data.get("auto_skill_enabled", false))
	hero.equipment_by_slot = {}
	var equipment_data := data.get("equipment_by_slot", {}) as Dictionary
	for slot in ["weapon", "armor", "accessory"]:
		hero.equipment_by_slot[slot] = String(equipment_data.get(slot, ""))
	hero.level = int(data.get("level", 1))
	hero.xp = int(data.get("xp", 0))
	# schema v8 兼容读取旧字段，但新规则下所有角色跨局始终无损。
	hero.readiness = 100
	hero.injury_flags = []
	hero.assigned_facility_id = String(data.get("assigned_facility_id", ""))
	hero.base_stats = _copy_int_dict(data.get("base_stats", {}))
	hero.stat_remainders = _copy_int_dict(data.get("stat_remainders", {}))
	hero.seed_token = String(data.get("seed_token", ""))
	return hero


static func _copy_int_dict(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in ATTR_KEYS:
		result[key] = int(data.get(key, 0))
	return result


func validate() -> Array[String]:
	var errors: Array[String] = []
	if hero_id.is_empty():
		errors.append("hero_id is required")
	if display_name.is_empty():
		errors.append("display_name is required")
	if class_id.is_empty():
		errors.append("class_id is required")
	if archetype_id.is_empty():
		errors.append("archetype_id is required")
	if star < 1 or star > 5:
		errors.append("star must be 1..5")
	if aptitude_id.is_empty():
		errors.append("aptitude_id is required")
	if level < 1 or level > 5:
		errors.append("level must be 1..5")
	if xp < 0 or xp > 320:
		errors.append("xp must be 0..320")
	if readiness < 0 or readiness > 100:
		errors.append("readiness must be 0..100")
	if active_skill_level < 1 or active_skill_level > 3:
		errors.append("active_skill_level must be 1..3")
	for key in ATTR_KEYS:
		if int(base_stats.get(key, -1)) < 0:
			errors.append("base_stats.%s must not be negative" % key)
		if int(stat_remainders.get(key, -1)) < 0:
			errors.append("stat_remainders.%s must not be negative" % key)
	return errors

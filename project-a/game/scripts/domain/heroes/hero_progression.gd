class_name HeroProgression
extends RefCounted


const HeroCatalogScript := preload("res://game/scripts/domain/heroes/hero_catalog.gd")
const ATTRIBUTE_KEYS: Array[String] = ["vig", "str", "agi", "int"]
const GROWTH_DENOMINATOR: int = 10_000_000


static func add_xp(hero: Dictionary, amount: int) -> Dictionary:
	var result: Dictionary = hero.duplicate(true)
	var old_level: int = clampi(int(result.get("level", 1)), 1, HeroCatalogScript.MAX_LEVEL)
	var old_xp: int = clampi(int(result.get("xp", 0)), 0, HeroCatalogScript.MAX_XP)
	var new_xp: int = clampi(old_xp + maxi(0, amount), 0, HeroCatalogScript.MAX_XP)
	var new_level: int = level_for_xp(new_xp)
	result["xp"] = new_xp
	result["level"] = new_level
	if new_level > old_level:
		_apply_level_growth(result, new_level - old_level)
	return result


static func level_for_xp(xp: int) -> int:
	var clamped_xp: int = clampi(xp, 0, HeroCatalogScript.MAX_XP)
	var level: int = 1
	for index: int in range(HeroCatalogScript.XP_THRESHOLDS.size()):
		if clamped_xp >= HeroCatalogScript.XP_THRESHOLDS[index]:
			level = index + 1
	return mini(level, HeroCatalogScript.MAX_LEVEL)


static func _apply_level_growth(hero: Dictionary, gained_levels: int) -> void:
	var class_id: String = str(hero.get("class_id", ""))
	var aptitude: String = str(hero.get("aptitude", "B"))
	if not HeroCatalogScript.CLASS_GROWTH_MILLI.has(class_id):
		return
	var growth: Dictionary = HeroCatalogScript.CLASS_GROWTH_MILLI[class_id]
	var aptitude_bp: int = int(HeroCatalogScript.APTITUDE_BP.get(aptitude, 10_000))
	var stats: Dictionary = hero.get("stats", {}).duplicate(true)
	var remainders: Dictionary = hero.get("growth_remainders", {}).duplicate(true)
	for attribute: String in ATTRIBUTE_KEYS:
		var numerator: int = int(remainders.get(attribute, 0))
		numerator += int(growth[attribute]) * aptitude_bp * gained_levels
		@warning_ignore("integer_division")
		var whole_growth: int = numerator / GROWTH_DENOMINATOR
		stats[attribute] = int(stats.get(attribute, 0)) + whole_growth
		remainders[attribute] = numerator % GROWTH_DENOMINATOR
	hero["stats"] = stats
	hero["growth_remainders"] = remainders

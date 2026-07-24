class_name HeroProgression
extends RefCounted

const HeroStateScript := preload("res://game/scripts/state/hero_state.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const XP_PER_BOOK: int = 20
const GOLD_PER_BOOK: int = 30
const MAX_XP: int = 320
const LEVEL_XP: Array[int] = [0, 0, 40, 100, 200, 320]
const APTITUDE_BP: Dictionary = {"C": 8500, "B": 10000, "A": 11500, "S": 13000}
const CLASS_GROWTH_MILLI: Dictionary = {
	"guardian": {"vig": 2000, "str": 800, "agi": 400, "int": 200},
	"fighter": {"vig": 1000, "str": 1800, "agi": 800, "int": 200},
	"ranger": {"vig": 600, "str": 800, "agi": 2000, "int": 400},
	"arcanist": {"vig": 500, "str": 300, "agi": 700, "int": 2100},
}
static func train_with_books(hero: RefCounted, book_count: int) -> void:
	if book_count <= 0:
		return
	var old_level: int = hero.level
	hero.xp = mini(MAX_XP, hero.xp + book_count * XP_PER_BOOK)
	hero.level = level_for_xp(hero.xp)
	for level_value in range(old_level + 1, hero.level + 1):
		_apply_level_growth(hero, level_value)


static func level_for_xp(xp: int) -> int:
	var clamped_xp := clampi(xp, 0, MAX_XP)
	var result := 1
	for level_value in range(2, 6):
		if clamped_xp >= LEVEL_XP[level_value]:
			result = level_value
	return result


static func derived_battle_stats(hero: RefCounted) -> Dictionary:
	var vig := int(hero.base_stats["vig"])
	var str_stat := int(hero.base_stats["str"])
	var agi := int(hero.base_stats["agi"])
	var int_stat := int(hero.base_stats["int"])
	var star_bp := 10000 + (int(hero.star) - 1) * 2500
	return {
		"max_hp": int((50 + vig * 10) * star_bp / 10000),
		"defense": int((class_armor(hero.class_id) + vig * 2) * star_bp / 10000),
		"physical_atk": int(str_stat * 3 * star_bp / 10000),
		"magic_atk": int(int_stat * 3 * star_bp / 10000),
		"speed_milli": 60000 + agi * 4000,
		"crit_bp": clampi(500 + agi * 50, 0, 5000),
	}


static func active_skill_id(hero: RefCounted) -> String:
	return FactoryCatalogScript.active_skill_for_archetype(String(hero.archetype_id))


static func skill_tier(hero: RefCounted) -> int:
	return clampi(int(hero.star), 1, 3)


static func class_armor(class_id: String) -> int:
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


static func _apply_level_growth(hero: RefCounted, _level_value: int) -> void:
	var growth := CLASS_GROWTH_MILLI[hero.class_id] as Dictionary
	var aptitude := int(APTITUDE_BP[hero.aptitude_id])
	for key in HeroStateScript.ATTR_KEYS:
		var total_milli := int(hero.stat_remainders[key]) + int(int(growth[key]) * aptitude / 10000)
		hero.base_stats[key] = int(hero.base_stats[key]) + int(total_milli / 1000)
		hero.stat_remainders[key] = total_milli % 1000

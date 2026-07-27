class_name HeroProgression
extends RefCounted

const HeroStateScript := preload("res://game/scripts/state/hero_state.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const XP_PER_BOOK: int = 20
const MAX_XP: int = 320
const LEVEL_XP: Array[int] = [0, 0, 40, 100, 200, 320]
const GOLD_PER_BOOK_BY_LEVEL: Array[int] = [0, 20, 35, 55, 80, 0]
const APTITUDE_BP: Dictionary = {"C": 8500, "B": 10000, "A": 11500, "S": 13000}
const CLASS_GROWTH_MILLI: Dictionary = {
	"guardian": {"hp": 20000, "attack": 2400, "defense": 4000, "speed_milli": 1600000, "crit_bp": 20000},
	"fighter": {"hp": 10000, "attack": 5400, "defense": 2000, "speed_milli": 3200000, "crit_bp": 40000},
	"ranger": {"hp": 6000, "attack": 2400, "defense": 1200, "speed_milli": 8000000, "crit_bp": 100000},
	"arcanist": {"hp": 5000, "attack": 6300, "defense": 1000, "speed_milli": 2800000, "crit_bp": 35000},
}
static func train_with_books(hero: RefCounted, book_count: int) -> void:
	if book_count <= 0:
		return
	var next_xp := mini(MAX_XP, int(hero.xp) + book_count * XP_PER_BOOK)
	upgrade_to_level(hero, level_for_xp(next_xp))
	hero.xp = next_xp


static func upgrade_to_level(hero: RefCounted, target_level: int) -> bool:
	if hero == null:
		return false
	var current_level := clampi(int(hero.level), 1, 5)
	var clamped_target := clampi(target_level, 1, 5)
	if clamped_target <= current_level:
		return false
	for level_value in range(current_level + 1, clamped_target + 1):
		_apply_level_growth(hero, level_value)
	hero.level = clamped_target
	hero.xp = maxi(int(hero.xp), LEVEL_XP[clamped_target])
	return true


static func max_trainable_books(hero: RefCounted) -> int:
	if hero == null:
		return 0
	return int((MAX_XP - int(hero.xp)) / XP_PER_BOOK)


static func books_to_next_level(hero: RefCounted) -> int:
	if hero == null or int(hero.level) >= 5:
		return 0
	var next_level := int(hero.level) + 1
	var missing_xp := maxi(0, LEVEL_XP[next_level] - int(hero.xp))
	return int((missing_xp + XP_PER_BOOK - 1) / XP_PER_BOOK)


static func training_gold_cost(hero: RefCounted, book_count: int) -> int:
	if hero == null or book_count <= 0 or book_count > max_trainable_books(hero):
		return 0
	var total := 0
	var simulated_xp := int(hero.xp)
	for _index in book_count:
		var current_level := level_for_xp(simulated_xp)
		total += int(GOLD_PER_BOOK_BY_LEVEL[current_level])
		simulated_xp = mini(MAX_XP, simulated_xp + XP_PER_BOOK)
	return total


static func next_book_gold_cost(hero: RefCounted) -> int:
	return training_gold_cost(hero, 1)


static func level_for_xp(xp: int) -> int:
	var clamped_xp := clampi(xp, 0, MAX_XP)
	var result := 1
	for level_value in range(2, 6):
		if clamped_xp >= LEVEL_XP[level_value]:
			result = level_value
	return result


static func derived_battle_stats(hero: RefCounted) -> Dictionary:
	var star_index := clampi(int(hero.star), 1, 3)
	var star_bp: int = [0, 10000, 13000, 16000][star_index]
	return {
		"hp": int(int(hero.base_stats["hp"]) * star_bp / 10000),
		"attack": int(int(hero.base_stats["attack"]) * star_bp / 10000),
		"defense": int(int(hero.base_stats["defense"]) * star_bp / 10000),
		"speed_milli": int(hero.base_stats["speed_milli"]),
		"crit_bp": clampi(int(hero.base_stats["crit_bp"]), 0, 5000),
	}


static func active_skill_id(hero: RefCounted) -> String:
	return FactoryCatalogScript.active_skill_for_archetype(String(hero.archetype_id))


static func skill_tier(hero: RefCounted) -> int:
	return clampi(int(hero.star), 1, 3)


static func _apply_level_growth(hero: RefCounted, _level_value: int) -> void:
	var growth := CLASS_GROWTH_MILLI[hero.class_id] as Dictionary
	var aptitude := int(APTITUDE_BP[hero.aptitude_id])
	for key in HeroStateScript.ATTR_KEYS:
		var total_milli := int(hero.stat_remainders[key]) + int(int(growth[key]) * aptitude / 10000)
		hero.base_stats[key] = int(hero.base_stats[key]) + int(total_milli / 1000)
		hero.stat_remainders[key] = total_milli % 1000

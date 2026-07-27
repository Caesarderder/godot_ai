class_name HeroGenerator
extends RefCounted

const HeroStateScript := preload("res://game/scripts/state/hero_state.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const CLASS_IDS: Array[String] = ["guardian", "fighter", "ranger", "arcanist"]
# C remains accepted only for legacy saves; every newly created role uses B/A/S.
const APTITUDE_IDS: Array[String] = ["C", "B", "A", "S"]
const ACTIVE_APTITUDE_IDS: Array[String] = ["B", "A", "S"]
const APTITUDE_WEIGHT_BP: Dictionary = {"B": 8000, "A": 1800, "S": 200}
const TRAIT_IDS: Array[String] = [
	"brave", "patient", "reckless", "focused", "lucky", "stubborn", "swift", "calm"
]
const GIVEN_NAMES: Array[String] = ["Ari", "Bren", "Cato", "Dara", "Eli", "Faye", "Galen", "Hana"]
const FAMILY_NAMES: Array[String] = ["Ash", "Brook", "Crown", "Dusk", "Ember", "Frost"]
const CLASS_BASE_STATS: Dictionary = {
	"guardian": {"hp": 190, "attack": 21, "defense": 40, "speed_milli": 84000, "crit_bp": 800},
	"fighter": {"hp": 150, "attack": 36, "defense": 28, "speed_milli": 92000, "crit_bp": 900},
	"ranger": {"hp": 130, "attack": 24, "defense": 21, "speed_milli": 112000, "crit_bp": 1150},
	"arcanist": {"hp": 120, "attack": 42, "defense": 17, "speed_milli": 92000, "crit_bp": 900},
}
const STAT_VARIANCE: Dictionary = {
	"hp": 10, "attack": 3, "defense": 2, "speed_milli": 4000, "crit_bp": 50,
}
const ARCHETYPE_IDS: Array[String] = [
	"gman", "assault", "sonic", "rocket", "bomber", "armored", "saw", "repair", "parasite"
]
const INITIAL_ARCHETYPES: Array[String] = [
	"assault", "armored", "assault", "sonic", "repair", "parasite", "armored", "armored"
]
const INITIAL_CLASSES: Array[String] = [
	"fighter", "guardian", "fighter", "arcanist", "guardian", "arcanist", "guardian", "guardian"
]


static func create_initial_roster(run_seed: int) -> Array[RefCounted]:
	var specs: Array[Dictionary] = [
		{"archetype": "gman", "class": "guardian", "name": "G-Man 指挥官"},
	]
	var roster: Array[RefCounted] = []
	for index in specs.size():
		var spec := specs[index]
		var hero: RefCounted = generate_archetype(
			run_seed,
			index,
			String(spec["archetype"]),
			String(spec["class"])
		)
		hero.display_name = String(spec["name"])
		hero.aptitude_id = "B"
		hero.star = 1
		hero.level = 1
		hero.xp = 0
		hero.readiness = 100
		roster.append(hero)
	return roster


static func generate_hero(run_seed: int, roster_index: int) -> RefCounted:
	var hero := HeroStateScript.new()
	var token := "%s:%s" % [str(run_seed), str(roster_index)]
	hero.seed_token = token
	hero.hero_id = "hero_%04d_%08x" % [roster_index + 1, _stable_int(["hero-id", token])]
	hero.class_id = CLASS_IDS[roster_index] if roster_index < CLASS_IDS.size() else _pick(CLASS_IDS, ["class", token])
	hero.archetype_id = INITIAL_ARCHETYPES[roster_index] if roster_index < INITIAL_ARCHETYPES.size() else _pick(ARCHETYPE_IDS, ["archetype", token])
	hero.star = 1
	hero.aptitude_id = _pick_weighted_aptitude(["aptitude", token])
	hero.trait_ids = [_pick(TRAIT_IDS, ["trait-a", token]), _pick(TRAIT_IDS, ["trait-b", token])]
	if hero.trait_ids[0] == hero.trait_ids[1]:
		hero.trait_ids[1] = TRAIT_IDS[(TRAIT_IDS.find(hero.trait_ids[0]) + 1) % TRAIT_IDS.size()]
	hero.skill_ids = ["%s_basic" % hero.archetype_id, FactoryCatalogScript.active_skill_for_archetype(hero.archetype_id)]
	hero.equipment_by_slot = {"weapon": "", "armor": "", "accessory": ""}
	hero.display_name = "%s · %s %s" % [archetype_display_name(hero.archetype_id), _pick(GIVEN_NAMES, ["given", token]), _pick(FAMILY_NAMES, ["family", token])]
	hero.level = 1
	hero.xp = 0
	hero.base_stats = (CLASS_BASE_STATS[hero.class_id] as Dictionary).duplicate(true)
	for key in HeroStateScript.ATTR_KEYS:
		hero.base_stats[key] = int(hero.base_stats[key]) + _stat_variance(key, token)
		hero.stat_remainders[key] = 0
	return hero


static func generate_archetype(run_seed: int, roster_index: int, archetype_id: String, class_id: String) -> RefCounted:
	var hero: RefCounted = generate_hero(run_seed, roster_index)
	hero.archetype_id = archetype_id
	hero.class_id = class_id
	hero.base_stats = (CLASS_BASE_STATS[class_id] as Dictionary).duplicate(true)
	for key in HeroStateScript.ATTR_KEYS:
		hero.base_stats[key] = int(hero.base_stats[key]) + _stat_variance(key, hero.seed_token)
		hero.stat_remainders[key] = 0
	hero.skill_ids.clear()
	hero.skill_ids.append("%s_basic" % archetype_id)
	hero.skill_ids.append(FactoryCatalogScript.active_skill_for_archetype(archetype_id))
	hero.display_name = "%s · %s %s" % [archetype_display_name(archetype_id), _pick(GIVEN_NAMES, ["given", hero.seed_token]), _pick(FAMILY_NAMES, ["family", hero.seed_token])]
	var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
	if not recipe.is_empty():
		hero.aptitude_id = String(recipe.get("rating", "B"))
	return hero


static func merged_hero_id(run_seed: int, roster_index: int, consumed_ids: Array[String]) -> String:
	var sorted_ids := consumed_ids.duplicate()
	sorted_ids.sort()
	return "hero_%04d_%08x" % [roster_index + 1, _stable_int(["merge", str(run_seed), ",".join(sorted_ids)])]


static func archetype_display_name(archetype_id: String) -> String:
	var names := {
		"gman": "Gman",
		"assault": "冲锋马桶人",
		"sonic": "音波马桶人",
		"rocket": "火箭飞行马桶人",
		"bomber": "自爆飞行马桶人",
		"armored": "装甲冲城马桶人",
		"saw": "双锯重装马桶人",
		"repair": "维修马桶人",
		"parasite": "寄生母体马桶人",
	}
	return String(names.get(archetype_id, "马桶人"))


static func _pick(values: Array[String], parts: Array[String]) -> String:
	return values[_stable_int(parts) % values.size()]


static func _pick_weighted_aptitude(parts: Array[String]) -> String:
	var roll := _stable_int(parts) % 10000
	var cursor := 0
	for aptitude in ACTIVE_APTITUDE_IDS:
		cursor += int(APTITUDE_WEIGHT_BP[aptitude])
		if roll < cursor:
			return aptitude
	return "B"


static func _stable_int(parts: Array[String]) -> int:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for part in parts:
		ctx.update(part.to_utf8_buffer())
		ctx.update(PackedByteArray([0]))
	var bytes := ctx.finish()
	var value := 0
	for index in 4:
		value = (value << 8) + int(bytes[index])
	return value


static func _stat_variance(stat_id: String, token: String) -> int:
	var extent := int(STAT_VARIANCE[stat_id])
	return int(_stable_int(["l1-variance", stat_id, token]) % (extent * 2 + 1)) - extent

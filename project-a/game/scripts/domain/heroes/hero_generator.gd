class_name HeroGenerator
extends RefCounted


const HeroCatalogScript := preload("res://game/scripts/domain/heroes/hero_catalog.gd")
const ATTRIBUTE_KEYS: Array[String] = ["vig", "str", "agi", "int"]


static func generate_roster(seed_value: int, count: int = 8) -> Array[Dictionary]:
	var roster: Array[Dictionary] = []
	var state: int = seed_value & 0x7fffffff
	var aptitude_offset: int = state % HeroCatalogScript.APTITUDE_ORDER.size()
	var trait_offset: int = state % HeroCatalogScript.TRAITS.size()
	for index: int in range(maxi(0, count)):
		var class_id: String = HeroCatalogScript.CLASS_ORDER[index % 4]
		var aptitude: String = HeroCatalogScript.APTITUDE_ORDER[(index + aptitude_offset) % 4]
		var trait_id: String = HeroCatalogScript.TRAITS[(index + trait_offset) % HeroCatalogScript.TRAITS.size()]
		var base_stats: Dictionary = HeroCatalogScript.CLASS_BASE_STATS[class_id]
		var stats: Dictionary = {}
		var variation: Dictionary = {}
		for attribute: String in ATTRIBUTE_KEYS:
			state = _next_state(state)
			var delta: int = (state % 3) - 1
			variation[attribute] = delta
			stats[attribute] = int(base_stats[attribute]) + delta
		roster.append({
			"id": "hero-%08x-%02d" % [seed_value & 0xffffffff, index + 1],
			"name": "Adventurer %02d" % (index + 1),
			"class_id": class_id,
			"aptitude": aptitude,
			"trait": trait_id,
			"level": 1,
			"xp": 0,
			"l1_variation": variation,
			"stats": stats,
			"growth_remainders": {"vig": 0, "str": 0, "agi": 0, "int": 0},
		})
	return roster


static func _next_state(state: int) -> int:
	# A small platform-independent LCG. Masking keeps arithmetic in a signed-safe range.
	return (state * 1_103_515_245 + 12_345) & 0x7fffffff

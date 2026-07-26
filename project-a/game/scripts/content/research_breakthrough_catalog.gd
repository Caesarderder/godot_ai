class_name ResearchBreakthroughCatalog
extends RefCounted

const CLAIM_KEY: String = "reward.research_breakthrough_ten"
const CARDS: Array[Resource] = [
	preload("res://game/resources/definitions/research/breakthrough/01_assault_hero.tres"),
	preload("res://game/resources/definitions/research/breakthrough/02_armored_hero.tres"),
	preload("res://game/resources/definitions/research/breakthrough/03_skill_chip.tres"),
	preload("res://game/resources/definitions/research/breakthrough/04_porcelain.tres"),
	preload("res://game/resources/definitions/research/breakthrough/05_porcelain.tres"),
	preload("res://game/resources/definitions/research/breakthrough/06_porcelain.tres"),
	preload("res://game/resources/definitions/research/breakthrough/07_parts.tres"),
	preload("res://game/resources/definitions/research/breakthrough/08_parts.tres"),
	preload("res://game/resources/definitions/research/breakthrough/09_sludge.tres"),
	preload("res://game/resources/definitions/research/breakthrough/10_sludge.tres"),
]
const EXPECTED_MATERIAL_GRANT: Dictionary = {
	"porcelain": 18,
	"parts": 10,
	"sludge": 8,
}


static func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	var hero_archetypes: Array[String] = []
	var hero_count := 0
	var resource_count := 0
	for index in CARDS.size():
		var item := CARDS[index]
		if item == null:
			errors.append("research breakthrough card %d preload returned null" % index)
			continue
		var card_id := String(item.card_id)
		if ids.has(card_id):
			errors.append("duplicate research breakthrough card_id: %s" % card_id)
		ids[card_id] = true
		for error in item.validation_errors():
			errors.append(String(error))
		if String(item.kind) == "hero":
			hero_count += 1
			hero_archetypes.append(String(item.archetype_id))
			if index >= 2:
				errors.append("%s guaranteed hero must appear before resource cards" % card_id)
		else:
			resource_count += 1
	if CARDS.size() != 10:
		errors.append("research breakthrough must contain exactly ten cards")
	hero_archetypes.sort()
	if hero_count != 2 or hero_archetypes != ["armored", "assault"]:
		errors.append("research breakthrough must guarantee assault and armored exactly once")
	if resource_count != 8:
		errors.append("research breakthrough must contain exactly eight resource cards")
	if material_grant() != EXPECTED_MATERIAL_GRANT:
		errors.append("research breakthrough material grant does not match the first-session budget")
	if skill_chip_grant() != 1:
		errors.append("research breakthrough must grant exactly one skill chip")
	return errors


static func material_grant() -> Dictionary:
	var grant := {"porcelain": 0, "parts": 0, "sludge": 0}
	for item in CARDS:
		var kind := String(item.kind)
		if grant.has(kind):
			grant[kind] = int(grant[kind]) + int(item.amount)
	return grant


static func skill_chip_grant() -> int:
	var total := 0
	for item in CARDS:
		if String(item.kind) == "skill_chip":
			total += int(item.amount)
	return total


static func guaranteed_archetypes() -> Array[String]:
	var values: Array[String] = []
	for item in CARDS:
		if String(item.kind) == "hero":
			values.append(String(item.archetype_id))
	return values

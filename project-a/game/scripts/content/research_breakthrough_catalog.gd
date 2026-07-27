class_name ResearchBreakthroughCatalog
extends RefCounted

const CLAIM_KEY: String = "reward.foundational_signal_ten"
const LEGACY_CLAIM_KEY: String = "reward.research_breakthrough_ten"
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
static func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	var blueprint_archetypes: Array[String] = []
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
		if String(item.kind) == "blueprint":
			blueprint_archetypes.append(String(item.archetype_id))
			if not ["ordinary.assault", "heavy.armored"].has(String(item.recipe_id)):
				errors.append("%s onboarding signal card reveals a non-foundational design" % card_id)
	if CARDS.size() != 10:
		errors.append("foundational signal batch must contain exactly ten blueprint cards")
	if blueprint_archetypes.size() != 10:
		errors.append("foundational signal batch may only contain toilet design blueprints")
	if guaranteed_recipe_ids() != ["ordinary.assault", "heavy.armored"]:
		errors.append("foundational signal batch must reveal assault and armored first")
	return errors


static func material_grant() -> Dictionary:
	return {"porcelain": 0, "parts": 0, "sludge": 0}


static func skill_chip_grant() -> int:
	return 0


static func guaranteed_archetypes() -> Array[String]:
	return [String(CARDS[0].archetype_id), String(CARDS[1].archetype_id)]


static func guaranteed_recipe_ids() -> Array[String]:
	return [String(CARDS[0].recipe_id), String(CARDS[1].recipe_id)]

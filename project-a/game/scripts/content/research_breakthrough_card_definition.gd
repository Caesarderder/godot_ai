class_name ResearchBreakthroughCardDefinition
extends Resource

const HERO_KIND: String = "hero"
const RESOURCE_KINDS: Array[String] = ["skill_chip", "porcelain", "parts", "sludge"]
const VALID_RARITIES: Array[String] = ["R", "A"]

@export var card_id: StringName
@export_enum("R", "A") var rarity: String = "R"
@export_enum("hero", "skill_chip", "porcelain", "parts", "sludge") var kind: String = "porcelain"
@export_range(0, 999, 1) var amount: int = 0

@export_group("Hero reward")
@export var recipe_id: StringName
@export var archetype_id: StringName
@export var class_id: StringName
@export_range(0, 99, 1) var duplicate_data_amount: int = 0


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var id := String(card_id)
	if id.is_empty():
		errors.append("card_id is required")
	if not VALID_RARITIES.has(rarity):
		errors.append("%s rarity is invalid: %s" % [id, rarity])
	if kind == HERO_KIND:
		if rarity != "A":
			errors.append("%s guaranteed hero must use A rarity" % id)
		if amount != 0:
			errors.append("%s hero amount must be zero" % id)
		if String(recipe_id).is_empty() or String(archetype_id).is_empty() or String(class_id).is_empty():
			errors.append("%s hero fields are required" % id)
		if duplicate_data_amount <= 0:
			errors.append("%s duplicate_data_amount must be positive" % id)
	elif RESOURCE_KINDS.has(kind):
		if amount <= 0:
			errors.append("%s resource amount must be positive" % id)
		if (
			not String(recipe_id).is_empty()
				or not String(archetype_id).is_empty()
				or not String(class_id).is_empty()
				or duplicate_data_amount != 0
		):
			errors.append("%s resource card must not contain hero fields" % id)
		if kind == "skill_chip" and rarity != "A":
			errors.append("%s skill chip must use A rarity" % id)
		if kind != "skill_chip" and rarity != "R":
			errors.append("%s material card must use R rarity" % id)
	else:
		errors.append("%s kind is invalid: %s" % [id, kind])
	return errors

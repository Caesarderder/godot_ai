class_name ResearchBreakthroughCardDefinition
extends Resource

const BLUEPRINT_KIND: String = "blueprint"
const VALID_RARITIES: Array[String] = ["B", "A", "S"]

@export var card_id: StringName
@export_enum("B", "A", "S") var rarity: String = "B"
@export_enum("blueprint") var kind: String = "blueprint"
@export_range(0, 999, 1) var amount: int = 0

@export_group("Design reward")
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
	if kind == BLUEPRINT_KIND:
		if amount != 0:
			errors.append("%s blueprint amount must be zero" % id)
		if String(recipe_id).is_empty() or String(archetype_id).is_empty() or String(class_id).is_empty():
			errors.append("%s blueprint fields are required" % id)
		if duplicate_data_amount <= 0:
			errors.append("%s duplicate_data_amount must be positive" % id)
	else:
		errors.append("%s kind is invalid: %s" % [id, kind])
	return errors

extends GutTest

const Definitions := preload("res://game/scripts/domain/loot/equipment_definitions.gd")


func test_catalog_has_three_slots_twelve_templates_and_ten_affixes() -> void:
	var templates: Dictionary = Definitions.templates()
	var affixes: Dictionary = Definitions.affixes()
	assert_eq(Definitions.SLOTS, ["weapon", "armor", "accessory"])
	assert_eq(templates.size(), 12)
	assert_eq(affixes.size(), 10)
	for template_id: String in templates:
		assert_has(Definitions.SLOTS, templates[template_id].slot)


func test_quality_order_is_white_green_blue_purple() -> void:
	assert_eq(Definitions.QUALITIES, ["white", "green", "blue", "purple"])
	assert_eq(Definitions.quality_rank("white"), 0)
	assert_eq(Definitions.quality_rank("purple"), 3)

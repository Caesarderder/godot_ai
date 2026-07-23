extends GutTest

const LootGenerator := preload("res://game/scripts/domain/loot/loot_generator.gd")


func test_item_instance_is_stable_and_contains_persistent_fields() -> void:
	var first := LootGenerator.create_item(77, 4, "guardian_blade", "blue", ["strength"])
	var replay := LootGenerator.create_item(77, 4, "guardian_blade", "blue", ["strength"])
	assert_eq(first, replay)
	assert_false(str(first.id).is_empty())
	assert_eq(first.template_id, "guardian_blade")
	assert_eq(first.slot, "weapon")
	assert_eq(first.quality, "blue")
	assert_eq(first.affix_ids, ["strength"])
	assert_eq(first.enhancement, 0)


func test_different_drop_indices_produce_different_ids() -> void:
	var first := LootGenerator.create_item(77, 4, "guardian_blade", "white", [])
	var second := LootGenerator.create_item(77, 5, "guardian_blade", "white", [])
	assert_ne(first.id, second.id)

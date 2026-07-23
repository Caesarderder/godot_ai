extends GutTest

const EquipmentService := preload("res://game/scripts/domain/loot/equipment_service.gd")
const LootGenerator := preload("res://game/scripts/domain/loot/loot_generator.gd")


func _state() -> Dictionary:
	var item := LootGenerator.create_item(7, 1, "guardian_blade", "blue", ["strength"])
	return {
		"inventory": {"items": {item.id: item}},
		"roster": {"hero-1": {"class_id": "guardian", "equipment": {}}},
		"economy": {"gold": 1000, "recruit_tickets": 0, "experience_books": 0, "forge_stones": 20},
	}


func test_equip_and_unequip_use_the_template_slot() -> void:
	var state := _state()
	var item_id: String = state.inventory.items.keys()[0]
	var equipped := EquipmentService.equip(state, "hero-1", item_id)
	assert_true(equipped.ok, str(equipped))
	assert_eq(equipped.state.roster["hero-1"].equipment.weapon, item_id)
	assert_eq(equipped.events[0].type, "item_equipped")
	var unequipped := EquipmentService.unequip(equipped.state, "hero-1", "weapon")
	assert_true(unequipped.ok)
	assert_false(unequipped.state.roster["hero-1"].equipment.has("weapon"))


func test_item_cannot_be_equipped_by_two_heroes() -> void:
	var state := _state()
	state.roster["hero-2"] = {"class_id": "guardian", "equipment": {}}
	var item_id: String = state.inventory.items.keys()[0]
	var equipped := EquipmentService.equip(state, "hero-1", item_id)
	var rejected := EquipmentService.equip(equipped.state, "hero-2", item_id)
	assert_false(rejected.ok)
	assert_eq(rejected.code, "ITEM_ALREADY_EQUIPPED")


func test_enhancement_levels_one_to_three_charge_exact_cost_without_failure() -> void:
	var state := _state()
	var item_id: String = state.inventory.items.keys()[0]
	var expected_gold := [920, 780, 560]
	var expected_stones := [19, 17, 14]
	for index: int in range(3):
		var enhanced := EquipmentService.enhance(state, item_id)
		assert_true(enhanced.ok, str(enhanced))
		state = enhanced.state
		assert_eq(state.inventory.items[item_id].enhancement, index + 1)
		assert_eq(state.economy.gold, expected_gold[index])
		assert_eq(state.economy.forge_stones, expected_stones[index])


func test_enhancement_rejects_insufficient_resources_without_mutation() -> void:
	var state := _state()
	state.economy.gold = 79
	var before := state.duplicate(true)
	var item_id: String = state.inventory.items.keys()[0]
	var result := EquipmentService.enhance(state, item_id)
	assert_false(result.ok)
	assert_eq(result.code, "INSUFFICIENT_RESOURCES")
	assert_eq(state, before)


func test_enhancement_is_capped_at_five() -> void:
	var state := _state()
	var item_id: String = state.inventory.items.keys()[0]
	state.inventory.items[item_id].enhancement = 5
	var result := EquipmentService.enhance(state, item_id)
	assert_false(result.ok)
	assert_eq(result.code, "MAX_ENHANCEMENT")

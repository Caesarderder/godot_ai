extends GutTest

const LootGenerator := preload("res://game/scripts/domain/loot/loot_generator.gd")
const PityState := preload("res://game/scripts/domain/loot/pity_state.gd")


func _white_item(index: int) -> Dictionary:
	return LootGenerator.create_item(99, index, "guardian_blade", "white", [])


func test_eighth_qualifying_drop_is_upgraded_to_usable_blue_and_resets_counter() -> void:
	var pity := PityState.create_empty()
	var resolved: Dictionary = {}
	for index: int in range(1, 9):
		resolved = PityState.resolve_qualifying_drop(pity, _white_item(index), "", ["guardian_blade"])
		pity = resolved.pity
	assert_eq(resolved.item.quality, "blue")
	assert_eq(resolved.item.template_id, "guardian_blade")
	assert_true(resolved.guaranteed)
	assert_eq(pity.qualifying_drops, 0)
	assert_true(pity.first_guarantee_claimed)


func test_stage_one_three_reward_triggers_first_guarantee_before_eighth_drop() -> void:
	var pity := PityState.create_empty()
	for index: int in range(1, 4):
		pity = PityState.resolve_qualifying_drop(pity, _white_item(index)).pity
	var resolved := PityState.resolve_qualifying_drop(
		pity, _white_item(4), "stage-1-3", ["guardian_blade"]
	)
	assert_true(resolved.guaranteed)
	assert_eq(resolved.item.quality, "blue")
	assert_eq(resolved.pity.qualifying_drops, 0)


func test_stage_reward_does_not_award_second_first_guarantee() -> void:
	var pity := PityState.create_empty()
	pity.first_guarantee_claimed = true
	var resolved := PityState.resolve_qualifying_drop(
		pity, _white_item(1), "stage-1-3", ["guardian_blade"]
	)
	assert_false(resolved.guaranteed)
	assert_eq(resolved.item.quality, "white")
	assert_eq(resolved.pity.qualifying_drops, 1)

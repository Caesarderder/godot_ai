extends GutTest

const CampService := preload("res://game/scripts/domain/camp/camp_service.gd")


func test_default_camp_has_three_level_one_facilities() -> void:
	var camp: Dictionary = CampService.create_default()
	assert_eq(camp["tavern"]["level"], 1)
	assert_eq(camp["blacksmith"]["level"], 1)
	assert_eq(camp["training_ground"]["level"], 1)


func test_level_two_costs_300_gold_and_never_overdraws() -> void:
	var camp: Dictionary = CampService.create_default()
	var success: Dictionary = CampService.upgrade(camp, "tavern", 300)
	assert_true(success["ok"])
	assert_eq(success["camp"]["tavern"]["level"], 2)
	assert_eq(success["gold"], 0)
	assert_eq(success["spent"], 300)

	var rejected: Dictionary = CampService.upgrade(camp, "tavern", 299)
	assert_false(rejected["ok"])
	assert_eq(rejected["code"], "INSUFFICIENT_GOLD")
	assert_eq(rejected["gold"], 299)
	assert_eq(rejected["camp"], camp)


func test_facilities_stop_at_level_three() -> void:
	var camp: Dictionary = CampService.create_default()
	camp["blacksmith"]["level"] = 3
	var result: Dictionary = CampService.upgrade(camp, "blacksmith", 9999)
	assert_false(result["ok"])
	assert_eq(result["code"], "MAX_LEVEL")
	assert_eq(result["gold"], 9999)


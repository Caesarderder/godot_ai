extends GutTest

const EconomyService := preload("res://game/scripts/domain/progression/economy_service.gd")


func test_only_the_four_launch_resources_are_normalized() -> void:
	assert_eq(EconomyService.normalize({"gold": 5}), {
		"gold": 5,
		"recruit_tickets": 0,
		"experience_books": 0,
		"forge_stones": 0,
	})


func test_apply_delta_rejects_a_negative_balance_without_mutating_input() -> void:
	var economy := EconomyService.normalize({"gold": 10})
	var before := economy.duplicate(true)
	var result := EconomyService.apply_delta(economy, {"gold": -11})
	assert_false(result.ok)
	assert_eq(result.code, "NEGATIVE_BALANCE")
	assert_eq(economy, before)


func test_apply_delta_returns_updated_nonnegative_balances() -> void:
	var economy := EconomyService.normalize({"gold": 10, "forge_stones": 2})
	var result := EconomyService.apply_delta(economy, {"gold": -10, "forge_stones": 3})
	assert_true(result.ok)
	assert_eq(result.economy.gold, 0)
	assert_eq(result.economy.forge_stones, 5)

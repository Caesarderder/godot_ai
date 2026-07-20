extends GutTest

const OfflineSettlement := preload("res://game/scripts/domain/idle/offline_settlement.gd")


func test_normal_delta_uses_only_offline_anchor() -> void:
	var result: Dictionary = OfflineSettlement.calculate(
		{
			"offline_anchor_unix": 1_000,
			"saved_at_unix": 9_000,
			"last_seen_wall_unix": 8_000,
			"last_settled_unix": 7_000,
		},
		1_300
	)
	assert_eq(
		result,
		{"effective_end": 1_300, "elapsed_seconds": 300, "credited_seconds": 300}
	)


func test_clock_rollback_credits_zero_and_does_not_move_effective_end_back() -> void:
	var result: Dictionary = OfflineSettlement.calculate({"offline_anchor_unix": 1_000}, 400)
	assert_eq(
		result,
		{"effective_end": 1_000, "elapsed_seconds": 0, "credited_seconds": 0}
	)


func test_exact_eight_hours_is_fully_credited() -> void:
	var result: Dictionary = OfflineSettlement.calculate({"offline_anchor_unix": 100}, 28_900)
	assert_eq(result["elapsed_seconds"], 28_800)
	assert_eq(result["credited_seconds"], 28_800)


func test_forty_eight_hour_jump_advances_end_but_caps_credit_at_eight_hours() -> void:
	var result: Dictionary = OfflineSettlement.calculate(
		{"offline_anchor_unix": 100}, 100 + 48 * 60 * 60
	)
	assert_eq(result["effective_end"], 172_900)
	assert_eq(result["elapsed_seconds"], 172_800)
	assert_eq(result["credited_seconds"], 28_800)

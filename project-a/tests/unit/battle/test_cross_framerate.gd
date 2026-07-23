extends GutTest

const Session := preload("res://game/scripts/domain/battle/battle_session.gd")
const Unit := preload("res://game/scripts/domain/battle/battle_unit.gd")


func test_30_60_120_and_stalled_schedules_have_identical_results() -> void:
	var schedules := [
		_schedule(1.0 / 30.0),
		_schedule(1.0 / 60.0),
		_schedule(1.0 / 120.0),
		[0.03, 0.07, 1.4, 0.0, 0.0, 0.3],
	]
	var expected := ""
	for schedule in schedules:
		var result := _run(schedule)
		assert_not_null(result)
		if expected.is_empty():
			expected = result.digest
		else:
			assert_eq(result.digest, expected)


func _schedule(delta: float) -> Array:
	var values: Array = []
	for unused in 180:
		values.append(delta)
	return values


func _run(schedule: Array) -> BattleResult:
	var session := Session.new(
		123456,
		[
			Unit.new("hero-a", 0, 0, 42_000, 40, 7),
			Unit.new("hero-b", 0, 1, 31_000, 35, 5),
			Unit.new("enemy-a", 1, 0, 38_000, 55, 6),
			Unit.new("enemy-b", 1, 1, 29_000, 30, 4),
		]
	)
	var frame := 0
	while session.result == null and frame < 10_000:
		session.advance_frame(schedule[frame % schedule.size()])
		frame += 1
	return session.result

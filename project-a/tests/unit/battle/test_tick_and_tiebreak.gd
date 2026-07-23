extends GutTest

const Session := preload("res://game/scripts/domain/battle/battle_session.gd")
const Unit := preload("res://game/scripts/domain/battle/battle_unit.gd")


func test_tie_break_is_overflow_speed_slot_then_utf8_id() -> void:
	var file := FileAccess.open("res://tests/fixtures/golden/battle_tiebreak_v1.json", FileAccess.READ)
	var fixture: Dictionary = JSON.parse_string(file.get_as_text())
	var units: Array[BattleUnit] = [
		Unit.new("id-z", 0, 2, 100_000, 10, 1),
		Unit.new("id-a", 0, 2, 100_000, 10, 1),
		Unit.new("slot-a", 0, 1, 100_000, 10, 1),
		Unit.new("speed", 0, 0, 110_000, 10, 1),
		Unit.new("overflow", 0, 0, 90_000, 10, 1),
		Unit.new("enemy", 1, 0, 1, 100, 0),
	]
	units[4].action_meter = 30_000
	var session := Session.new(7, units)
	session.advance_frame(0.2)
	var order: Array = session._events.map(func(event: Array) -> String: return event[1])
	assert_eq(order, fixture["expected_first_round"])


func test_result_exposes_read_only_identity_outcome_and_reward_roll() -> void:
	var session := Session.new(1, [Unit.new("hero", 0, 0, 100_000, 10, 10), Unit.new("enemy", 1, 0, 1, 10, 1)])
	session.advance_frame(0.2)
	assert_eq(session.result.outcome, "victory")
	assert_true(session.result.result_id.ends_with(session.result.digest))
	assert_between(session.result.reward_roll, 0, 9_999)
	var state := session.result.end_state
	state[0]["hp"] = -1
	assert_ne(session.result.end_state[0]["hp"], -1)


func test_pause_clears_accumulator_and_background_adds_no_ticks() -> void:
	var session := _new_battle()
	session.advance_frame(0.19)
	session.set_paused(true)
	session.advance_frame(300.0)
	session.set_paused(false)
	assert_eq(session.tick_index, 0)
	session.advance_frame(0.01)
	assert_eq(session.tick_index, 0)


func test_each_frame_catches_up_at_most_five_ticks() -> void:
	var session := _new_battle()
	assert_eq(session.advance_frame(5.0), 5)
	assert_eq(session.tick_index, 5)
	assert_eq(session.advance_frame(0.0), 5)
	assert_eq(session.advance_frame(0.0), 5)
	assert_eq(session.advance_frame(0.0), 5)
	assert_eq(session.advance_frame(0.0), 5)
	assert_eq(session.tick_index, 25, "logic backlog must not be dropped by presentation queue limits")
	for event in session.presentation_events:
		if not event["critical"]:
			assert_gte(event["tick"], 16, "droppable presentation events are capped to ten ticks")


func test_presentation_queue_preserves_death_and_result_events() -> void:
	var session := Session.new(3, [Unit.new("hero", 0, 0, 100_000, 10, 10), Unit.new("enemy", 1, 0, 1, 10, 1)])
	session.advance_frame(0.2)
	var kinds: Array = session.presentation_events.map(func(event: Dictionary) -> String: return event["kind"])
	assert_has(kinds, "death")
	assert_has(kinds, "result")


func test_presentation_queue_never_drops_wave_or_key_skill() -> void:
	var session := _new_battle()
	session.queue_key_presentation("wave")
	session.queue_key_presentation("key_skill")
	for unused in 5:
		session.advance_frame(1.0)
	var kinds: Array = session.presentation_events.map(func(event: Dictionary) -> String: return event["kind"])
	assert_has(kinds, "wave")
	assert_has(kinds, "key_skill")


func _new_battle() -> BattleSession:
	return Session.new(
		42,
		[Unit.new("hero", 0, 0, 25_000, 30, 3), Unit.new("enemy", 1, 0, 20_000, 30, 2)]
	)

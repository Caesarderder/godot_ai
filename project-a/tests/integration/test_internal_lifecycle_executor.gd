extends GutTest

@warning_ignore("shadowed_global_identifier")
const CommandExecutor := preload("res://game/scripts/commands/command_executor.gd")
@warning_ignore("shadowed_global_identifier")
const GameState := preload("res://game/scripts/state/game_state.gd")


class FakeClock:
	extends RefCounted
	var now := 0

	func unix_time_seconds() -> int:
		return now


class FakeSavePort:
	extends RefCounted
	var saved: Dictionary = {}
	var calls := 0
	var fail_next := false

	func save_candidate(candidate: Dictionary, _saved_at_unix: int) -> Dictionary:
		calls += 1
		if fail_next:
			fail_next = false
			return {"ok": false, "code": "INJECTED_FAILURE"}
		saved = candidate.duplicate(true)
		return {"ok": true, "code": "OK"}


func _configured() -> Dictionary:
	var clock := FakeClock.new()
	var save_port := FakeSavePort.new()
	var state := GameState.create_new(0, "save-1", 7)
	var executor := CommandExecutor.new()
	var configured: Dictionary = executor.configure(save_port, clock, state)
	return {
		"clock": clock,
		"save_port": save_port,
		"executor": executor,
		"gateway": configured.get("internal_gateway"),
	}


func test_executor_public_api_does_not_authorize_internal_commands() -> void:
	var context := _configured()
	var executor: RefCounted = context.executor
	var result: Dictionary = executor.execute_internal(
		&"__lifecycle_pause_anchor", {"now_unix": 10}, "pause:10"
	)

	assert_eq(result.code, "INTERNAL_COMMAND_FORBIDDEN")
	assert_false(executor.has_method("_create_internal_gateway"))


func test_internal_gateway_is_transferred_only_during_initial_configuration() -> void:
	var context := _configured()
	assert_not_null(context.gateway)

	var repeated: Dictionary = context.executor.configure(
		context.save_port,
		context.clock,
		GameState.create_new(0, "replacement", 8),
	)

	assert_false(repeated.ok)
	assert_eq(repeated.code, "ALREADY_CONFIGURED")
	assert_false(repeated.has("internal_gateway"))


func test_twenty_heartbeats_and_five_minutes_credit_once_after_restart_safe_receipt() -> void:
	var context := _configured()
	var clock: FakeClock = context.clock
	var executor: RefCounted = context.gateway
	for minute in range(1, 21):
		clock.now = minute * 60
		assert_true(
			executor.execute_internal(
				&"__lifecycle_heartbeat_anchor",
				{"now_unix": clock.now},
				"heartbeat:%d" % clock.now
			).ok
		)

	clock.now = 1500
	var first_resume: Dictionary = executor.execute_internal(
		&"__lifecycle_resume_settle", {"now_unix": 1500}, "resume:1500"
	)
	var duplicate_resume: Dictionary = executor.execute_internal(
		&"__lifecycle_resume_settle", {"now_unix": 1500}, "resume:1500"
	)

	assert_eq(first_resume.result.credited_seconds, 300)
	assert_eq(duplicate_resume.result.credited_seconds, 300)
	assert_eq(context.executor.current_state().economy.offline_seconds, 300)
	assert_eq(context.executor.current_state().offline_anchor_unix, 1500)


func test_pause_save_failure_does_not_advance_memory_anchor() -> void:
	var context := _configured()
	var clock: FakeClock = context.clock
	var save_port: FakeSavePort = context.save_port
	var executor: RefCounted = context.gateway
	clock.now = 60
	executor.execute_internal(
		&"__lifecycle_heartbeat_anchor", {"now_unix": 60}, "heartbeat:60"
	)
	save_port.fail_next = true
	clock.now = 120
	var failed: Dictionary = executor.execute_internal(
		&"__lifecycle_pause_anchor", {"now_unix": 120}, "pause:120"
	)

	assert_eq(failed.code, "SAVE_FAILED")
	assert_eq(context.executor.current_state().offline_anchor_unix, 60)


func test_rollback_grants_zero_and_forward_jump_caps_at_eight_hours() -> void:
	var context := _configured()
	var clock: FakeClock = context.clock
	var executor: RefCounted = context.gateway
	clock.now = 1000
	executor.execute_internal(
		&"__lifecycle_pause_anchor", {"now_unix": 1000}, "pause:1000"
	)
	clock.now = 400
	var rollback: Dictionary = executor.execute_internal(
		&"__lifecycle_resume_settle", {"now_unix": 400}, "resume:400"
	)
	assert_eq(rollback.result.credited_seconds, 0)
	assert_eq(context.executor.current_state().offline_anchor_unix, 1000)
	assert_eq(context.executor.current_state().last_settled_unix, 1000)

	clock.now = 1000 + 48 * 60 * 60
	var jump: Dictionary = executor.execute_internal(
		&"__lifecycle_resume_settle", {"now_unix": clock.now}, "resume:jump"
	)
	assert_eq(jump.result.credited_seconds, 8 * 60 * 60)
	assert_eq(context.executor.current_state().economy.offline_seconds, 8 * 60 * 60)
	assert_eq(context.executor.current_state().offline_anchor_unix, clock.now)

extends GutTest

const CommandExecutor := preload("res://game/scripts/commands/command_executor.gd")
const GameState := preload("res://game/scripts/state/game_state.gd")


class FakeClock:
	extends RefCounted
	var now := 100

	func unix_time_seconds() -> int:
		return now


class FakeSavePort:
	extends RefCounted
	var saved_state: Dictionary = {}
	var save_calls := 0
	var fail_before_install := false

	func save_candidate(candidate: Dictionary, _saved_at_unix: int) -> Dictionary:
		save_calls += 1
		if fail_before_install:
			return {"ok": false, "code": "INJECTED_FAILURE"}
		saved_state = candidate.duplicate(true)
		return {"ok": true, "code": "OK"}


func _envelope(overrides := {}) -> Dictionary:
	var result := {
		"command_id": "command-1",
		"type": "recruit_hero",
		"payload": {"coins": 5},
		"business_key": "recruit:1",
		"expected_revision": 0,
		"requested_at": 100,
	}
	result.merge(overrides, true)
	return result


func _coin_reducer(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	candidate["economy"]["coins"] = (
		int(candidate["economy"].get("coins", 0)) + int(payload["coins"])
	)
	return {
		"ok": true,
		"result": {"coins": candidate["economy"]["coins"]},
		"events": [],
	}


func _executor(save_port: FakeSavePort, initial_state := {}) -> RefCounted:
	var state: Dictionary = initial_state
	if state.is_empty():
		state = GameState.create_new(100, "save-1", 7)
	var executor := CommandExecutor.new()
	executor.configure(save_port, FakeClock.new(), state)
	executor.register_reducer(&"recruit_hero", _coin_reducer)
	return executor


func test_unknown_and_internal_commands_are_rejected_without_saving() -> void:
	var save_port := FakeSavePort.new()
	var executor := _executor(save_port)

	assert_eq(executor.execute(_envelope({"type": "not_registered"})).code, "UNKNOWN_COMMAND")
	assert_eq(
		executor.execute(_envelope({"type": "__lifecycle_pause_anchor"})).code,
		"INTERNAL_COMMAND_FORBIDDEN"
	)
	assert_eq(save_port.save_calls, 0)


func test_durable_command_saves_candidate_before_swapping_memory() -> void:
	var save_port := FakeSavePort.new()
	var executor := _executor(save_port)

	var result: Dictionary = executor.execute(_envelope())

	assert_true(result.ok, str(result))
	assert_eq(result.result.coins, 5)
	assert_eq(save_port.saved_state.economy.coins, 5)
	assert_eq(executor.current_state().economy.coins, 5)
	assert_eq(executor.current_state().revision, 1)
	assert_eq(executor.current_state().saved_at_unix, 100)


func test_save_failure_does_not_swap_or_return_success() -> void:
	var save_port := FakeSavePort.new()
	save_port.fail_before_install = true
	var executor := _executor(save_port)

	var result: Dictionary = executor.execute(_envelope())

	assert_false(result.ok)
	assert_eq(result.code, "SAVE_FAILED")
	assert_eq(executor.current_state().economy.get("coins", 0), 0)
	assert_eq(executor.current_state().revision, 0)


func test_duplicate_returns_original_receipt_without_saving_again() -> void:
	var save_port := FakeSavePort.new()
	var executor := _executor(save_port)
	var first: Dictionary = executor.execute(_envelope())
	var duplicate: Dictionary = executor.execute(_envelope({"expected_revision": 1}))

	assert_true(first.ok)
	assert_true(duplicate.ok)
	assert_eq(duplicate.result, first.result)
	assert_eq(save_port.save_calls, 1)
	assert_eq(executor.current_state().economy.coins, 5)


func test_id_and_business_key_reuse_mismatches_do_not_mutate() -> void:
	var save_port := FakeSavePort.new()
	var executor := _executor(save_port)
	executor.execute(_envelope())

	var id_reuse: Dictionary = executor.execute(
		_envelope({"expected_revision": 1, "payload": {"coins": 9}})
	)
	var key_reuse: Dictionary = executor.execute(
		_envelope({
			"command_id": "command-2",
			"expected_revision": 1,
			"payload": {"coins": 9},
		})
	)

	assert_eq(id_reuse.code, "COMMAND_ID_REUSE_MISMATCH")
	assert_eq(key_reuse.code, "BUSINESS_KEY_REUSE_MISMATCH")
	assert_eq(executor.current_state().economy.coins, 5)
	assert_eq(save_port.save_calls, 1)


func test_expected_revision_mismatch_is_rejected() -> void:
	var save_port := FakeSavePort.new()
	var executor := _executor(save_port)
	var result: Dictionary = executor.execute(_envelope({"expected_revision": 2}))

	assert_eq(result.code, "REVISION_MISMATCH")
	assert_eq(save_port.save_calls, 0)

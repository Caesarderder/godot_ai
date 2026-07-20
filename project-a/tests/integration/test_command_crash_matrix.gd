extends GutTest

@warning_ignore("shadowed_global_identifier")
const CommandExecutor := preload("res://game/scripts/commands/command_executor.gd")
@warning_ignore("shadowed_global_identifier")
const GameState := preload("res://game/scripts/state/game_state.gd")


class FixedClock:
	extends RefCounted
	func unix_time_seconds() -> int:
		return 200


class InstalledSavePort:
	extends RefCounted
	var installed: Dictionary = {}
	var calls := 0

	func save_candidate(candidate: Dictionary, _saved_at_unix: int) -> Dictionary:
		calls += 1
		installed = candidate.duplicate(true)
		return {"ok": true, "code": "OK"}


func _reducer(candidate: Dictionary, _payload: Dictionary) -> Dictionary:
	candidate["economy"]["reward"] = int(candidate["economy"].get("reward", 0)) + 1
	return {
		"ok": true,
		"result": {"reward": candidate["economy"]["reward"]},
		"events": [],
	}


func _new_executor(port: InstalledSavePort, state: Dictionary) -> RefCounted:
	var executor := CommandExecutor.new()
	executor.configure(port, FixedClock.new(), state)
	executor.register_reducer(&"claim_reward", _reducer)
	return executor


func _command(expected_revision: int) -> Dictionary:
	return {
		"command_id": "claim-1",
		"type": "claim_reward",
		"payload": {"quest_id": "quest-1"},
		"business_key": "quest-1:claim",
		"expected_revision": expected_revision,
		"requested_at": 200,
	}


func test_restart_after_installed_snapshot_replays_receipt_without_value_twice() -> void:
	var port := InstalledSavePort.new()
	var first_executor := _new_executor(port, GameState.create_new(100, "save-1", 7))
	var first: Dictionary = first_executor.execute(_command(0))
	var restarted_executor := _new_executor(port, port.installed.duplicate(true))
	var replay: Dictionary = restarted_executor.execute(_command(1))

	assert_true(first.ok)
	assert_true(replay.ok)
	assert_eq(replay.result.reward, 1)
	assert_eq(restarted_executor.current_state().economy.reward, 1)
	assert_eq(port.calls, 1)

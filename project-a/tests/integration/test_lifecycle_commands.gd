extends GutTest

const AppLifecycleScript := preload("res://game/scripts/autoloads/app_lifecycle.gd")
const OfflineSettlement := preload("res://game/scripts/domain/idle/offline_settlement.gd")


class FakeClock extends RefCounted:
	var unix_seconds := 0
	var ticks_msec := 0

	func unix_time_seconds() -> int:
		return unix_seconds

	func monotonic_msec() -> int:
		return ticks_msec


class FakeExecutor extends RefCounted:
	var calls: Array[Dictionary] = []
	var fail_next := false
	var state := {
		"offline_anchor_unix": 0,
		"last_seen_wall_unix": 0,
		"last_settled_unix": 0,
		"credited_seconds": 0,
	}

	func execute_internal(
		command_type: StringName, payload: Dictionary, business_key: String
	) -> Dictionary:
		calls.append(
			{"type": command_type, "payload": payload.duplicate(true), "business_key": business_key}
		)
		if fail_next:
			fail_next = false
			return {"ok": false, "code": "SAVE_FAILED"}
		var now_unix := int(payload["now_unix"])
		match command_type:
			&"__lifecycle_pause_anchor", &"__lifecycle_heartbeat_anchor":
				state["offline_anchor_unix"] = maxi(state["offline_anchor_unix"], now_unix)
				state["last_seen_wall_unix"] = maxi(state["last_seen_wall_unix"], now_unix)
			&"__lifecycle_resume_settle":
				var settlement: Dictionary = OfflineSettlement.calculate(state, now_unix)
				state["credited_seconds"] += settlement["credited_seconds"]
				state["offline_anchor_unix"] = settlement["effective_end"]
				state["last_settled_unix"] = maxi(
					state["last_settled_unix"], settlement["effective_end"]
				)
				state["last_seen_wall_unix"] = maxi(state["last_seen_wall_unix"], now_unix)
		return {"ok": true, "code": "OK"}


func test_pause_and_resume_forward_only_through_internal_executor() -> void:
	var clock := FakeClock.new()
	var executor := FakeExecutor.new()
	var lifecycle: Node = add_child_autofree(AppLifecycleScript.new())
	lifecycle.configure(executor, clock)
	clock.unix_seconds = 10
	clock.ticks_msec = 10
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	clock.unix_seconds = 20
	clock.ticks_msec = 300
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(executor.calls.size(), 2)
	assert_eq(executor.calls[0]["type"], &"__lifecycle_pause_anchor")
	assert_eq(executor.calls[0]["payload"], {"now_unix": 10})
	assert_eq(executor.calls[1]["type"], &"__lifecycle_resume_settle")
	assert_eq(executor.calls[1]["payload"], {"now_unix": 20})


func test_pause_and_resume_edges_each_debounce_for_two_hundred_fifty_msec() -> void:
	var clock := FakeClock.new()
	var executor := FakeExecutor.new()
	var lifecycle: Node = add_child_autofree(AppLifecycleScript.new())
	lifecycle.configure(executor, clock)
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	clock.ticks_msec = 249
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	clock.ticks_msec = 498
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(executor.calls.size(), 2)
	assert_eq(executor.calls[0]["type"], &"__lifecycle_pause_anchor")
	assert_eq(executor.calls[1]["type"], &"__lifecycle_resume_settle")


func test_failed_pause_does_not_advance_executor_owned_state() -> void:
	var clock := FakeClock.new()
	clock.unix_seconds = 120
	var executor := FakeExecutor.new()
	executor.state["offline_anchor_unix"] = 60
	executor.fail_next = true
	var lifecycle: Node = add_child_autofree(AppLifecycleScript.new())
	lifecycle.configure(executor, clock)
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(executor.state["offline_anchor_unix"], 60)
	assert_eq(executor.calls.size(), 1)


func test_heartbeat_runs_once_per_sixty_seconds_and_retries_after_failure() -> void:
	var clock := FakeClock.new()
	var executor := FakeExecutor.new()
	var lifecycle: Node = add_child_autofree(AppLifecycleScript.new())
	lifecycle.configure(executor, clock)
	clock.unix_seconds = 59
	clock.ticks_msec = 59_999
	assert_false(lifecycle.poll_heartbeat())
	clock.unix_seconds = 60
	clock.ticks_msec = 60_000
	executor.fail_next = true
	assert_false(lifecycle.poll_heartbeat())
	clock.unix_seconds = 61
	clock.ticks_msec = 60_001
	assert_true(lifecycle.poll_heartbeat())
	clock.ticks_msec = 120_000
	assert_false(lifecycle.poll_heartbeat())
	clock.unix_seconds = 121
	clock.ticks_msec = 120_001
	assert_true(lifecycle.poll_heartbeat())
	assert_eq(executor.calls.size(), 3)


func test_twenty_heartbeats_then_resume_credits_three_hundred_seconds_once() -> void:
	var clock := FakeClock.new()
	var executor := FakeExecutor.new()
	var lifecycle: Node = add_child_autofree(AppLifecycleScript.new())
	lifecycle.configure(executor, clock)
	for minute: int in range(1, 21):
		clock.unix_seconds = minute * 60
		clock.ticks_msec = minute * 60_000
		assert_true(lifecycle.poll_heartbeat())
	assert_eq(executor.state["offline_anchor_unix"], 1_200)
	clock.unix_seconds = 1_500
	clock.ticks_msec = 1_500_000
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(executor.state["credited_seconds"], 300)
	assert_eq(executor.state["offline_anchor_unix"], 1_500)
	assert_eq(executor.calls.size(), 21)
	clock.unix_seconds = 900
	clock.ticks_msec += 250
	lifecycle._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(executor.state["credited_seconds"], 300)
	assert_eq(executor.state["offline_anchor_unix"], 1_500)
	assert_eq(executor.state["last_settled_unix"], 1_500)

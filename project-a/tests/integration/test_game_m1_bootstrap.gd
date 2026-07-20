extends GutTest

const GameScript := preload("res://game/scripts/autoloads/game.gd")
@warning_ignore("shadowed_global_identifier")
const GameState := preload("res://game/scripts/state/game_state.gd")


class FakeClock:
	extends RefCounted
	var now_unix := 1_000


	func unix_time_seconds() -> int:
		return now_unix


	func monotonic_msec() -> int:
		return 0


class FakeSavePort:
	extends RefCounted
	var load_result := { "ok": false, "state": { }, "code": "NO_VALID_SAVE" }
	var save_result_code := "OK"
	var saves: Array[Dictionary] = []
	var order: Array[String]


	func _init(shared_order: Array[String]) -> void:
		order = shared_order


	func load_state() -> Dictionary:
		return load_result.duplicate(true)


	func save_candidate(candidate: Dictionary, saved_at_unix: int) -> Dictionary:
		order.append("save")
		if save_result_code != "OK":
			return { "ok": false, "state": { }, "code": save_result_code }
		var installed := candidate.duplicate(true)
		installed.saved_at_unix = saved_at_unix
		saves.append(installed)
		return { "ok": true, "state": installed, "code": "OK" }


class FakeLifecycle:
	extends RefCounted
	var executor: Object
	var clock: Object


	func configure(configured_executor: Object, configured_clock: Object) -> void:
		executor = configured_executor
		clock = configured_clock


class FakeEventBus:
	extends RefCounted
	var events: Array[Dictionary] = []
	var order: Array[String]


	func _init(shared_order: Array[String]) -> void:
		order = shared_order


	func emit_domain_event(event: Dictionary) -> void:
		order.append("event")
		events.append(event.duplicate(true))


class FakeExecutor:
	extends RefCounted
	var state: Dictionary
	var execution_result := { "ok": true, "code": "OK", "result": { "gold": 5 } }
	var last_envelope: Dictionary = { }
	var order: Array[String]
	var poll_calls := 0


	func _init(shared_order: Array[String]) -> void:
		order = shared_order


	func configure(_save_port: Variant, _clock: Variant, initial_state: Dictionary) -> Dictionary:
		state = initial_state.duplicate(true)
		return { "ok": true, "code": "OK", "internal_gateway": self }


	func current_state() -> Dictionary:
		return state.duplicate(true)


	func execute(envelope: Dictionary) -> Dictionary:
		order.append("execute")
		last_envelope = envelope.duplicate(true)
		return execution_result.duplicate(true)


	func poll_reversible_save() -> bool:
		poll_calls += 1
		return true


func test_first_boot_durably_saves_before_game_ready_without_offline_credit() -> void:
	var order: Array[String] = []
	var game: Node = autofree(GameScript.new())
	var clock := FakeClock.new()
	var save_port := FakeSavePort.new(order)
	var events := FakeEventBus.new(order)
	var lifecycle := FakeLifecycle.new()
	game.game_ready.connect(func() -> void: order.append("ready"))

	var result: Dictionary = game.configure_dependencies(clock, save_port, events, lifecycle)

	assert_true(result.ok)
	assert_true(game.has_booted)
	assert_eq(save_port.saves.size(), 1)
	assert_eq(order, ["save", "event", "ready"])
	var state: Dictionary = game.get_state()
	assert_eq(state.last_seen_wall_unix, 1_000)
	assert_eq(state.offline_anchor_unix, 1_000)
	assert_eq(state.last_settled_unix, 0)
	assert_eq(state.saved_at_unix, 1_000)
	assert_eq(state.economy.get("offline_seconds", 0), 0)
	assert_not_null(lifecycle.executor)
	assert_eq(lifecycle.clock, clock)


func test_existing_save_loads_without_a_boot_save_or_offline_credit() -> void:
	var order: Array[String] = []
	var existing := GameState.create_new(500, "existing", 77)
	existing.revision = 9
	existing.economy = { "offline_seconds": 123 }
	var save_port := FakeSavePort.new(order)
	save_port.load_result = { "ok": true, "state": existing, "code": "OK" }
	var game: Node = autofree(GameScript.new())

	var result: Dictionary = game.configure_dependencies(
			FakeClock.new(),
			save_port,
			FakeEventBus.new(order),
			FakeLifecycle.new(),
	)

	assert_true(result.ok)
	assert_eq(save_port.saves.size(), 0)
	var loaded_state: Dictionary = game.get_state()
	assert_eq(loaded_state.save_id, "existing")
	assert_eq(loaded_state.revision, 9)
	assert_eq(loaded_state.offline_anchor_unix, 500)
	assert_eq(loaded_state.economy.offline_seconds, 123)


func test_first_boot_save_failure_does_not_emit_ready_or_expose_state() -> void:
	var order: Array[String] = []
	var save_port := FakeSavePort.new(order)
	save_port.save_result_code = "DISK_FULL"
	var game: Node = autofree(GameScript.new())
	watch_signals(game)

	var result: Dictionary = game.configure_dependencies(
			FakeClock.new(),
			save_port,
			FakeEventBus.new(order),
			FakeLifecycle.new(),
	)

	assert_false(result.ok)
	assert_eq(result.code, "FIRST_SAVE_FAILED")
	assert_false(game.has_booted)
	assert_eq(game.get_state(), { })
	assert_signal_not_emitted(game, "game_ready")


func test_load_failure_other_than_no_save_does_not_overwrite_storage() -> void:
	var order: Array[String] = []
	var save_port := FakeSavePort.new(order)
	save_port.load_result = { "ok": false, "state": { }, "code": "RECOVERY_FAILED" }
	var game: Node = autofree(GameScript.new())

	var result: Dictionary = game.configure_dependencies(
			FakeClock.new(),
			save_port,
			FakeEventBus.new(order),
			FakeLifecycle.new(),
	)

	assert_false(result.ok)
	assert_eq(result.code, "LOAD_FAILED")
	assert_eq(save_port.saves.size(), 0)
	assert_false(game.has_booted)


func test_execute_command_is_a_facade_and_emits_only_after_success() -> void:
	var order: Array[String] = []
	var existing := GameState.create_new(500, "existing", 77)
	var save_port := FakeSavePort.new(order)
	save_port.load_result = { "ok": true, "state": existing, "code": "OK" }
	var executor := FakeExecutor.new(order)
	var events := FakeEventBus.new(order)
	var game: Node = autofree(GameScript.new())
	var configured: Dictionary = game.configure_dependencies(
			FakeClock.new(),
			save_port,
			events,
			FakeLifecycle.new(),
			executor,
	)
	assert_true(configured.ok)
	order.clear()
	events.events.clear()
	var envelope := { "command_id": "cmd-1", "type": "grant_reward" }

	var result: Dictionary = game.execute_command(envelope)

	assert_true(result.ok)
	assert_eq(executor.last_envelope, envelope)
	assert_eq(order, ["execute", "event"])
	assert_eq(events.events[0].type, "command_committed")
	assert_eq(events.events[0].command_id, "cmd-1")
	executor.execution_result = { "ok": false, "code": "SAVE_FAILED", "result": { } }
	game.execute_command(envelope)
	assert_eq(events.events.size(), 1)


func test_process_polls_pending_reversible_save_after_boot() -> void:
	var order: Array[String] = []
	var existing := GameState.create_new(500, "existing", 77)
	var save_port := FakeSavePort.new(order)
	save_port.load_result = { "ok": true, "state": existing, "code": "OK" }
	var executor := FakeExecutor.new(order)
	var game: Node = autofree(GameScript.new())
	var configured: Dictionary = game.configure_dependencies(
		FakeClock.new(),
		save_port,
		FakeEventBus.new(order),
		FakeLifecycle.new(),
		executor,
	)
	assert_true(configured.ok)

	game._process(0.0)

	assert_eq(executor.poll_calls, 1)

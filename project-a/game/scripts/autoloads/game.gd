extends Node

signal boot_completed
signal game_ready
signal bootstrap_failed(code: String)

const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")

var has_booted := false
var _bootstrap_started := false
var _clock: Variant
var _save_port: Variant
var _event_bus: Variant
var _lifecycle: Variant
var _executor: Variant


func _ready() -> void:
	if _is_gut_runtime():
		return
	var root := get_tree().root
	configure_dependencies(
			root.get_node_or_null("SystemClock"),
			root.get_node_or_null("SaveManager"),
			root.get_node_or_null("EventBus"),
			root.get_node_or_null("AppLifecycle"),
	)


func _process(_delta: float) -> void:
	if has_booted and _executor != null and _executor.has_method("poll_reversible_save"):
		_executor.poll_reversible_save()


func configure_dependencies(
		clock: Variant,
		save_port: Variant,
		event_bus: Variant,
		lifecycle: Variant,
		executor: Variant = null,
) -> Dictionary:
	if _bootstrap_started:
		return _failure("BOOTSTRAP_ALREADY_STARTED")
	if clock == null or save_port == null or event_bus == null or lifecycle == null:
		return _failure("MISSING_DEPENDENCY")
	_bootstrap_started = true
	_clock = clock
	_save_port = save_port
	_event_bus = event_bus
	_lifecycle = lifecycle
	_executor = executor if executor != null else CommandExecutorScript.new()

	var loaded: Dictionary = _save_port.load_state()
	var initial_state: Dictionary
	if loaded.get("ok", false):
		initial_state = Dictionary(loaded.get("state", { })).duplicate(true)
	else:
		if str(loaded.get("code", "")) != "NO_VALID_SAVE":
			_bootstrap_started = false
			bootstrap_failed.emit("LOAD_FAILED")
			return _failure("LOAD_FAILED", str(loaded.get("code", "")))
		var now_unix := int(_clock.unix_time_seconds())
		initial_state = GameStateScript.create_new(now_unix, _new_save_id(), _new_run_seed())
		var first_save: Dictionary = _save_port.save_candidate(initial_state, now_unix)
		if not first_save.get("ok", false):
			_bootstrap_started = false
			bootstrap_failed.emit("FIRST_SAVE_FAILED")
			return _failure("FIRST_SAVE_FAILED", str(first_save.get("code", "")))
		initial_state = Dictionary(first_save.get("state", initial_state)).duplicate(true)

	_executor.configure(_save_port, _clock, initial_state)
	var lifecycle_executor: Variant = _executor
	if _executor.has_method("_create_internal_gateway"):
		lifecycle_executor = _executor._create_internal_gateway()
	_lifecycle.configure(lifecycle_executor, _clock)
	has_booted = true
	_event_bus.emit_domain_event(
			{
				"type": "game_ready",
				"save_id": str(initial_state.get("save_id", "")),
				"revision": int(initial_state.get("revision", 0)),
			}
	)
	game_ready.emit()
	boot_completed.emit()
	return { "ok": true, "code": "OK" }


func get_state() -> Dictionary:
	if not has_booted or _executor == null:
		return { }
	return _executor.current_state()


func execute_command(envelope: Dictionary) -> Dictionary:
	if not has_booted or _executor == null:
		return _failure("GAME_NOT_READY")
	var result: Dictionary = _executor.execute(envelope)
	if result.get("ok", false):
		_event_bus.emit_domain_event(
				{
					"type": "command_committed",
					"command_id": str(envelope.get("command_id", "")),
					"command_type": str(envelope.get("type", "")),
				}
		)
	return result


func _new_save_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


func _new_run_seed() -> int:
	return Crypto.new().generate_random_bytes(8).decode_s64(0)


func _is_gut_runtime() -> bool:
	for argument: String in OS.get_cmdline_args():
		if argument.contains("gut_cmdln.gd"):
			return true
	return false


func _failure(code: String, detail: String = "") -> Dictionary:
	return { "ok": false, "code": code, "detail": detail, "result": { } }

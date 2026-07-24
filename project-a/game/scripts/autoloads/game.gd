extends Node

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")

signal bootstrap_completed(status: String)

var executor: RefCounted = CommandExecutorScript.new()
var bootstrap_status: String = "not_started"


func _ready() -> void:
	var save_node := get_node_or_null("/root/SaveManager")
	if save_node != null:
		bootstrap_with_manager(save_node, 20260723, int(Time.get_unix_time_from_system()))


func new_game(run_seed: int = 20260723, now_unix: int = 0) -> void:
	executor.state = GameStateScript.create_new(run_seed, now_unix)


func execute_command(envelope: Dictionary) -> Dictionary:
	if bootstrap_status.begins_with("load_failed:"):
		return {"ok": false, "error": "SAVE_LOAD_FAILED"}
	if bootstrap_status != "loaded" and bootstrap_status != "created":
		return {"ok": false, "error": "GAME_NOT_BOOTSTRAPPED"}
	return executor.execute(envelope)


func current_state() -> RefCounted:
	return executor.state


func bootstrap_with_manager(save_manager: Object, run_seed: int = 20260723, now_unix: int = 0) -> String:
	if save_manager == null or not save_manager.has_method("save_state") or not save_manager.has_method("load_state"):
		executor.save_callback = Callable()
		bootstrap_status = "save_manager_unavailable"
		bootstrap_completed.emit(bootstrap_status)
		return bootstrap_status
	executor.save_callback = save_manager.save_state
	var loaded: Dictionary = save_manager.load_state()
	if bool(loaded.get("ok", false)):
		executor.state = loaded["state"]
		bootstrap_status = "loaded"
		bootstrap_completed.emit(bootstrap_status)
		return bootstrap_status
	if String(loaded.get("error", "")) == "SAVE_NOT_FOUND":
		var created: RefCounted = GameStateScript.create_new(run_seed, now_unix)
		if not bool(save_manager.save_state(created)):
			bootstrap_status = "initial_save_failed"
			bootstrap_completed.emit(bootstrap_status)
			return bootstrap_status
		executor.state = created
		bootstrap_status = "created"
		bootstrap_completed.emit(bootstrap_status)
		return bootstrap_status
	executor.save_callback = Callable()
	bootstrap_status = "load_failed:%s" % String(loaded.get("error", "UNKNOWN"))
	bootstrap_completed.emit(bootstrap_status)
	return bootstrap_status

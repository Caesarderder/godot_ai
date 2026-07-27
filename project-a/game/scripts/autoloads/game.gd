extends Node

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const ACTIVE_CONTENT_VERSION: String = "toilet-factory-slg-v3-factions"

signal bootstrap_completed(status: String)

var executor: RefCounted = CommandExecutorScript.new()
var bootstrap_status: String = "not_started"
var _save_manager: Object


func new_game(run_seed: int = 20260723, now_unix: int = 0) -> void:
	executor.state = GameStateScript.create_new(run_seed, now_unix, false)


func execute_command(envelope: Dictionary) -> Dictionary:
	if bootstrap_status.begins_with("load_failed:"):
		return {"ok": false, "error": "SAVE_LOAD_FAILED"}
	if bootstrap_status != "loaded" and bootstrap_status != "created":
		return {"ok": false, "error": "GAME_NOT_BOOTSTRAPPED"}
	return executor.execute(envelope)


func current_state() -> RefCounted:
	return executor.state


func export_save_backup() -> Dictionary:
	return export_local_save(_save_manager)


func preview_save_import(text: String) -> Dictionary:
	return preview_local_save_import(_save_manager, text)


func restore_save_import(text: String) -> Dictionary:
	return restore_local_save_import(_save_manager, text)


func reset_game(run_seed: int = 20260723, now_unix: int = 0) -> Dictionary:
	return reset_local_save(_save_manager, run_seed, now_unix)


func export_local_save(save_manager: Object) -> Dictionary:
	if save_manager == null or not save_manager.has_method("export_state"):
		return {"ok": false, "error": "SAVE_MANAGER_UNAVAILABLE"}
	return save_manager.export_state(executor.state)


func preview_local_save_import(save_manager: Object, text: String) -> Dictionary:
	if save_manager == null or not save_manager.has_method("parse_import_text"):
		return {"ok": false, "error": "SAVE_MANAGER_UNAVAILABLE"}
	var parsed: Dictionary = save_manager.parse_import_text(text)
	if not bool(parsed.get("ok", false)):
		return parsed
	var imported_state: RefCounted = parsed["state"]
	if _requires_slg_reset(imported_state):
		return {"ok": false, "error": "SAVE_IMPORT_INCOMPATIBLE_CONTENT"}
	return {
		"ok": true,
		"byte_count": int(parsed.get("byte_count", 0)),
		"save_id": String(imported_state.save_id),
		"revision": int(imported_state.revision),
		"captured_cities": (imported_state.stage_progress.get("cleared_stages", []) as Array).size(),
		"hero_count": imported_state.roster.size(),
		"state": imported_state,
	}


func restore_local_save_import(save_manager: Object, text: String) -> Dictionary:
	var preview := preview_local_save_import(save_manager, text)
	if not bool(preview.get("ok", false)):
		return preview
	if not save_manager.has_method("publish_imported_state"):
		return {"ok": false, "error": "SAVE_MANAGER_UNAVAILABLE"}
	var imported_state: RefCounted = preview["state"]
	var published: Dictionary = save_manager.publish_imported_state(imported_state)
	if not bool(published.get("ok", false)):
		return published
	executor.state = imported_state
	executor.save_callback = save_manager.save_state
	bootstrap_status = "loaded"
	bootstrap_completed.emit(bootstrap_status)
	return {
		"ok": true,
		"save_id": String(imported_state.save_id),
		"revision": int(imported_state.revision),
		"captured_cities": (imported_state.stage_progress.get("cleared_stages", []) as Array).size(),
		"hero_count": imported_state.roster.size(),
	}


func reset_local_save(save_manager: Object, run_seed: int = 20260723, now_unix: int = 0) -> Dictionary:
	if save_manager == null or not save_manager.has_method("delete_local_save") or not save_manager.has_method("save_state"):
		return {"ok": false, "error": "SAVE_MANAGER_UNAVAILABLE"}
	var deleted: Dictionary = save_manager.delete_local_save()
	if not bool(deleted.get("ok", false)):
		return deleted
	var created: RefCounted = GameStateScript.create_new(run_seed, now_unix, false)
	if not bool(save_manager.save_state(created)):
		bootstrap_status = "initial_save_failed"
		return {"ok": false, "error": "NEW_SAVE_WRITE_FAILED", "removed": deleted.get("removed", [])}
	executor.state = created
	executor.save_callback = save_manager.save_state
	bootstrap_status = "created"
	bootstrap_completed.emit(bootstrap_status)
	return {"ok": true, "removed": deleted.get("removed", []), "state": created}


func bootstrap_with_manager(save_manager: Object, run_seed: int = 20260723, now_unix: int = 0) -> String:
	if save_manager == null or not save_manager.has_method("save_state") or not save_manager.has_method("load_state"):
		_save_manager = null
		executor.save_callback = Callable()
		bootstrap_status = "save_manager_unavailable"
		bootstrap_completed.emit(bootstrap_status)
		return bootstrap_status
	_save_manager = save_manager
	executor.save_callback = save_manager.save_state
	var loaded: Dictionary = save_manager.load_state()
	if bool(loaded.get("ok", false)):
		var loaded_state: RefCounted = loaded["state"]
		if _requires_slg_reset(loaded_state):
			var migrated := reset_local_save(save_manager, run_seed, now_unix)
			if bool(migrated.get("ok", false)):
				return bootstrap_status
			bootstrap_status = "load_failed:%s" % String(migrated.get("error", "LEGACY_SAVE_RESET_FAILED"))
			bootstrap_completed.emit(bootstrap_status)
			return bootstrap_status
		executor.state = loaded_state
		bootstrap_status = "loaded"
		bootstrap_completed.emit(bootstrap_status)
		return bootstrap_status
	if String(loaded.get("error", "")) == "SAVE_NOT_FOUND":
		var created: RefCounted = GameStateScript.create_new(run_seed, now_unix, false)
		if not bool(save_manager.save_state(created)):
			bootstrap_status = "initial_save_failed"
			bootstrap_completed.emit(bootstrap_status)
			return bootstrap_status
		executor.state = created
		bootstrap_status = "created"
		bootstrap_completed.emit(bootstrap_status)
		return bootstrap_status
	if String(loaded.get("error", "")).begins_with("unsupported schema_version"):
		var reset := reset_local_save(save_manager, run_seed, now_unix)
		if bool(reset.get("ok", false)):
			return bootstrap_status
		bootstrap_status = "load_failed:%s" % String(reset.get("error", "OLD_SAVE_RESET_FAILED"))
		bootstrap_completed.emit(bootstrap_status)
		return bootstrap_status
	executor.save_callback = Callable()
	bootstrap_status = "load_failed:%s" % String(loaded.get("error", "UNKNOWN"))
	bootstrap_completed.emit(bootstrap_status)
	return bootstrap_status


func _requires_slg_reset(state: RefCounted) -> bool:
	if state == null:
		return true
	if String(state.content_version) != ACTIVE_CONTENT_VERSION:
		return true
	var has_gman := false
	for hero in state.roster:
		if String(hero.archetype_id) == "gman":
			has_gman = true
			break
	if not has_gman:
		return true
	if int(state.factory.facilities.get("command_center", 0)) < 1:
		return true
	return false

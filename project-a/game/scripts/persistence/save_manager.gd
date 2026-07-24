class_name SaveManagerCore
extends RefCounted

const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")

const SAVE_PATH: String = "user://save_v1.json"

var save_path: String = SAVE_PATH


func _init(path: String = SAVE_PATH) -> void:
	save_path = path


func save_state(state: RefCounted) -> bool:
	var encoded := SaveCodecScript.to_json_text(state)
	var tmp_path := save_path + ".tmp"
	var bak_path := save_path + ".bak"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encoded)
	file.flush()
	file.close()
	var validate_file := FileAccess.open(tmp_path, FileAccess.READ)
	if validate_file == null:
		return false
	var parsed := SaveCodecScript.from_json_text(validate_file.get_as_text())
	validate_file.close()
	if not bool(parsed.get("ok", false)):
		return false
	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		var bak_error := DirAccess.rename_absolute(save_path, bak_path)
		if bak_error != OK:
			return false
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	var rename_error := DirAccess.rename_absolute(tmp_path, save_path)
	return rename_error == OK


func load_state() -> Dictionary:
	var bak_path := save_path + ".bak"
	var tmp_path := save_path + ".tmp"
	if FileAccess.file_exists(save_path):
		var main_parsed := _load_file(save_path)
		if bool(main_parsed.get("ok", false)):
			return main_parsed
		var bak_after_corrupt := _try_load_existing(bak_path)
		if bool(bak_after_corrupt.get("ok", false)):
			return bak_after_corrupt
		return main_parsed
	var bak_result := _try_load_existing(bak_path)
	if bool(bak_result.get("ok", false)):
		return bak_result
	var tmp_result := _try_load_existing(tmp_path)
	if bool(tmp_result.get("ok", false)):
		return tmp_result
	return {"ok": false, "error": "SAVE_NOT_FOUND"}


func _try_load_existing(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "SAVE_NOT_FOUND"}
	return _load_file(path)


func _load_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "SAVE_OPEN_FAILED"}
	var text := file.get_as_text()
	file.close()
	return SaveCodecScript.from_json_text(text)

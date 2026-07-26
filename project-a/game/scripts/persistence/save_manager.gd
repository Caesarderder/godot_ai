class_name SaveManagerCore
extends RefCounted

const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")

const SAVE_PATH: String = "user://save_v1.json"
const MAX_SAVE_BYTES: int = 2 * 1024 * 1024

var save_path: String = SAVE_PATH


func _init(path: String = SAVE_PATH) -> void:
	save_path = path


func save_state(state: RefCounted) -> bool:
	var encoded := SaveCodecScript.to_json_text(state)
	if encoded.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		push_error("Save exceeds the %d byte limit" % MAX_SAVE_BYTES)
		return false
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
		push_error("Save validation failed: %s" % String(parsed.get("error", "unknown error")))
		DirAccess.remove_absolute(tmp_path)
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
	if rename_error == OK:
		return true
	if FileAccess.file_exists(bak_path) and not FileAccess.file_exists(save_path):
		DirAccess.rename_absolute(bak_path, save_path)
	return false


func export_state(state: RefCounted) -> Dictionary:
	if state == null:
		return {"ok": false, "error": "SAVE_STATE_UNAVAILABLE"}
	var text := SaveCodecScript.to_json_text(state)
	var byte_count := text.to_utf8_buffer().size()
	if byte_count > MAX_SAVE_BYTES:
		return {"ok": false, "error": "SAVE_TOO_LARGE", "max_bytes": MAX_SAVE_BYTES}
	var parsed := SaveCodecScript.from_json_text(text)
	if not bool(parsed.get("ok", false)):
		return {"ok": false, "error": "SAVE_EXPORT_VALIDATION_FAILED", "detail": parsed.get("error", "")}
	return {
		"ok": true,
		"text": text,
		"byte_count": byte_count,
		"state": parsed["state"],
	}


func parse_import_text(text: String) -> Dictionary:
	var byte_count := text.to_utf8_buffer().size()
	if byte_count <= 0:
		return {"ok": false, "error": "SAVE_IMPORT_EMPTY"}
	if byte_count > MAX_SAVE_BYTES:
		return {"ok": false, "error": "SAVE_TOO_LARGE", "max_bytes": MAX_SAVE_BYTES}
	var parsed := SaveCodecScript.from_json_text(text)
	if not bool(parsed.get("ok", false)):
		return {"ok": false, "error": "SAVE_IMPORT_INVALID", "detail": parsed.get("error", "")}
	return {
		"ok": true,
		"byte_count": byte_count,
		"state": parsed["state"],
	}


func publish_imported_state(state: RefCounted) -> Dictionary:
	if state == null:
		return {"ok": false, "error": "SAVE_IMPORT_STATE_UNAVAILABLE"}
	if not save_state(state):
		return {"ok": false, "error": "SAVE_IMPORT_WRITE_FAILED"}
	return {"ok": true, "state": state}


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
		_promote_recovered_state(bak_result)
		return bak_result
	var tmp_result := _try_load_existing(tmp_path)
	if bool(tmp_result.get("ok", false)):
		_promote_recovered_state(tmp_result)
		return tmp_result
	return {"ok": false, "error": "SAVE_NOT_FOUND"}


func delete_local_save() -> Dictionary:
	var targets: Array[String] = [save_path, save_path + ".bak", save_path + ".tmp"]
	var removed: Array[String] = []
	for path in targets:
		if not FileAccess.file_exists(path):
			continue
		var error := DirAccess.remove_absolute(path)
		if error != OK:
			return {
				"ok": false,
				"error": "SAVE_DELETE_FAILED",
				"path": path,
				"removed": removed,
			}
		removed.append(path)
	return {"ok": true, "removed": removed}


func _try_load_existing(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "SAVE_NOT_FOUND"}
	return _load_file(path)


func _load_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "SAVE_OPEN_FAILED"}
	if file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return {"ok": false, "error": "SAVE_TOO_LARGE"}
	var text := file.get_as_text()
	file.close()
	return SaveCodecScript.from_json_text(text)


func _promote_recovered_state(result: Dictionary) -> void:
	var recovered: RefCounted = result.get("state")
	if recovered == null:
		return
	# 合法的备份或临时文件不能长期作为唯一权威；恢复后立刻重写主文件。
	# 写入仍走同一套 tmp 校验与原子 rename，不直接复制未经验证的字节。
	save_state(recovered)

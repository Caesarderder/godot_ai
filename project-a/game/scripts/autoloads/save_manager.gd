extends Node

signal save_requested(reason: StringName)

@warning_ignore("shadowed_global_identifier")
const SaveCodec := preload("res://game/scripts/persistence/save_codec.gd")

const SAVE_PATH := "user://save_v1.json"
const TEMP_PATH := "user://save_v1.json.tmp"
const BACKUP_PATH := "user://save_v1.json.bak"

var _save_path := SAVE_PATH
var _temp_path := TEMP_PATH
var _backup_path := BACKUP_PATH
var _last_durable_revision := -1
var _write_in_progress := false


func request_save(reason: StringName) -> void:
	save_requested.emit(reason)


func configure_paths_for_test(base_path: String) -> void:
	var normalized := base_path.trim_suffix("/")
	_save_path = normalized.path_join("save_v1.json")
	_temp_path = normalized.path_join("save_v1.json.tmp")
	_backup_path = normalized.path_join("save_v1.json.bak")
	_last_durable_revision = -1
	_write_in_progress = false


func save_candidate(candidate: Dictionary, saved_at_unix: int) -> Dictionary:
	if _write_in_progress:
		return _failure("WRITE_IN_PROGRESS")
	_write_in_progress = true
	var result := _save_candidate(candidate, saved_at_unix)
	_write_in_progress = false
	return result


func load_state() -> Dictionary:
	var primary := _decode_file(_save_path)
	if primary.ok:
		_last_durable_revision = primary.state.revision
		return primary

	var backup := _decode_file(_backup_path)
	if not backup.ok:
		return _failure("NO_VALID_SAVE")

	if FileAccess.file_exists(_save_path):
		var corrupt_path := "%s.corrupt-%s-%s" % [
			_save_path,
			int(Time.get_unix_time_from_system()),
			Time.get_ticks_usec(),
		]
		if DirAccess.rename_absolute(
				ProjectSettings.globalize_path(_save_path),
				ProjectSettings.globalize_path(corrupt_path),
		) != OK:
			return _failure("RECOVERY_FAILED")

	_ensure_parent_directory(_save_path)
	if DirAccess.copy_absolute(
			ProjectSettings.globalize_path(_backup_path),
			ProjectSettings.globalize_path(_save_path),
	) != OK:
		return _failure("RECOVERY_FAILED")
	var installed := _decode_file(_save_path)
	if not installed.ok:
		return _failure("RECOVERY_FAILED")
	_last_durable_revision = installed.state.revision
	installed.code = "RECOVERED_BACKUP"
	return installed


func _save_candidate(candidate: Dictionary, saved_at_unix: int) -> Dictionary:
	var snapshot := candidate.duplicate(true)
	snapshot.saved_at_unix = saved_at_unix
	var encoded := SaveCodec.encode(snapshot)
	if encoded.is_empty():
		return _failure("INVALID_CANDIDATE")
	if snapshot.revision < _last_durable_revision:
		return _failure("LOW_REVISION")

	_ensure_parent_directory(_temp_path)
	var temporary := FileAccess.open(_temp_path, FileAccess.WRITE)
	if temporary == null:
		return _failure("SAVE_FAILED")
	temporary.store_string(encoded)
	temporary.flush()
	temporary.close()
	var verified_temporary := _decode_file(_temp_path)
	if not verified_temporary.ok or verified_temporary.state != snapshot:
		return _failure("SAVE_FAILED")

	if FileAccess.file_exists(_save_path):
		var current_primary := _decode_file(_save_path)
		if current_primary.ok:
			_remove_if_present(_backup_path)
			if DirAccess.copy_absolute(
					ProjectSettings.globalize_path(_save_path),
					ProjectSettings.globalize_path(_backup_path),
			) != OK:
				return _failure("SAVE_FAILED")

	_remove_if_present(_save_path)
	if DirAccess.rename_absolute(
			ProjectSettings.globalize_path(_temp_path),
			ProjectSettings.globalize_path(_save_path),
	) != OK:
		return _failure("SAVE_FAILED")
	var installed := _decode_file(_save_path)
	if not installed.ok or installed.state != snapshot:
		return _failure("SAVE_FAILED")
	_last_durable_revision = snapshot.revision
	return { "ok": true, "state": snapshot, "code": "OK" }


func _decode_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("FILE_NOT_FOUND")
	return SaveCodec.decode(FileAccess.get_file_as_string(path))


func _ensure_parent_directory(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))


func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _failure(code: String) -> Dictionary:
	return { "ok": false, "state": { }, "code": code }

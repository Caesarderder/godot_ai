extends GutTest

@warning_ignore("shadowed_global_identifier")
const GameState := preload("res://game/scripts/state/game_state.gd")
@warning_ignore("shadowed_global_identifier")
const SaveCodec := preload("res://game/scripts/persistence/save_codec.gd")
const SaveManagerScript := preload("res://game/scripts/autoloads/save_manager.gd")

var _manager: Node
var _base_path: String


func before_each() -> void:
	_base_path = "user://m1-save-tests/%s-%s" % [name, Time.get_ticks_usec()]
	_manager = SaveManagerScript.new()
	add_child_autofree(_manager)
	_manager.configure_paths_for_test(_base_path)


func after_each() -> void:
	_remove_test_directory()


func test_load_ignores_tmp_and_prefers_valid_primary() -> void:
	var primary := _state(2, "primary")
	var newer_tmp := _state(99, "tmp")
	_write(_base_path.path_join("save_v1.json"), SaveCodec.encode(primary))
	_write(_base_path.path_join("save_v1.json.tmp"), SaveCodec.encode(newer_tmp))
	_write(_base_path.path_join("save_v1.json.bak"), SaveCodec.encode(_state(50, "backup")))

	var loaded: Dictionary = _manager.load_state()

	assert_true(loaded.ok)
	assert_eq(loaded.state.revision, 2)
	assert_eq(loaded.state.save_id, "primary")


func test_corrupt_primary_is_preserved_and_valid_backup_is_restored() -> void:
	var corrupt := FileAccess.get_file_as_string("res://tests/fixtures/saves/save_corrupt.json")
	var backup := _state(7, "backup")
	_write(_base_path.path_join("save_v1.json"), corrupt)
	_write(_base_path.path_join("save_v1.json.bak"), SaveCodec.encode(backup))

	var loaded: Dictionary = _manager.load_state()

	assert_true(loaded.ok)
	assert_eq(loaded.code, "RECOVERED_BACKUP")
	assert_eq(loaded.state, backup)
	assert_eq(
			SaveCodec
			.decode(FileAccess.get_file_as_string(_base_path.path_join("save_v1.json")))
			.state,
			backup,
	)
	var corrupt_paths := _files_with_prefix("save_v1.json.corrupt-")
	assert_eq(corrupt_paths.size(), 1)
	assert_eq(FileAccess.get_file_as_string(corrupt_paths[0]), corrupt)


func test_invalid_backup_is_not_restored() -> void:
	var corrupt := FileAccess.get_file_as_string("res://tests/fixtures/saves/save_corrupt.json")
	_write(_base_path.path_join("save_v1.json"), corrupt)
	_write(_base_path.path_join("save_v1.json.bak"), corrupt)

	var loaded: Dictionary = _manager.load_state()

	assert_false(loaded.ok)
	assert_eq(loaded.code, "NO_VALID_SAVE")
	assert_eq(FileAccess.get_file_as_string(_base_path.path_join("save_v1.json")), corrupt)


func test_save_candidate_flushes_installs_and_backs_up_previous_primary() -> void:
	var first := _state(1, "save-alpha")
	var second := _state(2, "save-alpha")
	assert_true(_manager.save_candidate(first, 100).ok)

	var saved: Dictionary = _manager.save_candidate(second, 200)

	assert_true(saved.ok)
	assert_eq(saved.state.saved_at_unix, 200)
	assert_eq(saved.state.revision, 2)
	assert_false(FileAccess.file_exists(_base_path.path_join("save_v1.json.tmp")))
	var installed := SaveCodec.decode(
			FileAccess.get_file_as_string(_base_path.path_join("save_v1.json"))
	)
	var backup := SaveCodec.decode(
			FileAccess.get_file_as_string(_base_path.path_join("save_v1.json.bak"))
	)
	assert_true(installed.ok)
	assert_eq(installed.state.saved_at_unix, 200)
	assert_eq(backup.state.revision, 1)


func test_save_candidate_rejects_lower_revision_without_replacing_primary() -> void:
	assert_true(_manager.save_candidate(_state(3, "save-alpha"), 300).ok)

	var rejected: Dictionary = _manager.save_candidate(_state(2, "save-alpha"), 400)

	assert_false(rejected.ok)
	assert_eq(rejected.code, "LOW_REVISION")
	var installed := SaveCodec.decode(
			FileAccess.get_file_as_string(_base_path.path_join("save_v1.json"))
	)
	assert_eq(installed.state.revision, 3)
	assert_eq(installed.state.saved_at_unix, 300)


func test_save_candidate_rejects_a_reentrant_writer() -> void:
	_manager.set("_write_in_progress", true)

	var rejected: Dictionary = _manager.save_candidate(_state(1, "save-alpha"), 100)

	assert_false(rejected.ok)
	assert_eq(rejected.code, "WRITE_IN_PROGRESS")
	assert_false(FileAccess.file_exists(_base_path.path_join("save_v1.json")))


func _state(revision: int, save_id: String) -> Dictionary:
	var state := GameState.create_new(10, save_id, 42)
	state.revision = revision
	return state


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _files_with_prefix(prefix: String) -> Array[String]:
	var matches: Array[String] = []
	var directory := DirAccess.open(_base_path)
	if directory == null:
		return matches
	for file_name: String in directory.get_files():
		if file_name.begins_with(prefix):
			matches.append(_base_path.path_join(file_name))
	return matches


func _remove_test_directory() -> void:
	var directory := DirAccess.open(_base_path)
	if directory != null:
		for file_name: String in directory.get_files():
			directory.remove(file_name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_base_path))

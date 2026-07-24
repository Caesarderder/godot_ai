# Safe JSON save slots

This reference provides the file boundary for a Godot 4.6 GDScript save manager. Keep scene-specific snapshot/apply logic outside this boundary.

## Paths and limits

```gdscript
extends Node

const SAVE_DIR := "user://saves"
const SAVE_EXTENSION := ".json"
const BACKUP_EXTENSION := ".bak"
const TEMP_EXTENSION := ".tmp"
const CURRENT_VERSION := 3
const MAX_SAVE_BYTES := 2 * 1024 * 1024
const MAX_SLOT_LENGTH := 32
const MAX_INVENTORY_ITEMS := 500


func _ready() -> void:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	if error != OK:
		push_error("Cannot create save directory: %s" % error_string(error))
```

Validate the ID before constructing any path:

```gdscript
func _is_valid_slot(slot: String) -> bool:
	if slot.is_empty() or slot.length() > MAX_SLOT_LENGTH:
		return false
	for index in slot.length():
		var code := slot.unicode_at(index)
		var is_digit := code >= 48 and code <= 57
		var is_upper := code >= 65 and code <= 90
		var is_lower := code >= 97 and code <= 122
		if not is_digit and not is_upper and not is_lower and code != 45 and code != 95:
			return false
	return true


func _paths(slot: String) -> Dictionary:
	assert(_is_valid_slot(slot))
	var primary := "%s/%s%s" % [SAVE_DIR, slot, SAVE_EXTENSION]
	return {
		"primary": primary,
		"backup": primary + BACKUP_EXTENSION,
		"temporary": primary + TEMP_EXTENSION,
	}
```

This allowlist rejects separators, traversal, absolute paths, whitespace, and suffix injection.

## Atomic publication with backup

```gdscript
func save_snapshot(slot: String, data: Dictionary) -> bool:
	if not _is_valid_slot(slot):
		push_error("Invalid save slot")
		return false
	if not _validate_current_schema(data):
		return false

	var encoded := JSON.stringify(data)
	if encoded.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		push_error("Save exceeds byte limit")
		return false

	var paths := _paths(slot)
	_remove_if_present(paths.temporary)
	var file := FileAccess.open(paths.temporary, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open temporary save: %s" % FileAccess.get_open_error())
		return false
	file.store_string(encoded)
	file.flush()
	file.close()

	if FileAccess.file_exists(paths.backup):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(paths.backup))
		if remove_error != OK:
			_remove_if_present(paths.temporary)
			return false

	var moved_primary := false
	if FileAccess.file_exists(paths.primary):
		var backup_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(paths.primary),
			ProjectSettings.globalize_path(paths.backup),
		)
		if backup_error != OK:
			_remove_if_present(paths.temporary)
			return false
		moved_primary = true

	var publish_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(paths.temporary),
		ProjectSettings.globalize_path(paths.primary),
	)
	if publish_error == OK:
		return true

	push_error("Cannot publish save: %s" % error_string(publish_error))
	if moved_primary:
		var rollback_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(paths.backup),
			ProjectSettings.globalize_path(paths.primary),
		)
		if rollback_error != OK:
			push_error("Cannot restore backup: %s" % error_string(rollback_error))
	_remove_if_present(paths.temporary)
	return false


func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if error != OK:
			push_warning("Cannot remove '%s': %s" % [path, error_string(error)])
```

Keep temporary and primary files in the same directory so publication does not cross filesystem boundaries. This sequence retains the previous complete primary as a backup; it cannot promise stronger durability than the platform filesystem or browser storage provides.

## Bounded load and recovery

```gdscript
func load_snapshot(slot: String) -> Dictionary:
	if not _is_valid_slot(slot):
		push_error("Invalid save slot")
		return {}
	var paths := _paths(slot)
	var data := _read_and_validate(paths.primary)
	if not data.is_empty():
		return data
	data = _read_and_validate(paths.backup)
	if not data.is_empty():
		push_warning("Recovered save slot '%s' from backup" % slot)
	return data


func _read_and_validate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var length := file.get_length()
	if length <= 0 or length > MAX_SAVE_BYTES:
		file.close()
		return {}
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data := parsed as Dictionary
	if not _validate_version_envelope(data):
		return {}
	data["version"] = int(data["version"])
	data = _migrate(data.duplicate(true))
	if not _validate_current_schema(data):
		return {}
	return data
```

Using `{}` as failure requires the current schema to reject an empty dictionary. A production API may return a result object with an error enum so the UI can distinguish missing, corrupt, unsupported, and recovered saves.

## Schema gates

```gdscript
func _validate_version_envelope(data: Dictionary) -> bool:
	if not data.has("version") or not _is_json_integer(data.version):
		return false
	var version := int(data.version)
	return version >= 1 and version <= CURRENT_VERSION


func _validate_current_schema(data: Dictionary) -> bool:
	if not _validate_version_envelope(data) or data.version != CURRENT_VERSION:
		return false
	if not data.has("player") or typeof(data.player) != TYPE_DICTIONARY:
		return false
	var player := data.player as Dictionary
	if not player.has("health") or not _is_json_integer(player.health):
		return false
	var health := int(player.health)
	if health < 0 or health > 100000:
		return false
	if not player.has("inventory") or typeof(player.inventory) != TYPE_ARRAY:
		return false
	if player.inventory.size() > MAX_INVENTORY_ITEMS:
		return false
	for item_id in player.inventory:
		if typeof(item_id) != TYPE_STRING or (item_id as String).length() > 64:
			return false
	return true


func _is_json_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	var number := value as float
	return is_finite(number) and number == floorf(number)
```

Extend the validator for every field consumed by apply logic. Saved scene paths should be replaced by stable IDs resolved through an application-owned allowlist.

## Migration boundary

Run one migration per historical version and increment the version after each successful step. Reject future versions. Never apply a partially migrated dictionary to live nodes. See [version-migration.md](version-migration.md) for the migration shape, then validate the current schema again.

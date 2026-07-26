class_name SettingsStore
extends RefCounted

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION_AUDIO: String = "audio"
const SECTION_VIDEO: String = "video"
const SECTION_GAMEPLAY: String = "gameplay"
const EFFECTS_QUALITIES: Array[String] = ["low", "medium", "high"]
const DEFAULT_MASTER_VOLUME: int = 80
const DEFAULT_EFFECTS_QUALITY: String = "medium"
const DEFAULT_REDUCED_MOTION: bool = false
const DEFAULT_GLOBAL_AUTO_SKILL: bool = false
const DEFAULT_LOCAL_PLAYTEST_LOGGING: bool = false

var settings_path: String = SETTINGS_PATH
var master_volume: int = DEFAULT_MASTER_VOLUME
var effects_quality: String = DEFAULT_EFFECTS_QUALITY
var reduced_motion: bool = DEFAULT_REDUCED_MOTION
var global_auto_skill: bool = DEFAULT_GLOBAL_AUTO_SKILL
var local_playtest_logging: bool = DEFAULT_LOCAL_PLAYTEST_LOGGING


func _init(path: String = SETTINGS_PATH) -> void:
	settings_path = path


func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	effects_quality = DEFAULT_EFFECTS_QUALITY
	reduced_motion = DEFAULT_REDUCED_MOTION
	global_auto_skill = DEFAULT_GLOBAL_AUTO_SKILL
	local_playtest_logging = DEFAULT_LOCAL_PLAYTEST_LOGGING


func to_dictionary() -> Dictionary:
	return {
		"master_volume": master_volume,
		"effects_quality": effects_quality,
		"reduced_motion": reduced_motion,
		"global_auto_skill": global_auto_skill,
		"local_playtest_logging": local_playtest_logging,
	}


func apply_values(values: Dictionary) -> void:
	master_volume = _normalize_master_volume(values.get("master_volume", master_volume))
	effects_quality = _normalize_effects_quality(values.get("effects_quality", effects_quality))
	reduced_motion = _normalize_bool(values.get("reduced_motion", reduced_motion), reduced_motion)
	global_auto_skill = _normalize_bool(values.get("global_auto_skill", global_auto_skill), global_auto_skill)
	local_playtest_logging = _normalize_bool(values.get("local_playtest_logging", local_playtest_logging), local_playtest_logging)


func load_settings() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(settings_path)
	if err != OK:
		reset_to_defaults()
		return {"ok": false, "error": "SETTINGS_NOT_FOUND" if err == ERR_FILE_NOT_FOUND else "SETTINGS_LOAD_FAILED"}
	if not _apply_config(config):
		reset_to_defaults()
		return {"ok": false, "error": "SETTINGS_CORRUPT"}
	return {"ok": true, "settings": to_dictionary()}


func save_settings() -> bool:
	var config := ConfigFile.new()
	_write_config(config)
	return _save_config_safely(config)


func set_master_volume(value: Variant) -> void:
	master_volume = _normalize_master_volume(value)


func set_effects_quality(value: Variant) -> void:
	effects_quality = _normalize_effects_quality(value)


func set_reduced_motion(value: Variant) -> void:
	reduced_motion = _normalize_bool(value, reduced_motion)


func set_global_auto_skill(value: Variant) -> void:
	global_auto_skill = _normalize_bool(value, global_auto_skill)


func set_local_playtest_logging(value: Variant) -> void:
	local_playtest_logging = _normalize_bool(value, local_playtest_logging)


func _apply_config(config: ConfigFile) -> bool:
	if not config.has_section_key(SECTION_AUDIO, "master_volume"):
		return false
	if not config.has_section_key(SECTION_VIDEO, "effects_quality"):
		return false
	if not config.has_section_key(SECTION_VIDEO, "reduced_motion"):
		return false
	if not config.has_section_key(SECTION_GAMEPLAY, "global_auto_skill"):
		return false

	var loaded_values := {
		"master_volume": config.get_value(SECTION_AUDIO, "master_volume"),
		"effects_quality": config.get_value(SECTION_VIDEO, "effects_quality"),
		"reduced_motion": config.get_value(SECTION_VIDEO, "reduced_motion"),
		"global_auto_skill": config.get_value(SECTION_GAMEPLAY, "global_auto_skill"),
		"local_playtest_logging": config.get_value(
			SECTION_GAMEPLAY,
			"local_playtest_logging",
			DEFAULT_LOCAL_PLAYTEST_LOGGING
		),
	}
	if not _can_normalize(loaded_values):
		return false
	apply_values(loaded_values)
	return true


func _write_config(config: ConfigFile) -> void:
	config.set_value(SECTION_AUDIO, "master_volume", master_volume)
	config.set_value(SECTION_VIDEO, "effects_quality", effects_quality)
	config.set_value(SECTION_VIDEO, "reduced_motion", reduced_motion)
	config.set_value(SECTION_GAMEPLAY, "global_auto_skill", global_auto_skill)
	config.set_value(SECTION_GAMEPLAY, "local_playtest_logging", local_playtest_logging)


func _save_config_safely(config: ConfigFile) -> bool:
	var tmp_path := settings_path + ".tmp"
	var bak_path := settings_path + ".bak"
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)
	var save_error := config.save(tmp_path)
	if save_error != OK:
		return false
	var validation_config := ConfigFile.new()
	if validation_config.load(tmp_path) != OK or not _config_matches(validation_config):
		DirAccess.remove_absolute(tmp_path)
		return false
	if FileAccess.file_exists(settings_path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		if DirAccess.rename_absolute(settings_path, bak_path) != OK:
			DirAccess.remove_absolute(tmp_path)
			return false
	if DirAccess.rename_absolute(tmp_path, settings_path) != OK:
		if FileAccess.file_exists(bak_path) and not FileAccess.file_exists(settings_path):
			DirAccess.rename_absolute(bak_path, settings_path)
		return false
	return true


func _config_matches(config: ConfigFile) -> bool:
	var previous := to_dictionary()
	if not _apply_config(config):
		apply_values(previous)
		return false
	var matches := to_dictionary() == previous
	apply_values(previous)
	return matches


func _can_normalize(values: Dictionary) -> bool:
	return (
		_is_number_like(values.get("master_volume"))
		and _is_string_like(values.get("effects_quality"))
		and _is_bool_like(values.get("reduced_motion"))
		and _is_bool_like(values.get("global_auto_skill"))
		and _is_bool_like(values.get("local_playtest_logging"))
	)


func _normalize_master_volume(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return clampi(value, 0, 100)
	if typeof(value) == TYPE_FLOAT:
		return clampi(roundi(value), 0, 100)
	if typeof(value) == TYPE_STRING and String(value).is_valid_int():
		return clampi(int(String(value)), 0, 100)
	return DEFAULT_MASTER_VOLUME


func _normalize_effects_quality(value: Variant) -> String:
	var normalized := String(value).to_lower()
	if normalized in EFFECTS_QUALITIES:
		return normalized
	return DEFAULT_EFFECTS_QUALITY


func _normalize_bool(value: Variant, fallback: bool) -> bool:
	if typeof(value) == TYPE_BOOL:
		return bool(value)
	if typeof(value) == TYPE_STRING:
		var normalized := String(value).to_lower()
		if normalized == "true":
			return true
		if normalized == "false":
			return false
	return fallback


func _is_number_like(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT or (typeof(value) == TYPE_STRING and String(value).is_valid_int())


func _is_string_like(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME


func _is_bool_like(value: Variant) -> bool:
	return typeof(value) == TYPE_BOOL or (typeof(value) == TYPE_STRING and String(value).to_lower() in ["true", "false"])

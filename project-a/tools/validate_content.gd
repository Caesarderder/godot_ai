extends SceneTree

const RELEASE_VERSION := "0.1.0-vertical-slice"
const ANDROID_PACKAGE := "com.geekcaesar.godotai.projecta"

var _failures: Array[String] = []


func _initialize() -> void:
	_check_project_settings()
	_check_export_presets()

	if _failures.is_empty():
		print("release content validation passed.")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _check_project_settings() -> void:
	_expect_eq(
		ProjectSettings.get_setting("application/config/version", ""),
		RELEASE_VERSION,
		"application/config/version"
	)
	_expect_eq(
		ProjectSettings.get_setting("rendering/renderer/rendering_method", ""),
		"mobile",
		"rendering/renderer/rendering_method"
	)
	_expect_eq(
		ProjectSettings.get_setting("display/window/stretch/mode", ""),
		"canvas_items",
		"display/window/stretch/mode"
	)
	_expect_eq(
		ProjectSettings.get_setting("display/window/stretch/aspect", ""),
		"expand",
		"display/window/stretch/aspect"
	)
	_expect_eq(
		ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false),
		true,
		"rendering/textures/vram_compression/import_etc2_astc"
	)


func _check_export_presets() -> void:
	var config := ConfigFile.new()
	var load_error := config.load("res://export_presets.cfg")
	if load_error != OK:
		_failures.append("export_presets.cfg could not be loaded: error %d" % load_error)
		return

	var windows_debug := _find_preset(config, "Windows Desktop Debug")
	var windows_release := _find_preset(config, "Windows Desktop Release")
	var android_release := _find_preset(config, "Android Release")

	_require_preset(config, windows_debug, "Windows Desktop Debug", "Windows Desktop")
	_require_preset(config, windows_release, "Windows Desktop Release", "Windows Desktop")
	_require_preset(config, android_release, "Android Release", "Android")

	if android_release == "":
		return

	var android_options := "%s.options" % android_release
	_expect_cfg_eq(config, android_options, "package/unique_name", ANDROID_PACKAGE)
	_expect_cfg_eq(config, android_options, "package/signed", true)
	_expect_cfg_eq(config, android_options, "version/name", RELEASE_VERSION)
	_expect_cfg_eq(config, android_options, "texture_format/etc2_astc", true)
	_expect_cfg_eq(config, android_options, "texture_format/s3tc_bptc", false)
	_expect_cfg_eq(config, android_options, "keystore/release", "")
	_expect_cfg_eq(config, android_options, "keystore/release_user", "")
	_expect_cfg_eq(config, android_options, "keystore/release_password", "")

	for key in config.get_section_keys(android_options):
		if not key.begins_with("permissions/"):
			continue
		var value: Variant = config.get_value(android_options, key)
		if value is bool and value:
			_failures.append("Android permission must stay disabled unless intentionally reviewed: %s" % key)
		if key == "permissions/custom_permissions" and value is PackedStringArray and not value.is_empty():
			_failures.append("Android custom permissions must stay empty.")


func _find_preset(config: ConfigFile, preset_name: String) -> String:
	for section in config.get_sections():
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		if config.get_value(section, "name", "") == preset_name:
			return section
	return ""


func _require_preset(config: ConfigFile, section: String, preset_name: String, platform: String) -> void:
	if section == "":
		_failures.append("Missing export preset: %s" % preset_name)
		return
	_expect_cfg_eq(config, section, "platform", platform)
	var options_section := "%s.options" % section
	if not config.has_section(options_section):
		_failures.append("Missing options section for preset: %s" % preset_name)


func _expect_cfg_eq(config: ConfigFile, section: String, key: String, expected: Variant) -> void:
	if not config.has_section_key(section, key):
		_failures.append("Missing export preset key: %s/%s" % [section, key])
		return
	_expect_eq(config.get_value(section, key), expected, "%s/%s" % [section, key])


func _expect_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures.append("%s expected %s, got %s" % [label, var_to_str(expected), var_to_str(actual)])

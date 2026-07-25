extends SceneTree

const SettingsStoreScript := preload("res://game/scripts/platform/settings_store.gd")
const WebRuntimeScript := preload("res://game/scripts/platform/web_runtime.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_settings_defaults()
	_test_settings_roundtrip()
	_test_settings_corrupt_file_returns_defaults()
	_test_settings_normalizes_ranges()
	_test_web_runtime_capabilities_and_state()
	if failures.is_empty():
		print("PLATFORM TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PLATFORM TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _test_settings_defaults() -> void:
	var path := "user://platform_settings_defaults.cfg"
	_cleanup_settings(path)
	var store: RefCounted = SettingsStoreScript.new(path)
	var result: Dictionary = store.load_settings()
	_check(not bool(result.get("ok", true)), "missing settings reports a load miss")
	_eq(store.to_dictionary(), {
		"master_volume": 80,
		"effects_quality": "medium",
		"reduced_motion": false,
		"global_auto_skill": false,
	}, "missing settings falls back to defaults")
	_cleanup_settings(path)


func _test_settings_roundtrip() -> void:
	var path := "user://platform_settings_roundtrip.cfg"
	_cleanup_settings(path)
	var store: RefCounted = SettingsStoreScript.new(path)
	store.set_master_volume(42)
	store.set_effects_quality("high")
	store.set_reduced_motion(true)
	store.set_global_auto_skill(true)
	_check(store.save_settings(), "settings save succeeds")
	var loaded: RefCounted = SettingsStoreScript.new(path)
	var result: Dictionary = loaded.load_settings()
	_check(bool(result.get("ok", false)), "saved settings load")
	_eq(loaded.to_dictionary(), store.to_dictionary(), "settings roundtrip preserves values")
	_check(FileAccess.file_exists(path), "settings primary file exists")
	_cleanup_settings(path)


func _test_settings_corrupt_file_returns_defaults() -> void:
	var path := "user://platform_settings_corrupt.cfg"
	_cleanup_settings(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[audio]\nmaster_volume=\"loud\"\n")
	file.close()
	var store: RefCounted = SettingsStoreScript.new(path)
	store.set_master_volume(11)
	store.set_effects_quality("low")
	var result: Dictionary = store.load_settings()
	_check(not bool(result.get("ok", true)), "corrupt settings report failure")
	_eq(store.to_dictionary(), {
		"master_volume": 80,
		"effects_quality": "medium",
		"reduced_motion": false,
		"global_auto_skill": false,
	}, "corrupt settings resets to defaults")
	_cleanup_settings(path)


func _test_settings_normalizes_ranges() -> void:
	var path := "user://platform_settings_normalized.cfg"
	_cleanup_settings(path)
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", 140)
	config.set_value("video", "effects_quality", "LOW")
	config.set_value("video", "reduced_motion", "true")
	config.set_value("gameplay", "global_auto_skill", "false")
	_check(config.save(path) == OK, "raw config fixture writes")
	var store: RefCounted = SettingsStoreScript.new(path)
	var result: Dictionary = store.load_settings()
	_check(bool(result.get("ok", false)), "normalizable settings load")
	_eq(store.to_dictionary(), {
		"master_volume": 100,
		"effects_quality": "low",
		"reduced_motion": true,
		"global_auto_skill": false,
	}, "settings ranges and enums normalize")
	store.apply_values({
		"master_volume": -9,
		"effects_quality": "ultra",
		"reduced_motion": true,
		"global_auto_skill": true,
	})
	_eq(store.to_dictionary(), {
		"master_volume": 0,
		"effects_quality": "medium",
		"reduced_motion": true,
		"global_auto_skill": true,
	}, "direct setting mutation normalizes invalid values")
	_cleanup_settings(path)


func _test_web_runtime_capabilities_and_state() -> void:
	var runtime: Node = WebRuntimeScript.new()
	root.add_child(runtime)
	var capabilities: Dictionary = runtime.platform_capabilities()
	_check(capabilities.has("is_web"), "capabilities expose is_web")
	_check(capabilities.has("userfs_persistent"), "capabilities expose userfs persistence")
	_check(bool(capabilities.get("visibility_events", false)), "capabilities expose visibility support")
	_check(bool(capabilities.get("focus_events", false)), "capabilities expose focus support")
	var events: Array[String] = []
	runtime.focus_changed.connect(func(value: bool) -> void: events.append("focus:%s" % str(value)))
	runtime.visibility_changed.connect(func(value: bool) -> void: events.append("visible:%s" % str(value)))
	runtime.set_focus_state(false)
	runtime.set_visibility_state(false)
	runtime.set_visibility_state(false)
	var state: Dictionary = runtime.runtime_state()
	_eq(events, ["focus:false", "visible:false"], "runtime emits one signal per state transition")
	_eq(state["has_focus"], false, "runtime state tracks focus")
	_eq(state["is_visible"], false, "runtime state tracks visibility")
	_eq(state["is_interactive"], false, "runtime interactivity requires focus and visibility")
	runtime.queue_free()


func _cleanup_settings(path: String) -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

extends SceneTree

const SettingsStoreScript := preload("res://game/scripts/platform/settings_store.gd")
const WebRuntimeScript := preload("res://game/scripts/platform/web_runtime.gd")
const LocalPlaytestJournalScript := preload("res://game/scripts/platform/local_playtest_journal.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_settings_defaults()
	_test_settings_roundtrip()
	_test_settings_corrupt_file_returns_defaults()
	_test_settings_normalizes_ranges()
	_test_local_playtest_journal_opt_in_and_export()
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
			"local_playtest_logging": false,
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
	store.set_local_playtest_logging(true)
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
			"local_playtest_logging": false,
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
			"local_playtest_logging": false,
	}, "settings ranges and enums normalize")
	store.apply_values({
		"master_volume": -9,
		"effects_quality": "ultra",
			"reduced_motion": true,
			"global_auto_skill": true,
			"local_playtest_logging": false,
	})
	_eq(store.to_dictionary(), {
		"master_volume": 0,
		"effects_quality": "medium",
		"reduced_motion": true,
		"global_auto_skill": true,
		"local_playtest_logging": false,
	}, "direct setting mutation normalizes invalid values")
	_cleanup_settings(path)


func _test_local_playtest_journal_opt_in_and_export() -> void:
	var path := "user://platform_playtest_journal.json"
	_cleanup_settings(path)
	var journal: RefCounted = LocalPlaytestJournalScript.new(path)
	_check(not FileAccess.file_exists(path), "playtest journal creates no file before opt-in")
	_check(journal.set_enabled(true, "test-1", 1000), "playtest journal opt-in creates an atomic local report")
	_check(FileAccess.file_exists(path), "opted-in playtest journal persists locally")
	_check(journal.record_event("screen_view", {"screen": "base"}, 1005), "playtest journal records an allowed screen event")
	_check(journal.record_event("screen_view", {"screen": "base"}, 1006), "duplicate screen event is accepted without duplication")
	_check(journal.record_event("command_result", {
		"command_type": "upgrade_permanent_hero",
		"ok": true,
		"error": "",
		"revision_after": 2,
	}, 1010), "playtest journal records bounded command metadata")
	_check(not journal.record_event("free_form_note", {"text": "private"}, 1011), "playtest journal rejects non-whitelisted event types")
	_check(not journal.record_event("screen_view", {"screen": ["invalid"]}, 1011), "playtest journal rejects nested or unbounded details")
	var summary: Dictionary = journal.summary(1060)
	_eq(summary.get("event_count"), 3, "journal contains session start plus two unique events")
	_eq(summary.get("duration_seconds"), 60, "journal reports an explicit session time window")
	var exported: Dictionary = journal.export_report(1060)
	_check(bool(exported.get("ok", false)), "playtest report exports")
	var parsed: Variant = JSON.parse_string(String(exported.get("text", "")))
	_check(typeof(parsed) == TYPE_DICTIONARY, "playtest report export is JSON")
	if typeof(parsed) == TYPE_DICTIONARY:
		var report := parsed as Dictionary
		_eq(report.get("product_version"), "test-1", "playtest report declares its product version")
		_eq(int(report.get("event_count", 0)), 3, "playtest report declares its sample size")
		_eq(int(report.get("duration_seconds", 0)), 60, "playtest report declares its time window")
		_check(not report.has("save_id") and not report.has("device_id") and not report.has("account_id"), "playtest report has no player or device identifier fields")

	var resumed: RefCounted = LocalPlaytestJournalScript.new(path)
	_check(resumed.set_enabled(true, "test-1", 1070), "same-version journal resumes after reload")
	_eq((resumed.summary(1070) as Dictionary).get("event_count"), 3, "reload preserves bounded local events")
	for index in 270:
		resumed.record_event("screen_view", {"screen": "base" if index % 2 == 0 else "map"}, 1080 + index)
	_eq((resumed.summary(1400) as Dictionary).get("event_count"), LocalPlaytestJournalScript.MAX_EVENTS, "journal caps retained events")
	var capped_export: Dictionary = resumed.export_report(1400)
	var capped_report := JSON.parse_string(String(capped_export.get("text", ""))) as Dictionary
	var capped_events := capped_report.get("events", []) as Array
	_eq(int((capped_events[0] as Dictionary).get("sequence", 0)), 1, "journal renumbers retained events after cap eviction")
	_check(resumed.set_enabled(false, "test-1", 1401), "opting out clears the local report")
	for suffix in ["", ".tmp", ".bak"]:
		_check(not FileAccess.file_exists(path + suffix), "opt-out removes playtest journal%s" % suffix)


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
	root.remove_child(runtime)
	runtime.set_focus_state(true)
	runtime.set_visibility_state(true)
	_eq(events, ["focus:false", "visible:false"], "detached runtime does not emit teardown signals")
	_eq(runtime.runtime_state()["is_interactive"], true, "detached runtime still records final platform state")
	runtime.free()


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

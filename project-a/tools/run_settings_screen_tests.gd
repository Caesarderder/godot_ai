extends SceneTree

const SETTINGS_SCENE := preload("res://game/scenes/screens/settings_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings := SETTINGS_SCENE.instantiate() as Control
	settings.call("configure", {
		"master_volume": 37,
		"effects_quality": "high",
		"reduced_motion": true,
		"global_auto_skill": true,
		"local_playtest_logging": false,
		"storage_persistent": false,
		"persistence_copy": "浏览器未确认持久存储，请立即下载备份。",
		"has_import_preview": false,
		"delete_armed": false,
	})
	root.add_child(settings)
	await process_frame
	await process_frame
	await process_frame
	var volume := settings.get_node("%SettingsMasterVolumeSlider") as HSlider
	var quality := settings.get_node("%SettingsEffectsQualityOption") as OptionButton
	var reduced := settings.get_node("%SettingsReducedMotionToggle") as CheckButton
	var playtest_status := settings.get_node("%SettingsPlaytestStatus") as Label
	var import_button := settings.get_node("%SettingsImportSaveButton") as Button
	var save := settings.get_node("%SettingsSaveButton") as Button
	_check(is_equal_approx(volume.value, 37.0), "master volume is projected")
	_check(quality.get_item_text(quality.selected) == "high", "effects quality is projected")
	_check(reduced.button_pressed, "reduced motion is projected")
	_check(not playtest_status.visible, "playtest details stay hidden before opt-in")
	_check(import_button.text == "选择备份并校验", "import starts with validation intent")
	_check(save.has_focus(), "save action receives initial focus")

	var changed := {"id": "", "value": null}
	settings.connect("setting_changed", func(id: String, value: Variant) -> void:
		changed["id"] = id
		changed["value"] = value
	)
	volume.value = 42
	_check(changed["id"] == "master_volume" and is_equal_approx(float(changed["value"]), 42.0), "volume emits semantic setting change")

	var requested := {"id": ""}
	settings.connect("action_requested", func(id: String) -> void: requested["id"] = id)
	import_button.pressed.emit()
	_check(requested["id"] == "import_save", "import emits semantic action")

	settings.call("configure", {
		"master_volume": 42,
		"effects_quality": "medium",
		"reduced_motion": false,
		"global_auto_skill": false,
		"local_playtest_logging": true,
		"playtest_status": "已记录 12 条本地事件 · 4 分钟 · 不含设备或账号标识",
		"storage_persistent": true,
		"persistence_copy": "浏览器存储当前可持久化；仍建议定期下载备份。",
		"has_import_preview": true,
		"import_preview": "待导入：4 城 · 3 名英雄 · 修订 9（再次点击确认）",
		"delete_armed": true,
	})
	_check(playtest_status.visible and playtest_status.text.contains("不含设备"), "opt-in playtest scope is projected")
	_check(import_button.text == "确认覆盖当前进度", "validated import requires confirmation")
	_check((settings.get_node("%SettingsImportPreview") as Label).visible, "validated import preview is visible")
	_check((settings.get_node("%SettingsDeleteLocalSaveButton") as Button).text.contains("再次点击"), "delete requires a second click")

	settings.queue_free()
	await process_frame
	if failures.is_empty():
		print("SETTINGS_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SETTINGS_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

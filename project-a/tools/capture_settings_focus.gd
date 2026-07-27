extends SceneTree

const SETTINGS_SCENE := preload("res://game/scenes/screens/settings_screen.tscn")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	var background := ColorRect.new()
	background.color = Color("#070b0f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	background.add_child(margin)
	var settings := SETTINGS_SCENE.instantiate() as Control
	settings.call("configure", {
		"master_volume": 37,
		"music_volume": 55,
		"effects_quality": "medium",
		"reduced_motion": false,
		"global_auto_skill": false,
		"local_playtest_logging": false,
		"storage_persistent": false,
		"persistence_copy": "浏览器未确认持久存储，请立即下载备份。",
		"has_import_preview": false,
		"delete_armed": false,
	})
	margin.add_child(settings)
	for _frame in 4:
		await process_frame
	var slider := settings.get_node("%SettingsMasterVolumeSlider") as HSlider
	slider.grab_focus()
	for _frame in 3:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var path := "res://artifacts/ui-settings-slider-focus-844x390.png"
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("SETTINGS FOCUS CAPTURE FAIL: %s" % error_string(error))
		quit(1)
		return
	print("SETTINGS_FOCUS_CAPTURE_OK: %s" % path)
	quit(0)

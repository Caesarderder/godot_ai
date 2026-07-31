extends SceneTree

const TITLE_SCENE := preload("res://game/scenes/screens/title_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var title := TITLE_SCENE.instantiate() as Control
	title.call("configure", {
		"primary_label": "率领Gman · 进入 E07",
		"summary": "已夺回 0 座城镇 · 1 名战士仍在回应",
		"objective": "当前目标 · 摧毁联盟前哨 1-1",
		"storage_blocked": true,
	})
	var host := Control.new()
	host.size = Vector2(568, 320)
	root.add_child(host)
	host.add_child(title)
	await process_frame
	await process_frame
	await process_frame
	var primary_button := title.get_node("%TitlePrimaryButton") as Button
	var settings_button := title.get_node("%TitleSettingsButton") as Button
	var help_button := title.get_node("%TitleHelpButton") as Button
	var progress_summary := title.get_node("%TitleProgressSummary") as Label
	var next_objective := title.get_node("%TitleNextObjective") as Label
	var storage_warning := title.get_node("%TitleStorageWarning") as Label
	var background := title.get_node("Background") as TextureRect
	_check(
		background.texture != null and background.texture.get_size() == Vector2(844, 390),
		"title screen uses the lightweight anime toilet-resistance landscape background"
	)
	_check(primary_button.text.contains("进入 E07"), "new-save primary action is canon-anchored")
	_check(progress_summary.text.contains("1 名战士"), "durable roster summary is projected")
	_check(next_objective.text.contains("摧毁联盟前哨 1-1"), "next objective is projected")
	_check(storage_warning.visible and storage_warning.text.contains("未允许保存"), "blocked browser storage is explicit before play")
	_check(not progress_summary.is_visible_in_tree(), "title keeps progress prose out of the hero composition")
	_check(not next_objective.is_visible_in_tree(), "title keeps objective prose out of the hero composition")
	_check(settings_button.text == "⚙" and help_button.text == "?", "secondary title actions are icon-led")
	_check(primary_button.has_focus(), "primary action receives initial focus")
	for control in [primary_button, settings_button, help_button]:
		var rect := (control as Control).get_global_rect()
		_check(
			rect.position.x >= 0.0
				and rect.end.x <= 568.0
				and rect.position.y >= 0.0
				and rect.end.y <= 320.0,
			"title action fits the 568x320 compact landscape fixture: %s" % rect
		)
	_check(
		primary_button.get_theme_stylebox("focus") is StyleBoxTexture,
		"primary action owns a visible focus style"
	)

	var requested := {"id": ""}
	title.connect("action_requested", func(action_id: String) -> void: requested["id"] = action_id)
	primary_button.pressed.emit()
	_check(requested["id"] == "primary", "primary button emits a semantic action")
	settings_button.pressed.emit()
	_check(requested["id"] == "settings", "settings button emits a semantic action")
	help_button.pressed.emit()
	_check(requested["id"] == "help", "help button emits a semantic action")

	title.call("configure", {
		"primary_label": "返回指挥室",
		"summary": "已夺回 3 座城镇 · 3 名战士仍在回应",
		"objective": "前线等待命令 · E10 · 监控人增援",
		"storage_blocked": false,
	})
	_check(primary_button.text == "返回指挥室", "returning-save primary action updates in place")
	_check(next_objective.text.contains("E10 · 监控人增援"), "returning-save objective updates in place")
	_check(not storage_warning.visible, "normal storage does not show a false blocking warning")

	title.call("configure", {
		"primary_label": "重返前线",
		"summary": "已夺回 25 座城镇 · 8 名战士仍在回应",
		"objective": "E10 防线已崩溃，战争仍未结束",
	})
	_check(primary_button.text == "重返前线", "completed-campaign action updates in place")
	title.queue_free()
	await process_frame
	if failures.is_empty():
		print("TITLE_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("TITLE_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

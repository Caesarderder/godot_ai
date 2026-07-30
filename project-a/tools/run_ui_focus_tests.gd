extends SceneTree

const SCENES: Array[PackedScene] = [
	preload("res://game/scenes/screens/war_zone_screen.tscn"),
	preload("res://game/scenes/screens/battle_hud_screen.tscn"),
	preload("res://game/scenes/screens/battle_result_screen.tscn"),
	preload("res://game/scenes/screens/legion_screen.tscn"),
	preload("res://game/scenes/screens/factory_screen.tscn"),
	preload("res://game/scenes/screens/goals_screen.tscn"),
	preload("res://game/scenes/ui/stage_detail_panel.tscn"),
	preload("res://game/scenes/screens/title_screen.tscn"),
	preload("res://game/scenes/screens/settings_screen.tscn"),
	preload("res://game/scenes/screens/help_screen.tscn"),
	preload("res://game/scenes/screens/blueprint_screen.tscn"),
	preload("res://game/scenes/screens/epilogue_screen.tscn"),
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_index in SCENES.size():
		var scene := SCENES[scene_index]
		var instance := scene.instantiate() as Control
		root.add_child(instance)
		await process_frame
		await process_frame
		await process_frame
		var controls: Array[Control] = []
		_collect_interactive_controls(instance, controls)
		if scene_index != 0:
			_check(not controls.is_empty(), "%s exposes no authored focus targets" % instance.name)
		for control in controls:
			_assert_interactive_focus_contract(control, "%s/%s" % [instance.name, control.name])
		var first_enabled := _first_enabled(controls)
		if first_enabled != null:
			first_enabled.grab_focus()
			await process_frame
			_check(
				root.gui_get_focus_owner() == first_enabled,
				"%s cannot acquire keyboard focus" % first_enabled.name
			)
			if _enabled_count(controls) > 1:
				var next_focus := first_enabled.find_next_valid_focus()
				_check(
					next_focus != null and next_focus != first_enabled,
					"%s has no forward keyboard/gamepad focus route" % instance.name
				)
		instance.queue_free()
		await process_frame

	var goals := SCENES[5].instantiate() as Control
	var goal_button := goals.call("_button", "测试行动", true) as Button
	_assert_focus_contract(goal_button, "GoalsScreen dynamic button")
	goal_button.free()
	goals.free()

	var factory := SCENES[4].instantiate() as Control
	var factory_button := factory.call("_button", "测试建造", true) as Button
	_assert_focus_contract(factory_button, "FactoryScreen dynamic button")
	factory_button.free()
	factory.free()

	var legion := SCENES[3].instantiate() as Control
	var legion_button := legion.call("_button", "测试阵位", true) as Button
	_assert_focus_contract(legion_button, "LegionScreen dynamic button")
	legion_button.free()
	legion.free()

	var war_zone := SCENES[0].instantiate() as Control
	var war_button := war_zone.call("_button", "测试关卡", false) as Button
	_assert_focus_contract(war_button, "WarZoneScreen dynamic button")
	war_button.free()
	war_zone.free()

	var battle_hud := SCENES[1].instantiate() as Control
	var card := battle_hud.call("_build_unit_card", {
		"hero_id": "gman",
		"display_name": "Gman",
		"max_hp": 100,
	}) as Dictionary
	var skill_button := card.get("button") as Button
	_assert_focus_contract(skill_button, "BattleHudScreen skill overlay")
	(card.get("root") as Node).free()
	battle_hud.free()

	if failures.is_empty():
		print("UI_FOCUS_TESTS_OK: authored and dynamic screen controls expose visible focus")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("UI_FOCUS_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _collect_interactive_controls(node: Node, output: Array[Control]) -> void:
	if node is BaseButton or node is Slider or node is LineEdit or node is TextEdit:
		output.append(node as Control)
	for child in node.get_children():
		_collect_interactive_controls(child, output)


func _first_enabled(controls: Array[Control]) -> Control:
	for control in controls:
		if _is_enabled(control):
			return control
	return null


func _enabled_count(controls: Array[Control]) -> int:
	var count := 0
	for control in controls:
		if _is_enabled(control):
			count += 1
	return count


func _is_enabled(control: Control) -> bool:
	if control is BaseButton:
		return not (control as BaseButton).disabled
	if control is Slider:
		return (control as Slider).editable
	if control is LineEdit:
		return (control as LineEdit).editable
	if control is TextEdit:
		return (control as TextEdit).editable
	return false


func _assert_interactive_focus_contract(control: Control, context: String) -> void:
	_check(control.focus_mode == Control.FOCUS_ALL, "%s is not keyboard/gamepad focusable" % context)
	if control is Slider:
		_check(
			control.has_theme_stylebox_override("grabber_area_highlight"),
			"%s has no visible focused/hovered slider track" % context
		)
		var highlight := control.get_theme_stylebox("grabber_area_highlight")
		_check(
			highlight != null and not highlight is StyleBoxEmpty,
			"%s slider focus highlight is invisible" % context
		)
		return
	_assert_focus_style(control, context)


func _assert_focus_contract(button: Button, context: String) -> void:
	_check(button != null, "%s is missing" % context)
	if button == null:
		return
	_check(button.focus_mode == Control.FOCUS_ALL, "%s is not keyboard/gamepad focusable" % context)
	_assert_focus_style(button, context)


func _assert_focus_style(control: Control, context: String) -> void:
	_check(control.has_theme_stylebox_override("focus"), "%s has no explicit focus style" % context)
	var focus_style := control.get_theme_stylebox("focus")
	_check(focus_style != null and not focus_style is StyleBoxEmpty, "%s focus style is invisible" % context)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

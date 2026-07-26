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
		var buttons: Array[Button] = []
		_collect_buttons(instance, buttons)
		if scene_index != 0:
			_check(not buttons.is_empty(), "%s exposes no authored focus targets" % instance.name)
		for button in buttons:
			_assert_focus_contract(button, "%s/%s" % [instance.name, button.name])
		var first_enabled := _first_enabled(buttons)
		if first_enabled != null:
			first_enabled.grab_focus()
			await process_frame
			_check(
				root.gui_get_focus_owner() == first_enabled,
				"%s cannot acquire keyboard focus" % first_enabled.name
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


func _collect_buttons(node: Node, output: Array[Button]) -> void:
	if node is Button:
		output.append(node as Button)
	for child in node.get_children():
		_collect_buttons(child, output)


func _first_enabled(buttons: Array[Button]) -> Button:
	for button in buttons:
		if not button.disabled:
			return button
	return null


func _assert_focus_contract(button: Button, context: String) -> void:
	_check(button != null, "%s is missing" % context)
	if button == null:
		return
	_check(button.focus_mode == Control.FOCUS_ALL, "%s is not keyboard/gamepad focusable" % context)
	_check(button.has_theme_stylebox_override("focus"), "%s has no explicit focus style" % context)
	var focus_style := button.get_theme_stylebox("focus")
	_check(focus_style != null and not focus_style is StyleBoxEmpty, "%s focus style is invisible" % context)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

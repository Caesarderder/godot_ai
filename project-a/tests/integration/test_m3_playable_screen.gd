extends GutTest

const MAIN_SCENE := preload("res://game/scenes/app/main.tscn")


func test_m3_screen_exposes_battlefield_controls_and_touch_targets() -> void:
	var screen := MAIN_SCENE.instantiate()
	add_child_autofree(screen)
	await get_tree().process_frame

	var arena := screen.get_node("SafeArea/BattleScreen/Arena") as BattleArena
	assert_true(arena.visible)
	assert_gte(arena.custom_minimum_size.y, 600.0)
	for path: String in [
		"SafeArea/BattleScreen/StageSelector/Stage11",
		"SafeArea/BattleScreen/StageSelector/Stage12",
		"SafeArea/BattleScreen/StageSelector/Stage13",
		"SafeArea/BattleScreen/ActionButtons/StartButton",
	]:
		var button := screen.get_node(path) as Button
		assert_gte(button.custom_minimum_size.y, 48.0, "%s is touch friendly" % path)
	assert_not_null(screen.get_node_or_null("SafeArea/BattleScreen/LogPanel/LogRows/BattleLog"))


func test_start_button_drives_a_real_battle_session_and_presents_five_units() -> void:
	var screen := MAIN_SCENE.instantiate()
	add_child_autofree(screen)
	await get_tree().process_frame

	var start := screen.get_node("SafeArea/BattleScreen/ActionButtons/StartButton") as Button
	start.pressed.emit()
	assert_true(screen.has_active_battle())
	var arena := screen.get_node("SafeArea/BattleScreen/Arena") as BattleArena
	assert_eq(arena.presented_unit_count(), 5)
	_drive_to_result(screen)
	assert_not_null(screen.get_battle_result())
	assert_gt(screen.get_battle_result().events.size(), 0)


func test_stage_1_3_failure_can_adjust_formation_and_win_on_retry() -> void:
	var screen := MAIN_SCENE.instantiate()
	add_child_autofree(screen)
	await get_tree().process_frame

	var stage_13 := screen.get_node("SafeArea/BattleScreen/StageSelector/Stage13") as Button
	var start := screen.get_node("SafeArea/BattleScreen/ActionButtons/StartButton") as Button
	var adjust := screen.get_node("SafeArea/BattleScreen/ActionButtons/FormationButton") as Button
	stage_13.pressed.emit()
	start.pressed.emit()
	_drive_to_result(screen)
	assert_eq(screen.get_battle_result().outcome, "defeat")
	assert_true(adjust.visible)

	adjust.pressed.emit()
	assert_true(screen.has_active_battle())
	_drive_to_result(screen)
	assert_eq(screen.get_battle_result().outcome, "victory")
	var battle_log := screen.get_node("SafeArea/BattleScreen/LogPanel/LogRows/BattleLog") as RichTextLabel
	assert_string_contains(battle_log.get_parsed_text(), "set_formation")


func _drive_to_result(screen: Control) -> void:
	var guard := 0
	while screen.has_active_battle() and guard < 2000:
		screen._process(0.2)
		guard += 1
	assert_lt(guard, 2000, "battle completes before the safety guard")

extends SceneTree

const HELP_SCENE := preload("res://game/scenes/screens/help_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var help := HELP_SCENE.instantiate() as Control
	help.call("configure", {"version": "0.11.0-test"})
	root.add_child(help)
	await process_frame
	await process_frame
	await process_frame
	var all_text := _collect_text(help)
	_check(all_text.contains("大目标、中目标、小目标"), "default help topic points players to the objective ladder")
	var recovery := help.get_node("%HelpRecoveryTab") as Button
	recovery.pressed.emit()
	await process_frame
	all_text = _collect_text(help)
	_check(all_text.contains("1-2、1-3"), "recovery topic explains the deterministic reinforcement path")
	_check(all_text.contains("信号招募") and all_text.contains("图纸") and all_text.contains("研究所逐张研发"), "recovery topic explains the signal-to-research role path")
	_check(all_text.contains("冲锋二星") and all_text.contains("装甲二星"), "recovery topic compares both recovery routes")
	_check(all_text.contains("完全恢复"), "recovery topic explains lossless battle recovery")
	var data := help.get_node("%HelpDataTab") as Button
	data.pressed.emit()
	await process_frame
	all_text = _collect_text(help)
	_check(all_text.contains("不使用分析 SDK"), "data topic explains local-data privacy")
	_check(all_text.contains("0.11.0-test"), "data topic projects the runtime version")
	var columns := help.get_node("HelpLandscapeColumns") as HBoxContainer
	_check(columns.get_child_count() == 2, "help keeps two independent landscape columns")
	var back := help.get_node("%HelpBackButton") as Button
	var now := help.get_node("%HelpNowTab") as Button
	var topic_grid := help.get_node(
		"HelpLandscapeColumns/HelpGameplayScroll/HelpTopicRail"
	) as GridContainer
	var step_row := help.get_node("%HelpStepRow") as HBoxContainer
	_check(
		now.custom_minimum_size.y >= 48.0
			and recovery.custom_minimum_size.y >= 48.0
			and data.custom_minimum_size.y >= 48.0,
		"help topic navigation remains touch sized"
	)
	_check(
		topic_grid.columns == 2
			and now.icon != null
			and recovery.icon != null
			and data.icon != null,
		"help presents four icon-led topics as a two-column field manual"
	)
	_check(
		step_row.get_child_count() == 3
			and step_row.get_child(0).name == "HelpStepCard_1"
			and (step_row.get_child(0) as Control).custom_minimum_size.y >= 68.0,
		"each help topic renders three compact visual instruction cards"
	)
	_check(
		back.icon != null and back.custom_minimum_size.y >= 48.0,
		"help keeps an icon-led touch-ready return action"
	)
	_check(
		help.get_viewport().gui_get_focus_owner() != null,
		"help maintains keyboard and gamepad focus while switching topics"
	)
	var requested := {"back": false}
	help.connect("back_requested", func() -> void: requested["back"] = true)
	back.pressed.emit()
	_check(requested["back"], "back emits a semantic request")

	help.queue_free()
	await process_frame
	if failures.is_empty():
		print("HELP_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("HELP_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _collect_text(node: Node) -> String:
	var result := ""
	if node is Label:
		result += (node as Label).text + "\n"
	for child in node.get_children():
		result += _collect_text(child)
	return result


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

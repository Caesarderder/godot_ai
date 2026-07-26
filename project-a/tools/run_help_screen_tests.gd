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
	_check(all_text.contains("1-4"), "help explains the first deliberate hurdle")
	_check(all_text.contains("免费突破十连"), "help explains the research breakthrough reward")
	_check(all_text.contains("冲锋二星") and all_text.contains("装甲二星"), "help compares both recovery routes")
	_check(all_text.contains("完全恢复"), "help explains lossless battle recovery")
	_check(all_text.contains("大目标、中目标、小目标"), "help points players to the objective ladder")
	_check(all_text.contains("不使用分析 SDK"), "help explains local-data privacy")
	_check(all_text.contains("0.11.0-test"), "runtime version is projected")
	var columns := help.get_node("HelpLandscapeColumns") as HBoxContainer
	_check(columns.get_child_count() == 2, "help keeps two independent landscape columns")
	var back := help.get_node("%HelpBackButton") as Button
	_check(back.has_focus(), "back action receives initial focus")
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

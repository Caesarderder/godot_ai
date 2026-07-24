extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	await process_frame
	await process_frame
	_press_button("进入营地")
	await process_frame
	await process_frame
	_press_button("出征")
	await process_frame
	await process_frame
	_press_button("开始攻城")
	for _frame in 10:
		await process_frame
	var image := root.get_texture().get_image()
	var output := "res://artifacts/playable-battle-844x390.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var error := image.save_png(output)
	if error == OK:
		print("BATTLE CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
		quit(0)
	else:
		push_error("BATTLE CAPTURE FAIL: %s" % error_string(error))
		quit(1)


func _press_button(text: String) -> void:
	var button := _find_button(root, text)
	if button == null:
		push_error("Button not found: %s" % text)
		quit(1)
		return
	button.pressed.emit()


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null

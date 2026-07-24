extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 8:
		await process_frame
	var image := root.get_texture().get_image()
	var output := "res://artifacts/playable-title-844x390.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var error := image.save_png(output)
	if error == OK:
		print("CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
		quit(0)
	else:
		push_error("CAPTURE FAIL: %s" % error_string(error))
		quit(1)

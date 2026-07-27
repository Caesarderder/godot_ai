extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var capture_width := int(OS.get_environment("CAPTURE_WIDTH"))
	var capture_height := int(OS.get_environment("CAPTURE_HEIGHT"))
	if capture_width <= 0:
		capture_width = 844
	if capture_height <= 0:
		capture_height = 390
	DisplayServer.window_set_size(Vector2i(capture_width, capture_height))
	root.size = Vector2i(capture_width, capture_height)
	change_scene_to_file("res://scenes/screens/main.tscn")
	await process_frame
	await process_frame
	var main := current_scene
	var game: Node = main.get("game") if main != null else null
	if game != null:
		game.reset_game(20260728, 1000)
		main.set("selected_stage_id", "stage_1_1")
		main.call("_start_battle")
		await process_frame
		await process_frame
		if not bool(main.get("battle_manual_skills")):
			main.call("_toggle_battle_skill_mode")
			await process_frame
	for _frame in 10:
		await process_frame
	var image := root.get_texture().get_image()
	var output := "res://artifacts/playable-battle-%dx%d.png" % [
		capture_width,
		capture_height,
	]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var error := image.save_png(output)
	if error == OK:
		print("BATTLE CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
		quit(0)
	else:
		push_error("BATTLE CAPTURE FAIL: %s" % error_string(error))
		quit(1)

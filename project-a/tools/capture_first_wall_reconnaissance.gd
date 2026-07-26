extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 20:
		await process_frame
	var main := current_scene
	if main == null:
		push_error("FIRST WALL RECONNAISSANCE CAPTURE FAIL: main scene unavailable")
		quit(1)
		return
	var game: Node = main.get("game")
	game.new_game(20260727, 1000)
	var state: RefCounted = game.current_state()
	state.stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3"]
	state.stage_progress["highest_unlocked_stage"] = "stage_1_4"
	main.set("selected_chapter", 1)
	main.set("selected_stage_id", "stage_1_4")
	main.call("_show_map")
	for _frame in 8:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png("res://artifacts/ui-first-wall-reconnaissance-844x390.png")
	if error != OK:
		push_error("FIRST WALL RECONNAISSANCE CAPTURE FAIL: %s" % error_string(error))
		quit(1)
		return
	state.attempt_counters["stage_1_4"] = 1
	state.factory.eligible_facilities["research_lab"] = true
	main.call("_show_map")
	for _frame in 8:
		await process_frame
	image = root.get_viewport().get_texture().get_image()
	error = image.save_png("res://artifacts/ui-first-wall-recovery-844x390.png")
	if error != OK:
		push_error("FIRST WALL RECOVERY CAPTURE FAIL: %s" % error_string(error))
		quit(1)
		return
	print("FIRST_WALL_RECONNAISSANCE_CAPTURE_OK")
	quit(0)

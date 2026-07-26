extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 8:
		await process_frame
	var main := current_scene
	var game: Node = root.get_node_or_null("Game")
	if main == null or game == null:
		_fail("app shell unavailable")
		return
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("set_playback_enabled", false)
	game.reset_game(20260727, 1000)
	var state: RefCounted = game.current_state()
	state.onboarding["active_index"] = 5
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	main.call("_on_result_action_requested", "factory", {})
	for _frame in 12:
		await process_frame
	var porcelain := main.find_child("ChooseFacility_porcelain_plant", true, false) as Button
	var parts := main.find_child("ChooseFacility_parts_workshop", true, false) as Button
	var energy := main.find_child("ChooseFacility_energy_station", true, false) as Button
	if porcelain == null or parts == null or energy == null:
		_fail("three resource choices unavailable")
		return
	if not porcelain.is_visible_in_tree() or not parts.is_visible_in_tree() or not energy.is_visible_in_tree():
		_fail("three resource choices are not visible together")
		return
	var output := "res://artifacts/ui-first-industrial-choice-844x390.png"
	var error := root.get_texture().get_image().save_png(output)
	if error != OK:
		_fail(error_string(error))
		return
	main.queue_free()
	await process_frame
	print("FIRST INDUSTRIAL CHOICE CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
	quit(0)


func _fail(reason: String) -> void:
	push_error("FIRST INDUSTRIAL CHOICE CAPTURE FAIL: %s" % reason)
	quit(1)

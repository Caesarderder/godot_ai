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
		push_error("RESEARCH BREAKTHROUGH CAPTURE FAIL: app shell unavailable")
		quit(1)
		return
	var state: RefCounted = game.current_state()
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	main.call("_claim_research_breakthrough")
	for _frame in 24:
		await process_frame
	var results := main.find_child("ResearchBreakthroughResults", true, false)
	var counterattack := main.find_child("BlueprintResultsLegionButton", true, false)
	if results == null or not results.visible or counterattack == null:
		push_error("RESEARCH BREAKTHROUGH CAPTURE FAIL: focused result state unavailable")
		quit(1)
		return
	var image := root.get_texture().get_image()
	var output := "res://artifacts/ui-research-breakthrough-844x390.png"
	var error := image.save_png(output)
	if error == OK:
		var audio_director: Node = main.get("audio_director")
		if audio_director != null:
			audio_director.call("stop_all")
		main.queue_free()
		await process_frame
		print("RESEARCH BREAKTHROUGH CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
		quit(0)
		return
	push_error("RESEARCH BREAKTHROUGH CAPTURE FAIL: %s" % error_string(error))
	quit(1)

extends SceneTree

const ResearchBreakthroughService := preload("res://game/scripts/domain/recruitment/research_breakthrough_service.gd")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 8:
		await process_frame
	var main := current_scene
	var game: Node = main.get("game")
	game.reset_game(20260727, 1000)
	var state: RefCounted = game.current_state()
	state.onboarding["active_index"] = 4
	state.stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3"]
	state.stage_progress["highest_unlocked_stage"] = "stage_1_4"
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	ResearchBreakthroughService.claim(state)
	for _frame in 4:
		await process_frame
	main.call("_open_breakthrough_formation")
	for _frame in 6:
		await process_frame
	var guide := main.find_child("FirstFormationGuide", true, false)
	var armored_button: Button
	for hero in game.current_state().roster:
		if String(hero.archetype_id) == "armored":
			armored_button = main.find_child("FormationCandidate_%s" % hero.hero_id, true, false) as Button
			break
	if guide == null or armored_button == null:
		push_error("FIRST FORMATION CAPTURE FAIL: guided formation state unavailable")
		quit(1)
		return
	var image := root.get_texture().get_image()
	var output := "res://artifacts/ui-first-formation-844x390.png"
	var error := image.save_png(output)
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("stop_all")
	main.queue_free()
	for _frame in 4:
		await process_frame
	if error == OK:
		print("FIRST FORMATION CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
		quit(0)
		return
	push_error("FIRST FORMATION CAPTURE FAIL: %s" % error_string(error))
	quit(1)

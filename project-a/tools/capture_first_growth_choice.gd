extends SceneTree

const OnboardingService := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")


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
	state.factory.eligible_facilities["research_lab"] = true
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	_seed_foundational_research(main)
	for _frame in 4:
		await process_frame
	state = game.current_state()
	state.onboarding["active_index"] = 5
	state.factory.facilities["porcelain_plant"] = 1
	state.factory.facility_placements["porcelain_plant"] = [-1, 0]
	OnboardingService.apply_event(state, {
		"type": "facility_constructed",
		"facility_id": "porcelain_plant",
		"request_id": "capture-growth-built",
	})
	OnboardingService.apply_event(state, {
		"type": "factory_output_claimed",
		"facility_id": "porcelain_plant",
		"request_id": "capture-growth-collected",
	})
	state.economy.hero_shards = maxi(4, int(state.economy.hero_shards))
	state.factory.materials["porcelain"] = maxi(18, int(state.factory.materials["porcelain"]))
	state.factory.materials["parts"] = maxi(10, int(state.factory.materials["parts"]))
	state.factory.materials["sludge"] = maxi(8, int(state.factory.materials["sludge"]))
	main.call("_follow_task", "legion")
	for _frame in 12:
		await process_frame
	if not await _capture_size(main, Vector2i(844, 390), "ui-first-growth-choice-844x390.png"):
		return
	if not await _capture_size(main, Vector2i(568, 320), "ui-first-growth-choice-568x320.png"):
		return
	main.queue_free()
	await process_frame
	print("FIRST GROWTH CHOICE CAPTURE PASS: 844x390 + 568x320")
	quit(0)


func _capture_size(main: Node, viewport_size: Vector2i, file_name: String) -> bool:
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	for _frame in 6:
		await process_frame
	var assault := main.find_child("ChooseGrowth_assault", true, false) as Button
	var armored := main.find_child("ChooseGrowth_armored", true, false) as Button
	if assault == null or armored == null or not assault.is_visible_in_tree() or not armored.is_visible_in_tree():
		_fail(
			"both growth routes are not visible together at %s (assault=%s/%s armored=%s/%s)" % [
				viewport_size,
				assault != null,
				assault != null and assault.is_visible_in_tree(),
				armored != null,
				armored != null and armored.is_visible_in_tree(),
			]
		)
		return false
	var output := "res://artifacts/%s" % file_name
	var error := root.get_texture().get_image().save_png(output)
	if error != OK:
		_fail(error_string(error))
		return false
	print("FIRST GROWTH CHOICE CAPTURE: %s" % ProjectSettings.globalize_path(output))
	return true


func _seed_foundational_research(main: Node) -> void:
	main.call("_command", "claim_foundational_signal", {})
	for entry in [["ordinary.assault", 1000, 1045], ["heavy.armored", 1045, 1090]]:
		main.call("_command", "unlock_foundational_blueprint", {
			"recipe_id": String(entry[0]),
			"now_unix": int(entry[1]),
		})
		main.call("_command", "claim_blueprint_research", {
			"now_unix": int(entry[2]),
		})


func _fail(reason: String) -> void:
	push_error("FIRST GROWTH CHOICE CAPTURE FAIL: %s" % reason)
	quit(1)

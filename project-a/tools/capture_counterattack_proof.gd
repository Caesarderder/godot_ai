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
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	main.call("_command", "claim_foundational_signal", {})
	for entry in [["ordinary.assault", 1000, 1045], ["heavy.armored", 1045, 1090]]:
		main.call("_command", "unlock_foundational_blueprint", {
			"recipe_id": String(entry[0]),
			"now_unix": int(entry[1]),
		})
		main.call("_command", "claim_blueprint_research", {"now_unix": int(entry[2])})
	for _frame in 4:
		await process_frame
	state = game.current_state()
	state.onboarding["active_index"] = 5
	var gman := _hero_for(state, "gman")
	var armored := _hero_for(state, "armored")
	var assault := _hero_for(state, "assault")
	if gman == null or armored == null or assault == null:
		_fail("reinforcement roster unavailable")
		return
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_1_4",
			"next_stage_id": "stage_1_5",
			"reward": {"gold": 46, "porcelain": 20, "parts": 16, "sludge": 12},
			"industrial_tech": 3,
			"onboarding_settlement": {
				"task_id": "operation.counterattack",
				"next_index": 5,
				"auto_settled": true,
			},
		},
	})
	main.set("last_battle_runtime_result", {
		"ticks": 235,
		"structures_destroyed": 5,
		"enemies_defeated": 7,
		"deployed_unit_ids": [gman.hero_id, armored.hero_id, assault.hero_id],
		"troop_damage_share_percent": 68,
		"ally_damage_dealt_by_unit": {
			gman.hero_id: 100,
			armored.hero_id: 40,
			assault.hero_id: 60,
		},
	})
	main.call("_show_result")
	for _frame in 12:
		await process_frame
	var proof := main.find_child("HurdleProof", true, false) as Label
	if proof == null or not proof.visible or not proof.text.contains("三人反攻成功"):
		_fail("counterattack proof unavailable")
		return
	var output := "res://artifacts/ui-counterattack-proof-844x390.png"
	var error := root.get_texture().get_image().save_png(output)
	if error != OK:
		_fail(error_string(error))
		return
	DisplayServer.window_set_size(Vector2i(568, 320))
	root.size = Vector2i(568, 320)
	for _frame in 8:
		await process_frame
	var compact_output := "res://artifacts/ui-counterattack-proof-568x320.png"
	error = root.get_texture().get_image().save_png(compact_output)
	if error != OK:
		_fail(error_string(error))
		return
	main.queue_free()
	await process_frame
	print("COUNTERATTACK PROOF CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
	quit(0)


func _hero_for(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null


func _fail(reason: String) -> void:
	push_error("COUNTERATTACK PROOF CAPTURE FAIL: %s" % reason)
	quit(1)

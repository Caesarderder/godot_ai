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
		push_error("FIRST BREAKTHROUGH CAPTURE FAIL: app shell unavailable")
		quit(1)
		return
	var audio_director: Node = main.get("audio_director")
	if audio_director != null:
		audio_director.call("set_playback_enabled", false)
	game.reset_game(20260727, 1000)
	main.set("selected_stage_id", "stage_1_1")
	main.call("_start_battle")
	for _frame in 8:
		await process_frame
	var world: Node = main.get("battle_world")
	var hud: Node = main.get("battle_hud_screen")
	if world == null or hud == null:
		push_error("FIRST BREAKTHROUGH CAPTURE FAIL: battle presentation unavailable")
		quit(1)
		return
	world.set_process(false)
	world.set("_camera_progress", 430.0)
	world.call("_update_camera", 0.16)
	var events: Array[Dictionary] = [{
		"type": &"structure_destroyed",
		"structure_id": "abandoned_barricade",
		"display_name": "废弃路障",
		"road_position": 430,
		"lane": 1,
		"kind": "structure",
	}]
	world.call("_apply_events", events)
	var world_snapshot := world.call("snapshot") as Dictionary
	var hero := (world_snapshot.get("units", []) as Array)[0] as Dictionary
	hud.call("apply_snapshot", {
		"stage_index": 0,
		"stage_count": 1,
		"stage_name": "城市外围",
		"road_progress": 430,
		"warnings": [],
		"structures": [{
			"structure_id": "abandoned_barricade",
			"display_name": "废弃路障",
			"kind": "structure",
			"stage": 0,
			"hp": 0,
			"max_hp": 180,
			"alive": false,
		}, {
			"structure_id": "unguarded_city",
			"display_name": "无防备城市",
			"kind": "city",
			"stage": 0,
			"hp": 760,
			"max_hp": 760,
			"alive": true,
		}],
		"units": [{
			"unit_id": String(hero.get("unit_id", "")),
			"hp": 200,
			"max_hp": 200,
			"energy": 35,
			"alive": true,
			"temporary": false,
		}],
	})
	await process_frame
	var image := root.get_texture().get_image()
	var output := "res://artifacts/ui-first-breakthrough-844x390.png"
	var error := image.save_png(output)
	if error == OK:
		print("FIRST BREAKTHROUGH CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
		quit(0)
		return
	push_error("FIRST BREAKTHROUGH CAPTURE FAIL: %s" % error_string(error))
	quit(1)

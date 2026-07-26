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
	main.set("selected_stage_id", "stage_1_1")
	main.call("_start_battle")
	for _frame in 8:
		await process_frame
	var world: Node = main.get("battle_world")
	var hud: Node = main.get("battle_hud_screen")
	if world == null or hud == null:
		push_error("FIRST SKILL CAPTURE FAIL: battle presentation unavailable")
		quit(1)
		return
	world.set("_camera_progress", 360.0)
	world.call("_update_camera", 0.16)
	var hero: Dictionary = {
		"hero_id": "hero_gman",
		"display_name": "Gman 先锋",
		"archetype_id": "gman",
		"class_id": "commander",
		"skill_id": "gman_overrun",
		"skill_level": 1,
		"star": 1,
		"slot": 0,
		"max_hp": 200,
		"attack": 24,
		"defense": 18,
		"speed_milli": 1000,
		"crit_bp": 500,
		"auto_skill": false,
	}
	var heroes: Array[Dictionary] = [hero]
	hud.call("configure", heroes, true, true)
	hud.call("apply_snapshot", {
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "街区推进",
		"road_progress": 360,
		"warnings": [],
		"units": [{
			"unit_id": "hero_gman",
			"hp": 200,
			"max_hp": 200,
			"energy": 100,
			"alive": true,
			"temporary": false,
		}],
	})
	await process_frame
	var image := root.get_texture().get_image()
	var output := "res://artifacts/ui-first-skill-tutorial-844x390.png"
	var error := image.save_png(output)
	if error == OK:
		print("FIRST SKILL CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
		quit(0)
		return
	push_error("FIRST SKILL CAPTURE FAIL: %s" % error_string(error))
	quit(1)

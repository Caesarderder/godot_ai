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
		"skill_display_name": "统帅碾压",
		"skill_timing": "敌人或结构集中出现时释放",
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
		"stage_index": 0,
		"stage_count": 1,
		"stage_name": "城市外围",
		"road_progress": 360,
		"warnings": [],
		"structures": [{
			"structure_id": "abandoned_barricade",
			"display_name": "废弃路障",
			"kind": "structure",
			"stage": 0,
			"hp": 113,
			"max_hp": 180,
			"alive": true,
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
			"unit_id": "hero_gman",
			"hp": 200,
			"max_hp": 200,
			"energy": 100,
			"alive": true,
			"temporary": false,
		}],
	})
	await process_frame
	var tutorial_output := "res://artifacts/ui-first-skill-tutorial-844x390.png"
	var tutorial_error := root.get_texture().get_image().save_png(tutorial_output)
	if tutorial_error != OK:
		push_error("FIRST SKILL CAPTURE FAIL: %s" % error_string(tutorial_error))
		quit(1)
		return
	var skill_events: Array[Dictionary] = [
		{"type": &"skill_used", "unit_id": &"hero_gman", "skill_id": "gman_overrun"},
		{"type": &"structure_damaged", "source_id": &"hero_gman", "damage": 96, "effective_damage": 96, "is_skill": true},
		{"type": &"structure_damaged", "source_id": &"hero_gman", "damage": 96, "effective_damage": 96, "is_skill": true},
	]
	hud.call("apply_battle_events", skill_events)
	hud.call("apply_snapshot", {
		"stage_index": 0,
		"stage_count": 1,
		"stage_name": "城市外围",
		"road_progress": 360,
		"warnings": [],
		"structures": [{
			"structure_id": "abandoned_barricade",
			"display_name": "废弃路障",
			"kind": "structure",
			"stage": 0,
			"hp": 17,
			"max_hp": 180,
			"alive": true,
		}, {
			"structure_id": "unguarded_city",
			"display_name": "无防备城市",
			"kind": "city",
			"stage": 0,
			"hp": 664,
			"max_hp": 760,
			"alive": true,
		}],
		"units": [{
			"unit_id": "hero_gman",
			"hp": 200,
			"max_hp": 200,
			"energy": 0,
			"alive": true,
			"temporary": false,
		}],
	})
	await process_frame
	var result_output := "res://artifacts/ui-first-skill-result-844x390.png"
	var result_error := root.get_texture().get_image().save_png(result_output)
	if result_error != OK:
		push_error("FIRST SKILL RESULT CAPTURE FAIL: %s" % error_string(result_error))
		quit(1)
		return
	print("FIRST SKILL CAPTURE PASS: %s" % ProjectSettings.globalize_path(tutorial_output))
	print("FIRST SKILL RESULT CAPTURE PASS: %s" % ProjectSettings.globalize_path(result_output))
	quit(0)

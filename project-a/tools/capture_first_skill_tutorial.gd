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
	world.set_process(false)
	var battle_snapshot: Dictionary = world.call("snapshot")
	for _tick in range(240):
		var hero_snapshot := _permanent_hero(battle_snapshot)
		if int(hero_snapshot.get("energy", 0)) >= 100:
			break
		world.call("_process", 0.2)
		battle_snapshot = world.call("snapshot")
	if int(_permanent_hero(battle_snapshot).get("energy", 0)) < 100:
		push_error("FIRST SKILL CAPTURE FAIL: real battle never reached the first ready skill")
		quit(1)
		return
	var camera_focus := float(world.call("_camera_focus_progress", battle_snapshot))
	world.set("_camera_progress", camera_focus)
	world.call("_update_camera", 0.0)
	var hero: Dictionary = {
		"hero_id": String(_permanent_hero(battle_snapshot).get("unit_id", "hero_gman")),
		"display_name": String(_permanent_hero(battle_snapshot).get("display_name", "Gman 先锋")),
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
	hud.call("apply_snapshot", battle_snapshot)
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
	var result_snapshot := battle_snapshot.duplicate(true)
	for unit_value in result_snapshot.get("units", []):
		var unit := unit_value as Dictionary
		if not bool(unit.get("temporary", false)):
			unit["energy"] = 0
	hud.call("apply_snapshot", result_snapshot)
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


func _permanent_hero(battle_snapshot: Dictionary) -> Dictionary:
	for unit_value in battle_snapshot.get("units", []):
		var unit := unit_value as Dictionary
		if bool(unit.get("alive", false)) and not bool(unit.get("temporary", false)):
			return unit
	return {}

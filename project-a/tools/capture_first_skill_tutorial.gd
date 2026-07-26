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
		_step_unit_views(world, 0.2)
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
	var event_holder := {"events": []}
	world.battle_events_applied.connect(func(events: Array[Dictionary]) -> void:
		event_holder["events"] = events
	)
	var unit_id := String(_permanent_hero(battle_snapshot).get("unit_id", ""))
	var skill_buttons := hud.call("skill_buttons") as Dictionary
	var skill_button := skill_buttons.get(unit_id) as Button
	if skill_button == null:
		push_error("FIRST SKILL RESULT CAPTURE FAIL: real skill button is unavailable")
		quit(1)
		return
	skill_button.pressed.emit()
	world.call("_process", 0.2)
	_step_unit_views(world, 0.2)
	var accepted_events := event_holder.get("events", []) as Array
	if not _has_real_skill_result(accepted_events, unit_id):
		push_error("FIRST SKILL RESULT CAPTURE FAIL: no accepted skill damage event")
		quit(1)
		return
	var vfx_root := world.get_node_or_null("LightweightVFX")
	if vfx_root == null or vfx_root.get_child_count() <= 1:
		push_error("FIRST SKILL RESULT CAPTURE FAIL: accepted skill produced no world VFX")
		quit(1)
		return
	var result_snapshot := world.call("snapshot") as Dictionary
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


func _step_unit_views(world: Node, delta: float) -> void:
	var units_root := world.get_node_or_null("AttackingArmy")
	if units_root == null:
		return
	for child in units_root.get_children():
		if child.has_method("_process"):
			child.call("_process", delta)


func _has_real_skill_result(events: Array, unit_id: String) -> bool:
	var has_skill_used := false
	var effective_damage := 0
	for event_value in events:
		var event := event_value as Dictionary
		if StringName(event.get("type", &"")) == &"skill_used" and String(event.get("unit_id", "")) == unit_id:
			has_skill_used = true
		if (
			StringName(event.get("type", &"")) in [&"structure_damaged", &"enemy_damaged"]
			and String(event.get("source_id", "")) == unit_id
		):
			effective_damage += int(event.get("effective_damage", 0))
	return has_skill_used and effective_damage > 0

extends SceneTree

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 8:
		await process_frame
	var main := current_scene
	main.set("selected_stage_id", "stage_1_5")
	main.call("_start_battle")
	for _frame in 8:
		await process_frame
	var world: Node = main.get("battle_world")
	var hud: BattleHudScreen = main.get("battle_hud_screen")
	if world == null or hud == null:
		_fail("battle presentation unavailable")
		return
	var heroes := _heroes()
	world.call("start_battle", heroes, "stage_1_5", StageCatalogScript.stage("stage_1_5"))
	world.set("_camera_progress", 820.0)
	world.call("_update_camera", 0.16)
	var session: RefCounted = BattleSessionScript.new()
	session.start(heroes, "stage_1_5", StageCatalogScript.stage("stage_1_5"))
	_force_final_stage(session)
	var events: Array[Dictionary] = session.advance_tick()
	if not _has_event(events, &"cannon_suppressed"):
		_fail("authoritative session did not accept cannon suppression")
		return
	var snapshot := session.snapshot() as Dictionary
	var warnings := snapshot.get("warnings", []) as Array
	if warnings.size() != 1 or not bool((warnings[0] as Dictionary).get("suppressed", false)):
		_fail("accepted suppression did not remain in the confirmation snapshot")
		return
	world.call("_apply_events", events)
	hud.configure(heroes, true)
	hud.apply_snapshot(snapshot)
	await process_frame
	var output := "res://artifacts/ui-boss-cannon-suppressed-844x390.png"
	var error := root.get_texture().get_image().save_png(output)
	if error != OK:
		_fail(error_string(error))
		return
	print("CANNON SUPPRESSED CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
	quit(0)


func _force_final_stage(session: RefCounted) -> void:
	session._stage_index = 2
	var battery_count := 0
	for structure in session._structures:
		if String(structure.get("kind", "")) == "battery":
			battery_count += 1
	session.tick_index = (42 - battery_count * 6) - 1
	for unit in session._units:
		if int(unit["team"]) == BattleSessionScript.TEAM_ENEMY:
			unit["alive"] = false
		else:
			unit["stage"] = 2
			unit["road_position"] = 780
			unit["cooldown_ticks"] = 0
	for structure in session._structures:
		if int(structure["stage"]) < 2:
			structure["alive"] = false


func _heroes() -> Array[Dictionary]:
	var heroes: Array[Dictionary] = []
	var archetypes := ["gman", "armored", "assault"]
	var classes := ["commander", "guardian", "fighter"]
	var skills := ["gman_overrun", "siege_shield", "plunger_charge"]
	var skill_names := ["统帅碾压", "攻城护盾", "皮搋冲锋"]
	for slot in 3:
		heroes.append({
			"hero_id": "capture_hero_%d" % slot,
			"display_name": ["G-Man 指挥官", "装甲冲城", "冲锋马桶人"][slot],
			"archetype_id": archetypes[slot],
			"class_id": classes[slot],
			"skill_id": skills[slot],
			"skill_display_name": skill_names[slot],
			"skill_timing": "核心巨炮预警倒计时内释放",
			"skill_level": 1,
			"star": 2,
			"slot": slot,
			"max_hp": 500,
			"attack": 220,
			"defense": 40,
			"speed_milli": 1000,
			"crit_bp": 500,
			"starting_energy": 0,
			"auto_skill": false,
		})
	return heroes


func _has_event(events: Array[Dictionary], event_type: StringName) -> bool:
	for event in events:
		if StringName(event.get("type", &"")) == event_type:
			return true
	return false


func _fail(reason: String) -> void:
	push_error("CANNON SUPPRESSED CAPTURE FAIL: %s" % reason)
	quit(1)

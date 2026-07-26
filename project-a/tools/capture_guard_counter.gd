extends SceneTree

const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")


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
	var hud: Node = main.get("battle_hud_screen")
	if world == null or hud == null:
		push_error("GUARD COUNTER CAPTURE FAIL: battle presentation unavailable")
		quit(1)
		return
	var heroes: Array[Dictionary] = [
		_hero("hero_gman", "Gman 先锋", "gman", "commander", "gman_overrun", 1, 0),
		_hero("hero_assault", "冲锋马桶人", "assault", "fighter", "plunger_charge", 1, 1),
		_hero("hero_armored", "装甲冲城", "armored", "guardian", "siege_shield", 2, 2),
	]
	world.call("start_battle", heroes, "stage_1_5", StageCatalog.stage("stage_1_5"))
	world.set("_camera_progress", 820.0)
	world.call("_update_camera", 0.16)
	var counter_events: Array[Dictionary] = [{
		"type": &"cannon_guard_counter",
		"warning_id": "capture_guard",
		"structure_id": &"alliance_core",
		"lane": 1,
		"damage": 60,
	}]
	world.call("_apply_events", counter_events)
	hud.call("configure", heroes, true)
	hud.call("apply_snapshot", {
		"stage_index": 2,
		"stage_count": 3,
		"stage_name": "基地广场",
		"road_progress": 820,
		"warnings": [{"remaining_ticks": 17}],
		"units": [
			_unit("hero_gman", 200, 72),
			_unit("hero_assault", 150, 84),
			_unit("hero_armored", 260, 100),
		],
	})
	await process_frame
	var image := root.get_texture().get_image()
	var output := "res://artifacts/ui-battle-guard-counter-844x390.png"
	var error := image.save_png(output)
	if error == OK:
		print("GUARD COUNTER CAPTURE PASS: %s" % ProjectSettings.globalize_path(output))
		quit(0)
		return
	push_error("GUARD COUNTER CAPTURE FAIL: %s" % error_string(error))
	quit(1)


func _hero(
	hero_id: String,
	display_name: String,
	archetype_id: String,
	class_id: String,
	skill_id: String,
	star: int,
	slot: int
) -> Dictionary:
	return {
		"hero_id": hero_id,
		"display_name": display_name,
		"archetype_id": archetype_id,
		"class_id": class_id,
		"skill_id": skill_id,
		"skill_level": 1,
		"star": star,
		"slot": slot,
		"max_hp": 200 if class_id != "guardian" else 260,
		"attack": 24,
		"defense": 18 if class_id != "guardian" else 30,
		"speed_milli": 1000,
		"crit_bp": 500,
		"auto_skill": false,
	}


func _unit(unit_id: String, hp: int, energy: int) -> Dictionary:
	return {
		"unit_id": unit_id,
		"hp": hp,
		"max_hp": hp,
		"energy": energy,
		"alive": true,
		"temporary": false,
	}

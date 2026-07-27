extends SceneTree

const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 20:
		await process_frame
	var main := current_scene
	if main == null:
		push_error("UI REVIEW CAPTURE FAIL: main scene unavailable")
		quit(1)
		return
	if not _save_viewport("res://artifacts/ui-title-844x390.png"):
		quit(1)
		return
	main.call("_show_help", 1)
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-help-844x390.png"):
		quit(1)
		return
	main.call("_show_settings", 1)
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-settings-844x390.png"):
		quit(1)
		return
	var settings_scroll := main.find_child("SettingsScroll", true, false) as ScrollContainer
	if settings_scroll != null:
		settings_scroll.scroll_vertical = int(settings_scroll.get_v_scroll_bar().max_value)
	for _frame in 3:
		await process_frame
	if not _save_viewport("res://artifacts/ui-settings-storage-844x390.png"):
		quit(1)
		return
	main.call("_set_local_playtest_logging", true)
	for _frame in 6:
		await process_frame
	settings_scroll = main.find_child("SettingsScroll", true, false) as ScrollContainer
	if settings_scroll != null:
		settings_scroll.scroll_vertical = int(settings_scroll.get_v_scroll_bar().max_value)
	for _frame in 3:
		await process_frame
	if not _save_viewport("res://artifacts/ui-settings-playtest-844x390.png"):
		quit(1)
		return
	main.call("_set_local_playtest_logging", false)
	for _frame in 4:
		await process_frame
	main.call("_show_base")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-camp-844x390.png"):
		quit(1)
		return
	var blueprint_state: RefCounted = main.get("game").current_state()
	blueprint_state.factory.facilities["research_lab"] = 1
	blueprint_state.factory.facility_placements["research_lab"] = [2, 1]
	for recipe_id in ["ordinary.assault", "heavy.armored"]:
		blueprint_state.factory.blueprints.erase(recipe_id)
		blueprint_state.factory.discovered_blueprints[recipe_id] = true
	main.call("_show_blueprints")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-blueprint-tree-844x390.png"):
		quit(1)
		return
	var construction_state: RefCounted = main.get("game").current_state()
	construction_state.factory.facilities["porcelain_plant"] = 0
	construction_state.factory.facility_placements.erase("porcelain_plant")
	construction_state.factory.facility_work.clear()
	construction_state.economy.toilet_coins = maxi(100, int(construction_state.economy.toilet_coins))
	main.set("construction_facility_id", "")
	main.set("construction_cell", Vector2i(999, 999))
	main.set("factory_hud_panel", "mission")
	main.call("_show_base")
	for _frame in 4:
		await process_frame
	main.call("_set_factory_hud_panel", "build")
	for _frame in 4:
		await process_frame
	var build_choice := main.find_child("ChooseFacility_porcelain_plant", true, false) as Button
	if build_choice != null:
		build_choice.pressed.emit()
		for _frame in 5:
			await process_frame
		if not _save_viewport("res://artifacts/ui-construction-placement-844x390.png"):
			quit(1)
			return
		main.call("_cancel_facility_construction")
		for _frame in 4:
			await process_frame
	main.call("_show_intelligence")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-war-intelligence-844x390.png"):
		quit(1)
		return
	main.call("_show_map")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-expedition-844x390.png"):
		quit(1)
		return
	main.call("_show_legion")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-legion-844x390.png"):
		quit(1)
		return
	var goal_state: RefCounted = main.get("game").current_state()
	goal_state.onboarding["active_index"] = 2
	goal_state.onboarding["progress"] = {}
	goal_state.onboarding["completed"] = {}
	goal_state.onboarding["claimed"] = {}
	goal_state.stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3"]
	main.call("_show_goals")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-goals-844x390.png"):
		quit(1)
		return
	var capture_state: RefCounted = main.get("game").current_state()
	capture_state.meta_progression.commander_xp = 300
	capture_state.meta_progression.season_merit = 350
	capture_state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	]
	capture_state.meta_progression.achievement_progress["meta.campaign.first"] = 1
	main.call("_set_goals_tab", "pass")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-pass-844x390.png"):
		quit(1)
		return
	main.call("_set_goals_tab", "achievements")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-achievements-844x390.png"):
		quit(1)
		return
	capture_state.economy.recruit_tickets = 10
	main.call("_signal_recruit", 10)
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-recruit-result-844x390.png"):
		quit(1)
		return
	main.call("_select_formation_slot", "troop_5")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-formation-edit-844x390.png"):
		quit(1)
		return
	capture_state = main.get("game").current_state()
	capture_state.stage_progress["cleared_stages"] = StageCatalog.ACT1_STAGE_IDS.duplicate()
	capture_state.stage_progress["highest_unlocked_stage"] = "endless_1"
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_5_5",
			"ticks": 385,
			"campaign_completed": true,
			"first_campaign_completion": true,
		},
	})
	main.set("last_battle_runtime_result", {
		"ticks": 125,
		"structures_destroyed": 4,
		"enemies_defeated": 8,
		"stage_reached": 2,
		"cannon_hit_count": 1,
		"cannon_suppressed_count": 0,
	})
	main.call("_show_result")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-epilogue-844x390.png"):
		quit(1)
		return
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_1_5",
			"reward": {"gold": 58, "porcelain": 27, "parts": 23, "sludge": 21},
			"industrial_tech": 4,
			"hero_shards": 8,
			"skill_chips": 2,
			"damage_manifest": {
				"hero_0001": {"loss": 12, "readiness": 68},
				"hero_0002": {"loss": 12, "readiness": 76},
			},
			"next_stage_id": "stage_2_1",
		},
	})
	var capture_formation_ids: Array[String] = capture_state.formation.hero_ids()
	var contribution_by_unit: Dictionary = {}
	if not capture_formation_ids.is_empty():
		contribution_by_unit[capture_formation_ids[0]] = 1840
	main.set("last_battle_runtime_result", {
		"ticks": 385,
		"structures_destroyed": 7,
		"enemies_defeated": 8,
		"stage_reached": 2,
		"cannon_hit_count": 0,
		"cannon_suppressed_count": 2,
		"ally_damage_dealt_by_unit": contribution_by_unit,
	})
	main.call("_show_result")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-boss-result-844x390.png"):
		quit(1)
		return
	capture_state.onboarding["active_index"] = 5
	(capture_state.onboarding["completed"] as Dictionary)["operation.counterattack"] = true
	(capture_state.onboarding["claimed"] as Dictionary)["operation.counterattack"] = true
	for facility_id in ["porcelain_plant", "parts_workshop", "energy_station"]:
		capture_state.factory.facilities[facility_id] = 0
		capture_state.factory.facility_placements.erase(facility_id)
	for hero in capture_state.roster:
		if String(hero.archetype_id) in ["assault", "armored"]:
			hero.star = 1
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_1_4",
			"reward": {"gold": 54, "porcelain": 22, "parts": 18, "sludge": 16},
			"industrial_tech": 4,
			"hero_shards": 4,
			"skill_chips": 1,
			"next_stage_id": "stage_1_5",
			"onboarding_settlement": {
				"task_id": "operation.counterattack",
				"reward": {
					"toilet_coins": 80,
					"hero_shards": 4,
					"skill_chips": 1,
					"porcelain": 18,
					"parts": 10,
					"sludge": 8,
				},
				"next_index": 5,
				"auto_settled": true,
			},
		},
	})
	main.set("last_battle_runtime_result", {
		"ticks": 325,
		"structures_destroyed": 5,
		"enemies_defeated": 6,
		"stage_reached": 2,
		"cannon_hit_count": 0,
		"cannon_suppressed_count": 1,
	})
	main.call("_show_result")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-action-auto-settlement-844x390.png"):
		quit(1)
		return
	capture_state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4",
	]
	capture_state.stage_progress["highest_unlocked_stage"] = "stage_1_5"
	main.set("selected_stage_id", "stage_1_5")
	main.set("selected_chapter", 1)
	main.call("_show_map")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-boss-briefing-844x390.png"):
		quit(1)
		return
	main.call("_start_battle")
	for _frame in 30:
		await process_frame
	main.call("_set_battle_paused", false)
	for _frame in 3:
		await process_frame
	if not _save_viewport("res://artifacts/ui-battle-844x390.png"):
		quit(1)
		return
	main.call("_set_battle_paused", true)
	for _frame in 3:
		await process_frame
	if not _save_viewport("res://artifacts/ui-battle-pause-844x390.png"):
		quit(1)
		return
	print("UI REVIEW CAPTURE PASS")
	quit(0)


func _save_viewport(path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	# Fast scripted screen changes can outpace the renderer even after idle frames.
	# Force the current scene tree to draw so evidence never re-saves the previous screen.
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("UI REVIEW CAPTURE FAIL: %s" % error_string(error))
		return false
	return true

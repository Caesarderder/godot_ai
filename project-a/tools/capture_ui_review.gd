extends SceneTree

const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")

const CAPTURE_NOW_UNIX := 1_750_000_000

var _capture_main: Node
var _capture_fixture_index := 0


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.content_scale_size = Vector2i(844, 390)
	root.size = Vector2i(844, 390)
	change_scene_to_file("res://scenes/screens/main.tscn")
	for _frame in 20:
		await process_frame
	var main := current_scene
	if main == null:
		push_error("UI REVIEW CAPTURE FAIL: main scene unavailable")
		quit(1)
		return
	_capture_main = main
	if _install_fresh_state(main, "title") == null:
		quit(1)
		return
	main.call("_show_title")
	for _frame in 4:
		await process_frame
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
	var settings_data_tab := main.find_child("SettingsDataTab", true, false) as Button
	if settings_data_tab != null:
		settings_data_tab.pressed.emit()
	for _frame in 3:
		await process_frame
	if not _save_viewport("res://artifacts/ui-settings-storage-844x390.png"):
		quit(1)
		return
	main.call("_set_local_playtest_logging", true)
	for _frame in 6:
		await process_frame
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
	DisplayServer.window_set_size(Vector2i(568, 320))
	root.content_scale_size = Vector2i(568, 320)
	root.size = Vector2i(568, 320)
	main.set("active_layout_profile", "compact_landscape")
	main.call("_show_base")
	for _frame in 8:
		await process_frame
	if not _save_viewport("res://artifacts/ui-camp-568x320.png"):
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.content_scale_size = Vector2i(844, 390)
	root.size = Vector2i(844, 390)
	main.set("active_layout_profile", "standard_landscape")
	main.call("_show_base")
	for _frame in 8:
		await process_frame
	var blueprint_state := _install_fresh_state(main, "blueprints")
	if blueprint_state == null:
		quit(1)
		return
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
	for branch_id in ["heavy", "flying", "special"]:
		main.call("_set_blueprint_branch", branch_id)
		for _frame in 20:
			await process_frame
		if not _save_viewport("res://artifacts/ui-blueprint-%s-844x390.png" % branch_id):
			quit(1)
			return
	var construction_state := _install_fresh_state(main, "construction")
	if construction_state == null:
		quit(1)
		return
	construction_state.factory.facilities["porcelain_plant"] = 0
	construction_state.factory.facility_placements.erase("porcelain_plant")
	construction_state.factory.facility_work.clear()
	construction_state.factory.refresh_capacities()
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
	main.call("_show_current_frontline")
	for _frame in 6:
		await process_frame
	if not _save_viewport("res://artifacts/ui-frontline-briefing-844x390.png"):
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(568, 320))
	root.content_scale_size = Vector2i(568, 320)
	root.size = Vector2i(568, 320)
	main.set("active_layout_profile", "compact_landscape")
	main.call("_show_current_frontline")
	for _frame in 10:
		await process_frame
	if not _save_viewport("res://artifacts/ui-frontline-briefing-568x320.png"):
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.content_scale_size = Vector2i(844, 390)
	root.size = Vector2i(844, 390)
	main.set("active_layout_profile", "standard_landscape")
	for _frame in 10:
		await process_frame
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
	var goal_state := _install_fresh_state(main, "goals")
	if goal_state == null:
		quit(1)
		return
	goal_state.onboarding["active_index"] = 2
	goal_state.onboarding["progress"] = {}
	goal_state.onboarding["completed"] = {}
	goal_state.onboarding["claimed"] = {}
	goal_state.stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3"]
	main.call("_show_goals")
	for _frame in 20:
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
	for _frame in 20:
		await process_frame
	if not _save_viewport("res://artifacts/ui-pass-844x390.png"):
		quit(1)
		return
	main.call("_set_goals_tab", "achievements")
	for _frame in 20:
		await process_frame
	if not _save_viewport("res://artifacts/ui-achievements-844x390.png"):
		quit(1)
		return
	capture_state = _install_fresh_state(main, "recruitment")
	if capture_state == null:
		quit(1)
		return
	capture_state.stage_progress["cleared_stages"] = StageCatalog.ACT1_STAGE_IDS.duplicate()
	capture_state.stage_progress["highest_unlocked_stage"] = "stage_2_1"
	capture_state.meta_progression.commander_xp = 300
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
	capture_state = _install_fresh_state(main, "epilogue")
	if capture_state == null:
		quit(1)
		return
	capture_state.stage_progress["cleared_stages"] = StageCatalog.all_stage_ids()
	capture_state.stage_progress["highest_unlocked_stage"] = "endless_1"
	main.set("last_settlement", {
		"ok": true,
		"event": {
			"outcome": "victory",
			"stage_id": "stage_5_12",
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
	main.call("_show_epilogue", (main.get("last_settlement") as Dictionary).get("event", {}))
	for _frame in 6:
		await process_frame
	if (
		main.find_child("CampaignEpilogueScreen", true, false) == null
		or main.find_child("CampaignEpilogueFuture", true, false) == null
	):
		push_error("UI REVIEW CAPTURE FAIL [epilogue]: _show_epilogue did not build the epilogue scene")
		quit(1)
		return
	if not _save_viewport("res://artifacts/ui-epilogue-844x390.png"):
		quit(1)
		return
	capture_state = _install_fresh_state(main, "boss_result")
	if capture_state == null:
		quit(1)
		return
	capture_state.stage_progress["cleared_stages"] = StageCatalog.ACT1_STAGE_IDS.duplicate()
	capture_state.stage_progress["highest_unlocked_stage"] = "stage_2_1"
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
	capture_state = _install_fresh_state(main, "counterattack_result")
	if capture_state == null:
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
	capture_state = _install_fresh_state(main, "battle")
	if capture_state == null:
		quit(1)
		return
	capture_state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4",
	]
	capture_state.stage_progress["highest_unlocked_stage"] = "stage_1_5"
	var growth_hero: RefCounted = HeroGeneratorScript.generate_archetype(
		capture_state.run_seed,
		capture_state.roster.size(),
		"assault",
		"fighter"
	)
	growth_hero.star = 2
	capture_state.roster.append(growth_hero)
	capture_state.formation.assign_next_troop(String(growth_hero.hero_id))
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
	if not _require_active_battle(main):
		quit(1)
		return
	main.call("_set_battle_paused", false)
	for _frame in 3:
		await process_frame
	if not _save_viewport("res://artifacts/ui-battle-844x390.png"):
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(568, 320))
	root.content_scale_size = Vector2i(568, 320)
	root.size = Vector2i(568, 320)
	main.set("active_layout_profile", "compact_landscape")
	for _frame in 5:
		await process_frame
	var compact_battle_hud := main.get("battle_hud_screen") as BattleHudScreen
	if compact_battle_hud != null:
		compact_battle_hud.configure(
			main.call("_battle_snapshots"),
			bool(main.get("battle_manual_skills")),
			false,
			false,
			true
		)
	await process_frame
	if compact_battle_hud != null:
		compact_battle_hud.set("_compact_layout", true)
		var capture_battle_world := main.get("battle_world") as Node
		if capture_battle_world != null:
			compact_battle_hud.apply_snapshot(
				capture_battle_world.call("get_battle_snapshot") as Dictionary
			)
	await process_frame
	if not _save_viewport("res://artifacts/ui-battle-568x320.png"):
		quit(1)
		return
	main.call("_set_battle_paused", true)
	for _frame in 3:
		await process_frame
	if not _save_viewport("res://artifacts/ui-battle-pause-568x320.png", true):
		quit(1)
		return
	main.call("_set_battle_paused", false)
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.content_scale_size = Vector2i(844, 390)
	root.size = Vector2i(844, 390)
	main.set("active_layout_profile", "standard_landscape")
	if compact_battle_hud != null:
		compact_battle_hud.configure(
			main.call("_battle_snapshots"),
			bool(main.get("battle_manual_skills"))
		)
	for _frame in 10:
		await process_frame
	main.call("_set_battle_paused", true)
	for _frame in 3:
		await process_frame
	if not _save_viewport("res://artifacts/ui-battle-pause-844x390.png", true):
		quit(1)
		return
	print("UI REVIEW CAPTURE PASS")
	quit(0)


func _install_fresh_state(main: Node, fixture_name: String) -> RefCounted:
	var game_node := main.get("game") as Node
	if game_node == null:
		push_error("UI REVIEW CAPTURE FAIL [%s]: game service unavailable" % fixture_name)
		return null
	var executor := game_node.get("executor") as RefCounted
	if executor == null:
		push_error("UI REVIEW CAPTURE FAIL [%s]: command executor unavailable" % fixture_name)
		return null
	_capture_fixture_index += 1
	var state := GameStateScript.create_new(
		2026072900 + _capture_fixture_index,
		CAPTURE_NOW_UNIX + _capture_fixture_index,
		false
	)
	executor.set("state", state)
	executor.set("save_callback", func(_candidate: RefCounted) -> bool: return true)
	_clear_capture_transients(main)
	var invariant_errors: Array[String] = state.validate()
	if not invariant_errors.is_empty():
		push_error(
			"UI REVIEW CAPTURE FAIL [%s]: fresh fixture violates invariants: %s"
			% [fixture_name, "; ".join(invariant_errors)]
		)
		return null
	return state


func _require_active_battle(main: Node) -> bool:
	var battle_world := main.get("battle_world") as Node3D
	if battle_world == null or not is_instance_valid(battle_world):
		push_error("UI REVIEW CAPTURE FAIL [battle]: BattleWorld did not start")
		return false
	var pause_overlay := main.get("battle_pause_overlay") as Control
	if pause_overlay == null or not is_instance_valid(pause_overlay):
		push_error("UI REVIEW CAPTURE FAIL [battle]: pause overlay was not built")
		return false
	return true


func _clear_capture_transients(main: Node) -> void:
	var toast_tween := main.get("toast_tween") as Tween
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	main.set("toast_tween", null)
	var toast := main.get("toast") as Label
	if toast != null and is_instance_valid(toast):
		toast.text = ""
		toast.visible = false
		toast.modulate = Color.WHITE
	main.set("last_settlement", {})
	main.set("last_battle_runtime_result", {})
	main.set("pending_battle_settlement_payload", {})
	main.set("last_recruit_results", [])
	main.set("formation_edit_slot", "")
	main.set("command_serial", 0)
	main.set("goals_tab", "action")
	main.set("legion_tab", "formation")
	main.set("legion_selected_hero_id", "")
	main.set("blueprint_branch", "ordinary")
	main.set("blueprint_focus_recipe_id", "")
	main.set("blueprint_focus_label", "")
	main.set("factory_hud_panel", "mission")
	main.set("ui_scroll_positions", {})
	main.set("selected_stage_id", StageCatalog.DEFAULT_STAGE_ID)
	main.set("selected_chapter", 1)
	main.set("selected_facility_id", "command_center")
	main.set("construction_facility_id", "")
	main.set("construction_cell", Vector2i(999, 999))
	main.set("pending_save_import_text", "")
	main.set("pending_save_import_summary", {})
	main.set("local_save_delete_armed", false)
	main.set("battle_is_paused", false)
	main.set("battle_manual_skills", false)


func _capture_contract_error(allow_battle_pause: bool) -> String:
	if _capture_main == null or not is_instance_valid(_capture_main):
		return "main scene unavailable"
	var game_node := _capture_main.get("game") as Node
	if game_node == null:
		return "game service unavailable"
	var state := game_node.current_state() as RefCounted
	if state == null:
		return "game state unavailable"
	var invariant_errors: Array[String] = state.validate()
	if not invariant_errors.is_empty():
		return "state invariant failure: %s" % "; ".join(invariant_errors)
	var toast := _capture_main.get("toast") as Label
	if toast != null and is_instance_valid(toast) and not toast.text.strip_edges().is_empty():
		return "unexpected toast: %s" % toast.text.strip_edges()
	if not String(_capture_main.get("pending_save_import_text")).is_empty():
		return "save import is pending"
	var import_summary := _capture_main.get("pending_save_import_summary") as Dictionary
	if import_summary != null and not import_summary.is_empty():
		return "save import summary is pending"
	if bool(_capture_main.get("local_save_delete_armed")):
		return "save deletion confirmation is pending"
	var settlement_payload := _capture_main.get("pending_battle_settlement_payload") as Dictionary
	if settlement_payload != null and not settlement_payload.is_empty():
		return "battle settlement is pending"
	if bool(_capture_main.get("orientation_gate_active")):
		return "orientation gate obscures evidence"
	var pause_overlay := _capture_main.get("battle_pause_overlay") as Control
	if (
		not allow_battle_pause
		and pause_overlay != null
		and is_instance_valid(pause_overlay)
		and pause_overlay.visible
	):
		return "unexpected battle pause overlay"
	if allow_battle_pause and (
		pause_overlay == null
		or not is_instance_valid(pause_overlay)
		or not pause_overlay.visible
	):
		return "expected battle pause overlay is missing"
	return ""


func _save_viewport(path: String, allow_battle_pause: bool = false) -> bool:
	var contract_error := _capture_contract_error(allow_battle_pause)
	if not contract_error.is_empty():
		push_error("UI REVIEW CAPTURE FAIL [%s]: %s" % [path, contract_error])
		return false
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

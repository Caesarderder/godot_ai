extends SceneTree

const LEGION_SCENE := preload("res://game/scenes/screens/legion_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-faction-core-choice"
const CASES := ["candidate_choice", "reduced_motion_choice", "selected_handoff"]
const VIEWPORTS := [Vector2i(844, 390), Vector2i(568, 320)]


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var artifacts: Array[String] = []
	for case_id in CASES:
		for viewport_size in VIEWPORTS:
			var filename := "%s-%dx%d.png" % [case_id, viewport_size.x, viewport_size.y]
			if not await _capture_case(case_id, viewport_size, "%s/%s" % [OUTPUT_DIR, filename]):
				quit(1)
				return
			artifacts.append(filename)
	var manifest := {
		"scenario_id": "scenario_faction_core_choice_identity",
		"fixture": "shipping LegionScreen through configure and action_requested",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"two equal candidates remain simultaneously comparable",
			"stable archetype portraits and actions remain available",
			"reduced motion preserves the complete decision",
			"selected handoff exposes one research action",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("FACTION CORE CHOICE SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("FACTION_CORE_CHOICE_SCENARIO_OK")
	quit(0)


func _capture_case(case_id: String, viewport_size: Vector2i, path: String) -> bool:
	DisplayServer.window_set_size(viewport_size)
	root.content_scale_size = viewport_size
	root.size = viewport_size
	for child in root.get_children():
		child.queue_free()
	await process_frame
	var background := ColorRect.new()
	background.color = Color("#091015")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	root.add_child(margin)
	var legion := LEGION_SCENE.instantiate() as LegionScreen
	margin.add_child(legion)
	legion.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 14:
		await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("FACTION CORE CHOICE SCENARIO FAIL: texture unavailable")
		return false
	var error := image.save_png(path)
	if error != OK:
		push_error("FACTION CORE CHOICE SCENARIO FAIL: %s" % error_string(error))
		return false
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var choices: Array[Dictionary] = []
	var focus := {}
	if case_id != "selected_handoff":
		choices = [_choice("assault"), _choice("rocket")]
	else:
		focus = {
			"archetype_id": "assault",
			"hero_id": "",
			"display_name": "普通马桶人",
			"faction": "快攻破城",
			"status": "图纸已获得 · 研发后永久入列",
			"next_star_effect": "顺劈多个目标",
			"action": "open_research",
			"action_label": "前往研究",
		}
	return {
		"compact": compact,
		"tab": "recruit",
		"first_formation": {"active": false},
		"first_growth_choice": {"active": false},
		"boss_ready": {"active": false},
		"recruitment_unlocked": true,
		"recruit_tickets": 0,
		"recruit_s_pity": 10,
		"recruit_target_guaranteed": false,
		"foundational_signal": {"unlocked": true, "claimable": false, "claimed": true},
		"recruit_results": [{"rarity": "B", "kind": "hero_fragments", "display_name": "普通马桶人", "amount": 20}],
		"recruit_reward_summary": {"draw_count": 10, "new_blueprints": 2, "fragment_total": 60, "highest_rating": "B"},
		# Strict captures compare the settled decision. Reveal timing remains a runtime assertion.
		"recruit_reveal": false,
		"reduced_motion": case_id == "reduced_motion_choice",
		"recruit_core_choices": choices,
		"recruit_focus": focus,
		"formation": [],
		"roster": [],
	}


func _choice(archetype_id: String) -> Dictionary:
	if archetype_id == "assault":
		return {
			"archetype_id": "assault", "display_name": "普通马桶人", "rating": "B",
			"faction": "快攻破城", "playstyle": "抢先破城", "synergy_summary": "已有搭档：Gman",
			"fragments": 20, "next_star_effect": "顺劈多个目标",
		}
	return {
		"archetype_id": "rocket", "display_name": "飞行四发射器马桶人", "rating": "B",
		"faction": "远程轰炸", "playstyle": "后排拆塔", "synergy_summary": "补足：远程拆塔",
		"fragments": 20, "next_star_effect": "齐射多个目标",
	}

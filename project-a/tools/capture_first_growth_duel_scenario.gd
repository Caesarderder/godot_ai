extends SceneTree

const LEGION_SCENE := preload("res://game/scenes/screens/legion_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-mobile-first-growth-duel"
const CASES := ["route_duel", "resource_blocked", "route_committed"]
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
		"scenario_id": "scenario_mobile_first_growth_duel",
		"fixture": "shipping LegionScreen through configure and action_requested",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"ready routes emit exact assault and armored hero identities",
			"blocked routes expose no executable star action",
			"committed handoff emits boss stage_1_5",
			"decisive targets remain at least 48 logical pixels",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("FIRST GROWTH DUEL SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("FIRST_GROWTH_DUEL_SCENARIO_OK")
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
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	root.add_child(margin)
	var legion := LEGION_SCENE.instantiate() as LegionScreen
	margin.add_child(legion)
	var requested := {"id": "", "hero_id": "", "stage_id": ""}
	legion.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		requested["id"] = action_id
		requested["hero_id"] = String(payload.get("hero_id", ""))
		requested["stage_id"] = String(payload.get("stage_id", ""))
	)
	legion.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 10:
		await process_frame
	if not _verify_case(legion, case_id, requested):
		return false
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null or image.save_png(path) != OK:
		push_error("FIRST GROWTH DUEL SCENARIO FAIL: capture unavailable")
		return false
	return true


func _verify_case(legion: LegionScreen, case_id: String, requested: Dictionary) -> bool:
	if case_id == "route_committed":
		var attack := legion.find_child("BossReadyAttackButton", true, false) as Button
		if attack == null or attack.disabled or attack.custom_minimum_size.y < 48.0:
			push_error("FIRST GROWTH DUEL SCENARIO FAIL: boss handoff unavailable")
			return false
		attack.pressed.emit()
		if requested["id"] != "boss" or requested["stage_id"] != "stage_1_5":
			push_error("FIRST GROWTH DUEL SCENARIO FAIL: boss identity mismatch")
			return false
		return true
	var assault := legion.find_child("ChooseGrowth_assault", true, false) as Button
	var armored := legion.find_child("ChooseGrowth_armored", true, false) as Button
	if assault == null or armored == null or assault.custom_minimum_size.y < 48.0 or armored.custom_minimum_size.y < 48.0:
		push_error("FIRST GROWTH DUEL SCENARIO FAIL: route targets unavailable")
		return false
	if case_id == "resource_blocked":
		if not assault.disabled or not armored.disabled:
			push_error("FIRST GROWTH DUEL SCENARIO FAIL: blocked route is executable")
			return false
		return true
	assault.pressed.emit()
	if requested["id"] != "star" or requested["hero_id"] != "hero-assault":
		push_error("FIRST GROWTH DUEL SCENARIO FAIL: assault identity mismatch")
		return false
	armored.pressed.emit()
	if requested["id"] != "star" or requested["hero_id"] != "hero-armored":
		push_error("FIRST GROWTH DUEL SCENARIO FAIL: armored identity mismatch")
		return false
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	if case_id == "route_committed":
		return {
			"compact": compact,
			"tab": "formation",
			"boss_ready": {
				"active": true,
				"hero_name": "冲锋马桶人",
				"route": "快攻路线 · 2★",
				"tactic": "巨炮预警 5 秒 · 技能打断",
				"team_power": 3792,
				"recommended_power": 3600,
				"stage_name": "1-5 灰镜核心",
				"stage_id": "stage_1_5",
			},
		}
	var affordable := case_id == "route_duel"
	return {
		"compact": compact,
		"tab": "formation",
		"first_growth_choice": {
			"active": true,
			"target_stage": "1-5 灰镜核心",
			"choices": [
				{
					"archetype_id": "assault", "hero_id": "hero-assault",
					"display_name": "冲锋马桶人", "route": "破城快攻 · 技能打断巨炮",
					"verified": "实测 7/7 通关", "power_before": 1690,
					"power_after": 2101, "power_gain": 411,
					"resource_context": {}, "cost": "军团数据 20",
					"already_upgraded": false, "affordable": affordable,
				},
				{
					"archetype_id": "armored", "hero_id": "hero-armored",
					"display_name": "铁甲冲锋马桶人", "route": "铁甲守势 · 格挡反震",
					"verified": "实测 7/7 通关", "power_before": 1159,
					"power_after": 1983, "power_gain": 388,
					"resource_context": {}, "cost": "军团数据 20",
					"already_upgraded": false, "affordable": affordable,
				},
			],
		},
	}

extends SceneTree

const GOALS_SCENE := preload("res://game/scenes/screens/goals_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-mobile-achievement-cabinet"
const CASES := ["mixed_claimable", "settled_collection", "locked_cabinet"]
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
		"scenario_id": "scenario_mobile_achievement_medal_cabinet",
		"fixture": "shipping GoalsScreen through configure and action_requested",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"mixed state emits claim_achievement with meta.campaign.first",
			"mixed state emits claim_all_achievements",
			"settled and locked states expose no batch claim",
			"visible medal targets remain at least 64 logical pixels",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("ACHIEVEMENT CABINET SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("ACHIEVEMENT_CABINET_SCENARIO_OK")
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
	var goals := GOALS_SCENE.instantiate() as GoalsScreen
	margin.add_child(goals)
	var requested := {"id": "", "achievement_id": ""}
	goals.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		requested["id"] = action_id
		requested["achievement_id"] = String(payload.get("achievement_id", ""))
	)
	goals.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 10:
		await process_frame
	if not _verify_case(goals, case_id, requested):
		return false
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("ACHIEVEMENT CABINET SCENARIO FAIL: texture unavailable")
		return false
	var error := image.save_png(path)
	if error != OK:
		push_error("ACHIEVEMENT CABINET SCENARIO FAIL: %s" % error_string(error))
		return false
	return true


func _verify_case(goals: GoalsScreen, case_id: String, requested: Dictionary) -> bool:
	var batch := goals.find_child("AchievementBatchClaim", true, false) as Button
	if case_id != "mixed_claimable":
		if batch != null:
			push_error("ACHIEVEMENT CABINET SCENARIO FAIL: non-claimable state exposes batch action")
			return false
		return true
	if batch == null or batch.disabled or batch.custom_minimum_size.y < 48.0:
		push_error("ACHIEVEMENT CABINET SCENARIO FAIL: batch action is not touch-ready")
		return false
	var medal := goals.find_child("Achievement_meta_campaign_first", true, false) as Button
	if medal == null or medal.disabled or medal.custom_minimum_size.y < 64.0:
		push_error("ACHIEVEMENT CABINET SCENARIO FAIL: claimable medal is not touch-ready")
		return false
	medal.pressed.emit()
	if requested["id"] != "claim_achievement" or requested["achievement_id"] != "meta.campaign.first":
		push_error("ACHIEVEMENT CABINET SCENARIO FAIL: individual durable action mismatch")
		return false
	batch.pressed.emit()
	if requested["id"] != "claim_all_achievements":
		push_error("ACHIEVEMENT CABINET SCENARIO FAIL: batch durable action mismatch")
		return false
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	if case_id == "locked_cabinet":
		return {
			"compact": compact,
			"tab": "achievements",
			"notification_counts": {"goals_action": 0, "goals_pass": 0, "goals_achievements": 0},
			"commander": {"level": 2, "xp": 80, "next_xp": 100, "claimable": 0},
			"achievements_unlocked": false,
			"achievement_claimable": 0,
			"achievement_lock": {"title":"成就陈列","level":2,"required_level":3,"stage_copy":"通关 1-2","stage_complete":false},
		}
	var settled := case_id == "settled_collection"
	return {
		"compact": compact,
		"tab": "achievements",
		"notification_counts": {"goals_action": 0, "goals_pass": 0, "goals_achievements": 0 if settled else 2},
		"commander": {"level": 5, "xp": 300, "next_xp": 450, "claimable": 0},
		"achievements_unlocked": true,
		"achievement_claimable": 0 if settled else 2,
		"achievements": _achievements(settled),
	}


func _achievements(settled: bool) -> Array[Dictionary]:
	return [
		{"achievement_id":"meta.campaign.first","title":"第一座城","progress":1,"target":1,"complete":true,"claimed":settled},
		{"achievement_id":"meta.factory.claim_1","title":"第一次入库","progress":1,"target":1,"complete":true,"claimed":settled},
		{"achievement_id":"meta.campaign.ten","title":"十城推进","progress":3,"target":10,"complete":false,"claimed":false},
		{"achievement_id":"meta.factory.claim_10","title":"工厂轰鸣","progress":4,"target":10,"complete":false,"claimed":false},
		{"achievement_id":"meta.legion.level_3","title":"主力成型","progress":2,"target":3,"complete":false,"claimed":false},
		{"achievement_id":"meta.collection.six","title":"六人军团","progress":4,"target":6,"complete":false,"claimed":false},
	]

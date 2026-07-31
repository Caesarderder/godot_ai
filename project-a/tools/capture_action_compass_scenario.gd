extends SceneTree

const GOALS_SCENE := preload("res://game/scenes/screens/goals_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-mobile-action-compass"
const CASES := ["active_hurdle", "claimable_supply", "locked_missions"]
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
		"scenario_id": "scenario_mobile_objective_action_compass",
		"fixture": "shipping GoalsScreen through configure and action_requested",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"active hurdle emits follow_task with stage_1_4",
			"claimable supply emits claim_starter_gift with rookie_departure_v1",
			"locked missions expose no mission claim action",
			"all visible primary actions remain at least 48 logical pixels",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("ACTION COMPASS SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("ACTION_COMPASS_SCENARIO_OK")
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
	var requested := {"id": "", "stage_id": "", "gift_id": ""}
	goals.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		requested["id"] = action_id
		requested["stage_id"] = String(payload.get("stage_id", ""))
		requested["gift_id"] = String(payload.get("gift_id", ""))
	)
	goals.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 10:
		await process_frame
	if not _verify_case(goals, case_id, requested):
		return false
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("ACTION COMPASS SCENARIO FAIL: texture unavailable")
		return false
	var error := image.save_png(path)
	if error != OK:
		push_error("ACTION COMPASS SCENARIO FAIL: %s" % error_string(error))
		return false
	return true


func _verify_case(goals: GoalsScreen, case_id: String, requested: Dictionary) -> bool:
	var action := goals.find_child("GoalHierarchyPrimaryCTA", true, false) as Button
	var gift := goals.find_child("StarterGift_rookie_departure_v1", true, false) as Button
	if case_id == "claimable_supply":
		if gift == null or gift.disabled or gift.custom_minimum_size.y < 48.0:
			push_error("ACTION COMPASS SCENARIO FAIL: claimable supply is not touch-ready")
			return false
		gift.pressed.emit()
		if requested["id"] != "claim_starter_gift" or requested["gift_id"] != "rookie_departure_v1":
			push_error("ACTION COMPASS SCENARIO FAIL: durable reward action mismatch")
			return false
		return true
	if action == null or action.disabled or action.custom_minimum_size.y < 48.0:
		push_error("ACTION COMPASS SCENARIO FAIL: campaign action is not touch-ready")
		return false
	action.pressed.emit()
	if requested["id"] != "follow_task" or requested["stage_id"] != "stage_1_4":
		push_error("ACTION COMPASS SCENARIO FAIL: durable campaign action mismatch")
		return false
	if case_id == "locked_missions":
		for button in goals.find_children("*", "Button", true, false):
			if String((button as Button).name).begins_with("MissionClaim") and not (button as Button).disabled:
				push_error("ACTION COMPASS SCENARIO FAIL: locked mission exposes claim action")
				return false
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var hierarchy := {
		"macro": "摧毁 E11 联盟核心巨炮，完成第一章",
		"medium": "行动三：撞击高墙",
		"small": "完成 1-4 首次挑战并寻找失败原因",
		"hurdle": {
			"scale": "大坎",
			"title": "1-4 E10 · 监控人增援",
			"reason": "职责覆盖不足",
			"recovery": "首战后建研究所，启动免费突破十连。",
		},
		"finished": false,
		"actionable": case_id != "claimable_supply",
		"cta_label": "挑战 1-4 高墙",
		"target": "expedition",
		"stage_id": "stage_1_4",
	}
	if case_id == "claimable_supply":
		hierarchy["milestone"] = "研究所已落成"
	var claimable := case_id == "claimable_supply"
	return {
		"compact": compact,
		"tab": "action",
		"notification_counts": {"goals_action": 1, "goals_pass": 0, "goals_achievements": 0},
		"hierarchy": hierarchy,
		"campaign": {"cleared": 3, "chapters_copy": "第1章 3/5"},
		"starter_gifts": {
			"claimable_count": 1 if claimable else 0,
			"gifts": [{
				"gift_id": "rookie_departure_v1",
				"title": "新手启程礼包",
				"reward_copy": "金币 ×30",
				"reason_copy": "第一座设施落成奖励",
				"unlock_copy": "研究所落成后解锁",
				"unlocked": claimable,
				"claimable": claimable,
				"claimed": false,
			}],
		},
		"new_player_welfare": {"unlocked": false, "claimable": false, "claimed": false},
		"missions_unlocked": false,
		"mission_lock": {"title":"行动任务","level":1,"required_level":2,"stage_copy":"通关 1-1","stage_complete":true},
	}

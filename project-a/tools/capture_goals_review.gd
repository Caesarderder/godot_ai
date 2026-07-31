extends SceneTree

const GOALS_SCENE := preload("res://game/scenes/screens/goals_screen.tscn")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if not await _capture_size(
		Vector2i(844, 390),
		"res://artifacts/ui-goals-action-844x390.png",
		_action_view(false)
	):
		quit(1)
		return
	if not await _capture_size(
		Vector2i(568, 320),
		"res://artifacts/ui-goals-action-568x320.png",
		_action_view(true)
	):
		quit(1)
		return
	if not await _capture_size(
		Vector2i(844, 390),
		"res://artifacts/ui-achievement-medals-844x390.png",
		_achievement_view(false)
	):
		quit(1)
		return
	if not await _capture_size(
		Vector2i(568, 320),
		"res://artifacts/ui-achievement-medals-568x320.png",
		_achievement_view(true)
	):
		quit(1)
		return
	print("GOALS REVIEW CAPTURE PASS")
	quit(0)


func _capture_size(viewport_size: Vector2i, path: String, view: Dictionary) -> bool:
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
	goals.configure(view)
	for _frame in 6:
		await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("GOALS REVIEW CAPTURE FAIL: viewport texture unavailable")
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error := image.save_png(path)
	if error != OK:
		push_error("GOALS REVIEW CAPTURE FAIL: %s" % error_string(error))
		return false
	return true


func _action_view(compact: bool) -> Dictionary:
	return {
		"compact": compact,
		"tab": "action",
		"notification_counts": {
			"goals_action": 1,
			"goals_pass": 0,
			"goals_achievements": 0,
		},
		"hierarchy": {
			"macro": "摧毁 E11 联盟核心巨炮，完成第一章",
			"medium": "行动三：撞击高墙",
			"small": "完成 1-4 首次挑战并寻找失败原因",
			"hurdle": {
				"scale": "大坎",
				"title": "1-4 E10 · 监控人增援",
				"reason": "职责覆盖不足",
				"recovery": "完成首战后用保障币建研究所，启动免费突破十连。",
			},
			"finished": false,
			"cta_label": "挑战 1-4 高墙",
			"target": "expedition",
			"stage_id": "stage_1_4",
		},
		"campaign": {
			"cleared": 3,
			"chapters_copy": "第1章 3/5 · 第2章 0/5 · 第3章 0/5 · 第4章 0/5 · 第5章 0/5",
		},
		"new_player_welfare": {
			"unlocked": false,
			"claimable": false,
			"claimed": false,
		},
		"starter_gifts": {
			"claimable_count": 1,
			"gifts": [
				{
					"gift_id": "rookie_departure_v1",
					"title": "新手启程礼包",
					"reward_copy": "金币 ×30",
					"reason_copy": "第一座设施落成奖励",
					"unlock_copy": "研究所落成后解锁",
					"unlocked": true,
					"claimable": true,
					"claimed": false,
				},
				{
					"gift_id": "new_game_supply_v1",
					"title": "新游补给礼包",
					"reward_copy": "金币 ×50 · 工业材料 ×30",
					"reason_copy": "下一座工业设施启动资金",
					"unlock_copy": "首次通关 1-3 后解锁",
					"unlocked": false,
					"claimable": false,
					"claimed": false,
				},
			],
		},
		"missions_unlocked": false,
		"mission_lock": {
			"title": "行动任务",
			"level": 1,
			"required_level": 2,
			"stage_copy": "通关 1-1",
			"stage_complete": true,
		},
	}


func _achievement_view(compact: bool) -> Dictionary:
	return {
		"compact": compact,
		"tab": "achievements",
		"notification_counts": {
			"goals_action": 0,
			"goals_pass": 0,
			"goals_achievements": 2,
		},
		"commander": {
			"level": 5,
			"xp": 300,
			"next_xp": 450,
			"claimable": 0,
		},
		"achievements_unlocked": true,
		"achievement_claimable": 2,
		"achievements": [
			{
				"achievement_id": "meta.campaign.first",
				"title": "第一座城",
				"progress": 1,
				"target": 1,
				"complete": true,
				"claimed": false,
			},
			{
				"achievement_id": "meta.campaign.ten",
				"title": "十城推进",
				"progress": 3,
				"target": 10,
				"complete": false,
				"claimed": false,
			},
			{
				"achievement_id": "meta.factory.claim_1",
				"title": "第一次入库",
				"progress": 1,
				"target": 1,
				"complete": true,
				"claimed": false,
			},
			{
				"achievement_id": "meta.factory.claim_10",
				"title": "工厂轰鸣",
				"progress": 4,
				"target": 10,
				"complete": false,
				"claimed": false,
			},
			{
				"achievement_id": "meta.legion.level_3",
				"title": "主力成型",
				"progress": 2,
				"target": 3,
				"complete": false,
				"claimed": false,
			},
			{
				"achievement_id": "meta.collection.six",
				"title": "六人军团",
				"progress": 4,
				"target": 6,
				"complete": false,
				"claimed": false,
			},
		],
	}

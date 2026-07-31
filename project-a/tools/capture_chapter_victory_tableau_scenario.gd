extends SceneTree

const RESULT_SCENE := preload("res://game/scenes/screens/battle_result_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-mobile-chapter-victory-tableau"
const CASES := ["fresh_chapter_clear", "replayed_chapter_clear"]
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
		"scenario_id": "scenario_mobile_chapter_victory_tableau",
		"fixture": "shipping BattleResultScreen through configure and action_requested",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"fresh clear emits exact welfare action",
			"replayed clear emits exact map_stage stage_2_1 payload",
			"gold, legion data and battle fact metrics remain present",
			"primary action remains a 48px touch target",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		return _fail_and_quit("manifest unavailable")
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("CHAPTER_VICTORY_TABLEAU_SCENARIO_OK")
	quit(0)


func _capture_case(case_id: String, viewport_size: Vector2i, path: String) -> bool:
	for child in root.get_children():
		child.queue_free()
	await process_frame
	var viewport := SubViewport.new()
	viewport.name = "ChapterVictoryCaptureViewport"
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("#091015")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 12)
	viewport.add_child(margin)
	var result := RESULT_SCENE.instantiate() as BattleResultScreen
	margin.add_child(result)
	var requested := {"id": "", "stage_id": ""}
	result.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		requested["id"] = action_id
		requested["stage_id"] = String(payload.get("stage_id", ""))
	)
	result.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 10:
		await process_frame
	if not _verify(result, case_id, requested):
		return false
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	if image == null or image.get_size() != viewport_size:
		return _fail("capture size mismatch: expected %s, got %s" % [viewport_size, Vector2i.ZERO if image == null else image.get_size()])
	if image.save_png(path) != OK:
		return _fail("capture unavailable")
	return true


func _verify(result: BattleResultScreen, case_id: String, requested: Dictionary) -> bool:
	var primary := result.find_child("PrimaryAction", true, false) as Button
	if primary == null or primary.size.y < 48.0:
		return _fail("primary action is not touch-ready")
	for node_name in ["ChapterVictoryHeroTableau", "ResultRewardChips", "ResultBattleFacts"]:
		if result.find_child(node_name, true, false) == null:
			return _fail("missing visual result node %s" % node_name)
	for hero_name in ["ChapterVictoryAssault", "ChapterVictoryArmored"]:
		var hero := result.find_child(hero_name, true, false) as TextureRect
		if hero == null or hero.texture == null or hero.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return _fail("chapter hero art is missing or intercepts touch: %s" % hero_name)
	primary.pressed.emit()
	if case_id == "fresh_chapter_clear":
		if requested["id"] != "welfare":
			return _fail("fresh clear action mismatch")
	elif requested["id"] != "map_stage" or requested["stage_id"] != "stage_2_1":
		return _fail("replay forward payload mismatch")
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var fresh := case_id == "fresh_chapter_clear"
	return {
		"compact": compact,
		"chapter_complete": true,
		"chapter_hero_ids": ["assault", "armored"],
		"outcome_banner": "首章胜利 · 核心巨炮已摧毁",
		"outcome_color": "green",
		"reward_headline": "金币 +58    军团数据 +8",
		"hero_experience": "3名主力各 +30 经验",
		"mission_progress": "行动五完成 · 首章训练闭环达成",
		"combat_summary": "战斗复盘 · 77秒 · 击破7个目标 · 消灭8名守军",
		"contribution": "冲锋压炮 4 次",
		"debrief": "护盾挡下巨炮后完成反击",
		"growth": "首章解锁 · 第2章战线 · 信号招募",
		"safety": "全员无损返回 · 无维修消耗",
		"qualification": "第2章战线已开放\n%s" % ("开服庆典礼包已解锁" if fresh else "庆典礼包已领取"),
		"primary_label": "领取开服庆典礼包" if fresh else "查看第2章新战线",
		"primary_action": "welfare" if fresh else "map_stage",
		"primary_payload": {} if fresh else {"stage_id": "stage_2_1"},
	}


func _fail(message: String) -> bool:
	push_error("CHAPTER VICTORY TABLEAU SCENARIO FAIL: %s" % message)
	return false


func _fail_and_quit(message: String) -> void:
	_fail(message)
	quit(1)

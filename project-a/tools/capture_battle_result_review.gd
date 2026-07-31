extends SceneTree

const RESULT_SCENE := preload("res://game/scenes/screens/battle_result_screen.tscn")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if not await _capture_case(
		Vector2i(844, 390),
		"res://artifacts/ui-battle-result-victory-844x390.png",
		_victory_view(false)
	):
		quit(1)
		return
	if not await _capture_case(
		Vector2i(568, 320),
		"res://artifacts/ui-battle-result-victory-568x320.png",
		_victory_view(true)
	):
		quit(1)
		return
	if not await _capture_case(
		Vector2i(568, 320),
		"res://artifacts/ui-battle-result-defeat-568x320.png",
		_defeat_view()
	):
		quit(1)
		return
	print("BATTLE RESULT REVIEW CAPTURE PASS")
	quit(0)


func _capture_case(viewport_size: Vector2i, path: String, view: Dictionary) -> bool:
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
	var result := RESULT_SCENE.instantiate() as BattleResultScreen
	margin.add_child(result)
	result.configure(view)
	for _frame in 6:
		await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("BATTLE RESULT REVIEW CAPTURE FAIL: viewport texture unavailable")
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error := image.save_png(path)
	if error != OK:
		push_error("BATTLE RESULT REVIEW CAPTURE FAIL: %s" % error_string(error))
		return false
	return true


func _victory_view(compact: bool) -> Dictionary:
	return {
		"compact": compact,
		"outcome_banner": "首章胜利 · 核心巨炮已摧毁",
		"outcome_color": "green",
		"reward_headline": "金币 +58    军团数据 +8",
		"hero_experience": "3名主力各 +30 经验",
		"mission_progress": "行动五完成 · 新目标：第2章战线",
		"combat_summary": "战斗复盘 · 77秒 · 击破7个目标 · 消灭8名守军",
		"contribution": "核心贡献 · 前排承伤 68%",
		"hurdle_proof": "单人首战失败 → 三人反攻成功",
		"debrief": "护盾挡下巨炮后完成反击",
		"growth": "首章解锁 · 第2章战线 · 信号招募",
		"safety": "全员无损返回 · 无维修消耗",
		"qualification": "第2章战线已开放\n开服庆典礼包已解锁",
		"primary_label": "领取开服庆典礼包",
		"primary_action": "welfare",
		"primary_payload": {},
	}


func _defeat_view() -> Dictionary:
	return {
		"compact": true,
		"outcome_banner": "攻势受阻 · 战术数据已保留",
		"outcome_color": "red",
		"reward_headline": "",
		"combat_summary": "战斗复盘 · 64秒 · 击破2个目标 · 消灭4名守军",
		"hurdle_proof": "巨炮蓄力阶段缺少护盾承伤",
		"debrief": "失败原因已定位：先挡住巨炮，再集中反击",
		"safety": "全员安全返回 · 无永久损失",
		"qualification": "调整阵型后可立即再战",
		"primary_label": "调整阵型 · 再战 1-5",
		"primary_action": "legion",
		"primary_payload": {},
	}

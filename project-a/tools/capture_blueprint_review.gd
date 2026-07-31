extends SceneTree

const BLUEPRINT_SCENE := preload("res://game/scenes/screens/blueprint_screen.tscn")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if not await _capture_size(
		Vector2i(844, 390),
		"res://artifacts/ui-blueprint-branch-844x390.png"
	):
		quit(1)
		return
	if not await _capture_size(
		Vector2i(568, 320),
		"res://artifacts/ui-blueprint-branch-568x320.png"
	):
		quit(1)
		return
	print("BLUEPRINT REVIEW CAPTURE PASS")
	quit(0)


func _capture_size(viewport_size: Vector2i, path: String) -> bool:
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
	var blueprint := BLUEPRINT_SCENE.instantiate() as BlueprintScreen
	margin.add_child(blueprint)
	blueprint.configure(_branch_view(viewport_size.x < 720))
	for _frame in 6:
		await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("BLUEPRINT REVIEW CAPTURE FAIL: viewport texture unavailable")
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error := image.save_png(path)
	if error != OK:
		push_error("BLUEPRINT REVIEW CAPTURE FAIL: %s" % error_string(error))
		return false
	return true


func _branch_view(compact: bool) -> Dictionary:
	return {
		"compact": compact,
		"branch": "ordinary",
		"branch_title": "突击枝",
		"branch_summary": "突破 · 控场",
		"core_status": "首败信号已解析",
		"breakthrough": {},
		"results": [],
		"nodes": [
			{
				"recipe_id": "ordinary.assault",
				"display_name": "普通马桶人",
				"rating": "B",
				"faction": "快攻破城",
				"skill_name": "皮搋冲锋",
				"role_copy": "前线突破",
				"one_star_value": "重击最近守军",
				"two_star_effect": "突进顺劈多个目标",
				"three_star_effect": "高倍率冲击并震慑",
				"unlock_source": "1-2 首通或信号招募",
				"status_id": "available",
				"status_copy": "免费研发 · 仅耗时5秒 · 长期资源保持不变",
				"action_id": "start_research",
				"action_label": "免费研发冲锋蓝图 · 5秒",
				"action_name": "UnlockFoundationalBlueprint_ordinary_assault",
				"disabled": false,
			},
			{
				"recipe_id": "ordinary.sonic",
				"display_name": "故障闪电马桶人",
				"rating": "A",
				"faction": "干扰增殖",
				"skill_name": "音波干扰",
				"role_copy": "群体控制",
				"one_star_value": "伤害并削弱同路守军",
				"two_star_effect": "虚弱覆盖跨线目标",
				"three_star_effect": "控制并处决普通守军",
				"unlock_source": "信号招募",
				"status_id": "locked",
				"status_copy": "尚未获得该型号图纸",
				"action_id": "",
			},
		],
	}

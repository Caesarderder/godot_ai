extends SceneTree

const LEGION_SCENE := preload("res://game/scenes/screens/legion_screen.tscn")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if not await _capture_size(Vector2i(844, 390), "res://artifacts/ui-legion-formation-844x390.png"):
		quit(1)
		return
	if not await _capture_size(Vector2i(568, 320), "res://artifacts/ui-legion-formation-568x320.png"):
		quit(1)
		return
	print("LEGION REVIEW CAPTURE PASS")
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
	var legion := LEGION_SCENE.instantiate() as LegionScreen
	margin.add_child(legion)
	legion.configure(_formation_view(viewport_size.x < 720))
	for _frame in 6:
		await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("LEGION REVIEW CAPTURE FAIL: viewport texture unavailable")
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error := image.save_png(path)
	if error != OK:
		push_error("LEGION REVIEW CAPTURE FAIL: %s" % error_string(error))
		return false
	return true


func _formation_view(compact: bool) -> Dictionary:
	return {
		"compact": compact,
		"tab": "formation",
		"first_formation": {"active": false},
		"counterattack": {"visible": false},
		"team_power": 1711,
		"target_stage_name": "1-1 E07 · 监控人登场",
		"recommended_power": 1650,
		"formation_edit_slot": "",
		"formation": [
			{
				"slot_id": "commander",
				"hero_id": "hero_gman",
				"display_name": "Gman",
				"role": "统帅 · 稳定输出",
			},
			{"slot_id": "troop_1", "hero_id": "", "display_name": "空位", "role": "待命"},
			{"slot_id": "troop_2", "hero_id": "", "display_name": "空位", "role": "待命"},
			{"slot_id": "troop_3", "hero_id": "", "display_name": "空位", "role": "待命"},
			{"slot_id": "troop_4", "hero_id": "", "display_name": "空位", "role": "待命"},
			{"slot_id": "troop_5", "hero_id": "", "display_name": "空位", "role": "待命"},
		],
		"candidates": [],
		"roster": [],
	}

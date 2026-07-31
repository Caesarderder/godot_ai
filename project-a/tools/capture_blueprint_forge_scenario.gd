extends SceneTree

const BLUEPRINT_SCENE := preload("res://game/scenes/screens/blueprint_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-blueprint-character-forge"
const CASES := ["available_research", "ready_to_claim", "locked_preview"]
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
		"scenario_id": "scenario_blueprint_character_forge",
		"fixture": "shipping BlueprintScreen through configure and action_requested",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"available research emits start_research with ordinary.assault",
			"ready claim emits claim_research with ordinary.assault",
			"locked preview exposes no primary blueprint action",
			"all visible primary actions remain at least 48 logical pixels",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("BLUEPRINT FORGE SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("BLUEPRINT_FORGE_SCENARIO_OK")
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
	var blueprint := BLUEPRINT_SCENE.instantiate() as BlueprintScreen
	margin.add_child(blueprint)
	var requested := {"id": "", "recipe_id": ""}
	blueprint.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		requested["id"] = action_id
		requested["recipe_id"] = String(payload.get("recipe_id", ""))
	)
	blueprint.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 10:
		await process_frame
	if not _verify_case(blueprint, case_id, requested):
		return false
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("BLUEPRINT FORGE SCENARIO FAIL: texture unavailable")
		return false
	var error := image.save_png(path)
	if error != OK:
		push_error("BLUEPRINT FORGE SCENARIO FAIL: %s" % error_string(error))
		return false
	return true


func _verify_case(blueprint: BlueprintScreen, case_id: String, requested: Dictionary) -> bool:
	var actions := blueprint.find_children("*", "Button", true, false).filter(
		func(node: Node) -> bool: return bool(node.get_meta("primary_blueprint_action", false))
	)
	if case_id == "locked_preview":
		if not actions.is_empty():
			push_error("BLUEPRINT FORGE SCENARIO FAIL: locked preview exposes an action")
			return false
		return true
	if actions.size() != 1:
		push_error("BLUEPRINT FORGE SCENARIO FAIL: expected one primary action")
		return false
	var action := actions[0] as Button
	if action.custom_minimum_size.y < 48.0 or action.disabled:
		push_error("BLUEPRINT FORGE SCENARIO FAIL: primary action is not touch-ready")
		return false
	action.pressed.emit()
	var expected := "start_research" if case_id == "available_research" else "claim_research"
	if requested["id"] != expected or requested["recipe_id"] != "ordinary.assault":
		push_error("BLUEPRINT FORGE SCENARIO FAIL: durable action mismatch")
		return false
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var assault := _assault_node(case_id)
	var sonic := _sonic_node()
	return {
		"compact": compact,
		"branch": "ordinary",
		"branch_title": "突击枝",
		"branch_summary": "突破 · 控场",
		"focus_recipe_id": "ordinary.sonic" if case_id == "locked_preview" else "ordinary.assault",
		"core_status": "选择角色图纸 · 研发后永久入列",
		"breakthrough": {},
		"results": [],
		"nodes": [assault, sonic],
	}


func _assault_node(case_id: String) -> Dictionary:
	var node := {
		"recipe_id": "ordinary.assault",
		"archetype_id": "assault",
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
		"action_label": "免费研发普通马桶人 · 5秒",
		"action_name": "BlueprintForgePrimaryAction",
		"disabled": false,
		"journey_focus": true,
	}
	if case_id == "ready_to_claim":
		node["status_id"] = "researching"
		node["status_copy"] = "研发完成 · 等待领取"
		node["action_id"] = "claim_research"
		node["action_label"] = "领取永久角色"
	return node


func _sonic_node() -> Dictionary:
	return {
		"recipe_id": "ordinary.sonic",
		"archetype_id": "sonic",
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
		"disabled": true,
	}

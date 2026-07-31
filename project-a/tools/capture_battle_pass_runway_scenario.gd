extends SceneTree

const GOALS_SCENE := preload("res://game/scenes/screens/goals_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-mobile-battle-pass-runway"
const CASES := ["claimable_runway", "settled_runway", "future_focus"]
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
		"scenario_id": "scenario_mobile_battle_pass_supply_runway",
		"fixture": "shipping GoalsScreen plus global MobileScrollInput",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"all thirty exact MetaPassLevel identities remain projected",
			"claimable state emits exact individual and batch actions",
			"settled state exposes no executable claim",
			"runway is horizontal-only and focuses the current frontier",
			"finger drag and hovered desktop wheel both move the shipping runway",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("BATTLE PASS RUNWAY SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("BATTLE_PASS_RUNWAY_SCENARIO_OK")
	quit(0)


func _capture_case(case_id: String, viewport_size: Vector2i, path: String) -> bool:
	DisplayServer.window_set_size(viewport_size)
	root.content_scale_size = viewport_size
	root.size = viewport_size
	for child in root.get_children():
		if child.name != "MobileScrollInput":
			child.queue_free()
	await process_frame
	var background := ColorRect.new()
	background.color = Color("#091015")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 12)
	root.add_child(margin)
	var goals := GOALS_SCENE.instantiate() as GoalsScreen
	margin.add_child(goals)
	var requested := {"id": "", "level": 0}
	goals.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		requested["id"] = action_id
		requested["level"] = int(payload.get("level", 0))
	)
	goals.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 10:
		await process_frame
	if not _verify_structure(goals, case_id):
		return false
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null or image.save_png(path) != OK:
		push_error("BATTLE PASS RUNWAY SCENARIO FAIL: capture unavailable")
		return false
	if not await _verify_interaction(goals, case_id, requested):
		return false
	return true


func _verify_structure(goals: GoalsScreen, case_id: String) -> bool:
	var cards: Array[Node] = []
	_collect_prefix(goals, "MetaPassLevel_", cards)
	var runway := goals.find_child("BattlePassRunwayScroll", true, false) as ScrollContainer
	if cards.size() != 30 or runway == null:
		return _fail("thirty-level runway missing")
	if runway.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_SHOW_NEVER or runway.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		return _fail("runway is not horizontal-only")
	var left_hint := goals.find_child("BattlePassRunwayLeftHint", true, false) as Label
	var right_hint := goals.find_child("BattlePassRunwayRightHint", true, false) as Label
	if left_hint == null or right_hint == null or left_hint.text != "◀" or right_hint.text != "▶":
		return _fail("directional drag edge hints are missing")
	if not right_hint.visible:
		return _fail("runway does not expose a forward drag hint")
	if left_hint.get_global_rect().intersects(runway.get_global_rect()) or right_hint.get_global_rect().intersects(runway.get_global_rect()):
		return _fail("drag edge hints overlap reward-card content")
	var batch := goals.find_child("MetaPassBatchClaim", true, false) as Button
	if case_id == "claimable_runway" and (batch == null or batch.disabled or batch.size.y < 48.0):
		return _fail("claimable batch action is not touch-ready")
	if case_id != "claimable_runway" and batch != null:
		return _fail("settled runway exposes a fake batch action")
	if case_id == "future_focus" and runway.scroll_horizontal < 700:
		return _fail("mid-season frontier was not brought into view")
	return true


func _verify_interaction(goals: GoalsScreen, case_id: String, requested: Dictionary) -> bool:
	var runway := goals.find_child("BattlePassRunwayScroll", true, false) as ScrollContainer
	var before := runway.scroll_horizontal
	var origin := runway.get_global_rect().get_center()
	var input := root.get_node_or_null("MobileScrollInput")
	if input == null:
		return _fail("global mobile input router missing")
	_dispatch_touch(input, 7, origin, true)
	_dispatch_drag(input, 7, origin - Vector2(90, 0), Vector2(-90, 0))
	_dispatch_touch(input, 7, origin - Vector2(90, 0), false)
	await process_frame
	if runway.scroll_horizontal <= before:
		return _fail("finger drag did not move shipping runway")
	var wheel_before := runway.scroll_horizontal
	var wheel := InputEventMouseButton.new()
	wheel.position = origin
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	input.call("_input", wheel)
	await process_frame
	if runway.scroll_horizontal <= wheel_before:
		return _fail("desktop wheel did not move shipping runway")
	if case_id == "claimable_runway":
		var level_two := goals.find_child("MetaPassLevel_2", true, false) as Button
		var batch := goals.find_child("MetaPassBatchClaim", true, false) as Button
		level_two.pressed.emit()
		if requested["id"] != "claim_pass_level" or requested["level"] != 2:
			return _fail("individual pass action payload mismatch")
		batch.pressed.emit()
		if requested["id"] != "claim_all_pass":
			return _fail("batch pass action mismatch")
	elif case_id == "settled_runway":
		for level in range(1, 8):
			if not (goals.find_child("MetaPassLevel_%d" % level, true, false) as Button).disabled:
				return _fail("settled tier remains executable")
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var reached := 3 if case_id != "future_focus" else 18
	var claimable_levels := [2, 3] if case_id == "claimable_runway" else []
	var levels: Array[Dictionary] = []
	for level in range(1, 31):
		levels.append({
			"level": level,
			"claimed": level <= reached and level not in claimable_levels,
			"claimable": level in claimable_levels,
			"reward": {
				"toilet_coins": 30 if level % 3 != 0 else 0,
				"porcelain": 30 if level % 3 == 0 else 0,
				"recruit_tickets": 2 if level in [5, 15, 25] else 0,
				"hero_shards": 4 if level in [8, 18, 28] else 0,
			},
		})
	return {
		"compact": compact,
		"short": true,
		"tab": "pass",
		"notification_counts": {"goals_action": 0, "goals_pass": claimable_levels.size(), "goals_achievements": 0},
		"commander": {"level": 5, "xp": 300, "next_xp": 450, "claimable": 0},
		"pass_unlocked": true,
		"pass": {"merit": reached * 100 + 50, "reached": reached, "claimable": claimable_levels.size(), "levels": levels},
	}


func _dispatch_touch(input: Node, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	input.call("_input", event)


func _dispatch_drag(input: Node, index: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	input.call("_input", event)


func _collect_prefix(node: Node, prefix: String, output: Array[Node]) -> void:
	if String(node.name).begins_with(prefix):
		output.append(node)
	for child in node.get_children():
		_collect_prefix(child, prefix, output)


func _fail(message: String) -> bool:
	push_error("BATTLE PASS RUNWAY SCENARIO FAIL: %s" % message)
	return false

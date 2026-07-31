extends SceneTree

const BLUEPRINT_SCENE := preload("res://game/scenes/screens/blueprint_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-mobile-faction-doctrine-deck"
const CASES := ["assault_choice", "armored_choice", "doctrine_activated"]
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
		"scenario_id": "scenario_mobile_faction_doctrine_command_deck",
		"fixture": "shipping BlueprintScreen through configure and action_requested",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"choice states emit exact coordination and specialization ids",
			"activated state exposes no doctrine replacement action",
			"choice targets remain at least 48 logical pixels",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("DOCTRINE DECK SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("FACTION_DOCTRINE_DECK_SCENARIO_OK")
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
	var screen := BLUEPRINT_SCENE.instantiate() as BlueprintScreen
	margin.add_child(screen)
	var requested := {"id": "", "doctrine_id": ""}
	screen.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		requested["id"] = action_id
		requested["doctrine_id"] = String(payload.get("doctrine_id", ""))
	)
	screen.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 10:
		await process_frame
	if not _verify_case(screen, case_id, requested):
		return false
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null or image.save_png(path) != OK:
		push_error("DOCTRINE DECK SCENARIO FAIL: capture unavailable")
		return false
	return true


func _verify_case(screen: BlueprintScreen, case_id: String, requested: Dictionary) -> bool:
	var coordination := screen.find_child("CoordinationChoice", true, false) as Button
	var specialization := screen.find_child("SpecializationChoice", true, false) as Button
	if case_id == "doctrine_activated":
		if (coordination != null and coordination.visible) or (specialization != null and specialization.visible):
			push_error("DOCTRINE DECK SCENARIO FAIL: activated doctrine exposes replacement action")
			return false
		return true
	if coordination == null or specialization == null or coordination.custom_minimum_size.y < 48.0 or specialization.custom_minimum_size.y < 48.0:
		push_error("DOCTRINE DECK SCENARIO FAIL: doctrine targets unavailable")
		return false
	coordination.pressed.emit()
	if requested["id"] != "choose_faction_doctrine" or requested["doctrine_id"] != "coordination":
		push_error("DOCTRINE DECK SCENARIO FAIL: coordination identity mismatch")
		return false
	specialization.pressed.emit()
	if requested["id"] != "choose_faction_doctrine" or requested["doctrine_id"] != "specialization":
		push_error("DOCTRINE DECK SCENARIO FAIL: specialization identity mismatch")
		return false
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var armored := case_id == "armored_choice"
	if case_id == "doctrine_activated":
		return {
			"compact": compact, "branch": "ordinary", "nodes": [],
			"faction_tech_preview": {
				"tier": 2, "faction": "冲锋阵营", "title": "全队协同协议",
				"effect": "同阵营开局 50 能量 · 其余主力 +20 能量",
				"activation_chapter": 4,
			},
		}
	var faction := "铁甲阵营" if armored else "冲锋阵营"
	var coordination_copy := "全队协同 · 同阵营18%护盾\n其余主力 +8%护盾" if armored else "全队协同 · 同阵营50能量\n其余主力 +20能量"
	var specialization_copy := "阵营专精 · 仅同阵营\n获得25%护盾" if armored else "阵营专精 · 仅同阵营\n开局75能量"
	return {
		"compact": compact, "branch": "ordinary", "nodes": [],
		"faction_tech_preview": {"tier": 1, "faction": faction, "title": "核心协议", "effect": "第4章起自动生效", "activation_chapter": 4},
		"faction_tech_choices": [
			{"doctrine_id":"coordination","choice_summary":coordination_copy,"action_label":"选择全队协同"},
			{"doctrine_id":"specialization","choice_summary":specialization_copy,"action_label":"选择阵营专精"},
		],
	}

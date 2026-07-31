extends SceneTree

const BLUEPRINT_SCENE := preload("res://game/scenes/screens/blueprint_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-mobile-breakthrough-hero-reveal"
const CASES := ["mixed_reveal", "resource_heavy_reveal", "reduced_motion_reveal"]
const VIEWPORTS := [Vector2i(844, 390), Vector2i(568, 320)]


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	# Prime fonts, styles and renderer resources outside the evidence bundle so
	# the first 844-wide artifact is not a one-time warmup frame.
	var warmup_path := "user://breakthrough_reveal_warmup.png"
	if not await _capture_case("reduced_motion_reveal", Vector2i(844, 390), warmup_path):
		quit(1)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(warmup_path))
	var artifacts: Array[String] = []
	for case_id in CASES:
		for viewport_size in VIEWPORTS:
			var filename := "%s-%dx%d.png" % [case_id, viewport_size.x, viewport_size.y]
			if not await _capture_case(case_id, viewport_size, "%s/%s" % [OUTPUT_DIR, filename]):
				quit(1)
				return
			artifacts.append(filename)
	var manifest := {
		"scenario_id": "scenario_mobile_breakthrough_hero_reveal",
		"fixture": "shipping BlueprintScreen through configure and action_requested",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"all ten reward identities remain projected",
			"result emits exact open_legion handoff",
			"resolved result exposes no repeat breakthrough claim",
			"handoff remains at least 48 logical pixels",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("BREAKTHROUGH HERO REVEAL SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("BREAKTHROUGH_HERO_REVEAL_SCENARIO_OK")
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
	var requested := {"id": ""}
	screen.action_requested.connect(func(action_id: String, _payload: Dictionary) -> void:
		requested["id"] = action_id
	)
	screen.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 12:
		await process_frame
	if not _verify_case(screen, case_id, requested):
		return false
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null or image.save_png(path) != OK:
		push_error("BREAKTHROUGH HERO REVEAL SCENARIO FAIL: capture unavailable")
		return false
	return true


func _verify_case(screen: BlueprintScreen, case_id: String, requested: Dictionary) -> bool:
	var results_panel := screen.find_child("ResearchBreakthroughResults", true, false) as Control
	var handoff := screen.find_child("BlueprintResultsLegionButton", true, false) as Button
	var repeat_claim := screen.find_child("ClaimResearchBreakthroughTen", true, false) as Button
	if results_panel == null or not results_panel.visible:
		return _fail("result panel unavailable in %s" % case_id)
	if handoff == null or not handoff.visible or handoff.custom_minimum_size.y < 48.0:
		return _fail("legion handoff unavailable in %s" % case_id)
	if repeat_claim != null and repeat_claim.visible:
		return _fail("resolved result exposes repeat claim in %s" % case_id)
	for reward_id in ["assault", "armored", "skill_chip", "porcelain_0", "porcelain_1", "parts_0", "parts_1", "energy_0", "energy_1", "sludge_0"]:
		if screen.find_child("BreakthroughResult_%s" % reward_id, true, false) == null:
			return _fail("reward identity missing: %s" % reward_id)
	handoff.pressed.emit()
	if requested["id"] != "open_legion":
		return _fail("legion handoff identity mismatch")
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var resource_heavy := case_id == "resource_heavy_reveal"
	var results := [
		{"id":"assault","rarity":"A","kind":"hero","title":"精锐 · 冲锋马桶人","subtitle":"突击 · 快速压制","impact":"反攻：快速突破敌阵"},
		{"id":"armored","rarity":"A","kind":"hero","title":"精锐 · 装甲冲城马桶人","subtitle":"重装 · 承伤保护","impact":"反攻：承伤保护队伍"},
		{"id":"skill_chip","rarity":"A","kind":"skill_chip","title":"A · 技能芯片","subtitle":"+1"},
		{"id":"porcelain_0","rarity":"R","kind":"porcelain","title":"R · 陶瓷","subtitle":"+%d" % (120 if resource_heavy else 80)},
		{"id":"porcelain_1","rarity":"R","kind":"porcelain","title":"R · 陶瓷","subtitle":"+60"},
		{"id":"parts_0","rarity":"R","kind":"parts","title":"R · 零件","subtitle":"+5"},
		{"id":"parts_1","rarity":"R","kind":"parts","title":"R · 零件","subtitle":"+5"},
		{"id":"energy_0","rarity":"R","kind":"energy","title":"R · 能源","subtitle":"+4"},
		{"id":"energy_1","rarity":"R","kind":"energy","title":"R · 能源","subtitle":"+4"},
		{"id":"sludge_0","rarity":"R","kind":"sludge","title":"R · 污泥","subtitle":"+3"},
	]
	return {
		"compact": compact,
		"branch": "ordinary",
		"breakthrough": {},
		"results_summary": "2 名永久援军 + 8 份研究物资 · 高墙反攻条件已经凑齐",
		# Canonical visual evidence captures the settled state. Animation behavior
		# remains covered by BlueprintScreen runtime tests rather than frame hashes.
		"reduced_motion": true,
		"results": results,
		"nodes": [],
	}


func _fail(message: String) -> bool:
	push_error("BREAKTHROUGH HERO REVEAL SCENARIO FAIL: %s" % message)
	return false

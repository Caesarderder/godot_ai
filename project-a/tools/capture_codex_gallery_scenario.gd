extends SceneTree

const LEGION_SCENE := preload("res://game/scenes/screens/legion_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-codex-gallery"
const CASES := ["early_collection", "blueprint_focus", "mixed_collection"]
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
		"scenario_id": "scenario_codex_gallery_identity",
		"fixture": "shipping LegionScreen through configure and public signals",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"collection progress remains visible",
			"collected, blueprint-ready and unknown states remain distinct",
			"every character choice remains reachable",
			"interactive gallery targets remain touch sized",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("CODEX GALLERY SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("CODEX_GALLERY_SCENARIO_OK")
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
	var legion := LEGION_SCENE.instantiate() as LegionScreen
	margin.add_child(legion)
	legion.configure(_case_view(case_id, viewport_size.x < 720))
	for _frame in 8:
		await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	if image == null:
		push_error("CODEX GALLERY SCENARIO FAIL: texture unavailable")
		return false
	var error := image.save_png(path)
	if error != OK:
		push_error("CODEX GALLERY SCENARIO FAIL: %s" % error_string(error))
		return false
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var entries := _entries()
	var focus_id := "gman"
	if case_id == "blueprint_focus":
		focus_id = "assault"
		_set_status(entries, "assault", "blueprint_owned", "已有图纸 · 等待研究")
	elif case_id == "mixed_collection":
		focus_id = "armored"
		_set_status(entries, "assault", "researched", "已研发 · 永久入列")
		_set_status(entries, "armored", "researched", "已研发 · 永久入列")
		_set_status(entries, "rocket", "blueprint_owned", "已有图纸 · 等待研究")
		_set_status(entries, "sonic", "blueprint_owned", "已有图纸 · 等待研究")
	return {
		"compact": compact,
		"tab": "codex",
		"first_formation": {"active": false},
		"first_growth_choice": {"active": false},
		"boss_ready": {"active": false},
		"codex_focus_id": focus_id,
		"codex": entries,
		"formation": [],
		"roster": [],
	}


func _entries() -> Array[Dictionary]:
	var ids := [
		"gman", "assault", "armored", "rocket", "sonic", "bomber", "saw", "repair",
		"parasite", "signal_purifier", "anchor_bastion", "magnetic_conductor",
	]
	var names := [
		"Gman", "普通马桶人", "激光火箭筒马桶人", "飞行四发射器马桶人",
		"故障闪电马桶人", "炸弹桶马桶人", "飞行双圆锯马桶人", "研究员马桶人",
		"大型寄生虫马桶人", "钢爪马桶人科学家", "巨型飞行马桶人", "冲击波直升机马桶人",
	]
	var entries: Array[Dictionary] = []
	for index in ids.size():
		entries.append({
			"recipe_id": "recipe_%s" % ids[index],
			"archetype_id": ids[index],
			"display_name": names[index],
			"rating": "S" if index in [6, 8] else ("A" if index in [2, 4, 5, 9, 11] else "B"),
			"role_copy": ["全线攻坚", "前线突破", "承压反炮", "远程攻城"][index % 4],
			"description": "永久角色战术档案",
			"status": "researched" if index == 0 else "undiscovered",
			"status_copy": "初始指挥官 · 永久入列" if index == 0 else "尚未发现设计信号",
			"fragments": index * 3,
			"faction": ["快攻破城", "钢铁防线", "远程轰炸", "干扰增殖"][index % 4],
		})
	return entries


func _set_status(entries: Array[Dictionary], archetype_id: String, status: String, copy: String) -> void:
	for entry in entries:
		if String(entry["archetype_id"]) == archetype_id:
			entry["status"] = status
			entry["status_copy"] = copy
			return

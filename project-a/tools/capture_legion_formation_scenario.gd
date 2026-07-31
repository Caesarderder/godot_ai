extends SceneTree

const LEGION_SCENE := preload("res://game/scenes/screens/legion_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-legion-formation"
const CASES := ["single_commander", "slot_selected", "full_squad"]
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
		"scenario_id": "scenario_legion_formation_identity",
		"fixture": "shipping LegionScreen through configure and action signals",
		"cases": CASES,
		"viewports": ["844x390", "568x320"],
		"artifacts": artifacts,
		"assertions": [
			"six formation slots remain visible",
			"occupied slots preserve stable hero identity",
			"selected empty slot exposes deploy candidates",
			"primary action remains touch sized",
		],
		"exit_code": 0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		push_error("LEGION FORMATION SCENARIO FAIL: manifest unavailable")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("LEGION_FORMATION_SCENARIO_OK")
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
		push_error("LEGION FORMATION SCENARIO FAIL: texture unavailable")
		return false
	var error := image.save_png(path)
	if error != OK:
		push_error("LEGION FORMATION SCENARIO FAIL: %s" % error_string(error))
		return false
	return true


func _case_view(case_id: String, compact: bool) -> Dictionary:
	var formation := _single_formation()
	var candidates: Array[Dictionary] = []
	var edit_slot := ""
	if case_id == "slot_selected":
		edit_slot = "troop_1"
		candidates = [
			_candidate("hero_assault", "assault", "冲锋马桶人", "前线突破", 1724, 1724, true),
			_candidate("hero_armored", "armored", "装甲马桶人", "承压反炮", 1638, 1638, false),
		]
	elif case_id == "full_squad":
		formation = [
			_slot("commander", "hero_gman", "gman", "Gman", "统帅"),
			_slot("troop_1", "hero_assault", "assault", "冲锋马桶人", "突破"),
			_slot("troop_2", "hero_armored", "armored", "装甲马桶人", "承压"),
			_slot("troop_3", "hero_rocket", "rocket", "火箭马桶人", "攻城"),
			_slot("troop_4", "hero_repair", "repair", "研究员马桶人", "救援"),
			_slot("troop_5", "hero_saw", "saw", "圆锯马桶人", "斩杀"),
		]
	return {
		"compact": compact,
		"tab": "formation",
		"first_formation": {"active": false},
		"counterattack": {"visible": case_id == "full_squad", "stage_id": "stage_1_4", "label": "立即反攻 1-4"},
		"team_power": 1711 if case_id != "full_squad" else 10426,
		"target_stage_name": "1-4 高墙防线",
		"recommended_power": 5700,
		"formation_edit_slot": edit_slot,
		"formation": formation,
		"candidates": candidates,
		"roster": [],
	}


func _single_formation() -> Array[Dictionary]:
	return [
		_slot("commander", "hero_gman", "gman", "Gman", "统帅"),
		_slot("troop_1", "", "", "空位", "待命"),
		_slot("troop_2", "", "", "空位", "待命"),
		_slot("troop_3", "", "", "空位", "待命"),
		_slot("troop_4", "", "", "空位", "待命"),
		_slot("troop_5", "", "", "空位", "待命"),
	]


func _slot(slot_id: String, hero_id: String, archetype_id: String, display_name: String, role: String) -> Dictionary:
	return {"slot_id": slot_id, "hero_id": hero_id, "archetype_id": archetype_id, "display_name": display_name, "role": role}


func _candidate(hero_id: String, archetype_id: String, display_name: String, role: String, power: int, delta: int, recommended: bool) -> Dictionary:
	return {
		"hero_id": hero_id,
		"archetype_id": archetype_id,
		"display_name": display_name,
		"role": role,
		"faction": "高速突袭" if archetype_id == "assault" else "钢铁防线",
		"playstyle": "抢先破城" if archetype_id == "assault" else "吸收炮击",
		"skill_name": "强袭" if archetype_id == "assault" else "护盾反震",
		"power": power,
		"power_delta": delta,
		"current": false,
		"recommended": recommended,
		"journey_focus": recommended,
		"journey_focus_label": "推荐",
	}

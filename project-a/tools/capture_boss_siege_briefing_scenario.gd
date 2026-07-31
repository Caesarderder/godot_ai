extends SceneTree

const WAR_ZONE_SCENE := preload("res://game/scenes/screens/war_zone_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-mobile-boss-siege-briefing"
const CASES := ["underpowered_boss", "boss_ready", "boss_cleared"]
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
		"scenario_id":"scenario_mobile_boss_siege_briefing",
		"fixture":"shipping WarZoneScreen plus StageDetailPanel signals",
		"cases":CASES,"viewports":["844x390","568x320"],"artifacts":artifacts,
		"assertions":["five exact stage nodes remain","underpowered preparation emits upgrade","attack and replay emit stage_1_5","visible actions remain 48px touch targets"],
		"exit_code":0,
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
	if file == null:
		return _fail_and_quit("manifest unavailable")
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	print("BOSS_SIEGE_BRIEFING_SCENARIO_OK")
	quit(0)


func _capture_case(case_id: String, viewport_size: Vector2i, path: String) -> bool:
	for child in root.get_children():
		child.queue_free()
	await process_frame
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	root.add_child(viewport)
	var war_zone := WAR_ZONE_SCENE.instantiate() as WarZoneScreen
	war_zone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(war_zone)
	var requested := {"attack":"","prepare":""}
	war_zone.attack_requested.connect(func(stage_id: String) -> void: requested["attack"] = stage_id)
	war_zone.preparation_requested.connect(func(action_id: String) -> void: requested["prepare"] = action_id)
	war_zone.configure(
		1, 1, "stage_1_5", _stage_rows(case_id), _boss_config(), _report(case_id),
		true, case_id == "boss_cleared", "低" if case_id == "boss_ready" else "高",
		viewport_size.x < 650
	)
	for _frame in 10:
		await process_frame
	if not _verify(war_zone, case_id, requested):
		return false
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	if image == null or image.get_size() != viewport_size:
		return _fail("capture size mismatch")
	if image.save_png(path) != OK:
		return _fail("capture unavailable")
	return true


func _verify(war_zone: WarZoneScreen, case_id: String, requested: Dictionary) -> bool:
	for level in range(1, 6):
		if war_zone.find_child("StageNode_stage_1_%d" % level, true, false) == null:
			return _fail("missing stage node %d" % level)
	var boss_node := war_zone.find_child("StageNode_stage_1_5", true, false) as Button
	if (
		OS.get_environment("BOSS_BRIEFING_BASELINE_CAPTURE") != "1"
		and (boss_node == null or boss_node.icon == null or not bool(boss_node.get_meta("boss_fortress", false)))
	):
		return _fail("chapter boss lacks a semantic fortress landmark")
	var detail := war_zone.find_child("SelectedStagePanel", true, false) as Control
	var attack := war_zone.find_child("AttackButton", true, false) as Button
	var growth := war_zone.find_child("GrowthButton", true, false) as Button
	if detail == null or attack == null or not attack.is_visible_in_tree() or attack.size.y < 48:
		return _fail("boss attack HUD is not touch-ready")
	if case_id == "underpowered_boss":
		if growth == null or not growth.is_visible_in_tree() or growth.size.y < 48:
			return _fail("preparation HUD is not touch-ready")
		growth.pressed.emit()
		if requested["prepare"] != "upgrade":
			return _fail("preparation action mismatch")
	attack.pressed.emit()
	if requested["attack"] != "stage_1_5":
		return _fail("boss attack/replay stage mismatch")
	return true


func _stage_rows(case_id: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for level in range(1, 6):
		rows.append({
			"stage_id":"stage_1_%d" % level,
			"display_name":"1-%d · %s" % [level, ["城市街口","废弃车站","信号塔","高墙前哨","联盟核心巨炮"][level - 1]],
			"status":"已夺回" if level < 5 or case_id == "boss_cleared" else "前线",
			"unlocked":true,
		})
	return rows


func _boss_config() -> Dictionary:
	return {
		"display_name":"1-5 · 联盟核心巨炮",
		"threat_summary":"飞行马桶加入交战，核心巨炮正在蓄能。",
		"counter_hint":"用突击抢拆炮台，或由装甲格挡巨炮后反震。",
	}


func _report(case_id: String) -> Dictionary:
	if case_id == "boss_ready":
		return {"cp_ready":5480,"recommended_power":5400,"capability_ratio":1.01,"risk_id":"stable","risk_label":"可进攻","next_action":{"id":"attack","title":"击穿核心"}}
	if case_id == "boss_cleared":
		return {"cp_ready":6200,"recommended_power":5400,"capability_ratio":1.15,"risk_id":"stable","risk_label":"已攻克","next_action":{"id":"attack","title":"再次夺取"}}
	return {"cp_ready":3792,"recommended_power":5400,"capability_ratio":0.70,"risk_id":"extreme","risk_label":"极高风险","next_action":{"id":"upgrade","title":"先培养军团","blocks_attack":false}}


func _fail(message: String) -> bool:
	push_error("BOSS SIEGE BRIEFING SCENARIO FAIL: %s" % message)
	return false


func _fail_and_quit(message: String) -> void:
	_fail(message)
	quit(1)

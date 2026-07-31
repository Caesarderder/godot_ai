extends SceneTree

const WAR_ZONE_SCENE := preload("res://game/scenes/screens/war_zone_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-war-zone-exploration"

var manifest: Dictionary = {
	"scenario_id": "scenario_war_zone_exploration",
	"subject": "chapter_1_frontier",
	"cases": [],
	"complete": false,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for viewport_size in [Vector2i(844, 390), Vector2i(568, 320)]:
		if not await _capture_case(viewport_size):
			quit(1)
			return
	manifest["complete"] = true
	var manifest_path := "%s/manifest.json" % OUTPUT_DIR
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		push_error("WAR_ZONE_CAPTURE_FAIL: cannot write manifest")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	print("WAR_ZONE_CAPTURE_OK: %s" % manifest_path)
	quit(0)


func _capture_case(viewport_size: Vector2i) -> bool:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var war_zone := WAR_ZONE_SCENE.instantiate() as Control
	viewport.add_child(war_zone)
	war_zone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	war_zone.configure(
		1,
		1,
		"stage_1_3",
		_stage_rows(),
		{
			"display_name": "1-3 E09 · 城市信号塔",
			"threat_summary": "监控人正在从高楼搜索地下反抗信号。",
			"counter_hint": "沿已夺回街区推进，切断塔顶监控阵列。",
		},
		{
			"cp_ready": 1960,
			"recommended_power": 2100,
			"capability_ratio": 0.93,
			"risk_id": "high",
			"risk_label": "高风险",
			"next_action": {"id": "attack", "title": "突入信号塔"},
		},
		true,
		false,
		"高",
		viewport_size.x < 650
	)
	for _frame in 6:
		await process_frame
		await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("WAR_ZONE_CAPTURE_FAIL: empty %s" % viewport_size)
		viewport.queue_free()
		return false
	var output := "%s/war-zone-%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y]
	if image.save_png(output) != OK:
		push_error("WAR_ZONE_CAPTURE_FAIL: cannot save %s" % output)
		viewport.queue_free()
		return false
	manifest["cases"].append({
		"case_id": "territorial_progress" if viewport_size.x > 600 else "compact_frontier",
		"viewport": [viewport_size.x, viewport_size.y],
		"selected_stage": "stage_1_3",
		"cleared_stages": ["stage_1_1", "stage_1_2"],
		"locked_stages": ["stage_1_4", "stage_1_5"],
		"artifact": output.trim_prefix("res://"),
	})
	viewport.queue_free()
	await process_frame
	return true


func _stage_rows() -> Array[Dictionary]:
	return [
		{"stage_id":"stage_1_1","display_name":"1-1 · 地铁出口","status":"已夺回","unlocked":true},
		{"stage_id":"stage_1_2","display_name":"1-2 · 破碎街区","status":"已夺回","unlocked":true},
		{"stage_id":"stage_1_3","display_name":"1-3 · 城市信号塔","status":"前线","unlocked":true},
		{"stage_id":"stage_1_4","display_name":"1-4 · 监控人火力点","status":"信号中断","unlocked":false},
		{"stage_id":"stage_1_5","display_name":"1-5 · 未知空域","status":"未知","unlocked":false},
	]

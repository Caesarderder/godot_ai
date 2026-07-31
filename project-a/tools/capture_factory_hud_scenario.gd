extends SceneTree

const FACTORY_SCENE := preload("res://game/scenes/screens/factory_screen.tscn")
const OUTPUT_DIR := "res://artifacts/scenario-factory-hud"
const CASES: Array[String] = [
	"mission_world_first",
	"contextual_facility",
	"construction_carousel",
	"placement_decision",
]

var manifest: Dictionary = {
	"scenario_id": "scenario_factory_world_hud",
	"subject": "factory_hud_state",
	"cases": [],
	"complete": false,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for viewport_size in [Vector2i(844, 390), Vector2i(568, 320)]:
		for case_id in CASES:
			if not await _capture_case(viewport_size, case_id):
				quit(1)
				return
	manifest["complete"] = true
	var manifest_path := "%s/manifest.json" % OUTPUT_DIR
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		push_error("FACTORY_HUD_CAPTURE_FAIL: cannot write manifest")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	print("FACTORY_HUD_CAPTURE_OK: %s" % manifest_path)
	quit(0)


func _capture_case(viewport_size: Vector2i, case_id: String) -> bool:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	_build_neutral_world(viewport, viewport_size)
	var factory := FACTORY_SCENE.instantiate() as FactoryScreen
	viewport.add_child(factory)
	factory.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	factory.configure(_view_for(case_id, viewport_size.x < 650))
	for _frame in 6:
		await process_frame
		await RenderingServer.frame_post_draw
	var hud_frame := factory.find_child("FactoryHudFrame", true, false) as Control
	var resource_hud := factory.find_child("FactoryResourceHUD", true, false) as Control
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty() or hud_frame == null or resource_hud == null:
		push_error("FACTORY_HUD_CAPTURE_FAIL: invalid case %s %s" % [case_id, viewport_size])
		viewport.queue_free()
		return false
	var output := "%s/%s-%dx%d.png" % [OUTPUT_DIR, case_id, viewport_size.x, viewport_size.y]
	if image.save_png(output) != OK:
		push_error("FACTORY_HUD_CAPTURE_FAIL: cannot save %s" % output)
		viewport.queue_free()
		return false
	manifest["cases"].append({
		"case_id": case_id,
		"viewport": [viewport_size.x, viewport_size.y],
		"artifact": output.trim_prefix("res://"),
		"hud_rect": [hud_frame.position.x, hud_frame.position.y, hud_frame.size.x, hud_frame.size.y],
		"resource_rect": [resource_hud.position.x, resource_hud.position.y, resource_hud.size.x, resource_hud.size.y],
		"hud_area_ratio": snappedf(
			(hud_frame.size.x * hud_frame.size.y + resource_hud.size.x * resource_hud.size.y)
			/ float(viewport_size.x * viewport_size.y),
			0.001
		),
	})
	viewport.queue_free()
	await process_frame
	return true


func _build_neutral_world(viewport: SubViewport, viewport_size: Vector2i) -> void:
	var background := ColorRect.new()
	background.color = Color("#071015")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(background)
	var world := Control.new()
	world.name = "NeutralFactoryWorldField"
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(world)
	var floor := Polygon2D.new()
	var center := Vector2(viewport_size) * Vector2(0.53, 0.57)
	var radius := minf(viewport_size.x * 0.34, viewport_size.y * 0.43)
	var polygon := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		polygon.append(center + Vector2(cos(angle), sin(angle) * 0.52) * radius)
	floor.polygon = polygon
	floor.color = Color("#18363a")
	world.add_child(floor)
	for index in range(7):
		var angle := TAU * float(index) / 7.0 - PI * 0.5
		var building := Polygon2D.new()
		var building_center := center + Vector2(cos(angle), sin(angle) * 0.52) * radius * 0.72
		building.polygon = PackedVector2Array([
			building_center + Vector2(-22, -13),
			building_center + Vector2(18, -13),
			building_center + Vector2(24, 12),
			building_center + Vector2(-17, 15),
		])
		building.color = Color("#31585a") if index != 0 else Color("#3c8880")
		world.add_child(building)
		var beacon := ColorRect.new()
		beacon.position = building_center + Vector2(9, -17)
		beacon.size = Vector2(5, 5)
		beacon.color = Color("#58c9c2") if index % 2 == 0 else Color("#e5a84b")
		world.add_child(beacon)


func _view_for(case_id: String, compact: bool) -> Dictionary:
	var view := _base_view(compact)
	match case_id:
		"contextual_facility":
			view["panel"] = "facility"
		"construction_carousel":
			view["panel"] = "build"
		"placement_decision":
			view["panel"] = "build"
			view["construction"] = {
				"options": [],
				"active_id": "research_lab",
				"active_name": "研究所",
				"active_copy": "把战场情报转成永久援军",
				"cost_copy": "工业材料 30",
				"build_seconds": 5,
				"placement_copy": "已选网格 (2,1) · 确认后扣除材料",
				"can_confirm": true,
				"occupied": false,
			}
	return view


func _base_view(compact: bool) -> Dictionary:
	return {
		"compact": compact,
		"panel": "mission",
		"notification_counts": {"factory_work_ready": 1},
		"resources": [
			{"name":"工业材料","current":30,"capacity":160,"rate":0.0,"status":"暂停后满","full":false},
		],
		"task": {
			"title":"建设研究所",
			"objectives":[{"label":"在基地建设首座研究所","completed":false}],
			"cta_label":"建设研究所",
			"target":"factory_build",
		},
		"facility": {
			"facility_id":"command_center","name":"指挥中心","copy":"地下抵抗军的调度核心",
			"level":1,"work":{},"kind":"global","upgrade_cost_copy":"工业材料 40",
			"upgrade_preview":"提升工厂容量","can_upgrade":true,
		},
		"construction": {
			"options":[
				{"facility_id":"research_lab","name":"研究所","cost_copy":"材料 30","copy":"研发永久援军","build_seconds":5,"disabled":false},
				{"facility_id":"porcelain_plant","name":"材料厂","cost_copy":"材料 30","copy":"持续生产工业材料","build_seconds":5,"disabled":false},
				{"facility_id":"coin_mint","name":"铸币厂","cost_copy":"2-12 解锁","copy":"生产金币","build_seconds":5,"disabled":true},
			],
			"active_id":"",
		},
	}

extends SceneTree

const FACTORY_SCENE := preload("res://game/scenes/screens/factory_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var factory := FACTORY_SCENE.instantiate() as FactoryScreen
	root.add_child(factory)
	await process_frame
	factory.configure(_base_view())
	await process_frame
	_check(factory.find_child("FactoryWorldInteractionArea", true, false) != null, "screen reserves the 3D interaction area")
	_check(factory.find_child("FactoryResourceHUD", true, false) != null, "resources remain fixed above the factory body")
	_check(factory.find_child("ResourceMeter_陶瓷", true, false) != null, "industrial stock uses a capacity meter")
	_check(_tree_has_text(factory, "全员无损"), "factory reinforces the lossless battle contract")
	_check(_tree_has_text(factory, "撞击高墙"), "mission panel projects the current player action")
	var mission_tab := factory.find_child("FactoryHudMissionTab", true, false) as Button
	var build_tab := factory.find_child("FactoryHudBuildTab", true, false) as Button
	_check(mission_tab != null and build_tab != null and mission_tab.button_group == build_tab.button_group, "three HUD tabs are one exclusive decision group")
	var panel_request := {"id": ""}
	factory.panel_selected.connect(func(panel_id: String) -> void: panel_request["id"] = panel_id)
	if build_tab != null:
		build_tab.pressed.emit()
	_check(panel_request["id"] == "build", "screen emits a semantic panel request")

	var build_view := _base_view()
	build_view["panel"] = "build"
	factory.configure(build_view)
	await process_frame
	_check(factory.find_child("ConstructionButtonGrid", true, false) != null, "build mode owns a compact facility catalog")
	var research_choice := factory.find_child("ChooseFacility_research_lab", true, false) as Button
	_check(research_choice != null and research_choice.disabled, "research lab remains unavailable before battle evidence")
	_check(String(research_choice.tooltip_text).contains("挑战 1-4"), "locked research explains the exact unlock action")

	build_view["construction"] = {
		"options": [],
		"active_id": "research_lab",
		"active_name": "研究所",
		"active_copy": "把战场情报转化为永久援军",
		"cost": 70,
		"placement_copy": "已选择格子 (2, 1)；确认后才扣除资源。",
		"can_confirm": true,
		"occupied": false,
	}
	factory.configure(build_view)
	await process_frame
	_check(_tree_has_text(factory, "确认后才扣除资源"), "placement makes the transaction boundary explicit")
	var confirm := factory.find_child("ConfirmFacilityConstruction", true, false) as Button
	_check(confirm != null and not confirm.disabled, "valid placement exposes a single confirmation action")
	var action_request := {"id": ""}
	factory.action_requested.connect(func(action_id: String, _payload: Dictionary) -> void: action_request["id"] = action_id)
	if confirm != null:
		confirm.pressed.emit()
	_check(action_request["id"] == "confirm_construction", "screen emits a semantic construction request")
	factory.queue_free()
	await process_frame
	if failures.is_empty():
		print("FACTORY_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FACTORY_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _base_view() -> Dictionary:
	return {
		"compact": false,
		"panel": "mission",
		"coins": 70,
		"tech": 0,
		"resources": [
			{"name": "陶瓷", "current": 80, "capacity": 120, "rate": 6.0, "status": "7分 后存满", "full": false},
			{"name": "零件", "current": 48, "capacity": 120, "rate": 3.0, "status": "24分 后存满", "full": false},
			{"name": "能源", "current": 32, "capacity": 120, "rate": 4.0, "status": "22分 后存满", "full": false},
		],
		"task": {
			"title": "行动三：撞击高墙",
			"objectives": [{"label": "完成首次 1-4 挑战", "completed": false}],
			"cta_label": "前往 1-4",
			"target": "map",
			"stage_id": "stage_1_4",
		},
		"facility": {
			"facility_id": "command_center",
			"name": "指挥中心",
			"copy": "决定全局等级与城区权限",
			"level": 1,
			"work": {},
			"kind": "global",
			"upgrade_cost_copy": "升级消耗：金币 40",
			"upgrade_preview": "升级收益：提高工厂全局容量",
			"can_upgrade": true,
		},
		"construction": {
			"options": [
				{"facility_id": "porcelain_plant", "name": "陶瓷厂", "cost": 30, "copy": "生产陶瓷", "disabled": false},
				{"facility_id": "research_lab", "name": "研究所", "cost": 70, "copy": "先挑战 1-4，让首败战报定位研究所方案。", "disabled": true},
			],
			"active_id": "",
		},
	}


func _tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment):
		return true
	if node is Button and (node as Button).text.contains(fragment):
		return true
	for child in node.get_children():
		if _tree_has_text(child, fragment):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

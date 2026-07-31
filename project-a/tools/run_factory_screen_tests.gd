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
	var resource_hud := factory.find_child("FactoryResourceHUD", true, false) as Control
	_check(
		resource_hud != null and resource_hud.anchor_right < 1.0 and resource_hud.offset_right <= 330.0,
		"factory keeps logistics in a shrink-wrapped edge island"
	)
	var compact_view := _base_view()
	compact_view["compact"] = true
	factory.configure(compact_view)
	await process_frame
	var compact_resource_icon := factory.find_child("CompactIndustrialMaterialIcon", true, false) as TextureRect
	_check(
		compact_resource_icon != null
		and compact_resource_icon.texture != null
		and compact_resource_icon.tooltip_text == "陶瓷",
		"compact logistics replaces the cramped material name with a raster icon and on-demand label"
	)
	factory.configure(_base_view())
	await process_frame
	var mission_action := factory.find_child("FactoryMissionPrimaryAction", true, false) as Button
	_check(mission_action != null and mission_action.icon != null, "factory mission action uses a raster target icon instead of a Unicode arrow")
	_check(
		mission_action != null
		and mission_action.text.contains("前往 1-4")
		and mission_action.tooltip_text.contains("撞击高墙"),
		"mission beacon keeps the current action visible with detailed context on demand"
	)
	var mission_tab := factory.find_child("FactoryHudMissionTab", true, false) as Button
	var build_tab := factory.find_child("FactoryHudBuildTab", true, false) as Button
	_check(mission_tab != null and build_tab != null and mission_tab.button_group == build_tab.button_group, "three HUD tabs are one exclusive decision group")
	var tool_rail := factory.find_child("FactoryToolRail", true, false) as Control
	var hud_frame := factory.find_child("FactoryHudFrame", true, false) as Control
	_check(
		tool_rail != null and hud_frame != null and tool_rail.get_parent() == hud_frame.get_parent(),
		"facility and build tools stay independent from the contextual content panel"
	)
	_check(
		hud_frame != null and hud_frame.size.x <= 210.0 and hud_frame.size.y <= 100.0,
		"mission state remains a compact action beacon instead of a dashboard"
	)
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
	var porcelain_choice := factory.find_child("ChooseFacility_porcelain_plant", true, false) as Button
	_check(
		porcelain_choice != null and porcelain_choice.tooltip_text.contains("5秒"),
		"construction catalog keeps the five-second wait in on-demand detail"
	)
	var catalog_scroll := factory.find_child("ConstructionCatalogScroll", true, false) as ScrollContainer
	_check(
		catalog_scroll != null and catalog_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED,
		"construction choices remain one horizontal touch strip"
	)
	var gift_view := _base_view()
	gift_view["panel"] = "build"
	(gift_view["construction"] as Dictionary)["focused_growth"] = true
	(gift_view["construction"] as Dictionary)["recovery_gift"] = {
		"gift_id": "new_game_supply_v1",
		"title": "新游补给礼包",
		"reward_copy": "金币 ×50 · 工业材料 ×30",
		"reason_copy": "下一座工业设施启动资金",
	}
	factory.configure(gift_view)
	await process_frame
	var gift_action_request := {"id": "", "gift_id": ""}
	factory.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		gift_action_request["id"] = action_id
		gift_action_request["gift_id"] = String(payload.get("gift_id", ""))
	)
	var recovery_gift := factory.find_child("ClaimFactoryRecoveryGift", true, false) as Button
	_check(
		recovery_gift != null and recovery_gift.text.contains("领取补给"),
		"an unfunded first facility exposes the earned supply gift instead of three dead choices"
	)
	if recovery_gift != null:
		recovery_gift.pressed.emit()
	_check(
		gift_action_request["id"] == "claim_starter_gift"
		and gift_action_request["gift_id"] == "new_game_supply_v1",
		"the factory recovery gift emits one exact durable claim request"
	)

	build_view["construction"] = {
		"options": [],
		"active_id": "research_lab",
		"active_name": "研究所",
		"active_copy": "把战场情报转化为永久援军",
		"cost": 70,
		"build_seconds": 5,
		"placement_copy": "已选择格子 (2, 1)；确认后才扣除资源。",
		"can_confirm": true,
		"occupied": false,
	}
	factory.configure(build_view)
	await process_frame
	_check(_tree_has_text(factory, "确认后才扣除资源"), "placement makes the transaction boundary explicit")
	_check(_tree_has_text(factory, "5秒"), "placement states the short construction wait before confirmation")
	var confirm := factory.find_child("ConfirmFacilityConstruction", true, false) as Button
	_check(confirm != null and not confirm.disabled, "valid placement exposes a single confirmation action")
	var cancel := factory.find_child("CancelFacilityConstruction", true, false) as Button
	_check(
		confirm != null and cancel != null and confirm.get_parent() == cancel.get_parent(),
		"construction keeps confirm and cancel in one compact decision row"
	)
	_check(
		confirm != null and confirm.custom_minimum_size.y >= 44.0
			and cancel != null and cancel.custom_minimum_size.y >= 44.0,
		"both construction decisions retain touch-sized controls"
	)
	var action_request := {"id": ""}
	factory.action_requested.connect(func(action_id: String, _payload: Dictionary) -> void: action_request["id"] = action_id)
	if confirm != null:
		confirm.pressed.emit()
	_check(action_request["id"] == "confirm_construction", "screen emits a semantic construction request")
	var empty_resource_view := _base_view()
	empty_resource_view["panel"] = "facility"
	empty_resource_view["facility"] = {
		"facility_id": "porcelain_plant",
		"name": "陶瓷厂",
		"copy": "持续生产陶瓷",
		"level": 1,
		"work": {},
		"kind": "resource",
		"resource_name": "陶瓷",
		"output": 0,
		"can_collect": false,
		"upgrade_cost_copy": "升级消耗：金币 40",
		"upgrade_preview": "提高产速",
		"can_upgrade": true,
	}
	factory.configure(empty_resource_view)
	await process_frame
	var empty_collect := factory.find_child("Collect_porcelain_plant", true, false) as Button
	_check(
		empty_collect != null and empty_collect.disabled and empty_collect.text == "暂无可收取",
		"zero stored output cannot advertise a guaranteed-error collection action"
	)
	(empty_resource_view["facility"] as Dictionary)["output"] = 6
	(empty_resource_view["facility"] as Dictionary)["can_collect"] = true
	factory.configure(empty_resource_view)
	await process_frame
	var ready_collect := factory.find_child("Collect_porcelain_plant", true, false) as Button
	_check(
		ready_collect != null and not ready_collect.disabled and ready_collect.text == "收取陶瓷",
		"positive stored output exposes the exact resource collection action"
	)
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
				{"facility_id": "porcelain_plant", "name": "陶瓷厂", "cost": 30, "copy": "生产陶瓷", "build_seconds": 5, "disabled": false},
				{"facility_id": "research_lab", "name": "研究所", "cost": 70, "copy": "先挑战 1-4，让首败战报定位研究所方案。", "build_seconds": 5, "disabled": true},
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

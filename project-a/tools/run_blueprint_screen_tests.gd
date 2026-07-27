extends SceneTree

const BLUEPRINT_SCENE := preload("res://game/scenes/screens/blueprint_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(844, 390)
	var host := Control.new()
	host.name = "AppShellContentHost"
	host.position = Vector2(0, 48)
	host.size = Vector2(844, 342)
	root.add_child(host)
	var screen := BLUEPRINT_SCENE.instantiate() as Control
	screen.call("configure", {
		"branch": "ordinary",
		"branch_title": "突击枝",
		"branch_summary": "突破与控场，两条独立研发路线",
		"core_status": "首败信号已解析 · 选择两条基础树枝",
		"breakthrough": {
			"claimable": true,
			"copy": "免费突破十连 · 招募券 0 · 不推进长期保底",
		},
		"results": [],
		"nodes": [
			{
				"recipe_id": "ordinary.assault",
				"display_name": "冲锋蓝图",
				"rating": "B",
				"faction": "快攻破城",
				"role_copy": "前线突破",
				"one_star_value": "重击最近守军",
				"two_star_effect": "突进顺劈多个目标",
				"three_star_effect": "高倍率冲击并震慑",
				"unlock_source": "1-2 首通或信号招募",
				"status_id": "available",
				"status_copy": "免费研发 · 仅耗时5秒 · 长期资源保持不变",
				"action_id": "start_research",
				"action_label": "免费研发冲锋蓝图 · 5秒",
				"action_name": "UnlockFoundationalBlueprint_ordinary_assault",
				"disabled": false,
			},
			{
				"recipe_id": "ordinary.sonic",
				"display_name": "音波蓝图",
				"rating": "A",
				"faction": "干扰增殖",
				"role_copy": "群体控制",
				"one_star_value": "伤害并削弱同路守军",
				"two_star_effect": "虚弱覆盖跨线目标",
				"three_star_effect": "控制并处决普通守军",
				"unlock_source": "信号招募",
				"status_id": "locked",
				"status_copy": "尚未获得该型号图纸",
				"action_id": "",
			},
		],
	})
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	await process_frame
	_check((screen.get_node("%ClaimResearchBreakthroughTen") as Button).visible, "free breakthrough CTA is visible")
	_check((screen.get_node("%ClaimResearchBreakthroughTen") as Button).has_focus(), "breakthrough CTA receives initial focus")
	_check(screen.find_children("BlueprintNode_*", "Control", true, false).size() == 2, "selected branch shows exactly two nodes")
	_check(_collect_text(screen).contains("不推进长期保底"), "breakthrough scope is explicit")
	var research_hud := screen.get_node("%BlueprintResourceContext") as Control
	_check(
		research_hud != null and not research_hud.is_visible_in_tree(),
		"research screen leaves the four persistent balances to the App Shell top bar"
	)
	_check(_collect_text(screen).contains("长期资源保持不变"), "available blueprint node repeats the zero-cost boundary beside its CTA")
	_check(_collect_text(screen).contains("两条独立研发路线"), "branch copy does not imply a false prerequisite chain")
	_check(_collect_text(screen).contains("1★ 重击最近守军"), "node explains the complete one-star role")
	_check(_collect_text(screen).contains("2★ 突进顺劈多个目标"), "node exposes the next qualitative star breakpoint")
	_check(_collect_text(screen).contains("来源：1-2 首通或信号招募"), "node exposes its acquisition route")
	var requested := {"id": "", "recipe_id": ""}
	screen.connect("action_requested", func(id: String, payload: Dictionary) -> void:
		requested["id"] = id
		requested["recipe_id"] = String(payload.get("recipe_id", ""))
	)
	var unlock := screen.find_child("UnlockFoundationalBlueprint_ordinary_assault", true, false) as Button
	var back := screen.get_node("%BlueprintBackButton") as Button
	for control_value in [
		screen.get_node("%ClaimResearchBreakthroughTen"),
		unlock,
		back,
	]:
		var control := control_value as Control
		_check(
			_within_844x390(control),
			"%s remains fully inside the App Shell 844x390 content viewport: %s" % [
				control.name,
				str(control.get_global_rect()),
			]
		)
		_check(control.focus_mode == Control.FOCUS_ALL, "%s remains keyboard/gamepad focusable" % control.name)
		control.grab_focus()
		await process_frame
		_check(control.has_focus(), "%s is reachable in the 844x390 focus chain" % control.name)
	unlock.pressed.emit()
	_check(requested["id"] == "start_research" and requested["recipe_id"] == "ordinary.assault", "research node emits stable recipe action")
	var branch := {"id": ""}
	screen.connect("branch_selected", func(id: String) -> void: branch["id"] = id)
	(screen.get_node("BlueprintTabs/BlueprintHeavyTab") as Button).pressed.emit()
	_check(branch["id"] == "heavy", "branch tab emits semantic selection")

	screen.call("configure", {
		"branch": "heavy",
		"branch_title": "重装枝",
		"core_status": "首败信号已解析",
		"breakthrough": {"claimable": false, "copy": "研究突破十连已完成 · 冲锋与装甲永久入列"},
		"results_summary": "2 名永久援军 + 8 份研究物资 · 高墙反攻条件已经凑齐",
		"reduced_motion": true,
		"results": [
			{
				"id": "armored",
				"rarity": "A",
				"kind": "hero",
				"title": "A · 装甲马桶人",
				"subtitle": "重装 · 承伤保护",
				"impact": "反攻：承伤保护队伍",
			},
			{"id": "porcelain_0", "rarity": "R", "kind": "porcelain", "title": "R · 陶瓷", "subtitle": "+80"},
		],
		"nodes": [
			{"recipe_id": "heavy.armored", "display_name": "装甲蓝图", "status_id": "unlocked", "status_copy": "已解锁 · 永久角色已入列", "action_id": ""},
			{"recipe_id": "heavy.saw", "display_name": "双锯蓝图", "status_id": "researching", "status_copy": "研发完成 · 等待领取", "action_id": "claim_research", "action_label": "领取新角色", "action_name": "ClaimFoundationalBlueprint", "disabled": false},
		],
	})
	_check(not (screen.get_node("%ClaimResearchBreakthroughTen") as Button).visible, "claimed breakthrough cannot repeat")
	_check((screen.get_node("%ResearchBreakthroughResults") as PanelContainer).visible, "ten-pull results are projected")
	_check(_collect_text(screen).contains("装甲马桶人"), "permanent reinforcement reveal is readable")
	_check(_collect_text(screen).contains("承伤保护队伍"), "reinforcement reveal explains its immediate counterplay value")
	_check(_collect_text(screen).contains("高墙反攻条件已经凑齐"), "celebration connects rewards to the overcome hurdle")
	_check(not (screen.get_node("%BlueprintTabs") as HBoxContainer).visible, "result focus mode hides unrelated research branches")
	await process_frame
	await process_frame
	await process_frame
	_check((screen.get_node("%BlueprintResultsLegionButton") as Button).has_focus(), "result focus moves to the immediate counterattack action")
	var claim := screen.find_child("ClaimFoundationalBlueprint", true, false) as Button
	claim.pressed.emit()
	_check(requested["id"] == "claim_research", "completed research emits claim action")

	screen.queue_free()
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("BLUEPRINT_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("BLUEPRINT_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _collect_text(node: Node) -> String:
	var result := ""
	if node is Label:
		result += (node as Label).text + "\n"
	for child in node.get_children():
		result += _collect_text(child)
	return result


func _within_844x390(control: Control) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	var rect := control.get_global_rect()
	return (
		rect.position.x >= -0.5
		and rect.position.y >= 47.5
		and rect.end.x <= 844.5
		and rect.end.y <= 390.5
	)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

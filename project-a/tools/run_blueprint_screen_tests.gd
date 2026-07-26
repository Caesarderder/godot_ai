extends SceneTree

const BLUEPRINT_SCENE := preload("res://game/scenes/screens/blueprint_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen := BLUEPRINT_SCENE.instantiate() as Control
	screen.call("configure", {
		"branch": "ordinary",
		"branch_title": "突击枝",
		"core_status": "首败信号已解析 · 选择两条基础树枝",
		"breakthrough": {
			"claimable": true,
			"copy": "本次免费，不消耗招募券，不推进长期保底。",
		},
		"results": [],
		"nodes": [
			{
				"recipe_id": "ordinary.assault",
				"display_name": "冲锋蓝图",
				"status_id": "available",
				"status_copy": "可研发 · 耗时45秒",
				"action_id": "start_research",
				"action_label": "开始研发冲锋蓝图",
				"action_name": "UnlockFoundationalBlueprint_ordinary_assault",
				"disabled": false,
			},
			{
				"recipe_id": "ordinary.sonic",
				"display_name": "音波蓝图",
				"status_id": "locked",
				"status_copy": "前置节点尚未开放",
				"action_id": "",
			},
		],
	})
	root.add_child(screen)
	await process_frame
	await process_frame
	await process_frame
	_check((screen.get_node("%ClaimResearchBreakthroughTen") as Button).visible, "free breakthrough CTA is visible")
	_check((screen.get_node("%ClaimResearchBreakthroughTen") as Button).has_focus(), "breakthrough CTA receives initial focus")
	_check(screen.find_children("BlueprintNode_*", "Control", true, false).size() == 2, "selected branch shows exactly two nodes")
	_check(_collect_text(screen).contains("不推进长期保底"), "breakthrough scope is explicit")
	var requested := {"id": "", "recipe_id": ""}
	screen.connect("action_requested", func(id: String, payload: Dictionary) -> void:
		requested["id"] = id
		requested["recipe_id"] = String(payload.get("recipe_id", ""))
	)
	var unlock := screen.find_child("UnlockFoundationalBlueprint_ordinary_assault", true, false) as Button
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
		"results": [
			{"rarity": "A", "copy": "A\n装甲马桶人\n永久援军"},
			{"rarity": "R", "copy": "R\n陶瓷\n+80"},
		],
		"nodes": [
			{"recipe_id": "heavy.armored", "display_name": "装甲蓝图", "status_id": "unlocked", "status_copy": "已解锁 · 永久角色已入列", "action_id": ""},
			{"recipe_id": "heavy.saw", "display_name": "双锯蓝图", "status_id": "researching", "status_copy": "研发完成 · 等待领取", "action_id": "claim_research", "action_label": "领取新角色", "action_name": "ClaimFoundationalBlueprint", "disabled": false},
		],
	})
	_check(not (screen.get_node("%ClaimResearchBreakthroughTen") as Button).visible, "claimed breakthrough cannot repeat")
	_check((screen.get_node("%ResearchBreakthroughResults") as PanelContainer).visible, "ten-pull results are projected")
	_check(_collect_text(screen).contains("装甲马桶人"), "permanent reinforcement reveal is readable")
	var claim := screen.find_child("ClaimFoundationalBlueprint", true, false) as Button
	claim.pressed.emit()
	_check(requested["id"] == "claim_research", "completed research emits claim action")

	screen.queue_free()
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


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

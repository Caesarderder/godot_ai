extends SceneTree

const GOALS_SCENE := preload("res://game/scenes/screens/goals_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var goals: Control = GOALS_SCENE.instantiate()
	root.add_child(goals)
	await process_frame
	goals.call("configure", _action_view())
	await process_frame
	_check(goals.find_child("GoalHierarchyPanel", true, false) != null, "action tab owns one macro-to-micro chain")
	_check(_tree_has_text(goals, "大目标 · 摧毁灰镜核心"), "macro goal remains visible")
	_check(_tree_has_text(goals, "中目标 · 行动三：撞击高墙"), "medium operation remains visible")
	_check(_tree_has_text(goals, "小目标 · 完成 1-4 首次挑战"), "small executable goal remains visible")
	_check(_tree_has_text(goals, "大坎 · 1-4 灰镜高墙"), "hurdle scale and identity are explicit")
	_check(_tree_has_text(goals, "过坎：完成首战后用保障币建研究所"), "recovery path is explicit")
	var action_request := {"id": "", "stage_id": ""}
	goals.connect("action_requested", func(action_id: String, payload: Dictionary) -> void:
		action_request["id"] = action_id
		action_request["stage_id"] = String(payload.get("stage_id", ""))
	)
	var cta := goals.find_child("GoalHierarchyPrimaryCTA", true, false) as Button
	if cta != null:
		cta.pressed.emit()
	_check(action_request["id"] == "follow_task", "primary CTA emits a semantic follow request")
	_check(action_request["stage_id"] == "stage_1_4", "primary CTA preserves the exact stage target")
	var locked_welfare := goals.find_child("NewPlayerWelfareClaimButton", true, false) as Button
	_check(locked_welfare != null and locked_welfare.disabled, "welfare card is visible but locked before 1-5")
	var welfare_view := _action_view()
	welfare_view["new_player_welfare"] = {
		"unlocked": true,
		"claimable": true,
		"claimed": false,
		"star_core_count": 0,
		"logistics_case_count": 0,
	}
	goals.call("configure", welfare_view)
	await process_frame
	var welfare_claim := goals.find_child("NewPlayerWelfareClaimButton", true, false) as Button
	_check(welfare_claim != null and not welfare_claim.disabled, "post-chapter welfare card becomes claimable")
	if welfare_claim != null:
		welfare_claim.pressed.emit()
	_check(action_request["id"] == "claim_new_player_welfare", "welfare claim emits its semantic command request")
	welfare_view["new_player_welfare"] = {
		"unlocked": true,
		"claimable": false,
		"claimed": true,
		"case_openable": true,
		"case_opened": false,
		"star_core_count": 1,
		"logistics_case_count": 1,
	}
	goals.call("configure", welfare_view)
	await process_frame
	var open_case := goals.find_child("SmuggledLogisticsCaseButton", true, false) as Button
	_check(open_case != null, "claimed welfare card exposes the unopened logistics case")
	if open_case != null:
		open_case.pressed.emit()
	_check(action_request["id"] == "open_smuggled_logistics_case", "case button emits its semantic command request")
	welfare_view["new_player_welfare"] = {
		"unlocked": true,
		"claimable": false,
		"claimed": true,
		"case_openable": false,
		"case_opened": true,
		"star_core_count": 1,
		"logistics_case_count": 0,
	}
	goals.call("configure", welfare_view)
	await process_frame
	_check(_tree_has_text(goals, "走私后勤箱已开启"), "welfare card renders the opened-case state")

	var tab_request := {"id": ""}
	goals.connect("tab_selected", func(tab_id: String) -> void: tab_request["id"] = tab_id)
	var pass_tab := goals.find_child("MetaGoalsPassTab", true, false) as Button
	if pass_tab != null:
		pass_tab.pressed.emit()
	_check(tab_request["id"] == "pass", "authored tabs emit semantic navigation")

	goals.call("configure", _pass_view())
	await process_frame
	var pass_cards: Array[Node] = []
	_collect_prefix(goals, "MetaPassLevel_", pass_cards)
	_check(pass_cards.size() == 30, "pass tab renders the full thirty-level track")
	_check(_tree_has_text(goals, "一键领取 3 项奖励"), "pass tab exposes batch claim")
	var commander := goals.find_child("CommanderProgressPanel", true, false)
	_check(commander != null, "long-term tabs retain commander progression")
	goals.queue_free()
	await process_frame
	if failures.is_empty():
		print("GOALS_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("GOALS_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _action_view() -> Dictionary:
	return {
		"tab": "action",
		"hierarchy": {
			"macro": "摧毁灰镜核心，完成第一章",
			"medium": "行动三：撞击高墙",
			"small": "完成 1-4 首次挑战并寻找失败原因",
			"hurdle": {
				"scale": "大坎",
				"title": "1-4 灰镜高墙",
				"reason": "职责覆盖不足",
				"recovery": "完成首战后用保障币建研究所，启动免费突破十连。",
			},
			"finished": false,
			"cta_label": "挑战 1-4 高墙",
			"target": "expedition",
			"stage_id": "stage_1_4",
		},
		"campaign": {"cleared": 3, "chapters_copy": "第1章 3/5 · 第2章 0/5"},
		"new_player_welfare": {
			"unlocked": false,
			"claimable": false,
			"claimed": false,
		},
		"missions_unlocked": false,
		"mission_lock": {
			"title": "行动任务", "level": 1, "required_level": 2,
			"stage_copy": "通关 1-1", "stage_complete": true,
		},
	}


func _pass_view() -> Dictionary:
	var levels: Array[Dictionary] = []
	for level in range(1, 31):
		levels.append({
			"level": level,
			"claimed": false,
			"claimable": level <= 3,
			"reward": {"toilet_coins": 30},
		})
	return {
		"tab": "pass",
		"commander": {"level": 5, "xp": 300, "next_xp": 450, "claimable": 0},
		"pass_unlocked": true,
		"pass": {"merit": 350, "reached": 3, "claimable": 3, "levels": levels},
	}


func _collect_prefix(node: Node, prefix: String, output: Array[Node]) -> void:
	if String(node.name).begins_with(prefix):
		output.append(node)
	for child in node.get_children():
		_collect_prefix(child, prefix, output)


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

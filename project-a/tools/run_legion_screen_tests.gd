extends SceneTree

const LEGION_SCENE := preload("res://game/scenes/screens/legion_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var legion := LEGION_SCENE.instantiate() as LegionScreen
	root.add_child(legion)
	await process_frame
	legion.configure({
		"tab": "formation",
		"formation_edit_slot": "troop_1",
		"first_formation": {
			"active": true,
			"deployed": 0,
			"target": 2,
			"instruction": "先让装甲进入前排承伤",
		},
		"counterattack": {"visible": false},
		"team_power": 5700,
		"target_stage_name": "1-5 灰镜核心巨炮",
		"recommended_power": 6500,
		"formation": [
			{"slot_id": "commander", "display_name": "G-Man 指挥官", "role": "统帅 · 稳定输出"},
			{"slot_id": "troop_1", "display_name": "冲锋马桶人", "role": "突击 · 快速压制"},
		],
		"candidates": [
			{
				"hero_id": "hero_assault",
				"display_name": "冲锋马桶人",
				"role": "突击 · 快速压制",
				"power": 1900,
				"power_delta": 0,
				"current": true,
				"recommended": false,
			},
			{
				"hero_id": "hero_armored",
				"display_name": "装甲马桶人",
				"role": "重装 · 承伤保护",
				"power": 2050,
				"power_delta": 150,
				"current": false,
				"recommended": true,
			},
		],
		"roster": [],
	})
	await process_frame
	_check(not _tree_has_text(legion, "战力差 +800"), "focused first formation defers generalized power analysis")
	_check(_tree_has_text(legion, "重装 · 承伤保护"), "candidate comparison exposes gameplay role")
	_check(_tree_has_text(legion, "军团变化 +150"), "candidate comparison exposes formation impact")
	_check(_tree_has_text(legion, "高墙反攻编队 0/2"), "first formation exposes visible two-reinforcement progress")
	_check(_tree_has_text(legion, "先让装甲进入前排承伤"), "first formation explains the recommended responsibility")
	_check(_tree_has_text(legion, "推荐下一步"), "recommended candidate is explicit without disabling alternatives")
	_check(not (legion.get_node("TaskTabs") as HBoxContainer).visible, "first formation hides unrelated recruit and roster tabs")
	var candidate := legion.find_child("FormationCandidate_hero_armored", true, false) as Button
	_check(candidate != null and not candidate.disabled, "a replacement candidate is actionable")
	var request := {"action": "", "hero_id": "", "stage_id": ""}
	legion.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		request["action"] = action_id
		request["hero_id"] = String(payload.get("hero_id", ""))
		request["stage_id"] = String(payload.get("stage_id", ""))
	)
	if candidate != null:
		candidate.pressed.emit()
	_check(request["action"] == "assign_slot" and request["hero_id"] == "hero_armored", "screen emits a semantic assignment request")
	legion.configure({
		"tab": "formation",
		"formation_edit_slot": "troop_2",
		"first_formation": {"active": false},
		"counterattack": {
			"visible": true,
			"stage_id": "stage_1_4",
			"label": "编队完成 · 立即反攻 1-4",
		},
		"team_power": 5700,
		"target_stage_name": "1-4 高墙防线",
		"recommended_power": 5700,
		"formation": [],
		"candidates": [],
		"roster": [],
	})
	await process_frame
	var counterattack := legion.find_child("FormationCounterattackButton", true, false) as Button
	_check(counterattack != null, "completed first formation exposes one direct counterattack action")
	if counterattack != null:
		counterattack.pressed.emit()
	_check(request["action"] == "counterattack" and request["stage_id"] == "stage_1_4", "counterattack action routes to the exact hurdle")
	legion.configure({
		"tab": "recruit",
		"recruitment_unlocked": false,
		"recruitment_progress": "指挥官 Lv2/4 · 关卡 1-5 未通关",
	})
	await process_frame
	_check(_tree_has_text(legion, "随机招募不会卡住首章"), "locked recruitment protects deterministic onboarding")
	legion.queue_free()
	await process_frame
	if failures.is_empty():
		print("LEGION_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LEGION_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


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

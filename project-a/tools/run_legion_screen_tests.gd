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
			},
			{
				"hero_id": "hero_armored",
				"display_name": "装甲马桶人",
				"role": "重装 · 承伤保护",
				"power": 2050,
				"power_delta": 150,
				"current": false,
			},
		],
		"roster": [],
	})
	await process_frame
	_check(_tree_has_text(legion, "军团战力 5700"), "formation projects current team power")
	_check(_tree_has_text(legion, "战力差 +800"), "formation explains the next-stage gap")
	_check(_tree_has_text(legion, "重装 · 承伤保护"), "candidate comparison exposes gameplay role")
	_check(_tree_has_text(legion, "军团变化 +150"), "candidate comparison exposes formation impact")
	var candidate := legion.find_child("FormationCandidate_hero_armored", true, false) as Button
	_check(candidate != null and not candidate.disabled, "a replacement candidate is actionable")
	var request := {"action": "", "hero_id": ""}
	legion.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		request["action"] = action_id
		request["hero_id"] = String(payload.get("hero_id", ""))
	)
	if candidate != null:
		candidate.pressed.emit()
	_check(request["action"] == "assign_slot" and request["hero_id"] == "hero_armored", "screen emits a semantic assignment request")
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

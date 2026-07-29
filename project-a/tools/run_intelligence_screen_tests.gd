extends SceneTree

const INTELLIGENCE_SCENE := preload("res://game/scenes/screens/intelligence_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen := INTELLIGENCE_SCENE.instantiate() as Control
	screen.call("configure", {
		"stage_id": "stage_1_4",
		"report": {
			"stage_name": "1-4 E10 · 监控人增援",
			"cp_ready": 860,
			"recommended_power": 1100,
			"capability_ratio": 0.78,
			"risk_id": "challenge",
			"risk_label": "高风险",
			"risk_detail": "单人火力无法穿透装甲线；先补充永久援军。",
			"ready_count": 1,
			"formation_size": 6,
			"weakest_resource_label": "机械零件",
			"weakest_resource_percent": 24,
			"next_action": {
				"id": "upgrade",
				"title": "先培养军团",
				"detail": "把确定性资源投入冲锋或装甲路线。",
			},
		},
	})
	root.add_child(screen)
	await process_frame
	await process_frame
	await process_frame
	var all_text := _collect_text(screen)
	_check(all_text.contains("当前编队战力  860"), "canonical formation power is projected")
	_check(all_text.contains("关卡推荐  1100"), "stage recommendation is projected")
	_check(all_text.contains("能力比 78%"), "stage-relative capability is projected")
	_check(all_text.contains("战后无需维修"), "lossless battle rule is visible")
	_check(all_text.contains("机械零件 24%"), "weakest logistics resource is projected")
	var bar := screen.get_node("%IntelligenceCapabilityBar") as ProgressBar
	_check(is_equal_approx(bar.value, 78.0), "capability bar matches the report ratio")
	var action := screen.get_node("%IntelligenceActionButton") as Button
	_check(action.text == "进入军团培养", "upgrade recommendation owns the correct CTA")
	_check(action.has_focus(), "recommended action receives initial focus")
	var requested := {"id": "", "stage_id": ""}
	screen.connect("action_requested", func(id: String, payload: Dictionary) -> void:
		requested["id"] = id
		requested["stage_id"] = String(payload.get("stage_id", ""))
	)
	action.pressed.emit()
	_check(requested["id"] == "upgrade" and requested["stage_id"] == "stage_1_4", "CTA emits semantic action and stable stage id")

	screen.call("configure", {
		"stage_id": "stage_1_1",
		"report": {
			"stage_name": "1-1 无防备城市",
			"cp_ready": 860,
			"recommended_power": 700,
			"capability_ratio": 1.23,
			"risk_id": "advantage",
			"risk_label": "优势",
			"risk_detail": "当前阵容可稳定推进。",
			"ready_count": 1,
			"formation_size": 6,
			"weakest_resource_label": "陶瓷",
			"weakest_resource_percent": 65,
			"next_action": {"id": "attack", "title": "立即推进", "detail": "夺回第一座城市。"},
		},
	})
	_check(action.text == "立即出击", "attack recommendation updates the CTA in place")
	action.pressed.emit()
	_check(requested["id"] == "attack" and requested["stage_id"] == "stage_1_1", "attack CTA emits the updated stage")

	screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("INTELLIGENCE_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("INTELLIGENCE_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
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

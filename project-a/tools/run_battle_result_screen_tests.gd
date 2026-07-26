extends SceneTree

const RESULT_SCENE := preload("res://game/scenes/screens/battle_result_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var result_screen: Control = RESULT_SCENE.instantiate()
	root.add_child(result_screen)
	result_screen.call("configure", {
		"outcome_banner": "胜利 · 工厂与军团获得成长",
		"outcome_color": "green",
		"mission_progress": "行动五完成 · 奖励已自动入账 → 新目标：行动六：工业备战",
		"hurdle_proof": "高墙复盘 · 单人首战失败 → 三人反攻成功 · 援军分担 68% 承伤、贡献 52% 输出",
		"primary_label": "选择工业支援",
		"primary_action": "factory",
		"primary_payload": {},
	})
	await process_frame
	var primary := result_screen.find_child("PrimaryAction", true, false) as Button
	var fallback_factory := result_screen.find_child("FactoryAction", true, false) as Button
	_check(primary != null and primary.text == "选择工业支援", "result promotes the next onboarding action")
	_check(primary != null and primary.visible, "next onboarding action remains visible")
	_check(fallback_factory != null and not fallback_factory.visible, "generic factory fallback is hidden when factory is primary")
	_check(_tree_has_text(result_screen, "单人首战失败 → 三人反攻成功"), "result presents the hurdle before-after proof")
	_check(_tree_has_text(result_screen, "68% 承伤") and _tree_has_text(result_screen, "52% 输出"), "result projects real reinforcement contribution channels")
	var requested := {"id": ""}
	result_screen.connect("action_requested", func(action_id: String, _payload: Dictionary) -> void:
		requested["id"] = action_id
	)
	if primary != null:
		primary.pressed.emit()
	_check(requested["id"] == "factory", "industrial onboarding CTA routes to the factory")
	result_screen.queue_free()
	await process_frame
	if failures.is_empty():
		print("BATTLE_RESULT_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("BATTLE_RESULT_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment):
		return true
	for child in node.get_children():
		if _tree_has_text(child, fragment):
			return true
	return false

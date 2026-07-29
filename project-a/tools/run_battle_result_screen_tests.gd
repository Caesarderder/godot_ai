extends SceneTree

const RESULT_SCENE := preload("res://game/scenes/screens/battle_result_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(844, 390)
	var result_screen: Control = RESULT_SCENE.instantiate()
	root.add_child(result_screen)
	result_screen.size = Vector2(844, 390)
	result_screen.call("configure", {
		"outcome_banner": "胜利 · 工厂与军团获得成长",
		"outcome_color": "green",
		"reward_headline": "金币 +80",
		"hero_experience": "参战经验 · 3名主力各 +30 经验 · 阵营核心 火箭马桶人 经验 60/100，距3级还差 40",
		"mission_progress": "行动五完成 · 奖励已自动入账 → 新目标：行动六：工业备战",
		"unlocked_hero": "新成员已入列",
		"materials": "工业材料 +12",
		"breakthrough": "研究所建造资格已取得",
		"combat_summary": "摧毁 4 座设施 · 击败 8 名守军",
		"contribution": "核心贡献 · 前排承伤 68%",
		"hurdle_proof": "高墙复盘 · 单人首战失败 → 三人反攻成功 · 援军分担 68% 承伤、贡献 52% 输出",
		"debrief": "战斗复盘 · 护盾挡下巨炮后完成反击",
		"growth": "下一步成长 · 选择工业支援",
		"safety": "全员无损返回",
		"qualification": "新战线已经开放 · 先查看敌方结构，再选择下一次出击路线",
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
	_check(
		result_screen.base_action.text.contains("稍后继续"),
		"result preserves a clearly secondary safe exit without presenting another growth recommendation"
	)
	_check(_tree_has_text(result_screen, "单人首战失败 → 三人反攻成功"), "result presents the hurdle before-after proof")
	_check(_tree_has_text(result_screen, "68% 承伤") and _tree_has_text(result_screen, "52% 输出"), "result projects real reinforcement contribution channels")
	_check(
		_tree_has_text(result_screen, "3名主力各 +30 经验")
			and _tree_has_text(result_screen, "距3级还差 40"),
		"result makes hidden battle experience and the faction core's next level visible"
	)
	_check(
		_tree_has_text(result_screen, "金币 +80")
			and not _tree_has_text(result_screen, "军团数据 +0"),
		"result celebrates only resources that actually increased"
	)
	_check(
		result_screen.combat_summary.visible
			and result_screen.combat_summary.text.contains("摧毁 4 座设施")
			and result_screen.combat_summary.text.contains("前排承伤 68%"),
		"all-fields result keeps combat facts and contribution together in the visible causal summary"
	)
	_check(
		result_screen.hurdle_proof.visible
			and result_screen.debrief.visible
			and result_screen.hurdle_proof.text.contains("单人首战失败 → 三人反攻成功")
			and result_screen.debrief.text.contains("护盾挡下巨炮后完成反击"),
		"all-fields result keeps both hurdle proof and battle debrief visible"
	)
	for merged_fragment in [
		"3名主力各 +30 经验",
		"行动五完成",
		"新成员已入列",
		"工业材料 +12",
		"研究所建造资格已取得",
	]:
		_check(
			result_screen.mission_progress.visible
				and result_screen.mission_progress.text.contains(merged_fragment),
			"all-fields result preserves merged progression fact: %s" % merged_fragment
		)
	for causal_row in [
		result_screen.hurdle_proof,
		result_screen.debrief,
		result_screen.combat_summary,
	]:
		var row := causal_row as Control
		_check(
			row.is_visible_in_tree()
				and row.get_global_rect().end.y <= result_screen.get_global_rect().end.y + 0.5,
			"main causal row remains readable inside 844x390: %s" % row.name
		)
		_check(
			row.get_global_rect().end.x <= result_screen.get_global_rect().end.x + 0.5,
			"main causal row remains horizontally inside 844x390: %s" % row.name
		)
	var columns := result_screen.get_node("Columns") as Control
	var next_panel := result_screen.get_node("Columns/NextPanel") as Control
	_check(
		columns.get_global_rect().end.x <= result_screen.get_global_rect().end.x + 0.5
			and next_panel.get_global_rect().end.x <= result_screen.get_global_rect().end.x + 0.5,
		"result columns keep the next-action panel inside the 844px right edge"
	)
	for action in [primary, result_screen.base_action]:
		var visible_action := action as Button
		_check(
			visible_action.is_visible_in_tree()
				and visible_action.get_global_rect().end.x
					<= result_screen.get_global_rect().end.x + 0.5
				and visible_action.get_global_rect().end.y
					<= result_screen.get_global_rect().end.y + 0.5,
			"right-column action remains fully visible inside 844x390: %s" % visible_action.name
		)
	var requested := {"id": ""}
	result_screen.connect("action_requested", func(action_id: String, _payload: Dictionary) -> void:
		requested["id"] = action_id
	)
	if primary != null:
		primary.pressed.emit()
	_check(requested["id"] == "factory", "industrial onboarding CTA routes to the factory")
	result_screen.configure({
		"outcome_banner": "失败 · 可立即调整后再战",
		"reward_headline": "",
		"primary_label": "掌握巨炮时机 · 再战 1-5",
		"primary_action": "next_stage",
		"primary_payload": {"stage_id": "stage_1_5"},
	})
	await process_frame
	_check(
		not result_screen.factory_action.visible,
		"result hides unrelated factory navigation by default during a specific recovery"
	)
	_check(
		not result_screen.reward_headline.visible,
		"a zero-resource result removes the empty reward headline instead of showing +0"
	)
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

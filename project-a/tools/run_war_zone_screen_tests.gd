extends SceneTree

const WAR_ZONE_SCENE := preload("res://game/scenes/screens/war_zone_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in [Vector2(844, 342), Vector2(568, 272)]:
		await _verify_layout(viewport_size)
	if failures.is_empty():
		print("WAR_ZONE_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("WAR_ZONE_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _verify_layout(viewport_size: Vector2) -> void:
	var host := Control.new()
	host.size = viewport_size
	root.add_child(host)
	var war_zone := WAR_ZONE_SCENE.instantiate() as Control
	host.add_child(war_zone)
	war_zone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_check(
		war_zone.has_method("configure"),
		"%s loads the shipping WarZoneScreen script" % viewport_size
	)
	if not war_zone.has_method("configure"):
		host.queue_free()
		await process_frame
		return
	var stages: Array[Dictionary] = []
	for stage_number in range(1, 13):
		stages.append({
			"stage_id": "stage_1_%d" % stage_number,
			"display_name": "第%d前线" % stage_number,
			"status": "已夺回" if stage_number < 2 else ("前线" if stage_number < 4 else "信号中断"),
			"unlocked": stage_number < 4,
		})
	war_zone.configure(
		1,
		1,
		"stage_1_2",
		stages,
		{
			"display_name": "1-1 E07 · 监控人登场",
			"threat_summary": "前哨守军尚未完成集结。",
			"counter_hint": "维持火力并观察推进。",
		},
		{
			"cp_ready": 1711,
			"recommended_power": 1650,
			"capability_ratio": 1.04,
			"risk_id": "target",
			"risk_label": "目标区间",
			"next_action": {"id": "attack", "title": "立即推进"},
		},
		true,
		false,
		"低",
		viewport_size.x < 650.0
	)
	await process_frame
	await process_frame
	await process_frame
	var chapter_nav := war_zone.get_node("%ChapterNav") as Control
	var detail := war_zone.get_node("%StageDetailHost") as Control
	var attack := war_zone.find_child("AttackButton", true, false) as Button
	_check(_inside(chapter_nav, host), "%s chapter navigation fits the screen" % viewport_size)
	_check(_inside(detail, host), "%s selected-stage briefing fits the screen" % viewport_size)
	_check(
		attack != null and attack.visible and _inside(attack, host)
			and attack.get_global_rect().size.y >= 48.0,
		"%s keeps the single primary attack action visible and touch-sized" % viewport_size
	)
	_check(
		attack != null
			and not attack.text.is_empty()
			and attack.get_theme_constant("icon_max_width") <= 26
			and attack.size.x >= attack.get_minimum_size().x,
		"%s budgets the raster action icon without clipping the CTA label" % viewport_size
	)
	_check(
		war_zone.find_child("StageNode_stage_1_1", true, false) != null,
		"%s exposes the selected world node" % viewport_size
	)
	var stage_strip := war_zone.get_node("%StageNodeStrip") as Control
	var stage_nodes := _children_with_prefix(stage_strip, "StageNode_")
	var location_nodes := _children_with_prefix(stage_strip, "StageLocation_")
	_check(
		stage_nodes.size() == 5,
		"%s keeps one five-node frontline window instead of a chapter-wide button matrix" % viewport_size
	)
	_check(
		war_zone.get_node_or_null("StageScroll") == null,
		"%s places stage controls on the world instead of a persistent UI strip" % viewport_size
	)
	for stage_node in stage_nodes:
		var stage_control := stage_node as Control
		_check(
			not stage_control.get_global_rect().intersects(detail.get_global_rect()),
			"%s keeps world node %s %s clear of briefing %s" % [
				viewport_size,
				stage_control.name,
				stage_control.get_global_rect(),
				detail.get_global_rect(),
			]
		)
	_check(
		location_nodes.size() == 5,
		"%s gives every world node a visible location identity" % viewport_size
	)
	for location_node in location_nodes:
		var location := location_node as Control
		_check(
			not location.get_global_rect().intersects(detail.get_global_rect()),
			"%s keeps location %s %s clear of briefing %s" % [
				viewport_size,
				location.name,
				location.get_global_rect(),
				detail.get_global_rect(),
				]
			)
	for stage_node in stage_nodes:
		var icon_node := stage_node as Button
		_check(
			icon_node.icon != null
				and not icon_node.text.contains("◇")
				and not icon_node.text.contains("△")
				and not icon_node.text.contains("?")
				and not icon_node.text.contains("✓"),
			"%s stage %s uses a raster state icon instead of Unicode status glyphs" % [viewport_size, icon_node.name]
		)
	var selected_by_gesture := {"stage_id": ""}
	war_zone.stage_selected.connect(func(stage_id: String) -> void: selected_by_gesture["stage_id"] = stage_id)
	var map_position := Vector2(viewport_size.x * 0.42, viewport_size.y * 0.48)
	var touch_start := InputEventScreenTouch.new()
	touch_start.index = 0
	touch_start.position = map_position
	touch_start.pressed = true
	war_zone.call("_handle_map_input", touch_start)
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 0
	touch_drag.position = map_position - Vector2(70, 0)
	touch_drag.relative = Vector2(-70, 0)
	_check(
		bool(war_zone.call("_handle_map_input", touch_drag))
			and selected_by_gesture["stage_id"] == "stage_1_3",
		"%s leftward touch drag selects the next reachable world landmark" % viewport_size
	)
	selected_by_gesture["stage_id"] = ""
	var wheel_up := InputEventMouseButton.new()
	wheel_up.position = map_position
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	_check(
		bool(war_zone.call("_handle_map_input", wheel_up))
			and selected_by_gesture["stage_id"] == "stage_1_1",
		"%s desktop wheel traverses to the previous reachable world landmark" % viewport_size
	)
	selected_by_gesture["stage_id"] = ""
	var locked_probe := InputEventMouseButton.new()
	locked_probe.position = map_position
	locked_probe.button_index = MOUSE_BUTTON_WHEEL_DOWN
	locked_probe.pressed = true
	war_zone.configure(
		1, 1, "stage_1_3", stages, {}, {}, true, false, "高", viewport_size.x < 650.0
	)
	await process_frame
	_check(
		not bool(war_zone.call("_handle_map_input", locked_probe))
			and selected_by_gesture["stage_id"].is_empty(),
		"%s gesture traversal cannot select the locked stage beyond the frontline" % viewport_size
	)
	var boss_stages := stages.duplicate(true)
	(boss_stages[4] as Dictionary)["unlocked"] = true
	war_zone.configure(
		1,
		1,
		"stage_1_5",
		boss_stages,
		{
			"display_name": "1-5 E11 · 飞行马桶交战",
			"threat_summary": "飞行马桶加入交战，优先处理炮台。",
			"counter_hint": "升级两名援军形成快攻或守势解法。",
		},
		{
			"cp_ready": 3792,
			"recommended_power": 5400,
			"capability_ratio": 0.70,
			"risk_id": "extreme",
			"risk_label": "极高风险",
			"next_action": {"id": "upgrade", "title": "先培养军团"},
		},
		true,
		false,
		"高",
		viewport_size.x < 650.0
	)
	await process_frame
	await process_frame
	await process_frame
	detail = war_zone.get_node("%StageDetailHost") as Control
	var boss_card := detail.get_child(0) as Control
	var boss_growth := boss_card.find_child("GrowthButton", true, false) as Button
	var boss_attack := boss_card.find_child("AttackButton", true, false) as Button
	_check(
		detail.size.y <= 86.0,
		"%s keeps the boss briefing as a compact map card" % viewport_size
	)
	_check(
		boss_growth != null
			and boss_growth.is_visible_in_tree()
			and boss_growth.size.y >= 48.0
			and boss_growth.icon != null
			and boss_attack != null
			and boss_attack.is_visible_in_tree()
			and boss_attack.size.y >= 48.0
			and boss_attack.icon != null,
		"%s keeps icon-led preparation and probe actions touch-ready" % viewport_size
	)
	_check(
		boss_card.tooltip_text.contains("抢拆炮台")
			and boss_card.tooltip_text.contains("格挡反震"),
		"%s preserves both full boss recovery routes in progressive disclosure" % viewport_size
	)
	host.queue_free()
	await process_frame


func _children_with_prefix(parent: Node, prefix: String) -> Array[Node]:
	var matches: Array[Node] = []
	for child in parent.get_children():
		if String(child.name).begins_with(prefix):
			matches.append(child)
	return matches


func _inside(control: Control, host: Control) -> bool:
	if control == null:
		return false
	var bounds := host.get_global_rect()
	var rect := control.get_global_rect()
	return (
		rect.position.x >= bounds.position.x - 0.5
		and rect.position.y >= bounds.position.y - 0.5
		and rect.end.x <= bounds.end.x + 0.5
		and rect.end.y <= bounds.end.y + 0.5
	)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

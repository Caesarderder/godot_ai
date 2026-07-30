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
	var stages: Array[Dictionary] = []
	for stage_number in range(1, 13):
		stages.append({
			"stage_id": "stage_1_%d" % stage_number,
			"display_name": "第%d前线" % stage_number,
			"status": "前线" if stage_number == 1 else "信号中断",
			"unlocked": stage_number == 1,
		})
	war_zone.configure(
		1,
		1,
		"stage_1_1",
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
		"低"
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
		war_zone.find_child("StageNode_stage_1_1", true, false) != null,
		"%s exposes the selected world node" % viewport_size
	)
	var stage_strip := war_zone.get_node("%StageNodeStrip") as HBoxContainer
	_check(
		stage_strip.get_child_count() == 5,
		"%s keeps one five-node frontline window instead of a chapter-wide button matrix" % viewport_size
	)
	host.queue_free()
	await process_frame


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

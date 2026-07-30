extends SceneTree

const HUD_SCENE := preload("res://game/scenes/screens/battle_hud_screen.tscn")

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_layout(Vector2(844, 390), false, 2)
	await _verify_layout(Vector2(568, 320), true, 2)
	await _verify_layout(Vector2(568, 320), true, 6)
	if _failures > 0:
		push_error("BATTLE_HUD_LAYOUT_TESTS_FAIL: %d issue(s)" % _failures)
		quit(1)
		return
	print("BATTLE_HUD_LAYOUT_TESTS_OK")
	quit(0)


func _verify_layout(viewport_size: Vector2, compact: bool, unit_count: int) -> void:
	var host := Control.new()
	host.size = viewport_size
	root.add_child(host)
	var hud := HUD_SCENE.instantiate() as BattleHudScreen
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(hud)
	await process_frame
	hud.configure(_snapshots(unit_count), false, false, false, compact)
	hud.apply_snapshot(_battle_snapshot())
	await process_frame
	await process_frame
	var tactical_bar := hud.get_node("TacticalBar") as PanelContainer
	var tactical_style := tactical_bar.get_theme_stylebox("panel") as StyleBoxFlat
	var bottom := hud.get_node("%BattleBottomHud") as PanelContainer
	var pause := hud.get_node("%BattlePauseButton") as Button
	var mode := hud.get_node("%BattleSkillModeButton") as Button
	var retreat := hud.get_node("%BattleRetreatButton") as Button
	var status := hud.get_node("%BattleTacticalStatus") as Label
	_check(
		tactical_style != null and tactical_style.bg_color.a <= 0.01,
		"%s top controls float over the battlefield instead of drawing a full-width slab" % viewport_size
	)
	_check(
		bottom.size.x <= viewport_size.x * 0.96
			and (unit_count > 2 or bottom.size.x <= viewport_size.x * 0.46),
		"%s bottom HUD shrink-wraps %d deployed units: %s" % [
			viewport_size,
			unit_count,
			bottom.size,
		]
	)
	_check(
		bottom.get_global_rect().position.x >= 0.0
			and bottom.get_global_rect().end.x <= viewport_size.x,
		"%s bottom HUD remains inside the touch canvas" % viewport_size
	)
	_check(
		pause.custom_minimum_size.y >= 48.0
			and mode.custom_minimum_size.y >= 48.0
			and pause.is_visible_in_tree()
			and mode.is_visible_in_tree(),
		"%s keeps pause and skill mode as touch-sized edge actions" % viewport_size
	)
	_check(
		not retreat.is_visible_in_tree(),
		"%s removes destructive retreat from the live battlefield and leaves it in pause" % viewport_size
	)
	_check(
		mode.text == "自动·开",
		"%s encodes the active automatic mode with explicit text" % viewport_size
	)
	hud.set_manual_skills(true)
	_check(
		mode.text == "自动·关",
		"%s encodes the manual mode as automatic off instead of an ambiguous action label" % viewport_size
	)
	hud.set_manual_skills(false)
	_check(
		status.text.contains("阶段") and not status.text.contains("..."),
		"%s status pill preserves complete stage context without authored ellipsis" % viewport_size
	)
	host.queue_free()
	await process_frame


func _snapshots(count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(count):
		result.append({
			"hero_id": "hero_%d" % index,
			"display_name": "主力%d · 编队呼号" % (index + 1),
			"skill_display_name": "主动技能",
			"skill_timing": "能量达到 100% 后释放",
			"max_hp": 200,
			"auto_skill": true,
		})
	return result


func _battle_snapshot() -> Dictionary:
	var units: Array[Dictionary] = []
	for index in range(6):
		units.append({
			"unit_id": "hero_%d" % index,
			"alive": true,
			"hp": 180,
			"max_hp": 200,
			"energy": 40,
			"temporary": false,
		})
	return {
		"stage_index": 0,
		"stage_count": 3,
		"stage_name": "突破解围",
		"road_progress": 120,
		"warnings": [],
		"units": units,
		"structures": [{
			"stage": 0,
			"alive": true,
			"kind": "barricade",
			"display_name": "外围路障",
			"hp": 100,
			"max_hp": 100,
		}],
	}


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)

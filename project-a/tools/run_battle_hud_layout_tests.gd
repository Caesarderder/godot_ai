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
	var portraits := hud.find_children("BattleUnitPortrait_*", "TextureRect", true, false)
	var cards := hud.find_children("BattleUnitCard_*", "PanelContainer", true, false)
	var name_labels := hud.find_children("BattleUnitNameLabel", "Label", true, false)
	var portraits_valid := portraits.size() == unit_count
	for value in portraits:
		var portrait := value as TextureRect
		portraits_valid = portraits_valid and portrait.texture != null
		portraits_valid = portraits_valid and portrait.custom_minimum_size.x >= (30.0 if unit_count > 4 else 38.0)
		portraits_valid = portraits_valid and portrait.size_flags_vertical == Control.SIZE_SHRINK_CENTER
	var cards_touch_sized := cards.size() == unit_count
	for value in cards:
		cards_touch_sized = cards_touch_sized and (value as Control).size.y >= 44.0
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
		portraits_valid,
		"%s renders one repository-owned raster portrait for each of %d deployed units" % [viewport_size, unit_count]
	)
	_check(
		cards_touch_sized,
		"%s keeps every portrait card as a whole touch-sized skill target" % viewport_size
	)
	_check(
		hud.find_children("Battle生命Bar", "ProgressBar", true, false).size() == unit_count
			and hud.find_children("Battle技能充能Bar", "ProgressBar", true, false).size() == unit_count,
		"%s replaces visible HP/EN table rows with paired health and charge bars" % viewport_size
	)
	_check(
		(not compact and name_labels.all(func(value: Node) -> bool: return (value as Control).visible))
			or (compact and name_labels.all(func(value: Node) -> bool: return not (value as Control).visible)),
		"%s keeps names on the standard HUD but uses portrait-only identity on compact phones" % viewport_size
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
			"archetype_id": "gman" if index % 2 == 0 else "ordinary.assault",
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

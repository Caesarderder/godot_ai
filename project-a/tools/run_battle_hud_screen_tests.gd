extends SceneTree

const BATTLE_HUD_SCENE := preload("res://game/scenes/screens/battle_hud_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud := BATTLE_HUD_SCENE.instantiate() as BattleHudScreen
	root.add_child(hud)
	await process_frame
	hud.configure([{
		"hero_id": "hero_test",
		"display_name": "测试先锋",
		"max_hp": 200,
		"skill_id": "siege_shield",
		"star": 2,
	}], true, true)
	await process_frame
	_check(hud.find_child("BattleWorldViewportArea", true, false) != null, "HUD reserves the world view area")
	_check(hud.find_child("BattlePauseButton", true, false) != null, "HUD owns a pause action")
	_check(hud.find_child("BattleSkillModeButton", true, false) != null, "HUD owns an explicit skill mode")
	var skill_button := hud.find_child("BattleSkillButton_hero_test", true, false) as Button
	_check(skill_button != null, "HUD builds one skill action for each permanent hero")
	hud.apply_snapshot({
		"stage_index": 2,
		"stage_count": 3,
		"stage_name": "核心巨炮",
		"road_progress": 820,
		"warnings": [{"remaining_ticks": 10}],
		"units": [{
			"unit_id": "hero_test",
			"hp": 40,
			"max_hp": 200,
			"energy": 100,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(hud.status_label.text.contains("阶段 3/3"), "HUD projects battle phase from the runtime snapshot")
	_check(hud.status_label.text.contains("炮击 2.0秒"), "HUD exposes the boss warning countdown")
	_check(hud.status_label.text.contains("点装甲护盾扛炮"), "HUD explains the roster-specific cannon response")
	_check(skill_button != null and not skill_button.disabled, "manual skill becomes actionable at full energy")
	hud.apply_snapshot({
		"stage_index": 0,
		"stage_count": 3,
		"stage_name": "外围接敌",
		"road_progress": 300,
		"warnings": [],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 100,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(hud.status_label.text.contains("点击下方发光的 测试先锋 卡"), "first battle teaches the full-card skill action in context")
	var state_label := hud.find_child("BattleUnitStateLabel", true, false) as Label
	_check(state_label != null and state_label.text == "点击整张卡", "ready card labels the complete touch target")
	hud.confirm_skill_requested()
	hud.apply_snapshot({
		"stage_index": 0,
		"stage_count": 3,
		"stage_name": "外围接敌",
		"road_progress": 300,
		"warnings": [],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 0,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(hud.status_label.text.contains("指令生效"), "accepted first skill receives immediate HUD confirmation")
	hud.set_manual_skills(false)
	hud.apply_snapshot({
		"units": [{
			"unit_id": "hero_test",
			"hp": 0,
			"max_hp": 200,
			"energy": 100,
			"alive": false,
			"temporary": false,
		}],
	})
	_check(skill_button != null and skill_button.disabled, "automatic or defeated units cannot receive manual skill orders")
	_check(state_label != null and state_label.text == "阵亡", "HUD explains disabled skill state with text")
	hud.configure([{
		"hero_id": "hero_test",
		"display_name": "测试先锋",
		"max_hp": 200,
		"skill_id": "siege_shield",
		"star": 2,
	}], true, false, true)
	hud.apply_snapshot({
		"stage_index": 0,
		"stage_count": 3,
		"stage_name": "高墙接敌",
		"road_progress": 100,
		"warnings": [],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 0,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(hud.status_label.text.contains("援军已就位"), "counterattack opens with a short reinforcement rally")
	_check(hud.status_label.text.contains("装甲前排承伤") and hud.status_label.text.contains("冲锋快速压制"), "rally restates both learned responsibilities")
	hud.queue_free()
	await process_frame
	if failures.is_empty():
		print("BATTLE_HUD_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("BATTLE_HUD_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

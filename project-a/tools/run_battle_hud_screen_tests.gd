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
		"skill_display_name": "攻城护盾",
		"skill_timing": "核心巨炮预警倒计时内释放",
		"star": 2,
	}], true, true)
	await process_frame
	_check(hud.find_child("BattleWorldViewportArea", true, false) != null, "HUD reserves the world view area")
	_check(hud.find_child("BattlePauseButton", true, false) != null, "HUD owns a pause action")
	_check(hud.find_child("BattleSkillModeButton", true, false) != null, "HUD owns an explicit skill mode")
	var skill_button := hud.find_child("BattleSkillButton_hero_test", true, false) as Button
	_check(skill_button != null, "HUD builds one skill action for each permanent hero")
	_check(_tree_has_text(hud, "测试先锋 · 攻城护盾"), "HUD names the real player-facing skill")
	_check(skill_button != null and skill_button.tooltip_text.contains("核心巨炮预警"), "HUD exposes the skill timing")
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
		"structures": [{
			"structure_id": "opening_barricade",
			"display_name": "废弃路障",
			"kind": "structure",
			"stage": 0,
			"hp": 113,
			"max_hp": 180,
			"alive": true,
		}, {
			"structure_id": "opening_city",
			"display_name": "无防备城市",
			"kind": "city",
			"stage": 0,
			"hp": 760,
			"max_hp": 760,
			"alive": true,
		}],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 100,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(hud.status_label.text.contains("突破废弃路障 · 耐久 63%"), "first battle names the current destructible objective and remaining durability")
	_check(
		hud.status_label.text.contains("首次反攻强化 · 点击发光的 测试先锋 卡"),
		"first battle teaches the full-card skill action and names the one-off power fantasy"
	)
	_check(
		String(hud.call("_objective_copy", {
			"stage_index": 0,
			"structures": [{
				"display_name": "废弃路障",
				"kind": "structure",
				"stage": 0,
				"hp": 0,
				"max_hp": 180,
				"alive": false,
			}, {
				"display_name": "无防备城市",
				"kind": "city",
				"stage": 0,
				"hp": 380,
				"max_hp": 760,
				"alive": true,
			}],
		})).contains("摧毁无防备城市 · 耐久 50%"),
		"HUD advances from a destroyed roadblock to the live city objective"
	)
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
	hud.configure([{
		"hero_id": "hero_test",
		"display_name": "装甲先锋",
		"max_hp": 200,
		"skill_id": "siege_shield",
		"skill_display_name": "攻城护盾",
		"skill_timing": "核心巨炮预警倒计时内释放",
		"star": 2,
	}], true)
	hud.apply_battle_events([
		{"type": &"skill_used", "unit_id": &"hero_test", "skill_id": "siege_shield"},
		{"type": &"unit_shielded", "unit_id": &"hero_test", "source_id": &"hero_test", "shield": 80},
		{"type": &"unit_shielded", "unit_id": &"hero_ally", "source_id": &"hero_test", "shield": 60},
		{"type": &"structure_damaged", "source_id": &"hero_test", "damage": 75, "effective_damage": 40, "is_skill": true},
	])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "火力区",
		"road_progress": 600,
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
	_check(
		hud.status_label.text.contains("装甲先锋 · 攻城护盾")
		and hud.status_label.text.contains("造成 40 伤害")
		and hud.status_label.text.contains("为 2 人提供 140 护盾"),
		"accepted battle events become a named, quantified skill result"
	)
	hud.apply_snapshot({
		"stage_index": 2,
		"stage_count": 3,
		"stage_name": "核心巨炮",
		"road_progress": 800,
		"warnings": [{"remaining_ticks": 9}],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 0,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(
		hud.status_label.text.contains("炮击 1.8秒") and not hud.status_label.text.contains("造成 40 伤害"),
		"boss warning keeps priority over general skill feedback"
	)
	hud.show_skill_unavailable()
	hud.apply_snapshot({
		"stage_index": 2,
		"stage_count": 3,
		"stage_name": "核心巨炮",
		"road_progress": 800,
		"warnings": [{"remaining_ticks": 8}],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 0,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(
		hud.status_label.text.contains("炮击 1.6秒") and not hud.status_label.text.contains("技能尚未就绪"),
		"boss warning also keeps priority over a rejected skill order"
	)
	hud.apply_snapshot({
		"stage_index": 2,
		"stage_count": 3,
		"stage_name": "核心巨炮",
		"road_progress": 800,
		"warnings": [{
			"remaining_ticks": 22,
			"suppressed": true,
			"suppression_current": 82,
			"suppression_target": 70,
		}],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 0,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(
		hud.status_label.text.contains("巨炮已压制 · 安全窗口")
		and hud.status_label.get_theme_color("font_color") == BattleHudScreen.GREEN,
		"accepted suppression keeps a readable green confirmation instead of a stale countdown"
	)
	hud.apply_snapshot({
		"stage_index": 2,
		"stage_count": 3,
		"stage_name": "核心巨炮",
		"road_progress": 800,
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
	_check(
		hud.status_label.text.contains("技能尚未就绪 · 等待能量充满"),
		"rejected skill order uses the local HUD after the cannon warning clears"
	)
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


func _tree_has_text(node: Node, expected: String) -> bool:
	if node is Label and expected in String((node as Label).text):
		return true
	for child in node.get_children():
		if _tree_has_text(child, expected):
			return true
	return false

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
	hud.apply_battle_events([{
		"type": &"resonance_warning",
		"remaining_ticks": 10,
		"energy_drain": 14,
	}])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "共振街区",
		"road_progress": 500,
		"warnings": [],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 80,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(
		hud.status_label.text.contains("共振蓄能")
			and hud.status_label.text.contains("立即释放已就绪技能"),
		"chapter-two warning turns hidden energy loss into a timed player decision"
	)
	hud.apply_battle_events([{
		"type": &"resonance_pulse",
		"energy_drained": 42,
		"affected": 3,
	}])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "共振街区",
		"road_progress": 500,
		"warnings": [],
		"units": [{
			"unit_id": "hero_test",
			"hp": 200,
			"max_hp": 200,
			"energy": 66,
			"alive": true,
			"temporary": false,
		}],
	})
	_check(
		hud.status_label.text.contains("共振冲击")
			and hud.status_label.text.contains("全队损失 42 能量"),
		"chapter-two pulse quantifies its real impact after the warning"
	)
	hud.apply_battle_events([{
		"type": &"speaker_reinforcement",
		"wave": 1,
		"wave_limit": 2,
	}])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "广播车队",
		"road_progress": 520,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("广播车增援")
			and hud.status_label.text.contains("第1/2波"),
		"stage 2-3 HUD turns a spawned enemy into readable tempo pressure"
	)
	hud.apply_battle_events([{
		"type": &"speaker_echo_warning",
		"rank": "back",
		"remaining_ticks": 10,
	}])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "双塔回响",
		"road_progress": 560,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("2秒后冲击后排"),
		"stage 2-4 HUD names the threatened rank before impact"
	)
	hud.apply_battle_events([{
		"type": &"speaker_echo_impact",
		"rank": "back",
		"damage": 38,
	}])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "双塔回响",
		"road_progress": 560,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("后排承受 38 伤害")
			and hud.status_label.text.contains("下一次将切换排位"),
		"echo impact quantifies the consequence and teaches the next alternating target"
	)
	hud.apply_battle_events([{
		"type": &"tv_signal_vanish",
		"duration_ticks": 10,
	}])
	hud.apply_snapshot({
		"stage_index": 0,
		"stage_count": 3,
		"stage_name": "信号消失",
		"road_progress": 420,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("目标信号消失")
			and hud.status_label.text.contains("先转火"),
		"stage 3-1 HUD converts target loss into an immediate fallback action"
	)
	hud.apply_battle_events([{
		"type": &"screen_control",
		"unit_id": &"hero_unknown",
		"duration_ticks": 8,
	}])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "屏幕控制",
		"road_progress": 520,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("屏幕控制")
			and hud.status_label.text.contains("1.6秒")
			and hud.status_label.text.contains("其余成员继续推进"),
		"stage 3-3 HUD names the controlled member window and unaffected fallback"
	)
	hud.apply_battle_events([{
		"type": &"tv_overseer_shield",
		"shielded": 2,
		"amount": 24,
	}])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "处决画面",
		"road_progress": 560,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("2名精英获得 24 护盾")
			and hud.status_label.text.contains("集中爆发击穿"),
		"stage 3-4 HUD quantifies overseer protection and its response"
	)
	hud.apply_battle_events([{
		"type": &"alliance_anti_air",
		"locked": false,
		"duration_ticks": 5,
	}])
	hud.apply_snapshot({
		"stage_index": 0,
		"stage_count": 3,
		"stage_name": "禁飞走廊",
		"road_progress": 440,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("当前无飞行单位")
			and hud.status_label.text.contains("成功规避"),
		"stage 4-2 explicitly rewards a ground formation instead of showing an empty hazard"
	)
	hud.apply_battle_events([{
		"type": &"alliance_purge",
		"purged": 2,
		"damage": 64,
	}])
	hud.apply_snapshot({
		"stage_index": 1,
		"stage_count": 3,
		"stage_name": "反寄生实验区",
		"road_progress": 530,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("2个临时单位承受 64 伤害")
			and hud.status_label.text.contains("保护永久主队"),
		"stage 4-3 identifies the exact disposable targets and reassures permanent-roster safety"
	)
	hud.apply_battle_events([{
		"type": &"alliance_mark",
		"unit_id": &"hero_unknown",
		"duration_ticks": 15,
	}])
	hud.apply_snapshot({
		"stage_index": 0,
		"stage_count": 3,
		"stage_name": "联合标记",
		"road_progress": 420,
		"warnings": [],
		"units": [],
	})
	_check(
		hud.status_label.text.contains("被锁定 3.0秒")
			and hud.status_label.text.contains("开盾或治疗"),
		"stage 4-1 turns focus fire into a timed defensive decision"
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

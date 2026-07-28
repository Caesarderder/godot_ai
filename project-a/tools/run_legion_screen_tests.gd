extends SceneTree

const LEGION_SCENE := preload("res://game/scenes/screens/legion_screen.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var legion := LEGION_SCENE.instantiate() as LegionScreen
	root.add_child(legion)
	await process_frame
	legion.configure({
		"tab": "formation",
		"formation_edit_slot": "troop_1",
		"first_formation": {
			"active": true,
			"deployed": 0,
			"target": 2,
			"instruction": "先让装甲进入前排承伤",
		},
		"counterattack": {"visible": false},
		"team_power": 5700,
		"target_stage_name": "1-5 灰镜核心巨炮",
		"recommended_power": 6500,
		"formation": [
			{"slot_id": "commander", "display_name": "G-Man 指挥官", "role": "统帅 · 稳定输出"},
			{"slot_id": "troop_1", "display_name": "冲锋马桶人", "role": "突击 · 快速压制"},
		],
		"candidates": [
			{
				"hero_id": "hero_assault",
				"display_name": "冲锋马桶人",
				"role": "突击 · 快速压制",
				"power": 1900,
				"power_delta": 0,
				"current": true,
				"recommended": false,
			},
			{
				"hero_id": "hero_armored",
				"display_name": "装甲马桶人",
				"role": "重装 · 承伤保护",
				"power": 2050,
				"power_delta": 150,
				"current": false,
				"recommended": true,
			},
		],
		"roster": [],
	})
	await process_frame
	_check(not _tree_has_text(legion, "战力差 +800"), "focused first formation defers generalized power analysis")
	_check(_tree_has_text(legion, "重装 · 承伤保护"), "candidate comparison exposes gameplay role")
	_check(_tree_has_text(legion, "军团变化 +150"), "candidate comparison exposes formation impact")
	_check(_tree_has_text(legion, "高墙反攻编队 0/2"), "first formation exposes visible two-reinforcement progress")
	_check(_tree_has_text(legion, "先让装甲进入前排承伤"), "first formation explains the recommended responsibility")
	_check(_tree_has_text(legion, "推荐下一步"), "recommended candidate is explicit without disabling alternatives")
	_check(not (legion.get_node("TaskTabs") as HBoxContainer).visible, "first formation hides unrelated recruit and roster tabs")
	var candidate := legion.find_child("FormationCandidate_hero_armored", true, false) as Button
	_check(candidate != null and not candidate.disabled, "a replacement candidate is actionable")
	var request := {"action": "", "hero_id": "", "stage_id": ""}
	var selection := {"hero_id": ""}
	legion.action_requested.connect(func(action_id: String, payload: Dictionary) -> void:
		request["action"] = action_id
		request["hero_id"] = String(payload.get("hero_id", ""))
		request["stage_id"] = String(payload.get("stage_id", ""))
	)
	legion.hero_selected.connect(func(hero_id: String) -> void:
		selection["hero_id"] = hero_id
	)
	if candidate != null:
		candidate.pressed.emit()
	_check(request["action"] == "assign_slot" and request["hero_id"] == "hero_armored", "screen emits a semantic assignment request")
	legion.configure({
		"tab": "formation",
		"formation_edit_slot": "troop_2",
		"first_formation": {"active": false},
		"counterattack": {
			"visible": true,
			"stage_id": "stage_1_4",
			"label": "编队完成 · 立即反攻 1-4",
		},
		"team_power": 5700,
		"target_stage_name": "1-4 高墙防线",
		"recommended_power": 5700,
		"formation": [],
		"candidates": [],
		"roster": [],
	})
	await process_frame
	var counterattack := legion.find_child("FormationCounterattackButton", true, false) as Button
	_check(counterattack != null, "completed first formation exposes one direct counterattack action")
	if counterattack != null:
		counterattack.pressed.emit()
	_check(request["action"] == "counterattack" and request["stage_id"] == "stage_1_4", "counterattack action routes to the exact hurdle")
	legion.configure({
		"tab": "recruit",
		"recruitment_unlocked": false,
		"recruitment_progress": "指挥官 Lv2/4 · 关卡 1-5 未通关",
		"foundational_signal": {
			"unlocked": false,
			"claimable": false,
			"claimed": false,
		},
	})
	await process_frame
	_check(_tree_has_text(legion, "解锁信号招募后才开放免费十连"), "locked recruitment also keeps the free ten-pull locked")
	var foundational_signal := legion.find_child("FoundationalSignalTenButton", true, false) as Button
	_check(foundational_signal == null, "free blueprint ten-pull is absent before signal recruitment unlocks")
	legion.configure({
		"tab": "recruit",
		"recruitment_unlocked": true,
		"recruit_tickets": 10,
		"recruit_s_pity": 0,
		"recruit_target_guaranteed": false,
		"blueprint_data_copy": "重复图纸将自动转化为型号专属碎片",
		"recruit_results": [{
			"rarity": "B",
			"kind": "hero_fragments",
			"display_name": "冲锋马桶人",
			"amount": 20,
		}],
		"recruit_reward_summary": {
			"draw_count": 10,
			"new_blueprints": 2,
			"fragment_total": 60,
			"highest_rating": "A",
		},
		"recruit_reveal": true,
		"reduced_motion": false,
		"recruit_core_choices": [
			{
				"archetype_id": "assault",
				"display_name": "冲锋马桶人",
				"rating": "B",
				"faction": "高速突袭",
				"playstyle": "抢先破城",
				"synergy_summary": "已有搭档：Gman",
				"fragments": 20,
				"next_star_effect": "顺劈多个目标",
			},
			{
				"archetype_id": "rocket",
				"display_name": "火箭飞行马桶人",
				"rating": "B",
				"faction": "远程轰炸",
				"playstyle": "后排拆塔",
				"synergy_summary": "阵容变化：补足后排拆塔",
				"fragments": 20,
				"next_star_effect": "齐射多个目标",
			},
		],
		"recruit_focus": {
			"archetype_id": "assault",
			"hero_id": "",
			"display_name": "冲锋马桶人",
			"faction": "高速突袭",
			"status": "图纸已获得 · 研发后角色永久入列",
			"next_star_effect": "攻击会顺劈附近敌人",
			"action": "open_research",
			"action_label": "前往研究所 · 研发阵营核心",
		},
	})
	await process_frame
	await process_frame
	await process_frame
	var reveal_card := legion.find_child(
		"RecruitFactionChoiceCard_assault",
		true,
		false
	) as Control
	_check(
		reveal_card != null
			and (
				reveal_card.modulate.a < 1.0
				or reveal_card.scale.x < 1.0
			),
		"a fresh ten-pull starts a bounded candidate reveal without changing its action"
	)
	await create_timer(0.8).timeout
	_check(
		reveal_card != null
			and is_equal_approx(reveal_card.modulate.a, 1.0)
			and reveal_card.scale.is_equal_approx(Vector2.ONE),
		"the candidate reveal settles at a fully readable stable layout"
	)
	_check(
		_tree_has_text(legion, "十连战果已锁定 · 新角色图纸 2 · 专属碎片 +60"),
		"faction choice first names the concrete ten-pull haul"
	)
	_check(
		_tree_has_text(legion, "研发 → 入队 → 3场实战 → 质变突破"),
		"faction choice previews the next playable proof loop"
	)
	_check(
		_tree_has_text(legion, "新角色设计 · B级 · 冲锋马桶人"),
		"faction choice frames each candidate as a newly unlocked character design"
	)
	var reduced_view := (legion.get("_view") as Dictionary).duplicate(true)
	reduced_view["reduced_motion"] = true
	reduced_view["recruit_reveal"] = true
	legion.configure(reduced_view)
	await process_frame
	await process_frame
	await process_frame
	reveal_card = legion.find_child(
		"RecruitFactionChoiceCard_assault",
		true,
		false
	) as Control
	_check(
		reveal_card != null
			and is_equal_approx(reveal_card.modulate.a, 1.0)
			and reveal_card.scale.is_equal_approx(Vector2.ONE),
		"reduced motion bypasses the reveal and keeps the complete result immediately visible"
	)
	_check(_tree_has_text(legion, "冲锋马桶人专属碎片 +20"), "duplicate signal result projects archetype-specific fragments")
	_check(not _tree_has_text(legion, "设计数据"), "recruitment no longer projects blueprint data as a resource")
	_check(_tree_has_text(legion, "阵营核心 · 高速突袭"), "recruit result identifies the faction core")
	_check(_tree_has_text(legion, "2★质变：攻击会顺劈附近敌人"), "recruit result previews the qualitative star upgrade")
	var recruit_focus_action := legion.find_child("RecruitFocusActionButton", true, false) as Button
	_check(
		recruit_focus_action != null and recruit_focus_action.size.y >= 48.0,
		"recruit result exposes a touch-ready dominant next action"
	)
	if recruit_focus_action != null:
		recruit_focus_action.pressed.emit()
	_check(request["action"] == "open_research", "recruit result routes directly to research")
	legion.configure({
		"tab": "codex",
		"first_formation": {"active": false},
		"first_growth_choice": {"active": false},
		"boss_ready": {"active": false},
		"codex": [
			{
				"archetype_id": "gman",
				"display_name": "Gman",
				"rating": "S",
				"description": "初始指挥官",
				"status": "researched",
				"status_copy": "初始指挥官 · 永久角色已入列",
			},
			{
				"archetype_id": "assault",
				"display_name": "冲锋马桶人",
				"rating": "B",
				"description": "快速接敌",
				"status": "blueprint_owned",
				"status_copy": "已获得图纸 · 等待研究所研发",
			},
			{
				"archetype_id": "parasite",
				"display_name": "寄生母体马桶人",
				"rating": "S",
				"description": "召唤寄生幼体",
				"status": "undiscovered",
				"status_copy": "尚未获得设计图纸",
			},
		],
	})
	await process_frame
	_check(legion.find_child("ToiletRoleCodex", true, false) != null, "legion exposes a dedicated toilet-role codex")
	_check(_tree_has_text(legion, "B 评级 · 冲锋马桶人"), "codex displays the B rating")
	_check(_tree_has_text(legion, "S 评级 · 寄生母体马桶人"), "codex displays the S rating")
	_check(_tree_has_text(legion, "已获得图纸 · 等待研究所研发"), "codex distinguishes blueprint-owned from researched")
	# The App Shell leaves roughly 238 px for LegionScreen at the 844x390 target:
	# 48 px task tabs plus about 190 px of page content above the persistent nav.
	legion.size = Vector2(820, 238)
	legion.configure({
		"tab": "roster",
		"first_formation": {"active": false},
		"first_growth_choice": {"active": false},
		"boss_ready": {"active": false},
		"roster": [{
			"hero_id": "hero_armored",
			"display_name": "装甲马桶人",
			"archetype_id": "armored",
			"class_id": "guardian",
			"aptitude_id": "A",
			"role": "重装 · 承伤保护",
			"level": 1,
			"xp": 20,
			"next_level_xp": 40,
			"star": 1,
			"power": 2000,
			"battle_stats": {
				"hp": 190,
				"attack": 21,
				"defense": 40,
				"speed_milli": 84000,
				"crit_bp": 800,
			},
			"skill_name": "装甲护盾",
			"skill_level": 1,
			"skill_role": "前排保护",
			"skill_effect": "为全队建立吸收伤害的装甲屏障",
			"skill_timing": "敌方集火前释放",
			"next_growth": "升至 2★ 解锁职责被动",
			"faction": "钢铁防线",
			"fragment_balance": 1,
			"next_star_effect": "炮击格挡、冲门与反震",
			"welfare_star_core_count": 1,
			"auto_skill": false,
			"level_resource_context": {
				"name": "LevelResources_hero_armored",
				"title": "升级至 Lv.2 · 当前/需要 → 操作后",
				"items": [
					{"id": "toilet_coins", "name": "金币", "current": 120, "required": 60},
				],
			},
				"star_resource_context": {
					"name": "StarResources_hero_armored",
					"title": "普通升至 2★ · 当前/需要 → 操作后",
					"items": [
						{"id": "hero_fragments", "name": "装甲冲城马桶人专属碎片", "short_name": "专属碎片", "current": 1, "required": 30},
					],
				},
				"welfare_star_resource_context": {
					"name": "WelfareStarResources_hero_armored",
					"title": "黑金核心升至 2★ · 专属碎片本次免除",
					"items": [
						{"id": "hero_fragments", "name": "装甲冲城马桶人专属碎片", "short_name": "专属碎片", "current": 1, "required": 30, "waived": true},
					],
					"note": "核心替代本次型号碎片；工业材料不参与升星。",
				},
			"skill_resource_context": {
				"name": "SkillResources_hero_armored",
					"title": "技能研究 Lv.2 · 当前/需要 → 研究后",
					"items": [
						{"id": "toilet_coins", "name": "金币", "current": 120, "required": 80},
						{"id": "hero_shards", "name": "军团数据", "current": 1, "required": 1},
				],
			},
			"skill_research_cost": {"toilet_coins": 80, "hero_shards": 1},
		}, {
			"hero_id": "hero_assault",
			"display_name": "冲锋马桶人",
			"archetype_id": "assault",
			"class_id": "fighter",
			"aptitude_id": "B",
			"role": "突击 · 快速压制",
			"level": 2,
			"xp": 55,
			"next_level_xp": 100,
			"star": 2,
			"power": 2300,
			"battle_stats": {
				"hp": 200,
				"attack": 52,
				"defense": 37,
				"speed_milli": 96000,
				"crit_bp": 950,
			},
			"skill_name": "冲锋爆破",
			"skill_level": 3,
			"skill_role": "单体突破",
			"skill_effect": "快速压低核心耐久",
			"skill_timing": "核心暴露时释放",
			"next_growth": "升级提高基础属性",
			"specialty_name": "材料加工车间",
			"specialty_assigned": false,
			"auto_skill": true,
		}],
	})
	await process_frame
	var roster_split := legion.find_child("RosterSplitView", true, false) as Control
	_check(roster_split != null, "roster uses a left-list and right-detail split view")
	_check(
		roster_split != null
			and roster_split.size.y <= 190.0
			and roster_split.position.y + roster_split.size.y <= legion.size.y + 0.5,
		"roster split yields to the App Shell content height so persistent navigation stays visible"
	)
	_check(legion.find_child("RosterHeroListScroll", true, false) != null, "the permanent-hero list scrolls independently")
	_check(
		legion.find_child("RosterDetailScroll", true, false) == null,
		"selected hero detail uses a fixed two-dimensional board instead of a long scroll"
	)
	var identity_strip := legion.find_child("RosterIdentityStrip", true, false) as Control
	var data_board := legion.find_child("RosterDataBoard", true, false) as Control
	var cultivation_bar := legion.find_child("RosterCultivationBar", true, false) as Control
	_check(identity_strip != null, "roster keeps identity, role, power and XP in a compact top strip")
	_check(
		data_board != null
			and legion.find_child("RosterStatBoard", true, false) != null
			and legion.find_child("RosterSkillBoard", true, false) != null,
		"base stats, battle stats and active-skill responsibilities share one visible data board"
	)
	_check(cultivation_bar != null, "primary cultivation decisions share one horizontal bottom bar")
	for fixed_region in [identity_strip, data_board, cultivation_bar]:
		_check(
			fixed_region != null
				and fixed_region.get_global_rect().position.y
					>= roster_split.get_global_rect().position.y - 0.5
				and fixed_region.get_global_rect().end.y
					<= roster_split.get_global_rect().end.y + 0.5,
			"fixed roster region remains inside the 190 px first-frame detail board"
		)
	var skill_detail := legion.find_child("RosterSkillDetail", true, false) as Label
	var skill_timing := legion.find_child("RosterSkillTiming", true, false) as Label
	_check(
		skill_detail != null
			and skill_detail.text.contains("职责：前排保护")
			and skill_detail.text.contains("效果：为全队建立吸收伤害的装甲屏障")
			and skill_detail.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
		"touch-first skill board renders responsibility and effect as untrimmed first-frame text"
	)
	_check(
		skill_timing != null
			and skill_timing.text.contains("最佳时机：敌方集火前释放")
			and skill_timing.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING,
		"touch-first skill board renders best timing without relying on hover"
	)
	_check(_tree_has_text(legion, "守卫 · A评级"), "detail projects class and aptitude")
	_check(_tree_has_text(legion, "经验 20/40"), "detail projects current and next-level XP")
	_check(not _tree_has_text(legion, "体魄"), "detail removes the retired source attributes")
	_check(_tree_has_text(legion, "生命") and _tree_has_text(legion, "190"), "detail projects HP")
	_check(_tree_has_text(legion, "攻击") and _tree_has_text(legion, "21"), "detail projects the single attack stat")
	_check(not _tree_has_text(legion, "物理攻击"), "detail removes split physical attack")
	_check(not _tree_has_text(legion, "术能攻击"), "detail removes split magic attack")
	_check(_tree_has_text(legion, "防御") and _tree_has_text(legion, "40"), "detail projects defense")
	_check(_tree_has_text(legion, "速度") and _tree_has_text(legion, "84.0"), "detail projects speed")
	_check(_tree_has_text(legion, "暴击") and _tree_has_text(legion, "8.0%"), "detail projects crit chance")
	_check(not _tree_has_text(legion, "战备"), "detail does not expose the retired readiness field")
	_check(not _tree_has_text(legion, "伤势"), "detail does not expose the retired injury field")
	_check(
		legion.find_child("RosterResourceContext", true, false) == null,
		"roster leaves the fixed core-resource summary to the App Shell top bar"
	)
	_check(_tree_has_text(legion, "金币 120/60 → 60"), "level context projects the post-upgrade balance")
	_check(_tree_has_text(legion, "专属碎片 1/30 · 缺29"), "star context exposes the exact archetype-fragment shortage")
	_check(_tree_has_text(legion, "专属碎片 1/30 · 免"), "welfare star path marks the fragment cost as replaced")
	_check(
		not _tree_has_text(legion, "所有马桶人共用"),
		"hero detail does not duplicate quote-derived star cost with a hardcoded summary"
	)
	_check(_tree_has_text(legion, "工业材料不参与升星"), "welfare path reinforces the separated resource roles")
	_check(_tree_has_text(legion, "军团数据 1/1 → 0"), "skill research context exposes the post-research balance")
	_check(not _tree_has_text(legion, "技能芯片"), "hero growth omits the retired skill-chip resource")
	_check(not _tree_has_text(legion, "专属数据"), "hero growth omits the retired per-role data resource")
	_check(not _tree_has_text(legion, "陶瓷"), "hero growth omits factory materials")
	_check(not _tree_has_text(legion, "招募券"), "roster omits resources unrelated to growth decisions")
	var welfare_core := legion.find_child("WelfareStarCore_hero_armored", true, false) as Button
	_check(
		welfare_core != null and welfare_core.text.contains("本次专属碎片全免"),
		"one-star hero card exposes the contraband fragment-waiver action"
	)
	for action_spec in [
		["upgrade", "CultivationAction_upgrade"],
		["star", "CultivationAction_star"],
		["welfare_star_core", "WelfareStarCore_hero_armored"],
		["skill", "ResearchSkill_armored"],
	]:
		var action_id := String(action_spec[0])
		var cultivation_action := legion.find_child(String(action_spec[1]), true, false) as Button
		_check(
			cultivation_action != null
				and cultivation_action.get_global_rect().end.y
					<= roster_split.get_global_rect().end.y + 0.5,
			"cultivation action %s is visible without scrolling" % action_id
		)
	for action_node in cultivation_bar.find_children("*", "Button", true, false):
		var touch_action := action_node as Button
		_check(
			touch_action.size.y >= 48.0
				and touch_action.get_global_rect().end.y
					<= roster_split.get_global_rect().end.y + 0.5,
			"every roster detail action is a 48 px first-frame touch target: %s" % touch_action.name
		)
	for quote_node in cultivation_bar.find_children("CultivationQuote_*", "Label", true, false):
		var quote_label := quote_node as Label
		_check(
			quote_label.get_theme_font_size("font_size") >= 9,
			"cultivation quote remains readable at 9 px or larger: %s" % quote_label.name
		)
	if welfare_core != null:
		welfare_core.pressed.emit()
	_check(
		request["action"] == "welfare_star_core" and request["hero_id"] == "hero_armored",
		"contraband core button emits the exact semantic hero request"
	)
	var assault_entry := legion.find_child("RosterHero_hero_assault", true, false) as Button
	_check(assault_entry != null, "left roster exposes every permanent hero")
	if assault_entry != null:
		assault_entry.pressed.emit()
	await process_frame
	await process_frame
	_check(selection["hero_id"] == "hero_assault", "hero selection emits the App Shell persistence key")
	_check(
		legion.find_child("RosterHeroDetail_hero_assault", true, false) != null,
		"selecting a left-list hero replaces the right-side detail"
	)
	_check(
		root.gui_get_focus_owner() == legion.find_child("RosterHero_hero_assault", true, false),
		"roster rebuild restores focus to the selected hero"
	)
	_check(_tree_has_text(legion, "战士 · B评级"), "selected detail updates class and aptitude")
	_check(_tree_has_text(legion, "经验 55/100"), "selected detail updates XP without changing domain state")
	for secondary_name in ["RosterSecondaryAction_specialist", "RosterSecondaryAction_auto"]:
		var secondary_action := legion.find_child(secondary_name, true, false) as Button
		var secondary_visible := (
			secondary_action != null
		)
		if secondary_visible:
			secondary_visible = (
				secondary_action.size.y >= 48.0
				and secondary_action.get_global_rect().end.y
					<= legion.get_global_rect().end.y + 0.5
			)
		_check(
			secondary_visible,
			"selected hero secondary action is a visible 48 px touch target: %s" % secondary_name
		)
	var rebuild_view := (legion.get("_view") as Dictionary).duplicate(true)
	rebuild_view["selected_hero_id"] = String(selection["hero_id"])
	legion.queue_free()
	await process_frame
	legion = LEGION_SCENE.instantiate() as LegionScreen
	legion.size = Vector2(820, 238)
	root.add_child(legion)
	legion.configure(rebuild_view)
	await process_frame
	await process_frame
	_check(
		legion.find_child("RosterHeroDetail_hero_assault", true, false) != null,
		"App Shell selection projection survives a full LegionScreen recreation after cultivation"
	)
	_check(
		root.gui_get_focus_owner() == legion.find_child("RosterHero_hero_assault", true, false),
		"full LegionScreen recreation restores focus to the persisted hero"
	)
	legion.queue_free()
	await process_frame
	if failures.is_empty():
		print("LEGION_SCREEN_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LEGION_SCREEN_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment):
		return true
	if node is Button and (node as Button).text.contains(fragment):
		return true
	for child in node.get_children():
		if _tree_has_text(child, fragment):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

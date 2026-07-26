class_name LegionScreen
extends VBoxContainer

signal tab_selected(tab_id: String)
signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")
const RED := Color("#d95c4f")

const SLOT_NAMES := {
	"commander": "前排 1",
	"troop_1": "前排 2",
	"troop_2": "前排 3",
	"troop_3": "后排 1",
	"troop_4": "后排 2",
	"troop_5": "后排 3",
}
@onready var content: VBoxContainer = %Content
@onready var scroll: ScrollContainer = %LegionContentScroll
@onready var task_tabs: HBoxContainer = $TaskTabs
@onready var formation_tab: Button = %LegionFormationTab
@onready var recruit_tab: Button = %LegionRecruitTab
@onready var roster_tab: Button = %LegionRosterTab

var _view: Dictionary = {}


func _ready() -> void:
	formation_tab.pressed.connect(tab_selected.emit.bind("formation"))
	recruit_tab.pressed.connect(tab_selected.emit.bind("recruit"))
	roster_tab.pressed.connect(tab_selected.emit.bind("roster"))
	_style_tab(formation_tab, true)
	_style_tab(recruit_tab, false)
	_style_tab(roster_tab, false)
	if not _view.is_empty():
		_rebuild()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	var active_tab := String(_view.get("tab", "formation"))
	var first_formation := _view.get("first_formation", {}) as Dictionary
	var first_growth := _view.get("first_growth_choice", {}) as Dictionary
	var boss_ready := _view.get("boss_ready", {}) as Dictionary
	task_tabs.visible = (
		not bool(first_formation.get("active", false))
		and not bool(first_growth.get("active", false))
		and not bool(boss_ready.get("active", false))
	)
	scroll.name = "LegionContentScroll_%s" % active_tab
	_style_tab(formation_tab, active_tab == "formation")
	_style_tab(recruit_tab, active_tab == "recruit")
	_style_tab(roster_tab, active_tab == "roster")
	_clear_content()
	if bool(first_growth.get("active", false)):
		content.add_child(_growth_choice_panel(first_growth))
		return
	if bool(boss_ready.get("active", false)):
		content.add_child(_boss_ready_panel(boss_ready))
		return
	match active_tab:
		"recruit":
			content.add_child(_recruit_panel())
		"roster":
			for hero_value in _view.get("roster", []):
				content.add_child(_hero_card(hero_value as Dictionary))
		_:
			content.add_child(_formation_panel())


func _boss_ready_panel(boss_ready: Dictionary) -> Control:
	var panel := _panel("成长已生效 · 立即验证你的选择")
	panel.name = "BossReadyPanel"
	panel.add_child(_label(
		"%s · %s" % [
			String(boss_ready.get("hero_name", "")),
			String(boss_ready.get("route", "")),
		],
		18,
		GOLD
	))
	panel.add_child(_label(String(boss_ready.get("tactic", "")), 14, CYAN))
	var team_power := int(boss_ready.get("team_power", 0))
	var recommended_power := int(boss_ready.get("recommended_power", 0))
	panel.add_child(_label(
		"军团战力 %d / 推荐 %d · %s" % [
			team_power,
			recommended_power,
			"已达验证线" if team_power >= recommended_power else "机制操作可弥补部分战力差",
		],
		14,
		GREEN if team_power >= recommended_power else GOLD
	))
	panel.add_child(_label(
		"失败不会损失角色或资源；结算会区分成长、巨炮时机和阵容问题。",
		12,
		GREEN
	))
	var action := _button("验证成长 · 进攻 1-5 灰镜核心巨炮", true)
	action.name = "BossReadyAttackButton"
	action.custom_minimum_size.y = 52
	action.pressed.connect(action_requested.emit.bind("boss", {
		"stage_id": String(boss_ready.get("stage_id", "stage_1_5")),
	}))
	panel.add_child(action)
	return panel


func _growth_choice_panel(first_growth: Dictionary) -> Control:
	var panel := _panel("首次战斗成长 · 二选一挑战 %s" % String(first_growth.get("target_stage", "章节 Boss")))
	panel.name = "FirstGrowthChoice"
	var choices := first_growth.get("choices", []) as Array
	var grid := GridContainer.new()
	grid.name = "FirstGrowthChoiceGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	panel.add_child(grid)
	for choice_value in choices:
		var choice := choice_value as Dictionary
		var frame := PanelContainer.new()
		frame.name = "GrowthRoute_%s" % String(choice.get("archetype_id", ""))
		frame.custom_minimum_size.x = 360
		frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		frame.add_theme_stylebox_override("panel", _box(PANEL_2, LINE))
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		frame.add_child(margin)
		var card := _panel("")
		margin.add_child(card)
		var archetype_id := String(choice.get("archetype_id", ""))
		card.add_child(_label(
			"%s · %s" % [
				String(choice.get("display_name", "")),
				"快攻" if archetype_id == "assault" else "守势",
			],
			16,
			TEXT
		))
		card.add_child(_label(String(choice.get("route", "")), 12, CYAN))
		card.add_child(_label(String(choice.get("verified", "")), 12, GREEN))
		card.add_child(_label(
			"战力 %d → %d（+%d）" % [
				int(choice.get("power_before", 0)),
				int(choice.get("power_after", 0)),
				int(choice.get("power_gain", 0)),
			],
			13,
			GOLD
		))
		card.add_child(_label("消耗 · %s" % String(choice.get("cost", "")), 11, TEXT))
		var upgraded := bool(choice.get("already_upgraded", false))
		var action := _button("已完成二星成长" if upgraded else "选择此路线并升至 2★", true)
		action.name = "ChooseGrowth_%s" % String(choice.get("archetype_id", ""))
		action.custom_minimum_size.y = 38
		action.disabled = upgraded or not bool(choice.get("affordable", false))
		action.pressed.connect(action_requested.emit.bind("star", {
			"hero_id": String(choice.get("hero_id", "")),
		}))
		card.add_child(action)
		if not upgraded and not bool(choice.get("affordable", false)):
			card.add_child(_label("资源不足 · 返回工厂收取后勤", 11, RED))
		grid.add_child(frame)
	return panel


func _formation_panel() -> Control:
	var first_formation := _view.get("first_formation", {}) as Dictionary
	var onboarding_active := bool(first_formation.get("active", false))
	var panel := _panel("" if onboarding_active else "出击阵型")
	if onboarding_active:
		var guide := _panel("高墙反攻编队 %d/%d · %s" % [
			int(first_formation.get("deployed", 0)),
			int(first_formation.get("target", 2)),
			String(first_formation.get("instruction", "")),
		])
		guide.name = "FirstFormationGuide"
		panel.add_child(guide)
	var counterattack := _view.get("counterattack", {}) as Dictionary
	if bool(counterattack.get("visible", false)):
		var action := _button(String(counterattack.get("label", "立即反攻")), true)
		action.name = "FormationCounterattackButton"
		action.custom_minimum_size.y = 48
		action.pressed.connect(action_requested.emit.bind("counterattack", {
			"stage_id": String(counterattack.get("stage_id", "stage_1_4")),
		}))
		panel.add_child(action)
	if not onboarding_active:
		panel.add_child(_label(
			"军团战力 %d · 下一目标 %s 推荐 %d" % [
				int(_view.get("team_power", 0)),
				String(_view.get("target_stage_name", "未知战区")),
				int(_view.get("recommended_power", 0)),
			],
			15,
			GOLD
		))
		var gap := int(_view.get("recommended_power", 0)) - int(_view.get("team_power", 0))
		panel.add_child(_label(
			"战力差 %s · 先选职责，再比较战力；前排承伤，后排保住关键输出。" % (
				"+%d" % gap if gap > 0 else "已达推荐线"
			),
			12,
			RED if gap > 0 else GREEN
		))
	var grid := GridContainer.new()
	grid.name = "FormationSlotGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	for slot_value in _view.get("formation", []):
		var slot := slot_value as Dictionary
		var slot_id := String(slot.get("slot_id", ""))
		if bool(first_formation.get("active", false)) and not slot_id in ["commander", "troop_1", "troop_2"]:
			continue
		var selected := slot_id == String(_view.get("formation_edit_slot", ""))
		var button := _button(
			"%s\n%s\n%s" % [
				String(SLOT_NAMES.get(slot_id, slot_id)),
				String(slot.get("display_name", "空位")),
				String(slot.get("role", "待命")),
			],
			selected
		)
		button.name = "FormationSlot_%s" % slot_id
		button.custom_minimum_size = Vector2(220, 54 if onboarding_active else 70)
		button.pressed.connect(action_requested.emit.bind("select_slot", {"slot": slot_id}))
		grid.add_child(button)
	panel.add_child(grid)
	var edit_slot := String(_view.get("formation_edit_slot", ""))
	if edit_slot.is_empty():
		panel.add_child(_label("轻点一个阵位，立即比较可替换角色。", 13, MUTED))
	else:
		panel.add_child(_candidate_panel(edit_slot))
	return panel


func _candidate_panel(slot_id: String) -> Control:
	var panel := _panel("替换 %s · 比较职责与战力变化" % String(SLOT_NAMES.get(slot_id, slot_id)))
	panel.name = "FormationCandidatePanel"
	var candidates := GridContainer.new()
	candidates.columns = 3
	candidates.add_theme_constant_override("h_separation", 6)
	candidates.add_theme_constant_override("v_separation", 6)
	for candidate_value in _view.get("candidates", []):
		var candidate := candidate_value as Dictionary
		var delta := int(candidate.get("power_delta", 0))
		var current := bool(candidate.get("current", false))
		var recommended := bool(candidate.get("recommended", false))
		var action := _button(
			"%s%s%s\n%s · 战力 %d\n军团变化 %s" % [
				String(candidate.get("display_name", "")),
				" ✓" if current else "",
				" · 推荐下一步" if recommended else "",
				String(candidate.get("role", "")),
				int(candidate.get("power", 0)),
				("%+d" % delta) if delta != 0 else "不变",
			],
			recommended and not current
		)
		action.name = "FormationCandidate_%s" % String(candidate.get("hero_id", ""))
		action.custom_minimum_size = Vector2(220, 66 if bool((_view.get("first_formation", {}) as Dictionary).get("active", false)) else 72)
		action.disabled = current
		action.pressed.connect(action_requested.emit.bind("assign_slot", {
			"slot": slot_id,
			"hero_id": String(candidate.get("hero_id", "")),
		}))
		candidates.add_child(action)
	panel.add_child(candidates)
	if not bool((_view.get("first_formation", {}) as Dictionary).get("active", false)):
		panel.add_child(_label("已在其他阵位的角色会与当前成员互换，不会丢失永久角色。", 11, MUTED))
	return panel


func _recruit_panel() -> Control:
	var panel := _panel("信号招募")
	if not bool(_view.get("recruitment_unlocked", false)):
		panel.add_child(_label(String(_view.get("recruitment_progress", "主线推进后开放")), 14, MUTED))
		panel.add_child(_label("冲锋与装甲由主线确定性获得；随机招募不会卡住首章。", 12, GREEN))
		return panel
	panel.add_child(_label(
		"招募券 %d · S 保底 %d/60 · 十抽至少 A · 定向保底%s" % [
			int(_view.get("recruit_tickets", 0)),
			int(_view.get("recruit_s_pity", 0)),
			"已生效" if bool(_view.get("recruit_target_guaranteed", false)) else "未触发",
		],
		14,
		GOLD
	))
	panel.add_child(_label("概率 R 80% / A 18% / S 2% · 重复英雄转专属数据", 12, MUTED))
	panel.add_child(_label("定向 S：寄生母体 · 十抽至少出现一名 A 级或更高成员", 12, TEXT))
	panel.add_child(_label(String(_view.get("hero_data_copy", "英雄数据：暂无")), 12, MUTED))
	var actions := HBoxContainer.new()
	var single := _button("招募 1 次", true)
	single.disabled = int(_view.get("recruit_tickets", 0)) < 1
	single.pressed.connect(action_requested.emit.bind("recruit", {"count": 1}))
	actions.add_child(single)
	var ten := _button("招募 10 次", false)
	ten.disabled = int(_view.get("recruit_tickets", 0)) < 10
	ten.pressed.connect(action_requested.emit.bind("recruit", {"count": 10}))
	actions.add_child(ten)
	panel.add_child(actions)
	var results := _view.get("recruit_results", []) as Array
	if not results.is_empty():
		var result_panel := _panel("本次信号响应")
		result_panel.name = "SignalRecruitResultPanel"
		var grid := GridContainer.new()
		grid.columns = 5
		for draw_value in results:
			var draw := draw_value as Dictionary
			var rarity := String(draw.get("rarity", "R"))
			var card := _label(
				"%s · %s\n%s" % [
					rarity,
					String(draw.get("display_name", "")),
					"永久英雄" if String(draw.get("kind", "hero")) == "hero" else "英雄数据 +%d" % int(draw.get("amount", 0)),
				],
				12,
				GOLD if rarity == "S" else (CYAN if rarity == "A" else MUTED)
			)
			card.custom_minimum_size = Vector2(150, 50)
			grid.add_child(card)
		result_panel.add_child(grid)
		panel.add_child(result_panel)
	return panel


func _hero_card(hero: Dictionary) -> Control:
	var panel := _panel("")
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	panel.add_child(line)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(info)
	info.add_child(_label(
		"%s    Lv.%d · %d★ · 战力 %d" % [
			String(hero.get("display_name", "")),
			int(hero.get("level", 1)),
			int(hero.get("star", 1)),
			int(hero.get("power", 0)),
		],
		18,
		TEXT
	))
	info.add_child(_label("%s · 无损可出征" % String(hero.get("role", "")), 13, GREEN))
	info.add_child(_label(
		"主动技能：%s Lv.%d · 下一成长 %s" % [
			String(hero.get("skill_name", "")),
			int(hero.get("skill_level", 1)),
			String(hero.get("next_growth", "已达当前上限")),
		],
		12,
		CYAN
	))
	if int(hero.get("star", 1)) < 3:
		info.add_child(_label(
			"专属数据 %d/%d · 不足部分可由通用碎片补足" % [
				int(hero.get("owned_data", 0)),
				int(hero.get("next_star_data", 4)),
			],
			11,
			GOLD if int(hero.get("owned_data", 0)) > 0 else MUTED
		))
	var actions := GridContainer.new()
	actions.columns = 2
	actions.custom_minimum_size.x = 360
	line.add_child(actions)
	_add_action(actions, "升级角色", "upgrade", hero, true)
	if int(hero.get("star", 1)) < 3:
		_add_action(actions, "升星", "star", hero, false)
	if int(hero.get("skill_level", 1)) < 3:
		var research := _add_action(
			actions,
			"研究技能 Lv.%d" % (int(hero.get("skill_level", 1)) + 1),
			"skill",
			hero,
			false
		)
		research.disabled = not bool(hero.get("skill_research_allowed", false))
	if int(hero.get("star", 1)) >= 2:
		_add_action(
			actions,
			"派驻%s%s" % [
				String(hero.get("specialty_name", "")),
				" ✓" if bool(hero.get("specialty_assigned", false)) else "",
			],
			"specialist",
			hero,
			false
		)
	_add_action(
		actions,
		"自动技能：%s" % ("开" if bool(hero.get("auto_skill", false)) else "关"),
		"auto",
		hero,
		false
	)
	return panel


func _add_action(parent: Control, text: String, action_id: String, hero: Dictionary, primary: bool) -> Button:
	var button := _button(text, primary)
	button.pressed.connect(action_requested.emit.bind(action_id, {
		"hero_id": String(hero.get("hero_id", "")),
		"facility_id": String(hero.get("specialty_id", "")),
		"enabled": not bool(hero.get("auto_skill", false)),
	}))
	parent.add_child(button)
	return button


func _style_tab(button: Button, active: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _box(Color("#244546") if active else PANEL_2, CYAN if active else LINE))
	button.add_theme_stylebox_override("hover", _box(Color("#315a5b"), CYAN))
	button.add_theme_stylebox_override("pressed", _box(Color("#17383a"), CYAN))
	button.add_theme_stylebox_override("focus", _box(Color("#17383a"), Color.WHITE))


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _box(Color("#244546") if primary else PANEL_2, CYAN if primary else LINE))
	button.add_theme_stylebox_override("hover", _box(Color("#315a5b"), CYAN))
	button.add_theme_stylebox_override("pressed", _box(Color("#17383a"), CYAN))
	button.add_theme_stylebox_override("focus", _box(Color("#17383a"), Color.WHITE))
	return button


func _panel(title: String) -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 7)
	panel.add_theme_stylebox_override("panel", _box(PANEL, LINE))
	if not title.is_empty():
		panel.add_child(_label(title, 16, CYAN))
	return panel


func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", CJK_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _box(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _clear_content() -> void:
	for child in content.get_children():
		child.queue_free()

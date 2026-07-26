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
@onready var formation_tab: Button = %LegionFormationTab
@onready var recruit_tab: Button = %LegionRecruitTab
@onready var roster_tab: Button = %LegionRosterTab

var _view: Dictionary = {}


func _ready() -> void:
	formation_tab.pressed.connect(tab_selected.emit.bind("formation"))
	recruit_tab.pressed.connect(tab_selected.emit.bind("recruit"))
	roster_tab.pressed.connect(tab_selected.emit.bind("roster"))
	if not _view.is_empty():
		_rebuild()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	var active_tab := String(_view.get("tab", "formation"))
	scroll.name = "LegionContentScroll_%s" % active_tab
	_style_tab(formation_tab, active_tab == "formation")
	_style_tab(recruit_tab, active_tab == "recruit")
	_style_tab(roster_tab, active_tab == "roster")
	_clear_content()
	match active_tab:
		"recruit":
			content.add_child(_recruit_panel())
		"roster":
			for hero_value in _view.get("roster", []):
				content.add_child(_hero_card(hero_value as Dictionary))
		_:
			content.add_child(_formation_panel())


func _formation_panel() -> Control:
	var panel := _panel("出击阵型")
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
		button.custom_minimum_size = Vector2(220, 70)
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
		var action := _button(
			"%s%s\n%s · 战力 %d\n军团变化 %s" % [
				String(candidate.get("display_name", "")),
				" ✓" if current else "",
				String(candidate.get("role", "")),
				int(candidate.get("power", 0)),
				("%+d" % delta) if delta != 0 else "不变",
			],
			not current
		)
		action.name = "FormationCandidate_%s" % String(candidate.get("hero_id", ""))
		action.custom_minimum_size = Vector2(220, 72)
		action.disabled = current
		action.pressed.connect(action_requested.emit.bind("assign_slot", {
			"slot": slot_id,
			"hero_id": String(candidate.get("hero_id", "")),
		}))
		candidates.add_child(action)
	panel.add_child(candidates)
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
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _box(Color("#244546") if active else PANEL_2, CYAN if active else LINE))
	button.add_theme_stylebox_override("hover", _box(Color("#315a5b"), CYAN))
	button.add_theme_stylebox_override("pressed", _box(Color("#17383a"), CYAN))


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _box(Color("#244546") if primary else PANEL_2, CYAN if primary else LINE))
	button.add_theme_stylebox_override("hover", _box(Color("#315a5b"), CYAN))
	button.add_theme_stylebox_override("pressed", _box(Color("#17383a"), CYAN))
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

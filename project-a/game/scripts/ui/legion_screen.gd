class_name LegionScreen
extends VBoxContainer

class PanelVBox:
	extends VBoxContainer

	var panel_style: StyleBox

	func _draw() -> void:
		if panel_style != null:
			panel_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

signal tab_selected(tab_id: String)
signal action_requested(action_id: String, payload: Dictionary)
signal hero_selected(hero_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const FORMATION_ICON := preload("res://assets/ui/icons/kenney_game_icons/multiplayer.png")
const RECRUIT_TAB_ICON := preload("res://assets/ui/icons/kenney_game_icons/signal_3.png")
const CODEX_TAB_ICON := preload("res://assets/ui/icons/kenney_game_icons/target.png")
const ROSTER_TAB_ICON := preload("res://assets/ui/icons/kenney_game_icons/wrench.png")
const RECRUIT_SIGNAL_ICON := preload("res://assets/ui/icons/kenney_game_icons/target.png")
const RECRUIT_STAR_ICON := preload("res://assets/ui/icons/kenney_game_icons/star.png")
const RECRUIT_SELECT_ICON := preload("res://assets/ui/icons/kenney_game_icons/target.png")
const FACTION_ASSAULT_CHOICE_ART := preload("res://assets/ui/recruit/faction-assault-v2.webp")
const CODEX_LOCK_ICON := preload("res://assets/ui/icons/kenney_game_icons/locked.png")
const CODEX_STAR_ICON := preload("res://assets/ui/icons/kenney_game_icons/star.png")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const ResourceContextHudScript := preload("res://game/scripts/ui/resource_context_hud.gd")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")
const RED := Color("#d95c4f")
const CLASS_NAMES := {
	"guardian": "守卫",
	"fighter": "战士",
	"ranger": "远程",
	"arcanist": "术能",
}
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
@onready var codex_tab: Button = %LegionCodexTab
@onready var roster_tab: Button = %LegionRosterTab

var _view: Dictionary = {}
var _selected_hero_id := ""
var _selected_codex_id := ""
var _roster_hero_list: VBoxContainer
var _recruit_reveal_tween: Tween
var _recruit_reveal_generation := 0


func _ready() -> void:
	formation_tab.pressed.connect(tab_selected.emit.bind("formation"))
	recruit_tab.pressed.connect(tab_selected.emit.bind("recruit"))
	codex_tab.pressed.connect(tab_selected.emit.bind("codex"))
	roster_tab.pressed.connect(tab_selected.emit.bind("roster"))
	_style_tab(formation_tab, true)
	_style_tab(recruit_tab, false)
	_style_tab(codex_tab, false)
	_style_tab(roster_tab, false)
	if not _view.is_empty():
		_rebuild()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	_selected_hero_id = String(_view.get("selected_hero_id", _selected_hero_id))
	_selected_codex_id = String(_view.get("codex_focus_id", _selected_codex_id))
	_ensure_selected_hero()
	_ensure_selected_codex()
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	_cancel_recruit_reveal()
	var active_tab := String(_view.get("tab", "formation"))
	var compact := bool(_view.get("compact", get_viewport_rect().size.x < 720.0))
	var first_formation := _view.get("first_formation", {}) as Dictionary
	var first_growth := _view.get("first_growth_choice", {}) as Dictionary
	var boss_ready := _view.get("boss_ready", {}) as Dictionary
	task_tabs.visible = (
		not bool(first_formation.get("active", false))
		and not bool(first_growth.get("active", false))
		and not bool(boss_ready.get("active", false))
	)
	formation_tab.text = "阵型"
	recruit_tab.text = "招募"
	codex_tab.text = "图鉴"
	roster_tab.text = "培养"
	scroll.name = "LegionContentScroll_%s" % active_tab
	_style_tab(formation_tab, active_tab == "formation")
	_style_tab(recruit_tab, active_tab == "recruit")
	_style_tab(codex_tab, active_tab == "codex")
	_style_tab(roster_tab, active_tab == "roster")
	_configure_tool_tab(formation_tab, FORMATION_ICON, "阵型", "六人出击阵型")
	_configure_tool_tab(recruit_tab, RECRUIT_TAB_ICON, "招募", "信号招募")
	_configure_tool_tab(codex_tab, CODEX_TAB_ICON, "图鉴", "角色图鉴")
	_configure_tool_tab(roster_tab, ROSTER_TAB_ICON, "培养", "成员培养")
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
		if active_tab == "roster"
		else ScrollContainer.SCROLL_MODE_AUTO
	)
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
			if not (_view.get("recruit_results", []) as Array).is_empty():
				if (
					bool(_view.get("recruit_reveal", false))
					and not bool(_view.get("reduced_motion", false))
				):
					call_deferred("_play_recruit_reveal")
				else:
					call_deferred("_focus_recruit_result")
		"codex":
			content.add_child(_codex_panel())
		"roster":
			content.add_child(_roster_panel())
			call_deferred("_focus_selected_roster_hero")
		_:
			content.add_child(_formation_panel())
			call_deferred("_focus_faction_candidate")


func _boss_ready_panel(boss_ready: Dictionary) -> Control:
	var panel := _panel("成长已生效 · 立即投入战斗")
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
			"已达推荐线" if team_power >= recommended_power else "技能与站位可弥补部分战力差",
		],
		14,
		GREEN if team_power >= recommended_power else GOLD
	))
	panel.add_child(_label(
		"失败不会损失角色或资源；结算会区分成长、巨炮时机和阵容问题。",
		12,
		GREEN
	))
	var action := _button(
		"进攻 %s" % String(boss_ready.get("stage_name", "章节决战")),
		true
	)
	action.name = "BossReadyAttackButton"
	action.custom_minimum_size.y = 52
	action.pressed.connect(action_requested.emit.bind("boss", {
		"stage_id": String(boss_ready.get("stage_id", "stage_1_5")),
	}))
	panel.add_child(action)
	return panel


func _growth_choice_panel(first_growth: Dictionary) -> Control:
	var panel := _panel("首次战斗成长 · 冲锋/装甲二选一升至 2★ · 挑战 %s" % String(first_growth.get("target_stage", "章节首领")))
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
		frame.custom_minimum_size.x = 250
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
		card.add_child(_label(
			"%s · 战力 %d→%d（+%d）" % [
				String(choice.get("verified", "")),
				int(choice.get("power_before", 0)),
				int(choice.get("power_after", 0)),
				int(choice.get("power_gain", 0)),
			],
			11,
			GREEN
		))
		var resource_context := choice.get("resource_context", {}) as Dictionary
		if not resource_context.is_empty():
			card.add_child(_label(
				"消耗 · %s" % _resource_projection_copy(resource_context),
				10,
				GOLD
			))
		else:
			card.add_child(_label("消耗 · %s" % String(choice.get("cost", "")), 10, GOLD))
		var upgraded := bool(choice.get("already_upgraded", false))
		var action := _button("已完成二星成长" if upgraded else "选择此路线并升至 2★", true)
		action.name = "ChooseGrowth_%s" % String(choice.get("archetype_id", ""))
		action.custom_minimum_size.y = 48
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
	var compact := bool(_view.get("compact", get_viewport_rect().size.x < 720.0))
	var edit_slot := String(_view.get("formation_edit_slot", ""))
	var panel := _panel("")
	panel.add_theme_constant_override("separation", 5)
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
	if not onboarding_active and edit_slot.is_empty():
		var readiness := HBoxContainer.new()
		readiness.name = "FormationReadinessStrip"
		readiness.custom_minimum_size.y = 34
		readiness.add_theme_constant_override("separation", 8)
		var target_stage_name := String(_view.get("target_stage_name", "未知战区"))
		var power_label := _label(
			("%s%d/%d" % ["战力 " if compact else "出击小队 · ", int(_view.get("team_power", 0)), int(_view.get("recommended_power", 0))]),
			14,
			GOLD
		)
		power_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		power_label.custom_minimum_size.x = 132 if compact else 180
		power_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		readiness.add_child(power_label)
		var compact_target := target_stage_name.split(" ")[0]
		var target_label := _label(
			"目标 · %s" % (compact_target if compact else target_stage_name),
			12,
			CYAN
		)
		target_label.custom_minimum_size.x = 92 if compact else 230
		target_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		readiness.add_child(target_label)
		panel.add_child(readiness)
	var grid := GridContainer.new()
	grid.name = "FormationSlotGrid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var suggested_slot_id := ""
	for slot_value in _view.get("formation", []):
		var suggested_slot := slot_value as Dictionary
		if (
			String(suggested_slot.get("slot_id", "")) != "commander"
			and String(suggested_slot.get("hero_id", "")).is_empty()
		):
			suggested_slot_id = String(suggested_slot.get("slot_id", ""))
			break
	for slot_value in _view.get("formation", []):
		var slot := slot_value as Dictionary
		var slot_id := String(slot.get("slot_id", ""))
		if bool(first_formation.get("active", false)) and not slot_id in ["commander", "troop_1", "troop_2"]:
			continue
		var selected := slot_id == String(_view.get("formation_edit_slot", ""))
		var button := _formation_slot_card(
			slot,
			selected,
			slot_id == suggested_slot_id and not selected,
			compact,
			onboarding_active
		)
		button.pressed.connect(action_requested.emit.bind("select_slot", {"slot": slot_id}))
		grid.add_child(button)
	panel.add_child(grid)
	if not edit_slot.is_empty():
		panel.add_child(_candidate_panel(edit_slot))
	return panel


func _formation_slot_card(
	slot: Dictionary,
	selected: bool,
	suggested: bool,
	compact: bool,
	onboarding_active: bool
) -> Button:
	var slot_id := String(slot.get("slot_id", ""))
	var occupied := not String(slot.get("hero_id", "")).is_empty()
	var emphasized := selected or suggested
	var button := _button("", emphasized)
	button.name = "FormationSlot_%s" % slot_id
	button.custom_minimum_size = Vector2(0, 56 if compact else 60)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "%s · %s · %s" % [
		String(SLOT_NAMES.get(slot_id, slot_id)),
		String(slot.get("display_name", "空位")),
		String(slot.get("role", "待命")),
	]
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_top = 4
	row.offset_right = -6
	row.offset_bottom = -4
	row.add_theme_constant_override("separation", 6)
	button.add_child(row)
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(52, 52) if not compact else Vector2(42, 42)
	var badge_style := _box(
		Color("#10232a") if occupied else Color("#10191f"),
		CYAN if occupied else LINE
	)
	badge_style.set_corner_radius_all(10)
	badge.add_theme_stylebox_override("panel", badge_style)
	row.add_child(badge)
	if occupied:
		var portrait := TextureRect.new()
		portrait.name = "FormationPortrait_%s" % slot_id
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.texture = _hero_portrait(String(slot.get("archetype_id", "gman" if slot_id == "commander" else "")))
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.add_child(portrait)
	else:
		var symbol := _label("+", 30, Color("#443515") if emphasized else MUTED)
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(symbol)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)
	var tactical_slot := String(SLOT_NAMES.get(slot_id, slot_id)).replace("排 ", "")
	var slot_label := _label(
		tactical_slot,
		9,
		Color("#443515") if emphasized else MUTED
	)
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(slot_label)
	var title := _label(
		String(slot.get("display_name", "空位")) if occupied else ("推荐" if suggested else "待命"),
		12,
		Color("#182127") if emphasized else TEXT
	)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.max_lines_visible = 1
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(title)
	if occupied and not compact and not onboarding_active:
		var role := _label(
			String(slot.get("role", "待命")),
			10,
			Color("#3d4b2d") if emphasized else (GREEN if occupied else MUTED)
		)
		role.mouse_filter = Control.MOUSE_FILTER_IGNORE
		role.max_lines_visible = 1
		role.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		copy.add_child(role)
	return button


func _hero_portrait(archetype_id: String) -> Texture2D:
	if archetype_id.is_empty():
		return null
	return load("res://assets/ui/codex/%s.webp" % archetype_id) as Texture2D


func _faction_choice_portrait(archetype_id: String) -> Texture2D:
	if archetype_id == "assault":
		return FACTION_ASSAULT_CHOICE_ART
	return _hero_portrait(archetype_id)


func _candidate_panel(slot_id: String) -> Control:
	var slot_name := String(SLOT_NAMES.get(slot_id, slot_id))
	var target_empty := _formation_slot_is_empty(slot_id)
	var journey_candidate := _journey_focus_candidate()
	var panel := _panel("选择 %s" % slot_name)
	panel.name = "FormationCandidatePanel"
	if target_empty:
		panel.add_child(_label(
			"部署后 %d 人 · 完成 3 场磨合" % (_formation_deployed_count() + 1),
			11,
			CYAN
		))
	var candidates := GridContainer.new()
	candidates.columns = 2
	candidates.add_theme_constant_override("h_separation", 6)
	candidates.add_theme_constant_override("v_separation", 6)
	var ordered_candidates: Array = []
	for candidate_value in _view.get("candidates", []):
		if bool((candidate_value as Dictionary).get("journey_focus", false)):
			ordered_candidates.append(candidate_value)
	for candidate_value in _view.get("candidates", []):
		if not bool((candidate_value as Dictionary).get("journey_focus", false)):
			ordered_candidates.append(candidate_value)
	for candidate_value in ordered_candidates:
		var candidate := candidate_value as Dictionary
		var action := _formation_candidate_card(candidate)
		action.name = "FormationCandidate_%s" % String(candidate.get("hero_id", ""))
		action.disabled = bool(candidate.get("current", false))
		action.pressed.connect(action_requested.emit.bind("assign_slot", {
			"slot": slot_id,
			"hero_id": String(candidate.get("hero_id", "")),
		}))
		candidates.add_child(action)
	panel.add_child(candidates)
	if (
		not target_empty
		and not bool((_view.get("first_formation", {}) as Dictionary).get("active", false))
	):
		panel.add_child(_label(
			"已在其他阵位的角色会与当前成员互换，不会丢失永久角色。",
			11,
			MUTED
		))
	return panel


func _formation_candidate_card(candidate: Dictionary) -> Button:
	var recommended := bool(candidate.get("recommended", false)) or bool(candidate.get("journey_focus", false))
	var current := bool(candidate.get("current", false))
	var action := _button("", recommended and not current)
	action.custom_minimum_size = Vector2(0, 76)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.tooltip_text = "%s · %s · %s · 战力 %d" % [
		String(candidate.get("display_name", "")), String(candidate.get("faction", "")),
		String(candidate.get("skill_name", "")), int(candidate.get("power", 0))
	]
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 7
	row.offset_top = 5
	row.offset_right = -7
	row.offset_bottom = -5
	row.add_theme_constant_override("separation", 7)
	action.add_child(row)
	var portrait := TextureRect.new()
	portrait.name = "CandidatePortrait_%s" % String(candidate.get("archetype_id", ""))
	portrait.custom_minimum_size = Vector2(62, 62)
	portrait.texture = _hero_portrait(String(candidate.get("archetype_id", "")))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	copy.add_child(_label(("推荐下一步 · " if recommended else "") + String(candidate.get("display_name", "")), 12, Color("#182127") if recommended else TEXT))
	copy.add_child(_label(String(candidate.get("role", "")), 10, Color("#3d4b2d") if recommended else CYAN))
	var delta := int(candidate.get("power_delta", 0))
	copy.add_child(_label("军团变化 %+d" % delta if delta != 0 else "当前阵位", 10, Color("#3d4b2d") if recommended else MUTED))
	return action


func _journey_focus_candidate() -> Dictionary:
	for candidate_value in _view.get("candidates", []):
		var candidate := candidate_value as Dictionary
		if bool(candidate.get("journey_focus", false)) and not bool(candidate.get("current", false)):
			return candidate
	return {}


func _formation_slot_is_empty(slot_id: String) -> bool:
	for slot_value in _view.get("formation", []):
		var slot := slot_value as Dictionary
		if String(slot.get("slot_id", "")) == slot_id:
			return String(slot.get("hero_id", "")).is_empty()
	return true


func _formation_deployed_count() -> int:
	var count := 0
	for slot_value in _view.get("formation", []):
		if not String((slot_value as Dictionary).get("hero_id", "")).is_empty():
			count += 1
	return count


func _recruit_panel() -> Control:
	var results := _view.get("recruit_results", []) as Array
	var core_choices := _view.get("recruit_core_choices", []) as Array
	var recruit_focus := _view.get("recruit_focus", {}) as Dictionary
	if not results.is_empty() and not core_choices.is_empty():
		return _faction_core_choice_panel(
			core_choices,
			_view.get("recruit_reward_summary", {}) as Dictionary
		)
	if not results.is_empty() and not recruit_focus.is_empty():
		return _faction_core_handoff_panel(recruit_focus)
	var panel := _panel("信号招募")
	var foundational := _view.get("foundational_signal", {}) as Dictionary
	if bool(foundational.get("unlocked", false)):
		panel.add_child(_label(
			"阵营起手十连 · 真正参与精锐与传奇保底 · 新图纸研发角色，重复型号转专属碎片",
			13,
			GREEN
		))
		if bool(foundational.get("claimable", false)):
			var foundational_ten := _button("领取免费阵营十连", true)
			foundational_ten.name = "FoundationalSignalTenButton"
			foundational_ten.custom_minimum_size.y = 48
			foundational_ten.pressed.connect(
				action_requested.emit.bind("claim_foundational_signal", {})
			)
			panel.add_child(foundational_ten)
		elif bool(foundational.get("claimed", false)):
			panel.add_child(_label("免费十连已领取 · 新图纸去研究所研发，重复型号碎片可让对应角色升星", 12, CYAN))
	if not bool(_view.get("recruitment_unlocked", false)):
		panel.add_child(_label(String(_view.get("recruitment_progress", "主线推进后开放")), 14, MUTED))
		panel.add_child(_label("解锁信号招募后才开放免费十连；1-2、1-3 的首批角色图纸不依赖抽取。", 12, GREEN))
		return panel
	panel.add_child(_label(
		"招募券 %d · 传奇图纸保底 %d/60 · 十抽至少精锐 · 定向保底%s" % [
			int(_view.get("recruit_tickets", 0)),
			int(_view.get("recruit_s_pity", 0)),
			"已生效" if bool(_view.get("recruit_target_guaranteed", false)) else "未触发",
		],
		14,
		GOLD
	))
	panel.add_child(_label("图纸评级 标准80% / 精锐18% / 传奇2% · 重复图纸只转该型号专属碎片", 12, MUTED))
	panel.add_child(_label("定向传奇：寄生母体设计图 · 十抽至少出现一张精锐或更高图纸", 12, TEXT))
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
	if not results.is_empty():
		var result_panel := _panel(
			"" if not core_choices.is_empty() else "本次信号响应"
		)
		result_panel.name = "SignalRecruitResultPanel"
		if not core_choices.is_empty():
			var reward_summary := _view.get("recruit_reward_summary", {}) as Dictionary
			var choice_panel := _panel(
				"信号锁定  ·  新图纸 %d  ·  碎片 +%d" % [
					int(reward_summary.get("new_blueprints", 0)),
					int(reward_summary.get("fragment_total", 0)),
				]
			)
			choice_panel.name = "RecruitFactionCoreChoice"
			var choice_grid := GridContainer.new()
			choice_grid.columns = 2
			choice_grid.add_theme_constant_override("h_separation", 8)
			choice_grid.add_theme_constant_override("v_separation", 6)
			for choice_value in core_choices:
				var choice := choice_value as Dictionary
				var card := _panel("")
				card.name = "RecruitFactionChoiceCard_%s" % String(
					choice.get("archetype_id", "")
				)
				card.custom_minimum_size.x = 350
				card.panel_style = _box(
					Color("#181d22"),
					_faction_accent(String(choice.get("faction", "")))
				)
				card.tooltip_text = "%s · %s\n%s\n2★ %s\n选定后：研发 → 入队 → 3场磨合 → 挑战强敌" % [
					String(choice.get("display_name", "")),
					String(choice.get("faction", "")),
					String(choice.get("synergy_summary", "")),
					String(choice.get("next_star_effect", "")),
				]
				var identity := HBoxContainer.new()
				identity.add_theme_constant_override("separation", 8)
				card.add_child(identity)
				var signal_badge := PanelContainer.new()
				signal_badge.custom_minimum_size = Vector2(48, 48)
				var badge_style := _box(
					Color("#10232a"),
					_faction_accent(String(choice.get("faction", "")))
				)
				badge_style.set_corner_radius_all(10)
				signal_badge.add_theme_stylebox_override("panel", badge_style)
				identity.add_child(signal_badge)
				var signal_icon := TextureRect.new()
				signal_icon.texture = RECRUIT_SIGNAL_ICON
				signal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				signal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				signal_icon.modulate = _faction_accent(String(choice.get("faction", "")))
				signal_badge.add_child(signal_icon)
				var identity_copy := VBoxContainer.new()
				identity_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				identity_copy.add_theme_constant_override("separation", 1)
				identity.add_child(identity_copy)
				identity_copy.add_child(_label(
					"%s  %s  ·  %s" % [
						_rating_label(String(choice.get("rating", "B"))),
						String(choice.get("display_name", "")),
						String(choice.get("faction", "")),
					],
					14,
					GOLD
				))
				identity_copy.add_child(_icon_copy(
					RECRUIT_STAR_ICON,
					"2★  %s" % String(choice.get("next_star_effect", "")),
					CYAN
				))
				var choose := _button(
					"选定  ·  %s" % String(choice.get("playstyle", "")),
					true
				)
				choose.name = "ChooseFactionCore_%s" % String(
					choice.get("archetype_id", "")
				)
				# 76 logical px remains at least 48 physical px after the
				# compact App Shell's viewport scaling.
				choose.custom_minimum_size.y = 76
				choose.icon = RECRUIT_SELECT_ICON
				choose.expand_icon = true
				choose.tooltip_text = "选择%s作为阵营核心 · %s" % [
					String(choice.get("display_name", "")),
					String(choice.get("synergy_summary", "")),
				]
				choose.pressed.connect(action_requested.emit.bind(
					"choose_faction_core",
					{"archetype_id": String(choice.get("archetype_id", ""))}
				))
				card.add_child(choose)
				choice_grid.add_child(card)
			choice_panel.add_child(choice_grid)
			result_panel.add_child(choice_panel)
		var focus := _view.get("recruit_focus", {}) as Dictionary
		if not focus.is_empty():
			var focus_card := _panel("阵营核心 · %s" % String(focus.get("faction", "")))
			focus_card.name = "RecruitFactionFocus"
			focus_card.add_child(_label(
				"%s · %s" % [
					String(focus.get("display_name", "")),
					String(focus.get("status", "")),
				],
				16,
				GOLD
			))
			focus_card.add_child(_label(
				"2★新能力：%s" % String(focus.get("next_star_effect", "")),
				12,
				CYAN
			))
			var focus_action := String(focus.get("action", ""))
			if not focus_action.is_empty():
				var next_button := _button(String(focus.get("action_label", "继续培养")), true)
				next_button.name = "RecruitFocusActionButton"
				next_button.custom_minimum_size.y = 48
				next_button.pressed.connect(action_requested.emit.bind(focus_action, {
					"hero_id": String(focus.get("hero_id", "")),
					"archetype_id": String(focus.get("archetype_id", "")),
				}))
				focus_card.add_child(next_button)
			result_panel.add_child(focus_card)
		var grid := GridContainer.new()
		grid.columns = 5
		for draw_value in results:
			var draw := draw_value as Dictionary
			var rarity := String(draw.get("rarity", "B"))
			var pity_bonus := draw.get("pity_bonus", {}) as Dictionary
			var bonus_copy := ""
			if not pity_bonus.is_empty():
				bonus_copy = "\n60抽保底 · 传奇%s%s" % [
					String(pity_bonus.get("display_name", "")),
					(
						"碎片 +%d" % int(pity_bonus.get("amount", 0))
						if String(pity_bonus.get("kind", "")) == "hero_fragments"
						else "新图纸"
					),
				]
			var card := _label(
				"%s · %s\n%s%s" % [
					_rating_label(rarity),
					String(draw.get("display_name", "")),
					(
						"新设计图纸"
						if String(draw.get("kind", "blueprint")) == "blueprint"
						else "%s专属碎片 +%d" % [
							String(draw.get("display_name", "")),
							int(draw.get("amount", 0)),
						]
					),
					bonus_copy,
				],
				12,
				GOLD if rarity == "S" else (CYAN if rarity == "A" else MUTED)
			)
			card.custom_minimum_size = Vector2(150, 50)
			grid.add_child(card)
		result_panel.add_child(grid)
		panel.add_child(result_panel)
	return panel


func _faction_core_choice_panel(choices: Array, summary: Dictionary) -> Control:
	var compact := bool(_view.get("compact", false))
	var result_panel := _panel("")
	result_panel.name = "SignalRecruitResultPanel"
	result_panel.add_theme_constant_override("separation", 5)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	result_panel.add_child(heading)
	var heading_label := _label("选择阵营核心", 14, CYAN)
	# Wrapped labels report almost no horizontal minimum size. In an HBox the
	# expanding haul summary could therefore squeeze this title into one glyph
	# per line, consuming most of a phone's vertical viewport.
	heading_label.custom_minimum_size.x = 108 if compact else 124
	heading_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(heading_label)
	var haul := _label(
		"图纸 %d  ◆  碎片 +%d" % [
			int(summary.get("new_blueprints", 0)),
			int(summary.get("fragment_total", 0)),
		],
		11,
		MUTED
	)
	haul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haul.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	haul.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(haul)
	var choice_panel := HBoxContainer.new()
	choice_panel.name = "RecruitFactionCoreChoice"
	choice_panel.add_theme_constant_override("separation", 6)
	result_panel.add_child(choice_panel)
	for choice_value in choices:
		choice_panel.add_child(_faction_core_choice_card(choice_value as Dictionary, compact))
	var journey := _label("研发  →  入队  →  3场磨合  →  挑战强敌", 10, MUTED)
	journey.name = "RecruitFactionJourneyPromise"
	journey.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	journey.autowrap_mode = TextServer.AUTOWRAP_OFF
	result_panel.add_child(journey)
	return result_panel


func _faction_core_choice_card(choice: Dictionary, compact: bool) -> Control:
	var archetype_id := String(choice.get("archetype_id", ""))
	var faction := String(choice.get("faction", ""))
	var accent := _faction_accent(faction)
	var card := _panel("")
	card.name = "RecruitFactionChoiceCard_%s" % archetype_id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.x = 0
	card.add_theme_constant_override("separation", 3)
	card.panel_style = _box(Color("#111a20"), accent)
	card.tooltip_text = "%s · %s\n%s\n2★ %s\n选定后：研发 → 入队 → 3场磨合 → 挑战强敌" % [
		String(choice.get("display_name", "")),
		faction,
		String(choice.get("synergy_summary", "")),
		String(choice.get("next_star_effect", "")),
	]
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 6)
	card.add_child(identity)
	var portrait := TextureRect.new()
	portrait.name = "FactionChoicePortrait_%s" % archetype_id
	portrait.custom_minimum_size = Vector2(92 if compact else 118, 88 if compact else 108)
	portrait.texture = _faction_choice_portrait(archetype_id)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	identity.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 1)
	identity.add_child(copy)
	var name := _label(String(choice.get("display_name", "")), 15 if compact else 16, TEXT)
	name.max_lines_visible = 1
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	copy.add_child(name)
	copy.add_child(_label(String(choice.get("playstyle", "")), 14, GOLD))
	copy.add_child(_icon_copy(
		RECRUIT_STAR_ICON,
		"2★  %s" % _short_faction_effect(archetype_id),
		CYAN
	))
	var choose := _button("选定  ·  %s" % String(choice.get("playstyle", "")), true)
	choose.name = "ChooseFactionCore_%s" % archetype_id
	choose.custom_minimum_size.y = 48
	# Equal long-term choices use the same clean material in every state. The
	# global textured primary frame has corner marks and a bright focus fill
	# that read as resize handles plus a recommended/default answer here.
	choose.add_theme_stylebox_override("normal", _choice_button_style(GOLD))
	choose.add_theme_stylebox_override("hover", _choice_button_style(Color("#f2bd5d")))
	choose.add_theme_stylebox_override("pressed", _choice_button_style(Color("#c98c30")))
	choose.add_theme_stylebox_override("focus", _choice_button_style(GOLD, Color.WHITE))
	choose.tooltip_text = "选择%s作为阵营核心 · %s" % [
		String(choice.get("display_name", "")),
		String(choice.get("synergy_summary", "")),
	]
	choose.pressed.connect(action_requested.emit.bind(
		"choose_faction_core",
		{"archetype_id": archetype_id}
	))
	card.add_child(choose)
	return card


func _short_faction_effect(archetype_id: String) -> String:
	return "破城顺劈" if archetype_id == "assault" else "四联齐射"


func _choice_button_style(fill: Color, border: Color = Color("#f6d27a")) -> StyleBoxFlat:
	var style := _box(fill, border)
	style.set_corner_radius_all(7)
	style.set_border_width_all(2)
	return style


func _faction_core_handoff_panel(focus: Dictionary) -> Control:
	var compact := bool(_view.get("compact", false))
	var result_panel := _panel("")
	result_panel.name = "SignalRecruitResultPanel"
	var card := _panel("")
	card.name = "RecruitFactionFocus"
	card.panel_style = _box(Color("#111a20"), _faction_accent(String(focus.get("faction", ""))))
	result_panel.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var portrait := TextureRect.new()
	portrait.name = "RecruitFactionFocusPortrait"
	portrait.custom_minimum_size = Vector2(86 if compact else 116, 82 if compact else 108)
	portrait.texture = _hero_portrait(String(focus.get("archetype_id", "")))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	copy.add_child(_label(String(focus.get("display_name", "")), 17, TEXT))
	copy.add_child(_label(String(focus.get("faction", "")), 12, GOLD))
	copy.add_child(_icon_copy(RECRUIT_STAR_ICON, "2★  %s" % String(focus.get("next_star_effect", "")), CYAN))
	var focus_action := String(focus.get("action", ""))
	if not focus_action.is_empty():
		var next_button := _button(String(focus.get("action_label", "前往研究")), true)
		next_button.name = "RecruitFocusActionButton"
		next_button.custom_minimum_size.y = 48
		next_button.pressed.connect(action_requested.emit.bind(focus_action, {
			"hero_id": String(focus.get("hero_id", "")),
			"archetype_id": String(focus.get("archetype_id", "")),
		}))
		copy.add_child(next_button)
	return result_panel


func _icon_copy(icon: Texture2D, copy: String, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(18, 18)
	image.texture = icon
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.modulate = color
	row.add_child(image)
	var copy_label := _label(copy, 11, color)
	copy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_label.max_lines_visible = 1
	copy_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(copy_label)
	return row


func _codex_panel() -> Control:
	var entries := _view.get("codex", []) as Array
	var known_count := 0
	for entry_value in entries:
		if String((entry_value as Dictionary).get("status", "undiscovered")) != "undiscovered":
			known_count += 1
	var compact := bool(_view.get("compact", false))
	var panel := _panel("")
	panel.name = "ToiletRoleCodex"
	panel.add_theme_constant_override("separation", 5)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	panel.add_child(heading)
	var heading_label := _label("信号档案", 13, CYAN)
	heading_label.custom_minimum_size.x = 84
	heading_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(heading_label)
	var progress := _label("%d / %d" % [known_count, entries.size()], 12, TEXT)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.add_child(progress)
	var focus := _selected_codex_entry(entries)
	if not focus.is_empty():
		panel.add_child(_codex_focus_panel(focus, compact))
	var gallery := ScrollContainer.new()
	gallery.name = "ToiletRoleCodexGallery"
	gallery.custom_minimum_size.y = 58 if compact else 78
	gallery.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(gallery)
	var strip := HBoxContainer.new()
	strip.name = "ToiletRoleCodexGrid"
	strip.add_theme_constant_override("separation", 5)
	gallery.add_child(strip)
	for entry_value in entries:
		strip.add_child(_codex_portrait_card(entry_value as Dictionary))
	return panel


func _codex_portrait_card(entry: Dictionary) -> Control:
	var archetype_id := String(entry.get("archetype_id", "unknown"))
	var rating := String(entry.get("rating", "B"))
	var status := String(entry.get("status", "undiscovered"))
	var rating_color := GOLD if rating == "S" else (CYAN if rating == "A" else GREEN)
	var compact := bool(_view.get("compact", false))
	var selected := archetype_id == _selected_codex_id
	var card := Button.new()
	card.name = "Codex_%s" % archetype_id
	card.custom_minimum_size = Vector2(54 if compact else 72, 54 if compact else 72)
	card.focus_mode = Control.FOCUS_ALL
	card.add_theme_stylebox_override("normal", _box(
		Color("#10171c"),
		CYAN if selected else (rating_color if status != "undiscovered" else Color("#303940"))
	))
	card.add_theme_stylebox_override("hover", _box(Color("#16242a"), CYAN))
	card.add_theme_stylebox_override("pressed", _box(Color("#1a2d32"), Color.WHITE))
	card.add_theme_stylebox_override("focus", _box(Color("#16242a"), Color.WHITE))
	card.tooltip_text = "%s · %s · %s\n%s\n%s · 专属碎片 %d\n%s" % [
		_rating_label(rating),
		String(entry.get("display_name", "未知马桶人")),
		String(entry.get("role_copy", "玩法职责待确认")),
		String(entry.get("description", "")),
		String(entry.get("faction", "独立战术")),
		int(entry.get("fragments", 0)),
		String(entry.get("status_copy", "尚未获得设计图纸")),
	]
	var portrait := TextureRect.new()
	portrait.name = "CodexPortrait_%s" % archetype_id
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = 6
	portrait.offset_top = 5
	portrait.offset_right = -6
	portrait.offset_bottom = -5
	portrait.texture = load("res://assets/ui/codex/%s.webp" % archetype_id) as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.modulate = Color(0.18, 0.22, 0.24, 0.72) if status == "undiscovered" else Color.WHITE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)
	var state_icon := TextureRect.new()
	state_icon.name = "CodexState_%s" % archetype_id
	state_icon.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	state_icon.position = Vector2(-24, 5)
	state_icon.size = Vector2(18, 18)
	state_icon.texture = (
		CODEX_LOCK_ICON if status == "undiscovered"
		else (ROSTER_TAB_ICON if status == "blueprint_owned" else CODEX_STAR_ICON)
	)
	state_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	state_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	state_icon.modulate = MUTED if status == "undiscovered" else (CYAN if status == "blueprint_owned" else GREEN)
	state_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(state_icon)
	card.pressed.connect(_select_codex_entry.bind(archetype_id))
	return card


func _codex_focus_panel(entry: Dictionary, compact: bool) -> Control:
	var status := String(entry.get("status", "undiscovered"))
	var archetype_id := String(entry.get("archetype_id", "unknown"))
	var rating := String(entry.get("rating", "B"))
	var row := HBoxContainer.new()
	row.name = "CodexFocusPanel"
	row.custom_minimum_size.y = 82 if compact else 126
	row.add_theme_constant_override("separation", 9)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(88 if compact else 138, 82 if compact else 126)
	portrait_frame.add_theme_stylebox_override("panel", _box(
		Color("#0b1419"),
		CYAN if status == "blueprint_owned" else (GREEN if status == "researched" else LINE)
	))
	row.add_child(portrait_frame)
	var portrait := TextureRect.new()
	portrait.name = "CodexFocusPortrait_%s" % archetype_id
	portrait.texture = load("res://assets/ui/codex/%s.webp" % archetype_id) as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.modulate = Color(0.18, 0.22, 0.24, 0.72) if status == "undiscovered" else Color.WHITE
	portrait_frame.add_child(portrait)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 3)
	row.add_child(detail)
	var name := String(entry.get("display_name", "未知信号"))
	if status == "undiscovered":
		name = "未知信号"
	detail.add_child(_label(name, 18 if not compact else 15, TEXT))
	var status_copy := (
		"永久入列" if status == "researched"
		else ("图纸待研发" if status == "blueprint_owned" else "尚未发现")
	)
	detail.add_child(_label(
		"%s  ◆  %s  ◆  %s" % [
			_rating_label(rating),
			String(entry.get("role_copy", "未知职责")) if status != "undiscovered" else "信号受阻",
			status_copy,
		],
		11,
		GREEN if status == "researched" else (CYAN if status == "blueprint_owned" else MUTED)
	))
	if status != "undiscovered":
		detail.add_child(_label(String(entry.get("faction", "独立战术")), 12, GOLD))
	if status == "blueprint_owned":
		var action := _button("前往研发", true)
		action.name = "CodexResearchButton"
		action.custom_minimum_size.y = 44
		action.pressed.connect(action_requested.emit.bind("open_research", {
			"archetype_id": archetype_id,
			"recipe_id": String(entry.get("recipe_id", "")),
		}))
		detail.add_child(action)
	elif status == "researched":
		detail.add_child(_label("专属碎片  %d" % int(entry.get("fragments", 0)), 11, MUTED))
	else:
		detail.add_child(_label("继续攻城以捕获设计信号", 11, MUTED))
	return row


func _ensure_selected_codex() -> void:
	var entries := _view.get("codex", []) as Array
	if entries.is_empty():
		_selected_codex_id = ""
		return
	for entry_value in entries:
		if String((entry_value as Dictionary).get("archetype_id", "")) == _selected_codex_id:
			return
	_selected_codex_id = String((entries[0] as Dictionary).get("archetype_id", ""))


func _selected_codex_entry(entries: Array) -> Dictionary:
	for entry_value in entries:
		var entry := entry_value as Dictionary
		if String(entry.get("archetype_id", "")) == _selected_codex_id:
			return entry
	return {}


func _select_codex_entry(archetype_id: String) -> void:
	if archetype_id == _selected_codex_id:
		return
	_selected_codex_id = archetype_id
	_view["codex_focus_id"] = archetype_id
	_rebuild()


func _roster_panel() -> Control:
	var split := HBoxContainer.new()
	split.name = "RosterSplitView"
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 8)
	var roster := _view.get("roster", []) as Array

	var list_frame := PanelContainer.new()
	list_frame.name = "RosterListPanel"
	list_frame.custom_minimum_size.x = 188
	list_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_frame.add_theme_stylebox_override("panel", _box(Color("#10161c"), Color("#42525a")))
	split.add_child(list_frame)
	var list_margin := MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 6)
	list_margin.add_theme_constant_override("margin_top", 5)
	list_margin.add_theme_constant_override("margin_right", 6)
	list_margin.add_theme_constant_override("margin_bottom", 5)
	list_frame.add_child(list_margin)
	var list_column := VBoxContainer.new()
	list_column.add_theme_constant_override("separation", 4)
	list_margin.add_child(list_column)
	var list_title := HBoxContainer.new()
	list_column.add_child(list_title)
	var title := _label("角色名册", 14, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_title.add_child(title)
	list_title.add_child(_label("%d 名" % roster.size(), 10, CYAN))
	var list_scroll := ScrollContainer.new()
	list_scroll.name = "RosterHeroListScroll"
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_column.add_child(list_scroll)
	var list := VBoxContainer.new()
	list.name = "RosterHeroList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	list_scroll.add_child(list)
	_roster_hero_list = list
	for hero_value in roster:
		var hero := hero_value as Dictionary
		var hero_id := String(hero.get("hero_id", ""))
		var selected := hero_id == _selected_hero_id
		var entry := _button(
			"%s%s%s\n%d级 · %d★  战力 %d" % [
				"◆ " if selected else "",
				String(hero.get("display_name", "未知角色")),
				" · ★阵营核心" if bool(hero.get("journey_focus", false)) else "",
				int(hero.get("level", 1)),
				int(hero.get("star", 1)),
				int(hero.get("power", 0)),
			],
			selected
		)
		entry.name = "RosterHero_%s" % hero_id
		entry.custom_minimum_size = Vector2(168, 56)
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.add_theme_font_size_override("font_size", 11)
		entry.pressed.connect(_select_roster_hero.bind(hero_id))
		list.add_child(entry)

	var detail_frame := PanelContainer.new()
	detail_frame.name = "RosterDetailPanel"
	detail_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_frame.add_theme_stylebox_override("panel", _box(Color("#151c22"), Color("#53636b")))
	split.add_child(detail_frame)
	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 7)
	detail_margin.add_theme_constant_override("margin_top", 2)
	detail_margin.add_theme_constant_override("margin_right", 7)
	detail_margin.add_theme_constant_override("margin_bottom", 2)
	detail_frame.add_child(detail_margin)
	var selected_hero := _selected_hero()
	if selected_hero.is_empty():
		var empty := _panel("")
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.add_child(_label("暂无永久角色", 18, TEXT))
		empty.add_child(_label("完成角色研发后，成员会出现在这里。", 12, MUTED))
		detail_margin.add_child(empty)
	else:
		detail_margin.add_child(_hero_card(selected_hero))
	return split


func _ensure_selected_hero() -> void:
	var roster := _view.get("roster", []) as Array
	if roster.is_empty():
		_selected_hero_id = ""
		return
	for hero_value in roster:
		if String((hero_value as Dictionary).get("hero_id", "")) == _selected_hero_id:
			return
	_selected_hero_id = String((roster[0] as Dictionary).get("hero_id", ""))


func _selected_hero() -> Dictionary:
	for hero_value in _view.get("roster", []):
		var hero := hero_value as Dictionary
		if String(hero.get("hero_id", "")) == _selected_hero_id:
			return hero
	return {}


func _select_roster_hero(hero_id: String) -> void:
	if hero_id == _selected_hero_id:
		return
	_selected_hero_id = hero_id
	_view["selected_hero_id"] = hero_id
	hero_selected.emit(hero_id)
	_rebuild()


func _focus_selected_roster_hero() -> void:
	if _roster_hero_list == null or not is_instance_valid(_roster_hero_list):
		return
	var selected := _roster_hero_list.get_node_or_null(
		NodePath("RosterHero_%s" % _selected_hero_id)
	) as Button
	if selected != null and not selected.disabled:
		selected.grab_focus()


func _focus_recruit_result() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var result_panel := content.find_child("SignalRecruitResultPanel", true, false) as Control
	if result_panel == null:
		return
	var action := result_panel.find_child("RecruitFocusActionButton", true, false) as Button
	if action != null and not action.disabled:
		action.grab_focus()
	scroll.scroll_vertical = clampi(
		int(result_panel.position.y),
		0,
		int(scroll.get_v_scroll_bar().max_value)
	)


func _play_recruit_reveal() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var choice_panel := content.find_child(
		"RecruitFactionCoreChoice",
		true,
		false
	) as Control
	if choice_panel == null:
		_focus_recruit_result()
		return
	var cards: Array[Control] = []
	for choice_value in _view.get("recruit_core_choices", []):
		var choice := choice_value as Dictionary
		var card := content.find_child(
			"RecruitFactionChoiceCard_%s" % String(choice.get("archetype_id", "")),
			true,
			false
		) as Control
		if card != null:
			cards.append(card)
	choice_panel.modulate.a = 0.25
	for card in cards:
		card.modulate.a = 0.0
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.96, 0.96)
	_recruit_reveal_generation += 1
	var generation := _recruit_reveal_generation
	_recruit_reveal_tween = create_tween().set_parallel(true)
	_recruit_reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_recruit_reveal_tween.tween_property(
		choice_panel,
		"modulate:a",
		1.0,
		0.18
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for card_index in cards.size():
		var card := cards[card_index]
		var delay := 0.14 + float(card_index) * 0.18
		_recruit_reveal_tween.tween_property(
			card,
			"modulate:a",
			1.0,
			0.24
		).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_recruit_reveal_tween.tween_property(
			card,
			"scale",
			Vector2.ONE,
			0.28
		).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_recruit_reveal_tween.chain().tween_callback(func() -> void:
		if (
			generation == _recruit_reveal_generation
			and is_inside_tree()
		):
			_focus_recruit_result()
	)


func _cancel_recruit_reveal() -> void:
	_recruit_reveal_generation += 1
	if _recruit_reveal_tween != null and _recruit_reveal_tween.is_valid():
		_recruit_reveal_tween.kill()
	_recruit_reveal_tween = null


func _faction_accent(faction: String) -> Color:
	return Color(String({
		"快攻破城": "#d77b45",
		"钢铁防线": "#58c9c2",
		"远程轰炸": "#e5a84b",
		"干扰增殖": "#a979d1",
	}.get(faction, "#58c9c2")))


func _focus_faction_candidate() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	for candidate_value in _view.get("candidates", []):
		var candidate := candidate_value as Dictionary
		if not bool(candidate.get("journey_focus", false)) or bool(candidate.get("current", false)):
			continue
		var action := content.find_child(
			"FormationCandidate_%s" % String(candidate.get("hero_id", "")),
			true,
			false
		) as Button
		if action != null and not action.disabled:
			action.grab_focus()
			var candidate_panel := content.find_child(
				"FormationCandidatePanel",
				true,
				false
			) as Control
			scroll.scroll_vertical = clampi(
				int(
					(
						candidate_panel.global_position.y
						if candidate_panel != null
						else action.global_position.y
					) - content.global_position.y
				) - 4,
				0,
				int(scroll.get_v_scroll_bar().max_value)
			)
			return


func _hero_card(hero: Dictionary) -> Control:
	var panel := VBoxContainer.new()
	panel.name = "RosterHeroDetail_%s" % String(hero.get("hero_id", "unknown"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 2)

	# The roster receives about 180 px in the compact App Shell. Keep identity,
	# the two-dimensional data board and all cultivation decisions in one frame.
	var identity := HBoxContainer.new()
	identity.name = "RosterIdentityStrip"
	identity.custom_minimum_size.y = 32
	identity.add_theme_constant_override("separation", 6)
	panel.add_child(identity)
	var identity_copy := VBoxContainer.new()
	identity_copy.add_theme_constant_override("separation", -3)
	identity_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(identity_copy)
	identity_copy.add_child(_label(
		"%s%s  ·  %d级  %d★  ·  %s  ·  碎片%d" % [
			"★阵营核心 · " if bool(hero.get("journey_focus", false)) else "",
			String(hero.get("display_name", "未知角色")),
			int(hero.get("level", 1)),
			int(hero.get("star", 1)),
			String(hero.get("faction", "独立战术")),
			int(hero.get("fragment_balance", 0)),
		],
		14,
		TEXT
	))
	identity_copy.add_child(_label(
		"%s · %s · %s  |  经验 %s · 无损可出征" % [
			String(CLASS_NAMES.get(String(hero.get("class_id", "")), "未知职业")),
			_rating_label(String(hero.get("aptitude_id", "B"))),
			String(hero.get("role", "待命")),
			"上限" if int(hero.get("level", 1)) >= 5 else "%d/%d" % [
				int(hero.get("xp", 0)),
				int(hero.get("next_level_xp", 0)),
			],
		],
		10,
		CYAN
	))
	var power_card := VBoxContainer.new()
	power_card.custom_minimum_size.x = 84
	power_card.add_theme_constant_override("separation", -4)
	power_card.add_child(_label("战力", 9, MUTED))
	power_card.add_child(_label("%d" % int(hero.get("power", 0)), 17, GOLD))
	identity.add_child(power_card)

	var data_board := HBoxContainer.new()
	data_board.name = "RosterDataBoard"
	data_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	data_board.add_theme_constant_override("separation", 6)
	panel.add_child(data_board)
	var stat_board := VBoxContainer.new()
	stat_board.name = "RosterStatBoard"
	stat_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_board.add_theme_constant_override("separation", 2)
	data_board.add_child(stat_board)
	var battle_stats := hero.get("battle_stats", {}) as Dictionary
	var battle_grid := GridContainer.new()
	battle_grid.name = "RosterBattleStats"
	battle_grid.columns = 5
	battle_grid.add_theme_constant_override("h_separation", 3)
	for metric in [
		["生命", "%d" % int(battle_stats.get("hp", 0))],
		["攻击", "%d" % int(battle_stats.get("attack", 0))],
		["防御", "%d" % int(battle_stats.get("defense", 0))],
		["速度", "%.1f" % (float(battle_stats.get("speed_milli", 0)) / 1000.0)],
		["暴击", "%.1f%%" % (float(battle_stats.get("crit_bp", 0)) / 100.0)],
	]:
		battle_grid.add_child(_compact_metric(String(metric[0]), String(metric[1]), TEXT))
	stat_board.add_child(battle_grid)

	var skill_board := VBoxContainer.new()
	skill_board.name = "RosterSkillBoard"
	skill_board.custom_minimum_size.x = 210
	skill_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_board.add_theme_constant_override("separation", 1)
	data_board.add_child(skill_board)
	var skill_name := _label(
		"主动技能  %s %d级" % [
			String(hero.get("skill_name", "")),
			int(hero.get("skill_level", 1)),
		],
		10,
		CYAN
	)
	skill_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	skill_board.add_child(skill_name)
	var skill_detail := _label(
		"职责：%s\n效果：%s" % [
			String(hero.get("skill_role", "")),
			String(hero.get("skill_effect", "")),
		],
		9,
		TEXT
	)
	skill_detail.name = "RosterSkillDetail"
	skill_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_board.add_child(skill_detail)
	var skill_timing := _label(
		"最佳时机：%s" % String(hero.get("skill_timing", "")),
		9,
		GREEN
	)
	skill_timing.name = "RosterSkillTiming"
	skill_timing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_board.add_child(skill_timing)

	var cultivation := HBoxContainer.new()
	cultivation.name = "RosterCultivationBar"
	cultivation.custom_minimum_size.y = 64
	cultivation.add_theme_constant_override("separation", 4)
	panel.add_child(cultivation)
	var prioritize_star := (
		bool(hero.get("journey_focus", false))
		and bool(hero.get("star_upgrade_available", false))
	)
	_add_cultivation_action(
		cultivation,
		"升级",
		"upgrade",
		hero,
		hero.get("level_resource_context", {}) as Dictionary,
		not prioritize_star
	)
	if int(hero.get("star", 1)) < 3:
		var target_star := int(hero.get("star", 1)) + 1
		_add_cultivation_action(
			cultivation,
			"升至%d★\n解锁 · %s" % [
				target_star,
				String(hero.get("next_star_effect", "职责强化")),
			],
			"star",
			hero,
			hero.get("star_resource_context", {}) as Dictionary,
			prioritize_star
		)
	if int(hero.get("star", 1)) == 1 and int(hero.get("welfare_star_core_count", 0)) > 0:
		var welfare_core := _add_cultivation_action(
			cultivation,
			"福利升星 · 本次专属碎片全免",
			"welfare_star_core",
			hero,
			hero.get("welfare_star_resource_context", {}) as Dictionary,
			true
		)
		welfare_core.name = "WelfareStarCore_%s" % String(hero.get("hero_id", "hero"))
		welfare_core.tooltip_text = "黑金核心：本次型号专属碎片全免；工业材料不参与升星。"
	if int(hero.get("skill_level", 1)) < 3:
		var research := _add_cultivation_action(
			cultivation,
			"研究技能%d级" % (int(hero.get("skill_level", 1)) + 1),
			"skill",
			hero,
			hero.get("skill_resource_context", {}) as Dictionary,
			false
		)
		research.name = "ResearchSkill_%s" % String(hero.get("archetype_id", "hero"))
		research.disabled = (
			not bool(hero.get("skill_research_allowed", false))
			or (
				hero.has("skill_research_affordable")
				and not bool(hero.get("skill_research_affordable", false))
			)
		)
	if int(hero.get("star", 1)) >= 2:
		_add_secondary_action(
			cultivation,
			"派驻%s%s" % [
				String(hero.get("specialty_name", "")),
				" ✓" if bool(hero.get("specialty_assigned", false)) else "",
			],
			"specialist",
			hero
		)
	_add_secondary_action(
		cultivation,
		"自动技能：%s" % ("开" if bool(hero.get("auto_skill", false)) else "关"),
		"auto",
		hero
	)
	return panel


func _add_cultivation_action(
	parent: Control,
	text: String,
	action_id: String,
	hero: Dictionary,
	resource_context: Dictionary,
	primary: bool
) -> Button:
	var tile := VBoxContainer.new()
	tile.name = String(resource_context.get("name", "Cultivation_%s" % action_id))
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_constant_override("separation", 1)
	var quote := _label(_resource_projection_copy(resource_context), 9, MUTED)
	quote.name = "CultivationQuote_%s" % action_id
	quote.autowrap_mode = TextServer.AUTOWRAP_OFF
	quote.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	quote.tooltip_text = String(resource_context.get("title", ""))
	tile.add_child(quote)
	var button := _add_action(tile, text, action_id, hero, primary)
	button.name = "CultivationAction_%s" % action_id
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 10)
	var available_key: String = String({
		"upgrade": "level_upgrade_available",
		"star": "star_upgrade_available",
	}.get(action_id, ""))
	var block_key: String = String({
		"upgrade": "level_block_reason",
		"star": "star_block_reason",
	}.get(action_id, ""))
	if not available_key.is_empty():
		button.disabled = not bool(hero.get(available_key, false))
		var block_reason := String(hero.get(block_key, ""))
		if button.disabled and not block_reason.is_empty():
			quote.text = block_reason
			quote.add_theme_color_override("font_color", RED)
	parent.add_child(tile)
	return button


func _add_secondary_action(
	parent: Control,
	text: String,
	action_id: String,
	hero: Dictionary
) -> Button:
	var tile := VBoxContainer.new()
	tile.name = "SecondaryAction_%s" % action_id
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_constant_override("separation", 1)
	var context := _label("次操作", 9, MUTED)
	context.autowrap_mode = TextServer.AUTOWRAP_OFF
	tile.add_child(context)
	var button := _add_action(tile, text, action_id, hero, false)
	button.name = "RosterSecondaryAction_%s" % action_id
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 10)
	parent.add_child(tile)
	return button


func _resource_projection_copy(view: Dictionary) -> String:
	var projections: Array[String] = []
	for item_value in view.get("items", []):
		projections.append(ResourceContextHudScript.projection_copy(item_value as Dictionary))
	if projections.is_empty():
		return "当前已达上限"
	var result := " · ".join(projections)
	var note := String(view.get("note", ""))
	if not note.is_empty():
		result += " · %s" % note
	return result


func _skill_research_status(error: String) -> String:
	match error:
		"":
			return "资源已齐 · 研究后主动技能威力提高 20%"
		"RESEARCH_LAB_LEVEL_TOO_LOW":
			return "需先升级研究所"
		"NOT_ENOUGH_SKILL_CHIPS":
			return "军团数据不足 · 击败章节首领或领取长期进度"
		"NOT_ENOUGH_TOILET_COINS":
			return "金币不足 · 继续攻城获得战果"
		_:
			return "当前不可研究"


func _add_action(parent: Control, text: String, action_id: String, hero: Dictionary, primary: bool) -> Button:
	var button := _button(text, primary)
	button.pressed.connect(action_requested.emit.bind(action_id, {
		"hero_id": String(hero.get("hero_id", "")),
		"facility_id": String(hero.get("specialty_id", "")),
		"enabled": not bool(hero.get("auto_skill", false)),
	}))
	parent.add_child(button)
	return button


func _resource_context(view: Dictionary) -> Control:
	var context := ResourceContextHudScript.new() as Control
	context.call("configure", view)
	context.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return context


func _section_title(value: String) -> Label:
	var title := _label(value, 13, CYAN)
	title.add_theme_color_override("font_shadow_color", Color("#071012"))
	title.add_theme_constant_override("shadow_offset_y", 1)
	return title


func _metric(title: String, value: String, color: Color) -> Control:
	var metric := PanelContainer.new()
	metric.custom_minimum_size = Vector2(104, 48)
	metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric.add_theme_stylebox_override("panel", _box(Color("#0e1419"), Color("#344149")))
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", -2)
	metric.add_child(copy)
	copy.add_child(_label(title, 10, MUTED))
	copy.add_child(_label(value, 15, color))
	return metric


func _compact_metric(title: String, value: String, color: Color) -> Control:
	var metric := VBoxContainer.new()
	metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric.add_theme_constant_override("separation", -4)
	var title_label := _label(title, 8, MUTED)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	metric.add_child(title_label)
	var value_label := _label(value, 10, color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	metric.add_child(value_label)
	return metric


func _style_tab(button: Button, active: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	var normal := _box(PANEL_2, CYAN if active else LINE)
	var hover := _box(Color("#203039"), CYAN if active else Color("#53616a"))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", _box(PANEL_2, Color.WHITE))
	button.add_theme_color_override("font_color", CYAN if active else TEXT)
	button.add_theme_color_override("font_hover_color", CYAN if active else TEXT)
	button.add_theme_color_override("font_pressed_color", CYAN if active else TEXT)


func _configure_tool_tab(button: Button, icon: Texture2D, short_label: String, hint: String) -> void:
	button.text = short_label
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 24)
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(96, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 48
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(primary))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(primary, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(primary, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(primary, "focus"))
	button.add_theme_color_override("font_color", PANEL_2 if primary else TEXT)
	button.add_theme_color_override("font_hover_color", PANEL_2 if primary else TEXT)
	button.add_theme_color_override("font_pressed_color", PANEL_2 if primary else TEXT)
	return button


func _rating_label(rating: String) -> String:
	return String({
		"C": "基础",
		"B": "标准",
		"A": "精锐",
		"S": "传奇",
	}.get(rating, "标准"))


func _panel(title: String) -> PanelVBox:
	var panel := PanelVBox.new()
	panel.add_theme_constant_override("separation", 7)
	panel.panel_style = _box(PANEL, LINE)
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

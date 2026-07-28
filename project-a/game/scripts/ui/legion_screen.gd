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
	_ensure_selected_hero()
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	_cancel_recruit_reveal()
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
	_style_tab(codex_tab, active_tab == "codex")
	_style_tab(roster_tab, active_tab == "roster")
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
	var panel := _panel("首次战斗成长 · 冲锋/装甲二选一升至 2★ · 挑战 %s" % String(first_growth.get("target_stage", "章节 Boss")))
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
	var slot_name := String(SLOT_NAMES.get(slot_id, slot_id))
	var target_empty := _formation_slot_is_empty(slot_id)
	var journey_candidate := _journey_focus_candidate()
	var panel := _panel(
		"永久角色已入列 · %s" % String(journey_candidate.get("display_name", "阵营核心"))
		if target_empty and not journey_candidate.is_empty()
		else "%s为空 · 部署阵营核心" % slot_name
		if target_empty
		else "替换 %s · 比较职责与战力变化" % slot_name
	)
	panel.name = "FormationCandidatePanel"
	if target_empty:
		panel.add_child(_label(
			"%s · %s · 1★主动「%s」\n目标%s · 部署后%d人军团 · 接下来完成3场实战证明" % [
				String(journey_candidate.get("faction", "阵营待确认")),
				String(journey_candidate.get("playstyle", "灵活应战")),
				String(journey_candidate.get("skill_name", "待命")),
				slot_name,
				_formation_deployed_count() + 1,
			]
			if not journey_candidate.is_empty()
			else "部署后形成%d人军团 · 下一步：完成3场实战证明" % (
				_formation_deployed_count() + 1
			),
			11,
			CYAN
		))
	var candidates := GridContainer.new()
	candidates.columns = 1 if get_viewport_rect().size.x < 720.0 else 3
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
		var delta := int(candidate.get("power_delta", 0))
		var current := bool(candidate.get("current", false))
		var recommended := bool(candidate.get("recommended", false))
		var journey_focus := bool(candidate.get("journey_focus", false))
		var action := _button(
			"%s%s%s%s\n%s · 战力 %d\n军团变化 %s" % [
				String(candidate.get("display_name", "")),
				" ✓" if current else "",
				" · 推荐下一步" if recommended else "",
				" · ★%s" % String(candidate.get("journey_focus_label", "阵营核心"))
					if journey_focus
					else "",
				String(candidate.get("role", "")),
				int(candidate.get("power", 0)),
				("%+d" % delta) if delta != 0 else "不变",
			],
			(recommended or journey_focus) and not current
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
	var panel := _panel("信号招募")
	var foundational := _view.get("foundational_signal", {}) as Dictionary
	if bool(foundational.get("unlocked", false)):
		panel.add_child(_label(
			"阵营起手十连 · 真正参与 A/S 保底 · 新图纸研发角色，重复型号转专属碎片",
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
		"招募券 %d · S 图纸保底 %d/60 · 十抽至少 A · 定向保底%s" % [
			int(_view.get("recruit_tickets", 0)),
			int(_view.get("recruit_s_pity", 0)),
			"已生效" if bool(_view.get("recruit_target_guaranteed", false)) else "未触发",
		],
		14,
		GOLD
	))
	panel.add_child(_label("图纸评级 B 80% / A 18% / S 2% · 重复图纸只转该型号专属碎片", 12, MUTED))
	panel.add_child(_label("定向 S：寄生母体设计图 · 十抽至少出现一张 A 级或更高图纸", 12, TEXT))
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
		var core_choices := _view.get("recruit_core_choices", []) as Array
		var result_panel := _panel(
			"" if not core_choices.is_empty() else "本次信号响应"
		)
		result_panel.name = "SignalRecruitResultPanel"
		if not core_choices.is_empty():
			var reward_summary := _view.get("recruit_reward_summary", {}) as Dictionary
			var choice_panel := _panel(
				"十连战果已锁定 · 新角色图纸 %d · 专属碎片 +%d" % [
					int(reward_summary.get("new_blueprints", 0)),
					int(reward_summary.get("fragment_total", 0)),
				]
			)
			choice_panel.name = "RecruitFactionCoreChoice"
			var journey := _label(
				"两套2★路线均已就绪 · 选定后：研发 → 入队 → 3场实战 → 质变突破",
				12,
				CYAN
			)
			journey.name = "RecruitFactionJourneyPromise"
			choice_panel.add_child(journey)
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
				card.add_child(_label(
					"新角色设计 · %s级 · %s · %s\n%s · 2★%s（碎片已齐）" % [
						String(choice.get("rating", "B")),
						String(choice.get("display_name", "")),
						String(choice.get("faction", "")),
						String(choice.get("synergy_summary", "")),
						String(choice.get("next_star_effect", "")),
					],
					12,
					GOLD
				))
				var choose := _button(
					"选择%s · %s" % [
						String(choice.get("display_name", "")),
						String(choice.get("playstyle", "")),
					],
					true
				)
				choose.name = "ChooseFactionCore_%s" % String(
					choice.get("archetype_id", "")
				)
				choose.custom_minimum_size.y = 48
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
				"2★质变：%s" % String(focus.get("next_star_effect", "")),
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
				bonus_copy = "\n60抽保底 · S级%s%s" % [
					String(pity_bonus.get("display_name", "")),
					(
						"碎片 +%d" % int(pity_bonus.get("amount", 0))
						if String(pity_bonus.get("kind", "")) == "hero_fragments"
						else "新图纸"
					),
				]
			var card := _label(
				"%s · %s\n%s%s" % [
					rarity,
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


func _codex_panel() -> Control:
	var panel := _panel("马桶角色图鉴")
	panel.name = "ToiletRoleCodex"
	panel.add_child(_label(
		"B / A / S 为当前三档角色评级；图纸来自信号招募，永久角色只在研究所完成研发。",
		13,
		CYAN
	))
	var grid := GridContainer.new()
	grid.name = "ToiletRoleCodexGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for entry_value in _view.get("codex", []):
		var entry := entry_value as Dictionary
		var rating := String(entry.get("rating", "B"))
		var status := String(entry.get("status", "undiscovered"))
		var rating_color := GOLD if rating == "S" else (CYAN if rating == "A" else GREEN)
		var card := _panel("")
		card.name = "Codex_%s" % String(entry.get("archetype_id", "unknown"))
		card.custom_minimum_size = Vector2(330, 88)
		card.add_child(_label(
			"%s 评级 · %s" % [rating, String(entry.get("display_name", "未知马桶人"))],
			16,
			rating_color
		))
		card.add_child(_label(String(entry.get("description", "")), 11, TEXT))
		card.add_child(_label(
			"%s · 专属碎片 %d" % [
				String(entry.get("faction", "独立战术")),
				int(entry.get("fragments", 0)),
			],
			11,
			GOLD
		))
		card.add_child(_label(
			String(entry.get("status_copy", "尚未获得设计图纸")),
			12,
			GREEN if status == "researched" else (CYAN if status == "blueprint_owned" else MUTED)
		))
		grid.add_child(card)
	panel.add_child(grid)
	return panel


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
			"%s%s%s\nLv.%d · %d★  战力 %d" % [
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
	if action == null:
		for choice_value in _view.get("recruit_core_choices", []):
			action = result_panel.find_child(
				"ChooseFactionCore_%s" % String(
					(choice_value as Dictionary).get("archetype_id", "")
				),
				true,
				false
			) as Button
			if action != null:
				break
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
		"%s%s  ·  Lv.%d  %d★  ·  %s  ·  碎片%d" % [
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
		"%s · %s评级 · %s  |  经验 %s · 无损可出征" % [
			String(CLASS_NAMES.get(String(hero.get("class_id", "")), "未知职业")),
			String(hero.get("aptitude_id", "?")),
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
		"主动技能  %s Lv.%d" % [
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
				String(hero.get("next_star_effect", "职责质变")),
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
			"研究技能 Lv.%d" % (int(hero.get("skill_level", 1)) + 1),
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
			return "军团数据不足 · 击败章节 Boss 或领取长期进度"
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
	button.add_theme_stylebox_override("normal", _box(Color("#244546") if active else PANEL_2, CYAN if active else LINE))
	button.add_theme_stylebox_override("hover", _box(Color("#315a5b"), CYAN))
	button.add_theme_stylebox_override("pressed", _box(Color("#17383a"), CYAN))
	button.add_theme_stylebox_override("focus", _box(Color("#17383a"), Color.WHITE))


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 48
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _box(Color("#244546") if primary else PANEL_2, CYAN if primary else LINE))
	button.add_theme_stylebox_override("hover", _box(Color("#315a5b"), CYAN))
	button.add_theme_stylebox_override("pressed", _box(Color("#17383a"), CYAN))
	button.add_theme_stylebox_override("focus", _box(Color("#17383a"), Color.WHITE))
	return button


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

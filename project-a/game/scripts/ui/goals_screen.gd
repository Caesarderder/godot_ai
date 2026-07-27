class_name GoalsScreen
extends VBoxContainer

class GoalPanel:
	extends VBoxContainer

	var panel_style: StyleBox

	func _draw() -> void:
		if panel_style != null:
			panel_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

signal tab_selected(tab_id: String)
signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const NotificationBadgeScript := preload(
	"res://game/scripts/presentation/notification_badge.gd"
)
const PANEL := Color("#12171c")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")

@onready var commander_host: VBoxContainer = %CommanderHost
@onready var content: VBoxContainer = %Content
@onready var scroll: ScrollContainer = %GoalsContentScroll
@onready var action_tab: Button = %MetaGoalsActionTab
@onready var pass_tab: Button = %MetaGoalsPassTab
@onready var achievements_tab: Button = %MetaGoalsAchievementsTab

var _view: Dictionary = {}
var _tab_badges: Dictionary = {}


func _ready() -> void:
	action_tab.pressed.connect(tab_selected.emit.bind("action"))
	pass_tab.pressed.connect(tab_selected.emit.bind("pass"))
	achievements_tab.pressed.connect(tab_selected.emit.bind("achievements"))
	_tab_badges = {
		"action": _add_badge(action_tab, "ActionNotificationBadge"),
		"pass": _add_badge(pass_tab, "PassNotificationBadge"),
		"achievements": _add_badge(achievements_tab, "AchievementsNotificationBadge"),
	}
	_style_tab(action_tab, true)
	_style_tab(pass_tab, false)
	_style_tab(achievements_tab, false)
	if not _view.is_empty():
		_rebuild()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	var active_tab := String(_view.get("tab", "action"))
	var notification_counts := _view.get("notification_counts", {}) as Dictionary
	(_tab_badges["action"] as NotificationBadge).set_count(
		int(notification_counts.get("goals_action", 0))
	)
	(_tab_badges["pass"] as NotificationBadge).set_count(
		int(notification_counts.get("goals_pass", 0))
	)
	(_tab_badges["achievements"] as NotificationBadge).set_count(
		int(notification_counts.get("goals_achievements", 0))
	)
	action_tab.button_pressed = active_tab == "action"
	pass_tab.button_pressed = active_tab == "pass"
	achievements_tab.button_pressed = active_tab == "achievements"
	_style_tab(action_tab, action_tab.button_pressed)
	_style_tab(pass_tab, pass_tab.button_pressed)
	_style_tab(achievements_tab, achievements_tab.button_pressed)
	_clear(commander_host)
	_clear(content)
	if active_tab != "action":
		commander_host.add_child(_commander_panel(_view.get("commander", {}) as Dictionary))
	match active_tab:
		"pass":
			_build_pass()
		"achievements":
			_build_achievements()
		_:
			_build_action()


func _build_action() -> void:
	content.add_child(_goal_hierarchy(_view.get("hierarchy", {}) as Dictionary))
	content.add_child(_starter_gifts_panel(_view.get("starter_gifts", {}) as Dictionary))
	content.add_child(_new_player_welfare_panel(
		_view.get("new_player_welfare", {}) as Dictionary
	))
	content.add_child(_campaign_panel(_view.get("campaign", {}) as Dictionary))
	if bool(_view.get("missions_unlocked", false)):
		content.add_child(_mission_panel())
	else:
		content.add_child(_lock_panel(_view.get("mission_lock", {}) as Dictionary))


func _starter_gifts_panel(view: Dictionary) -> Control:
	var panel := _panel("限时补给 · 分段解锁")
	panel.name = "StarterGiftsPanel"
	for gift_value in view.get("gifts", []):
		var gift := gift_value as Dictionary
		var gift_id := String(gift.get("gift_id", ""))
		panel.add_child(_label(
			"%s · %s\n%s" % [
				String(gift.get("title", "")),
				String(gift.get("reward_copy", "")),
				String(gift.get("reason_copy", "")),
			],
			13,
			GOLD if bool(gift.get("claimable", false)) else MUTED
		))
		var button_copy := "已领取"
		if not bool(gift.get("unlocked", false)):
			button_copy = String(gift.get("unlock_copy", "尚未解锁"))
		elif bool(gift.get("claimable", false)):
			button_copy = "立即领取"
		var claim := _button(button_copy, bool(gift.get("claimable", false)))
		claim.name = "StarterGift_%s" % gift_id
		claim.disabled = not bool(gift.get("claimable", false))
		claim.pressed.connect(action_requested.emit.bind(
			"claim_starter_gift",
			{"gift_id": gift_id}
		))
		panel.add_child(claim)
	return panel


func _new_player_welfare_panel(view: Dictionary) -> Control:
	var panel := _panel("开服庆典礼包 · 黑市援助")
	panel.name = "NewPlayerWelfarePanel"
	if not bool(view.get("unlocked", false)):
		panel.add_child(_label("完成第一章 1-5 后解锁 · 不提前跳过新兵训练", 13, MUTED))
		var locked := _button("首章完成后可领取", false)
		locked.name = "NewPlayerWelfareClaimButton"
		locked.disabled = true
		panel.add_child(locked)
		return panel
	if bool(view.get("claimable", false)):
		panel.add_child(_label(
			"黑金升星核心 ×1 · 走私后勤箱 ×1\n核心可替代一星角色升二星所需的英雄数据；工业材料不参与角色升星。",
			13,
			GOLD
		))
		var claim := _button("领取开服庆典礼包", true)
		claim.name = "NewPlayerWelfareClaimButton"
		claim.pressed.connect(action_requested.emit.bind("claim_new_player_welfare", {}))
		panel.add_child(claim)
		return panel
	panel.add_child(_label(
		"黑金升星核心 ×%d · 走私后勤箱 ×%d" % [
			int(view.get("star_core_count", 0)),
			int(view.get("logistics_case_count", 0)),
		],
		14,
		GREEN
	))
	if bool(view.get("case_openable", false)):
		var open_case := _button("开启走私后勤箱 · 获得 18/10/8 工业材料", true)
		open_case.name = "SmuggledLogisticsCaseButton"
		open_case.pressed.connect(action_requested.emit.bind("open_smuggled_logistics_case", {}))
		panel.add_child(open_case)
	elif bool(view.get("case_opened", false)):
		panel.add_child(_label("走私后勤箱已开启 · 工业材料已入库", 13, GREEN))
	if int(view.get("star_core_count", 0)) > 0:
		var legion := _button("去军团使用黑金核心", false)
		legion.name = "NewPlayerWelfareLegionButton"
		legion.pressed.connect(action_requested.emit.bind("open_legion_for_welfare", {}))
		panel.add_child(legion)
	return panel


func _goal_hierarchy(view: Dictionary) -> Control:
	var panel := _panel("")
	panel.name = "GoalHierarchyPanel"
	panel.add_child(_label("大目标 · %s" % String(view.get("macro", "")), 17, GOLD))
	panel.add_child(_label("中目标 · %s" % String(view.get("medium", "")), 15, CYAN))
	panel.add_child(_label("小目标 · %s" % String(view.get("small", "")), 14, TEXT))
	var hurdle := view.get("hurdle", {}) as Dictionary
	if not hurdle.is_empty():
		var hurdle_copy := _label(
			"%s · %s  →  过坎：%s" % [
				String(hurdle.get("scale", "当前坎")),
				String(hurdle.get("title", "")),
				String(hurdle.get("recovery", "")),
			],
			12,
			GREEN
		)
		hurdle_copy.name = "CurrentHurdlePanel"
		hurdle_copy.tooltip_text = String(hurdle.get("reason", ""))
		panel.add_child(hurdle_copy)
	if bool(view.get("actionable", not bool(view.get("finished", false)))):
		var cta := _button(String(view.get("cta_label", "继续")), true)
		cta.name = "GoalHierarchyPrimaryCTA"
		cta.pressed.connect(action_requested.emit.bind("follow_task", {
			"target": String(view.get("target", "expedition")),
			"stage_id": String(view.get("stage_id", "")),
		}))
		panel.add_child(cta)
	return panel


func _campaign_panel(view: Dictionary) -> Control:
	var panel := _panel("五章攻城进度")
	panel.add_child(_label("已占领 %d/25 座城镇" % int(view.get("cleared", 0)), 17, GOLD))
	panel.add_child(_progress(float(view.get("cleared", 0)), 25.0, CYAN))
	panel.add_child(_label(String(view.get("chapters_copy", "")), 13, TEXT))
	var map_button := _button("前往战区", false)
	map_button.pressed.connect(action_requested.emit.bind("open_map", {}))
	panel.add_child(map_button)
	return panel


func _mission_panel() -> Control:
	var panel := _panel("行动任务 · 每日与每周")
	for mission_value in _view.get("missions", []):
		var mission := mission_value as Dictionary
		if bool(mission.get("weekly_heading", false)):
			panel.add_child(_label("每周行动", 15, CYAN))
			continue
		panel.add_child(_mission_row(mission))
	if not bool(_view.get("weekly_unlocked", false)):
		panel.add_child(_label("周任务将在指挥官 Lv10 开放", 13, MUTED))
	return panel


func _mission_row(view: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var claimed := bool(view.get("claimed", false))
	var copy := _label(
		"%s  %d/%d" % [
			String(view.get("title", "")),
			int(view.get("progress", 0)),
			int(view.get("target", 1)),
		],
		14,
		GREEN if claimed else TEXT
	)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var claim := _button("已领取" if claimed else "领取", false)
	claim.disabled = claimed or not bool(view.get("complete", false))
	claim.pressed.connect(action_requested.emit.bind("claim_mission", {
		"mission_id": String(view.get("mission_id", "")),
		"generation": int(view.get("generation", 0)),
	}))
	row.add_child(claim)
	return row


func _build_pass() -> void:
	if not bool(_view.get("pass_unlocked", false)):
		content.add_child(_lock_panel(_view.get("pass_lock", {}) as Dictionary))
		return
	var pass_view := _view.get("pass", {}) as Dictionary
	var panel := _panel("免费战役战令 · %d/30" % int(pass_view.get("reached", 0)))
	panel.add_child(_label(
		"%d / 3000 战功 · 赛季结束不重置英雄、工厂或招募保底" % int(pass_view.get("merit", 0)),
		13,
		MUTED
	))
	panel.add_child(_progress(float(pass_view.get("merit", 0)), 3000.0, GOLD))
	var claimable := int(pass_view.get("claimable", 0))
	if claimable > 0:
		var batch := _button("一键领取 %d 项奖励" % claimable, true)
		batch.pressed.connect(action_requested.emit.bind("claim_all_pass", {}))
		panel.add_child(batch)
	else:
		panel.add_child(_label("当前已达等级奖励均已领取", 13, GREEN))
	var track := GridContainer.new()
	track.name = "MetaPassRewardTrack"
	track.columns = 3
	track.add_theme_constant_override("h_separation", 6)
	track.add_theme_constant_override("v_separation", 6)
	for level_value in pass_view.get("levels", []):
		var level := level_value as Dictionary
		var card := _button(
			"Lv%d%s\n%s" % [
				int(level.get("level", 0)),
				" ✓" if bool(level.get("claimed", false)) else "",
				_reward_copy(level.get("reward", {}) as Dictionary),
			],
			bool(level.get("claimable", false))
		)
		card.name = "MetaPassLevel_%d" % int(level.get("level", 0))
		card.disabled = not bool(level.get("claimable", false))
		card.custom_minimum_size = Vector2(205, 66)
		card.pressed.connect(action_requested.emit.bind("claim_pass_level", {
			"level": int(level.get("level", 0)),
		}))
		track.add_child(card)
	panel.add_child(track)
	content.add_child(panel)


func _build_achievements() -> void:
	if not bool(_view.get("achievements_unlocked", false)):
		content.add_child(_lock_panel(_view.get("achievement_lock", {}) as Dictionary))
		return
	var panel := _panel("永久成就")
	var claimable := int(_view.get("achievement_claimable", 0))
	if claimable > 0:
		var batch := _button("一键领取 %d 项成就" % claimable, true)
		batch.pressed.connect(action_requested.emit.bind("claim_all_achievements", {}))
		panel.add_child(batch)
	for value in _view.get("achievements", []):
		var achievement := value as Dictionary
		var row := HBoxContainer.new()
		var claimed := bool(achievement.get("claimed", false))
		var copy := _label(
			"%s  %d/%d" % [
				String(achievement.get("title", "")),
				int(achievement.get("progress", 0)),
				int(achievement.get("target", 1)),
			],
			14,
			GREEN if claimed else TEXT
		)
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		var claim := _button("已领取" if claimed else "领取", false)
		claim.disabled = claimed or not bool(achievement.get("complete", false))
		claim.pressed.connect(action_requested.emit.bind("claim_achievement", {
			"achievement_id": String(achievement.get("achievement_id", "")),
		}))
		row.add_child(claim)
		panel.add_child(row)
	content.add_child(panel)


func _commander_panel(view: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "CommanderProgressPanel"
	panel.add_theme_stylebox_override("panel", _box(Color(PANEL, 0.94), 8, LINE))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var summary := VBoxContainer.new()
	summary.custom_minimum_size.x = 170
	summary.add_child(_label("指挥官 Lv%d" % int(view.get("level", 1)), 16, GOLD))
	summary.add_child(_label(
		"%d / %d XP" % [int(view.get("xp", 0)), int(view.get("next_xp", 0))],
		11,
		MUTED
	))
	row.add_child(summary)
	var progress := _progress(float(view.get("xp", 0)), float(view.get("next_xp", 1)), CYAN)
	progress.custom_minimum_size = Vector2(220, 12)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(progress)
	var claimable := int(view.get("claimable", 0))
	if claimable > 0:
		var claim := _button("领取 %d 项等级奖励" % claimable, true)
		claim.custom_minimum_size.x = 190
		claim.pressed.connect(action_requested.emit.bind("claim_all_commander", {}))
		row.add_child(claim)
	else:
		row.add_child(_label("奖励已领取", 13, GREEN))
	return panel


func _lock_panel(view: Dictionary) -> Control:
	var panel := _panel("%s · 尚未解锁" % String(view.get("title", "")))
	panel.add_child(_label(
		"双条件进度：指挥官 Lv%d/%d · %s %s" % [
			int(view.get("level", 1)),
			int(view.get("required_level", 1)),
			String(view.get("stage_copy", "")),
			"✓" if bool(view.get("stage_complete", false)) else "未完成",
		],
		14,
		GOLD
	))
	panel.add_child(_label("继续完成当前行动与攻城，两项都满足后自动开放。", 13, MUTED))
	return panel


func _reward_copy(reward: Dictionary) -> String:
	var parts: Array[String] = []
	for pair in [
		["toilet_coins", "金币"], ["porcelain", "工业材料"],
		["recruit_tickets", "招募券"], ["hero_shards", "军团数据"],
	]:
		var amount := int(reward.get(String(pair[0]), 0))
		if amount > 0:
			parts.append("%s%d" % [String(pair[1]), amount])
	return " · ".join(parts)


func _panel(title: String) -> VBoxContainer:
	var box := GoalPanel.new()
	box.panel_style = _box(Color(PANEL, 0.94), 6, LINE)
	box.add_theme_constant_override("separation", 6)
	if not title.is_empty():
		box.add_child(_label(title, 17, GOLD))
	return box


func _button(copy: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = copy
	button.custom_minimum_size.y = 48
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override(
		"normal",
		_box(Color("#d89d3f") if primary else Color("#1a2228"), 6, GOLD if primary else LINE)
	)
	button.add_theme_stylebox_override(
		"hover",
		_box(Color("#e5aa4c") if primary else Color("#263139"), 6, GOLD)
	)
	button.add_theme_stylebox_override(
		"focus",
		_box(Color("#5b421e") if primary else Color("#263139"), 6, Color.WHITE)
	)
	button.add_theme_color_override("font_color", Color("#14110c") if primary else TEXT)
	return button


func _add_badge(button: Button, badge_name: String) -> NotificationBadge:
	var badge := NotificationBadgeScript.new() as NotificationBadge
	badge.name = badge_name
	button.add_child(badge)
	return badge


func _label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_override("font", CJK_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _progress(value: float, maximum: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maxf(1.0, maximum)
	bar.value = value
	bar.custom_minimum_size.y = 10
	bar.add_theme_stylebox_override("background", _box(Color("#071014"), 4, LINE))
	bar.add_theme_stylebox_override("fill", _box(color, 4, color))
	return bar


func _style_tab(button: Button, active: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override(
		"normal",
		_box(Color("#c5903d") if active else Color("#1a2228"), 6, GOLD if active else LINE)
	)
	button.add_theme_stylebox_override(
		"focus",
		_box(Color("#5b421e") if active else Color("#263139"), 6, Color.WHITE)
	)
	button.add_theme_color_override("font_color", Color("#181109") if active else TEXT)


func _box(color: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

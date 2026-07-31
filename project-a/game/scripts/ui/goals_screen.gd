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
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const ICON_CHAPTER := preload("res://assets/ui/goals/chapter_stronghold.webp")
const ICON_OPERATION := preload("res://assets/ui/goals/current_operation.webp")
const ICON_HURDLE := preload("res://assets/ui/goals/wall_hurdle.webp")
const ICON_SUPPLY := preload("res://assets/ui/goals/supply_crate.webp")
const ICON_REWARD_GOLD := preload("res://assets/ui/battle_result/loot_coin.webp")
const ICON_REWARD_DATA := preload("res://assets/ui/battle_result/legion_data.webp")
const ICON_ACHIEVEMENT_FORTRESS := preload(
	"res://assets/ui/achievements/captured_fortress.webp"
)
const ICON_ACHIEVEMENT_CAMPAIGN := preload(
	"res://assets/ui/achievements/campaign_network.webp"
)
const ICON_ACHIEVEMENT_BATTLE := preload(
	"res://assets/ui/achievements/battle_mastery.webp"
)
const ICON_ACHIEVEMENT_FACTORY := preload(
	"res://assets/ui/achievements/factory_mastery.webp"
)
const ICON_COMMANDER_RANK := preload(
	"res://assets/ui/achievements/commander_rank.webp"
)
const ICON_ACHIEVEMENT_LOCK := preload(
	"res://assets/ui/achievements/classified_lock.webp"
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
	action_tab.icon = ICON_OPERATION
	pass_tab.icon = ICON_SUPPLY
	achievements_tab.icon = ICON_ACHIEVEMENT_FORTRESS
	for tab in [action_tab, pass_tab, achievements_tab]:
		tab.expand_icon = true
		tab.add_theme_constant_override("icon_max_width", 28)
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
	var compact := bool(_view.get("compact", false))
	for tab in [action_tab, pass_tab, achievements_tab]:
		tab.custom_minimum_size = Vector2(92 if compact else 124, 48)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	content.add_child(_goal_hierarchy(
		_view.get("hierarchy", {}) as Dictionary,
		_view.get("campaign", {}) as Dictionary
	))
	content.add_child(_action_reward_rail(
		_view.get("starter_gifts", {}) as Dictionary,
		_view.get("new_player_welfare", {}) as Dictionary,
		bool(_view.get("missions_unlocked", false))
	))


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
		var case_reward := view.get("case_reward", {}) as Dictionary
		var open_case := _button(
			"开启走私后勤箱 · 获得 %d 工业材料" % int(case_reward.get("porcelain", 0)),
			true
		)
		open_case.name = "SmuggledLogisticsCaseButton"
		open_case.pressed.connect(action_requested.emit.bind("open_smuggled_logistics_case", {}))
		panel.add_child(open_case)
	elif bool(view.get("case_opened", false)):
		panel.add_child(_label("走私后勤箱已开启 · 工业材料已入库", 13, GREEN))
	if int(view.get("star_core_count", 0)) > 0:
		var recommended_name := String(view.get("recommended_hero_name", "一星首章援军"))
		panel.add_child(_label(
			"推荐补齐：%s → 2★ · 保证基础三人职责完整，再由十连核心形成阵营差异。" % recommended_name,
			13,
			CYAN
		))
		var legion := _button("为%s使用黑金核心" % recommended_name, true)
		legion.name = "NewPlayerWelfareLegionButton"
		legion.pressed.connect(action_requested.emit.bind("open_legion_for_welfare", {
			"hero_id": String(view.get("recommended_hero_id", "")),
		}))
		panel.add_child(legion)
	return panel


func _goal_hierarchy(view: Dictionary, campaign: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "GoalHierarchyPanel"
	panel.add_theme_stylebox_override("panel", UiArtDirectionScript.panel_style(true))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)
	var milestone := String(view.get("milestone", ""))
	if not milestone.is_empty():
		var milestone_copy := _label("✓ %s" % milestone, 12, GREEN)
		milestone_copy.name = "GoalMilestoneBanner"
		layout.add_child(milestone_copy)
	var route := HBoxContainer.new()
	route.name = "CampaignRoute"
	route.add_theme_constant_override("separation", 10)
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(route)
	var compact := bool(_view.get("compact", false))
	var campaign_semantics := _label(
		"已占领 %d/60 座城镇" % int(campaign.get("cleared", 0)),
		11,
		GREEN
	)
	campaign_semantics.name = "CampaignProgressSemantics"
	campaign_semantics.visible = false
	layout.add_child(campaign_semantics)
	var chapter := VBoxContainer.new()
	chapter.custom_minimum_size.x = 68 if compact else 84
	chapter.add_theme_constant_override("separation", 0)
	route.add_child(chapter)
	var chapter_icon := TextureRect.new()
	chapter_icon.texture = ICON_CHAPTER
	chapter_icon.custom_minimum_size = Vector2(52 if compact else 64, 52 if compact else 64)
	chapter_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chapter_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chapter.add_child(chapter_icon)
	var chapter_copy := _label("第1章 · %d/5" % mini(int(campaign.get("cleared", 0)), 5), 11, GREEN)
	chapter_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_child(chapter_copy)
	var hurdle := view.get("hurdle", {}) as Dictionary
	var objective := HBoxContainer.new()
	objective.name = "CurrentObjectivePanel"
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.add_theme_constant_override("separation", 8)
	route.add_child(objective)
	var objective_icon := TextureRect.new()
	objective_icon.texture = ICON_HURDLE
	objective_icon.custom_minimum_size = Vector2(66 if compact else 78, 66 if compact else 78)
	objective_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	objective_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	objective.add_child(objective_icon)
	var objective_copy := VBoxContainer.new()
	objective_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_copy.custom_minimum_size.x = 0
	objective_copy.add_theme_constant_override("separation", 1)
	objective.add_child(objective_copy)
	objective_copy.add_child(_label("当前关口", 11, GOLD))
	var short_title := String(hurdle.get("title", view.get("small", ""))).replace(" E10", "")
	var objective_title := _label(short_title, 16 if compact else 20, TEXT)
	objective_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	objective_copy.add_child(objective_title)
	var operation_copy := _label(String(view.get("medium", "")), 11 if compact else 12, CYAN)
	operation_copy.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	operation_copy.autowrap_mode = TextServer.AUTOWRAP_OFF
	objective_copy.add_child(operation_copy)
	var recovery := String(hurdle.get("recovery", ""))
	if not recovery.is_empty():
		var recovery_copy := _label(recovery, 10 if compact else 11, GREEN)
		recovery_copy.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		recovery_copy.autowrap_mode = TextServer.AUTOWRAP_OFF
		recovery_copy.tooltip_text = "%s · %s" % [String(hurdle.get("reason", "")), recovery]
		recovery_copy.visible = not compact
		objective_copy.add_child(recovery_copy)
	var action_column := VBoxContainer.new()
	action_column.custom_minimum_size.x = 170 if compact else 214
	action_column.add_theme_constant_override("separation", 3)
	route.add_child(action_column)
	var medium_copy := _label("中目标 · %s" % String(view.get("medium", "")), 12, CYAN)
	medium_copy.visible = false
	action_column.add_child(medium_copy)
	var small_copy := _label("小目标 · %s" % String(view.get("small", "")), 11, TEXT)
	small_copy.visible = false
	action_column.add_child(small_copy)
	var macro_copy := _label("大目标 · %s" % String(view.get("macro", "")), 11, MUTED)
	macro_copy.visible = false
	action_column.add_child(macro_copy)
	var proof_focus := String(view.get("proof_focus", ""))
	if not proof_focus.is_empty():
		var focus_copy := _label(proof_focus, 12, CYAN)
		focus_copy.name = "GoalProofFocus"
		action_column.add_child(focus_copy)
	if not hurdle.is_empty():
		var full_hurdle_copy := "%s · %s\n过坎：%s" % [
			String(hurdle.get("scale", "当前坎")),
			String(hurdle.get("title", "")),
			String(hurdle.get("recovery", "")),
		]
		var hurdle_copy := _label(
			full_hurdle_copy,
			11,
			GREEN
		)
		hurdle_copy.name = "CurrentHurdlePanel"
		hurdle_copy.tooltip_text = String(hurdle.get("reason", ""))
		hurdle_copy.visible = false
		action_column.add_child(hurdle_copy)
		var recovery_semantics := _label("过坎：%s" % recovery, 11, GREEN)
		recovery_semantics.visible = false
		action_column.add_child(recovery_semantics)
	if bool(view.get("actionable", not bool(view.get("finished", false)))):
		var cta := _button(String(view.get("cta_label", "继续")), true)
		cta.name = "GoalHierarchyPrimaryCTA"
		cta.icon = ICON_HURDLE
		cta.expand_icon = true
		cta.custom_minimum_size = Vector2(170 if compact else 214, 60)
		cta.pressed.connect(action_requested.emit.bind("follow_task", {
			"target": String(view.get("target", "expedition")),
			"stage_id": String(view.get("stage_id", "")),
			"hero_id": String(view.get("hero_id", "")),
			"archetype_id": String(view.get("archetype_id", "")),
		}))
		action_column.add_child(cta)
	return panel


func _route_node(icon_texture: Texture2D, title: String, state: String, color: Color) -> Control:
	var node := VBoxContainer.new()
	node.custom_minimum_size.x = 64
	node.add_theme_constant_override("separation", 1)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.add_child(icon)
	var title_label := _label(title, 12, color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(title_label)
	var state_label := _label(state, 10, MUTED)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(state_label)
	return node


func _route_connector(color: Color) -> Control:
	var connector := ColorRect.new()
	connector.name = "CampaignRouteConnector"
	connector.color = color.darkened(0.35)
	connector.custom_minimum_size = Vector2(20, 3)
	connector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	connector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return connector


func _action_reward_rail(
	starter_view: Dictionary,
	welfare: Dictionary,
	missions_unlocked: bool
) -> Control:
	var panel := PanelContainer.new()
	panel.name = "ActionRewardRail"
	panel.add_theme_stylebox_override("panel", UiArtDirectionScript.panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = ICON_SUPPLY
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label := _label("战果", 12, GOLD)
	label.custom_minimum_size.x = 42
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var welfare_active := bool(welfare.get("unlocked", false)) and (
		bool(welfare.get("claimable", false))
		or bool(welfare.get("case_openable", false))
		or int(welfare.get("star_core_count", 0)) > 0
	)
	var has_claimable := false
	for gift_value in starter_view.get("gifts", []):
		if welfare_active:
			break
		var gift := gift_value as Dictionary
		var gift_id := String(gift.get("gift_id", ""))
		var claimable := bool(gift.get("claimable", false))
		if not claimable and gift_id != "rookie_departure_v1":
			continue
		has_claimable = has_claimable or claimable
		var claim_copy := String(gift.get("unlock_copy", "未解锁"))
		if claimable:
			claim_copy = "领取 · %s" % String(gift.get("reward_copy", ""))
		if claimable:
			var claim := _button(claim_copy, true)
			claim.name = "StarterGift_%s" % gift_id
			claim.icon = ICON_REWARD_GOLD
			claim.expand_icon = true
			claim.custom_minimum_size = Vector2(190, 52)
			claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			claim.pressed.connect(action_requested.emit.bind("claim_starter_gift", {"gift_id": gift_id}))
			row.add_child(claim)
		else:
			var preview := _label(String(gift.get("reward_copy", "金币 ×30")), 13, MUTED)
			preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			preview.tooltip_text = claim_copy
			row.add_child(preview)
	if not has_claimable and not missions_unlocked:
		var mission_lock := HBoxContainer.new()
		mission_lock.name = "MissionLockBadge"
		mission_lock.custom_minimum_size.x = 62
		mission_lock.add_theme_constant_override("separation", 4)
		var lock_icon := TextureRect.new()
		lock_icon.texture = ICON_ACHIEVEMENT_LOCK
		lock_icon.custom_minimum_size = Vector2(28, 28)
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mission_lock.add_child(lock_icon)
		var lock_copy := _label("Lv2", 11, MUTED)
		lock_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_copy.autowrap_mode = TextServer.AUTOWRAP_OFF
		lock_copy.tooltip_text = "行动任务将在指挥官 2 级开放"
		mission_lock.add_child(lock_copy)
		row.add_child(mission_lock)
	# Keep exactly one visible welfare step in the reward rail. This turns the
	# chapter handoff into a player-operable chain instead of hidden semantics.
	var welfare_semantics := _welfare_compact_button(welfare)
	welfare_semantics.visible = welfare_active and not welfare_semantics.disabled
	welfare_semantics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(welfare_semantics)
	return panel


func _welfare_compact_button(view: Dictionary) -> Button:
	var button: Button
	if not bool(view.get("unlocked", false)):
		button = _button("庆典 · 首章后开放", false)
		button.name = "NewPlayerWelfareClaimButton"
		button.disabled = true
	elif bool(view.get("claimable", false)):
		button = _button("领取庆典补给", false)
		button.name = "NewPlayerWelfareClaimButton"
		button.pressed.connect(action_requested.emit.bind("claim_new_player_welfare", {}))
	elif bool(view.get("case_openable", false)):
		var porcelain := int((view.get("case_reward", {}) as Dictionary).get("porcelain", 0))
		button = _button("开启后勤箱 · %d材料" % porcelain, false)
		button.name = "SmuggledLogisticsCaseButton"
		button.pressed.connect(action_requested.emit.bind("open_smuggled_logistics_case", {}))
	elif int(view.get("star_core_count", 0)) > 0:
		var recommended_name := String(view.get("recommended_hero_name", "首章援军"))
		button = _button("核心强化 · %s" % recommended_name, true)
		button.name = "NewPlayerWelfareLegionButton"
		button.pressed.connect(action_requested.emit.bind("open_legion_for_welfare", {
			"hero_id": String(view.get("recommended_hero_id", "")),
		}))
	elif bool(view.get("case_opened", false)):
		button = _button("走私后勤箱已开启", false)
		button.name = "NewPlayerWelfareClaimButton"
		button.disabled = true
	else:
		button = _button("庆典补给已结清", false)
		button.name = "NewPlayerWelfareClaimButton"
		button.disabled = true
	return button


func _campaign_panel(view: Dictionary) -> Control:
	var panel := _panel("五章攻城进度")
	panel.add_child(_label("已占领 %d/60 座城镇" % int(view.get("cleared", 0)), 17, GOLD))
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
		panel.add_child(_label("周任务将在指挥官10级开放", 13, MUTED))
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
	var panel := _panel("")
	panel.name = "BattlePassRewardRunway"
	var overview := HBoxContainer.new()
	overview.add_theme_constant_override("separation", 8)
	panel.add_child(overview)
	var pass_icon := TextureRect.new()
	pass_icon.texture = ICON_SUPPLY
	pass_icon.custom_minimum_size = Vector2(48, 48)
	pass_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pass_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overview.add_child(pass_icon)
	var summary := VBoxContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("separation", 3)
	var pass_title := _label(
		"战役补给线 · %d/30" % int(pass_view.get("reached", 0)),
		17,
		TEXT
	)
	pass_title.tooltip_text = "免费战役战令 · 赛季结束不重置永久成长"
	summary.add_child(pass_title)
	var merit_copy := _label(
		"%d / 3000 战功" % int(pass_view.get("merit", 0)),
		11,
		CYAN
	)
	summary.add_child(merit_copy)
	summary.add_child(_progress(float(pass_view.get("merit", 0)), 3000.0, GOLD))
	overview.add_child(summary)
	var claimable := int(pass_view.get("claimable", 0))
	if claimable > 0:
		var batch := _button("领取 ×%d" % claimable, true)
		batch.name = "MetaPassBatchClaim"
		batch.icon = ICON_SUPPLY
		batch.expand_icon = true
		batch.custom_minimum_size.x = 154
		batch.tooltip_text = "一键领取 %d 项奖励" % claimable
		batch.pressed.connect(action_requested.emit.bind("claim_all_pass", {}))
		overview.add_child(batch)
	else:
		var settled := _label("当前奖励已领取", 12, GREEN)
		settled.custom_minimum_size.x = 150
		settled.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		overview.add_child(settled)
	var runway_scroll := ScrollContainer.new()
	runway_scroll.name = "BattlePassRunwayScroll"
	runway_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	runway_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	runway_scroll.custom_minimum_size.y = 96
	runway_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(runway_scroll)
	var track := HBoxContainer.new()
	track.name = "MetaPassRewardTrack"
	track.add_theme_constant_override("h_separation", 5)
	track.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var compact := bool(_view.get("compact", false))
	var short_screen := bool(_view.get("short", false))
	for level_value in pass_view.get("levels", []):
		var level := level_value as Dictionary
		var reward := level.get("reward", {}) as Dictionary
		var level_number := int(level.get("level", 0))
		var claimed := bool(level.get("claimed", false))
		var claimable_level := bool(level.get("claimable", false))
		var current := level_number == int(pass_view.get("reached", 0))
		var status_mark := "✓" if claimed else ("领取" if claimable_level else "🔒")
		if current:
			status_mark = "◆%s" % status_mark
		var card := _button(
			"%02d\n%s  ×%d" % [
				level_number,
				status_mark,
				_pass_reward_amount(reward),
			],
			false
		)
		card.name = "MetaPassLevel_%d" % level_number
		card.icon = _pass_reward_icon(reward)
		card.expand_icon = true
		card.add_theme_constant_override("icon_max_width", 42)
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.disabled = not claimable_level
		card.custom_minimum_size = Vector2(
			86 if compact else 104,
			76 if short_screen else 88
		)
		card.tooltip_text = "%d级%s · %s · %s" % [
			level_number,
			" · 当前" if current else "",
			_reward_copy(reward),
			"已领取" if claimed else ("可领取" if claimable_level else "未到达"),
		]
		if claimed:
			card.modulate = Color(0.68, 0.82, 0.82, 0.76)
		elif claimable_level:
			card.add_theme_stylebox_override(
				"normal",
				UiArtDirectionScript.button_style(true)
			)
			card.add_theme_color_override("font_color", Color("#14110c"))
		card.pressed.connect(action_requested.emit.bind("claim_pass_level", {
			"level": level_number,
		}))
		track.add_child(card)
	runway_scroll.add_child(track)
	var frontier := maxi(0, int(pass_view.get("reached", 0)) - 2)
	call_deferred("_focus_pass_frontier", runway_scroll, frontier, 86 if compact else 104)
	content.add_child(panel)


func _focus_pass_frontier(runway_scroll: ScrollContainer, frontier: int, card_width: int) -> void:
	if not is_instance_valid(runway_scroll):
		return
	await get_tree().process_frame
	runway_scroll.scroll_horizontal = frontier * (card_width + 5)


func _pass_reward_icon(reward: Dictionary) -> Texture2D:
	if int(reward.get("recruit_tickets", 0)) > 0:
		return ICON_SUPPLY
	if int(reward.get("hero_shards", 0)) > 0:
		return ICON_REWARD_DATA
	if int(reward.get("porcelain", 0)) > 0:
		return ICON_ACHIEVEMENT_FACTORY
	return ICON_REWARD_GOLD


func _pass_reward_amount(reward: Dictionary) -> int:
	for key in ["recruit_tickets", "hero_shards", "porcelain", "toilet_coins"]:
		var amount := int(reward.get(key, 0))
		if amount > 0:
			return amount
	return 0


func _build_achievements() -> void:
	if not bool(_view.get("achievements_unlocked", false)):
		content.add_child(_achievement_lock_panel(
			_view.get("achievement_lock", {}) as Dictionary
		))
		return
	var panel := _panel("")
	panel.name = "AchievementMedalWall"
	var claimable := int(_view.get("achievement_claimable", 0))
	var compact := bool(_view.get("compact", false))
	var overview := HBoxContainer.new()
	overview.add_theme_constant_override("separation", 8)
	overview.custom_minimum_size.y = 48
	overview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var collection_icon := TextureRect.new()
	collection_icon.texture = ICON_ACHIEVEMENT_CAMPAIGN
	collection_icon.custom_minimum_size = Vector2(40, 40)
	collection_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	collection_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overview.add_child(collection_icon)
	var title := _label("荣誉柜", 15, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size.x = 72
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.tooltip_text = "永久成就 · 不随赛季重置"
	overview.add_child(title)
	var overview_state := _label("", 11, CYAN)
	overview_state.custom_minimum_size.x = 88
	overview_state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overview_state.autowrap_mode = TextServer.AUTOWRAP_OFF
	overview.add_child(overview_state)
	if claimable > 0:
		var batch := _button("领取 ×%d" % claimable, true)
		batch.name = "AchievementBatchClaim"
		batch.icon = ICON_ACHIEVEMENT_FORTRESS
		batch.expand_icon = true
		batch.custom_minimum_size = Vector2(126 if compact else 154, 48)
		batch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		batch.tooltip_text = "一键领取 %d 项成就" % claimable
		batch.pressed.connect(action_requested.emit.bind("claim_all_achievements", {}))
		overview.add_child(batch)
	else:
		var count := (_view.get("achievements", []) as Array).size()
		var settled := _label("%d 枚" % count, 12, GREEN)
		settled.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		overview.add_child(settled)
	panel.add_child(overview)
	var cabinet := HBoxContainer.new()
	cabinet.name = "AchievementMedalCabinet"
	cabinet.add_theme_constant_override("separation", 5 if compact else 8)
	cabinet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabinet.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.add_child(cabinet)
	var detail_semantics := Control.new()
	detail_semantics.name = "AchievementSelectedDetail"
	detail_semantics.visible = false
	panel.add_child(detail_semantics)
	var selected_achievement: Dictionary = {}
	for value in _view.get("achievements", []):
		var candidate := value as Dictionary
		if selected_achievement.is_empty():
			selected_achievement = candidate
		if bool(candidate.get("complete", false)) and not bool(candidate.get("claimed", false)):
			selected_achievement = candidate
			break
	if not selected_achievement.is_empty():
		_select_achievement_detail(collection_icon, title, overview_state, selected_achievement)
	for value in _view.get("achievements", []):
		var achievement := value as Dictionary
		var claimed := bool(achievement.get("claimed", false))
		var complete := bool(achievement.get("complete", false))
		var status_copy := "已领取" if claimed else ("可领取" if complete else "进行中")
		var status_mark := "✓" if claimed else ("!" if complete else "%d/%d" % [
			int(achievement.get("progress", 0)), int(achievement.get("target", 1))
		])
		var progress := int(achievement.get("progress", 0))
		var target := int(achievement.get("target", 1))
		var medal_slot := VBoxContainer.new()
		medal_slot.custom_minimum_size.x = 76 if compact else 98
		medal_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		medal_slot.add_theme_constant_override("separation", 0)
		cabinet.add_child(medal_slot)
		var card := _button(status_mark, false)
		card.name = "Achievement_%s" % String(
			achievement.get("achievement_id", "")
		).replace(".", "_")
		card.icon = _achievement_icon(String(achievement.get("achievement_id", "")))
		card.expand_icon = true
		card.add_theme_constant_override("icon_max_width", 50 if compact else 62)
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.custom_minimum_size = Vector2(64, 64 if compact else 74)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = "%s · %d/%d · %s" % [
			String(achievement.get("title", "")),
			progress,
			target,
			status_copy,
		]
		card.add_theme_font_size_override("font_size", 11)
		if claimed:
			card.modulate = Color(0.72, 0.82, 0.82, 0.78)
		elif complete:
			card.add_theme_stylebox_override(
				"normal",
				UiArtDirectionScript.button_style(true)
			)
			card.add_theme_color_override("font_color", Color("#14110c"))
		if complete and not claimed:
			card.pressed.connect(action_requested.emit.bind("claim_achievement", {
				"achievement_id": String(achievement.get("achievement_id", "")),
			}))
		else:
			card.pressed.connect(_select_achievement_detail.bind(
				collection_icon,
				title,
				overview_state,
				achievement
			))
		medal_slot.add_child(card)
	content.add_child(panel)


func _achievement_lock_panel(view: Dictionary) -> Control:
	var compact := bool(_view.get("compact", false))
	var panel := _panel("")
	panel.name = "AchievementLockedCabinet"
	var overview := HBoxContainer.new()
	overview.custom_minimum_size.y = 52
	overview.add_theme_constant_override("separation", 8)
	panel.add_child(overview)
	var lock_icon := TextureRect.new()
	lock_icon.texture = ICON_ACHIEVEMENT_LOCK
	lock_icon.custom_minimum_size = Vector2(48, 48)
	lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overview.add_child(lock_icon)
	var lock_title := _label("荣誉柜封存", 16, GOLD)
	lock_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overview.add_child(lock_title)
	var requirements := HBoxContainer.new()
	requirements.name = "AchievementUnlockRequirements"
	requirements.add_theme_constant_override("separation", 6)
	overview.add_child(requirements)
	requirements.add_child(_achievement_requirement(
		ICON_COMMANDER_RANK,
		"LV %d/%d" % [int(view.get("level", 1)), int(view.get("required_level", 1))],
		int(view.get("level", 1)) >= int(view.get("required_level", 1)),
		compact
	))
	requirements.add_child(_achievement_requirement(
		ICON_ACHIEVEMENT_FORTRESS,
		"1-2 %s" % ("✓" if bool(view.get("stage_complete", false)) else "✕"),
		bool(view.get("stage_complete", false)),
		compact
	))
	var cabinet := HBoxContainer.new()
	cabinet.name = "AchievementLockedMedalCabinet"
	cabinet.add_theme_constant_override("separation", 5 if compact else 8)
	cabinet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(cabinet)
	var locked_icons: Array[Texture2D] = [
		ICON_ACHIEVEMENT_FORTRESS,
		ICON_ACHIEVEMENT_FACTORY,
		ICON_ACHIEVEMENT_CAMPAIGN,
		ICON_ACHIEVEMENT_BATTLE,
		ICON_COMMANDER_RANK,
		ICON_ACHIEVEMENT_CAMPAIGN,
	]
	for medal_icon in locked_icons:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(76 if compact else 98, 66 if compact else 76)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", UiArtDirectionScript.button_style(false))
		var emblem := TextureRect.new()
		emblem.texture = medal_icon
		emblem.modulate = Color(0.28, 0.34, 0.35, 0.52)
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(emblem)
		var seal := _label("⌁", 19, MUTED)
		seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(seal)
		cabinet.add_child(slot)
	return panel


func _achievement_requirement(
	icon_texture: Texture2D,
	copy: String,
	complete: bool,
	compact: bool
) -> Control:
	var badge := HBoxContainer.new()
	badge.custom_minimum_size = Vector2(84 if compact else 104, 44)
	badge.add_theme_constant_override("separation", 3)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if complete else Color(0.68, 0.68, 0.68, 0.8)
	badge.add_child(icon)
	var label := _label(copy, 11, GREEN if complete else MUTED)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.add_child(label)
	return badge


func _select_achievement_detail(
	icon: TextureRect,
	title: Label,
	state: Label,
	achievement: Dictionary
) -> void:
	var claimed := bool(achievement.get("claimed", false))
	var complete := bool(achievement.get("complete", false))
	icon.texture = _achievement_icon(String(achievement.get("achievement_id", "")))
	title.text = String(achievement.get("title", ""))
	state.text = "%d/%d · %s" % [
		int(achievement.get("progress", 0)),
		int(achievement.get("target", 1)),
		"已领取" if claimed else ("可领取" if complete else "进行中"),
	]
	state.add_theme_color_override("font_color", GREEN if claimed else (GOLD if complete else CYAN))


func _achievement_icon(achievement_id: String) -> Texture2D:
	if achievement_id.begins_with("meta.factory"):
		return ICON_ACHIEVEMENT_FACTORY
	if achievement_id.begins_with("meta.legion"):
		return ICON_ACHIEVEMENT_BATTLE
	if achievement_id.begins_with("meta.repair"):
		return ICON_COMMANDER_RANK
	if achievement_id.begins_with("meta.collection"):
		return ICON_ACHIEVEMENT_CAMPAIGN
	if achievement_id == "meta.campaign.first":
		return ICON_ACHIEVEMENT_FORTRESS
	if achievement_id.begins_with("meta.campaign"):
		return ICON_ACHIEVEMENT_CAMPAIGN
	return ICON_ACHIEVEMENT_LOCK


func _commander_panel(view: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "CommanderProgressPanel"
	panel.add_theme_stylebox_override("panel", UiArtDirectionScript.panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var rank_icon := TextureRect.new()
	rank_icon.texture = ICON_COMMANDER_RANK
	rank_icon.custom_minimum_size = Vector2(48, 48)
	rank_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rank_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(rank_icon)
	var summary := VBoxContainer.new()
	summary.custom_minimum_size.x = 116
	summary.add_child(_label("LV.%d 指挥官" % int(view.get("level", 1)), 15, CYAN))
	summary.add_child(_label(
		"经验 %d / %d" % [int(view.get("xp", 0)), int(view.get("next_xp", 0))],
		11,
		MUTED
	))
	row.add_child(summary)
	var progress := _progress(float(view.get("xp", 0)), float(view.get("next_xp", 1)), CYAN)
	progress.custom_minimum_size = Vector2(180, 10)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(progress)
	var claimable := int(view.get("claimable", 0))
	if claimable > 0:
		var claim := _button("领取 %d 项等级奖励" % claimable, false)
		claim.custom_minimum_size.x = 185
		claim.pressed.connect(action_requested.emit.bind("claim_all_commander", {}))
		row.add_child(claim)
	else:
		var settled := _label("奖励已领取", 13, GREEN)
		settled.name = "CommanderRewardsSettledSemantics"
		settled.visible = false
		row.add_child(settled)
	return panel


func _lock_panel(view: Dictionary) -> Control:
	var panel := _panel("%s · 尚未解锁" % String(view.get("title", "")))
	panel.add_child(_label(
		"双条件进度：指挥官%d/%d级 · %s %s" % [
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
	box.panel_style = UiArtDirectionScript.panel_style()
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
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(primary))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(primary, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(primary, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(primary, "focus"))
	button.add_theme_stylebox_override("disabled", UiArtDirectionScript.button_style(false))
	button.add_theme_color_override("font_color", Color("#14110c") if primary else TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED)
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
		UiArtDirectionScript.button_style(false, "focus" if active else "normal")
	)
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(false, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(false, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(false, "focus"))
	button.add_theme_color_override("font_color", CYAN if active else TEXT)


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

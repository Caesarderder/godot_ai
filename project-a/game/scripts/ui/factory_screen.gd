class_name FactoryScreen
extends Control

signal panel_selected(panel_id: String)
signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const NotificationBadgeScript := preload(
	"res://game/scripts/presentation/notification_badge.gd"
)
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const RED := Color("#d95c4f")
const GREEN := Color("#78b982")

@onready var resource_hud: PanelContainer = %FactoryResourceHUD
@onready var resource_row: HBoxContainer = %FactoryResourceRow
@onready var hud_frame: PanelContainer = %FactoryHudFrame
@onready var panel_host: VBoxContainer = %FactoryHudPanelHost
@onready var mission_tab: Button = %FactoryHudMissionTab
@onready var facility_tab: Button = %FactoryHudFacilityTab
@onready var build_tab: Button = %FactoryHudBuildTab

var _view: Dictionary = {}
var _facility_badge: NotificationBadge


func _ready() -> void:
	_facility_badge = NotificationBadgeScript.new() as NotificationBadge
	_facility_badge.name = "FactoryFacilityNotificationBadge"
	facility_tab.add_child(_facility_badge)
	mission_tab.pressed.connect(panel_selected.emit.bind("mission"))
	facility_tab.pressed.connect(panel_selected.emit.bind("facility"))
	build_tab.pressed.connect(panel_selected.emit.bind("build"))
	_apply_shell_style()
	if not _view.is_empty():
		_rebuild()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		var notification_counts := _view.get("notification_counts", {}) as Dictionary
		_facility_badge.set_count(int(notification_counts.get("factory_work_ready", 0)))
		_rebuild()


func _rebuild() -> void:
	var compact := bool(_view.get("compact", false))
	hud_frame.custom_minimum_size.x = 258 if compact else 286
	_apply_shell_style()
	_build_resources(compact)
	_clear(panel_host)
	var active_panel := String(_view.get("panel", "mission"))
	mission_tab.button_pressed = active_panel == "mission"
	facility_tab.button_pressed = active_panel == "facility"
	build_tab.button_pressed = active_panel == "build"
	match active_panel:
		"facility":
			panel_host.add_child(_facility_panel())
		"build":
			panel_host.add_child(_construction_panel())
		_:
			panel_host.add_child(_mission_panel())


func _build_resources(compact: bool) -> void:
	_clear(resource_row)
	var heading := VBoxContainer.new()
	heading.custom_minimum_size.x = 56 if compact else 76
	var heading_label := _label("后勤" if compact else "后勤库存 · 全员无损", 14, TEXT)
	heading_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(heading_label)
	resource_row.add_child(heading)
	for resource_value in _view.get("resources", []):
		resource_row.add_child(_resource_meter(resource_value as Dictionary, compact))
	var claim := _button("收取" if compact else "全部收取", true)
	claim.name = "ClaimFactoryOutputButton"
	claim.custom_minimum_size = Vector2(76 if compact else 112, 48)
	claim.pressed.connect(action_requested.emit.bind("claim_output", {}))
	resource_row.add_child(claim)


func _resource_meter(resource: Dictionary, compact: bool) -> Control:
	var block := VBoxContainer.new()
	block.custom_minimum_size.x = 66 if compact else 104
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line := HBoxContainer.new()
	var name_label := _label(
		String(resource.get("name", "")).left(1) if compact else String(resource.get("name", "")),
		11 if compact else 12,
		TEXT
	)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(name_label)
	var value := _label(
		"%d/%d" % [int(resource.get("current", 0)), int(resource.get("capacity", 0))],
		10 if compact else 12,
		RED if bool(resource.get("full", false)) else GOLD
	)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(value)
	block.add_child(line)
	var bar := ProgressBar.new()
	bar.name = "ResourceMeter_%s" % String(resource.get("name", ""))
	bar.show_percentage = false
	bar.max_value = maxi(1, int(resource.get("capacity", 1)))
	bar.value = int(resource.get("current", 0))
	bar.custom_minimum_size.y = 6
	_set_progress_fill(bar, RED if bool(resource.get("full", false)) else CYAN)
	block.add_child(bar)
	if not compact:
		var rate_label := _label(
			"+%.1f/分 · %s" % [float(resource.get("rate", 0.0)), String(resource.get("status", ""))],
			9,
			RED if bool(resource.get("full", false)) else MUTED
		)
		rate_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		rate_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		block.add_child(rate_label)
	return block


func _mission_panel() -> Control:
	var task := _view.get("task", {}) as Dictionary
	var panel := _panel("前线来电")
	panel.name = "OnboardingMissionPanel"
	var title := _label(String(task.get("title", "战线暂时平静")), 15, GOLD)
	title.max_lines_visible = 1
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(title)
	var objectives := task.get("objectives", []) as Array
	if not objectives.is_empty():
		var objective := objectives[0] as Dictionary
		panel.add_child(_label(
			"%s %s" % ["◆" if bool(objective.get("completed", false)) else "◇", String(objective.get("label", ""))],
			11,
			MUTED if bool(objective.get("completed", false)) else TEXT
		))
	var actions := HBoxContainer.new()
	var primary := _button(String(task.get("cta_label", "继续")), true)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if bool(task.get("completed", false)) and not bool(task.get("claimed", false)):
		primary.pressed.connect(action_requested.emit.bind("claim_task", {}))
	else:
		primary.pressed.connect(action_requested.emit.bind("follow_task", {
			"target": String(task.get("target", "map")),
			"stage_id": String(task.get("stage_id", "")),
			"hero_id": String(task.get("hero_id", "")),
			"archetype_id": String(task.get("archetype_id", "")),
		}))
	actions.add_child(primary)
	var intelligence := _button("战况", false)
	intelligence.name = "OpenWarIntelligenceButton"
	intelligence.custom_minimum_size.x = 72
	intelligence.pressed.connect(action_requested.emit.bind("intelligence", {}))
	actions.add_child(intelligence)
	panel.add_child(actions)
	return panel


func _construction_panel() -> Control:
	var construction := _view.get("construction", {}) as Dictionary
	var focused_growth := bool(construction.get("focused_growth", false))
	var active_id := String(construction.get("active_id", ""))
	var panel_title := "选择首座资源设施" if focused_growth else "网格建造"
	# Placement already has an active Build tab and a three-step guide. Avoiding
	# a repeated title keeps its primary confirmation inside the 390 px viewport.
	var panel := _panel("" if not active_id.is_empty() else panel_title)
	panel.name = "ConstructionPanel"
	var guide := _label("① 选建筑  →  ② 点地图格子  →  ③ 确认", 11, MUTED if active_id.is_empty() else CYAN)
	guide.name = "ConstructionStepGuide"
	panel.add_child(guide)
	if active_id.is_empty():
		var recovery_gift := construction.get("recovery_gift", {}) as Dictionary
		if not recovery_gift.is_empty():
			panel.add_child(_label(
				"工业支援待领取\n%s · %s\n%s" % [
					String(recovery_gift.get("title", "新游补给礼包")),
					String(recovery_gift.get("reward_copy", "")),
					String(recovery_gift.get("reason_copy", "")),
				],
				13,
				GOLD
			))
			var claim_gift := _button("领取补给并继续选址", true)
			claim_gift.name = "ClaimFactoryRecoveryGift"
			claim_gift.pressed.connect(action_requested.emit.bind(
				"claim_starter_gift",
				{"gift_id": String(recovery_gift.get("gift_id", ""))}
			))
			panel.add_child(claim_gift)
			return panel
		var choices := GridContainer.new()
		choices.name = "ConstructionButtonGrid"
		choices.columns = 2
		for option_value in construction.get("options", []):
			var option := option_value as Dictionary
			var choose := _button(
				"%s · %s · %d秒%s" % [
					String(option.get("name", "")),
					String(option.get("cost_copy", "")),
					int(option.get("build_seconds", 5)),
					"\n%s" % String(option.get("growth_copy", "")) if focused_growth else "",
				],
				false
			)
			choose.name = "ChooseFacility_%s" % String(option.get("facility_id", ""))
			choose.disabled = bool(option.get("disabled", false))
			choose.tooltip_text = String(option.get("copy", ""))
			if focused_growth:
				choose.custom_minimum_size.y = 54
			choose.pressed.connect(action_requested.emit.bind("begin_construction", {
				"facility_id": String(option.get("facility_id", "")),
			}))
			choices.add_child(choose)
		if choices.get_child_count() == 0:
			panel.add_child(_label("所有设施均已建成", 13, GREEN))
		else:
			panel.add_child(choices)
		return panel
	panel.add_child(_label("正在放置：%s" % String(construction.get("active_name", "")), 13, CYAN))
	panel.add_child(_label(String(construction.get("active_copy", "")), 12, TEXT))
	panel.add_child(_label(
		"建造费用：%s · 耗时 %d 秒（确认后扣除）" % [
			String(construction.get("cost_copy", "")),
			int(construction.get("build_seconds", 5)),
		],
		12,
		GOLD
	))
	panel.add_child(_label(String(construction.get("placement_copy", "")), 12, TEXT))
	var actions := HBoxContainer.new()
	actions.name = "ConstructionActions"
	actions.add_theme_constant_override("separation", 6)
	var confirm := _button("确认建造", true)
	confirm.name = "ConfirmFacilityConstruction"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.disabled = not bool(construction.get("can_confirm", false))
	confirm.pressed.connect(action_requested.emit.bind("confirm_construction", {}))
	actions.add_child(confirm)
	var cancel := _button("取消", false)
	cancel.name = "CancelFacilityConstruction"
	cancel.custom_minimum_size.x = 76
	cancel.pressed.connect(action_requested.emit.bind("cancel_construction", {}))
	actions.add_child(cancel)
	panel.add_child(actions)
	if bool(construction.get("occupied", false)):
		panel.add_child(_label("该格子已有建筑，请换一个位置。", 12, RED))
	return panel


func _facility_panel() -> Control:
	var facility := _view.get("facility", {}) as Dictionary
	var level := int(facility.get("level", 0))
	var title := "%s · %d级" % [String(facility.get("name", "")), level] if level > 0 else "空地块 · %s" % String(facility.get("name", ""))
	var panel := _panel(title)
	panel.name = "SelectedFacilityPanel"
	panel.add_child(_label(String(facility.get("copy", "")), 13, MUTED))
	var work := facility.get("work", {}) as Dictionary
	if not work.is_empty():
		panel.add_child(_label(String(work.get("status", "")), 12, CYAN))
		var claim := _button(
				"启用建筑"
			if bool(work.get("ready", false))
			else "施工中 · %d秒" % int(work.get("remaining_seconds", 0)),
			true
		)
		claim.name = "ClaimFacilityWork"
		claim.disabled = not bool(work.get("ready", false))
		claim.pressed.connect(action_requested.emit.bind("claim_work", {}))
		panel.add_child(claim)
		if bool(work.get("blocks_panel", false)):
			return panel
	if level <= 0:
		var eligible := bool(facility.get("eligible", false))
		panel.add_child(_label("待建设" if eligible else "尚未取得建造资格", 13, GOLD if eligible else MUTED))
		if not eligible:
			panel.add_child(_label(String(facility.get("eligibility_copy", "")), 13, TEXT))
			return panel
		panel.add_child(_label("建造费用：%s" % String(facility.get("build_cost_copy", "")), 14, GOLD))
		var construct := _button("选择%s并放置" % String(facility.get("name", "")), true)
		construct.name = "ConstructFacility_%s" % String(facility.get("facility_id", ""))
		construct.disabled = not bool(facility.get("can_build", false))
		construct.pressed.connect(action_requested.emit.bind("begin_construction", {
			"facility_id": String(facility.get("facility_id", "")),
		}))
		panel.add_child(construct)
		if not bool(facility.get("enough_materials", false)):
			panel.add_child(_label("工业材料不足；先收取对应资源设施产出。", 12, RED))
		return panel
	var kind := String(facility.get("kind", "global"))
	match kind:
		"resource":
			panel.add_child(_label(
				"已储存 %s × %d" % [String(facility.get("resource_name", "")), int(facility.get("output", 0))],
				15,
				GOLD
			))
			var can_collect := bool(facility.get("can_collect", int(facility.get("output", 0)) > 0))
			var collect := _button(
				"收取%s" % String(facility.get("resource_name", ""))
				if can_collect
				else "暂无可收取",
				can_collect
			)
			collect.name = "Collect_%s" % String(facility.get("facility_id", ""))
			collect.disabled = not can_collect
			collect.pressed.connect(action_requested.emit.bind("claim_facility_output", {
				"facility_id": String(facility.get("facility_id", "")),
			}))
			panel.add_child(collect)
		"training":
			panel.add_child(_label("训练增益 · 角色升级与升星的长期投资中心", 14, GOLD))
			var roster := _button("进入角色培养", true)
			roster.pressed.connect(action_requested.emit.bind("legion", {}))
			panel.add_child(roster)
		"research":
			panel.add_child(_label("科技蓝图将战场情报转成永久援军。", 13, GOLD))
			var blueprints := _button("进入科技蓝图", true)
			blueprints.name = "EnterBlueprintTree"
			blueprints.pressed.connect(action_requested.emit.bind("blueprints", {}))
			panel.add_child(blueprints)
		_:
			panel.add_child(_label("升级后强化工厂运营与全局容量。", 14, GOLD))
	if level < 3:
		panel.add_child(_label(String(facility.get("upgrade_cost_copy", "")), 12, TEXT))
		panel.add_child(_label(String(facility.get("upgrade_preview", "")), 12, GREEN))
	var upgrade := _button("升级建筑", false)
	upgrade.disabled = not bool(facility.get("can_upgrade", false))
	upgrade.pressed.connect(action_requested.emit.bind("upgrade_facility", {
		"facility_id": String(facility.get("facility_id", "")),
	}))
	panel.add_child(upgrade)
	return panel


func _apply_shell_style() -> void:
	var resource_style := _box(Color(PANEL, 0.74), Color(CYAN, 0.24), 10)
	resource_style.set_border_width_all(1)
	resource_hud.add_theme_stylebox_override("panel", resource_style)
	hud_frame.add_theme_stylebox_override("panel", _box(Color(PANEL, 0.88), Color(CYAN, 0.35), 10))
	for button: Button in [mission_tab, facility_tab, build_tab]:
		_style_button(button, button.button_pressed)


func _panel(title: String) -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 6)
	if not title.is_empty():
		panel.add_child(_label(title, 16, CYAN))
	return panel


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 48
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 13)
	_style_button(button, primary)
	return button


func _style_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _box(Color("#244546") if primary else PANEL_2, CYAN if primary else LINE, 7))
	button.add_theme_stylebox_override("hover", _box(Color("#315a5b"), CYAN, 7))
	button.add_theme_stylebox_override("pressed", _box(Color("#17383a"), CYAN, 7))
	button.add_theme_stylebox_override("focus", _box(Color("#17383a"), Color.WHITE, 7))


func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", CJK_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _set_progress_fill(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#252f36")
	background.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)


func _box(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()

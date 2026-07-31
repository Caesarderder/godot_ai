class_name FactoryScreen
extends Control

signal panel_selected(panel_id: String)
signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const NotificationBadgeScript := preload(
	"res://game/scripts/presentation/notification_badge.gd"
)
const FACTORY_FACILITY_ICON := preload("res://assets/ui/icons/factory/factory-facility-v1.png")
const FACTORY_BUILD_ICON := preload("res://assets/ui/icons/factory/factory-build-v1.png")
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
@onready var tool_rail: VBoxContainer = %FactoryToolRail
@onready var mission_tab: Button = %FactoryHudMissionTab
@onready var facility_tab: Button = %FactoryHudFacilityTab
@onready var build_tab: Button = %FactoryHudBuildTab

var _view: Dictionary = {}
var _facility_badge: NotificationBadge


func _ready() -> void:
	_facility_badge = NotificationBadgeScript.new() as NotificationBadge
	_facility_badge.name = "FactoryFacilityNotificationBadge"
	tool_rail.get_parent().add_child(_facility_badge)
	facility_tab.icon = FACTORY_FACILITY_ICON
	build_tab.icon = FACTORY_BUILD_ICON
	for icon_button: Button in [facility_tab, build_tab]:
		icon_button.expand_icon = true
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
	var active_panel := String(_view.get("panel", "mission"))
	var construction := _view.get("construction", {}) as Dictionary
	var placement_active := (
		active_panel == "build"
		and not String(construction.get("active_id", "")).is_empty()
	)
	tool_rail.visible = not placement_active
	_facility_badge.visible = _facility_badge.visible and not placement_active
	mission_tab.visible = active_panel != "mission"
	mission_tab.text = "×"
	mission_tab.tooltip_text = "关闭面板"
	facility_tab.text = ""
	facility_tab.tooltip_text = "设施详情"
	build_tab.text = ""
	build_tab.tooltip_text = "建设建筑"
	_apply_responsive_layout(compact, active_panel, placement_active)
	_apply_shell_style()
	_build_resources(compact)
	_clear(panel_host)
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


func _apply_responsive_layout(compact: bool, active_panel: String, placement_active: bool) -> void:
	resource_hud.offset_right = 218.0 if compact else 282.0
	tool_rail.offset_left = -54.0 if compact else -58.0
	tool_rail.offset_right = -6.0 if compact else -8.0
	tool_rail.offset_top = 62.0 if compact else 66.0
	_facility_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_facility_badge.offset_left = -28.0
	_facility_badge.offset_top = tool_rail.offset_top - 10.0
	_facility_badge.offset_right = 0.0
	_facility_badge.offset_bottom = tool_rail.offset_top + 18.0
	var mission_mode := active_panel == "mission"
	var build_mode := active_panel == "build"
	if build_mode:
		hud_frame.anchor_left = 1.0 if placement_active else 0.5
		hud_frame.anchor_top = 1.0
		hud_frame.anchor_right = 1.0 if placement_active else 0.5
		hud_frame.anchor_bottom = 1.0
		hud_frame.grow_horizontal = Control.GROW_DIRECTION_BEGIN if placement_active else Control.GROW_DIRECTION_BOTH
		hud_frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
		hud_frame.custom_minimum_size.x = (290.0 if compact else 330.0) if placement_active else (508.0 if compact else 640.0)
		hud_frame.offset_left = (-298.0 if compact else -342.0) if placement_active else (-254.0 if compact else -320.0)
		hud_frame.offset_right = -8.0 if placement_active else (254.0 if compact else 320.0)
		hud_frame.offset_top = -104.0 if placement_active else -112.0
		hud_frame.offset_bottom = -8.0
	else:
		hud_frame.anchor_left = 0.0 if mission_mode else 1.0
		hud_frame.anchor_top = 0.0
		hud_frame.anchor_right = 0.0 if mission_mode else 1.0
		hud_frame.anchor_bottom = 0.0
		hud_frame.grow_horizontal = Control.GROW_DIRECTION_END if mission_mode else Control.GROW_DIRECTION_BEGIN
		hud_frame.grow_vertical = Control.GROW_DIRECTION_END
		hud_frame.custom_minimum_size.x = (176.0 if compact else 194.0) if mission_mode else (246.0 if compact else 274.0)
		hud_frame.offset_left = 8.0 if mission_mode else (-306.0 if compact else -340.0)
		hud_frame.offset_right = (184.0 if compact else 202.0) if mission_mode else -64.0
		hud_frame.offset_top = 76.0 if mission_mode else 62.0
		hud_frame.offset_bottom = hud_frame.offset_top
	if active_panel == "mission":
		hud_frame.custom_minimum_size.y = 94.0
	elif active_panel == "facility":
		hud_frame.custom_minimum_size.y = 184.0
	else:
		hud_frame.custom_minimum_size.y = 92.0 if placement_active else 104.0


func _build_resources(compact: bool) -> void:
	_clear(resource_row)
	var heading := VBoxContainer.new()
	heading.custom_minimum_size.x = 52 if compact else 62
	var heading_label := _label("后勤", 14, TEXT)
	heading_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(heading_label)
	resource_row.add_child(heading)
	for resource_value in _view.get("resources", []):
		resource_row.add_child(_resource_meter(resource_value as Dictionary, compact))
	var claim := _button("↧", false)
	claim.name = "ClaimFactoryOutputButton"
	claim.tooltip_text = "收取全部工厂产出"
	claim.custom_minimum_size = Vector2(48, 48)
	claim.pressed.connect(action_requested.emit.bind("claim_output", {}))
	resource_row.add_child(claim)


func _resource_meter(resource: Dictionary, compact: bool) -> Control:
	var block := VBoxContainer.new()
	block.custom_minimum_size.x = 66 if compact else 104
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line := HBoxContainer.new()
	var name_label := _label(
		String(resource.get("name", "")).left(2) if compact else String(resource.get("name", "")),
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
	var panel := _panel("")
	panel.name = "OnboardingMissionPanel"
	var title := _label("⚑ 当前行动", 11, GOLD)
	title.max_lines_visible = 1
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(title)
	var objectives := task.get("objectives", []) as Array
	if not objectives.is_empty():
		var objective := objectives[0] as Dictionary
		title.tooltip_text = String(objective.get("label", ""))
	var actions := HBoxContainer.new()
	var primary := _button("➤  %s" % String(task.get("cta_label", "继续")), true)
	primary.name = "FactoryMissionPrimaryAction"
	primary.tooltip_text = String(task.get("title", "当前行动"))
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
	panel.add_child(actions)
	return panel


func _construction_panel() -> Control:
	var construction := _view.get("construction", {}) as Dictionary
	var focused_growth := bool(construction.get("focused_growth", false))
	var active_id := String(construction.get("active_id", ""))
	var panel := _panel("")
	panel.name = "ConstructionPanel"
	if active_id.is_empty():
		var guide := _label("＋ 建设 · 选建筑后点空地", 11, MUTED)
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
		var scroll := ScrollContainer.new()
		scroll.name = "ConstructionCatalogScroll"
		scroll.custom_minimum_size.y = 66
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var choices := HBoxContainer.new()
		choices.name = "ConstructionButtonGrid"
		choices.add_theme_constant_override("separation", 8)
		scroll.add_child(choices)
		for option_value in construction.get("options", []):
			var option := option_value as Dictionary
			var choose := _button("%s  %s\n%s" % [
				_facility_icon(String(option.get("facility_id", ""))),
				String(option.get("name", "")),
				String(option.get("cost_copy", "")),
			], false)
			choose.name = "ChooseFacility_%s" % String(option.get("facility_id", ""))
			choose.custom_minimum_size = Vector2(132, 60)
			choose.disabled = bool(option.get("disabled", false))
			choose.tooltip_text = "%s · %d秒" % [String(option.get("copy", "")), int(option.get("build_seconds", 5))]
			if focused_growth:
				choose.custom_minimum_size.y = 54
			choose.pressed.connect(action_requested.emit.bind("begin_construction", {
				"facility_id": String(option.get("facility_id", "")),
			}))
			choices.add_child(choose)
		if choices.get_child_count() == 0:
			panel.add_child(_label("所有设施均已建成", 13, GREEN))
		else:
			panel.add_child(scroll)
		return panel
	panel.add_child(_label(
		"%s  %s · %s · %d秒" % [
			_facility_icon(active_id),
			String(construction.get("active_name", "")),
			String(construction.get("cost_copy", "")),
			int(construction.get("build_seconds", 5)),
		],
		13,
		CYAN
	))
	panel.add_child(_label(
		"点空地选址 · 拖动旋转 · 双指缩放"
			if not bool(construction.get("can_confirm", false))
			else String(construction.get("placement_copy", "")),
		11,
		GOLD if bool(construction.get("can_confirm", false)) else MUTED
	))
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


func _facility_icon(facility_id: String) -> String:
	match facility_id:
		"research_lab":
			return "⌬"
		"coin_mint":
			return "◉"
		"porcelain_plant":
			return "▰"
		"repair_center":
			return "✚"
		_:
			return "▣"


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
	hud_frame.add_theme_stylebox_override("panel", _box(Color(PANEL, 0.82), Color(CYAN, 0.38), 10))
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
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(primary))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(primary, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(primary, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(primary, "focus"))
	button.add_theme_color_override("font_color", PANEL if primary else TEXT)
	button.add_theme_color_override("font_hover_color", PANEL if primary else TEXT)
	button.add_theme_color_override("font_pressed_color", PANEL if primary else TEXT)


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

class_name BlueprintScreen
extends VBoxContainer

signal branch_selected(branch_id: String)
signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const ResourceContextHudScript := preload("res://game/scripts/ui/resource_context_hud.gd")
const BG := Color("#090d10")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")

const BRANCHES := [
	["ordinary", "突击枝"],
	["heavy", "重装枝"],
	["flying", "飞行枝"],
	["special", "支援枝"],
]

@onready var tabs: HBoxContainer = %BlueprintTabs
@onready var core_panel: PanelContainer = %BlueprintTreeRoot
@onready var core_status: Label = %BlueprintCoreStatus
@onready var resource_context_slot: VBoxContainer = %BlueprintResourceContext
@onready var breakthrough_copy: Label = %BlueprintBreakthroughCopy
@onready var breakthrough_button: Button = %ClaimResearchBreakthroughTen
@onready var results_panel: PanelContainer = %ResearchBreakthroughResults
@onready var results_summary: Label = %BlueprintResultsSummary
@onready var results_grid: GridContainer = %BlueprintResultsGrid
@onready var tech_preview: PanelContainer = %FactionTechPreview
@onready var tech_identity: Label = %Identity
@onready var tech_effect: Label = %Effect
@onready var coordination_choice: Button = %CoordinationChoice
@onready var specialization_choice: Button = %SpecializationChoice
@onready var branch_row: HBoxContainer = %BlueprintBranchRow
@onready var branch_panel: PanelContainer = %BlueprintBranchPanel
@onready var branch_heading: Label = %BlueprintBranchHeading
@onready var node_row: HBoxContainer = %BlueprintNodeRow
@onready var back_button: Button = %BlueprintBackButton

var _view: Dictionary = {}
var _reveal_tween: Tween
var _resource_context: Control
var _refresh_generation := 0


func _ready() -> void:
	_apply_theme()
	_resource_context = ResourceContextHudScript.new() as Control
	_resource_context.name = "BlueprintResearchResourceHUD"
	_resource_context.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_context_slot.add_child(_resource_context)
	for entry in BRANCHES:
		var id := String(entry[0])
		var button := tabs.get_node("Blueprint%sTab" % id.capitalize()) as Button
		button.pressed.connect(branch_selected.emit.bind(id))
	breakthrough_button.pressed.connect(action_requested.emit.bind("claim_breakthrough", {}))
	%BlueprintResultsLegionButton.pressed.connect(action_requested.emit.bind("open_legion", {}))
	coordination_choice.pressed.connect(
		action_requested.emit.bind("choose_faction_doctrine", {"doctrine_id": "coordination"})
	)
	specialization_choice.pressed.connect(
		action_requested.emit.bind("choose_faction_doctrine", {"doctrine_id": "specialization"})
	)
	back_button.pressed.connect(action_requested.emit.bind("back", {}))
	if not _view.is_empty():
		_apply_view()
	_focus_primary_after_layout()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()
		_focus_primary_after_layout()


func _apply_view() -> void:
	var compact := bool(_view.get("compact", false))
	var key_font_size := 16 if compact else 11
	tech_identity.add_theme_font_size_override("font_size", key_font_size)
	tech_effect.add_theme_font_size_override("font_size", key_font_size)
	back_button.add_theme_font_size_override("font_size", 16 if compact else 14)
	for entry in BRANCHES:
		var responsive_tab := tabs.get_node(
			"Blueprint%sTab" % String(entry[0]).capitalize()
		) as Button
		responsive_tab.add_theme_font_size_override("font_size", 16 if compact else 14)
	var selected := String(_view.get("branch", "ordinary"))
	for entry in BRANCHES:
		var id := String(entry[0])
		var button := tabs.get_node("Blueprint%sTab" % id.capitalize()) as Button
		button.button_pressed = id == selected
	core_status.text = String(_view.get("core_status", "首败信号尚未解析"))
	var resource_context := _view.get("resource_context", {}) as Dictionary
	_resource_context.call("configure", resource_context)
	resource_context_slot.visible = not resource_context.is_empty()
	var breakthrough := _view.get("breakthrough", {}) as Dictionary
	breakthrough_copy.text = String(breakthrough.get("copy", ""))
	breakthrough_copy.visible = not breakthrough_copy.text.is_empty()
	breakthrough_button.visible = bool(breakthrough.get("claimable", false))
	var results := _view.get("results", []) as Array
	var showing_results := not results.is_empty()
	var preview := _view.get("faction_tech_preview", {}) as Dictionary
	var choices := _view.get("faction_tech_choices", []) as Array
	var choosing_doctrine := choices.size() == 2
	results_panel.visible = showing_results
	tech_preview.visible = not showing_results and not preview.is_empty()
	if choosing_doctrine:
		tech_identity.text = "Tier 2科技待定 · %s\n选择后从第4章生效" % String(
			preview.get("faction", "阵营")
		)
		var coordination := choices[0] as Dictionary
		var specialization := choices[1] as Dictionary
		tech_effect.text = "永久选择 · 不可更改\n广覆盖 vs 高强度"
		coordination_choice.text = String(
			coordination.get("choice_summary", coordination.get("action_label", "选择全队协同"))
		)
		specialization_choice.text = String(
			specialization.get(
				"choice_summary",
				specialization.get("action_label", "选择阵营专精")
			)
		)
	else:
		tech_identity.text = "Tier %d阵营科技已激活 · %s\n%s" % [
			int(preview.get("tier", 1)),
			String(preview.get("faction", "阵营待形成")),
			String(preview.get("title", "未来协议")),
		]
		tech_effect.text = "%s\n第%d章起自动生效 · 编入同阵营角色可扩大收益" % [
			String(preview.get("effect", "")),
			int(preview.get("activation_chapter", 3)),
		]
	coordination_choice.visible = choosing_doctrine
	specialization_choice.visible = choosing_doctrine
	tabs.visible = not showing_results
	core_panel.visible = not showing_results and preview.is_empty()
	branch_row.visible = not showing_results
	results_summary.text = String(_view.get(
		"results_summary",
		"两名永久援军响应召唤 · 现在把他们编入反攻队"
	))
	_clear_children(results_grid)
	for result_value in results:
		var result := result_value as Dictionary
		results_grid.add_child(_build_result_card(result))
	if showing_results:
		call_deferred("_animate_results")
	branch_row.name = "BlueprintBranchRow_%s" % selected
	branch_heading.text = "%s · %s" % [
		String(_view.get("branch_title", "研究分支")),
		String(_view.get("branch_summary", "比较职责与成长质变")),
	]
	_clear_children(node_row)
	var nodes := _view.get("nodes", []) as Array
	for node_value in nodes:
		node_row.add_child(_build_node(node_value as Dictionary))
	_schedule_research_refresh(int(_view.get("refresh_at_unix", 0)))


func _build_result_card(view: Dictionary) -> PanelContainer:
	var is_hero := String(view.get("kind", "")) == "hero"
	var card := PanelContainer.new()
	card.name = "BreakthroughResult_%s" % String(view.get("id", "resource"))
	card.custom_minimum_size = Vector2(118, 64 if is_hero else 54)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := _panel_style(Color("#242015") if is_hero else PANEL_2)
	style.border_color = GOLD if is_hero else Color(LINE, 0.8)
	style.set_border_width_all(2 if is_hero else 1)
	card.add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 1)
	card.add_child(content)
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = String(view.get("title", "研究资源"))
	title.add_theme_font_override("font", CJK_FONT)
	title.add_theme_font_size_override("font_size", 13 if is_hero else 11)
	title.add_theme_color_override("font_color", GOLD if is_hero else TEXT)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = String(view.get("subtitle", ""))
	subtitle.add_theme_font_override("font", CJK_FONT)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", CYAN if is_hero else MUTED)
	content.add_child(subtitle)
	if is_hero:
		var impact := Label.new()
		impact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		impact.text = String(view.get("impact", "永久援军"))
		impact.add_theme_font_override("font", CJK_FONT)
		impact.add_theme_font_size_override("font_size", 10)
		impact.add_theme_color_override("font_color", GREEN)
		content.add_child(impact)
	return card


func _animate_results() -> void:
	if not is_inside_tree():
		return
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	var cards := results_grid.get_children()
	var reduced_motion := bool(_view.get("reduced_motion", false))
	for card_value in cards:
		var card := card_value as Control
		card.modulate = Color.WHITE
		card.scale = Vector2.ONE
	if reduced_motion or cards.is_empty():
		return
	_reveal_tween = create_tween()
	_reveal_tween.set_parallel(true)
	_reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_reveal_tween.set_ignore_time_scale(true)
	for index in cards.size():
		var card := cards[index] as Control
		card.pivot_offset = card.size * 0.5
		card.modulate.a = 0.0
		card.scale = Vector2(0.92, 0.92)
		var delay := minf(0.24, float(index) * 0.03)
		_reveal_tween.tween_property(card, "modulate:a", 1.0, 0.16).set_delay(delay)
		_reveal_tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_node(view: Dictionary) -> PanelContainer:
	var journey_focus := bool(view.get("journey_focus", false))
	var card := PanelContainer.new()
	card.name = "BlueprintNode_%s" % String(view.get("recipe_id", "")).replace(".", "_")
	card.custom_minimum_size = Vector2(286, 104)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style := _panel_style(Color("#242015") if journey_focus else PANEL_2)
	if journey_focus:
		card_style.border_color = GOLD
		card_style.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", card_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 3)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 1)
	margin.add_child(content)
	if journey_focus:
		var focus_badge := Label.new()
		focus_badge.name = "FactionJourneyBlueprintBadge"
		focus_badge.text = "★ 本轮十连阵营核心"
		focus_badge.add_theme_font_override("font", CJK_FONT)
		focus_badge.add_theme_font_size_override("font_size", 10)
		focus_badge.add_theme_color_override("font_color", GOLD)
		content.add_child(focus_badge)
	var heading := Label.new()
	heading.text = String(view.get("display_name", "未知蓝图"))
	heading.add_theme_font_override("font", CJK_FONT)
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", GOLD if journey_focus else CYAN)
	content.add_child(heading)
	var identity := Label.new()
	identity.text = "%s级 · %s · %s" % [
		String(view.get("rating", "B")),
		String(view.get("faction", "独立战术")),
		String(view.get("role_copy", "职责待确认")),
	]
	identity.add_theme_font_override("font", CJK_FONT)
	identity.add_theme_font_size_override("font_size", 10)
	identity.add_theme_color_override("font_color", GOLD)
	identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(identity)
	var growth := Label.new()
	growth.text = "1★ %s · 2★ %s → 3★ %s" % [
		String(view.get("one_star_value", "拥有完整主动技能")),
		String(view.get("two_star_effect", "职责强化")),
		String(view.get("three_star_effect", "技能质变")),
	]
	growth.add_theme_font_override("font", CJK_FONT)
	growth.add_theme_font_size_override("font_size", 9)
	growth.add_theme_color_override("font_color", TEXT)
	growth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(growth)
	var status := Label.new()
	status.text = "%s · 来源：%s" % [
		String(view.get("status_copy", "")),
		String(view.get("unlock_source", "信号招募")),
	]
	status.add_theme_font_override("font", CJK_FONT)
	status.add_theme_font_size_override("font_size", 9)
	status.add_theme_color_override("font_color", _status_color(String(view.get("status_id", "locked"))))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status)
	var action_id := String(view.get("action_id", ""))
	if not action_id.is_empty():
		var button := _button(String(view.get("action_label", "继续")), true)
		button.custom_minimum_size.y = 32
		button.name = String(view.get("action_name", "BlueprintNodeAction"))
		button.set_meta("primary_blueprint_action", true)
		button.disabled = bool(view.get("disabled", false))
		button.pressed.connect(action_requested.emit.bind(action_id, {
			"recipe_id": String(view.get("recipe_id", "")),
		}))
		content.add_child(button)
	return card


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()


func _status_color(status_id: String) -> Color:
	if status_id == "unlocked":
		return GREEN
	if status_id == "researching":
		return CYAN
	if status_id == "available":
		return GOLD
	return MUTED


func _focus_primary_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if breakthrough_button.visible:
		breakthrough_button.grab_focus()
		return
	if results_panel.visible:
		%BlueprintResultsLegionButton.grab_focus()
		return
	for action_value in find_children("*", "Button", true, false):
		var action := action_value as Button
		if (
			bool(action.get_meta("primary_blueprint_action", false))
			and action.visible
			and not action.disabled
		):
			action.grab_focus()
			return
	back_button.grab_focus()


func _schedule_research_refresh(refresh_at_unix: int) -> void:
	_refresh_generation += 1
	var generation := _refresh_generation
	var delay := refresh_at_unix - int(Time.get_unix_time_from_system())
	if delay <= 0:
		return
	await get_tree().create_timer(float(delay) + 0.15).timeout
	if is_inside_tree() and generation == _refresh_generation:
		action_requested.emit("refresh", {})


func _apply_theme() -> void:
	for panel in [core_panel, results_panel, tech_preview, branch_panel]:
		panel.add_theme_stylebox_override("panel", _panel_style(PANEL))
	for label_node in find_children("*", "Label", true, false):
		var label := label_node as Label
		label.add_theme_font_override("font", CJK_FONT)
		label.add_theme_color_override("font_color", TEXT)
	core_status.add_theme_color_override("font_color", GOLD)
	breakthrough_copy.add_theme_color_override("font_color", CYAN)
	results_summary.add_theme_color_override("font_color", CYAN)
	tech_identity.add_theme_color_override("font_color", GOLD)
	tech_identity.add_theme_font_size_override("font_size", 11)
	tech_effect.add_theme_color_override("font_color", CYAN)
	tech_effect.add_theme_font_size_override("font_size", 11)
	branch_heading.add_theme_font_size_override("font_size", 16)
	branch_heading.add_theme_color_override("font_color", CYAN)
	for button_node in find_children("*", "Button", true, false):
		_style_button(button_node as Button, button_node == breakthrough_button)
	for doctrine_button in [coordination_choice, specialization_choice]:
		doctrine_button.add_theme_font_size_override("font_size", 11)


func _button(text_value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 44
	_style_button(button, primary)
	return button


func _style_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _button_style(GOLD if primary else PANEL_2, GOLD if primary else LINE))
	button.add_theme_stylebox_override("hover", _button_style(GOLD.lightened(0.1) if primary else PANEL_2.lightened(0.1), GOLD))
	button.add_theme_stylebox_override("pressed", _button_style(PANEL, GOLD))
	button.add_theme_stylebox_override("focus", _button_style(Color(GOLD, 0.22), Color.WHITE))
	button.add_theme_color_override("font_color", BG if primary else TEXT)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(LINE, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style


func _button_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

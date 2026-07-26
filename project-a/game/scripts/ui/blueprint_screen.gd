class_name BlueprintScreen
extends VBoxContainer

signal branch_selected(branch_id: String)
signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
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
@onready var breakthrough_copy: Label = %BlueprintBreakthroughCopy
@onready var breakthrough_button: Button = %ClaimResearchBreakthroughTen
@onready var results_panel: PanelContainer = %ResearchBreakthroughResults
@onready var results_summary: Label = %BlueprintResultsSummary
@onready var results_grid: GridContainer = %BlueprintResultsGrid
@onready var branch_row: HBoxContainer = %BlueprintBranchRow
@onready var branch_panel: PanelContainer = %BlueprintBranchPanel
@onready var branch_heading: Label = %BlueprintBranchHeading
@onready var node_row: HBoxContainer = %BlueprintNodeRow
@onready var back_button: Button = %BlueprintBackButton

var _view: Dictionary = {}
var _reveal_tween: Tween


func _ready() -> void:
	_apply_theme()
	for entry in BRANCHES:
		var id := String(entry[0])
		var button := tabs.get_node("Blueprint%sTab" % id.capitalize()) as Button
		button.pressed.connect(branch_selected.emit.bind(id))
	breakthrough_button.pressed.connect(action_requested.emit.bind("claim_breakthrough", {}))
	%BlueprintResultsLegionButton.pressed.connect(action_requested.emit.bind("open_legion", {}))
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
	var selected := String(_view.get("branch", "ordinary"))
	for entry in BRANCHES:
		var id := String(entry[0])
		var button := tabs.get_node("Blueprint%sTab" % id.capitalize()) as Button
		button.button_pressed = id == selected
	core_status.text = String(_view.get("core_status", "首败信号尚未解析"))
	var breakthrough := _view.get("breakthrough", {}) as Dictionary
	breakthrough_copy.text = String(breakthrough.get("copy", ""))
	breakthrough_copy.visible = not breakthrough_copy.text.is_empty()
	breakthrough_button.visible = bool(breakthrough.get("claimable", false))
	var results := _view.get("results", []) as Array
	var showing_results := not results.is_empty()
	results_panel.visible = showing_results
	tabs.visible = not showing_results
	core_panel.visible = not showing_results
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
	branch_heading.text = String(_view.get("branch_title", "研究分支"))
	_clear_children(node_row)
	var nodes := _view.get("nodes", []) as Array
	for node_index in nodes.size():
		if node_index > 0:
			var arrow := Label.new()
			arrow.custom_minimum_size = Vector2(24, 48)
			arrow.text = "→"
			arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			arrow.add_theme_font_override("font", CJK_FONT)
			arrow.add_theme_font_size_override("font_size", 22)
			arrow.add_theme_color_override("font_color", MUTED)
			node_row.add_child(arrow)
		node_row.add_child(_build_node(nodes[node_index] as Dictionary))


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
	var card := PanelContainer.new()
	card.name = "BlueprintNode_%s" % String(view.get("recipe_id", "")).replace(".", "_")
	card.custom_minimum_size = Vector2(260, 104)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(PANEL_2))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 7)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)
	var heading := Label.new()
	heading.text = String(view.get("display_name", "未知蓝图"))
	heading.add_theme_font_override("font", CJK_FONT)
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", CYAN)
	content.add_child(heading)
	var status := Label.new()
	status.text = String(view.get("status_copy", ""))
	status.add_theme_font_override("font", CJK_FONT)
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", _status_color(String(view.get("status_id", "locked"))))
	content.add_child(status)
	var action_id := String(view.get("action_id", ""))
	if not action_id.is_empty():
		var button := _button(String(view.get("action_label", "继续")), true)
		button.name = String(view.get("action_name", "BlueprintNodeAction"))
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
	back_button.grab_focus()


func _apply_theme() -> void:
	for panel in [core_panel, results_panel, branch_panel]:
		panel.add_theme_stylebox_override("panel", _panel_style(PANEL))
	for label_node in find_children("*", "Label", true, false):
		var label := label_node as Label
		label.add_theme_font_override("font", CJK_FONT)
		label.add_theme_color_override("font_color", TEXT)
	core_status.add_theme_color_override("font_color", GOLD)
	breakthrough_copy.add_theme_color_override("font_color", CYAN)
	results_summary.add_theme_color_override("font_color", CYAN)
	branch_heading.add_theme_font_size_override("font_size", 16)
	branch_heading.add_theme_color_override("font_color", CYAN)
	for button_node in find_children("*", "Button", true, false):
		_style_button(button_node as Button, button_node == breakthrough_button)


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

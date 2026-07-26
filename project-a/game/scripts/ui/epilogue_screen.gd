class_name EpilogueScreen
extends HBoxContainer

signal action_requested(action_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const BG := Color("#090d10")
const PANEL := Color("#12171c")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")

@onready var story_panel: PanelContainer = %CampaignEpilogueStory
@onready var summary_panel: PanelContainer = %CampaignEpilogueSummary
@onready var occupied_label: Label = %CampaignOccupiedCount
@onready var roster_label: Label = %CampaignRosterCount
@onready var mastery_label: Label = %CampaignMasterySummary
@onready var time_label: Label = %CampaignFinalBattleTime
@onready var endless_button: Button = %CampaignEnterEndlessButton
@onready var goals_button: Button = %CampaignEndingGoalsButton
@onready var base_button: Button = %CampaignReturnBaseButton

var _view: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	endless_button.pressed.connect(func() -> void: action_requested.emit("endless"))
	goals_button.pressed.connect(func() -> void: action_requested.emit("goals"))
	base_button.pressed.connect(func() -> void: action_requested.emit("base"))
	if not _view.is_empty():
		_apply_view()
	_focus_continuation()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()


func _apply_view() -> void:
	occupied_label.text = "城镇占领  %d/25" % int(_view.get("cleared_count", 0))
	roster_label.text = "永久角色  %d 名" % int(_view.get("roster_count", 0))
	mastery_label.text = "军团星级  %d★ · 技能等级合计 %d" % [
		int(_view.get("total_stars", 0)),
		int(_view.get("total_skill_levels", 0)),
	]
	time_label.text = "最终战耗时  %d 秒" % int(_view.get("battle_seconds", 0))


func _focus_continuation() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		endless_button.grab_focus()


func _apply_theme() -> void:
	for panel in [story_panel, summary_panel]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(PANEL, 0.94)
		style.border_color = Color(LINE, 0.8)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		panel.add_theme_stylebox_override("panel", style)
	for label_node in find_children("*", "Label", true, false):
		var label := label_node as Label
		label.add_theme_font_override("font", CJK_FONT)
		label.add_theme_color_override("font_color", TEXT)
	%CampaignEpilogueHeading.add_theme_color_override("font_color", GOLD)
	%CampaignEpilogueFuture.add_theme_color_override("font_color", GOLD)
	%CampaignReplayPromise.add_theme_color_override("font_color", GREEN)
	occupied_label.add_theme_font_size_override("font_size", 18)
	occupied_label.add_theme_color_override("font_color", GOLD)
	%CampaignContinuationPromise.add_theme_color_override("font_color", CYAN)
	for button in [endless_button, goals_button, base_button]:
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size.y = 44
		button.add_theme_font_override("font", CJK_FONT)
		button.add_theme_stylebox_override("focus", _button_style(Color(CYAN, 0.16), CYAN))
	endless_button.add_theme_stylebox_override("normal", _button_style(GOLD, GOLD))
	endless_button.add_theme_stylebox_override("hover", _button_style(GOLD.lightened(0.12), GOLD))
	endless_button.add_theme_stylebox_override("pressed", _button_style(GOLD.darkened(0.18), GOLD))
	endless_button.add_theme_stylebox_override("focus", _button_style(Color(GOLD, 0.22), Color.WHITE))
	endless_button.add_theme_color_override("font_color", BG)


func _button_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

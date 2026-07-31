class_name TitleScreen
extends Control

signal action_requested(action_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const BG := Color("#090d10")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")

@onready var panel: PanelContainer = %TitleSignalPanel
@onready var game_title: Label = $TitleMark/GameTitle
@onready var game_subtitle: Label = $TitleMark/GameSubtitle
@onready var heading: Label = %TitleSignalHeading
@onready var transmission: Label = %TitleTransmission
@onready var progress_summary: Label = %TitleProgressSummary
@onready var next_objective: Label = %TitleNextObjective
@onready var storage_warning: Label = %TitleStorageWarning
@onready var primary_button: Button = %TitlePrimaryButton
@onready var settings_button: Button = %TitleSettingsButton
@onready var help_button: Button = %TitleHelpButton

var _view: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	primary_button.pressed.connect(action_requested.emit.bind("primary"))
	settings_button.pressed.connect(action_requested.emit.bind("settings"))
	help_button.pressed.connect(action_requested.emit.bind("help"))
	if not _view.is_empty():
		_apply_view()
	# Web viewport sizing can replace the initial title instance during its first
	# frame. Wait until that responsive pass settles, then reject stale instances
	# before touching Control focus.
	_focus_primary_after_layout()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()


func _focus_primary_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or not primary_button.is_inside_tree():
		return
	primary_button.grab_focus()


func _apply_view() -> void:
	progress_summary.text = String(_view.get("summary", ""))
	next_objective.text = String(_view.get("objective", ""))
	storage_warning.visible = bool(_view.get("storage_blocked", false))
	primary_button.text = String(_view.get("primary_label", "继续战役"))


func _apply_theme() -> void:
	var panel_style := UiArtDirectionScript.panel_style(true)
	panel.add_theme_stylebox_override("panel", panel_style)
	game_title.add_theme_font_override("font", CJK_FONT)
	game_subtitle.add_theme_font_override("font", CJK_FONT)

	for label: Label in [heading, transmission, progress_summary, next_objective, storage_warning]:
		label.add_theme_font_override("font", CJK_FONT)
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", GOLD)
	transmission.add_theme_font_size_override("font_size", 16)
	transmission.add_theme_color_override("font_color", TEXT)
	progress_summary.add_theme_font_size_override("font_size", 12)
	progress_summary.add_theme_color_override("font_color", CYAN)
	next_objective.add_theme_font_size_override("font_size", 12)
	next_objective.add_theme_color_override("font_color", GOLD)
	storage_warning.add_theme_font_size_override("font_size", 11)
	storage_warning.add_theme_color_override("font_color", Color("#ff806f"))

	_style_button(primary_button, true)
	_style_button(settings_button, false)
	_style_button(help_button, false)


func _style_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(primary))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(primary, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(primary, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(primary, "focus"))
	button.add_theme_color_override("font_color", BG if primary else TEXT)
	button.add_theme_color_override("font_hover_color", BG if primary else TEXT)
	button.add_theme_color_override("font_pressed_color", BG if primary else TEXT)

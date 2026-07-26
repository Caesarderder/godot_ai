class_name HelpScreen
extends VBoxContainer

signal back_requested

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const BG := Color("#090d10")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")

@onready var version_copy: Label = %HelpVersionCopy
@onready var back_button: Button = %HelpBackButton

var _view: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	back_button.pressed.connect(back_requested.emit)
	if not _view.is_empty():
		_apply_view()
	_focus_back_after_layout()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()


func _apply_view() -> void:
	version_copy.text = (
		"版本 %s\nGodot 4.6.3 · Compatibility / WebGL2\n"
		+ "Noto Sans CJK SC · SIL OFL 1.1\n"
		+ "非官方粉丝创作；商业发布仍需完成 IP 与地区合规审查。"
	) % String(_view.get("version", "dev"))


func _focus_back_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree() and back_button.is_inside_tree():
		back_button.grab_focus()


func _apply_theme() -> void:
	for panel_node in find_children("*", "PanelContainer", true, false):
		var panel := panel_node as PanelContainer
		var style := StyleBoxFlat.new()
		style.bg_color = Color(PANEL, 0.92)
		style.border_color = Color(LINE, 0.78)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		panel.add_theme_stylebox_override("panel", style)
	for label_node in find_children("*", "Label", true, false):
		var label := label_node as Label
		label.add_theme_font_override("font", CJK_FONT)
		label.add_theme_color_override("font_color", TEXT)
	for heading in find_children("*Heading", "Label", true, false):
		(heading as Label).add_theme_font_size_override("font_size", 16)
		(heading as Label).add_theme_color_override("font_color", CYAN)
	for body in find_children("*Body", "Label", true, false):
		(body as Label).add_theme_font_size_override("font_size", 12)
		(body as Label).add_theme_color_override("font_color", TEXT)
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.add_theme_font_override("font", CJK_FONT)
	back_button.add_theme_font_size_override("font_size", 15)
	back_button.add_theme_stylebox_override("normal", _button_style(PANEL_2, LINE))
	back_button.add_theme_stylebox_override("hover", _button_style(PANEL_2.lightened(0.1), GOLD))
	back_button.add_theme_stylebox_override("pressed", _button_style(PANEL, GOLD))
	back_button.add_theme_stylebox_override("focus", _button_style(Color(GOLD, 0.22), Color.WHITE))
	back_button.add_theme_color_override("font_color", TEXT)


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

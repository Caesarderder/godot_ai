class_name WarZoneScreen
extends VBoxContainer

signal chapter_selected(chapter: int)
signal stage_selected(stage_id: String)
signal attack_requested(stage_id: String)
signal growth_requested()

const STAGE_DETAIL_PANEL_SCENE := preload("res://game/scenes/ui/stage_detail_panel.tscn")
const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")

@onready var chapter_nav: HBoxContainer = %ChapterNav
@onready var stage_strip: HBoxContainer = %StageNodeStrip
@onready var detail_host: MarginContainer = %StageDetailHost

var _highest_chapter := 1
var _selected_chapter := 1
var _selected_stage_id := ""
var _stage_rows: Array[Dictionary] = []
var _selected_config: Dictionary = {}
var _selected_report: Dictionary = {}
var _selected_unlocked := false
var _selected_cleared := false
var _estimated_threat := "未知"


func _ready() -> void:
	if not _selected_config.is_empty():
		_rebuild()


func configure(
	highest_chapter: int,
	selected_chapter: int,
	selected_stage_id: String,
	stage_rows: Array[Dictionary],
	selected_config: Dictionary,
	selected_report: Dictionary,
	selected_unlocked: bool,
	selected_cleared: bool,
	estimated_threat: String
) -> void:
	_highest_chapter = highest_chapter
	_selected_chapter = selected_chapter
	_selected_stage_id = selected_stage_id
	_stage_rows = stage_rows.duplicate(true)
	_selected_config = selected_config.duplicate(true)
	_selected_report = selected_report.duplicate(true)
	_selected_unlocked = selected_unlocked
	_selected_cleared = selected_cleared
	_estimated_threat = estimated_threat
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	_clear_children(chapter_nav)
	_clear_children(stage_strip)
	_clear_children(detail_host)
	for chapter in range(1, 6):
		var chapter_button := _button("第%d章" % chapter, _selected_chapter == chapter)
		chapter_button.custom_minimum_size = Vector2(105, 36)
		chapter_button.disabled = chapter > _highest_chapter
		chapter_button.pressed.connect(_on_chapter_pressed.bind(chapter))
		chapter_nav.add_child(chapter_button)
	var endless_button := _button("无尽前线", _selected_chapter == 6)
	endless_button.custom_minimum_size = Vector2(120, 36)
	endless_button.disabled = _highest_chapter < 6
	endless_button.pressed.connect(_on_chapter_pressed.bind(6))
	chapter_nav.add_child(endless_button)

	for row in _stage_rows:
		var stage_id := String(row.get("stage_id", ""))
		var stage_button := _button(
			"%s\n%s" % [String(row.get("display_name", stage_id)), String(row.get("status", ""))],
			stage_id == _selected_stage_id
		)
		stage_button.name = "StageNode_%s" % stage_id
		stage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage_button.custom_minimum_size.y = 52
		stage_button.disabled = not bool(row.get("unlocked", false))
		stage_button.pressed.connect(_on_stage_pressed.bind(stage_id))
		stage_strip.add_child(stage_button)

	var detail := STAGE_DETAIL_PANEL_SCENE.instantiate()
	detail.configure(
		_selected_stage_id,
		_selected_config,
		_selected_report,
		_selected_unlocked,
		_selected_cleared,
		_estimated_threat
	)
	detail.attack_requested.connect(_on_attack_requested)
	detail.growth_requested.connect(growth_requested.emit)
	detail_host.add_child(detail)


func _button(value: String, selected: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED)
	var normal := StyleBoxFlat.new()
	normal.bg_color = PANEL_2
	normal.border_color = CYAN if selected else LINE
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#24333a")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#17383a")
	pressed.border_color = GOLD if selected else CYAN
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	var focus := pressed.duplicate() as StyleBoxFlat
	focus.border_color = Color.WHITE
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", normal)
	return button


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _on_chapter_pressed(chapter: int) -> void:
	chapter_selected.emit(chapter)


func _on_stage_pressed(stage_id: String) -> void:
	stage_selected.emit(stage_id)


func _on_attack_requested(stage_id: String) -> void:
	attack_requested.emit(stage_id)

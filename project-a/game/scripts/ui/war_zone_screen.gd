class_name WarZoneScreen
extends Control

signal chapter_selected(chapter: int)
signal stage_selected(stage_id: String)
signal attack_requested(stage_id: String)
signal preparation_requested(action_id: String)

const STAGE_DETAIL_PANEL_SCENE := preload("res://game/scenes/ui/stage_detail_panel.tscn")
const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")

@onready var chapter_nav: HBoxContainer = %ChapterNav
@onready var stage_scroll: ScrollContainer = $StageScroll
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
	resized.connect(queue_redraw)
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
		chapter_button.custom_minimum_size = Vector2(92, 36)
		chapter_button.disabled = chapter > _highest_chapter
		chapter_button.pressed.connect(_on_chapter_pressed.bind(chapter))
		chapter_nav.add_child(chapter_button)
	var endless_button := _button("无尽前线", _selected_chapter == 6)
	endless_button.custom_minimum_size = Vector2(104, 36)
	endless_button.disabled = _highest_chapter < 6
	endless_button.pressed.connect(_on_chapter_pressed.bind(6))
	chapter_nav.add_child(endless_button)

	for row in _stage_rows:
		var stage_id := String(row.get("stage_id", ""))
		var stage_number := stage_id.trim_prefix("stage_").replace("_", "-")
		var stage_state := "◆" if bool(row.get("unlocked", false)) else "×"
		if String(row.get("status", "")) == "已夺回":
			stage_state = "✓"
		var stage_button := _button(
			"%s\n%s" % [stage_number, stage_state],
			stage_id == _selected_stage_id
		)
		stage_button.name = "StageNode_%s" % stage_id
		stage_button.custom_minimum_size = Vector2(58, 50)
		stage_button.tooltip_text = "%s · %s" % [
			String(row.get("display_name", stage_id)),
			String(row.get("status", "")),
		]
		stage_button.disabled = not bool(row.get("unlocked", false))
		stage_button.pressed.connect(_on_stage_pressed.bind(stage_id))
		stage_strip.add_child(stage_button)
		if stage_id == _selected_stage_id:
			stage_scroll.call_deferred("ensure_control_visible", stage_button)

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
	detail.preparation_requested.connect(preparation_requested.emit)
	detail_host.add_child(detail)
	queue_redraw()


func _draw() -> void:
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#081219d9"))
	var horizon_y := viewport_size.y * 0.58
	for index in range(7):
		var y := lerpf(112.0, viewport_size.y - 8.0, float(index) / 6.0)
		var fade := 0.13 * (1.0 - float(index) / 8.0)
		draw_line(Vector2(0.0, y), Vector2(viewport_size.x, y), Color(CYAN, fade), 1.0)
	for index in range(9):
		var x := viewport_size.x * float(index) / 8.0
		draw_line(
			Vector2(viewport_size.x * 0.5, horizon_y),
			Vector2(x, viewport_size.y),
			Color(CYAN, 0.08),
			1.0
		)
	var route_start := Vector2(54.0, horizon_y + 28.0)
	var route_end := Vector2(viewport_size.x - 66.0, horizon_y - 14.0)
	draw_line(route_start, route_end, Color(CYAN, 0.32), 3.0, true)
	for index in range(5):
		var point := route_start.lerp(route_end, float(index) / 4.0)
		var active := index == clampi(_selected_stage_index(), 0, 4)
		draw_circle(point, 10.0 if active else 6.0, GOLD if active else Color(CYAN, 0.58))
		if active:
			draw_arc(point, 16.0, 0.0, TAU, 32, Color(GOLD, 0.54), 2.0, true)


func _selected_stage_index() -> int:
	for index in range(_stage_rows.size()):
		if String(_stage_rows[index].get("stage_id", "")) == _selected_stage_id:
			return index
	return 0


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

class_name WarZoneScreen
extends Control

signal chapter_selected(chapter: int)
signal stage_selected(stage_id: String)
signal attack_requested(stage_id: String)
signal preparation_requested(action_id: String)

const STAGE_DETAIL_PANEL_SCENE := preload("res://game/scenes/ui/stage_detail_panel.tscn")
const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const BOSS_FORTRESS_ICON := preload("res://assets/ui/goals/chapter_stronghold.webp")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const LANDMARK_GLYPHS: Array[String] = ["◇", "△", "▣", "▲", "◆"]
const ROUTE_Y_FACTORS: Array[float] = [0.36, 0.285, 0.35, 0.245, 0.32]

@onready var chapter_nav: HBoxContainer = %ChapterNav
@onready var stage_strip: Control = %StageNodeStrip
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
var _compact := false


func _ready() -> void:
	resized.connect(_on_resized)
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
	estimated_threat: String,
	compact := false
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
	_compact = compact
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	_clear_children(chapter_nav)
	_clear_children(stage_strip)
	_clear_children(detail_host)
	_apply_layout()
	_build_chapter_switcher()

	var visible_rows := _visible_stage_rows()
	for row_index in range(visible_rows.size()):
		var row := visible_rows[row_index]
		var stage_id := String(row.get("stage_id", ""))
		var stage_number := stage_id.trim_prefix("stage_").replace("_", "-")
		var landmark: String = LANDMARK_GLYPHS[row_index]
		var unlocked := bool(row.get("unlocked", false))
		var recovered := String(row.get("status", "")) == "已夺回"
		var stage_state: String = "%s ●" % landmark if unlocked else "%s ?" % landmark
		if String(row.get("status", "")) == "已夺回":
			stage_state = "%s ✓" % landmark
		var stage_button := _stage_node_button(
			(
				"%s\n%s" % [stage_number, "✓" if recovered else ("!" if unlocked else "?")]
				if row_index == visible_rows.size() - 1
				else "%s\n%s" % [stage_number, stage_state]
			),
			stage_id == _selected_stage_id,
			recovered,
			unlocked
		)
		stage_button.name = "StageNode_%s" % stage_id
		var boss_node := row_index == visible_rows.size() - 1
		var node_size := (
			Vector2(68, 58) if _is_compact_layout() else Vector2(78, 66)
		) if boss_node else (Vector2(46, 42) if _is_compact_layout() else Vector2(58, 50))
		if boss_node:
			stage_button.set_meta("boss_fortress", true)
			stage_button.icon = BOSS_FORTRESS_ICON
			stage_button.expand_icon = true
			stage_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			stage_button.add_theme_constant_override("icon_max_width", 34 if _is_compact_layout() else 40)
		stage_button.custom_minimum_size = node_size
		stage_button.size = node_size
		stage_button.position = _route_point(row_index, visible_rows.size()) - node_size * 0.5
		stage_button.tooltip_text = "%s · %s" % [
			String(row.get("display_name", stage_id)),
			String(row.get("status", "")),
		]
		stage_button.disabled = not bool(row.get("unlocked", false))
		stage_button.pressed.connect(_on_stage_pressed.bind(stage_id))
		stage_strip.add_child(stage_button)
		stage_button.name = "StageNode_%s" % stage_id
		var location_label := Label.new()
		location_label.name = "StageLocation_%s" % stage_id
		location_label.text = _stage_location_name(String(row.get("display_name", stage_id)))
		location_label.position = _route_point(row_index, visible_rows.size()) + Vector2(
			-43 if _is_compact_layout() else -48,
			31 if _is_compact_layout() and row_index % 2 == 0 else (29 if not _is_compact_layout() else 27)
		)
		location_label.size = Vector2(86, 18) if _is_compact_layout() else Vector2(96, 18)
		location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		location_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		location_label.add_theme_font_override("font", CJK_FONT)
		location_label.add_theme_font_size_override("font_size", 10 if _is_compact_layout() else 11)
		location_label.add_theme_color_override(
			"font_color",
			CYAN if stage_id == _selected_stage_id else MUTED
		)
		stage_strip.add_child(location_label)

	var detail := STAGE_DETAIL_PANEL_SCENE.instantiate()
	detail.configure(
		_selected_stage_id,
		_selected_config,
		_selected_report,
		_selected_unlocked,
		_selected_cleared,
		_estimated_threat,
		_is_compact_layout()
	)
	detail.attack_requested.connect(_on_attack_requested)
	detail.preparation_requested.connect(preparation_requested.emit)
	detail_host.add_child(detail)
	queue_redraw()


func _apply_layout() -> void:
	if _is_compact_layout():
		detail_host.offset_left = -330.0
		detail_host.offset_top = -68.0
		detail_host.offset_right = -6.0
		detail_host.offset_bottom = -3.0
		chapter_nav.offset_left = 20.0
		chapter_nav.offset_right = -20.0
	else:
		detail_host.offset_left = -470.0
		detail_host.offset_top = -78.0
		detail_host.offset_right = -8.0
		detail_host.offset_bottom = -4.0
		chapter_nav.offset_left = 34.0
		chapter_nav.offset_right = -34.0


func _is_compact_layout() -> bool:
	return _compact or size.x <= 600.0


func _on_resized() -> void:
	queue_redraw()
	if is_node_ready() and not _selected_config.is_empty():
		_rebuild.call_deferred()


func _draw() -> void:
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#050b12"))
	var horizon_y := viewport_size.y * 0.56
	_draw_sky_atmosphere(viewport_size, horizon_y)
	_draw_territory_fields(viewport_size, horizon_y)
	_draw_city_silhouette(viewport_size, horizon_y)
	_draw_tactical_grid(viewport_size, horizon_y)
	var route_points := PackedVector2Array()
	for index in range(5):
		route_points.append(_route_point(index, 5))
	if route_points.size() >= 2:
		var selected_index := clampi(_selected_stage_index(), 0, 4)
		for index in range(route_points.size() - 1):
			var segment := PackedVector2Array([route_points[index], route_points[index + 1]])
			var secured := index < selected_index
			var frontier := index == selected_index
			var route_color := Color("#62e7d8") if secured else (Color("#f4b657") if frontier else Color("#74433b"))
			draw_polyline(segment, Color("#02080c"), 13.0, true)
			draw_polyline(segment, Color(route_color, 0.22), 8.0, true)
			draw_polyline(segment, Color(route_color, 0.92 if secured or frontier else 0.48), 2.5, true)
	for index in range(route_points.size()):
		var point := route_points[index]
		var active := index == clampi(_selected_stage_index(), 0, 4)
		draw_line(
			point + Vector2(0, 24),
			Vector2(point.x, horizon_y + 68),
			Color(CYAN, 0.18 if not active else 0.42),
			2.0,
			true
		)
		var hostile := index > clampi(_selected_stage_index(), 0, 4)
		var node_color := Color("#f08b58") if hostile else CYAN
		draw_circle(point, 34.0 if active else 28.0, Color(node_color, 0.07 if not active else 0.18))
		draw_arc(
			point,
			35.0 if active else 31.0,
			0.0,
			TAU,
			32,
			Color(node_color, 0.78 if active else 0.28),
			2.0,
			true
		)
		_draw_landmark(index, point, active, horizon_y)
	_draw_frontier_searchlights(viewport_size, horizon_y)


func _draw_sky_atmosphere(viewport_size: Vector2, horizon_y: float) -> void:
	for band in range(8):
		var t := float(band) / 7.0
		var band_y := horizon_y * t
		draw_rect(
			Rect2(0, band_y, viewport_size.x, horizon_y / 7.0 + 2.0),
			Color("#07121d").lerp(Color("#15313a"), t)
		)
	var hostile_center := Vector2(viewport_size.x * 0.82, horizon_y * 0.63)
	for radius in range(150, 20, -18):
		draw_circle(hostile_center, float(radius), Color("#e56b3e", 0.006 + (150.0 - radius) * 0.00008))
	draw_circle(Vector2(viewport_size.x * 0.78, horizon_y * 0.22), 13.0, Color("#d7e7e6", 0.28))
	draw_circle(Vector2(viewport_size.x * 0.78, horizon_y * 0.22), 19.0, Color("#89d4d0", 0.04))


func _draw_territory_fields(viewport_size: Vector2, horizon_y: float) -> void:
	var selected_x := _route_point(clampi(_selected_stage_index(), 0, 4), 5).x
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon_y * 0.58), Vector2(selected_x, horizon_y * 0.72),
		Vector2(selected_x, viewport_size.y), Vector2(0, viewport_size.y),
	]), Color("#2cc7c0", 0.035))
	draw_colored_polygon(PackedVector2Array([
		Vector2(selected_x, horizon_y * 0.72), Vector2(viewport_size.x, horizon_y * 0.45),
		Vector2(viewport_size.x, viewport_size.y), Vector2(selected_x, viewport_size.y),
	]), Color("#d85d3f", 0.045))


func _draw_frontier_searchlights(viewport_size: Vector2, horizon_y: float) -> void:
	var source_a := Vector2(viewport_size.x * 0.83, horizon_y * 0.47)
	var source_b := Vector2(viewport_size.x * 0.94, horizon_y * 0.39)
	draw_colored_polygon(PackedVector2Array([
		source_a, Vector2(viewport_size.x * 0.58, horizon_y), Vector2(viewport_size.x * 0.69, horizon_y)
	]), Color("#ffd2a3", 0.055))
	draw_colored_polygon(PackedVector2Array([
		source_b, Vector2(viewport_size.x * 0.70, horizon_y * 0.92), Vector2(viewport_size.x * 0.80, horizon_y)
	]), Color("#ffb273", 0.05))
	draw_circle(source_a, 3.5, Color("#ffca8a", 0.8))
	draw_circle(source_b, 3.5, Color("#ffca8a", 0.8))


func _build_chapter_switcher() -> void:
	var previous_chapter := _selected_chapter - 1
	var previous := _button(
		"‹ 已是首章" if previous_chapter < 1 else "‹ %s" % _chapter_label(previous_chapter),
		false
	)
	previous.name = "PreviousChapterButton"
	previous.custom_minimum_size = Vector2(70, 34) if _is_compact_layout() else Vector2(86, 36)
	previous.disabled = previous_chapter < 1
	previous.pressed.connect(_on_chapter_pressed.bind(previous_chapter))
	chapter_nav.add_child(previous)
	var current := _button(_chapter_label(_selected_chapter), true)
	current.name = "CurrentChapterButton"
	current.custom_minimum_size = Vector2(88, 34) if _is_compact_layout() else Vector2(112, 36)
	current.pressed.connect(_on_chapter_pressed.bind(_selected_chapter))
	chapter_nav.add_child(current)
	var next_chapter := _selected_chapter + 1
	var next := _button(
		"战役终点 ›" if next_chapter > 6 else "%s ›" % _chapter_label(next_chapter),
		false
	)
	next.name = "NextChapterButton"
	next.custom_minimum_size = Vector2(70, 34) if _is_compact_layout() else Vector2(86, 36)
	next.disabled = next_chapter > 6 or next_chapter > _highest_chapter
	next.pressed.connect(_on_chapter_pressed.bind(next_chapter))
	chapter_nav.add_child(next)


func _chapter_label(chapter: int) -> String:
	if chapter == 6:
		return "无尽前线"
	if chapter < 1 or chapter > 6:
		return "战线边界"
	return "第%d章" % chapter


func _stage_location_name(display_name: String) -> String:
	var candidate := display_name.strip_edges()
	if candidate.contains("·"):
		var parts := candidate.split("·")
		candidate = parts[parts.size() - 1].strip_edges()
	if candidate.length() > 7:
		candidate = candidate.left(7)
	return candidate


func _draw_landmark(
	index: int,
	point: Vector2,
	active: bool,
	horizon_y: float
) -> void:
	var color := Color(CYAN, 0.55 if active else 0.28)
	var ground_y := minf(horizon_y + 6.0, point.y + 58.0)
	match index:
		0:
			draw_rect(Rect2(point + Vector2(-25, 28), Vector2(16, ground_y - point.y - 28)), color)
			draw_rect(Rect2(point + Vector2(8, 20), Vector2(18, ground_y - point.y - 20)), color)
		1:
			draw_colored_polygon(PackedVector2Array([
				point + Vector2(-20, 32),
				point + Vector2(0, 12),
				point + Vector2(20, 32),
			]), color)
			draw_rect(Rect2(point + Vector2(-13, 32), Vector2(26, ground_y - point.y - 32)), color)
		2:
			draw_line(point + Vector2(0, 22), Vector2(point.x, ground_y), color, 5.0)
			draw_line(point + Vector2(-17, 36), point + Vector2(17, 36), color, 3.0)
			draw_circle(point + Vector2(0, 17), 4.0, color)
		3:
			draw_rect(Rect2(point + Vector2(-27, 27), Vector2(54, ground_y - point.y - 27)), color)
			for offset in [-21.0, -7.0, 7.0, 21.0]:
				draw_rect(Rect2(point + Vector2(offset - 3, 20), Vector2(6, 9)), color)
		4:
			var core := point + Vector2(0, 28)
			draw_colored_polygon(PackedVector2Array([
				core + Vector2(0, -12),
				core + Vector2(13, 0),
				core + Vector2(0, 12),
				core + Vector2(-13, 0),
			]), color)
			draw_line(core + Vector2(0, 12), Vector2(core.x, ground_y), color, 5.0)


func _draw_city_silhouette(viewport_size: Vector2, horizon_y: float) -> void:
	var block_width := viewport_size.x / 18.0
	for index in range(18):
		var height := 14.0 + float((index * 11 + 3) % 7) * 7.0
		var rect := Rect2(
			index * block_width - 3.0,
			horizon_y - height,
			block_width + 5.0,
			height
		)
		var hostile_side := index >= 12
		draw_rect(rect, Color("#17242a") if hostile_side else Color("#0d252c"))
		if index % 5 == 2:
			draw_colored_polygon(PackedVector2Array([
				Vector2(rect.position.x, rect.position.y),
				Vector2(rect.position.x + rect.size.x * 0.62, rect.position.y - 9.0),
				Vector2(rect.end.x, rect.position.y + 3.0),
			]), Color("#111d22"))
		if index % 3 == 1:
			draw_rect(
				Rect2(rect.position + Vector2(block_width * 0.24, 8), Vector2(4, 3)),
				Color("#ef754d", 0.58) if hostile_side else Color(CYAN, 0.35)
			)
		if index % 4 == 2:
			draw_line(
				Vector2(rect.get_center().x, rect.position.y),
				Vector2(rect.get_center().x, rect.position.y - 12),
				Color(CYAN, 0.35),
				2.0
			)


func _draw_tactical_grid(viewport_size: Vector2, horizon_y: float) -> void:
	for index in range(4):
		var y := lerpf(horizon_y + 14.0, viewport_size.y - 5.0, float(index) / 5.0)
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), Color(CYAN, 0.045), 1.0)
	for index in range(6):
		var x := viewport_size.x * float(index) / 5.0
		draw_line(
			Vector2(viewport_size.x * 0.5, horizon_y),
			Vector2(x, viewport_size.y),
			Color(CYAN, 0.035),
			1.0
		)


func _route_point(index: int, count: int) -> Vector2:
	var viewport_size := size
	var t := float(index) / float(maxi(1, count - 1))
	var x := lerpf(
		viewport_size.x * (0.08 if _is_compact_layout() else 0.10),
		viewport_size.x * (0.91 if _is_compact_layout() else 0.72),
		t
	)
	return Vector2(
		x,
		viewport_size.y * ROUTE_Y_FACTORS[clampi(index, 0, ROUTE_Y_FACTORS.size() - 1)]
	)


func _selected_stage_index() -> int:
	var visible_rows := _visible_stage_rows()
	for index in range(visible_rows.size()):
		if String(visible_rows[index].get("stage_id", "")) == _selected_stage_id:
			return index
	return 0


func _visible_stage_rows() -> Array[Dictionary]:
	if _stage_rows.size() <= 5:
		return _stage_rows.duplicate(true)
	var selected_index := 0
	for index in range(_stage_rows.size()):
		if String(_stage_rows[index].get("stage_id", "")) == _selected_stage_id:
			selected_index = index
			break
	var start := clampi(selected_index - 2, 0, _stage_rows.size() - 5)
	var result: Array[Dictionary] = []
	for index in range(start, start + 5):
		result.append((_stage_rows[index] as Dictionary).duplicate(true))
	return result


func _button(value: String, selected: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override(
		"normal",
		_selected_navigation_style() if selected else UiArtDirectionScript.button_style(false)
	)
	button.add_theme_stylebox_override(
		"hover",
		_selected_navigation_style(true) if selected else UiArtDirectionScript.button_style(false, "hover")
	)
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(false, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(false, "focus"))
	button.add_theme_stylebox_override("disabled", UiArtDirectionScript.button_style(false, "disabled"))
	button.add_theme_color_override("font_color", CYAN if selected else TEXT)
	button.add_theme_color_override("font_hover_color", CYAN if selected else TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	return button


func _stage_node_button(value: String, selected: bool, recovered: bool, unlocked: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 13)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(
			state,
			_stage_node_style(selected, recovered, unlocked, state)
		)
	button.add_theme_stylebox_override("disabled", _stage_node_style(false, recovered, false, "disabled"))
	var state_color := CYAN if recovered else (GOLD if unlocked else Color("#c37a61"))
	button.add_theme_color_override("font_color", Color.WHITE if selected else state_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.72))
	return button


func _stage_node_style(selected: bool, recovered: bool, unlocked: bool, state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var state_color := CYAN if recovered else (GOLD if unlocked else Color("#b9654e"))
	style.bg_color = Color("#10242b", 0.97) if recovered else Color("#251b1b", 0.96)
	if selected:
		style.bg_color = Color("#3b2a1d", 0.98)
	style.border_color = Color.WHITE if selected else Color(state_color, 0.58)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(24)
	if state == "hover":
		style.bg_color = Color("#174049")
		style.border_color = CYAN
	elif state == "pressed":
		style.bg_color = Color("#0b1c21")
	elif state == "focus":
		style.border_color = Color.WHITE
		style.set_border_width_all(2)
	elif state == "disabled":
		style.bg_color = Color("#11191d", 0.92)
		style.border_color = Color(LINE, 0.8)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _selected_navigation_style(hover := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#122229") if not hover else Color("#193239")
	style.border_color = CYAN
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


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

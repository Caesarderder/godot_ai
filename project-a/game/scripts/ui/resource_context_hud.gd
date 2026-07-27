class_name ResourceContextHud
extends PanelContainer

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL := Color("#151c21")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")
const RED := Color("#d95c4f")

var _content: VBoxContainer
var _heading: Label
var _grid: GridContainer
var _note: Label
var _compact_row: HBoxContainer


func _init() -> void:
	add_theme_stylebox_override("panel", _panel_style())
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 3)
	add_child(_content)
	_heading = _label("", 11, CYAN)
	_heading.name = "ResourceContextHeading"
	_content.add_child(_heading)
	_grid = GridContainer.new()
	_grid.name = "ResourceContextGrid"
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 2)
	_content.add_child(_grid)
	_note = _label("", 10, MUTED)
	_note.name = "ResourceContextNote"
	_content.add_child(_note)
	_compact_row = HBoxContainer.new()
	_compact_row.name = "ResourceContextCompactRow"
	_compact_row.add_theme_constant_override("separation", 5)
	_content.add_child(_compact_row)


func configure(view: Dictionary) -> void:
	name = String(view.get("name", "ResourceContextHUD"))
	var compact := bool(view.get("compact", false))
	_heading.text = String(view.get("title", "相关资源"))
	_heading.visible = not compact and not _heading.text.is_empty()
	_grid.columns = clampi(int(view.get("columns", 3)), 1, 4)
	_grid.visible = not compact
	for child in _grid.get_children():
		child.free()
	for child in _compact_row.get_children():
		child.free()
	for item_value in view.get("items", []):
		var item := item_value as Dictionary
		var meter := _label(_projection_copy(item), 10, _projection_color(item))
		meter.name = "Resource_%s" % String(item.get("id", "unknown"))
		meter.tooltip_text = _tooltip_copy(item)
		meter.custom_minimum_size.x = int(view.get("item_min_width", 92))
		_grid.add_child(meter)
	_note.text = String(view.get("note", ""))
	_note.visible = not compact and not _note.text.is_empty()
	_compact_row.visible = compact
	if compact:
		var compact_heading := _label(_heading.text, 10, CYAN)
		compact_heading.name = "ResourceContextCompactHeading"
		compact_heading.custom_minimum_size.x = int(view.get("compact_heading_width", 112))
		compact_row_add(compact_heading)
		for item_value in view.get("items", []):
			var item := item_value as Dictionary
			var compact_meter := _label(_projection_copy(item), 9, _projection_color(item))
			compact_meter.name = "CompactResource_%s" % String(item.get("id", "unknown"))
			compact_meter.tooltip_text = _tooltip_copy(item)
			compact_meter.autowrap_mode = TextServer.AUTOWRAP_OFF
			compact_meter.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			compact_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			compact_row_add(compact_meter)


func compact_row_add(control: Control) -> void:
	_compact_row.add_child(control)


static func projection_copy(item: Dictionary) -> String:
	return _projection_copy(item)


static func _projection_copy(item: Dictionary) -> String:
	var display_name := String(item.get("short_name", item.get("name", "资源")))
	var current := int(item.get("current", 0))
	if not item.has("required"):
		return "%s %d" % [display_name, current]
	var required := int(item.get("required", 0))
	if bool(item.get("waived", false)):
		return "%s %d/%d · 免" % [display_name, current, required]
	var after := current - required
	if after >= 0:
		return "%s %d/%d → %d" % [display_name, current, required, after]
	return "%s %d/%d · 缺%d" % [display_name, current, required, -after]


static func _projection_color(item: Dictionary) -> Color:
	if not item.has("required"):
		return TEXT
	if bool(item.get("waived", false)):
		return CYAN
	return GREEN if int(item.get("current", 0)) >= int(item.get("required", 0)) else RED


static func _tooltip_copy(item: Dictionary) -> String:
	var display_name := String(item.get("name", "资源"))
	var current := int(item.get("current", 0))
	if not item.has("required"):
		return "%s当前拥有 %d" % [display_name, current]
	var required := int(item.get("required", 0))
	if bool(item.get("waived", false)):
		return "%s当前 %d，本次原需 %d，已免除" % [display_name, current, required]
	var after := current - required
	return (
		"%s当前 %d，需要 %d，操作后剩余 %d" % [display_name, current, required, after]
		if after >= 0
		else "%s当前 %d，需要 %d，还缺 %d" % [display_name, current, required, -after]
	)


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.focus_mode = Control.FOCUS_NONE
	label.add_theme_font_override("font", CJK_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(LINE, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

class_name BattleArena
extends Control

const TEAM_HERO := 0

var _units: Array[BattleUnit] = []
var _max_hp: Dictionary = {}
var _damage_popups: Array[Dictionary] = []
var _formation_labels: Dictionary = {}


func _ready() -> void:
	set_process(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func present_units(units: Array[BattleUnit], formation_labels: Dictionary = {}) -> void:
	_units = units
	_formation_labels = formation_labels.duplicate()
	_max_hp.clear()
	_damage_popups.clear()
	for unit: BattleUnit in _units:
		_max_hp[unit.unit_id] = maxi(unit.hp, 1)
	queue_redraw()


func show_damage(unit_id: String, damage: int) -> void:
	_damage_popups.append({"unit_id": unit_id, "damage": damage, "life": 0.8})
	queue_redraw()


func clear_battle() -> void:
	_units.clear()
	_max_hp.clear()
	_damage_popups.clear()
	queue_redraw()


func presented_unit_count() -> int:
	return _units.size()


func _process(delta: float) -> void:
	var retained: Array[Dictionary] = []
	for popup: Dictionary in _damage_popups:
		popup["life"] = float(popup["life"]) - delta
		if float(popup["life"]) > 0.0:
			retained.append(popup)
	_damage_popups = retained
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_style_box(_panel_style(Color("18233a"), Color("30486f"), 22), bounds)
	_draw_ground()
	for unit: BattleUnit in _units:
		_draw_unit(unit)
	for popup: Dictionary in _damage_popups:
		_draw_damage_popup(popup)


func _draw_ground() -> void:
	var center_y := size.y * 0.6
	draw_line(Vector2(28, center_y), Vector2(size.x - 28, center_y), Color("405775"), 3.0)
	draw_circle(Vector2(size.x * 0.5, center_y), 72.0, Color("20334d"))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(size.x * 0.5 - 28, center_y + 7),
		"VS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		24,
		Color("8ba7cc")
	)


func _draw_unit(unit: BattleUnit) -> void:
	var position_on_field := _unit_position(unit)
	var alive := unit.hp > 0
	var body_color := _hero_color(unit.slot) if unit.team == TEAM_HERO else Color("d25465")
	if not alive:
		body_color = body_color.darkened(0.65)
	# Simple silhouettes keep the battle readable without requiring external art.
	draw_circle(position_on_field - Vector2(0, 28), 27.0, body_color)
	draw_style_box(
		_panel_style(body_color.darkened(0.2), body_color.lightened(0.16), 16),
		Rect2(position_on_field + Vector2(-34, -5), Vector2(68, 66))
	)
	var display_name := "魔像" if unit.team != TEAM_HERO else str(
		_formation_labels.get(unit.unit_id, "英雄 %d" % (unit.slot + 1))
	)
	draw_string(
		ThemeDB.fallback_font,
		position_on_field + Vector2(-58, 88),
		display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		116,
		19,
		Color.WHITE if alive else Color("718096")
	)
	var hp_width := 112.0
	var hp_rect := Rect2(position_on_field + Vector2(-56, 68), Vector2(hp_width, 10))
	draw_rect(hp_rect, Color("0d1524"))
	var max_hp := maxi(int(_max_hp.get(unit.unit_id, 1)), 1)
	var fraction := clampf(float(unit.hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(hp_rect.position, Vector2(hp_width * fraction, 10)), Color("58d68d"))
	draw_string(
		ThemeDB.fallback_font,
		position_on_field + Vector2(-56, 63),
		"HP %d/%d" % [unit.hp, max_hp],
		HORIZONTAL_ALIGNMENT_CENTER,
		112,
		15,
		Color("dce8f7")
	)


func _draw_damage_popup(popup: Dictionary) -> void:
	var unit := _find_unit(str(popup["unit_id"]))
	if unit == null:
		return
	var life := float(popup["life"])
	var rise := (0.8 - life) * 55.0
	var point := _unit_position(unit) + Vector2(-42, -88 - rise)
	draw_string(
		ThemeDB.fallback_font,
		point,
		"-%d" % int(popup["damage"]),
		HORIZONTAL_ALIGNMENT_CENTER,
		84,
		28,
		Color(1.0, 0.76, 0.3, clampf(life / 0.25, 0.0, 1.0))
	)


func _find_unit(unit_id: String) -> BattleUnit:
	for unit: BattleUnit in _units:
		if unit.unit_id == unit_id:
			return unit
	return null


func _unit_position(unit: BattleUnit) -> Vector2:
	if unit.team != TEAM_HERO:
		return Vector2(size.x * 0.78, size.y * 0.48)
	var column := unit.slot % 2
	@warning_ignore("integer_division")
	var row: int = unit.slot / 2
	return Vector2(size.x * (0.14 + column * 0.19), size.y * (0.34 + row * 0.35))


func _hero_color(slot: int) -> Color:
	var colors: Array[Color] = [Color("4d9de0"), Color("59c3c3"), Color("8f7ee7"), Color("e29a55")]
	return colors[clampi(slot, 0, colors.size() - 1)]


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style

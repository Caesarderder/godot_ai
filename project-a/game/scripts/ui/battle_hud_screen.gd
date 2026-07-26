class_name BattleHudScreen
extends VBoxContainer

signal pause_requested
signal skill_mode_requested
signal retreat_requested
signal skill_requested(unit_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL := Color("#0b1117e8")
const PANEL_2 := Color("#111a21")
const LINE := Color("#42525d")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const RED := Color("#d95c4f")
const GREEN := Color("#78b982")

@onready var status_label: Label = %BattleTacticalStatus
@onready var pause_button: Button = %BattlePauseButton
@onready var skill_mode_button: Button = %BattleSkillModeButton
@onready var retreat_button: Button = %BattleRetreatButton
@onready var skill_grid: GridContainer = %BattleSkillGrid

var _manual_skills := false
var _warning_tactic := "点亮技能集中爆发"
var _first_skill_tutorial := false
var _first_skill_confirmed := false
var _skill_confirmation_updates := 0
var _reinforcement_rally_updates := 0
var _unit_hud: Dictionary = {}
var _skill_buttons: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	pause_button.pressed.connect(pause_requested.emit)
	skill_mode_button.pressed.connect(skill_mode_requested.emit)
	retreat_button.pressed.connect(retreat_requested.emit)


func configure(
	snapshots: Array[Dictionary],
	manual_skills: bool,
	first_skill_tutorial: bool = false,
	reinforcement_rally: bool = false
) -> void:
	_manual_skills = manual_skills
	_first_skill_tutorial = first_skill_tutorial
	_first_skill_confirmed = false
	_skill_confirmation_updates = 0
	_reinforcement_rally_updates = 10 if reinforcement_rally else 0
	_warning_tactic = _warning_tactic_for(snapshots)
	skill_mode_button.text = "技能：手动" if _manual_skills else "技能：自动"
	skill_grid.columns = maxi(1, snapshots.size())
	_clear_units()
	for snapshot in snapshots:
		var card := _build_unit_card(snapshot)
		var unit_id := String(snapshot.get("hero_id", ""))
		_skill_buttons[unit_id] = card["button"]
		_unit_hud[unit_id] = card
		skill_grid.add_child(card["root"])


func set_manual_skills(enabled: bool) -> void:
	_manual_skills = enabled
	skill_mode_button.text = "技能：手动" if enabled else "技能：自动"


func confirm_skill_requested() -> void:
	if not _first_skill_tutorial or _first_skill_confirmed:
		return
	_first_skill_confirmed = true
	_skill_confirmation_updates = 5


func skill_buttons() -> Dictionary:
	return _skill_buttons.duplicate()


func apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var objective_copy := _objective_copy(snapshot)
	var warnings := snapshot.get("warnings", []) as Array
	var warning_copy := ""
	if not warnings.is_empty():
		var warning := warnings[0] as Dictionary
		warning_copy = " · 炮击 %0.1f秒 · %s" % [
			float(warning.get("remaining_ticks", 0)) / 5.0,
			_warning_tactic,
		]
	var battle_status := "阶段 %d/%d · %s · 战线 %d%%%s" % [
		int(snapshot.get("stage_index", 0)) + 1,
		int(snapshot.get("stage_count", 3)),
		objective_copy if not objective_copy.is_empty() else String(snapshot.get("stage_name", "推进中")),
		clampi(int(snapshot.get("road_progress", 0)) / 10, 0, 100),
		warning_copy,
	]
	var ready_unit_name := ""
	for unit_value in snapshot.get("units", []):
		var unit := unit_value as Dictionary
		if bool(unit.get("temporary", false)):
			continue
		_apply_unit_snapshot(unit)
		if (
			_manual_skills
			and bool(unit.get("alive", false))
			and int(unit.get("energy", 0)) >= 100
			and ready_unit_name.is_empty()
		):
			ready_unit_name = _unit_display_name(String(unit.get("unit_id", "")))
	status_label.text = battle_status
	status_label.add_theme_color_override("font_color", RED if not warnings.is_empty() else GOLD)
	if _skill_confirmation_updates > 0:
		status_label.text = "指令生效 · %s 正在释放主动技能" % ready_unit_name if not ready_unit_name.is_empty() else "指令生效 · 主动技能正在释放"
		status_label.add_theme_color_override("font_color", GREEN)
		_skill_confirmation_updates -= 1
	elif _reinforcement_rally_updates > 0 and warnings.is_empty():
		status_label.text = "援军已就位 · 装甲前排承伤，冲锋快速压制"
		status_label.add_theme_color_override("font_color", CYAN)
		_reinforcement_rally_updates -= 1
	elif (
		_first_skill_tutorial
		and not _first_skill_confirmed
		and _manual_skills
		and not ready_unit_name.is_empty()
		and warnings.is_empty()
	):
		status_label.text = "%s · 技能已充满 · 点击下方发光的 %s 卡释放" % [
			objective_copy if not objective_copy.is_empty() else "继续推进",
			ready_unit_name,
		]
		status_label.add_theme_color_override("font_color", GOLD)


func _objective_copy(snapshot: Dictionary) -> String:
	var stage_index := int(snapshot.get("stage_index", 0))
	for structure_value in snapshot.get("structures", []):
		var structure := structure_value as Dictionary
		if int(structure.get("stage", -1)) != stage_index or not bool(structure.get("alive", false)):
			continue
		var max_hp := maxi(1, int(structure.get("max_hp", 1)))
		var durability := clampi(
			ceili(float(maxi(0, int(structure.get("hp", 0)))) * 100.0 / float(max_hp)),
			0,
			100
		)
		var verb := "摧毁" if String(structure.get("kind", "")) in ["city", "core"] else "突破"
		return "%s%s · 耐久 %d%%" % [
			verb,
			String(structure.get("display_name", "防御结构")),
			durability,
		]
	return ""


func _warning_tactic_for(snapshots: Array[Dictionary]) -> String:
	for snapshot in snapshots:
		if String(snapshot.get("skill_id", "")) == "siege_shield" and int(snapshot.get("star", 1)) >= 2:
			return "点装甲护盾扛炮"
	for snapshot in snapshots:
		if String(snapshot.get("skill_id", "")) == "assault_rush":
			return "点冲锋技能打断"
	return "点亮技能集中爆发"


func _apply_unit_snapshot(unit: Dictionary) -> void:
	var unit_id := String(unit.get("unit_id", ""))
	var button := _skill_buttons.get(unit_id) as Button
	if button == null:
		return
	var hud := _unit_hud.get(unit_id, {}) as Dictionary
	var energy := clampi(int(unit.get("energy", 0)), 0, 100)
	var hp := maxi(0, int(unit.get("hp", 0)))
	var max_hp := maxi(1, int(unit.get("max_hp", 1)))
	var alive := bool(unit.get("alive", false))
	button.disabled = not _manual_skills or not alive or energy < 100
	var hp_bar := hud.get("hp_bar") as ProgressBar
	var energy_bar := hud.get("energy_bar") as ProgressBar
	var hp_label := hud.get("hp_label") as Label
	var energy_label := hud.get("energy_label") as Label
	var state_label := hud.get("state_label") as Label
	var root := hud.get("root") as PanelContainer
	root.add_theme_stylebox_override("panel", _unit_card_style(false))
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	_set_progress_fill(hp_bar, GREEN if hp * 3 > max_hp else RED)
	energy_bar.value = energy
	_set_progress_fill(energy_bar, GOLD if energy >= 100 else CYAN)
	hp_label.text = "%d/%d" % [hp, max_hp]
	energy_label.text = "%d%%" % energy
	if not alive:
		state_label.text = "阵亡"
		state_label.add_theme_color_override("font_color", RED)
	elif energy >= 100:
		var tutorial_ready := _first_skill_tutorial and not _first_skill_confirmed and _manual_skills
		state_label.text = "点击整张卡" if tutorial_ready else ("技能就绪" if _manual_skills else "自动释放")
		state_label.add_theme_color_override("font_color", GOLD)
		if tutorial_ready:
			root.add_theme_stylebox_override("panel", _unit_card_style(true))
	else:
		state_label.text = "充能中"
		state_label.add_theme_color_override("font_color", MUTED)


func _build_unit_card(snapshot: Dictionary) -> Dictionary:
	var unit_id := String(snapshot.get("hero_id", ""))
	var root := PanelContainer.new()
	root.name = "BattleUnitCard_%s" % unit_id
	root.custom_minimum_size = Vector2(116, 72)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_stylebox_override("panel", _unit_card_style(false))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	root.add_child(stack)
	var header := HBoxContainer.new()
	var name_label := _label("%s · %s" % [
		String(snapshot.get("display_name", unit_id)),
		String(snapshot.get("skill_display_name", "主动技能")),
	], 12, TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(name_label)
	var state_label := _label("充能中", 10, MUTED)
	state_label.name = "BattleUnitStateLabel"
	state_label.custom_minimum_size.x = 52
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(state_label)
	stack.add_child(header)
	var hp := _meter_row("HP", GREEN, int(snapshot.get("max_hp", 1)), int(snapshot.get("max_hp", 1)))
	stack.add_child(hp["root"])
	var energy := _meter_row("EN", CYAN, 0, 100)
	stack.add_child(energy["root"])
	var skill := Button.new()
	skill.name = "BattleSkillButton_%s" % unit_id
	skill.flat = true
	skill.focus_mode = Control.FOCUS_ALL
	skill.custom_minimum_size.y = 72
	skill.tooltip_text = "%s\n%s" % [
		String(snapshot.get("skill_display_name", "主动技能")),
		String(snapshot.get("skill_timing", "能量达到 100% 后释放")),
	]
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled"]:
		skill.add_theme_stylebox_override(state, empty_style)
	skill.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), 6, Color.WHITE))
	skill.pressed.connect(skill_requested.emit.bind(unit_id))
	root.add_child(skill)
	skill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return {
		"root": root,
		"button": skill,
		"display_name": String(snapshot.get("display_name", unit_id)),
		"hp_bar": hp["bar"],
		"energy_bar": energy["bar"],
		"hp_label": hp["value"],
		"energy_label": energy["value"],
		"state_label": state_label,
	}


func _unit_display_name(unit_id: String) -> String:
	var hud := _unit_hud.get(unit_id, {}) as Dictionary
	return String(hud.get("display_name", unit_id))


func _unit_card_style(highlighted: bool) -> StyleBoxFlat:
	var style := _box(PANEL_2, 6, GOLD if highlighted else Color("#3b4a54"))
	if highlighted:
		style.set_border_width_all(2)
	return style


func _meter_row(tag_text: String, color: Color, value: int, maximum: int) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var tag := _label(tag_text, 9, color)
	tag.custom_minimum_size.x = 18
	row.add_child(tag)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maxi(1, maximum)
	bar.value = value
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_progress_fill(bar, color)
	row.add_child(bar)
	var value_label := _label("%d%s" % [value, "%" if tag_text == "EN" else "/%d" % maximum], 9, color)
	value_label.custom_minimum_size.x = 42
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return {"root": row, "bar": bar, "value": value_label}


func _apply_theme() -> void:
	%BattleBottomHud.add_theme_stylebox_override("panel", _box(PANEL, 8, LINE))
	for label: Label in [status_label]:
		label.add_theme_font_override("font", CJK_FONT)
	for button: Button in [pause_button, skill_mode_button, retreat_button]:
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_override("font", CJK_FONT)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", _box(Color("#1a2228"), 7, LINE))
		button.add_theme_stylebox_override("hover", _box(Color("#24333a"), 7, CYAN))
		button.add_theme_stylebox_override("pressed", _box(Color("#17383a"), 7, CYAN))
		button.add_theme_stylebox_override("focus", _box(Color("#17383a"), 7, Color.WHITE))


func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", CJK_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _set_progress_fill(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#252f36")
	background.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)


func _box(color: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _clear_units() -> void:
	_skill_buttons.clear()
	_unit_hud.clear()
	for child in skill_grid.get_children():
		child.queue_free()

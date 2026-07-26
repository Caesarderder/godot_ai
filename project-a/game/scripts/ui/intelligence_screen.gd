class_name IntelligenceScreen
extends HBoxContainer

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
const RED := Color("#d95c4f")

@onready var capability_panel: PanelContainer = %WarCapabilityPanel
@onready var sustain_panel: PanelContainer = %WarSustainPanel
@onready var target_heading: Label = %IntelligenceTargetHeading
@onready var formation_power: Label = %IntelligenceFormationPower
@onready var recommended_power: Label = %IntelligenceRecommendedPower
@onready var capability_bar: ProgressBar = %IntelligenceCapabilityBar
@onready var capability_copy: Label = %IntelligenceCapabilityCopy
@onready var risk_detail: Label = %IntelligenceRiskDetail
@onready var formation_count: Label = %IntelligenceFormationCount
@onready var weakest_resource: Label = %IntelligenceWeakestResource
@onready var next_action_title: Label = %IntelligenceNextActionTitle
@onready var next_action_detail: Label = %IntelligenceNextActionDetail
@onready var action_button: Button = %IntelligenceActionButton

var _view: Dictionary = {}
var _action_id := "attack"
var _stage_id := ""


func _ready() -> void:
	_apply_theme()
	action_button.pressed.connect(_on_action_pressed)
	if not _view.is_empty():
		_apply_view()
	_focus_action_after_layout()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()


func _apply_view() -> void:
	var report := _view.get("report", {}) as Dictionary
	_stage_id = String(_view.get("stage_id", ""))
	target_heading.text = "目标 · %s" % String(report.get("stage_name", "未知前线"))
	formation_power.text = "当前编队战力  %d" % int(report.get("cp_ready", 0))
	recommended_power.text = "关卡推荐  %d" % int(report.get("recommended_power", 0))
	var ratio_percent := int(round(float(report.get("capability_ratio", 0.0)) * 100.0))
	capability_bar.value = clampi(ratio_percent, 0, 130)
	var risk_id := String(report.get("risk_id", "extreme"))
	var risk_color := _risk_color(risk_id)
	var fill := StyleBoxFlat.new()
	fill.bg_color = risk_color
	fill.set_corner_radius_all(3)
	capability_bar.add_theme_stylebox_override("fill", fill)
	capability_copy.text = "能力比 %d%% · %s" % [ratio_percent, String(report.get("risk_label", ""))]
	capability_copy.add_theme_color_override("font_color", risk_color)
	risk_detail.text = String(report.get("risk_detail", ""))
	formation_count.text = "当前编队  %d/%d" % [
		int(report.get("ready_count", 0)),
		int(report.get("formation_size", 0)),
	]
	weakest_resource.text = "最紧缺后勤  %s %d%%" % [
		String(report.get("weakest_resource_label", "")),
		int(report.get("weakest_resource_percent", 0)),
	]
	var next_action := report.get("next_action", {}) as Dictionary
	next_action_title.text = String(next_action.get("title", "继续观察"))
	next_action_detail.text = String(next_action.get("detail", ""))
	_action_id = String(next_action.get("id", "attack"))
	action_button.text = "进入军团培养" if _action_id == "upgrade" else "立即出击"


func _on_action_pressed() -> void:
	action_requested.emit(_action_id, {"stage_id": _stage_id})


func _focus_action_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree() and action_button.is_inside_tree():
		action_button.grab_focus()


func _risk_color(risk_id: String) -> Color:
	if risk_id == "extreme":
		return RED
	if risk_id == "challenge":
		return GOLD
	if risk_id == "target":
		return CYAN
	return GREEN


func _apply_theme() -> void:
	for panel in [capability_panel, sustain_panel]:
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
	target_heading.add_theme_font_size_override("font_size", 17)
	target_heading.add_theme_color_override("font_color", CYAN)
	formation_power.add_theme_font_size_override("font_size", 20)
	formation_power.add_theme_color_override("font_color", CYAN)
	recommended_power.add_theme_font_size_override("font_size", 17)
	recommended_power.add_theme_color_override("font_color", GOLD)
	capability_copy.add_theme_font_size_override("font_size", 17)
	risk_detail.add_theme_font_size_override("font_size", 13)
	risk_detail.add_theme_color_override("font_color", MUTED)
	%IntelligenceLosslessRule.add_theme_color_override("font_color", GREEN)
	weakest_resource.add_theme_color_override("font_color", MUTED)
	next_action_title.add_theme_font_size_override("font_size", 18)
	next_action_title.add_theme_color_override("font_color", GREEN)
	next_action_detail.add_theme_color_override("font_color", MUTED)
	action_button.focus_mode = Control.FOCUS_ALL
	action_button.add_theme_font_override("font", CJK_FONT)
	action_button.add_theme_font_size_override("font_size", 15)
	action_button.add_theme_stylebox_override("normal", _button_style(GOLD, GOLD))
	action_button.add_theme_stylebox_override("hover", _button_style(GOLD.lightened(0.12), GOLD))
	action_button.add_theme_stylebox_override("pressed", _button_style(GOLD.darkened(0.18), GOLD))
	action_button.add_theme_stylebox_override("focus", _button_style(Color(GOLD, 0.22), Color.WHITE))
	action_button.add_theme_color_override("font_color", BG)


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

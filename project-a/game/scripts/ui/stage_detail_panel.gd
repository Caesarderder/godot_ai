class_name StageDetailPanel
extends PanelContainer

signal attack_requested(stage_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL := Color("#12171c")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const RED := Color("#d95c4f")
const GREEN := Color("#78b982")

@onready var stage_name: Label = %StageName
@onready var status_label: Label = %Status
@onready var threat_summary: Label = %ThreatSummary
@onready var decision_hint: Label = %DecisionHint
@onready var power_line: Label = %PowerLine
@onready var capability: ProgressBar = %Capability
@onready var risk_label: Label = %Risk
@onready var threat_level: Label = %ThreatLevel
@onready var attack_button: Button = %AttackButton

var _stage_id := ""
var _config: Dictionary = {}
var _report: Dictionary = {}
var _unlocked := false
var _cleared := false
var _estimated_threat := "未知"


func _ready() -> void:
	_apply_theme()
	attack_button.pressed.connect(_on_attack_pressed)
	if not _config.is_empty():
		_apply_configuration()


func configure(
	stage_id: String,
	config: Dictionary,
	report: Dictionary,
	unlocked: bool,
	cleared: bool,
	estimated_threat: String
) -> void:
	_stage_id = stage_id
	_config = config.duplicate(true)
	_report = report.duplicate(true)
	_unlocked = unlocked
	_cleared = cleared
	_estimated_threat = estimated_threat
	if is_node_ready():
		_apply_configuration()


func _apply_configuration() -> void:
	var status := "已夺回" if _cleared else ("等待命令" if _unlocked else "信号中断")
	var ratio_percent := clampi(int(round(float(_report.get("capability_ratio", 0.0)) * 100.0)), 0, 150)
	var risk_id := String(_report.get("risk_id", "extreme"))
	var risk_color := _risk_color(risk_id)
	stage_name.text = String(_config.get("display_name", _stage_id))
	stage_name.add_theme_color_override("font_color", GREEN if _cleared else TEXT)
	status_label.text = status
	status_label.add_theme_color_override("font_color", GREEN if _cleared else GOLD)
	threat_summary.text = String(_config.get("threat_summary", "联盟守军正在集结。"))
	decision_hint.text = "反制选择：%s" % String(
		_config.get("counter_hint", "观察敌方结构和阵容职责后再决定成长路线。")
	)
	power_line.text = "我方 %d  /  推荐 %d" % [
		int(_report.get("cp_ready", 0)),
		int(_report.get("recommended_power", 0)),
	]
	capability.value = mini(ratio_percent, 100)
	capability.add_theme_color_override("font_color", risk_color)
	risk_label.text = "能力比 %d%% · %s" % [ratio_percent, String(_report.get("risk_label", "未知"))]
	risk_label.add_theme_color_override("font_color", risk_color)
	threat_level.text = "威胁等级 · %s" % _estimated_threat
	threat_level.add_theme_color_override("font_color", RED if _estimated_threat == "高" else GOLD)
	attack_button.disabled = not _unlocked
	attack_button.text = "再次夺取" if _cleared else ("立即出击" if _unlocked else "尚未侦测")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.border_color = CYAN if _unlocked else LINE
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(14)
	add_theme_stylebox_override("panel", panel_style)


func _apply_theme() -> void:
	for label: Label in [stage_name, status_label, threat_summary, decision_hint, power_line, risk_label, threat_level]:
		label.add_theme_font_override("font", CJK_FONT)
	stage_name.add_theme_font_size_override("font_size", 23)
	status_label.add_theme_font_size_override("font_size", 12)
	threat_summary.add_theme_font_size_override("font_size", 15)
	threat_summary.add_theme_color_override("font_color", MUTED)
	decision_hint.add_theme_font_size_override("font_size", 13)
	decision_hint.add_theme_color_override("font_color", GOLD)
	power_line.add_theme_font_size_override("font_size", 17)
	power_line.add_theme_color_override("font_color", CYAN)
	risk_label.add_theme_font_size_override("font_size", 15)
	threat_level.add_theme_font_size_override("font_size", 14)
	attack_button.add_theme_font_override("font", CJK_FONT)
	attack_button.add_theme_font_size_override("font_size", 16)
	attack_button.focus_mode = Control.FOCUS_ALL
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color("#5b421e")
	focus.border_color = Color.WHITE
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(8)
	attack_button.add_theme_stylebox_override("focus", focus)


func _risk_color(risk_id: String) -> Color:
	match risk_id:
		"overwhelming", "stable":
			return GREEN
		"target":
			return CYAN
		"challenge":
			return GOLD
		_:
			return RED


func _on_attack_pressed() -> void:
	if not _stage_id.is_empty():
		attack_requested.emit(_stage_id)

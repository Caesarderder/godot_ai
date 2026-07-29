class_name StageDetailPanel
extends PanelContainer

signal attack_requested(stage_id: String)
signal preparation_requested(action_id: String)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const FactoryCatalog := preload("res://game/scripts/domain/factory/factory_catalog.gd")
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
@onready var boss_recovery_routes: VBoxContainer = %BossRecoveryRoutes
@onready var assault_recovery_route: Label = %BossRecoveryRoute_assault
@onready var armored_recovery_route: Label = %BossRecoveryRoute_armored
@onready var power_line: Label = %PowerLine
@onready var capability: ProgressBar = %Capability
@onready var risk_label: Label = %Risk
@onready var threat_level: Label = %ThreatLevel
@onready var next_action: Label = %NextAction
@onready var growth_button: Button = %GrowthButton
@onready var attack_button: Button = %AttackButton

var _stage_id := ""
var _config: Dictionary = {}
var _report: Dictionary = {}
var _unlocked := false
var _cleared := false
var _estimated_threat := "未知"
var _preparation_action_id := "upgrade"


func _ready() -> void:
	_apply_theme()
	attack_button.pressed.connect(_on_attack_pressed)
	growth_button.pressed.connect(_on_preparation_pressed)
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
	var faction_proof := _report.get("faction_proof", {}) as Dictionary
	var faction_protocol_preview := (
		_report.get("faction_protocol_preview", {}) as Dictionary
	)
	var formation_plan := _report.get("formation_plan", {}) as Dictionary
	_configure_boss_recovery_routes()
	if not faction_proof.is_empty():
		decision_hint.text = "%s\n%s" % [
			String(faction_proof.get("headline", "核心磨合")),
			String(faction_proof.get("focus", "")),
		]
		decision_hint.add_theme_color_override("font_color", CYAN)
	elif not faction_protocol_preview.is_empty():
		decision_hint.text = "阵营科技待命 · %d阶「%s」· 开战自动生效\n%s" % [
			int(faction_protocol_preview.get("tier", 1)),
			String(faction_protocol_preview.get("title", "阵营科技")),
			(
				"阵容核对 · 已覆盖：%s｜待补：%s" % [
					String(formation_plan.get("covered_copy", "无")),
					String(formation_plan.get("missing_copy", "无")),
				]
				if not formation_plan.is_empty()
				else String(faction_protocol_preview.get("effect", ""))
			),
		]
		decision_hint.add_theme_color_override("font_color", GOLD)
	elif formation_plan.is_empty():
		decision_hint.text = "反制选择：%s" % String(
			_config.get("counter_hint", "观察敌方结构和阵容职责后再决定成长路线。")
		)
	else:
		var plan_status := String(formation_plan.get("status_id", "missing"))
		var plan_consequence := "当前打法完整，可以直接出击。"
		if plan_status == "partial":
			plan_consequence = "已有可用解法；补齐建议角色会让职责更完整。"
		elif plan_status == "missing":
			plan_consequence = (
				"仓库已有反制角色，可先调整编队。"
				if bool(formation_plan.get("can_prepare", false))
				else "暂无建议角色，仍可凭战力与技能时机试探。"
			)
		decision_hint.text = "阵容核对 · 已覆盖：%s｜待补：%s\n%s" % [
			String(formation_plan.get("covered_copy", "无")),
			String(formation_plan.get("missing_copy", "无")),
			plan_consequence,
		]
	power_line.text = "我方 %d  /  推荐 %d" % [
		int(_report.get("cp_ready", 0)),
		int(_report.get("recommended_power", 0)),
	]
	capability.value = mini(ratio_percent, 100)
	capability.add_theme_color_override("font_color", risk_color)
	risk_label.text = "能力比 %d%% · %s · 威胁等级 · %s" % [
		ratio_percent,
		String(_report.get("risk_label", "未知")),
		_estimated_threat,
	]
	risk_label.add_theme_color_override("font_color", risk_color)
	threat_level.text = "威胁等级 · %s" % _estimated_threat
	threat_level.add_theme_color_override("font_color", RED if _estimated_threat == "高" else GOLD)
	threat_level.visible = false
	var action := _report.get("next_action", {}) as Dictionary
	var action_id := String(action.get("id", "attack"))
	var needs_preparation := action_id in ["upgrade", "research", "recruit", "formation"] and _unlocked and not _cleared
	var needs_discovery := action_id == "discover" and _unlocked and not _cleared
	var blocks_attack := bool(action.get("blocks_attack", false))
	var force_primary_attack := bool(
		faction_proof.get("force_primary_attack", false)
	)
	if force_primary_attack:
		needs_preparation = false
		needs_discovery = false
		blocks_attack = false
	_preparation_action_id = action_id
	next_action.text = "下一步 · %s" % String(action.get("title", "继续观察"))
	next_action.visible = needs_preparation or needs_discovery
	growth_button.visible = needs_preparation
	if action_id == "upgrade":
		growth_button.text = "先培养军团"
	elif action_id == "recruit":
		growth_button.text = String(action.get("title", "前往信号招募"))
	elif action_id == "formation":
		growth_button.text = "编入两名援军"
	else:
		growth_button.text = String(action.get("title", "建造研究所")) if needs_preparation else "先培养军团"
	attack_button.disabled = not _unlocked or blocks_attack
	attack_button.text = String(faction_proof.get("attack_label", "")) if not faction_proof.is_empty() else (
		"再次夺取"
		if _cleared
		else (
			"完成2★成长后解锁"
			if blocks_attack
			else (
			"仍要试探"
			if needs_preparation
			else ("试探炮台防线" if needs_discovery else ("立即出击" if _unlocked else "尚未侦测"))
			)
		)
	)
	if force_primary_attack:
		_style_pressure_test_action()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(PANEL, 0.9)
	panel_style.border_color = Color(CYAN, 0.72) if _unlocked else LINE
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(14)
	add_theme_stylebox_override("panel", panel_style)


func _apply_theme() -> void:
	for label: Label in [
		stage_name,
		status_label,
		threat_summary,
		decision_hint,
		assault_recovery_route,
		armored_recovery_route,
		power_line,
		risk_label,
		threat_level,
		next_action,
	]:
		label.add_theme_font_override("font", CJK_FONT)
	stage_name.add_theme_font_size_override("font_size", 23)
	status_label.add_theme_font_size_override("font_size", 12)
	threat_summary.add_theme_font_size_override("font_size", 15)
	threat_summary.add_theme_color_override("font_color", MUTED)
	decision_hint.add_theme_font_size_override("font_size", 13)
	decision_hint.add_theme_color_override("font_color", GOLD)
	for route_label in [assault_recovery_route, armored_recovery_route]:
		route_label.add_theme_font_size_override("font_size", 12)
		route_label.add_theme_color_override("font_color", CYAN)
	power_line.add_theme_font_size_override("font_size", 17)
	power_line.add_theme_color_override("font_color", CYAN)
	risk_label.add_theme_font_size_override("font_size", 15)
	threat_level.add_theme_font_size_override("font_size", 14)
	next_action.add_theme_font_size_override("font_size", 13)
	next_action.add_theme_color_override("font_color", GREEN)
	for button: Button in [growth_button, attack_button]:
		button.add_theme_font_override("font", CJK_FONT)
		button.add_theme_font_size_override("font_size", 16)
		button.focus_mode = Control.FOCUS_ALL
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color("#5b421e")
	focus.border_color = Color.WHITE
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(8)
	attack_button.add_theme_stylebox_override("focus", focus)
	growth_button.add_theme_stylebox_override("focus", focus)
	var growth_normal := StyleBoxFlat.new()
	growth_normal.bg_color = GOLD
	growth_normal.border_color = GOLD
	growth_normal.set_border_width_all(1)
	growth_normal.set_corner_radius_all(8)
	var growth_hover := growth_normal.duplicate() as StyleBoxFlat
	growth_hover.bg_color = GOLD.lightened(0.12)
	var growth_pressed := growth_normal.duplicate() as StyleBoxFlat
	growth_pressed.bg_color = GOLD.darkened(0.18)
	growth_button.add_theme_stylebox_override("normal", growth_normal)
	growth_button.add_theme_stylebox_override("hover", growth_hover)
	growth_button.add_theme_stylebox_override("pressed", growth_pressed)
	growth_button.add_theme_color_override("font_color", PANEL)
	growth_button.add_theme_color_override("font_hover_color", PANEL)
	growth_button.add_theme_color_override("font_pressed_color", PANEL)


func _configure_boss_recovery_routes() -> void:
	boss_recovery_routes.visible = _stage_id == "stage_1_5"
	if not boss_recovery_routes.visible:
		return
	var assault_name := String(
		FactoryCatalog.recipe("ordinary.assault").get(
			"display_name",
			"头套马桶人"
		)
	)
	var armored_name := String(
		FactoryCatalog.recipe("heavy.armored").get(
			"display_name",
			"装甲马桶人"
		)
	)
	assault_recovery_route.text = "快攻 · %s升至2★ → 抢拆炮台" % assault_name
	armored_recovery_route.text = "守势 · %s升至2★ → 格挡反震" % armored_name


func _style_pressure_test_action() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = GOLD
	normal.border_color = GOLD
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = GOLD.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = GOLD.darkened(0.18)
	attack_button.add_theme_stylebox_override("normal", normal)
	attack_button.add_theme_stylebox_override("hover", hover)
	attack_button.add_theme_stylebox_override("pressed", pressed)
	attack_button.add_theme_color_override("font_color", PANEL)
	attack_button.add_theme_color_override("font_hover_color", PANEL)
	attack_button.add_theme_color_override("font_pressed_color", PANEL)


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


func _on_preparation_pressed() -> void:
	preparation_requested.emit(_preparation_action_id)

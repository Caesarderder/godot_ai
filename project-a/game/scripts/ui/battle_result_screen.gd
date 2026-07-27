class_name BattleResultScreen
extends VBoxContainer

signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const RED := Color("#d95c4f")
const GREEN := Color("#78b982")

@onready var outcome_text: Label = %OutcomeText
@onready var reward_headline: Label = %RewardHeadline
@onready var hero_experience: Label = %HeroExperience
@onready var materials: Label = %Materials
@onready var mission_progress: Label = %MissionProgress
@onready var breakthrough: Label = %Breakthrough
@onready var unlocked_hero: Label = %UnlockedHero
@onready var combat_summary: Label = %CombatSummary
@onready var contribution: Label = %Contribution
@onready var hurdle_proof: Label = %HurdleProof
@onready var debrief: Label = %Debrief
@onready var growth: Label = %Growth
@onready var safety: Label = %Safety
@onready var qualification: Label = %Qualification
@onready var primary_action: Button = %PrimaryAction
@onready var factory_action: Button = %FactoryAction
@onready var base_action: Button = %BaseAction

var _view: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	primary_action.pressed.connect(_emit_primary_action)
	factory_action.pressed.connect(action_requested.emit.bind("factory", {}))
	base_action.pressed.connect(action_requested.emit.bind("base", {}))
	if not _view.is_empty():
		_apply_view()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()


func _apply_view() -> void:
	outcome_text.text = String(_view.get("outcome_banner", "战斗结束"))
	var outcome_color := _semantic_color(String(_view.get("outcome_color", "gold")))
	outcome_text.add_theme_color_override("font_color", outcome_color)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(outcome_color, 0.12)
	banner_style.border_color = outcome_color
	banner_style.set_border_width_all(1)
	banner_style.set_corner_radius_all(8)
	$OutcomeBanner.add_theme_stylebox_override("panel", banner_style)
	_set_optional(reward_headline, String(_view.get("reward_headline", "")))
	_set_optional(hero_experience, String(_view.get("hero_experience", "")))
	_set_optional(materials, String(_view.get("materials", "")))
	_set_optional(mission_progress, String(_view.get("mission_progress", "")))
	_set_optional(breakthrough, String(_view.get("breakthrough", "")))
	_set_optional(unlocked_hero, String(_view.get("unlocked_hero", "")))
	_set_optional(combat_summary, String(_view.get("combat_summary", "")))
	_set_optional(contribution, String(_view.get("contribution", "")))
	_set_optional(hurdle_proof, String(_view.get("hurdle_proof", "")))
	_set_optional(debrief, String(_view.get("debrief", "")))
	_set_optional(growth, String(_view.get("growth", "")))
	_set_optional(safety, String(_view.get("safety", "")))
	_set_optional(qualification, String(_view.get("qualification", "")))
	primary_action.text = String(_view.get("primary_label", "继续"))
	primary_action.visible = not primary_action.text.is_empty()
	factory_action.visible = bool(_view.get(
		"show_factory_action",
		String(_view.get("primary_action", "")) != "factory"
	))


func _apply_theme() -> void:
	for panel: PanelContainer in [$Columns/ReportPanel, $Columns/NextPanel]:
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL
		style.border_color = LINE
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		panel.add_theme_stylebox_override("panel", style)
	for label: Label in [
		outcome_text, reward_headline, hero_experience, materials, mission_progress, breakthrough, unlocked_hero,
		combat_summary, contribution, debrief, growth, safety, qualification,
		hurdle_proof,
		$Columns/ReportPanel/ReportMargin/Report/ReportTitle,
		$Columns/NextPanel/NextMargin/Next/NextTitle,
	]:
		label.add_theme_font_override("font", CJK_FONT)
	outcome_text.add_theme_font_size_override("font_size", 16)
	reward_headline.add_theme_font_size_override("font_size", 20)
	reward_headline.add_theme_color_override("font_color", GOLD)
	hero_experience.add_theme_font_size_override("font_size", 14)
	hero_experience.add_theme_color_override("font_color", CYAN)
	materials.add_theme_font_size_override("font_size", 14)
	materials.add_theme_color_override("font_color", TEXT)
	mission_progress.add_theme_color_override("font_color", GREEN)
	breakthrough.add_theme_color_override("font_color", CYAN)
	unlocked_hero.add_theme_color_override("font_color", GREEN)
	combat_summary.add_theme_color_override("font_color", TEXT)
	contribution.add_theme_color_override("font_color", GOLD)
	hurdle_proof.add_theme_color_override("font_color", GREEN)
	debrief.add_theme_color_override("font_color", GREEN)
	growth.add_theme_color_override("font_color", CYAN)
	safety.add_theme_color_override("font_color", GREEN)
	qualification.add_theme_color_override("font_color", GOLD)
	for button: Button in [primary_action, factory_action, base_action]:
		button.add_theme_font_override("font", CJK_FONT)
		button.add_theme_font_size_override("font_size", 15)
		_style_button(button, button == primary_action)


func _style_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#244546") if primary else PANEL_2
	normal.border_color = CYAN if primary else LINE
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#315a5b") if primary else Color("#24333a")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var focus := hover.duplicate() as StyleBoxFlat
	focus.border_color = Color.WHITE
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)


func _set_optional(label: Label, value: String) -> void:
	label.text = value
	label.visible = not value.is_empty()


func _semantic_color(color_id: String) -> Color:
	match color_id:
		"green":
			return GREEN
		"red":
			return RED
		_:
			return GOLD


func _emit_primary_action() -> void:
	action_requested.emit(
		String(_view.get("primary_action", "base")),
		(_view.get("primary_payload", {}) as Dictionary).duplicate(true)
	)

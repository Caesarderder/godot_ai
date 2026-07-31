class_name BattleResultScreen
extends VBoxContainer

signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const ICON_VICTORY := preload("res://assets/ui/battle_result/victory_medal.webp")
const ICON_DEFEAT := preload("res://assets/ui/battle_result/defeat_shield.webp")
const ICON_GOLD := preload("res://assets/ui/battle_result/loot_coin.webp")
const ICON_DATA := preload("res://assets/ui/battle_result/legion_data.webp")
const ICON_TIME := preload("res://assets/ui/battle_result/battle_time.webp")
const ICON_TARGET := preload("res://assets/ui/battle_result/destroyed_target.webp")
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
@onready var outcome_icon: TextureRect = %OutcomeIcon
@onready var next_outcome_icon: TextureRect = %NextOutcomeIcon
@onready var result_visuals: VBoxContainer = %ResultVisuals
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
@onready var report_stack: VBoxContainer = $Columns/ReportPanel/ReportMargin/Report

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
	var compact := bool(_view.get("compact", false))
	$Columns/NextPanel.custom_minimum_size.x = 205.0 if compact else 280.0
	base_action.text = "返回基地" if compact else "返回基地 · 稍后继续"
	outcome_icon.custom_minimum_size = Vector2(42, 42) if compact else Vector2(52, 52)
	next_outcome_icon.custom_minimum_size = Vector2(38, 38) if compact else Vector2(56, 56)
	$Columns/NextPanel/NextMargin.add_theme_constant_override("margin_top", 5 if compact else 8)
	$Columns/NextPanel/NextMargin.add_theme_constant_override("margin_bottom", 5 if compact else 8)
	$Columns/NextPanel/NextMargin/Next.add_theme_constant_override("separation", 3 if compact else 5)
	primary_action.custom_minimum_size.y = 48.0
	factory_action.custom_minimum_size.y = 34.0 if compact else 48.0
	base_action.custom_minimum_size.y = 34.0 if compact else 48.0
	outcome_text.text = String(_view.get("outcome_banner", "战斗结束"))
	var outcome_id := String(_view.get("outcome_color", "gold"))
	var outcome_color := _semantic_color(outcome_id)
	var outcome_texture := ICON_DEFEAT if outcome_id == "red" else ICON_VICTORY
	outcome_icon.texture = outcome_texture
	next_outcome_icon.texture = outcome_texture
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
	_merge_optional(
		combat_summary,
		[
			String(_view.get("combat_summary", "")),
			String(_view.get("contribution", "")),
		]
	)
	contribution.visible = false
	_merge_optional(
		mission_progress,
		[
			String(_view.get("hero_experience", "")),
			String(_view.get("mission_progress", "")),
			String(_view.get("unlocked_hero", "")),
			String(_view.get("materials", "")),
			String(_view.get("breakthrough", "")),
		]
	)
	for merged_source in [hero_experience, unlocked_hero, materials, breakthrough]:
		merged_source.visible = false
	_prioritize_report_rows()
	_build_visual_report()
	for semantic_row in [
		reward_headline,
		mission_progress,
		combat_summary,
		hurdle_proof,
		debrief,
		growth,
	]:
		semantic_row.visible = false
	var safety_full := safety.text
	safety.text = _compact_line(safety_full, 15 if compact else 22)
	safety.tooltip_text = safety_full
	var qualification_full := qualification.text
	qualification.text = _compact_line(
		qualification_full.get_slice("\n", 0),
		17 if compact else 26
	)
	qualification.tooltip_text = qualification_full
	primary_action.text = String(_view.get("primary_label", "继续"))
	primary_action.icon = outcome_texture
	primary_action.expand_icon = true
	primary_action.visible = not primary_action.text.is_empty()
	# Generic factory navigation competes with the causal recovery/continuation
	# action. It is opt-in only; factory onboarding already uses the primary CTA.
	factory_action.visible = (
		bool(_view.get("show_factory_action", false))
		and String(_view.get("primary_action", "")) != "factory"
	)


func _apply_theme() -> void:
	for panel: PanelContainer in [$Columns/ReportPanel, $Columns/NextPanel]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(PANEL, 0.82)
		style.set_corner_radius_all(5)
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
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(primary))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(primary, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(primary, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(primary, "focus"))
	button.add_theme_color_override("font_color", Color("#14110c") if primary else TEXT)


func _build_visual_report() -> void:
	_clear_children(result_visuals)
	var rewards := HBoxContainer.new()
	rewards.name = "ResultRewardChips"
	rewards.add_theme_constant_override("separation", 7)
	result_visuals.add_child(rewards)
	var reward_copy := String(_view.get("reward_headline", ""))
	var gold_gain := _extract_number(reward_copy, "金币\\s*\\+(\\d+)")
	var data_gain := _extract_number(reward_copy, "军团数据\\s*\\+(\\d+)")
	if gold_gain >= 0:
		rewards.add_child(_metric_chip(ICON_GOLD, "+%d" % gold_gain, "金币", GOLD, 116))
	if data_gain >= 0:
		rewards.add_child(_metric_chip(ICON_DATA, "+%d" % data_gain, "军团数据", CYAN, 132))
	rewards.visible = rewards.get_child_count() > 0
	var facts := HBoxContainer.new()
	facts.name = "ResultBattleFacts"
	facts.add_theme_constant_override("separation", 7)
	result_visuals.add_child(facts)
	var combat_copy := String(_view.get("combat_summary", ""))
	var seconds := _extract_number(combat_copy, "(\\d+)秒")
	var structures := _extract_number(combat_copy, "(?:击破|摧毁)\\s*(\\d+)")
	var enemies := _extract_number(combat_copy, "(?:消灭|击败)\\s*(\\d+)")
	facts.add_child(_metric_chip(ICON_TIME, "--" if seconds < 0 else str(seconds), "秒", MUTED, 92))
	facts.add_child(_metric_chip(ICON_TARGET, "--" if structures < 0 else str(structures), "击破", GREEN, 92))
	facts.add_child(_metric_chip(ICON_DEFEAT, "--" if enemies < 0 else str(enemies), "消灭", TEXT, 92))
	var highlight_source := String(_view.get("debrief", ""))
	if highlight_source.is_empty():
		highlight_source = String(_view.get("hurdle_proof", ""))
	if not highlight_source.is_empty():
		var highlight := HBoxContainer.new()
		highlight.name = "ResultHighlight"
		highlight.add_theme_constant_override("separation", 7)
		var icon := TextureRect.new()
		icon.texture = ICON_VICTORY if String(_view.get("outcome_color", "gold")) != "red" else ICON_DEFEAT
		icon.custom_minimum_size = Vector2(38, 38)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		highlight.add_child(icon)
		var copy := Label.new()
		copy.name = "ResultHighlightCopy"
		copy.text = "本场高光 · %s" % _compact_line(
			highlight_source.replace("战斗复盘 · ", ""),
			25
		)
		copy.tooltip_text = highlight_source
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		copy.add_theme_font_override("font", CJK_FONT)
		copy.add_theme_font_size_override("font_size", 12)
		copy.add_theme_color_override("font_color", GREEN)
		copy.clip_text = true
		copy.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		highlight.add_child(copy)
		result_visuals.add_child(highlight)


func _metric_chip(
	texture: Texture2D,
	value: String,
	label_copy: String,
	color: Color,
	minimum_width: float
) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minimum_width, 54)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiArtDirectionScript.panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_override("font", CJK_FONT)
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", color)
	copy.add_child(value_label)
	var caption := Label.new()
	caption.text = label_copy
	caption.add_theme_font_override("font", CJK_FONT)
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", MUTED)
	copy.add_child(caption)
	return panel


func _extract_number(source: String, pattern: String) -> int:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return -1
	var match := regex.search(source)
	if match == null:
		return -1
	return int(match.get_string(1))


func _compact_line(source: String, limit: int) -> String:
	var compact := source.strip_edges()
	if compact.length() <= limit:
		return compact
	return "%s…" % compact.substr(0, limit - 1)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()


func _set_optional(label: Label, value: String) -> void:
	label.text = value
	label.visible = not value.is_empty()


func _merge_optional(target: Label, values: Array) -> void:
	var non_empty: Array[String] = []
	for value in values:
		var copy := String(value).strip_edges()
		if not copy.is_empty():
			non_empty.append(copy)
	target.text = " · ".join(non_empty)
	target.visible = not target.text.is_empty()


func _prioritize_report_rows() -> void:
	var priority: Array[Control] = [
		reward_headline,
		hurdle_proof,
		debrief,
		combat_summary,
		mission_progress,
	]
	var target_index := 1
	for row in priority:
		report_stack.move_child(row, target_index)
		target_index += 1


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

class_name BlueprintScreen
extends VBoxContainer
signal branch_selected(branch_id: String)
signal action_requested(action_id: String, payload: Dictionary)

const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const ResourceContextHudScript := preload("res://game/scripts/ui/resource_context_hud.gd")
const UiArtDirectionScript := preload("res://game/scripts/ui/ui_art_direction.gd")
const ICON_BRANCH_ASSAULT := preload("res://assets/ui/blueprints/branch_assault.webp")
const ICON_BRANCH_HEAVY := preload("res://assets/ui/blueprints/branch_heavy.webp")
const ICON_BRANCH_FLYING := preload("res://assets/ui/blueprints/branch_flying.webp")
const ICON_BRANCH_SUPPORT := preload("res://assets/ui/blueprints/branch_support.webp")
const ICON_ABILITY_CHARGE := preload("res://assets/ui/blueprints/ability_charge.webp")
const ICON_ABILITY_SONIC := preload("res://assets/ui/blueprints/ability_sonic.webp")
const ICON_STATUS_LOCKED := preload("res://assets/ui/icons/kenney_game_icons/locked.png")
const ICON_STATUS_READY := preload("res://assets/ui/icons/kenney_game_icons/star.png")
const ICON_STATUS_RESEARCH := preload("res://assets/ui/icons/kenney_game_icons/wrench.png")
const ASSAULT_FORGE_ART := preload("res://assets/ui/recruit/faction-assault-v2.webp")
const BG := Color("#090d10")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const GREEN := Color("#78b982")

const BRANCHES := [
	["ordinary", "突击", ICON_BRANCH_ASSAULT],
	["heavy", "重装", ICON_BRANCH_HEAVY],
	["flying", "飞行", ICON_BRANCH_FLYING],
	["special", "支援", ICON_BRANCH_SUPPORT],
]

@onready var tabs: HBoxContainer = %BlueprintTabs
@onready var core_panel: PanelContainer = %BlueprintTreeRoot
@onready var core_status: Label = %BlueprintCoreStatus
@onready var resource_context_slot: VBoxContainer = %BlueprintResourceContext
@onready var breakthrough_copy: Label = %BlueprintBreakthroughCopy
@onready var breakthrough_button: Button = %ClaimResearchBreakthroughTen
@onready var results_panel: PanelContainer = %ResearchBreakthroughResults
@onready var results_summary: Label = %BlueprintResultsSummary
@onready var results_grid: GridContainer = %BlueprintResultsGrid
@onready var tech_preview: PanelContainer = %FactionTechPreview
@onready var doctrine_emblem: TextureRect = %DoctrineEmblem
@onready var tech_identity: Label = %Identity
@onready var tech_effect: Label = %Effect
@onready var doctrine_deck: HBoxContainer = %DoctrineDeck
@onready var coordination_choice: Button = %CoordinationChoice
@onready var specialization_choice: Button = %SpecializationChoice
@onready var branch_row: HBoxContainer = %BlueprintBranchRow
@onready var branch_panel: PanelContainer = %BlueprintBranchPanel
@onready var branch_heading: Label = %BlueprintBranchHeading
@onready var node_row: HBoxContainer = %BlueprintNodeRow
@onready var focus_panel: PanelContainer = %BlueprintFocusPanel
@onready var focus_content: HBoxContainer = %BlueprintFocusContent
@onready var back_button: Button = %BlueprintBackButton

var _view: Dictionary = {}
var _reveal_tween: Tween
var _resource_context: Control
var _refresh_generation := 0
var _selected_recipe_id := ""
var _node_views: Array[Dictionary] = []


func _ready() -> void:
	_apply_theme()
	_resource_context = ResourceContextHudScript.new() as Control
	_resource_context.name = "BlueprintResearchResourceHUD"
	_resource_context.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_context_slot.add_child(_resource_context)
	for entry in BRANCHES:
		var id := String(entry[0])
		var button := tabs.get_node("Blueprint%sTab" % id.capitalize()) as Button
		button.text = String(entry[1])
		button.icon = entry[2] as Texture2D
		button.expand_icon = true
		button.pressed.connect(branch_selected.emit.bind(id))
	breakthrough_button.pressed.connect(action_requested.emit.bind("claim_breakthrough", {}))
	%BlueprintResultsLegionButton.pressed.connect(action_requested.emit.bind("open_legion", {}))
	coordination_choice.pressed.connect(
		action_requested.emit.bind("choose_faction_doctrine", {"doctrine_id": "coordination"})
	)
	specialization_choice.pressed.connect(
		action_requested.emit.bind("choose_faction_doctrine", {"doctrine_id": "specialization"})
	)
	back_button.pressed.connect(action_requested.emit.bind("back", {}))
	if not _view.is_empty():
		_apply_view()
	_focus_primary_after_layout()


func configure(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if is_node_ready():
		_apply_view()
		_focus_primary_after_layout()


func _apply_view() -> void:
	var compact := bool(_view.get("compact", false))
	var key_font_size := 16 if compact else 11
	tech_identity.add_theme_font_size_override("font_size", key_font_size)
	tech_effect.add_theme_font_size_override("font_size", key_font_size)
	back_button.add_theme_font_size_override("font_size", 16 if compact else 14)
	# The shipping App Shell already owns back/navigation. Keeping a second
	# bottom return button consumes the character forge's mobile height.
	back_button.visible = false
	for entry in BRANCHES:
		var responsive_tab := tabs.get_node(
			"Blueprint%sTab" % String(entry[0]).capitalize()
		) as Button
		responsive_tab.add_theme_font_size_override("font_size", 16 if compact else 14)
		responsive_tab.custom_minimum_size.y = 60 if compact else 52
	var selected := String(_view.get("branch", "ordinary"))
	for entry in BRANCHES:
		var id := String(entry[0])
		var button := tabs.get_node("Blueprint%sTab" % id.capitalize()) as Button
		button.button_pressed = id == selected
		_style_branch_tab(button, id == selected)
	core_status.text = String(_view.get("core_status", "首败信号尚未解析"))
	var resource_context := _view.get("resource_context", {}) as Dictionary
	_resource_context.call("configure", resource_context)
	resource_context_slot.visible = not resource_context.is_empty()
	var breakthrough := _view.get("breakthrough", {}) as Dictionary
	breakthrough_copy.text = String(breakthrough.get("copy", ""))
	breakthrough_copy.visible = not breakthrough_copy.text.is_empty()
	core_status.visible = breakthrough_copy.text.is_empty()
	breakthrough_button.visible = bool(breakthrough.get("claimable", false))
	var results := _view.get("results", []) as Array
	var showing_results := not results.is_empty()
	var preview := _view.get("faction_tech_preview", {}) as Dictionary
	var choices := _view.get("faction_tech_choices", []) as Array
	var choosing_doctrine := choices.size() == 2
	var faction_name := String(preview.get("faction", "阵营"))
	var faction_icon := ICON_BRANCH_HEAVY if faction_name.contains("铁甲") else ICON_BRANCH_ASSAULT
	doctrine_emblem.texture = faction_icon
	results_panel.visible = showing_results
	tech_preview.visible = not showing_results and not preview.is_empty()
	if choosing_doctrine:
		tech_identity.text = "选择二阶指令\n%s" % faction_name
		var coordination := choices[0] as Dictionary
		var specialization := choices[1] as Dictionary
		tech_effect.text = "◆ 永久锁定"
		_configure_doctrine_choice(
			coordination_choice,
			"全军联动",
			String(coordination.get("choice_summary", "全队共享增益")),
			ICON_BRANCH_SUPPORT,
			CYAN
		)
		_configure_doctrine_choice(
			specialization_choice,
			"核心过载",
			String(specialization.get("choice_summary", "阵营核心强化")),
			faction_icon,
			GOLD
		)
	else:
		tech_identity.text = "%d阶指令已激活 · %s\n%s\n%s" % [
			int(preview.get("tier", 1)),
			faction_name,
			String(preview.get("title", "阵营科技")),
			String(preview.get("effect", "")),
		]
		tech_effect.text = "◆ 生效中"
	coordination_choice.visible = choosing_doctrine
	specialization_choice.visible = choosing_doctrine
	doctrine_deck.visible = choosing_doctrine
	tabs.visible = not showing_results and not breakthrough_button.visible
	core_panel.visible = (
		not showing_results
		and preview.is_empty()
		and (
			breakthrough_copy.visible
			or breakthrough_button.visible
			or resource_context_slot.visible
		)
	)
	branch_row.visible = not showing_results and preview.is_empty()
	results_summary.text = String(_view.get(
		"results_summary",
		"两名永久援军响应召唤 · 现在把他们编入反攻队"
	))
	_clear_children(results_grid)
	for result_value in results:
		var result := result_value as Dictionary
		results_grid.add_child(_build_result_card(result))
	if showing_results:
		call_deferred("_animate_results")
	branch_row.name = "BlueprintBranchRow_%s" % selected
	_node_views.clear()
	for node_value in _view.get("nodes", []):
		_node_views.append((node_value as Dictionary).duplicate(true))
	branch_heading.text = "%s  ·  %s" % [
		String(_view.get("branch_title", "研究分支")),
		_branch_progress_copy(),
	]
	_selected_recipe_id = _resolve_selected_recipe()
	_rebuild_node_path()
	_show_node_detail(_selected_recipe_id)
	_schedule_research_refresh(int(_view.get("refresh_at_unix", 0)))


func _configure_doctrine_choice(
	button: Button,
	title: String,
	summary: String,
	icon: Texture2D,
	accent: Color
) -> void:
	var compact_effect := summary
	compact_effect = compact_effect.replace("全队协同 · ", "")
	compact_effect = compact_effect.replace("阵营专精 · ", "")
	compact_effect = compact_effect.replace("\n", " · ")
	button.text = "%s\n%s" % [title, compact_effect]
	button.tooltip_text = summary.replace("\n", " · ") + " · 选择后不可更改"
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 44)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", accent.lightened(0.14))
	button.add_theme_color_override("font_pressed_color", accent)


func _build_result_card(view: Dictionary) -> PanelContainer:
	var is_hero := String(view.get("kind", "")) == "hero"
	var card := PanelContainer.new()
	card.name = "BreakthroughResult_%s" % String(view.get("id", "resource"))
	card.custom_minimum_size = Vector2(118, 64 if is_hero else 54)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := _panel_style(Color("#242015") if is_hero else PANEL_2)
	style.border_color = GOLD if is_hero else Color(LINE, 0.8)
	style.set_border_width_all(2 if is_hero else 1)
	card.add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 1)
	card.add_child(content)
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = String(view.get("title", "研究资源"))
	title.add_theme_font_override("font", CJK_FONT)
	title.add_theme_font_size_override("font_size", 13 if is_hero else 11)
	title.add_theme_color_override("font_color", GOLD if is_hero else TEXT)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = String(view.get("subtitle", ""))
	subtitle.add_theme_font_override("font", CJK_FONT)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", CYAN if is_hero else MUTED)
	content.add_child(subtitle)
	if is_hero:
		var impact := Label.new()
		impact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		impact.text = String(view.get("impact", "永久援军"))
		impact.add_theme_font_override("font", CJK_FONT)
		impact.add_theme_font_size_override("font_size", 10)
		impact.add_theme_color_override("font_color", GREEN)
		content.add_child(impact)
	return card


func _animate_results() -> void:
	if not is_inside_tree():
		return
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	var cards := results_grid.get_children()
	var reduced_motion := bool(_view.get("reduced_motion", false))
	for card_value in cards:
		var card := card_value as Control
		card.modulate = Color.WHITE
		card.scale = Vector2.ONE
	if reduced_motion or cards.is_empty():
		return
	_reveal_tween = create_tween()
	_reveal_tween.set_parallel(true)
	_reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_reveal_tween.set_ignore_time_scale(true)
	for index in cards.size():
		var card := cards[index] as Control
		card.pivot_offset = card.size * 0.5
		card.modulate.a = 0.0
		card.scale = Vector2(0.92, 0.92)
		var delay := minf(0.24, float(index) * 0.03)
		_reveal_tween.tween_property(card, "modulate:a", 1.0, 0.16).set_delay(delay)
		_reveal_tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _resolve_selected_recipe() -> String:
	if _node_views.is_empty():
		return ""
	var requested := String(_view.get("focus_recipe_id", _selected_recipe_id))
	for view in _node_views:
		if String(view.get("recipe_id", "")) == requested:
			return requested
	for view in _node_views:
		if not String(view.get("action_id", "")).is_empty() and not bool(view.get("disabled", false)):
			return String(view.get("recipe_id", ""))
	return String(_node_views[0].get("recipe_id", ""))


func _build_node_selector(view: Dictionary) -> Button:
	var journey_focus := bool(view.get("journey_focus", false))
	var recipe_id := String(view.get("recipe_id", ""))
	var selected := recipe_id == _selected_recipe_id
	var selector := Button.new()
	selector.name = "BlueprintNode_%s" % recipe_id.replace(".", "_")
	selector.custom_minimum_size = Vector2(68, 64)
	selector.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	selector.clip_text = true
	selector.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	selector.icon = _character_portrait(view)
	selector.expand_icon = true
	selector.add_theme_constant_override("icon_max_width", 54)
	selector.text = ""
	selector.add_theme_font_override("font", CJK_FONT)
	selector.add_theme_font_size_override("font_size", 11)
	selector.add_theme_stylebox_override("normal", _forge_selector_style(selected, false))
	selector.add_theme_stylebox_override("hover", _forge_selector_style(true, false))
	selector.add_theme_stylebox_override("pressed", _forge_selector_style(true, false))
	selector.add_theme_stylebox_override("focus", _forge_selector_style(true, true))
	selector.add_theme_color_override(
		"font_color",
		_status_color(String(view.get("status_id", "locked")))
	)
	if String(view.get("status_id", "locked")) == "locked":
		selector.modulate = Color(0.48, 0.52, 0.56, 0.72)
	selector.focus_mode = Control.FOCUS_ALL
	selector.tooltip_text = "%s · %s" % [
		String(view.get("display_name", "未知蓝图")),
		String(view.get("status_copy", "")),
	]
	selector.pressed.connect(_select_recipe.bind(recipe_id))
	return selector


func _rebuild_node_path() -> void:
	_clear_children(node_row)
	node_row.name = "BlueprintCharacterStrip"
	for node_view in _node_views:
		node_row.add_child(_build_node_selector(node_view))


func _path_connector(index: int, color: Color) -> Control:
	var connector := ColorRect.new()
	connector.name = "BlueprintPathConnector_%d" % index
	connector.color = color.darkened(0.35)
	connector.custom_minimum_size = Vector2(18, 3)
	connector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	connector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return connector


func _branch_icon(branch_id: String) -> Texture2D:
	return {
		"heavy": ICON_BRANCH_HEAVY,
		"flying": ICON_BRANCH_FLYING,
		"special": ICON_BRANCH_SUPPORT,
	}.get(branch_id, ICON_BRANCH_ASSAULT) as Texture2D


func _recipe_icon(recipe_id: String) -> Texture2D:
	if recipe_id.contains("sonic"):
		return ICON_ABILITY_SONIC
	if recipe_id.contains("saw") or recipe_id.contains("crusher"):
		return ICON_ABILITY_CHARGE
	if recipe_id.contains("anchor") or recipe_id.contains("rocket") or recipe_id.contains("bomber"):
		return ICON_BRANCH_FLYING
	if recipe_id.contains("drain") or recipe_id.contains("repair"):
		return ICON_BRANCH_SUPPORT
	if recipe_id.begins_with("heavy"):
		return ICON_BRANCH_HEAVY
	if recipe_id.begins_with("flying"):
		return ICON_BRANCH_FLYING
	if recipe_id.begins_with("special"):
		return ICON_BRANCH_SUPPORT
	return ICON_ABILITY_CHARGE


func _select_recipe(recipe_id: String) -> void:
	if recipe_id == _selected_recipe_id:
		return
	_selected_recipe_id = recipe_id
	_refresh_selected_recipe.call_deferred()


func _refresh_selected_recipe() -> void:
	_rebuild_node_path()
	_show_node_detail(_selected_recipe_id)


func _show_node_detail(recipe_id: String) -> void:
	_clear_children(focus_content)
	focus_panel.visible = not recipe_id.is_empty()
	if recipe_id.is_empty():
		return
	var view: Dictionary = {}
	for candidate in _node_views:
		if String(candidate.get("recipe_id", "")) == recipe_id:
			view = candidate
			break
	if view.is_empty():
		focus_panel.visible = false
		return
	focus_panel.add_theme_stylebox_override(
		"panel",
		_forge_focus_style(String(view.get("status_id", "locked")))
	)
	var compact := bool(_view.get("compact", false))
	var portrait := TextureRect.new()
	portrait.name = "BlueprintFocusedCharacterPortrait"
	portrait.texture = _character_portrait(view)
	portrait.custom_minimum_size = Vector2(116 if compact else 154, 112 if compact else 132)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if String(view.get("status_id", "locked")) == "locked":
		portrait.modulate = Color(0.5, 0.54, 0.58, 0.68)
	focus_content.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	focus_content.add_child(copy)
	var identity := Label.new()
	identity.name = "BlueprintFocusedIdentity"
	identity.text = String(view.get("display_name", "未知蓝图"))
	identity.add_theme_font_override("font", CJK_FONT)
	identity.add_theme_font_size_override("font_size", 18 if compact else 20)
	identity.add_theme_color_override("font_color", TEXT)
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.clip_text = true
	identity.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(identity)
	var role := Label.new()
	role.name = "BlueprintAbilityTags"
	role.text = "%s  ·  %s" % [
		String(view.get("faction", "独立战术")),
		String(view.get("role_copy", "职责待确认")),
	]
	role.add_theme_font_override("font", CJK_FONT)
	role.add_theme_font_size_override("font_size", 13 if compact else 14)
	role.add_theme_color_override("font_color", GOLD)
	role.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role.clip_text = true
	role.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(role)
	var growth := Label.new()
	growth.name = "BlueprintGrowthPips"
	growth.text = "★ %s   →   2★ %s" % [
		_compact_effect(String(view.get("one_star_value", "完整主动技能"))),
		_compact_effect(String(view.get("two_star_effect", "职责强化"))),
	]
	growth.tooltip_text = "1★ %s\n2★ %s\n3★ %s" % [
		String(view.get("one_star_value", "完整主动技能")),
		String(view.get("two_star_effect", "职责强化")),
		String(view.get("three_star_effect", "技能强化")),
	]
	growth.add_theme_font_override("font", CJK_FONT)
	growth.add_theme_font_size_override("font_size", 12 if compact else 13)
	growth.add_theme_color_override("font_color", TEXT)
	growth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	growth.clip_text = true
	growth.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(growth)
	var status := Label.new()
	status.name = "BlueprintNodeStatus"
	status.text = _forge_status_copy(view)
	status.add_theme_font_override("font", CJK_FONT)
	status.add_theme_font_size_override("font_size", 12 if compact else 13)
	status.add_theme_color_override("font_color", _status_color(String(view.get("status_id", "locked"))))
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.clip_text = true
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(status)
	var semantic_copy := Label.new()
	semantic_copy.name = "BlueprintDetailSemantics"
	semantic_copy.text = "1★ %s · %s\n升星：2★ %s · 3★ %s\n%s · 来源：%s" % [
		String(view.get("one_star_value", "拥有完整主动技能")),
		String(view.get("role_copy", "职责待确认")),
		String(view.get("two_star_effect", "职责强化")),
		String(view.get("three_star_effect", "技能强化")),
		String(view.get("status_copy", "")),
		String(view.get("unlock_source", "信号招募")),
	]
	semantic_copy.visible = false
	semantic_copy.tooltip_text = semantic_copy.text
	copy.add_child(semantic_copy)
	var action_id := String(view.get("action_id", ""))
	if not action_id.is_empty():
		var button := _button(_forge_action_label(view, compact), true)
		button.icon = _status_icon(String(view.get("status_id", "locked")))
		button.expand_icon = true
		button.custom_minimum_size = Vector2(166 if compact else 220, 60 if compact else 54)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.name = String(view.get("action_name", "BlueprintNodeAction"))
		button.set_meta("primary_blueprint_action", true)
		button.set_meta("recipe_id", String(view.get("recipe_id", "")))
		button.disabled = bool(view.get("disabled", false))
		_style_forge_primary(button)
		button.pressed.connect(action_requested.emit.bind(action_id, {
			"recipe_id": recipe_id,
		}))
		focus_content.add_child(button)


func _character_portrait(view: Dictionary) -> Texture2D:
	var archetype_id := String(view.get("archetype_id", ""))
	if archetype_id.is_empty():
		archetype_id = String(view.get("recipe_id", "")).get_slice(".", 1)
	if archetype_id == "assault":
		return ASSAULT_FORGE_ART
	return load("res://assets/ui/codex/%s.webp" % archetype_id) as Texture2D


func _branch_progress_copy() -> String:
	var known := 0
	for view in _node_views:
		if String(view.get("status_id", "locked")) != "locked":
			known += 1
	return "%d/%d 型号" % [known, _node_views.size()]


func _forge_status_copy(view: Dictionary) -> String:
	var status_id := String(view.get("status_id", "locked"))
	match status_id:
		"available":
			return "可研发  ·  免费  ·  5秒"
		"researching":
			return "研发完成  ·  等待领取" if not bool(view.get("disabled", false)) else "研发中"
		"unlocked":
			return "已入列  ·  永久角色"
		_:
			return "待获取  ·  %s" % String(view.get("unlock_source", "信号招募"))


func _forge_action_label(view: Dictionary, compact: bool) -> String:
	if compact:
		return (
			"研发 · 5秒"
			if String(view.get("status_id", "")) == "available"
			else "领取角色"
		)
	return _compact_action_label(String(view.get("action_label", "继续")))


func _status_icon(status_id: String) -> Texture2D:
	if status_id == "locked":
		return ICON_STATUS_LOCKED
	if status_id == "researching":
		return ICON_STATUS_READY
	return ICON_STATUS_RESEARCH


func _forge_selector_style(selected: bool, focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#122029") if selected else Color("#0d151b")
	style.border_color = Color.WHITE if focused else (GOLD if selected else Color("#2b3b44"))
	style.set_border_width_all(2 if selected or focused else 1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _forge_focus_style(status_id: String) -> StyleBoxFlat:
	var accent := _status_color(status_id)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b141a")
	style.border_color = Color(accent, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _style_forge_primary(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#e9ad46") if state != "pressed" else Color("#c88d2f")
		style.border_color = Color.WHITE if state == "focus" else Color("#f6d27a")
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		button.add_theme_stylebox_override(state, style)


func _status_short(status_id: String) -> String:
	return String({
		"available": "可研发",
		"researching": "研发中",
		"unlocked": "已入列",
	}.get(status_id, "待获取"))


func _compact_selector_name(display_name: String) -> String:
	if display_name.length() <= 5:
		return display_name
	return "%s…" % display_name.substr(0, 4)


func _compact_action_label(action_label: String) -> String:
	if action_label.begins_with("免费研发"):
		var duration := action_label.get_slice("·", 1).strip_edges()
		return "免费研发%s" % (" · %s" % duration if not duration.is_empty() else "")
	return action_label


func _compact_effect(effect: String) -> String:
	if effect.length() <= 6:
		return effect
	return "%s…" % effect.substr(0, 5)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()


func _status_color(status_id: String) -> Color:
	if status_id == "unlocked":
		return GREEN
	if status_id == "researching":
		return CYAN
	if status_id == "available":
		return GOLD
	return MUTED


func _rating_label(rating: String) -> String:
	return String({
		"C": "基础",
		"B": "标准",
		"A": "精锐",
		"S": "传奇",
	}.get(rating, "标准"))


func _focus_primary_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if breakthrough_button.visible:
		breakthrough_button.grab_focus()
		return
	if results_panel.visible:
		%BlueprintResultsLegionButton.grab_focus()
		return
	var focus_recipe_id := String(_view.get("focus_recipe_id", ""))
	if not focus_recipe_id.is_empty():
		for focused_action_value in find_children("*", "Button", true, false):
			var focused_action := focused_action_value as Button
			if (
				String(focused_action.get_meta("recipe_id", "")) == focus_recipe_id
				and focused_action.visible
				and not focused_action.disabled
			):
				focused_action.grab_focus()
				return
	for action_value in find_children("*", "Button", true, false):
		var action := action_value as Button
		if (
			bool(action.get_meta("primary_blueprint_action", false))
			and action.visible
			and not action.disabled
		):
			action.grab_focus()
			return
	back_button.grab_focus()


func _schedule_research_refresh(refresh_at_unix: int) -> void:
	_refresh_generation += 1
	var generation := _refresh_generation
	var delay := refresh_at_unix - int(Time.get_unix_time_from_system())
	if delay <= 0:
		return
	await get_tree().create_timer(float(delay) + 0.15).timeout
	if is_inside_tree() and generation == _refresh_generation:
		action_requested.emit("refresh", {})


func _apply_theme() -> void:
	for panel in [core_panel, results_panel, tech_preview, branch_panel, focus_panel]:
		panel.add_theme_stylebox_override("panel", UiArtDirectionScript.panel_style())
	for label_node in find_children("*", "Label", true, false):
		var label := label_node as Label
		label.add_theme_font_override("font", CJK_FONT)
		label.add_theme_color_override("font_color", TEXT)
	core_status.add_theme_color_override("font_color", GOLD)
	breakthrough_copy.add_theme_color_override("font_color", CYAN)
	results_summary.add_theme_color_override("font_color", CYAN)
	tech_identity.add_theme_color_override("font_color", GOLD)
	tech_identity.add_theme_font_size_override("font_size", 11)
	tech_effect.add_theme_color_override("font_color", CYAN)
	tech_effect.add_theme_font_size_override("font_size", 11)
	branch_heading.add_theme_font_size_override("font_size", 16)
	branch_heading.add_theme_color_override("font_color", CYAN)
	for button_node in find_children("*", "Button", true, false):
		_style_button(button_node as Button, button_node == breakthrough_button)
	for doctrine_button in [coordination_choice, specialization_choice]:
		doctrine_button.add_theme_font_size_override("font_size", 11)


func _button(text_value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 48
	_style_button(button, primary)
	return button


func _style_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", CJK_FONT)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", UiArtDirectionScript.button_style(primary))
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(primary, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(primary, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(primary, "focus"))
	button.add_theme_color_override("font_color", BG if primary else TEXT)


func _style_branch_tab(button: Button, active: bool) -> void:
	button.add_theme_stylebox_override(
		"normal",
		UiArtDirectionScript.button_style(false, "focus" if active else "normal")
	)
	button.add_theme_stylebox_override("hover", UiArtDirectionScript.button_style(false, "hover"))
	button.add_theme_stylebox_override("pressed", UiArtDirectionScript.button_style(false, "pressed"))
	button.add_theme_stylebox_override("focus", UiArtDirectionScript.button_style(false, "focus"))
	button.add_theme_color_override("font_color", CYAN if active else TEXT)
	button.add_theme_color_override("font_hover_color", CYAN if active else TEXT)
	button.add_theme_color_override("font_pressed_color", CYAN if active else TEXT)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(LINE, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

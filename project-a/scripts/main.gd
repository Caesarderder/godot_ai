extends Node

const FactoryCatalog := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactoryService := preload("res://game/scripts/domain/factory/factory_service.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")
const QuestCatalog := preload("res://game/scripts/domain/quest/quest_catalog.gd")
const BattleWorldScript := preload("res://game/scripts/presentation_3d/battle_world.gd")
const SettingsStoreScript := preload("res://game/scripts/platform/settings_store.gd")
const WebRuntimeScript := preload("res://game/scripts/platform/web_runtime.gd")
const CJKFont := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

enum AppState { BOOT, TITLE, CAMP, FACTORY, CULTIVATION, FORMATION, EXPEDITION, BATTLE, RESULT, SETTINGS, QUESTS }

const ACHIEVEMENT_CATALOG_PATH := "res://game/scripts/domain/achievement/achievement_catalog.gd"

const COLOR_BG := Color("#0b1322")
const COLOR_PANEL := Color("#16243a")
const COLOR_PANEL_ALT := Color("#20334d")
const COLOR_PRIMARY := Color("#29b6a6")
const COLOR_ACCENT := Color("#ffb74d")
const COLOR_TEXT := Color("#f3f7ff")
const COLOR_MUTED := Color("#a9b8cc")
const COLOR_DANGER := Color("#ff7b72")
const UI_SCALE: float = 1.65
const SLOT_KEYS: Array[String] = ["front_left", "front_center", "front_right", "back_left", "back_center", "back_right"]
const SLOT_NAMES: Array[String] = ["前左", "前中", "前右", "后左", "后中", "后右"]
const MATERIAL_LABELS := {"porcelain": "瓷片", "parts": "零件", "sludge": "污泥"}
const SALVAGE_EXCHANGES: Array[Dictionary] = [
	{"exchange_id": "porcelain_resupply", "display_name": "瓷片箱", "cost": 8, "reward_text": "瓷片40"},
	{"exchange_id": "mixed_parts", "display_name": "零件箱", "cost": 12, "reward_text": "零28 泥20"},
	{"exchange_id": "training_cache", "display_name": "训练箱", "cost": 15, "reward_text": "金120 书2"},
]
const FALLBACK_QUESTS: Array[Dictionary] = [
	{"quest_id": "campaign_act1", "generation": 1, "scope": "campaign", "title": "当前大战役任务", "description": "推进第一幕城市大道，累计完成 25 个关键目标。", "progress": 0, "target": 25, "reward_text": "战功 +50"},
	{"quest_id": "loop_destroy", "generation": 1, "scope": "loop", "title": "摧毁联盟设施", "description": "在战斗中拆除结构。", "progress": 0, "target": 3, "reward_text": "战功 +8"},
	{"quest_id": "loop_factory", "generation": 1, "scope": "loop", "title": "补充攻城单位", "description": "完成一次生产或领取。", "progress": 0, "target": 1, "reward_text": "战功 +6"},
	{"quest_id": "loop_training", "generation": 1, "scope": "loop", "title": "强化主力", "description": "完成一次训练或升星。", "progress": 0, "target": 1, "reward_text": "战功 +6"},
]

@onready var world_host: Node3D = $WorldHost
@onready var ui_root: Control = $Interface/UIRoot

var app_state: AppState = AppState.BOOT
var game: Node
var battle_world: Node3D
var battle_id: String = ""
var battle_elapsed: float = 0.0
var battle_snapshot_elapsed: float = 0.0
var factory_refresh_elapsed: float = 0.0
var factory_order_views: Array[Dictionary] = []
var battle_timer_label: Label
var battle_stage_label: Label
var battle_warning_label: Label
var battle_progress_label: Label
var battle_skill_rows: VBoxContainer
var battle_pause_button: Button
var status_label: Label
var command_serial: int = 0
var selected_formation_slot: int = 0
var selected_merge_ids: Array[String] = []
var selected_training_id: String = ""
var selected_stage_id: String = StageCatalog.DEFAULT_STAGE_ID
var selected_achievement_category: String = "all"
var battle_is_paused: bool = false
var settings_store: RefCounted
var web_runtime: Node
var settings_return_state: AppState = AppState.CAMP


func _ready() -> void:
	_initialize_platform_runtime()
	game = get_node_or_null("/root/Game")
	ui_root.theme = _build_theme()
	if game == null:
		_show_boot_error("Game 服务未加载，无法进入游戏。")
		return
	if not game.bootstrap_completed.is_connected(_on_bootstrap_completed):
		game.bootstrap_completed.connect(_on_bootstrap_completed)
	_show_boot()
	_on_bootstrap_completed(String(game.bootstrap_status))


func _notification(what: int) -> void:
	if web_runtime == null:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			web_runtime.set_focus_state(true)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			web_runtime.set_focus_state(false)
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			web_runtime.set_focus_state(true)
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			web_runtime.set_focus_state(false)
		NOTIFICATION_WM_CLOSE_REQUEST:
			web_runtime.set_visibility_state(false)
		_:
			pass


func _initialize_platform_runtime() -> void:
	settings_store = SettingsStoreScript.new()
	settings_store.load_settings()
	_apply_settings_to_runtime()
	web_runtime = WebRuntimeScript.new()
	web_runtime.name = "WebRuntime"
	add_child(web_runtime)
	web_runtime.runtime_state_changed.connect(_on_runtime_state_changed)


func _apply_settings_to_runtime() -> void:
	if settings_store == null:
		return
	var volume_ratio := float(settings_store.master_volume) / 100.0
	AudioServer.set_bus_volume_db(0, -80.0 if volume_ratio <= 0.0 else linear_to_db(volume_ratio))
	AudioServer.set_bus_mute(0, volume_ratio <= 0.0)
	if battle_world != null and battle_world.has_method("configure_presentation"):
		battle_world.configure_presentation(settings_store.effects_quality, settings_store.reduced_motion)


func _on_runtime_state_changed(state: Dictionary) -> void:
	if app_state != AppState.BATTLE or battle_world == null:
		return
	if not bool(state.get("is_interactive", true)):
		_set_battle_paused(true)


func _process(delta: float) -> void:
	if app_state == AppState.FACTORY:
		factory_refresh_elapsed += delta
		if factory_refresh_elapsed >= 0.5:
			factory_refresh_elapsed = 0.0
			_update_factory_order_views()
		return
	if app_state != AppState.BATTLE or battle_world == null:
		return
	if not battle_is_paused:
		battle_elapsed += delta
	battle_snapshot_elapsed += delta
	if battle_snapshot_elapsed >= 0.2:
		battle_snapshot_elapsed = 0.0
		_update_battle_hud()


func _show_boot() -> void:
	app_state = AppState.BOOT
	_clear_ui()
	_clear_world()
	_add_background(COLOR_BG)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(center)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	var title := _label("马桶人工厂攻城", 32, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	status_label = _label("正在装配马桶军团...", 18, COLOR_MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status_label)


func _on_bootstrap_completed(status: String) -> void:
	if status in ["loaded", "created"]:
		_show_title()
	elif status != "not_started":
		_show_boot_error("存档初始化失败：%s" % status)


func _show_boot_error(message: String) -> void:
	if status_label == null:
		_show_boot()
	status_label.text = message
	status_label.add_theme_color_override("font_color", COLOR_DANGER)


func _show_title() -> void:
	app_state = AppState.TITLE
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_add_background(Color(0.02, 0.04, 0.08, 0.56))
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(center)
	var panel := _panel(COLOR_PANEL, 18)
	panel.custom_minimum_size = Vector2(420, 210)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := _label("马桶人工厂攻城", 34, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := _label("造兵、升星、六人编队，突破三阶段城市防线。", 16, COLOR_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var button := _button("进入营地", COLOR_PRIMARY, Vector2(210, 54), 19)
	button.pressed.connect(_show_camp)
	column.add_child(button)
	var settings_button := _button("设置", COLOR_PANEL_ALT, Vector2(210, 46), 16)
	settings_button.name = "TitleSettingsButton"
	settings_button.pressed.connect(func() -> void: _show_settings(AppState.TITLE))
	column.add_child(settings_button)
	button.grab_focus()


func _show_camp() -> void:
	app_state = AppState.CAMP
	_clear_ui()
	_clear_world()
	_build_camp_world()
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	root.add_child(_build_top_bar())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var objective := _panel(Color(0.055, 0.09, 0.14, 0.92), 14)
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(objective)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 8)
	objective.add_child(copy)
	var objective_action := _derive_next_action(game.current_state())
	var objective_eyebrow := _label("下一目标", 14, COLOR_PRIMARY)
	copy.add_child(objective_eyebrow)
	var objective_title := _label(String(objective_action["title"]), 26, COLOR_TEXT)
	objective_title.name = "ObjectiveTitle"
	copy.add_child(objective_title)
	var objective_body := _label(String(objective_action["body"]), 15, COLOR_MUTED)
	objective_body.name = "ObjectiveBody"
	copy.add_child(objective_body)
	var objective_button := _button(String(objective_action["cta_label"]), COLOR_PRIMARY, Vector2(180, 50), 16)
	objective_button.name = "CampObjectiveButton"
	objective_button.pressed.connect(func() -> void: _navigate_objective_action(objective_action))
	copy.add_child(objective_button)
	copy.add_child(_label("CTA 只进入对应界面；生产、领取、培育和出征仍由玩家确认。", 12, COLOR_ACCENT))
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	body.add_child(actions)
	var factory := _button("工厂", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	factory.pressed.connect(_show_factory)
	actions.add_child(factory)
	var cultivate := _button("培育", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	cultivate.pressed.connect(_show_cultivation)
	actions.add_child(cultivate)
	var formation := _button("编队", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	formation.pressed.connect(_show_formation)
	actions.add_child(formation)
	var quests := _button("目标", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	quests.name = "QuestEntryButton"
	quests.pressed.connect(_show_quests)
	actions.add_child(quests)
	var expedition := _button("出征", COLOR_ACCENT, Vector2(138, 58), 19)
	expedition.pressed.connect(_show_expedition)
	actions.add_child(expedition)
	var settings_button := _button("设置", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	settings_button.name = "CampSettingsButton"
	settings_button.pressed.connect(func() -> void: _show_settings(AppState.CAMP))
	actions.add_child(settings_button)


func _build_top_bar() -> Control:
	var panel := _panel(Color(0.055, 0.09, 0.14, 0.94), 10)
	panel.custom_minimum_size.y = 54
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var brand := _label("马桶军团营地", 21, COLOR_TEXT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand)
	var state: RefCounted = game.current_state()
	var materials: Dictionary = state.factory.materials
	var resources := _label(
		"金 %d · 书 %d · 残 %d · 战功Lv%d · 瓷 %d · 零 %d · 泥 %d" % [
			state.economy.gold,
			state.economy.xp_books,
			_salvage_balance(state),
			_war_merit_rank(state),
			int(materials.get("porcelain", 0)),
			int(materials.get("parts", 0)),
			int(materials.get("sludge", 0)),
		],
		13,
		COLOR_ACCENT
	)
	resources.name = "TopResourceSummaryLabel"
	resources.autowrap_mode = TextServer.AUTOWRAP_OFF
	resources.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(resources)
	var settings_button := _button("设置", COLOR_PANEL_ALT, Vector2(72, 50), 12)
	settings_button.name = "TopBarSettingsButton"
	settings_button.pressed.connect(func() -> void: _show_settings(AppState.CAMP))
	row.add_child(settings_button)
	return panel


func _show_settings(return_state: AppState = AppState.CAMP) -> void:
	settings_return_state = return_state
	app_state = AppState.SETTINGS
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_add_background(Color(0.02, 0.04, 0.08, 0.64))
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(center)
	var panel := _panel(COLOR_PANEL, 14)
	panel.custom_minimum_size = Vector2(760, 420)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := _label("设置", 26, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(_settings_volume_row())
	column.add_child(_settings_quality_row())
	column.add_child(_settings_toggle_row("减少动态", "SettingsReducedMotionToggle", settings_store.reduced_motion, func(enabled: bool) -> void:
		settings_store.set_reduced_motion(enabled)
		_apply_settings_to_runtime()
	))
	column.add_child(_settings_toggle_row("全局自动技能", "SettingsGlobalAutoSkillToggle", settings_store.global_auto_skill, func(enabled: bool) -> void:
		settings_store.set_global_auto_skill(enabled)
	))
	var platform_state := "Web" if web_runtime != null and web_runtime.is_web() else "本地/Headless"
	column.add_child(_label("平台：%s · 失焦或隐藏时战斗会暂停，需要手动继续。" % platform_state, 13, COLOR_MUTED))
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	var save := _button("保存设置", COLOR_PRIMARY, Vector2(150, 44), 15)
	save.name = "SettingsSaveButton"
	save.pressed.connect(_save_settings_from_ui)
	actions.add_child(save)
	var back := _button("返回", COLOR_PANEL_ALT, Vector2(110, 44), 15)
	back.name = "SettingsBackButton"
	back.pressed.connect(_return_from_settings)
	actions.add_child(back)
	save.grab_focus()


func _settings_volume_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := _label("主音量", 16, COLOR_TEXT)
	label.custom_minimum_size.x = 120 * UI_SCALE
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = "SettingsMasterVolumeSlider"
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = settings_store.master_volume
	slider.custom_minimum_size = Vector2(340, 44) * UI_SCALE
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	row.add_child(slider)
	var value_label := _label("%d" % settings_store.master_volume, 15, COLOR_ACCENT)
	value_label.name = "SettingsMasterVolumeValue"
	value_label.custom_minimum_size.x = 52 * UI_SCALE
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void:
		settings_store.set_master_volume(value)
		value_label.text = "%d" % settings_store.master_volume
		_apply_settings_to_runtime()
	)
	return row


func _settings_quality_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := _label("特效质量", 16, COLOR_TEXT)
	label.custom_minimum_size.x = 120 * UI_SCALE
	row.add_child(label)
	var options := OptionButton.new()
	options.name = "SettingsEffectsQualityOption"
	options.custom_minimum_size = Vector2(340, 44) * UI_SCALE
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.focus_mode = Control.FOCUS_ALL
	for quality in SettingsStoreScript.EFFECTS_QUALITIES:
		options.add_item(quality)
	var selected_index := SettingsStoreScript.EFFECTS_QUALITIES.find(settings_store.effects_quality)
	options.select(maxi(0, selected_index))
	options.item_selected.connect(func(index: int) -> void:
		settings_store.set_effects_quality(SettingsStoreScript.EFFECTS_QUALITIES[index])
		_apply_settings_to_runtime()
	)
	row.add_child(options)
	return row


func _settings_toggle_row(label_text: String, node_name: String, enabled: bool, callback: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := _label(label_text, 16, COLOR_TEXT)
	label.custom_minimum_size.x = 120 * UI_SCALE
	row.add_child(label)
	var toggle := CheckButton.new()
	toggle.name = node_name
	toggle.button_pressed = enabled
	toggle.custom_minimum_size = Vector2(160, 44) * UI_SCALE
	toggle.focus_mode = Control.FOCUS_ALL
	toggle.add_theme_font_size_override("font_size", int(14 * UI_SCALE))
	toggle.toggled.connect(func(value: bool) -> void: callback.call(value))
	row.add_child(toggle)
	return row


func _save_settings_from_ui() -> void:
	_apply_settings_to_runtime()
	if settings_store.save_settings():
		_show_notice("设置已保存。")
	else:
		_show_notice("设置保存失败。")


func _return_from_settings() -> void:
	if settings_return_state == AppState.TITLE:
		_show_title()
	else:
		_show_camp()


func _derive_next_action(state: RefCounted, now_unix: int = -1) -> Dictionary:
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	var highest_stage := String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	if not StageCatalog.has_stage(highest_stage):
		highest_stage = StageCatalog.DEFAULT_STAGE_ID
	var cleared: Array = state.stage_progress.get("cleared_stages", [])
	var highest_cleared := cleared.has(highest_stage)
	var highest_attempted := int(state.attempt_counters.get(highest_stage, 0)) > 0
	var ready_count := _ready_factory_order_count(state, now)
	if ready_count > 0:
		return {
			"title": "领取完成生产",
			"body": "工厂已有 %d 单完成。先领取永久单位，再决定培育或继续推进。" % ready_count,
			"cta_label": "去工厂领取",
			"target": "factory",
			"stage_id": highest_stage,
		}
	if not cleared.is_empty() and not highest_cleared and not highest_attempted:
		return {
			"title": "推进下一关",
			"body": "%s 已开放。先看本关威胁，再决定是否调整编队。" % String(StageCatalog.stage(highest_stage).get("display_name", highest_stage)),
			"cta_label": "查看下一关",
			"target": "expedition",
			"stage_id": highest_stage,
		}
	if state.attempt_counters.is_empty():
		return {
			"title": "出征侦察",
			"body": "第一场先摸清 Cameramen 的路障、炮塔和核心巨炮节奏。失败不会卡死，会带回反制蓝图和成长资源。",
			"cta_label": "去侦察",
			"target": "expedition",
			"stage_id": StageCatalog.DEFAULT_STAGE_ID,
		}
	var recipe_action := _recipe_guidance_action_for_stage(state, highest_stage)
	if not recipe_action.is_empty():
		return recipe_action
	return {
		"title": "再战城市大道",
		"body": "关键成长已经到位。回到出征页，带着新单位和技能节奏再次压向联盟基地。",
		"cta_label": "去出征",
		"target": "expedition",
		"stage_id": highest_stage,
	}


func _navigate_objective_action(action: Dictionary) -> void:
	var stage_id := String(action.get("stage_id", selected_stage_id))
	if StageCatalog.has_stage(stage_id):
		selected_stage_id = stage_id
	match String(action.get("target", "expedition")):
		"factory":
			_show_factory()
		"cultivation":
			_show_cultivation()
		_:
			_show_expedition()


func _ready_factory_order_count(state: RefCounted, now_unix: int) -> int:
	var count := 0
	for order in state.factory.production_queue:
		if int((order as Dictionary).get("completes_at_unix", 0)) <= now_unix:
			count += 1
	return count


func _recipe_guidance_action_for_stage(state: RefCounted, stage_id: String) -> Dictionary:
	var recipe_id := _select_guidance_recipe_id(state, stage_id)
	if recipe_id.is_empty():
		return {}
	var recipe := FactoryCatalog.recipe(recipe_id)
	if recipe.is_empty():
		return {}
	var archetype_id := String(recipe.get("archetype_id", ""))
	var recipe_name := String(recipe.get("display_name", recipe_id))
	var archetype_name := _archetype_name(archetype_id)
	var count := _hero_count_by_archetype(state, archetype_id)
	var has_two_star := _has_hero_by_archetype_and_star(state, archetype_id, 2)
	if count <= 3:
		return {
			"title": "生产%s" % recipe_name,
			"body": "%s蓝图已解锁，但%s数量不足。先补同原型单位，为三合一和后续升星准备材料。" % [recipe_name, archetype_name],
			"cta_label": "去工厂生产",
			"target": "factory",
			"stage_id": stage_id,
		}
	if not has_two_star:
		return {
			"title": "合成%s" % archetype_name,
			"body": "%s数量够了，先合成 2 星。原型升星比单纯堆战力更能解决当前关卡机制。" % archetype_name,
			"cta_label": "去培育合成",
			"target": "cultivation",
			"stage_id": stage_id,
		}
	if _can_train_archetype_two_star(state, archetype_id):
		return {
			"title": "训练%s" % archetype_name,
			"body": "%s已有 2 星，训练资源足够。先把等级转成稳定输出或承压能力，再回到城市大道。" % archetype_name,
			"cta_label": "去培育训练",
			"target": "cultivation",
			"stage_id": stage_id,
		}
	return {}


func _select_guidance_recipe_id(state: RefCounted, stage_id: String) -> String:
	for recipe_id in _stage_guidance_recipe_ids(stage_id):
		if not bool(state.factory.blueprints.get(recipe_id, false)):
			continue
		var recipe := FactoryCatalog.recipe(recipe_id)
		if recipe.is_empty():
			continue
		var archetype_id := String(recipe.get("archetype_id", ""))
		if _hero_count_by_archetype(state, archetype_id) <= 3:
			return recipe_id
		if not _has_hero_by_archetype_and_star(state, archetype_id, 2):
			return recipe_id
		if _can_train_archetype_two_star(state, archetype_id):
			return recipe_id
	return ""


func _stage_guidance_recipe_ids(stage_id: String) -> Array[String]:
	var stage_config := StageCatalog.stage(stage_id)
	var ordered: Array[String] = []
	for key in ["recommended_recipe_ids", "fallback_recipe_ids"]:
		for recipe_value in stage_config.get(key, []):
			var recipe_id := String(recipe_value)
			if FactoryCatalog.has_recipe(recipe_id) and not ordered.has(recipe_id):
				ordered.append(recipe_id)
	if ordered.is_empty():
		for recipe_id in ["heavy.armored", "ordinary.assault"]:
			if FactoryCatalog.has_recipe(recipe_id):
				ordered.append(recipe_id)
	return ordered


func _hero_count_by_archetype(state: RefCounted, archetype_id: String) -> int:
	var count := 0
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			count += 1
	return count


func _has_hero_by_archetype_and_star(state: RefCounted, archetype_id: String, minimum_star: int) -> bool:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id and int(hero.star) >= minimum_star:
			return true
	return false


func _can_train_any_two_star(state: RefCounted) -> bool:
	if state.economy.xp_books <= 0 or state.economy.gold < HeroProgression.GOLD_PER_BOOK:
		return false
	for hero in state.roster:
		if int(hero.star) >= 2 and int(hero.xp) < HeroProgression.MAX_XP:
			return true
	return false


func _can_train_archetype_two_star(state: RefCounted, archetype_id: String) -> bool:
	if state.economy.xp_books <= 0 or state.economy.gold < HeroProgression.GOLD_PER_BOOK:
		return false
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id and int(hero.star) >= 2 and int(hero.xp) < HeroProgression.MAX_XP:
			return true
	return false


func _salvage_balance(state: RefCounted) -> int:
	if state == null:
		return 0
	if state.get("inventory") != null:
		var inventory := state.inventory as Dictionary
		var items := inventory.get("items", {}) as Dictionary
		if items.has("alliance_scrap"):
			return int(items["alliance_scrap"])
	var direct: Variant = state.get("salvage")
	if direct != null:
		return int(direct)
	if state.get("economy") != null:
		var economy_value: Variant = state.economy.get("salvage")
		if economy_value != null:
			return int(economy_value)
	if state.get("factory") != null:
		var factory_value: Variant = state.factory.get("salvage")
		if factory_value != null:
			return int(factory_value)
	return 0


func _war_merit_points(state: RefCounted) -> int:
	if state == null:
		return 0
	var quests := state.get("quests") as Dictionary
	if quests != null:
		for key in ["war_merit", "war_merit_points", "points", "total_points"]:
			if quests.has(key):
				return int(quests[key])
	if state.get("inventory") != null:
		var inventory := state.inventory as Dictionary
		var items := inventory.get("items", {}) as Dictionary
		for item_id in ["war_merit", "battle_merit"]:
			if items.has(item_id):
				return int(items[item_id])
	return 0


func _war_merit_rank(state: RefCounted) -> int:
	return QuestCatalog.rank_for_merit(_war_merit_points(state))


func _war_merit_next_progress(state: RefCounted) -> String:
	var rank := _war_merit_rank(state)
	if rank >= QuestCatalog.MAX_RANK:
		return "已达等级上限（战功继续累计）"
	var remaining := _war_merit_points(state)
	for level in range(1, rank):
		remaining -= QuestCatalog.rank_requirement(level)
	return "%d/%d" % [maxi(0, remaining), QuestCatalog.rank_requirement(rank)]


func _show_quests() -> void:
	app_state = AppState.QUESTS
	_refresh_quests_if_needed()
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_add_background(Color(0.02, 0.04, 0.08, 0.64))
	_show_management_shell("目标", _build_quests_body())


func _refresh_quests_if_needed() -> void:
	var state: RefCounted = game.current_state()
	var quest_state := state.get("quests") as Dictionary
	if quest_state != null:
		var active := quest_state.get("active", {}) as Dictionary
		var slots := active.get("minor_slots", []) as Array
		if slots.size() == QuestCatalog.MINOR_SLOT_COUNT:
			return
	var request_id := "quests:refresh:%d" % int(state.revision)
	_execute_command("refresh_quests", {}, request_id)


func _build_quests_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "QuestsScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(1180, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	column.add_child(_build_goal_tabs(false))
	var state: RefCounted = game.current_state()
	var rank_label := _label(
		"累计战功 %d · 当前等级 Lv%d · 下一级 %s" % [_war_merit_points(state), _war_merit_rank(state), _war_merit_next_progress(state)],
		16,
		COLOR_ACCENT
	)
	rank_label.name = "QuestWarMeritLabel"
	column.add_child(rank_label)
	var no_timer := _label("无每日倒计时：任务按大战役推进和循环目标刷新。", 13, COLOR_MUTED)
	no_timer.name = "QuestNoDailyCountdownLabel"
	column.add_child(no_timer)
	var entries := _quest_active_entries(state, true)
	var campaign := _campaign_quest_entry(entries)
	column.add_child(_quest_card(campaign, true, state))
	var loop_grid := GridContainer.new()
	loop_grid.columns = 3
	loop_grid.add_theme_constant_override("h_separation", 6)
	loop_grid.add_theme_constant_override("v_separation", 6)
	loop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(loop_grid)
	var loops := _loop_quest_entries(entries)
	for index in 3:
		loop_grid.add_child(_quest_card(loops[index], false, state, index + 1))
	return scroll


func _show_achievements() -> void:
	app_state = AppState.QUESTS
	_refresh_achievements_if_needed()
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_add_background(Color(0.02, 0.04, 0.08, 0.64))
	_show_management_shell("目标", _build_achievements_body())


func _build_goal_tabs(achievements_selected: bool) -> Control:
	var tabs := HBoxContainer.new()
	tabs.name = "GoalCenterTabs"
	tabs.add_theme_constant_override("separation", 8)
	var quests := _button("任务", COLOR_PRIMARY if not achievements_selected else COLOR_PANEL_ALT, Vector2(120, 50), 15)
	quests.name = "GoalTabQuestsButton"
	quests.pressed.connect(_show_quests)
	tabs.add_child(quests)
	var achievements := _button("成就", COLOR_PRIMARY if achievements_selected else COLOR_PANEL_ALT, Vector2(120, 50), 15)
	achievements.name = "GoalTabAchievementsButton"
	achievements.pressed.connect(_show_achievements)
	tabs.add_child(achievements)
	return tabs


func _refresh_achievements_if_needed() -> void:
	var state: RefCounted = game.current_state()
	var achievement_state := state.get("achievements") as Dictionary
	if achievement_state != null:
		var progress := achievement_state.get("progress", {}) as Dictionary
		var completed := achievement_state.get("completed", {}) as Dictionary
		var claimed := achievement_state.get("claimed", {}) as Dictionary
		if not progress.is_empty() or not completed.is_empty() or not claimed.is_empty():
			return
	var request_id := "achievements:refresh:%d" % int(state.revision)
	_execute_command("refresh_achievements", {}, request_id)


func _build_achievements_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "AchievementsScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.name = "AchievementsListColumn"
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(1180, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	column.add_child(_build_goal_tabs(true))
	var state: RefCounted = game.current_state()
	var definitions := _achievement_definitions()
	var completed_count := _achievement_completed_count(state, definitions)
	var claimable_count := _achievement_claimable_count(state, definitions)
	var overview := _label("总完成 %d/%d · 可领取 %d" % [completed_count, definitions.size(), claimable_count], 16, COLOR_ACCENT)
	overview.name = "AchievementOverviewLabel"
	column.add_child(overview)
	column.add_child(_build_achievement_category_buttons())
	var sorted_definitions := definitions.duplicate(true)
	sorted_definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _achievement_sort_weight(state, a) < _achievement_sort_weight(state, b)
	)
	for definition in sorted_definitions:
		if selected_achievement_category == "all" or String(definition.get("category", "")) == selected_achievement_category:
			column.add_child(_achievement_card(definition, state))
	return scroll


func _build_achievement_category_buttons() -> Control:
	var row := HBoxContainer.new()
	row.name = "AchievementCategoryButtons"
	row.add_theme_constant_override("separation", 6)
	var categories := [
		{"id": "all", "label": "全部"},
		{"id": "campaign", "label": "战役"},
		{"id": "factory", "label": "工厂"},
		{"id": "cultivation", "label": "培育"},
		{"id": "collection", "label": "收集"},
	]
	for category in categories:
		var category_id := String(category["id"])
		var button := _button(String(category["label"]), COLOR_PRIMARY if selected_achievement_category == category_id else COLOR_PANEL_ALT, Vector2(92, 50), 13)
		button.name = "AchievementCategoryButton_%s" % category_id
		button.pressed.connect(func() -> void:
			selected_achievement_category = category_id
			_show_achievements()
		)
		row.add_child(button)
	return row


func _achievement_card(definition: Dictionary, state: RefCounted) -> Control:
	var achievement_id := String(definition.get("achievement_id", definition.get("id", "")))
	var completed := _achievement_is_completed(state, definition)
	var claimed := _achievement_is_claimed(state, definition)
	var card := _panel(COLOR_PANEL, 7)
	card.name = "AchievementCard_%s" % _safe_node_suffix(achievement_id)
	card.custom_minimum_size = Vector2(1180, 132)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 3)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(String(definition.get("title", achievement_id)), 15, COLOR_TEXT))
	copy.add_child(_label("分类：%s · 进度：%s" % [_achievement_category_label(String(definition.get("category", "campaign"))), _achievement_progress_text(state, definition)], 12, COLOR_MUTED))
	copy.add_child(_label("奖励：%s" % _achievement_reward_text(definition.get("reward", {}) as Dictionary), 12, COLOR_ACCENT))
	var action := _button("已领取" if claimed else ("领取" if completed else "进行中"), COLOR_PRIMARY if completed and not claimed else COLOR_PANEL_ALT, Vector2(104, 50), 13)
	action.name = "AchievementClaimButton_%s" % _safe_node_suffix(achievement_id)
	action.disabled = claimed or not completed
	action.pressed.connect(func() -> void: _claim_achievement(achievement_id))
	row.add_child(action)
	return card


func _claim_achievement(achievement_id: String) -> void:
	var request_id := "achievement:claim:%s:0:%d" % [achievement_id, int(game.current_state().revision)]
	var result := _execute_command("claim_achievement", {"achievement_id": achievement_id, "generation": 0, "request_id": request_id}, request_id)
	if bool(result.get("ok", false)):
		if app_state == AppState.QUESTS:
			_show_achievements()
		return
	_show_notice("成就领取暂不可用：%s" % String(result.get("error", "UNKNOWN")))


func _achievement_definitions() -> Array[Dictionary]:
	if ResourceLoader.exists(ACHIEVEMENT_CATALOG_PATH):
		var catalog = load(ACHIEVEMENT_CATALOG_PATH)
		if catalog != null and catalog.has_method("definitions"):
			var values: Array[Dictionary] = []
			for value in catalog.definitions():
				if typeof(value) == TYPE_DICTIONARY:
					values.append((value as Dictionary).duplicate(true))
			if not values.is_empty():
				return values
	return _fallback_achievement_definitions()


func _fallback_achievement_definitions() -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	var categories: Array[String] = ["campaign", "factory", "cultivation", "collection"]
	var labels: Dictionary = {"campaign": "战役", "factory": "工厂", "cultivation": "培育", "collection": "收集"}
	for index in 24:
		var category: String = categories[index % categories.size()]
		values.append({
			"achievement_id": "fallback.%s.%02d" % [category, index + 1],
			"title": "%s成就 %02d" % [String(labels[category]), index + 1],
			"category": category,
			"progress": 0,
			"target": 1,
			"reward": {"merit": 10},
		})
	return values


func _achievement_completed_count(state: RefCounted, definitions: Array[Dictionary]) -> int:
	var count := 0
	for definition in definitions:
		if _achievement_is_completed(state, definition):
			count += 1
	return count


func _achievement_claimable_count(state: RefCounted, definitions: Array[Dictionary]) -> int:
	var count := 0
	for definition in definitions:
		if _achievement_is_completed(state, definition) and not _achievement_is_claimed(state, definition):
			count += 1
	return count


func _achievement_sort_weight(state: RefCounted, definition: Dictionary) -> int:
	if _achievement_is_completed(state, definition) and not _achievement_is_claimed(state, definition):
		return 0
	if not _achievement_is_completed(state, definition):
		return 1
	return 2


func _achievement_is_completed(state: RefCounted, definition: Dictionary) -> bool:
	var achievement_id := String(definition.get("achievement_id", definition.get("id", "")))
	var achievement_state := state.get("achievements") as Dictionary
	if achievement_state != null:
		var completed := achievement_state.get("completed", {}) as Dictionary
		if completed.has(achievement_id):
			return true
	return _achievement_progress_value(state, definition) >= _achievement_target(definition)


func _achievement_is_claimed(state: RefCounted, definition: Dictionary) -> bool:
	var achievement_id := String(definition.get("achievement_id", definition.get("id", "")))
	var achievement_state := state.get("achievements") as Dictionary
	if achievement_state != null:
		var claimed := achievement_state.get("claimed", {}) as Dictionary
		return claimed.has(achievement_id)
	return false


func _achievement_progress_text(state: RefCounted, definition: Dictionary) -> String:
	var target := _achievement_target(definition)
	return "%d/%d" % [clampi(_achievement_progress_value(state, definition), 0, target), target]


func _achievement_progress_value(state: RefCounted, definition: Dictionary) -> int:
	var achievement_id := String(definition.get("achievement_id", definition.get("id", "")))
	var achievement_state := state.get("achievements") as Dictionary
	if achievement_state != null:
		var progress := achievement_state.get("progress", {}) as Dictionary
		if progress.has(achievement_id):
			var value = progress[achievement_id]
			if typeof(value) == TYPE_DICTIONARY:
				return int((value as Dictionary).get("value", (value as Dictionary).get("progress", 0)))
			return int(value)
	return int(definition.get("progress", 0))


func _achievement_target(definition: Dictionary) -> int:
	return maxi(1, int(definition.get("target", definition.get("goal", 1))))


func _achievement_reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	if int(reward.get("merit", 0)) > 0:
		parts.append("战功+%d" % int(reward["merit"]))
	if int(reward.get("gold", 0)) > 0:
		parts.append("金币+%d" % int(reward["gold"]))
	if int(reward.get("xp_books", 0)) > 0:
		parts.append("训练书+%d" % int(reward["xp_books"]))
	return "无" if parts.is_empty() else " · ".join(parts)


func _achievement_category_label(category: String) -> String:
	return String({
		"campaign": "战役",
		"factory": "工厂",
		"cultivation": "培育",
		"collection": "收集",
	}.get(category, category))


func _safe_node_suffix(value: String) -> String:
	return value.replace(".", "_").replace(":", "_").replace("/", "_")


func _quest_card(entry: Dictionary, campaign: bool, state: RefCounted, loop_index: int = 0) -> Control:
	var card := _panel(COLOR_PANEL, 7)
	card.name = "CampaignQuestCard" if campaign else "LoopQuestCard_%d" % loop_index
	card.custom_minimum_size = Vector2(1180, 150) if campaign else Vector2(384, 190)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var title := _label(String(entry.get("title", "任务")), 15 if campaign else 13, COLOR_TEXT)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(title)
	var progress := _quest_progress_text(entry)
	var body := _label("%s · %s" % [String(entry.get("description", "")), progress], 12, COLOR_MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	if campaign:
		var summary := _label("大战役进度：%s · 25目标不展开长列表" % progress, 12, COLOR_ACCENT)
		summary.name = "CampaignQuestSummaryLabel"
		column.add_child(summary)
	else:
		column.add_child(_label(String(entry.get("reward_text", "战功")), 11, COLOR_ACCENT))
	var action := _quest_action_button(entry, state)
	column.add_child(action)
	return card


func _quest_action_button(entry: Dictionary, state: RefCounted) -> Button:
	var quest_id := String(entry.get("quest_id", ""))
	var generation := int(entry.get("generation", 1))
	var completed := _quest_is_completed(state, entry)
	var claimed := _quest_is_claimed(state, entry)
	var action := _button("已领取" if claimed else ("领取" if completed else "进行中"), COLOR_PRIMARY if completed and not claimed else COLOR_PANEL_ALT, Vector2(104, 50), 13)
	action.name = "QuestClaimButton_%s" % _safe_node_suffix(quest_id)
	action.disabled = claimed or not completed
	action.pressed.connect(func() -> void: _claim_quest(quest_id, generation))
	return action


func _claim_quest(quest_id: String, generation: int) -> void:
	var request_id := "quest:claim:%s:%d:%d" % [quest_id, generation, int(game.current_state().revision)]
	var result := _execute_command("claim_quest", {"quest_id": quest_id, "generation": generation, "request_id": request_id}, request_id)
	if bool(result.get("ok", false)):
		if app_state == AppState.QUESTS:
			_show_quests()
		return
	_show_notice("任务领取暂不可用：%s" % String(result.get("error", "UNKNOWN")))


func _quest_active_entries(state: RefCounted, include_fallback: bool) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var quest_state := state.get("quests") as Dictionary
	if quest_state != null:
		var active := quest_state.get("active", {}) as Dictionary
		var completed := quest_state.get("completed", {}) as Dictionary
		var claimed := quest_state.get("claimed", {}) as Dictionary
		for stage_id in StageCatalog.all_stage_ids():
			var major := QuestCatalog.major_quest(stage_id)
			var major_id := String(major.get("quest_id", ""))
			if claimed.has(major_id):
				continue
			major["scope"] = "major"
			major["description"] = "完成该关首次胜利，推动地球马桶人战线。"
			major["progress"] = 1 if completed.has(major_id) else 0
			major["target"] = 1
			major["reward_text"] = _quest_reward_text(major.get("reward", {}) as Dictionary)
			entries.append(major)
			break
		for slot_value in active.get("minor_slots", []):
			if typeof(slot_value) != TYPE_DICTIONARY:
				continue
			var entry := (slot_value as Dictionary).duplicate(true)
			entry["scope"] = "minor"
			entry["description"] = "完成后可手动领取，领取后本槽自动补入新目标。"
			entry["reward_text"] = _quest_reward_text(entry.get("reward", {}) as Dictionary)
			entries.append(entry)
	if entries.is_empty() and include_fallback:
		for fallback in FALLBACK_QUESTS:
			entries.append(fallback.duplicate(true))
	return entries


func _quest_reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	if int(reward.get("merit", 0)) > 0:
		parts.append("战功+%d" % int(reward["merit"]))
	if int(reward.get("gold", 0)) > 0:
		parts.append("金币+%d" % int(reward["gold"]))
	if int(reward.get("xp_books", 0)) > 0:
		parts.append("训练书+%d" % int(reward["xp_books"]))
	return " · ".join(parts)


func _campaign_quest_entry(entries: Array[Dictionary]) -> Dictionary:
	for entry in entries:
		var scope := String(entry.get("scope", entry.get("type", "")))
		if scope in ["campaign", "major", "war"]:
			return entry
	return FALLBACK_QUESTS[0].duplicate(true)


func _loop_quest_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	var loops: Array[Dictionary] = []
	for entry in entries:
		var scope := String(entry.get("scope", entry.get("type", "")))
		if scope in ["loop", "daily", "repeatable", "minor"]:
			loops.append(entry)
	while loops.size() < 3:
		loops.append(FALLBACK_QUESTS[loops.size() + 1].duplicate(true))
	return loops.slice(0, 3)


func _quest_progress_text(entry: Dictionary) -> String:
	var progress := int(entry.get("progress", entry.get("current", 0)))
	var target := maxi(1, int(entry.get("target", entry.get("goal", 1))))
	return "%d/%d" % [clampi(progress, 0, target), target]


func _quest_is_completed(state: RefCounted, entry: Dictionary) -> bool:
	if bool(entry.get("completed", false)):
		return true
	var quest_id := String(entry.get("quest_id", ""))
	var quest_state := state.get("quests") as Dictionary
	if quest_state != null:
		var completed := quest_state.get("completed", {}) as Dictionary
		if completed.has(quest_id):
			return true
	return int(entry.get("progress", entry.get("current", 0))) >= int(entry.get("target", entry.get("goal", 1)))


func _quest_is_claimed(state: RefCounted, entry: Dictionary) -> bool:
	if bool(entry.get("claimed", false)):
		return true
	var quest_id := String(entry.get("quest_id", ""))
	var quest_state := state.get("quests") as Dictionary
	if quest_state != null:
		var claimed := quest_state.get("claimed", {}) as Dictionary
		return claimed.has(quest_id)
	return false


func _show_factory() -> void:
	app_state = AppState.FACTORY
	factory_refresh_elapsed = 0.0
	factory_order_views.clear()
	_clear_ui()
	_clear_world()
	_build_factory_world()
	_show_management_shell("工厂", _build_factory_body())


func _build_factory_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	var state: RefCounted = game.current_state()
	var now := int(Time.get_unix_time_from_system())
	var summary: Dictionary = FactoryService.offline_summary(state, now)
	if int(summary.get("ready_count", 0)) > 0:
		var ready_panel := _panel(Color(0.10, 0.16, 0.12, 0.96), 8)
		column.add_child(ready_panel)
		var ready_row := HBoxContainer.new()
		ready_row.add_theme_constant_override("separation", 8)
		ready_panel.add_child(ready_row)
		var ready_copy := _label("离线生产完成 %d 单，打开仓门即可领取。" % int(summary["ready_count"]), 15, COLOR_PRIMARY)
		ready_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ready_row.add_child(ready_copy)
		var claim_all := _button("领取完成", COLOR_PRIMARY, Vector2(120, 34), 13)
		claim_all.pressed.connect(_claim_ready_productions)
		ready_row.add_child(claim_all)
	column.add_child(_build_salvage_exchange_panel(state))
	var queue_title := _label("生产队列  %d/3" % state.factory.production_queue.size(), 17, COLOR_PRIMARY)
	column.add_child(queue_title)
	var queue_grid := GridContainer.new()
	queue_grid.columns = 3
	queue_grid.add_theme_constant_override("h_separation", 8)
	column.add_child(queue_grid)
	for index in 3:
		var order: Dictionary = state.factory.production_queue[index] if index < state.factory.production_queue.size() else {}
		queue_grid.add_child(_factory_order_card(order, now))
	column.add_child(_label("四类车间", 17, COLOR_PRIMARY))
	var workshop_labels := {
		"ordinary": "普通车间：低成本补员与前线压制",
		"flying": "飞行车间：远程轰炸与爆发突破",
		"heavy": "重装车间：抗线、破门、切精英",
		"special": "特殊车间：维修、寄生与战术反制",
	}
	for workshop_id in ["ordinary", "flying", "heavy", "special"]:
		var workshop := _panel(COLOR_PANEL, 8)
		column.add_child(workshop)
		var workshop_box := VBoxContainer.new()
		workshop_box.add_theme_constant_override("separation", 6)
		workshop.add_child(workshop_box)
		workshop_box.add_child(_label(String(workshop_labels[workshop_id]), 15, COLOR_ACCENT))
		var recipes := GridContainer.new()
		recipes.columns = 2
		recipes.add_theme_constant_override("h_separation", 8)
		recipes.add_theme_constant_override("v_separation", 8)
		workshop_box.add_child(recipes)
		for recipe in FactoryCatalog.recipes():
			if String(recipe["workshop"]) == workshop_id:
				recipes.add_child(_recipe_card(recipe, bool(state.factory.blueprints.get(String(recipe["recipe_id"]), false))))
	return scroll


func _build_salvage_exchange_panel(state: RefCounted) -> Control:
	var panel := _panel(Color(0.06, 0.095, 0.13, 0.96), 8)
	panel.name = "SalvageExchangePanel"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var balance := _salvage_balance(state)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	var title := _label("联盟残骸回收", 16, COLOR_PRIMARY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var balance_label := _label("残骸 %d" % balance, 14, COLOR_ACCENT)
	balance_label.name = "SalvageSummaryLabel"
	header.add_child(balance_label)
	var exchange_grid := GridContainer.new()
	exchange_grid.columns = 3
	exchange_grid.add_theme_constant_override("h_separation", 6)
	exchange_grid.add_theme_constant_override("v_separation", 4)
	column.add_child(exchange_grid)
	for config in SALVAGE_EXCHANGES:
		exchange_grid.add_child(_salvage_exchange_card(config, balance))
	return panel


func _salvage_exchange_card(config: Dictionary, balance: int) -> Control:
	var exchange := _button(
		"%s\n%d残 → %s" % [
			String(config["display_name"]),
			int(config["cost"]),
			String(config["reward_text"]),
		],
		COLOR_PRIMARY,
		Vector2(105, 52),
		11
	)
	var exchange_id := String(config["exchange_id"])
	exchange.name = "SalvageExchangeButton_%s" % exchange_id
	exchange.disabled = balance < int(config["cost"])
	exchange.tooltip_text = "%s：消耗%d联盟残骸，获得%s" % [
		String(config["display_name"]),
		int(config["cost"]),
		String(config["reward_text"]),
	]
	exchange.pressed.connect(func() -> void: _exchange_salvage(exchange_id))
	return exchange


func _exchange_salvage(exchange_id: String) -> void:
	var request_id := "salvage:%s:%d" % [exchange_id, int(game.current_state().revision)]
	var result := _execute_command("exchange_salvage", {"request_id": request_id, "offer_id": exchange_id}, request_id)
	if bool(result.get("ok", false)):
		if app_state == AppState.FACTORY:
			_show_factory()
		return
	_show_notice("残骸回收暂不可用：%s" % String(result.get("error", "UNKNOWN")))


func _factory_order_card(order: Dictionary, now: int) -> Control:
	var card := _panel(COLOR_PANEL, 8)
	card.custom_minimum_size = Vector2(180, 92)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	if order.is_empty():
		column.add_child(_label("空队列", 15, COLOR_MUTED))
		column.add_child(_label("选择下方配方开始生产", 13, COLOR_MUTED))
		return card
	var recipe := FactoryCatalog.recipe(String(order["recipe_id"]))
	column.add_child(_label(String(recipe.get("display_name", order["recipe_id"])), 15, COLOR_TEXT))
	var remain := maxi(0, int(order["completes_at_unix"]) - now)
	var timer_label := _label("剩余 %02d:%02d" % [remain / 60, remain % 60], 13, COLOR_ACCENT if remain > 0 else COLOR_PRIMARY)
	column.add_child(timer_label)
	var claim := _button("领取", COLOR_PRIMARY if remain == 0 else COLOR_PANEL_ALT, Vector2(120, 34), 14)
	claim.disabled = remain > 0
	var order_id := String(order["order_id"])
	claim.pressed.connect(func() -> void: _claim_production(order_id))
	column.add_child(claim)
	factory_order_views.append({
		"completes_at_unix": int(order["completes_at_unix"]),
		"timer_label": timer_label,
		"claim_button": claim,
	})
	return card


func _update_factory_order_views() -> void:
	var now := int(Time.get_unix_time_from_system())
	for view in factory_order_views:
		var timer_label := view.get("timer_label") as Label
		var claim_button := view.get("claim_button") as Button
		if not is_instance_valid(timer_label) or not is_instance_valid(claim_button):
			continue
		var remain := maxi(0, int(view["completes_at_unix"]) - now)
		timer_label.text = "剩余 %02d:%02d" % [remain / 60, remain % 60]
		timer_label.add_theme_color_override("font_color", COLOR_ACCENT if remain > 0 else COLOR_PRIMARY)
		claim_button.disabled = remain > 0


func _recipe_card(recipe: Dictionary, unlocked: bool = true) -> Control:
	var card := _panel(COLOR_PANEL, 8)
	card.custom_minimum_size = Vector2(270, 112)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(String(recipe["display_name"]), 16, COLOR_TEXT))
	copy.add_child(_label("%s · %s · %ds" % [recipe["workshop"], recipe["rarity"], int(recipe["duration_seconds"])], 12, COLOR_MUTED))
	var cost: Dictionary = recipe["cost"]
	copy.add_child(_label("瓷%d 零%d 泥%d" % [int(cost["porcelain"]), int(cost["parts"]), int(cost["sludge"])], 13, COLOR_ACCENT))
	var archetype: Dictionary = FactoryCatalog.archetype(String(recipe["archetype_id"]))
	copy.add_child(_label("%s · %s" % [_role_name(String(archetype.get("role", ""))), String(archetype.get("description", ""))], 11, COLOR_MUTED))
	var start := _button("开始", COLOR_PRIMARY, Vector2(74, 74), 14)
	var recipe_id := String(recipe["recipe_id"])
	if not unlocked:
		start.text = "锁定"
		start.disabled = true
		copy.add_child(_label(_blueprint_hint(recipe_id), 11, COLOR_DANGER))
	start.pressed.connect(func() -> void: _start_production(recipe_id))
	row.add_child(start)
	return card


func _start_production(recipe_id: String) -> void:
	var now := int(Time.get_unix_time_from_system())
	var result := _execute_command("start_production", {"recipe_id": recipe_id, "now_unix": now}, "")
	if bool(result.get("ok", false)):
		_play_factory_start_feedback(recipe_id)
		await get_tree().create_timer(0.35).timeout
		if app_state == AppState.FACTORY:
			_show_factory()
	else:
		_show_notice("生产失败：%s" % result.get("error", "UNKNOWN"))


func _claim_production(order_id: String) -> void:
	var now := int(Time.get_unix_time_from_system())
	var result := _execute_command("claim_production", {"order_id": order_id, "now_unix": now}, "")
	if bool(result.get("ok", false)):
		var event: Dictionary = result.get("event", {}) as Dictionary
		_play_factory_claim_feedback(String(event.get("hero_id", "")), String(event.get("recipe_id", "")))
		await get_tree().create_timer(0.75).timeout
		if app_state == AppState.FACTORY:
			_show_factory()
	else:
		_show_notice("领取失败：%s" % result.get("error", "UNKNOWN"))


func _claim_ready_productions() -> void:
	var now := int(Time.get_unix_time_from_system())
	var result := _execute_command("claim_ready_productions", {"now_unix": now}, "")
	if bool(result.get("ok", false)):
		var event: Dictionary = result.get("event", {}) as Dictionary
		var claimed: Array = event.get("claimed", [])
		_show_notice("离线完成订单已领取：%d 名马桶人入列。" % claimed.size())
		if not claimed.is_empty():
			var first := claimed[0] as Dictionary
			_play_factory_claim_feedback(String(first.get("hero_id", "")), String(first.get("recipe_id", "")))
			await get_tree().create_timer(0.75).timeout
		if app_state == AppState.FACTORY:
			_show_factory()
	else:
		_show_notice("暂无可领取订单：%s" % result.get("error", "UNKNOWN"))


func _show_cultivation() -> void:
	app_state = AppState.CULTIVATION
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_show_management_shell("培育", _build_cultivation_body())


func _build_cultivation_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	column.add_child(_label("同 archetype + star 的 3 个英雄可三合一升星。", 15, COLOR_MUTED))
	column.add_child(_build_training_panel())
	var groups: Dictionary = {}
	for hero in game.current_state().roster:
		var key := "%s|%d" % [hero.archetype_id, hero.star]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(hero)
	for key in groups.keys():
		var heroes := groups[key] as Array
		if heroes.size() < 2:
			continue
		var card := _panel(COLOR_PANEL, 8)
		column.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)
		var exemplar: RefCounted = heroes[0]
		box.add_child(_label("%s  ★%d  (%d/3)" % [_archetype_name(exemplar.archetype_id), exemplar.star, heroes.size()], 17, COLOR_TEXT))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		box.add_child(row)
		for hero in heroes:
			var toggle := _button(("✓ " if selected_merge_ids.has(hero.hero_id) else "") + hero.display_name, COLOR_PANEL_ALT, Vector2(150, 42), 13)
			var hero_id := String(hero.hero_id)
			toggle.pressed.connect(func() -> void: _toggle_merge_selection(hero_id))
			row.add_child(toggle)
	var merge := _button("三合一升星", COLOR_PRIMARY, Vector2(180, 48), 16)
	merge.disabled = selected_merge_ids.size() != 3
	merge.pressed.connect(_merge_selected_heroes)
	column.add_child(merge)
	return scroll


func _build_training_panel() -> Control:
	var state: RefCounted = game.current_state()
	if selected_training_id.is_empty() and not state.roster.is_empty():
		selected_training_id = String(state.roster[0].hero_id)
	var panel := _panel(Color(0.07, 0.11, 0.17, 0.96), 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	row.add_child(list)
	list.add_child(_label("训练", 17, COLOR_PRIMARY))
	for index in state.roster.size():
		var hero: RefCounted = state.roster[index]
		var pick := _button(("✓ " if hero.hero_id == selected_training_id else "") + "%s L%d ★%d" % [hero.display_name, hero.level, hero.star], COLOR_PANEL_ALT, Vector2(190, 34), 11)
		var hero_id := String(hero.hero_id)
		pick.pressed.connect(func() -> void:
			selected_training_id = hero_id
			_show_cultivation()
		)
		list.add_child(pick)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 5)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	var selected: RefCounted = state.hero_by_id(selected_training_id)
	if selected == null:
		detail.add_child(_label("没有可训练英雄。", 14, COLOR_MUTED))
		return panel
	var stats_before: Dictionary = HeroProgression.derived_battle_stats(selected)
	var preview: RefCounted = selected.deep_clone()
	HeroProgression.train_with_books(preview, 1)
	var stats_after: Dictionary = HeroProgression.derived_battle_stats(preview)
	var archetype: Dictionary = FactoryCatalog.archetype(String(selected.archetype_id))
	detail.add_child(_label("%s  L%d  XP %d/320  ★%d" % [selected.display_name, selected.level, selected.xp, selected.star], 15, COLOR_TEXT))
	detail.add_child(_label("%s · %s · 技能层级 T%d" % [
		_role_name(String(archetype.get("role", ""))),
		String(archetype.get("active_skill", "")),
		HeroProgression.skill_tier(selected),
	], 12, COLOR_PRIMARY))
	detail.add_child(_label("消耗：金币%d + 训练书1；当前 金%d/书%d" % [HeroProgression.GOLD_PER_BOOK, state.economy.gold, state.economy.xp_books], 13, COLOR_ACCENT))
	detail.add_child(_label("预览：HP %d→%d  攻击 %d→%d  防御 %d→%d" % [
		int(stats_before["max_hp"]),
		int(stats_after["max_hp"]),
		maxi(int(stats_before["physical_atk"]), int(stats_before["magic_atk"])),
		maxi(int(stats_after["physical_atk"]), int(stats_after["magic_atk"])),
		int(stats_before["defense"]),
		int(stats_after["defense"]),
	], 13, COLOR_MUTED))
	var train := _button("训练1本", COLOR_PRIMARY, Vector2(140, 40), 13)
	train.disabled = state.economy.xp_books < 1 or state.economy.gold < HeroProgression.GOLD_PER_BOOK or selected.level >= 5
	train.pressed.connect(func() -> void: _train_selected_hero(1))
	detail.add_child(train)
	return panel


func _train_selected_hero(book_count: int) -> void:
	if selected_training_id.is_empty():
		return
	var result := _execute_command("train_hero", {"hero_id": selected_training_id, "book_count": book_count}, "")
	if bool(result.get("ok", false)):
		_show_cultivation()
	else:
		_show_notice("训练失败：%s" % result.get("error", "UNKNOWN"))


func _toggle_merge_selection(hero_id: String) -> void:
	if selected_merge_ids.has(hero_id):
		selected_merge_ids.erase(hero_id)
	elif selected_merge_ids.size() < 3:
		if selected_merge_ids.is_empty():
			selected_merge_ids.append(hero_id)
		elif _merge_group_key(hero_id) == _merge_group_key(selected_merge_ids[0]):
			selected_merge_ids.append(hero_id)
		else:
			selected_merge_ids.clear()
			selected_merge_ids.append(hero_id)
	_show_cultivation()


func _merge_selected_heroes() -> void:
	var result := _execute_command("merge_heroes", {"hero_ids": selected_merge_ids.duplicate()}, "")
	if bool(result.get("ok", false)):
		selected_merge_ids.clear()
		_show_cultivation()
	else:
		_show_notice("培育失败：%s" % result.get("error", "UNKNOWN"))


func _show_formation() -> void:
	app_state = AppState.FORMATION
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_show_management_shell("六人编队", _build_formation_body())


func _build_formation_body() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	row.add_child(grid)
	var state: RefCounted = game.current_state()
	var ids: Array[String] = state.formation.hero_ids()
	for index in 6:
		var hero: RefCounted = state.hero_by_id(ids[index])
		var slot := _button(_formation_slot_text(index, hero), COLOR_PRIMARY if index == selected_formation_slot else COLOR_PANEL, Vector2(150, 82), 13)
		var slot_index := index
		slot.pressed.connect(func() -> void:
			selected_formation_slot = slot_index
			_show_formation()
		)
		grid.add_child(slot)
	var reserve_panel := _panel(COLOR_PANEL, 10)
	reserve_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(reserve_panel)
	var reserve_column := VBoxContainer.new()
	reserve_column.add_theme_constant_override("separation", 6)
	reserve_panel.add_child(reserve_column)
	reserve_column.add_child(_label("替换 %s" % SLOT_NAMES[selected_formation_slot], 17, COLOR_PRIMARY))
	var reserves := _reserve_heroes()
	if reserves.is_empty():
		reserve_column.add_child(_label("当前没有未上阵英雄。", 15, COLOR_MUTED))
	for hero in reserves:
		var pick := _button("%s ★%d %s" % [hero.display_name, hero.star, _class_name(hero.class_id)], COLOR_PANEL_ALT, Vector2(220, 40), 13)
		var hero_id := String(hero.hero_id)
		pick.pressed.connect(func() -> void: _replace_formation_slot(hero_id))
		reserve_column.add_child(pick)
	return row


func _formation_slot_text(index: int, hero: RefCounted) -> String:
	if hero == null:
		return "%s\n空" % SLOT_NAMES[index]
	return "%s\n%s ★%d\n%s" % [SLOT_NAMES[index], hero.display_name, hero.star, _class_name(hero.class_id)]


func _replace_formation_slot(hero_id: String) -> void:
	var state: RefCounted = game.current_state()
	var payload: Dictionary = state.formation.to_dict()
	payload[SLOT_KEYS[selected_formation_slot]] = hero_id
	var result := _execute_command("set_formation", payload, "")
	if bool(result.get("ok", false)):
		_show_formation()
	else:
		_show_notice("编队保存失败：%s" % result.get("error", "UNKNOWN"))


func _reserve_heroes() -> Array[RefCounted]:
	var state: RefCounted = game.current_state()
	var deployed: Array[String] = state.formation.hero_ids()
	var reserves: Array[RefCounted] = []
	for hero in state.roster:
		if not deployed.has(String(hero.hero_id)):
			reserves.append(hero)
	return reserves


func _show_expedition() -> void:
	app_state = AppState.EXPEDITION
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_add_background(Color(0.02, 0.04, 0.08, 0.62))
	var state: RefCounted = game.current_state()
	if not _stage_is_unlocked(selected_stage_id, state):
		selected_stage_id = String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	if not StageCatalog.has_stage(selected_stage_id):
		selected_stage_id = StageCatalog.DEFAULT_STAGE_ID
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)
	var title := _label("第一幕 · 地球战争", 25, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := _button("返回营地", COLOR_PANEL_ALT, Vector2(110, 50), 14)
	back.name = "ExpeditionBackButton"
	back.pressed.connect(_show_camp)
	header.add_child(back)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var map_panel := _panel(Color(0.045, 0.07, 0.11, 0.96), 9)
	map_panel.name = "ExpeditionMapPanel"
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_stretch_ratio = 0.45
	body.add_child(map_panel)
	var map_scroll := ScrollContainer.new()
	map_scroll.name = "MapScrollContainer"
	map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_child(map_scroll)
	var chapter_column := VBoxContainer.new()
	chapter_column.add_theme_constant_override("separation", 8)
	map_scroll.add_child(chapter_column)
	var chapter_names := ["灰镜", "震荡", "黑屏", "联防", "伪胜"]
	var stage_ids := StageCatalog.all_stage_ids()
	var cleared: Array = state.stage_progress.get("cleared_stages", [])
	for chapter_index in 5:
		var chapter_row := HBoxContainer.new()
		chapter_row.name = "ChapterStageRow_%d" % [chapter_index + 1]
		chapter_row.add_theme_constant_override("separation", 5)
		chapter_column.add_child(chapter_row)
		var chapter_title := _label("%d  %s" % [chapter_index + 1, chapter_names[chapter_index]], 14, COLOR_ACCENT)
		chapter_title.custom_minimum_size.x = 112 * UI_SCALE
		chapter_row.add_child(chapter_title)
		for stage_index in 5:
			var stage_id: String = stage_ids[chapter_index * 5 + stage_index]
			var unlocked := _stage_is_unlocked(stage_id, state)
			var is_cleared := cleared.has(stage_id)
			var selected := stage_id == selected_stage_id
			var stage_text := "%d-%d" % [chapter_index + 1, stage_index + 1]
			if is_cleared:
				stage_text = "✓ " + stage_text
			elif not unlocked:
				stage_text = "锁 " + stage_text
			var stage_button := _button(
				stage_text,
				COLOR_PRIMARY if selected else (COLOR_PANEL_ALT if unlocked else COLOR_BG),
				Vector2(52, 52),
				12
			)
			stage_button.name = "StageButton_%d_%d" % [chapter_index + 1, stage_index + 1]
			stage_button.disabled = not unlocked
			stage_button.pressed.connect(func() -> void:
				selected_stage_id = stage_id
				_show_expedition()
			)
			chapter_row.add_child(stage_button)

	var detail := _panel(COLOR_PANEL, 10)
	detail.name = "ExpeditionDetailPanel"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.size_flags_stretch_ratio = 0.55
	body.add_child(detail)
	var detail_column := VBoxContainer.new()
	detail_column.add_theme_constant_override("separation", 6)
	detail.add_child(detail_column)
	var stage_config: Dictionary = StageCatalog.stage(selected_stage_id)
	detail_column.add_child(_label(String(stage_config.get("display_name", selected_stage_id)), 20, COLOR_TEXT))
	var chapter := int(stage_config.get("chapter", 1))
	var is_boss := int(stage_config.get("stage_in_chapter", 1)) == 5
	var threat_label := _label(
		_stage_text(stage_config, "threat_summary", _chapter_threat_text(chapter, is_boss)),
		13,
		COLOR_DANGER if is_boss else COLOR_MUTED
	)
	threat_label.name = "StageThreatSummary"
	detail_column.add_child(threat_label)
	var counter_label := _label(
		_stage_text(stage_config, "counter_hint", "反制：装甲顶线，火箭/双锯拆设施，维修保主力。"),
		12,
		COLOR_PRIMARY
	)
	counter_label.name = "StageCounterHint"
	detail_column.add_child(counter_label)
	var unlock_label := _label(
		_stage_text(stage_config, "unlock_preview", _unlock_preview_text(stage_config)),
		12,
		COLOR_ACCENT
	)
	unlock_label.name = "StageUnlockPreview"
	detail_column.add_child(unlock_label)
	var feedback_label := _label(
		_stage_text(stage_config, "chapter_feedback", "章节反馈：根据战斗结果回到工厂或培育补强，再沿城市大道推进。"),
		12,
		COLOR_MUTED
	)
	feedback_label.name = "StageChapterFeedback"
	detail_column.add_child(feedback_label)
	var rewards: Dictionary = StageCatalog.reward_for(selected_stage_id, "victory")
	detail_column.add_child(_label(
		"胜利：金%d · 书%d · 瓷%d · 零%d · 泥%d" % [
			int(rewards.get("gold", 0)),
			int(rewards.get("xp_books", 0)),
			int(rewards.get("porcelain", 0)),
			int(rewards.get("parts", 0)),
			int(rewards.get("sludge", 0)),
		],
		12,
		COLOR_ACCENT
	))
	detail_column.add_child(_label("路线：城市外围 → 火力封锁区 → 基地广场", 12, COLOR_MUTED))
	detail_column.add_child(_label("自动推进和索敌；点击技能，或为单个角色开启自动技能。", 12, COLOR_PRIMARY))
	detail_column.add_child(HSeparator.new())
	detail_column.add_child(_label("出征六人", 15, COLOR_PRIMARY))
	var squad_grid := GridContainer.new()
	squad_grid.columns = 2
	squad_grid.add_theme_constant_override("h_separation", 8)
	squad_grid.add_theme_constant_override("v_separation", 4)
	detail_column.add_child(squad_grid)
	var ids: Array[String] = state.formation.hero_ids()
	for index in 6:
		var hero: RefCounted = state.hero_by_id(ids[index])
		var hero_label := _label("%s  %s L%d ★%d" % [SLOT_NAMES[index], _archetype_name(hero.archetype_id), hero.level, hero.star], 11, COLOR_TEXT)
		hero_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		squad_grid.add_child(hero_label)
	var start := _button("开始攻城", COLOR_DANGER if is_boss else COLOR_PRIMARY, Vector2(190, 50), 16)
	start.name = "StartBattleButton"
	start.pressed.connect(_start_battle)
	detail_column.add_child(start)
	start.grab_focus()


func _stage_is_unlocked(stage_id: String, state: RefCounted) -> bool:
	var all_ids := StageCatalog.all_stage_ids()
	var target_index := all_ids.find(stage_id)
	var highest_id := String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	var highest_index := all_ids.find(highest_id)
	return target_index >= 0 and target_index <= maxi(0, highest_index)


func _chapter_threat_text(chapter: int, is_boss: bool) -> String:
	var threats := {
		1: "Cameramen 火力线：标记、盾卫与炮塔",
		2: "Speakermen 封锁线：冲锋、震荡与能量干扰",
		3: "TV Men 黑屏城区：传送、控制与周期护盾",
		4: "三军联合防线：防空、净化与协同火控",
		5: "联盟中央基地：持续轰炸与综合机制验收",
	}
	var text := String(threats.get(chapter, "联盟城市防线"))
	return ("BOSS · " if is_boss else "") + text


func _stage_text(stage_config: Dictionary, key: String, fallback: String) -> String:
	var value := String(stage_config.get(key, ""))
	return fallback if value.is_empty() else value


func _unlock_preview_text(stage_config: Dictionary) -> String:
	var unlocks: Array = stage_config.get("unlock_on_victory", [])
	if unlocks.is_empty():
		return "蓝图预览：本关主要提供资源与下一段路线进度。"
	return "蓝图预览：%s" % _blueprint_usage_text(unlocks)


func _blueprint_usage_text(recipe_ids: Array) -> String:
	var parts: Array[String] = []
	for recipe_value in recipe_ids:
		var recipe_id := String(recipe_value)
		match recipe_id:
			"heavy.armored":
				parts.append("装甲冲城用于顶住第一轮火力并提供三合一材料")
			"flying.rocket":
				parts.append("火箭飞行用于远程拆炮塔")
			"flying.bomber":
				parts.append("自爆飞行用于爆发破门")
			"heavy.saw":
				parts.append("双锯重装用于斩杀精英守军")
			"special.repair":
				parts.append("维修单位用于长线续航")
			"special.parasite":
				parts.append("寄生母体用于召唤和干扰核心守军")
			_:
				parts.append(recipe_id)
	return "；".join(parts)


func _start_battle() -> void:
	app_state = AppState.BATTLE
	_clear_ui()
	_clear_world()
	battle_id = "%s-%d-%d" % [selected_stage_id, int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	battle_elapsed = 0.0
	battle_snapshot_elapsed = 0.0
	battle_is_paused = false
	battle_world = BattleWorldScript.new()
	world_host.add_child(battle_world)
	battle_world.battle_finished.connect(_on_battle_finished)
	if battle_world.has_method("configure_presentation"):
		battle_world.configure_presentation(settings_store.effects_quality, settings_store.reduced_motion)
	var snapshots: Array[Dictionary] = _build_battle_snapshots()
	battle_world.start_battle(snapshots, selected_stage_id, StageCatalog.stage(selected_stage_id))
	_apply_global_auto_skill_to_battle(snapshots)
	_build_battle_hud()
	_update_battle_hud()


func _build_battle_hud() -> void:
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	battle_pause_button = _button("暂停", COLOR_PANEL_ALT, Vector2(72, 40), 14)
	battle_pause_button.pressed.connect(_toggle_battle_pause)
	top.add_child(battle_pause_button)
	var stage := _panel(Color(0.055, 0.09, 0.14, 0.88), 8)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stage)
	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 8)
	stage.add_child(stage_row)
	battle_stage_label = _label("阶段", 16, COLOR_TEXT)
	battle_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_stage_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	battle_stage_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stage_row.add_child(battle_stage_label)
	battle_progress_label = _label("进度 0/1000", 14, COLOR_PRIMARY)
	battle_progress_label.custom_minimum_size.x = 130
	battle_progress_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stage_row.add_child(battle_progress_label)
	battle_timer_label = _label("00:00", 14, COLOR_ACCENT)
	battle_timer_label.custom_minimum_size.x = 70
	battle_timer_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stage_row.add_child(battle_timer_label)
	battle_warning_label = _label("无炮击预警", 14, COLOR_MUTED)
	battle_warning_label.name = "CannonSuppressionLabel"
	battle_warning_label.custom_minimum_size.x = 170
	battle_warning_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	battle_warning_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	battle_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(battle_warning_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var bottom := _panel(Color(0.055, 0.09, 0.14, 0.84), 8)
	bottom.name = "BattleBottomHud"
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(bottom)
	battle_skill_rows = VBoxContainer.new()
	battle_skill_rows.add_theme_constant_override("separation", 4)
	battle_skill_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(battle_skill_rows)


func _update_battle_hud() -> void:
	if battle_world == null or not battle_world.has_method("get_battle_snapshot"):
		return
	var snapshot: Dictionary = battle_world.get_battle_snapshot()
	if snapshot.is_empty():
		return
	battle_timer_label.text = "%02d:%02d" % [int(battle_elapsed) / 60, int(battle_elapsed) % 60]
	battle_stage_label.text = "阶段 %d/3  %s" % [int(snapshot.get("stage_index", 0)) + 1, snapshot.get("stage_name", "")]
	battle_progress_label.text = "推进 %d/1000" % int(snapshot.get("road_progress", 0))
	_apply_cannon_suppression_hud(snapshot)
	if battle_pause_button != null:
		battle_pause_button.text = "继续" if battle_is_paused else "暂停"
	_rebuild_skill_hud(snapshot)


func _apply_cannon_suppression_hud(snapshot: Dictionary) -> void:
	if battle_warning_label == null:
		return
	var warnings: Array = snapshot.get("warnings", [])
	var suppression_warning := _suppression_warning(warnings)
	if not suppression_warning.is_empty():
		var current := _warning_int(suppression_warning, ["current", "suppression_current", "suppression"], 0)
		var target := _warning_int(suppression_warning, ["target", "suppression_target"], maxi(1, current))
		var seconds := _warning_seconds_to_impact(suppression_warning, int(snapshot.get("tick", 0)))
		battle_warning_label.text = "巨炮压制 %d/%d · %.1f秒" % [current, maxi(1, target), seconds]
		battle_warning_label.add_theme_color_override("font_color", COLOR_DANGER if seconds <= 2.0 or current >= target else COLOR_ACCENT)
		return
	if warnings.is_empty():
		battle_warning_label.text = "巨炮待机" if _snapshot_is_boss_cannon(snapshot) else "无炮击预警"
		battle_warning_label.add_theme_color_override("font_color", COLOR_MUTED)
		return
	battle_warning_label.text = "炮击预警 %d" % warnings.size()
	battle_warning_label.add_theme_color_override("font_color", COLOR_ACCENT)


func _suppression_warning(warnings: Array) -> Dictionary:
	for warning_value in warnings:
		if typeof(warning_value) != TYPE_DICTIONARY:
			continue
		var warning := warning_value as Dictionary
		if bool(warning.get("suppression", false)) or warning.has("suppression_current") or warning.has("suppression_target"):
			return warning
	return {}


func _warning_int(warning: Dictionary, keys: Array[String], fallback: int) -> int:
	for key in keys:
		if not warning.has(key):
			continue
		var value = warning[key]
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			return int(value)
		if typeof(value) == TYPE_DICTIONARY:
			var nested := value as Dictionary
			if nested.has("current"):
				return int(nested["current"])
	return fallback


func _warning_seconds_to_impact(warning: Dictionary, snapshot_tick: int = 0) -> float:
	var tick := int(warning.get("tick", snapshot_tick))
	var impact_tick := int(warning.get("impact_tick", tick))
	return maxf(0.0, float(impact_tick - tick) / 5.0)


func _snapshot_is_boss_cannon(snapshot: Dictionary) -> bool:
	if bool(snapshot.get("is_boss", false)):
		return true
	var stage_id := String(snapshot.get("stage_id", selected_stage_id))
	if not StageCatalog.has_stage(stage_id):
		return false
	return int(StageCatalog.stage(stage_id).get("stage_in_chapter", 0)) == 5


func _toggle_battle_pause() -> void:
	if battle_world == null:
		return
	_set_battle_paused(not battle_is_paused)
	_update_battle_hud()


func _set_battle_paused(value: bool) -> void:
	if battle_world == null:
		return
	battle_is_paused = value
	if battle_world.has_method("set_paused"):
		battle_world.set_paused(battle_is_paused)


func _rebuild_skill_hud(snapshot: Dictionary) -> void:
	for child in battle_skill_rows.get_children():
		child.queue_free()
	var grid := GridContainer.new()
	grid.name = "BattleSkillGrid"
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	battle_skill_rows.add_child(grid)
	var units: Array[Dictionary] = []
	for unit_value in snapshot.get("units", []):
		var unit := unit_value as Dictionary
		if int(unit.get("team", 0)) == 0 and not bool(unit.get("temporary", false)) and int(unit.get("slot", 99)) < 6:
			units.append(unit)
	units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["slot"]) < int(b["slot"]))
	for unit in units:
		grid.add_child(_battle_unit_control(unit))


func _battle_unit_control(unit: Dictionary) -> Control:
	var card := _panel(COLOR_PANEL, 5)
	card.custom_minimum_size = Vector2(190, 96)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(row)
	var hp := _label("%s %d/%d E%d" % [
		SLOT_NAMES[int(unit["slot"])],
		int(unit["hp"]),
		int(unit["max_hp"]),
		int(unit["energy"]),
	], 11, COLOR_TEXT if bool(unit["alive"]) else COLOR_DANGER)
	hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp.autowrap_mode = TextServer.AUTOWRAP_OFF
	hp.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(hp)
	var skill_name := _label(_skill_short(String(unit["skill_id"])), 11, COLOR_MUTED)
	skill_name.custom_minimum_size.x = 34
	skill_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	skill_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(skill_name)
	var unit_id := StringName(unit["unit_id"])
	var skill := _button("技", COLOR_PRIMARY, Vector2(52, 52), 12)
	skill.name = "SkillButton"
	skill.disabled = int(unit["energy"]) < 100 or not bool(unit["alive"])
	skill.pressed.connect(func() -> void:
		if battle_world != null:
			battle_world.request_skill(unit_id)
			_update_battle_hud()
	)
	row.add_child(skill)
	var auto := CheckButton.new()
	auto.name = "AutoSkillToggle"
	auto.text = ""
	auto.button_pressed = bool(unit.get("auto_skill", false))
	auto.custom_minimum_size = Vector2(52, 52) * UI_SCALE
	auto.add_theme_font_size_override("font_size", int(12 * UI_SCALE))
	auto.toggled.connect(func(enabled: bool) -> void:
		var result := _execute_command("set_auto_skill_preference", {"hero_id": String(unit_id), "enabled": enabled}, "")
		if bool(result.get("ok", false)):
			if battle_world != null:
				battle_world.set_auto_skill(unit_id, enabled)
			_update_battle_hud()
		else:
			auto.set_pressed_no_signal(not enabled)
			_show_notice("自动技能偏好保存失败：%s" % result.get("error", "UNKNOWN"))
	)
	row.add_child(auto)
	return card


func _on_battle_finished(result: Dictionary) -> void:
	var outcome := String(result.get("outcome", "defeat"))
	var stage_id := String(result.get("stage_id", selected_stage_id))
	var max_ticks := int(StageCatalog.stage(stage_id).get("max_ticks", 300))
	var ticks := clampi(int(result.get("ticks", 1)), 1, max_ticks)
	var settlement := _execute_command(
		"settle_battle",
		{"battle_id": battle_id, "stage_id": stage_id, "outcome": outcome, "ticks": ticks},
		"battle:%s" % battle_id
	)
	if not bool(settlement.get("ok", false)):
		_show_result(result, {}, "结算保存失败：%s" % settlement.get("error", "UNKNOWN"))
		return
	_show_result(result, settlement.get("event", {}) as Dictionary)


func _show_result(result: Dictionary, settlement: Dictionary, error_message: String = "") -> void:
	app_state = AppState.RESULT
	_clear_ui()
	_add_background(Color(0.02, 0.04, 0.08, 0.72))
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(center)
	var panel := _panel(COLOR_PANEL, 14)
	panel.name = "ResultPanel"
	panel.custom_minimum_size = Vector2(620, 290)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var outcome := String(result.get("outcome", "defeat"))
	var victory := outcome == "victory"
	var stage_id := String(settlement.get("stage_id", result.get("stage_id", selected_stage_id)))
	var stage_config := StageCatalog.stage(stage_id)
	column.add_child(_label("目标已摧毁" if victory else "攻城失败", 28, COLOR_ACCENT if victory else COLOR_DANGER))
	column.add_child(_label(String(stage_config.get("display_name", stage_id)), 15, COLOR_MUTED))
	var report_title := _label("战术战报", 18, COLOR_PRIMARY)
	report_title.name = "ResultReportTitle"
	column.add_child(report_title)
	var cannon_report := _label(_cannon_result_report_text(result, settlement), 13, COLOR_ACCENT)
	cannon_report.name = "ResultCannonReportLabel"
	column.add_child(cannon_report)
	var reason := String(result.get("reason", ""))
	var reason_text: String = String({
		"core_destroyed": "联盟核心已经坍塌",
		"main_squad_defeated": "六名主力全部阵亡",
		"timeout": "60 秒内攻城输出不足",
		"invalid_formation": "出征编队不足六人",
	}.get(reason, reason))
	column.add_child(_label(
		"到达阶段 %d/3 · 摧毁结构 %d · %s" % [
			clampi(int(result.get("stage_reached", 0)) + 1, 1, 3),
			int(result.get("structures_destroyed", 0)),
			reason_text,
		],
		14,
		COLOR_TEXT
	))
	var reward: Dictionary = settlement.get("reward", {}) as Dictionary
	column.add_child(_label(
		"奖励：金币%d 书%d 瓷%d 零%d 泥%d" % [
			int(reward.get("gold", 0)),
			int(reward.get("xp_books", 0)),
			int(reward.get("porcelain", 0)),
			int(reward.get("parts", 0)),
			int(reward.get("sludge", 0)),
		],
		17,
		COLOR_PRIMARY if victory else COLOR_MUTED
	))
	if not victory:
		var recommended_action := _derive_next_action(game.current_state())
		column.add_child(_label(_failure_advice(result, recommended_action), 13, COLOR_ACCENT))
	else:
		var salvage_label := _label("本次残骸：+%d" % _salvage_reward_from_settlement(settlement), 13, COLOR_ACCENT)
		salvage_label.name = "ResultSalvageLabel"
		column.add_child(salvage_label)
	if victory and stage_id == "stage_5_5":
		column.add_child(_label("伪胜警报：联盟主力正在沿大道反推。科学家已启动核心数据库撤离协议……", 14, COLOR_DANGER))
		column.add_child(_label("第一幕完成。永久角色、星级与关键蓝图已安全转移；工厂毁灭将开启下一幕。", 13, COLOR_TEXT))
	elif victory:
		var next_stage := String(settlement.get("next_stage_id", StageCatalog.next_stage_id(stage_id)))
		if not next_stage.is_empty():
			var next_config := StageCatalog.stage(next_stage)
			column.add_child(_label("下一目标已开放：%s" % String(next_config.get("display_name", next_stage)), 13, COLOR_PRIMARY))
			column.add_child(_label("威胁预告：%s" % _stage_text(next_config, "threat_summary", _chapter_threat_text(int(next_config.get("chapter", 1)), int(next_config.get("stage_in_chapter", 1)) == 5)), 12, COLOR_MUTED))
	var unlocked: Array = settlement.get("unlocked_blueprints", [])
	if victory and not unlocked.is_empty():
		column.add_child(_label("本次蓝图用途：%s" % _blueprint_usage_text(unlocked), 12, COLOR_ACCENT))
	if not error_message.is_empty():
		column.add_child(_label(error_message, 14, COLOR_DANGER))
	_build_result_actions(column, victory)


func _build_result_actions(column: VBoxContainer, victory: bool) -> void:
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	if victory:
		var next_action := _derive_next_action(game.current_state())
		var next := _button(String(next_action.get("cta_label", "继续")), COLOR_PRIMARY, Vector2(130, 44), 14)
		next.name = "ResultRecommendedButton"
		next.pressed.connect(func() -> void: _navigate_objective_action(next_action))
		actions.add_child(next)
	else:
		var recommended_action := _derive_next_action(game.current_state())
		var recommended := _button(String(recommended_action.get("cta_label", "继续")), COLOR_PRIMARY, Vector2(150, 44), 14)
		recommended.name = "ResultRecommendedButton"
		recommended.pressed.connect(func() -> void: _navigate_objective_action(recommended_action))
		actions.add_child(recommended)
	var camp := _button("营地", COLOR_PANEL_ALT, Vector2(90, 44), 14)
	camp.name = "ResultCampButton"
	camp.pressed.connect(_show_camp)
	actions.add_child(camp)


func _failure_advice(result: Dictionary, action: Dictionary = {}) -> String:
	var reason := String(result.get("reason", ""))
	var stage_reached := int(result.get("stage_reached", 0))
	var next_text := "推荐：%s。" % String(action.get("title", "回营地调整"))
	if reason == "timeout":
		return "诊断：输出不足。%s" % next_text
	if stage_reached <= 0:
		return "诊断：前排过早崩溃。%s" % next_text
	if stage_reached == 1:
		return "诊断：火力封锁未突破。%s" % next_text
	return "诊断：基地炮击压垮队伍。%s" % next_text


func _salvage_reward_from_settlement(settlement: Dictionary) -> int:
	var reward := settlement.get("reward", {}) as Dictionary
	if reward.has("salvage"):
		return int(reward["salvage"])
	if settlement.has("salvage"):
		return int(settlement["salvage"])
	if settlement.has("salvage_delta"):
		return int(settlement["salvage_delta"])
	if settlement.has("alliance_scrap_granted"):
		return int(settlement["alliance_scrap_granted"])
	return 0


func _cannon_result_report_text(result: Dictionary, settlement: Dictionary) -> String:
	var suppressed := _first_int_value([result, settlement], ["cannon_suppression_count", "cannon_suppressed_count", "suppression_count", "boss_suppression_count"])
	var hits := _first_int_value([result, settlement], ["cannon_hit_count", "cannon_hits", "bombardment_hits", "boss_cannon_hits"])
	return "本局压制巨炮 %d 次 / 炮击命中 %d 次" % [suppressed, hits]


func _first_int_value(sources: Array[Dictionary], keys: Array[String]) -> int:
	for source in sources:
		for key in keys:
			if source.has(key):
				return int(source[key])
	return 0


func _build_battle_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	var state: RefCounted = game.current_state()
	var hero_ids: Array[String] = state.formation.hero_ids()
	for slot_index in 6:
		var hero_id: String = hero_ids[slot_index]
		var hero: RefCounted = state.hero_by_id(hero_id)
		var stats: Dictionary = HeroProgression.derived_battle_stats(hero)
		var skill_id := FactoryCatalog.active_skill_for_archetype(hero.archetype_id)
		snapshots.append({
			"hero_id": hero.hero_id,
			"display_name": hero.display_name,
			"archetype_id": hero.archetype_id,
			"class_id": hero.class_id,
			"star": hero.star,
			"max_hp": int(stats["max_hp"]),
			"attack": maxi(int(stats["physical_atk"]), int(stats["magic_atk"])),
			"defense": int(stats["defense"]),
			"slot": slot_index,
			"skill_id": skill_id,
			"auto_skill": bool(hero.auto_skill_enabled) or bool(settings_store.global_auto_skill),
		})
	return snapshots


func _apply_global_auto_skill_to_battle(snapshots: Array[Dictionary]) -> void:
	if battle_world == null:
		return
	for snapshot in snapshots:
		var enabled := bool(snapshot.get("auto_skill", false))
		if settings_store.global_auto_skill:
			enabled = true
		if enabled and battle_world.has_method("set_auto_skill"):
			battle_world.set_auto_skill(StringName(String(snapshot["hero_id"])), true)


func _execute_command(command_type: String, payload: Dictionary, business_key: String) -> Dictionary:
	command_serial += 1
	var now := Time.get_ticks_msec()
	var command_id := "%s-%d-%d" % [command_type, now, command_serial]
	var key := business_key if not business_key.is_empty() else command_id
	return game.execute_command({
		"command_id": command_id,
		"type": command_type,
		"payload": payload,
		"business_key": key,
		"expected_revision": game.current_state().revision,
		"requested_at": int(Time.get_unix_time_from_system()),
	})


func _show_management_shell(title_text: String, body: Control) -> void:
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	root.add_child(_build_top_bar())
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)
	var title := _label(title_text, 24, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := _button("返回营地", COLOR_PANEL_ALT, Vector2(110, 50), 14)
	back.name = "ManagementBackButton"
	back.pressed.connect(_show_camp)
	header.add_child(back)
	root.add_child(body)


func _show_notice(message: String) -> void:
	var notice := Label.new()
	notice.text = message
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size", 15)
	notice.add_theme_color_override("font_color", Color("#ffcf70"))
	notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice.position = Vector2(-240, 56)
	notice.custom_minimum_size = Vector2(480, 32)
	ui_root.add_child(notice)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(notice, "modulate:a", 0.0, 0.4)
	tween.tween_callback(notice.queue_free)


func _build_camp_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101e31")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#91a8bf")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	world_host.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	world_host.add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(8, 6.5, 10)
	camera.look_at_from_position(camera.position, Vector3(0, 1.2, 0))
	camera.fov = 42
	camera.current = true
	world_host.add_child(camera)
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(22, 16)
	floor.mesh = floor_mesh
	floor.material_override = _material(Color("#24364b"), 0.9)
	world_host.add_child(floor)
	for index in 7:
		var block := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.6 + index * 0.25, 1.5 + index * 0.5, 1.8)
		block.mesh = mesh
		block.position = Vector3(-7.5 + index * 2.5, mesh.size.y * 0.5, -3.5)
		block.material_override = _material(Color("#30475e").lightened(index * 0.025), 0.85)
		world_host.add_child(block)
	for lane in [-1, 1]:
		var strip := MeshInstance3D.new()
		var strip_mesh := BoxMesh.new()
		strip_mesh.size = Vector3(0.12, 0.02, 12)
		strip.mesh = strip_mesh
		strip.position = Vector3(lane * 2.4, 0.02, 0)
		strip.material_override = _material(Color("#dfc16e"), 0.8)
		world_host.add_child(strip)


func _build_factory_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101825")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#91a8bf")
	environment.ambient_light_energy = 0.78
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	world_host.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -28, 0)
	sun.light_energy = 1.05
	world_host.add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(8.5, 5.8, 9.5)
	camera.look_at_from_position(camera.position, Vector3(0, 1.0, -0.6))
	camera.fov = 43
	camera.current = true
	world_host.add_child(camera)
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(24, 14)
	floor.mesh = floor_mesh
	floor.material_override = _material(Color("#1f2c3a"), 0.88)
	world_host.add_child(floor)
	var workshop_colors := [Color("#2f6f7b"), Color("#594a7a"), Color("#6a5840"), Color("#4d704c")]
	for index in 4:
		var line := MeshInstance3D.new()
		line.name = "FactoryLine_%d" % index
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(4.4, 0.35, 1.1)
		line.mesh = line_mesh
		line.position = Vector3(-5.7 + float(index) * 3.8, 0.18, -1.2)
		line.material_override = _material(workshop_colors[index], 0.62)
		world_host.add_child(line)
		var machine := MeshInstance3D.new()
		machine.name = "FactoryMachine_%d" % index
		var machine_mesh := CylinderMesh.new()
		machine_mesh.top_radius = 0.55
		machine_mesh.bottom_radius = 0.75
		machine_mesh.height = 1.8
		machine_mesh.radial_segments = 10
		machine.mesh = machine_mesh
		machine.position = line.position + Vector3(0.0, 1.08, -0.1)
		machine.material_override = _material(workshop_colors[index].lightened(0.2), 0.5)
		world_host.add_child(machine)
		var door := MeshInstance3D.new()
		door.name = "FactoryDoor_%d" % index
		var door_mesh := BoxMesh.new()
		door_mesh.size = Vector3(0.9, 1.0, 0.14)
		door.mesh = door_mesh
		door.position = line.position + Vector3(0.0, 0.78, 0.74)
		door.material_override = _material(Color("#d9e8ed"), 0.54)
		world_host.add_child(door)


func _play_factory_start_feedback(recipe_id: String) -> void:
	_show_notice("设备启动：%s 正在生产。" % String(FactoryCatalog.recipe(recipe_id).get("display_name", recipe_id)))
	var machine := world_host.get_node_or_null("FactoryMachine_%d" % _workshop_index(String(FactoryCatalog.recipe(recipe_id).get("workshop", "ordinary")))) as Node3D
	if machine == null:
		return
	var tween := machine.create_tween()
	tween.tween_property(machine, "scale", Vector3(1.18, 0.86, 1.18), 0.12)
	tween.tween_property(machine, "scale", Vector3.ONE, 0.18)


func _play_factory_claim_feedback(hero_id: String, recipe_id: String) -> void:
	var recipe := FactoryCatalog.recipe(recipe_id)
	_show_notice("仓门开启：%s 入列，%s ★1。" % [String(recipe.get("display_name", hero_id)), String(recipe.get("rarity", ""))])
	var workshop := String(recipe.get("workshop", "ordinary"))
	var door := world_host.get_node_or_null("FactoryDoor_%d" % _workshop_index(workshop)) as Node3D
	if door != null:
		var tween := door.create_tween()
		tween.tween_property(door, "position:y", door.position.y + 0.75, 0.18)
		tween.tween_property(door, "position:y", door.position.y, 0.26)
	var reveal := MeshInstance3D.new()
	reveal.name = "FactoryReveal"
	var mesh := SphereMesh.new()
	mesh.radius = 0.32
	mesh.height = 0.64
	mesh.radial_segments = 10
	mesh.rings = 5
	reveal.mesh = mesh
	reveal.position = Vector3(-5.7 + float(_workshop_index(workshop)) * 3.8, 1.15, 0.15)
	reveal.material_override = _material(Color("#ffe082"), 0.5)
	world_host.add_child(reveal)
	var appear := reveal.create_tween()
	reveal.scale = Vector3(0.2, 0.2, 0.2)
	appear.tween_property(reveal, "scale", Vector3(1.35, 1.35, 1.35), 0.22)
	appear.tween_property(reveal, "transparency", 1.0, 0.5)
	appear.tween_callback(reveal.queue_free)


func _clear_ui() -> void:
	battle_timer_label = null
	battle_stage_label = null
	battle_warning_label = null
	battle_progress_label = null
	battle_skill_rows = null
	status_label = null
	for child in ui_root.get_children():
		child.queue_free()


func _clear_world() -> void:
	battle_world = null
	for child in world_host.get_children():
		child.queue_free()


func _add_background(color: Color) -> void:
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(background)


func _safe_margin() -> MarginContainer:
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", int(14 * UI_SCALE))
	safe.add_theme_constant_override("margin_right", int(14 * UI_SCALE))
	safe.add_theme_constant_override("margin_top", int(10 * UI_SCALE))
	safe.add_theme_constant_override("margin_bottom", int(10 * UI_SCALE))
	return safe


func _panel(color: Color, padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	var scaled_padding := int(padding * UI_SCALE)
	style.content_margin_left = scaled_padding
	style.content_margin_right = scaled_padding
	style.content_margin_top = scaled_padding
	style.content_margin_bottom = scaled_padding
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(color, 1.0).lightened(0.15)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _button(text: String, color: Color, min_size: Vector2 = Vector2(120, 48), font_size: int = 16) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size * UI_SCALE
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.darkened(0.35) if state_name == "disabled" else color.lightened(0.10 if state_name == "hover" else (-0.08 if state_name == "pressed" else 0.0))
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.content_margin_left = int(8 * UI_SCALE)
		style.content_margin_right = int(8 * UI_SCALE)
		style.content_margin_top = int(6 * UI_SCALE)
		style.content_margin_bottom = int(6 * UI_SCALE)
		if state_name == "focus":
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = COLOR_TEXT
		button.add_theme_stylebox_override(state_name, style)
	button.add_theme_font_size_override("font_size", int(font_size * UI_SCALE))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(size * UI_SCALE))
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _resource_chip(name_text: String, value: String, color: Color) -> Control:
	var chip := _panel(COLOR_PANEL_ALT, 5)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	chip.add_child(row)
	row.add_child(_label(name_text, 12, COLOR_MUTED))
	row.add_child(_label(value, 14, color))
	return chip


func _build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = CJKFont
	theme.default_font_size = int(14 * UI_SCALE)
	return theme


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _class_name(class_id: String) -> String:
	return {
		"guardian": "重装",
		"fighter": "突击",
		"ranger": "远程",
		"arcanist": "能量",
	}.get(class_id, class_id)


func _merge_group_key(hero_id: String) -> String:
	var hero: RefCounted = game.current_state().hero_by_id(hero_id)
	if hero == null:
		return ""
	return "%s|%d" % [hero.archetype_id, hero.star]


func _archetype_name(archetype_id: String) -> String:
	return {
		"assault": "冲锋马桶人",
		"sonic": "音波马桶人",
		"rocket": "火箭飞行马桶人",
		"bomber": "自爆飞行马桶人",
		"armored": "装甲冲城马桶人",
		"saw": "双锯重装马桶人",
		"repair": "维修马桶人",
		"parasite": "寄生母体马桶人",
	}.get(archetype_id, archetype_id)


func _blueprint_hint(recipe_id: String) -> String:
	var rows: Array = FactoryService.blueprint_status(game.current_state()).filter(func(row: Dictionary) -> bool: return String(row["recipe_id"]) == recipe_id)
	if rows.is_empty():
		return "等待蓝图解锁"
	return String((rows[0] as Dictionary).get("unlock_hint", "等待蓝图解锁"))


func _workshop_index(workshop_id: String) -> int:
	return {
		"ordinary": 0,
		"flying": 1,
		"heavy": 2,
		"special": 3,
	}.get(workshop_id, 0)


func _skill_short(skill_id: String) -> String:
	return {
		"plunger_charge": "冲",
		"sonic_disruptor": "音",
		"rocket_salvo": "箭",
		"suicide_dive": "爆",
		"siege_shield": "盾",
		"saw_rush": "锯",
		"field_repair": "修",
		"parasite_swarm": "寄",
	}.get(skill_id, "技")


func _role_name(role_id: String) -> String:
	return {
		"frontline_breaker": "前线突破",
		"crowd_control": "群体控制",
		"siege_artillery": "远程攻城",
		"burst_sacrifice": "爆发突击",
		"siege_tank": "攻城承伤",
		"elite_duelist": "精英斩杀",
		"sustain_support": "持续修复",
		"summoner_debuffer": "召唤干扰",
	}.get(role_id, role_id)

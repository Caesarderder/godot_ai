extends Node

const FactoryCatalog := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const ActiveSkillCatalog := preload("res://game/scripts/content/active_skill_catalog.gd")
const FactoryService := preload("res://game/scripts/domain/factory/factory_service.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const CombatPower := preload("res://game/scripts/domain/progression/combat_power.gd")
const GrowthPlan := preload("res://game/scripts/domain/progression/growth_plan.gd")
const EconomyValuation := preload("res://game/scripts/domain/economy/economy_valuation.gd")
const GoldShopCatalog := preload("res://game/scripts/domain/economy/gold_shop_catalog.gd")
const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")
const QuestCatalog := preload("res://game/scripts/domain/quest/quest_catalog.gd")
const WarMeritTrack := preload("res://game/scripts/domain/quest/war_merit_track.gd")
const BattleWorldScript := preload("res://game/scripts/presentation_3d/battle_world.gd")
const SettingsStoreScript := preload("res://game/scripts/platform/settings_store.gd")
const WebRuntimeScript := preload("res://game/scripts/platform/web_runtime.gd")
const NotificationSummaryScript := preload("res://game/scripts/presentation/notification_summary.gd")
const NotificationBadgeScript := preload("res://game/scripts/presentation/notification_badge.gd")
const OnboardingService := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")
const CJKFont := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

enum AppState { BOOT, TITLE, CAMP, FACTORY, CULTIVATION, FORMATION, EXPEDITION, BATTLE, RESULT, SETTINGS, QUESTS, SHOP }

const ACHIEVEMENT_CATALOG_PATH := "res://game/scripts/domain/achievement/achievement_catalog.gd"

const COLOR_BG := Color("#09111d")
const COLOR_PANEL := Color("#132238")
const COLOR_PANEL_ALT := Color("#1b3049")
const COLOR_PRIMARY := Color("#35d0ba")
const COLOR_ACCENT := Color("#f6bd55")
const COLOR_TEXT := Color("#f5f8fc")
const COLOR_MUTED := Color("#93a7be")
const COLOR_DANGER := Color("#ff665f")
const COLOR_STROKE := Color("#34516d")
const UI_SCALE: float = 1.65
const SLOT_KEYS: Array[String] = ["commander", "troop_1", "troop_2", "troop_3", "troop_4", "troop_5"]
const SLOT_NAMES: Array[String] = ["前排1", "前排2", "前排3", "后排1", "后排2", "后排3"]
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
	{"quest_id": "loop_training", "generation": 1, "scope": "loop", "title": "升级型号", "description": "完成一次型号科技升星。", "progress": 0, "target": 1, "reward_text": "战功 +6"},
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
var notification_refresh_elapsed: float = 0.0
var factory_order_views: Array[Dictionary] = []
var factory_research_view: Dictionary = {}
var battle_timer_label: Label
var battle_stage_label: Label
var battle_power_label: Label
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
var reveal_all_camp_systems: bool = false
var local_save_delete_armed: bool = false


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
	if app_state == AppState.CAMP:
		notification_refresh_elapsed += delta
		if notification_refresh_elapsed >= 0.5:
			notification_refresh_elapsed = 0.0
			_refresh_visible_notification_badges()
		return
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
	panel.custom_minimum_size = Vector2(500, 210)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := _label("马桶人工厂攻城", 34, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(title)
	var subtitle := _label("Gman 单人开局，夺取图纸，让马桶博士扩建军团。", 16, COLOR_MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var is_fresh_campaign: bool = game.current_state().attempt_counters.is_empty() and (game.current_state().stage_progress.get("cleared_stages", []) as Array).is_empty()
	var button := _button("进入工厂" if is_fresh_campaign else "继续战争", COLOR_PRIMARY, Vector2(210, 54), 19)
	button.name = "TitlePrimaryButton"
	button.pressed.connect(_start_from_title)
	column.add_child(button)
	var settings_button := _button("设置", COLOR_PANEL_ALT, Vector2(210, 46), 16)
	settings_button.name = "TitleSettingsButton"
	settings_button.pressed.connect(func() -> void: _show_settings(AppState.TITLE))
	column.add_child(settings_button)
	button.grab_focus()


func _start_from_title() -> void:
	var state: RefCounted = game.current_state()
	var is_fresh_campaign: bool = state.attempt_counters.is_empty() and (state.stage_progress.get("cleared_stages", []) as Array).is_empty()
	_show_camp()


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
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var objective := _accent_panel(Color(0.045, 0.08, 0.13, 0.96), COLOR_PRIMARY, 16)
	objective.name = "CampObjectivePanel"
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	objective.size_flags_stretch_ratio = 0.68
	objective.custom_minimum_size.y = 430
	body.add_child(objective)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 10)
	objective.add_child(copy)
	var tutorial := OnboardingService.snapshot(game.current_state())
	var objective_action := _derive_next_action(game.current_state())
	var notifications := _notification_summary()
	var objective_eyebrow := _label("新兵任务 %d/%d" % [int(tutorial["step"]), int(tutorial["total"])], 13, COLOR_PRIMARY)
	objective_eyebrow.name = "TutorialStepLabel"
	copy.add_child(objective_eyebrow)
	var tutorial_progress := _progress_bar(float(tutorial["step"]), float(tutorial["total"]), COLOR_PRIMARY, 8)
	tutorial_progress.name = "TutorialProgressBar"
	copy.add_child(tutorial_progress)
	var objective_title := _label(String(tutorial["title"]), 26, COLOR_TEXT)
	objective_title.name = "ObjectiveTitle"
	copy.add_child(objective_title)
	var tutorial_hint := _label(String(tutorial["lesson"]), 16, COLOR_ACCENT)
	tutorial_hint.name = "TutorialHintLabel"
	copy.add_child(tutorial_hint)
	var objective_button := _button(String(tutorial["cta_label"]), COLOR_PRIMARY, Vector2(180, 50), 16)
	objective_button.name = "CampObjectiveButton"
	objective_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if bool(tutorial.get("completed", false)) and not bool(tutorial.get("claimed", false)):
		objective_button.pressed.connect(func() -> void: _claim_current_onboarding_task())
	else:
		objective_button.pressed.connect(func() -> void: _navigate_objective_action(tutorial))
	copy.add_child(objective_button)
	var system_column := VBoxContainer.new()
	system_column.add_theme_constant_override("separation", 7)
	system_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	system_column.size_flags_stretch_ratio = 0.32
	body.add_child(system_column)
	var system_title := _label("快捷入口" if not reveal_all_camp_systems else "全部入口", 13, COLOR_MUTED)
	system_column.add_child(system_title)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	system_column.add_child(actions)
	var current_target := String(tutorial.get("target", "expedition"))
	var tutorial_step := int(tutorial["step"])
	var factory := _button("工厂", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	factory.name = "CampFactoryButton"
	factory.pressed.connect(_show_factory)
	factory.visible = reveal_all_camp_systems or current_target == "factory"
	_attach_notification_badge(factory, int(notifications["factory_ready"]), "FactoryNotificationBadge")
	actions.add_child(factory)
	var cultivate := _button("型号科技", COLOR_PANEL_ALT, Vector2(138, 58), 17)
	cultivate.name = "CampCultivationButton"
	cultivate.pressed.connect(_show_cultivation)
	cultivate.visible = reveal_all_camp_systems or current_target == "cultivation"
	actions.add_child(cultivate)
	var formation := _button("编队", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	formation.name = "CampFormationButton"
	formation.pressed.connect(_show_formation)
	formation.visible = reveal_all_camp_systems or tutorial_step >= 2
	actions.add_child(formation)
	var quests := _button("目标", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	quests.name = "QuestEntryButton"
	quests.pressed.connect(_show_quests)
	quests.visible = reveal_all_camp_systems or tutorial_step >= 3
	_attach_notification_badge(quests, int(notifications["goal_claimable"]) + WarMeritTrack.claimable_count(game.current_state()), "GoalNotificationBadge")
	actions.add_child(quests)
	var shop := _button("图纸研发", COLOR_PANEL_ALT, Vector2(138, 58), 17)
	shop.name = "CampGoldShopButton"
	shop.pressed.connect(_show_factory)
	shop.visible = reveal_all_camp_systems or tutorial_step >= 2
	actions.add_child(shop)
	var expedition := _button("出征", COLOR_ACCENT, Vector2(138, 58), 19)
	expedition.name = "CampExpeditionButton"
	expedition.pressed.connect(_show_expedition)
	expedition.visible = reveal_all_camp_systems or current_target == "expedition"
	actions.add_child(expedition)
	var settings_button := _button("设置", COLOR_PANEL_ALT, Vector2(138, 58), 19)
	settings_button.name = "CampSettingsButton"
	settings_button.pressed.connect(func() -> void: _show_settings(AppState.CAMP))
	settings_button.visible = reveal_all_camp_systems
	actions.add_child(settings_button)
	var reveal := _button("收起" if reveal_all_camp_systems else "更多", COLOR_PANEL_ALT, Vector2(284, 46), 14)
	reveal.name = "CampRevealSystemsButton"
	reveal.pressed.connect(func() -> void:
		reveal_all_camp_systems = not reveal_all_camp_systems
		_show_camp()
	)
	system_column.add_child(reveal)


func _build_top_bar() -> Control:
	var panel := _panel(Color(0.035, 0.065, 0.105, 0.96), 9)
	panel.custom_minimum_size.y = 54
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var brand := _label("马桶军团营地", 21, COLOR_TEXT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand)
	var state: RefCounted = game.current_state()
	var power_summary := _power_summary(state)
	var power := _label(
		"战力 %d / 推荐 %d" % [
			int(power_summary["current"]),
			int(power_summary["recommended"]),
		],
		13,
		_readiness_color(String(power_summary["readiness"]))
	)
	power.name = "GlobalPowerSummaryLabel"
	power.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(power)
	var resources := _label(
		"金币 %d   技术 %d   陶%d 零%d 能%d" % [
			state.economy.toilet_coins,
			state.economy.industrial_tech,
			int(state.factory.materials.get("porcelain", 0)),
			int(state.factory.materials.get("parts", 0)),
			int(state.factory.materials.get("sludge", 0)),
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
	var delete_save := _button(
		"再次点击确认删除" if local_save_delete_armed else "删除本地存档",
		COLOR_DANGER,
		Vector2(190, 44),
		14
	)
	delete_save.name = "SettingsDeleteLocalSaveButton"
	delete_save.pressed.connect(_request_delete_local_save)
	actions.add_child(delete_save)
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


func _request_delete_local_save() -> void:
	if not local_save_delete_armed:
		local_save_delete_armed = true
		_show_settings(settings_return_state)
		return
	local_save_delete_armed = false
	var save_manager := get_node_or_null("/root/SaveManager")
	var result: Dictionary = game.reset_local_save(save_manager, 20260723, int(Time.get_unix_time_from_system()))
	if not bool(result.get("ok", false)):
		_show_notice("删除存档失败：%s" % String(result.get("error", "UNKNOWN")))
		return
	selected_stage_id = StageCatalog.DEFAULT_STAGE_ID
	selected_formation_slot = 0
	selected_merge_ids.clear()
	_show_notice("本地存档已删除，已创建全新进度。")
	_show_title()


func _return_from_settings() -> void:
	local_save_delete_armed = false
	if settings_return_state == AppState.TITLE:
		_show_title()
	else:
		_show_camp()


func _derive_next_action(state: RefCounted, now_unix: int = -1) -> Dictionary:
	var onboarding := OnboardingService.snapshot(state)
	if not bool(onboarding.get("finished", false)):
		return onboarding
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	if int(state.schema_version) >= 6:
		return _derive_factory_loop_action(state, now)
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
			"body": "先让 Gman 独自摧毁无防备城市。前三关不开放工厂，第 4 关遇到联盟炮台后再寻找扩军方案。",
			"cta_label": "去侦察",
			"target": "expedition",
			"stage_id": StageCatalog.DEFAULT_STAGE_ID,
		}
	if not state.factory.blueprint_research.is_empty():
		var research_recipe_id := String(state.factory.blueprint_research.get("recipe_id", ""))
		var research_recipe := FactoryCatalog.recipe(research_recipe_id)
		var research_ready := now >= int(state.factory.blueprint_research.get("completes_at_unix", 0))
		return {
			"title": "领取研究图纸" if research_ready else "等待马桶博士研究",
			"body": "%s已经研究完成。" % String(research_recipe.get("display_name", research_recipe_id)) if research_ready else "马桶博士正在破解%s图纸，研究结束后才能投入生产。" % String(research_recipe.get("display_name", research_recipe_id)),
			"cta_label": "去博士工厂",
			"target": "factory",
			"stage_id": highest_stage,
		}
	for recipe_value in state.factory.discovered_blueprints.keys():
		var discovered_recipe_id := String(recipe_value)
		if not bool(state.factory.discovered_blueprints.get(discovered_recipe_id, false)):
			continue
		var discovered_recipe := FactoryCatalog.recipe(discovered_recipe_id)
		return {
			"title": "研究%s图纸" % String(discovered_recipe.get("display_name", discovered_recipe_id)),
			"body": "图纸已经带回营地。交给马桶博士研究，完成后才能开始量产。",
			"cta_label": "去博士工厂",
			"target": "factory",
			"stage_id": highest_stage,
		}
	var stage_config := StageCatalog.stage(highest_stage)
	var production_target := int(stage_config.get("factory_production_target", 0))
	var produced_count := maxi(0, int(state.factory.next_hero_sequence) - 2)
	if highest_stage == "stage_1_4" and highest_attempted and production_target > 0 and produced_count < production_target:
		return {
			"title": "让马桶博士生产援军",
			"body": "联盟已经架起炮台防线。分三批生产九个冲锋兵：已完成 %d/%d；三合一后仍能保持六槽满编。" % [produced_count, production_target],
			"cta_label": "去博士工厂",
			"target": "factory",
			"stage_id": highest_stage,
		}
	if highest_stage == "stage_1_4" and highest_attempted and not _has_hero_by_archetype_and_star(state, "assault", 2):
		return {
			"title": "完成第一次技能质变",
			"body": "九个一星冲锋兵已经到位。选择三个三合一，得到会在冲锋后顺劈的二星主力，并保留六个一星兵。",
			"cta_label": "去培育合成",
			"target": "cultivation",
			"stage_id": highest_stage,
		}
	if highest_stage == "stage_1_4" and highest_attempted and not highest_cleared:
		return {
			"title": "检查满编军团",
			"body": "上次是 Gman 单人承受炮火；本次已有六名援军与一名二星主力。检查前后排后，重返同一炮台防线。",
			"cta_label": "去编队复仇",
			"target": "formation",
			"stage_id": highest_stage,
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


func _derive_factory_loop_action(state: RefCounted, now_unix: int) -> Dictionary:
	var highest_stage := String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	if not StageCatalog.has_stage(highest_stage):
		highest_stage = StageCatalog.DEFAULT_STAGE_ID
	var ready_count := _ready_factory_order_count(state, now_unix)
	if ready_count > 0:
		return {
			"title": "领取生产单位",
			"body": "工厂已有 %d 单完成。领取后单位进入真实库存，再决定补位或继续。" % ready_count,
			"cta_label": "去工厂领取",
			"target": "factory",
			"stage_id": highest_stage,
		}
	if state.roster.is_empty():
		return {
			"title": "重建第一名单位",
			"body": "当前已经全灭。先用废料恢复线补足基础材料，再制造一名冲锋马桶人。",
			"cta_label": "去工厂恢复",
			"target": "factory",
			"stage_id": highest_stage,
		}
	var deployed_count: int = state.formation.hero_ids().size()
	if deployed_count < mini(6, state.roster.size()):
		return {
			"title": "补齐攻城编队",
			"body": "当前上阵 %d/6。用真实库存一键补位，幸存单位不会被替换。" % deployed_count,
			"cta_label": "去编队补位",
			"target": "formation",
			"stage_id": highest_stage,
		}
	var cleared: Array = state.stage_progress.get("cleared_stages", [])
	var attempted := int(state.attempt_counters.get(highest_stage, 0)) > 0
	if attempted and not cleared.has(highest_stage):
		return {
			"title": "整备后再次攻城",
			"body": "本关失败不发资源。检查损失、补军或升级型号科技，再决定重试或撤退止损。",
			"cta_label": "整备当前关",
			"target": "expedition",
			"stage_id": highest_stage,
		}
	return {
		"title": "推进下一关",
		"body": "编队已就绪。胜利只掉马桶币与制造材料，幸存单位会保留到下一关。",
		"cta_label": "继续攻城",
		"target": "expedition",
		"stage_id": highest_stage,
	}


func _derive_tutorial_step(state: RefCounted, action: Dictionary = {}) -> Dictionary:
	var resolved_action := action if not action.is_empty() else _derive_next_action(state)
	var target := String(resolved_action.get("target", "expedition"))
	if target == "factory":
		return {
			"step": 1,
			"lesson": "制造军队",
			"hint": "领取生产、抽取图纸或用废料恢复线重新开工。",
		}
	if target == "formation":
		return {
			"step": 2,
			"lesson": "编成六人军队",
			"hint": "同型号可重复上阵，库存中的每个单位都是真实消耗品。",
		}
	return {
		"step": 3,
		"lesson": "持续攻城",
		"hint": "胜利获取马桶币与材料；失败、撤退或全灭均不发资源。",
	}


func _navigate_objective_action(action: Dictionary) -> void:
	var stage_id := String(action.get("stage_id", selected_stage_id))
	if StageCatalog.has_stage(stage_id):
		selected_stage_id = stage_id
	match String(action.get("target", "expedition")):
		"factory":
			_show_factory()
		"repair":
			_show_factory()
		"legion":
			_show_cultivation()
		"cultivation":
			_show_cultivation()
		"formation":
			_show_formation()
		_:
			_show_expedition()


func _claim_current_onboarding_task() -> void:
	var snapshot := OnboardingService.snapshot(game.current_state())
	var task_id := String(snapshot.get("task_id", ""))
	if task_id.is_empty():
		return
	var result := _execute_command("claim_onboarding_task", {"task_id": task_id}, "onboarding:%s" % task_id)
	if bool(result.get("ok", false)):
		_show_camp()
		_show_notice("任务奖励已领取，下一项训练已解锁。")
		return
	_show_notice("任务奖励领取失败：%s" % String(result.get("error", "UNKNOWN")))


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
	if state.economy.xp_books <= 0:
		return false
	for hero in state.roster:
		if (
			int(hero.star) >= 2
			and HeroProgression.max_trainable_books(hero) > 0
			and state.economy.gold >= HeroProgression.next_book_gold_cost(hero)
		):
			return true
	return false


func _can_train_archetype_two_star(state: RefCounted, archetype_id: String) -> bool:
	if state.economy.xp_books <= 0:
		return false
	for hero in state.roster:
		if (
			String(hero.archetype_id) == archetype_id
			and int(hero.star) >= 2
			and HeroProgression.max_trainable_books(hero) > 0
			and state.economy.gold >= HeroProgression.next_book_gold_cost(hero)
		):
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
	var rank_label := _label("战功 Lv%d  ·  %s" % [_war_merit_rank(state), _war_merit_next_progress(state)], 16, COLOR_ACCENT)
	rank_label.name = "QuestWarMeritLabel"
	column.add_child(rank_label)
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


func _build_goal_tabs(achievements_selected: bool, merit_selected: bool = false) -> Control:
	var tabs := HBoxContainer.new()
	tabs.name = "GoalCenterTabs"
	tabs.add_theme_constant_override("separation", 8)
	var quests := _button("任务", COLOR_PRIMARY if not achievements_selected and not merit_selected else COLOR_PANEL_ALT, Vector2(120, 50), 15)
	quests.name = "GoalTabQuestsButton"
	quests.pressed.connect(_show_quests)
	var notifications := _notification_summary()
	_attach_notification_badge(quests, int(notifications["quest_claimable"]), "QuestTabNotificationBadge")
	tabs.add_child(quests)
	var merit := _button("免费战令", COLOR_PRIMARY if merit_selected else COLOR_PANEL_ALT, Vector2(140, 50), 15)
	merit.name = "GoalTabWarMeritButton"
	merit.pressed.connect(_show_war_merit_track)
	_attach_notification_badge(merit, WarMeritTrack.claimable_count(game.current_state()), "WarMeritTabNotificationBadge")
	tabs.add_child(merit)
	return tabs


func _show_war_merit_track() -> void:
	app_state = AppState.QUESTS
	_clear_ui()
	_clear_world()
	_build_camp_world()
	_add_background(Color(0.02, 0.04, 0.08, 0.64))
	_show_management_shell("目标", _build_war_merit_body())


func _build_war_merit_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "WarMeritScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.name = "WarMeritRewardList"
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(1180, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	column.add_child(_build_goal_tabs(false, true))
	var state: RefCounted = game.current_state()
	var reached := WarMeritTrack.reached_level(state)
	var overview := _label(
		"免费战令 Lv%d · %s · 可领取 %d" % [
			reached,
			_war_merit_next_progress(state),
			WarMeritTrack.claimable_count(state),
		],
		16,
		COLOR_ACCENT
	)
	overview.name = "WarMeritTrackOverviewLabel"
	column.add_child(overview)
	var claim_all := _button("领取全部已解锁", COLOR_PRIMARY, Vector2(190, 50), 14)
	claim_all.name = "ClaimAllWarMeritRewardsButton"
	claim_all.disabled = WarMeritTrack.claimable_count(state) <= 0
	claim_all.pressed.connect(_claim_all_war_merit_rewards)
	column.add_child(claim_all)
	for level in range(1, QuestCatalog.MAX_RANK + 1):
		column.add_child(_war_merit_reward_card(state, level, reached))
	return scroll


func _war_merit_reward_card(state: RefCounted, level: int, reached: int) -> Control:
	var claimed := WarMeritTrack.is_claimed(state, level)
	var unlocked := level <= reached
	var card := _panel(COLOR_PANEL, 7)
	card.name = "WarMeritRewardCard_%d" % level
	card.custom_minimum_size = Vector2(1180, 92)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label("免费战令等级 %d%s" % [level, " · 里程碑" if level % 5 == 0 else ""], 15, COLOR_TEXT))
	copy.add_child(_label(_war_merit_reward_text(WarMeritTrack.reward_for_level(level)), 12, COLOR_ACCENT))
	var action := _button(
		"已领取" if claimed else ("领取" if unlocked else "未解锁"),
		COLOR_PRIMARY if unlocked and not claimed else COLOR_PANEL_ALT,
		Vector2(110, 50),
		13
	)
	action.name = "WarMeritClaimButton_%d" % level
	action.disabled = claimed or not unlocked
	_attach_notification_badge(action, 1 if unlocked and not claimed else 0, "WarMeritRewardNotificationBadge")
	action.pressed.connect(func() -> void: _claim_war_merit_reward(level))
	row.add_child(action)
	return card


func _war_merit_reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	for entry in [
		["toilet_coins", "马桶币"],
		["toilet_gems", "马桶钻"],
		["porcelain", "瓷片"],
		["parts", "零件"],
		["sludge", "污泥"],
	]:
		var amount := int(reward.get(String(entry[0]), 0))
		if amount > 0:
			parts.append("%s+%d" % [String(entry[1]), amount])
	return " · ".join(parts)


func _claim_war_merit_reward(level: int, refresh: bool = true) -> bool:
	var request_id := "war-merit:level:%d" % level
	var result := _execute_command(
		"claim_war_merit_reward",
		{"request_id": request_id, "level": level},
		request_id
	)
	if not bool(result.get("ok", false)):
		_show_notice("免费战令奖励领取失败：%s" % String(result.get("error", "UNKNOWN")))
		return false
	if refresh and app_state == AppState.QUESTS:
		_show_war_merit_track()
	return true


func _claim_all_war_merit_rewards() -> void:
	var state: RefCounted = game.current_state()
	var reached := WarMeritTrack.reached_level(state)
	var claimed_count := 0
	for level in range(1, reached + 1):
		if not WarMeritTrack.is_claimed(game.current_state(), level) and _claim_war_merit_reward(level, false):
			claimed_count += 1
	_show_war_merit_track()
	_show_notice("已领取 %d 档免费战令奖励。" % claimed_count)


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
	var tier_label := "大成就" if String(definition.get("tier", "minor")) == "major" else "小成就"
	var title := _label("%s · %s" % [tier_label, String(definition.get("title", achievement_id))], 15, COLOR_TEXT)
	title.name = "AchievementTitleLabel_%s" % _safe_node_suffix(achievement_id)
	copy.add_child(title)
	copy.add_child(_label("%s  ·  %s" % [_achievement_progress_text(state, definition), _achievement_reward_text(definition.get("reward", {}) as Dictionary)], 12, COLOR_ACCENT))
	var action := _button("已领取" if claimed else ("领取" if completed else "进行中"), COLOR_PRIMARY if completed and not claimed else COLOR_PANEL_ALT, Vector2(104, 50), 13)
	action.name = "AchievementClaimButton_%s" % _safe_node_suffix(achievement_id)
	action.disabled = claimed or not completed
	_attach_notification_badge(action, 1 if completed and not claimed else 0, "AchievementClaimNotificationBadge")
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
		parts.append("马桶币+%d" % int(reward["gold"]))
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
	var tier_label := "大任务" if campaign else "小任务"
	var title := _label("%s · %s" % [tier_label, String(entry.get("title", "任务"))], 15 if campaign else 13, COLOR_TEXT)
	title.name = "CampaignQuestTitleLabel" if campaign else "LoopQuestTitleLabel_%d" % loop_index
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(title)
	var progress := _quest_progress_text(entry)
	var summary := _label("%s  ·  %s" % [progress, String(entry.get("reward_text", "战功"))], 12, COLOR_ACCENT)
	if campaign:
		summary.name = "CampaignQuestSummaryLabel"
	column.add_child(summary)
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
	_attach_notification_badge(action, 1 if completed and not claimed else 0, "QuestClaimNotificationBadge")
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
	if int(reward.get("toilet_coins", 0)) > 0:
		parts.append("马桶币+%d" % int(reward["toilet_coins"]))
	if int(reward.get("toilet_gems", 0)) > 0:
		parts.append("马桶钻+%d" % int(reward["toilet_gems"]))
	if not String(reward.get("blueprint_id", "")).is_empty():
		parts.append("确定图纸")
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


func _show_gold_shop() -> void:
	app_state = AppState.SHOP
	_clear_ui()
	_clear_world()
	_build_factory_world()
	_show_management_shell("金币商店", _build_gold_shop_body())


func _build_gold_shop_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "GoldShopScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var state: RefCounted = game.current_state()
	var overview := _accent_panel(Color(0.08, 0.105, 0.14, 0.98), COLOR_ACCENT, 9)
	overview.name = "GoldShopOverviewPanel"
	column.add_child(overview)
	var overview_copy := VBoxContainer.new()
	overview.add_child(overview_copy)
	var gold_label := _label("当前金币 %d" % int(state.economy.gold), 19, COLOR_ACCENT)
	gold_label.name = "GoldShopBalanceLabel"
	overview_copy.add_child(gold_label)
	overview_copy.add_child(_label("金币可补齐训练书和生产材料；货架固定、无随机刷新、无付费入口。", 13, COLOR_TEXT))
	var grid := GridContainer.new()
	grid.name = "GoldShopOfferGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(grid)
	for offer in GoldShopCatalog.all():
		grid.add_child(_gold_shop_offer_card(state, offer))
	return scroll


func _gold_shop_offer_card(state: RefCounted, offer: Dictionary) -> Control:
	var card := _panel(COLOR_PANEL, 8)
	card.custom_minimum_size = Vector2(570, 138)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 4)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(String(offer["display_name"]), 16, COLOR_TEXT))
	copy.add_child(_label(String(offer["description"]), 12, COLOR_MUTED))
	copy.add_child(_label(_shop_offer_grant_text(offer), 13, COLOR_PRIMARY))
	var cost := int(offer["gold_cost"])
	var purchase := _button("%d 金币" % cost, COLOR_PRIMARY if int(state.economy.gold) >= cost else COLOR_PANEL_ALT, Vector2(128, 58), 13)
	var offer_id := String(offer["offer_id"])
	purchase.name = "GoldShopPurchaseButton_%s" % _safe_node_suffix(offer_id)
	purchase.disabled = int(state.economy.gold) < cost
	purchase.pressed.connect(func() -> void: _purchase_gold_shop_offer(offer_id))
	row.add_child(purchase)
	return card


func _shop_offer_grant_text(offer: Dictionary) -> String:
	var bundle := (offer.get("economy_grant", {}) as Dictionary).duplicate(true)
	for key in (offer.get("factory_grant", {}) as Dictionary):
		bundle[key] = int((offer["factory_grant"] as Dictionary)[key])
	var parts: Array[String] = []
	for entry in [
		["xp_books", "训练书"],
		["porcelain", "瓷片"],
		["parts", "零件"],
		["sludge", "污泥"],
	]:
		var amount := int(bundle.get(String(entry[0]), 0))
		if amount > 0:
			parts.append("%s ×%d" % [String(entry[1]), amount])
	return "获得 " + " · ".join(parts)


func _purchase_gold_shop_offer(offer_id: String) -> void:
	var request_id := "gold-shop:%s:%d" % [offer_id, int(game.current_state().revision)]
	var result := _execute_command(
		"purchase_gold_shop",
		{"request_id": request_id, "offer_id": offer_id},
		request_id
	)
	if bool(result.get("ok", false)):
		var offer := GoldShopCatalog.offer(offer_id)
		_show_gold_shop()
		_show_notice("购买成功：%s。" % String(offer.get("display_name", offer_id)))
		return
	_show_notice("购买失败：%s" % String(result.get("error", "UNKNOWN")))


func _show_factory() -> void:
	var previous_scroll := 0
	if app_state == AppState.FACTORY:
		var current_scroll := find_child("FactoryScrollContainer", true, false) as ScrollContainer
		if current_scroll != null:
			previous_scroll = current_scroll.scroll_vertical
	app_state = AppState.FACTORY
	factory_refresh_elapsed = 0.0
	factory_order_views.clear()
	factory_research_view.clear()
	_clear_ui()
	_clear_world()
	_build_factory_world()
	var body := _build_factory_body() as ScrollContainer
	_show_management_shell("马桶博士工厂", body)
	if previous_scroll > 0:
		_restore_factory_scroll(body, previous_scroll)


func _build_factory_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "FactoryScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	var state: RefCounted = game.current_state()
	var now := int(Time.get_unix_time_from_system())
	var summary: Dictionary = FactoryService.offline_summary(state, now)
	column.add_child(_build_logistics_panel(state, now))
	column.add_child(_build_blueprint_draw_panel(state))
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
		claim_all.name = "ClaimReadyProductionsButton"
		_attach_notification_badge(claim_all, int(summary["ready_count"]), "FactoryClaimAllNotificationBadge")
		claim_all.pressed.connect(_claim_ready_productions)
		ready_row.add_child(claim_all)
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


func _build_logistics_panel(state: RefCounted, now_unix: int) -> Control:
	var panel := _accent_panel(Color(0.055, 0.10, 0.12, 0.98), COLOR_PRIMARY, 10)
	panel.name = "LogisticsPanel"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	column.add_child(_label("工厂后勤 · 永久军团", 19, COLOR_TEXT))
	column.add_child(_label(
		"陶瓷 %d · 零件 %d · 能源 %d · 工业技术 %d" % [
			int(state.factory.materials.get("porcelain", 0)),
			int(state.factory.materials.get("parts", 0)),
			int(state.factory.materials.get("sludge", 0)),
			int(state.economy.industrial_tech),
		],
		14,
		COLOR_ACCENT
	))
	var claim := _button("收取后勤资源", COLOR_PRIMARY, Vector2(160, 48), 14)
	claim.name = "ClaimFactoryOutputButton"
	claim.pressed.connect(func() -> void:
		var result := _execute_command("claim_factory_output", {"now_unix": now_unix}, "factory-output:%d" % now_unix)
		if bool(result.get("ok", false)):
			_show_factory()
			_show_notice("后勤资源已入库。")
		else:
			_show_notice("暂时没有可收取资源：%s" % String(result.get("error", "UNKNOWN")))
	)
	column.add_child(claim)
	var facilities_row := HBoxContainer.new()
	facilities_row.add_theme_constant_override("separation", 8)
	column.add_child(facilities_row)
	var porcelain_level := int(state.factory.facilities.get("porcelain_plant", 1))
	var porcelain_upgrade := _button(
		"陶瓷厂 Lv%d\n升级：金%d 技术%d" % [porcelain_level, 40 * porcelain_level, 2 * porcelain_level],
		COLOR_PANEL_ALT,
		Vector2(180, 58),
		13
	)
	porcelain_upgrade.name = "UpgradePorcelainPlantButton"
	porcelain_upgrade.disabled = porcelain_level >= 3
	porcelain_upgrade.pressed.connect(func() -> void: _upgrade_facility_ui("porcelain_plant"))
	facilities_row.add_child(porcelain_upgrade)
	var readiness_label := _label("维修中心", 15, COLOR_PRIMARY)
	facilities_row.add_child(readiness_label)
	var damaged_count := 0
	for hero in state.roster:
		if int(hero.readiness) >= 100:
			continue
		damaged_count += 1
		var quick := _button("%s %d%%\n快速整备" % [String(hero.display_name), int(hero.readiness)], COLOR_ACCENT, Vector2(150, 58), 12)
		quick.name = "QuickRepairButton_%s" % _safe_node_suffix(String(hero.hero_id))
		var quick_id := String(hero.hero_id)
		quick.pressed.connect(func() -> void: _repair_hero_ui(quick_id, "quick"))
		facilities_row.add_child(quick)
		var full := _button("完全维修", COLOR_PANEL_ALT, Vector2(110, 58), 12)
		full.name = "FullRepairButton_%s" % _safe_node_suffix(String(hero.hero_id))
		var full_id := String(hero.hero_id)
		full.pressed.connect(func() -> void: _repair_hero_ui(full_id, "full"))
		facilities_row.add_child(full)
		break
	if damaged_count == 0:
		facilities_row.add_child(_label("军团战备完整；攻城后会在这里处理伤损。", 13, COLOR_MUTED))
	return panel


func _upgrade_facility_ui(facility_id: String) -> void:
	var result := _execute_command("upgrade_facility", {"facility_id": facility_id}, "")
	if bool(result.get("ok", false)):
		_show_factory()
		_show_notice("设施升级完成。")
		return
	_show_notice("设施升级失败：%s" % String(result.get("error", "UNKNOWN")))


func _repair_hero_ui(hero_id: String, repair_mode: String) -> void:
	var result := _execute_command("repair_hero", {"hero_id": hero_id, "repair_mode": repair_mode}, "")
	if bool(result.get("ok", false)):
		_show_factory()
		_show_notice("战备恢复完成。")
		return
	_show_notice("维修失败：%s" % String(result.get("error", "UNKNOWN")))


func _build_blueprint_draw_panel(state: RefCounted) -> Control:
	var panel := _accent_panel(Color(0.07, 0.10, 0.15, 0.98), COLOR_ACCENT, 9)
	panel.name = "BlueprintDrawPanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label("图纸研发 · 马桶钻", 17, COLOR_ACCENT))
	copy.add_child(_label(
		"马桶钻 %d · S 定向保底 %d/100" % [
			int(state.economy.toilet_gems),
			int(state.pity.get("s_pity_count", 0)),
		],
		14,
		COLOR_TEXT
	))
	copy.add_child(_label("主要获得制造材料；低概率获得图纸或图纸数据。关卡不会掉图纸。", 12, COLOR_MUTED))
	var single := _button("研发1次\n160钻", COLOR_PRIMARY, Vector2(108, 58), 13)
	single.name = "BlueprintDrawSingleButton"
	single.disabled = int(state.economy.toilet_gems) < 160
	single.pressed.connect(func() -> void: _draw_blueprints(1))
	row.add_child(single)
	var ten := _button("研发10次\n1440钻", COLOR_PRIMARY, Vector2(118, 58), 13)
	ten.name = "BlueprintDrawTenButton"
	ten.disabled = int(state.economy.toilet_gems) < 1440
	ten.pressed.connect(func() -> void: _draw_blueprints(10))
	row.add_child(ten)
	return panel


func _draw_blueprints(count: int) -> void:
	var result := _execute_command(
		"draw_blueprints",
		{"count": count, "target_s_recipe_id": "special.parasite", "pool_id": "standard_s"},
		""
	)
	if not bool(result.get("ok", false)):
		_show_notice("图纸研发失败：%s" % String(result.get("error", "UNKNOWN")))
		return
	var event := result.get("event", {}) as Dictionary
	var complete_count := 0
	var data_count := 0
	for item_value in event.get("results", []):
		var item := item_value as Dictionary
		if String(item.get("kind", "")) == "complete_blueprint":
			complete_count += 1
		elif String(item.get("kind", "")) == "blueprint_data":
			data_count += int(item.get("amount", 0))
	_show_factory()
	_show_notice("研发完成：完整图纸 %d，图纸数据 %d，其余为制造材料。" % [complete_count, data_count])


func _build_blueprint_research_panel(state: RefCounted, now_unix: int) -> Control:
	var panel := _accent_panel(Color(0.07, 0.10, 0.15, 0.98), COLOR_ACCENT, 9)
	panel.name = "BlueprintResearchPanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label("马桶博士 · 图纸研究", 17, COLOR_ACCENT))
	if not state.factory.blueprint_research.is_empty():
		var recipe_id := String(state.factory.blueprint_research.get("recipe_id", ""))
		var recipe := FactoryCatalog.recipe(recipe_id)
		var remaining := maxi(0, int(state.factory.blueprint_research.get("completes_at_unix", 0)) - now_unix)
		var timer_label := _label("%s · 剩余 %02d:%02d" % [String(recipe.get("display_name", recipe_id)), remaining / 60, remaining % 60], 14, COLOR_TEXT)
		timer_label.name = "BlueprintResearchTimerLabel"
		copy.add_child(timer_label)
		copy.add_child(_label("图纸商业价值≈%d金" % EconomyValuation.blueprint_value_gold(recipe_id), 12, COLOR_ACCENT))
		var debrief_text := ""
		if recipe_id == "ordinary.assault":
			debrief_text = "战术复盘：上次炮台伤害集中在 Gman；冲锋兵将分担第一轮火力。"
		elif recipe_id == "heavy.armored":
			debrief_text = "战术预览：装甲护盾承接核心巨炮，保护 Gman 持续输出。"
		if not debrief_text.is_empty():
			var debrief := _label(debrief_text, 12, COLOR_PRIMARY)
			debrief.name = "ResearchTacticalDebriefLabel"
			copy.add_child(debrief)
		var claim := _button("完成研究", COLOR_PRIMARY, Vector2(130, 48), 13)
		claim.name = "ClaimBlueprintResearchButton"
		claim.disabled = remaining > 0
		claim.pressed.connect(_claim_blueprint_research)
		row.add_child(claim)
		factory_research_view = {
			"recipe_name": String(recipe.get("display_name", recipe_id)),
			"completes_at_unix": int(state.factory.blueprint_research.get("completes_at_unix", 0)),
			"timer_label": timer_label,
			"claim_button": claim,
		}
		return panel
	var discovered_ids: Array[String] = []
	for recipe_value in state.factory.discovered_blueprints.keys():
		var discovered_recipe_id := String(recipe_value)
		if bool(state.factory.discovered_blueprints.get(discovered_recipe_id, false)):
			discovered_ids.append(discovered_recipe_id)
	if discovered_ids.is_empty():
		copy.add_child(_label("继续攻城，击败新防线后会缴获设计图纸。", 13, COLOR_MUTED))
		return panel
	discovered_ids.sort()
	var recipe_id := discovered_ids[0]
	var recipe := FactoryCatalog.recipe(recipe_id)
	copy.add_child(_label("已获得：%s设计图" % String(recipe.get("display_name", recipe_id)), 14, COLOR_TEXT))
	copy.add_child(_label("图纸商业价值≈%d金" % EconomyValuation.blueprint_value_gold(recipe_id), 12, COLOR_ACCENT))
	var research := _button("开始研究", COLOR_PRIMARY, Vector2(130, 48), 13)
	research.name = "StartBlueprintResearchButton"
	research.pressed.connect(func() -> void: _start_blueprint_research(recipe_id))
	row.add_child(research)
	return panel


func _start_blueprint_research(recipe_id: String) -> void:
	var now := int(Time.get_unix_time_from_system())
	var result := _execute_command("start_blueprint_research", {"recipe_id": recipe_id, "now_unix": now}, "")
	if bool(result.get("ok", false)):
		_show_factory()
	else:
		_show_notice("研究启动失败：%s" % String(result.get("error", "UNKNOWN")))


func _claim_blueprint_research() -> void:
	var now := int(Time.get_unix_time_from_system())
	var result := _execute_command("claim_blueprint_research", {"now_unix": now}, "")
	if bool(result.get("ok", false)):
		_show_factory()
	else:
		_show_notice("图纸尚未研究完成：%s" % String(result.get("error", "UNKNOWN")))


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
	claim.name = "ProductionClaimButton_%s" % _safe_node_suffix(String(order["order_id"]))
	claim.disabled = remain > 0
	_attach_notification_badge(claim, 1 if remain == 0 else 0, "ProductionReadyNotificationBadge")
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
	if not factory_research_view.is_empty():
		var research_timer := factory_research_view.get("timer_label") as Label
		var research_claim := factory_research_view.get("claim_button") as Button
		if is_instance_valid(research_timer) and is_instance_valid(research_claim):
			var research_remain := maxi(0, int(factory_research_view["completes_at_unix"]) - now)
			research_timer.text = "%s · 剩余 %02d:%02d" % [
				String(factory_research_view["recipe_name"]),
				research_remain / 60,
				research_remain % 60,
			]
			research_claim.disabled = research_remain > 0
	for view in factory_order_views:
		var timer_label := view.get("timer_label") as Label
		var claim_button := view.get("claim_button") as Button
		if not is_instance_valid(timer_label) or not is_instance_valid(claim_button):
			continue
		var remain := maxi(0, int(view["completes_at_unix"]) - now)
		timer_label.text = "剩余 %02d:%02d" % [remain / 60, remain % 60]
		timer_label.add_theme_color_override("font_color", COLOR_ACCENT if remain > 0 else COLOR_PRIMARY)
		claim_button.disabled = remain > 0
		_set_notification_badge(claim_button, 1 if remain == 0 else 0, "ProductionReadyNotificationBadge")


func _restore_factory_scroll(scroll: ScrollContainer, scroll_vertical: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if app_state == AppState.FACTORY and is_instance_valid(scroll):
		scroll.scroll_vertical = scroll_vertical


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
	copy.add_child(_label(
		"瓷%d 零%d 泥%d · 成本≈%d金" % [
			int(cost["porcelain"]),
			int(cost["parts"]),
			int(cost["sludge"]),
			EconomyValuation.recipe_cost_gold(String(recipe["recipe_id"])),
		],
		13,
		COLOR_ACCENT
	))
	var archetype: Dictionary = FactoryCatalog.archetype(String(recipe["archetype_id"]))
	copy.add_child(_label("%s · %s" % [_role_name(String(archetype.get("role", ""))), String(archetype.get("description", ""))], 11, COLOR_MUTED))
	var start := _button("研究生产", COLOR_PRIMARY, Vector2(94, 74), 13)
	var recipe_id := String(recipe["recipe_id"])
	if not unlocked:
		start.text = "缺少图纸"
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
	var previous_scroll := 0
	if app_state == AppState.CULTIVATION:
		var current_scroll := find_child("CultivationScrollContainer", true, false) as ScrollContainer
		if current_scroll != null:
			previous_scroll = current_scroll.scroll_vertical
	app_state = AppState.CULTIVATION
	_clear_ui()
	_clear_world()
	_build_camp_world()
	var body := _build_model_tech_body() as ScrollContainer
	_show_management_shell("型号科技", body)
	if previous_scroll > 0:
		_restore_cultivation_scroll(body, previous_scroll)


func _build_model_tech_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "CultivationScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	var state: RefCounted = game.current_state()
	column.add_child(_label("永久角色", 19, COLOR_PRIMARY))
	for hero in state.roster:
		var hero_card := _panel(COLOR_PANEL, 8)
		column.add_child(hero_card)
		var hero_row := HBoxContainer.new()
		hero_row.add_theme_constant_override("separation", 8)
		hero_card.add_child(hero_row)
		var hero_copy := VBoxContainer.new()
		hero_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hero_row.add_child(hero_copy)
		hero_copy.add_child(_label("%s · Lv%d · ★%d" % [String(hero.display_name), int(hero.level), int(hero.star)], 17, COLOR_TEXT))
		hero_copy.add_child(_label(
			"战备 %d%% · 经验 %d/320 · 工厂专长随星级解锁" % [int(hero.readiness), int(hero.xp)],
			13,
			COLOR_PRIMARY if int(hero.readiness) >= 60 else COLOR_DANGER
		))
		var upgrade_hero := _button("升级", COLOR_PRIMARY, Vector2(100, 52), 13)
		upgrade_hero.name = "PermanentHeroUpgradeButton_%s" % _safe_node_suffix(String(hero.hero_id))
		upgrade_hero.disabled = int(hero.level) >= 5
		var upgrade_id := String(hero.hero_id)
		upgrade_hero.pressed.connect(func() -> void: _upgrade_permanent_hero_ui(upgrade_id))
		hero_row.add_child(upgrade_hero)
	column.add_child(_label("旧型号科技（迁移兼容）", 15, COLOR_MUTED))
	column.add_child(_label(
		"马桶币 %d · 型号科技永久生效，单位个人不训练、不三合一。" % int(state.economy.toilet_coins),
		16,
		COLOR_ACCENT
	))
	for recipe in FactoryCatalog.recipes():
		var recipe_id := String(recipe["recipe_id"])
		if not bool(state.factory.blueprints.get(recipe_id, false)):
			continue
		var star := int(state.factory.model_tech_stars.get(recipe_id, 1))
		var data_count := int(state.factory.blueprint_data.get(recipe_id, 0))
		var data_cost := 0 if star >= 3 else (10 if star == 1 else 30)
		var coin_cost := 0 if star >= 3 else (200 if star == 1 else 600)
		var card := _panel(COLOR_PANEL, 8)
		column.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		copy.add_child(_label("%s · ★%d" % [String(recipe["display_name"]), star], 17, COLOR_TEXT))
		copy.add_child(_label(
			"图纸数据 %d%s" % [data_count, "" if star >= 3 else " / %d · 马桶币 %d" % [data_cost, coin_cost]],
			13,
			COLOR_MUTED
		))
		var upgrade := _button("已满星" if star >= 3 else "升至★%d" % (star + 1), COLOR_PRIMARY, Vector2(112, 52), 13)
		upgrade.name = "ModelTechUpgradeButton_%s" % _safe_node_suffix(recipe_id)
		upgrade.disabled = star >= 3 or data_count < data_cost or int(state.economy.toilet_coins) < coin_cost
		upgrade.pressed.connect(func() -> void: _upgrade_model_tech(recipe_id))
		row.add_child(upgrade)
	return scroll


func _upgrade_permanent_hero_ui(hero_id: String) -> void:
	var result := _execute_command("upgrade_permanent_hero", {"hero_id": hero_id}, "")
	if bool(result.get("ok", false)):
		_show_cultivation()
		_show_notice("永久角色升级完成。")
		return
	_show_notice("角色升级失败：%s" % String(result.get("error", "UNKNOWN")))


func _upgrade_model_tech(recipe_id: String) -> void:
	var result := _execute_command("upgrade_model_tech", {"recipe_id": recipe_id}, "")
	if bool(result.get("ok", false)):
		_show_cultivation()
		return
	_show_notice("型号科技升级失败：%s" % String(result.get("error", "UNKNOWN")))


func _build_cultivation_body() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "CultivationScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	var merge_header := _accent_panel(Color(0.06, 0.12, 0.16, 0.98), COLOR_PRIMARY, 10)
	merge_header.name = "MergeSelectionPanel"
	column.add_child(merge_header)
	var merge_box := VBoxContainer.new()
	merge_box.add_theme_constant_override("separation", 6)
	merge_header.add_child(merge_box)
	merge_box.add_child(_label("三合一升星", 19, COLOR_TEXT))
	var selection_count := selected_merge_ids.size()
	var selection_hint := _label(
		"已选 %d/3 · 请选择同类型、同星级的 3 个单位" % selection_count,
		14,
		COLOR_PRIMARY if selection_count > 0 else COLOR_MUTED
	)
	selection_hint.name = "MergeSelectionStatusLabel"
	merge_box.add_child(selection_hint)
	if selection_count == 3:
		var selected_hero: RefCounted = game.current_state().hero_by_id(selected_merge_ids[0])
		if selected_hero != null:
			var preview := _label(
				"将获得：%s ★%d → ★%d（消耗所选 3 个）" % [
					_archetype_name(String(selected_hero.archetype_id)),
					int(selected_hero.star),
					int(selected_hero.star) + 1,
				],
				14,
				COLOR_ACCENT
			)
			preview.name = "MergeResultPreviewLabel"
			merge_box.add_child(preview)
	var merge := _button(
		"确认升星" if selection_count == 3 else "请先选择 3 个单位（%d/3）" % selection_count,
		COLOR_PRIMARY,
		Vector2(220, 48),
		16
	)
	merge.name = "MergeSelectedHeroesButton"
	merge.disabled = selection_count != 3
	merge.pressed.connect(_merge_selected_heroes)
	merge_box.add_child(merge)

	var groups: Dictionary = {}
	for hero in game.current_state().roster:
		if String(hero.hero_id) == String(game.current_state().formation.slots.get("commander", "")):
			continue
		if int(hero.star) >= 5:
			continue
		var key := "%s|%d" % [hero.archetype_id, hero.star]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(hero)
	var visible_group_count := 0
	for key in groups.keys():
		var heroes := groups[key] as Array
		if heroes.size() < 2:
			continue
		visible_group_count += 1
		var card := _panel(COLOR_PANEL, 8)
		column.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)
		var exemplar: RefCounted = heroes[0]
		var group_header := HBoxContainer.new()
		group_header.add_theme_constant_override("separation", 8)
		box.add_child(group_header)
		var group_title := _label("%s  ★%d" % [_archetype_name(exemplar.archetype_id), exemplar.star], 17, COLOR_TEXT)
		group_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group_header.add_child(group_title)
		var can_merge := heroes.size() >= 3
		var group_status := _label(
			"可升星 · %d 个" % heroes.size() if can_merge else "还差 %d 个" % (3 - heroes.size()),
			13,
			COLOR_PRIMARY if can_merge else COLOR_ACCENT
		)
		group_header.add_child(group_status)
		if can_merge:
			var group_ids: Array[String] = []
			for hero in heroes:
				group_ids.append(String(hero.hero_id))
			var quick_select := _button("一键选择 3 个", COLOR_PRIMARY, Vector2(130, 38), 13)
			quick_select.name = "MergeQuickSelectButton_%s_%d" % [
				_safe_node_suffix(String(exemplar.archetype_id)),
				int(exemplar.star),
			]
			quick_select.pressed.connect(func() -> void: _select_merge_group(group_ids))
			group_header.add_child(quick_select)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		box.add_child(grid)
		for hero in heroes:
			var is_selected := selected_merge_ids.has(hero.hero_id)
			var toggle := _button(
				("已选 ✓  " if is_selected else "选择  ") + hero.display_name,
				COLOR_PRIMARY if is_selected else COLOR_PANEL_ALT,
				Vector2(170, 44),
				13
			)
			var hero_id := String(hero.hero_id)
			toggle.name = "MergeHeroButton_%s" % _safe_node_suffix(hero_id)
			toggle.pressed.connect(func() -> void: _toggle_merge_selection(hero_id))
			grid.add_child(toggle)
	if visible_group_count == 0:
		var empty := _panel(COLOR_PANEL, 8)
		column.add_child(empty)
		empty.add_child(_label("暂无可升星组合 · 每种同星单位至少需要 3 个", 14, COLOR_MUTED))

	column.add_child(_label("训练强化", 17, COLOR_PRIMARY))
	column.add_child(_build_training_panel())
	return scroll


func _restore_cultivation_scroll(scroll: ScrollContainer, scroll_vertical: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if app_state == AppState.CULTIVATION and is_instance_valid(scroll):
		scroll.scroll_vertical = scroll_vertical


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
	var books_to_next_level := HeroProgression.books_to_next_level(selected)
	var preview: RefCounted = selected.deep_clone()
	HeroProgression.train_with_books(preview, books_to_next_level)
	var stats_after: Dictionary = HeroProgression.derived_battle_stats(preview)
	var power_before := CombatPower.hero_power(selected)
	var power_after := CombatPower.hero_power(preview)
	var training_gold_cost := HeroProgression.next_book_gold_cost(selected)
	var archetype: Dictionary = FactoryCatalog.archetype(String(selected.archetype_id))
	detail.add_child(_label("%s  L%d  XP %d/320  ★%d" % [selected.display_name, selected.level, selected.xp, selected.star], 15, COLOR_TEXT))
	detail.add_child(_label("%s · %s · 技能 T%d" % [
		_role_name(String(archetype.get("role", ""))),
		String(archetype.get("active_skill", "")),
		HeroProgression.skill_tier(selected),
	], 12, COLOR_PRIMARY))
	var training_cost_label := _label(
		"金%d + 训练书1（总价值≈%d金）" % [
			training_gold_cost,
			training_gold_cost + EconomyValuation.resource_value_gold("xp_books"),
		],
		13,
		COLOR_ACCENT
	)
	if books_to_next_level <= 0:
		training_cost_label.text = "已达到 L5 训练上限"
	training_cost_label.name = "TrainingCostLabel"
	detail.add_child(training_cost_label)
	var milestone_gold_cost := HeroProgression.training_gold_cost(selected, books_to_next_level)
	var training_power_text := (
		"L5 已满级 · 当前战力 %d" % power_before
		if books_to_next_level <= 0
		else "升至L%d：还需书%d/金币%d · 战力 %d→%d（+%d）" % [
			mini(5, int(selected.level) + 1),
			books_to_next_level,
			milestone_gold_cost,
			power_before,
			power_after,
			power_after - power_before,
		]
	)
	var training_power_label := _label(training_power_text, 13, COLOR_PRIMARY)
	training_power_label.name = "TrainingPowerLabel"
	detail.add_child(training_power_label)
	detail.add_child(_label("HP %d→%d  攻 %d→%d  防 %d→%d" % [
		int(stats_before["max_hp"]),
		int(stats_after["max_hp"]),
		maxi(int(stats_before["physical_atk"]), int(stats_before["magic_atk"])),
		maxi(int(stats_after["physical_atk"]), int(stats_after["magic_atk"])),
		int(stats_before["defense"]),
		int(stats_after["defense"]),
	], 13, COLOR_MUTED))
	var train := _button("训练1本", COLOR_PRIMARY, Vector2(140, 40), 13)
	train.disabled = state.economy.xp_books < 1 or state.economy.gold < training_gold_cost or HeroProgression.max_trainable_books(selected) <= 0
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


func _select_merge_group(hero_ids: Array[String]) -> void:
	selected_merge_ids.clear()
	for hero_id in hero_ids:
		if selected_merge_ids.size() >= 3:
			break
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
	_show_management_shell("马桶人军团 · 2×3", _build_formation_body())


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
	var refill := _button("一键补位", COLOR_ACCENT, Vector2(150, 48), 14)
	refill.pressed.connect(_refill_formation)
	grid.add_child(refill)
	for index in SLOT_KEYS.size():
		var hero_id := String(state.formation.slots.get(SLOT_KEYS[index], ""))
		var hero: RefCounted = state.hero_by_id(hero_id) if not hero_id.is_empty() else null
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
		reserve_column.add_child(_label("当前没有未上阵单位。请先在工厂制造。", 15, COLOR_MUTED))
	for hero in reserves:
		var pick := _button("%s ★%d %s" % [hero.display_name, hero.star, _class_name(hero.class_id)], COLOR_PANEL_ALT, Vector2(220, 40), 13)
		var hero_id := String(hero.hero_id)
		pick.pressed.connect(func() -> void: _replace_formation_slot(hero_id))
		reserve_column.add_child(pick)
	var confirm_formation := _button("确认当前 2×3 编队", COLOR_PRIMARY, Vector2(220, 48), 14)
	confirm_formation.name = "ConfirmFormationButton"
	confirm_formation.pressed.connect(func() -> void:
		var result := _execute_command("set_formation", state.formation.to_dict(), "")
		if bool(result.get("ok", false)):
			_show_formation()
			_show_notice("编队已确认。")
		else:
			_show_notice("编队确认失败：%s" % String(result.get("error", "UNKNOWN")))
	)
	reserve_column.add_child(confirm_formation)
	if not state.formation.hero_ids().is_empty():
		var lead_id := String(state.formation.hero_ids()[0])
		var lead: RefCounted = state.hero_by_id(lead_id)
		if lead != null:
			var auto_skill := _button(
				"自动技能：%s" % ("已开启" if bool(lead.auto_skill_enabled) else "未开启"),
				COLOR_ACCENT if bool(lead.auto_skill_enabled) else COLOR_PANEL_ALT,
				Vector2(220, 48),
				14
			)
			auto_skill.name = "OnboardingAutoSkillButton"
			auto_skill.pressed.connect(func() -> void:
				var result := _execute_command(
					"set_auto_skill_preference",
					{"hero_id": lead_id, "enabled": not bool(lead.auto_skill_enabled)},
					""
				)
				if bool(result.get("ok", false)):
					_show_formation()
				else:
					_show_notice("自动技能设置失败：%s" % String(result.get("error", "UNKNOWN")))
			)
			reserve_column.add_child(auto_skill)
	if String(state.stage_progress.get("highest_unlocked_stage", "")) == "stage_1_4" and int(state.attempt_counters.get("stage_1_4", 0)) > 0:
		var retry := _button("确认阵容 · 复仇 1-4", COLOR_PRIMARY, Vector2(220, 48), 14)
		retry.name = "FormationRetryButton"
		retry.pressed.connect(func() -> void:
			selected_stage_id = "stage_1_4"
			_show_expedition()
		)
		reserve_column.add_child(retry)
	return row


func _refill_formation() -> void:
	var result := _execute_command("refill_formation", {}, "")
	if bool(result.get("ok", false)):
		_show_formation()
		return
	_show_notice("补位失败：%s" % String(result.get("error", "UNKNOWN")))


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

	var detail := _accent_panel(COLOR_PANEL, COLOR_PRIMARY, 11)
	detail.name = "ExpeditionDetailPanel"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.size_flags_stretch_ratio = 0.55
	body.add_child(detail)
	var detail_column := VBoxContainer.new()
	detail_column.add_theme_constant_override("separation", 6)
	detail.add_child(detail_column)
	var stage_config: Dictionary = StageCatalog.stage(selected_stage_id)
	var team_power := CombatPower.formation_power(state)
	var recommended_power := int(stage_config.get("recommended_power", 0))
	var minimum_power := int(stage_config.get("minimum_power", recommended_power))
	var readiness_id := CombatPower.readiness(team_power, recommended_power, minimum_power)
	var growth_plan := GrowthPlan.for_stage(state, stage_config)
	if state.attempt_counters.is_empty():
		var first_battle_brief := _label("前三关只派 Gman；第 4 关失败后才开放博士工厂。", 13, COLOR_ACCENT)
		first_battle_brief.name = "FirstBattleTutorialBrief"
		detail_column.add_child(first_battle_brief)
	detail_column.add_child(_label(String(stage_config.get("display_name", selected_stage_id)), 20, COLOR_TEXT))
	var power_color := COLOR_PRIMARY if readiness_id == "ready" else (COLOR_ACCENT if readiness_id == "challenge" else COLOR_DANGER)
	var power_label := _label(
		"军团战力 %d · 推荐 %d（最低 %d）· %s" % [
			team_power,
			recommended_power,
			minimum_power,
			CombatPower.readiness_label(readiness_id),
		],
		13,
		power_color
	)
	power_label.name = "StagePowerLabel"
	detail_column.add_child(power_label)
	if int(growth_plan.get("power_gap", 0)) > 0:
		var growth_label := _label(
			"成长方案：%s · 缺口 %d · %s" % [
				String(growth_plan.get("title", "继续培养")),
				int(growth_plan.get("power_gap", 0)),
				String(growth_plan.get("estimate_label", "暂无法估价")),
			],
			12,
			COLOR_ACCENT
		)
		growth_label.name = "StageGrowthPlanLabel"
		detail_column.add_child(growth_label)
	var chapter := int(stage_config.get("chapter", 1))
	var is_boss := int(stage_config.get("stage_in_chapter", 1)) == 5
	var intel := _panel(Color(0.07, 0.105, 0.15, 0.96), 7)
	detail_column.add_child(intel)
	var intel_column := VBoxContainer.new()
	intel_column.add_theme_constant_override("separation", 3)
	intel.add_child(intel_column)
	var threat_label := _label("威胁  " + _stage_text(stage_config, "threat_summary", _chapter_threat_text(chapter, is_boss)), 13, COLOR_DANGER if is_boss else COLOR_TEXT)
	threat_label.name = "StageThreatSummary"
	intel_column.add_child(threat_label)
	var counter_label := _label("建议  " + _stage_text(stage_config, "counter_hint", "装甲顶线，火箭/双锯拆设施，维修保主力。").trim_prefix("反制："), 12, COLOR_PRIMARY)
	counter_label.name = "StageCounterHint"
	intel_column.add_child(counter_label)
	var rewards: Dictionary = StageCatalog.reward_for(selected_stage_id, "victory")
	detail_column.add_child(_label(
		"胜利：金%d · 书%d · 瓷%d · 零%d · 泥%d（总价值≈%d金）" % [
			int(rewards.get("gold", 0)),
			int(rewards.get("xp_books", 0)),
			int(rewards.get("porcelain", 0)),
			int(rewards.get("parts", 0)),
			int(rewards.get("sludge", 0)),
			EconomyValuation.bundle_value_gold(rewards),
		],
		12,
		COLOR_ACCENT
	))
	detail_column.add_child(HSeparator.new())
	detail_column.add_child(_label("出征军团 %d/7" % state.formation.hero_ids().size(), 15, COLOR_PRIMARY))
	var squad_grid := GridContainer.new()
	squad_grid.columns = 2
	squad_grid.add_theme_constant_override("h_separation", 8)
	squad_grid.add_theme_constant_override("v_separation", 4)
	detail_column.add_child(squad_grid)
	var ids: Array[String] = state.formation.hero_ids()
	for index in ids.size():
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
	var highest_id := String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	if stage_id.begins_with(StageCatalog.ENDLESS_PREFIX):
		if not highest_id.begins_with(StageCatalog.ENDLESS_PREFIX):
			return false
		return int(stage_id.trim_prefix(StageCatalog.ENDLESS_PREFIX)) <= int(highest_id.trim_prefix(StageCatalog.ENDLESS_PREFIX))
	var target_index := all_ids.find(stage_id)
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
	return "关卡奖励：仅马桶币与制造材料；图纸请前往研发、免费战令或里程碑获取。"


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
	if game.current_state().formation.hero_ids().is_empty():
		_show_notice("至少需要一名真实库存单位才能出征。")
		_show_formation()
		return
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
	var retreat_button := _button("撤退", COLOR_DANGER, Vector2(72, 40), 14)
	retreat_button.pressed.connect(_request_battle_retreat)
	top.add_child(retreat_button)
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
	var battle_stage_config := StageCatalog.stage(selected_stage_id)
	var battle_team_power := CombatPower.formation_power(game.current_state())
	var battle_recommended_power := int(battle_stage_config.get("recommended_power", 0))
	battle_power_label = _label(
		"战力 %d / 推荐 %d" % [battle_team_power, battle_recommended_power],
		13,
		_readiness_color(CombatPower.readiness(
			battle_team_power,
			battle_recommended_power,
			int(battle_stage_config.get("minimum_power", battle_recommended_power))
		))
	)
	battle_power_label.name = "BattlePowerLabel"
	battle_power_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stage_row.add_child(battle_power_label)
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
	battle_stage_label.text = "阶段 %d/%d  %s" % [
		int(snapshot.get("stage_index", 0)) + 1,
		maxi(1, int(snapshot.get("stage_count", 1))),
		snapshot.get("stage_name", ""),
	]
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


func _request_battle_retreat() -> void:
	if battle_world == null:
		return
	battle_is_paused = false
	if not battle_world.request_retreat():
		_show_notice("当前战斗已经结束，无法撤退。")


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
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(column)
	var hp := _label("%s  %d/%d" % [
		SLOT_NAMES[int(unit["slot"])],
		int(unit["hp"]),
		int(unit["max_hp"]),
	], 11, COLOR_TEXT if bool(unit["alive"]) else COLOR_DANGER)
	hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp.autowrap_mode = TextServer.AUTOWRAP_OFF
	hp.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(hp)
	var hp_bar := _progress_bar(float(unit["hp"]), maxf(1.0, float(unit["max_hp"])), COLOR_PRIMARY if bool(unit["alive"]) else COLOR_DANGER, 5)
	hp_bar.name = "BattleUnitHpBar"
	column.add_child(hp_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	column.add_child(row)
	var unit_id := StringName(unit["unit_id"])
	var skill := _button(_skill_short(String(unit["skill_id"])), COLOR_PRIMARY, Vector2(56, 50), 12)
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
	auto.text = "自动"
	auto.button_pressed = bool(unit.get("auto_skill", false))
	auto.custom_minimum_size = Vector2(78, 50) * UI_SCALE
	auto.add_theme_font_size_override("font_size", int(10 * UI_SCALE))
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
	var ticks := maxi(int(result.get("ticks", 1)), 1)
	var settlement := _execute_command(
		"settle_battle",
		{
			"battle_id": battle_id,
			"stage_id": stage_id,
			"outcome": outcome,
			"ticks": ticks,
			"deployed_unit_ids": (result.get("deployed_unit_ids", []) as Array).duplicate(),
			"dead_unit_ids": (result.get("dead_unit_ids", []) as Array).duplicate(),
		},
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
	var outcome := String(result.get("outcome", "defeat"))
	var victory := outcome == "victory"
	var safe := _safe_margin()
	ui_root.add_child(safe)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(center)
	var panel := _accent_panel(COLOR_PANEL, COLOR_ACCENT if victory else COLOR_DANGER, 14)
	panel.name = "ResultPanel"
	panel.custom_minimum_size = Vector2(620, 290)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var stage_id := String(settlement.get("stage_id", result.get("stage_id", selected_stage_id)))
	var stage_config := StageCatalog.stage(stage_id)
	column.add_child(_label("目标已摧毁" if victory else "攻城失败", 28, COLOR_ACCENT if victory else COLOR_DANGER))
	column.add_child(_label(String(stage_config.get("display_name", stage_id)), 15, COLOR_MUTED))
	var result_team_power := CombatPower.formation_power(game.current_state())
	var result_recommended_power := int(stage_config.get("recommended_power", 0))
	var result_readiness := CombatPower.readiness(
		result_team_power,
		result_recommended_power,
		int(stage_config.get("minimum_power", result_recommended_power))
	)
	var result_power_label := _label(
		"军团战力 %d / 本关推荐 %d · %s" % [
			result_team_power,
			result_recommended_power,
			CombatPower.readiness_label(result_readiness),
		],
		14,
		_readiness_color(result_readiness)
	)
	result_power_label.name = "ResultPowerLabel"
	column.add_child(result_power_label)
	var report_title := _label("战况", 18, COLOR_PRIMARY)
	report_title.name = "ResultReportTitle"
	column.add_child(report_title)
	var cannon_report := _label(_cannon_result_report_text(result, settlement), 13, COLOR_ACCENT)
	cannon_report.name = "ResultCannonReportLabel"
	column.add_child(cannon_report)
	var reason := String(result.get("reason", ""))
	var result_stage_config := StageCatalog.stage(String(result.get("stage_id", selected_stage_id)))
	var result_stage_count := maxi(1, (result_stage_config.get("stage_names", []) as Array).size())
	var reason_text: String = String({
		"core_destroyed": "目标已经摧毁",
		"main_squad_defeated": "出征军团全部阵亡",
		"invalid_formation": "出征阵容必须包含 1–6 名真实单位",
		"player_retreat": "已主动撤退并保全幸存单位",
	}.get(reason, reason))
	column.add_child(_label(
		"到达阶段 %d/%d · 摧毁结构 %d · %s" % [
			clampi(int(result.get("stage_reached", 0)) + 1, 1, result_stage_count),
			result_stage_count,
			int(result.get("structures_destroyed", 0)),
			reason_text,
		],
		14,
		COLOR_TEXT
	))
	var gman_max_hp := int(result.get("gman_max_hp", 0))
	if gman_max_hp > 0:
		var gman_hp := maxi(0, int(result.get("gman_hp", 0)))
		var gman_hp_percent := clampi(int(round(float(gman_hp) * 100.0 / float(gman_max_hp))), 0, 100)
		var gman_status := "Gman 已阵亡" if gman_hp == 0 else "Gman 剩余生命 %d%%" % gman_hp_percent
		var gman_status_label := _label(gman_status, 14, COLOR_DANGER if gman_hp_percent <= 35 else COLOR_PRIMARY)
		gman_status_label.name = "ResultGmanHealthLabel"
		column.add_child(gman_status_label)
	var reward: Dictionary = settlement.get("reward", {}) as Dictionary
	var reward_tier := String(settlement.get("reward_tier", ""))
	var reward_tier_text: String = String({
		"first_victory": "首次通关全额",
		"repeat_victory": "重复通关30%",
		"first_defeat": "失败零奖励",
		"repeat_defeat": "失败零奖励",
	}.get(reward_tier, ""))
	var result_reward_label := _label(
		"奖励%s：马桶币%d 瓷%d 零%d 泥%d" % [
			" · %s" % reward_tier_text if not String(reward_tier_text).is_empty() else "",
			int(reward.get("gold", 0)),
			int(reward.get("porcelain", 0)),
			int(reward.get("parts", 0)),
			int(reward.get("sludge", 0)),
		],
		17,
		COLOR_PRIMARY if victory else COLOR_MUTED
	)
	result_reward_label.name = "ResultRewardLabel"
	column.add_child(result_reward_label)
	var damage_manifest := settlement.get("damage_manifest", {}) as Dictionary
	var disabled_count := 0
	var total_readiness_loss := 0
	for damage_value in damage_manifest.values():
		var damage := damage_value as Dictionary
		total_readiness_loss += int(damage.get("loss", 0))
		if bool(damage.get("disabled", false)):
			disabled_count += 1
	column.add_child(_label(
		"永久角色 %d · 战备损失 %d · 失能 %d（可维修）" % [
			(settlement.get("surviving_unit_ids", []) as Array).size(),
			total_readiness_loss,
			disabled_count,
		],
		14,
		COLOR_DANGER if disabled_count > 0 else COLOR_PRIMARY
	))
	if not victory:
		var recommended_action := _derive_next_action(game.current_state())
		if stage_id == "stage_1_4":
			var failure_debrief := _accent_panel(Color(0.16, 0.075, 0.06, 0.96), COLOR_DANGER, 7)
			failure_debrief.name = "FailureDebriefPanel"
			failure_debrief.add_child(_label("失败复盘：Gman 承受了集中炮火，但首座炮台已受损——补充前排即可突破。", 12, COLOR_TEXT))
			column.add_child(failure_debrief)
		column.add_child(_label(_failure_advice(result, recommended_action), 13, COLOR_ACCENT))
	if victory and stage_id == "stage_5_5":
		column.add_child(_label("伪胜警报：联盟主力正在沿大道反推。科学家已启动核心数据库撤离协议……", 14, COLOR_DANGER))
		column.add_child(_label("第一幕完成。型号图纸、型号科技与货币账本永久保留；单位库存按实际幸存结果保留。", 13, COLOR_TEXT))
	elif victory:
		var next_stage := String(settlement.get("next_stage_id", StageCatalog.next_stage_id(stage_id)))
		if not next_stage.is_empty():
			var next_config := StageCatalog.stage(next_stage)
			column.add_child(_label("下一关：%s" % String(next_config.get("display_name", next_stage)), 13, COLOR_PRIMARY))
	var unlocked: Array = settlement.get("unlocked_blueprints", [])
	if not unlocked.is_empty():
		column.add_child(_label("缴获设计图 · 需要马桶博士研究", 12, COLOR_ACCENT))
	if not error_message.is_empty():
		column.add_child(_label(error_message, 14, COLOR_DANGER))
	_build_result_actions(column, victory, stage_id)


func _build_result_actions(column: VBoxContainer, victory: bool, stage_id: String) -> void:
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	var onboarding := OnboardingService.snapshot(game.current_state())
	if bool(onboarding.get("completed", false)) and not bool(onboarding.get("claimed", false)):
		var claim_onboarding := _button("领取任务奖励", COLOR_PRIMARY, Vector2(150, 44), 14)
		claim_onboarding.name = "ResultClaimOnboardingButton"
		claim_onboarding.pressed.connect(_claim_current_onboarding_task)
		actions.add_child(claim_onboarding)
	elif String(onboarding.get("target", "")) == "repair":
		var repair_action := _button(String(onboarding.get("cta_label", "战后维修")), COLOR_PRIMARY, Vector2(130, 44), 14)
		repair_action.name = "ResultRepairButton"
		repair_action.pressed.connect(_show_factory)
		actions.add_child(repair_action)
	if victory and stage_id == "stage_1_4":
		var research := _button("研究装甲兵", COLOR_PRIMARY, Vector2(132, 44), 14)
		research.name = "ResultResearchArmorButton"
		research.pressed.connect(_show_factory)
		actions.add_child(research)
		var challenge := _button("挑战 1-5", COLOR_ACCENT, Vector2(118, 44), 14)
		challenge.name = "ResultChallengeNextButton"
		challenge.pressed.connect(func() -> void:
			selected_stage_id = "stage_1_5"
			_show_expedition()
		)
		actions.add_child(challenge)
	elif victory:
		var next_stage_id := StageCatalog.next_stage_id(stage_id)
		var next_action := _derive_next_action(game.current_state())
		var next_label := "继续 %s" % String(StageCatalog.stage(next_stage_id).get("display_name", next_stage_id)) if not next_stage_id.is_empty() else String(next_action.get("cta_label", "继续"))
		var next := _button(next_label, COLOR_PRIMARY, Vector2(180, 44), 14)
		next.name = "ResultRecommendedButton"
		if not next_stage_id.is_empty():
			next.pressed.connect(func() -> void:
				selected_stage_id = next_stage_id
				_show_expedition()
			)
		else:
			next.pressed.connect(func() -> void: _navigate_objective_action(next_action))
		actions.add_child(next)
	else:
		var recommended_action := _derive_next_action(game.current_state())
		var recommended := _button(String(recommended_action.get("cta_label", "继续")), COLOR_PRIMARY, Vector2(150, 44), 14)
		recommended.name = "ResultRecommendedButton"
		recommended.pressed.connect(func() -> void: _navigate_objective_action(recommended_action))
		actions.add_child(recommended)
	var current_state: RefCounted = game.current_state()
	if current_state.formation.hero_ids().size() < 6 and current_state.roster.size() > current_state.formation.hero_ids().size():
		var refill := _button("一键补位", COLOR_ACCENT, Vector2(110, 44), 14)
		refill.name = "ResultRefillButton"
		refill.pressed.connect(_refill_formation)
		actions.add_child(refill)
	if current_state.roster.is_empty():
		var recover := _button("回收废料", COLOR_PRIMARY, Vector2(110, 44), 14)
		recover.name = "ResultScrapRecoveryButton"
		recover.pressed.connect(_claim_scrap_recovery_ui)
		actions.add_child(recover)
	var camp := _button("营地", COLOR_PANEL_ALT, Vector2(90, 44), 14)
	camp.name = "ResultCampButton"
	camp.pressed.connect(_show_camp)
	actions.add_child(camp)


func _claim_scrap_recovery_ui() -> void:
	var result := _execute_command("claim_scrap_recovery", {}, "")
	if bool(result.get("ok", false)):
		_show_factory()
		_show_notice("废料线已补足一名基础冲锋单位的制造材料。")
		return
	_show_notice("暂不能回收废料：%s" % String(result.get("error", "UNKNOWN")))


func _failure_advice(result: Dictionary, action: Dictionary = {}) -> String:
	var reason := String(result.get("reason", ""))
	var stage_reached := int(result.get("stage_reached", 0))
	var next_text := "下一步：%s" % String(action.get("title", "回营地调整"))
	if String(result.get("stage_id", "")) == "stage_1_4":
		return "Gman 独自承受了炮台持续集火；受损炮台证明只差援军。%s" % next_text
	var stage_config := StageCatalog.stage(String(result.get("stage_id", StageCatalog.DEFAULT_STAGE_ID)))
	var plan := GrowthPlan.for_stage(game.current_state(), stage_config)
	if int(plan.get("power_gap", 0)) > 0:
		return "%s · 当前差 %d 战力，预计投入约 %d 金价值 · %s" % [
			String(plan.get("title", "继续培养")),
			int(plan.get("power_gap", 0)),
			int(plan.get("estimated_gold_value", 0)),
			next_text,
		]
	if stage_reached <= 0:
		return "前排倒得太快 · %s" % next_text
	if stage_reached == 1:
		return "没能突破火力线 · %s" % next_text
	return "没能扛住基地炮击 · %s" % next_text


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
	for slot_index in hero_ids.size():
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
			"speed_milli": int(stats["speed_milli"]),
			"crit_bp": int(stats["crit_bp"]),
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
	var state_before: RefCounted = game.current_state()
	var team_power_before := CombatPower.formation_power(state_before)
	var hero_powers_before := _hero_power_snapshot(state_before)
	command_serial += 1
	var now := Time.get_ticks_msec()
	var command_id := "%s-%d-%d" % [command_type, now, command_serial]
	var key := business_key if not business_key.is_empty() else command_id
	var result: Dictionary = game.execute_command({
		"command_id": command_id,
		"type": command_type,
		"payload": payload,
		"business_key": key,
		"expected_revision": game.current_state().revision,
		"requested_at": int(Time.get_unix_time_from_system()),
	})
	if bool(result.get("ok", false)):
		var state_after: RefCounted = game.current_state()
		var team_power_after := CombatPower.formation_power(state_after)
		var hero_powers_after := _hero_power_snapshot(state_after)
		var feedback_text := _power_feedback_text(
			team_power_before,
			team_power_after,
			hero_powers_before,
			hero_powers_after
		)
		if not feedback_text.is_empty():
			call_deferred("_show_power_change_feedback", feedback_text, team_power_after > team_power_before)
	return result


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


func _show_power_change_feedback(message: String, increased: bool) -> void:
	if ui_root == null:
		return
	var existing := ui_root.get_node_or_null("PowerChangeFeedbackLabel")
	if existing != null:
		existing.free()
	var notice := Label.new()
	notice.name = "PowerChangeFeedbackLabel"
	notice.text = message
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size", int(18 * UI_SCALE))
	notice.add_theme_color_override("font_color", COLOR_PRIMARY if increased else COLOR_ACCENT)
	notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice.position = Vector2(-270, 96)
	notice.custom_minimum_size = Vector2(540, 38)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(notice)
	notice.scale = Vector2(0.88, 0.88)
	notice.pivot_offset = notice.custom_minimum_size * 0.5
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(notice, "scale", Vector2.ONE, 0.18)
	tween.tween_interval(1.65)
	tween.tween_property(notice, "modulate:a", 0.0, 0.35)
	tween.tween_callback(notice.queue_free)


func _hero_power_snapshot(state: RefCounted) -> Dictionary:
	var powers := {}
	for hero in state.roster:
		powers[String(hero.hero_id)] = CombatPower.hero_power(hero)
	return powers


func _power_feedback_text(
	team_before: int,
	team_after: int,
	hero_before: Dictionary,
	hero_after: Dictionary
) -> String:
	var team_delta := team_after - team_before
	if team_delta != 0:
		return "军团战力 %s%d  ·  %d → %d" % [
			"+" if team_delta > 0 else "",
			team_delta,
			team_before,
			team_after,
		]
	var hero_gain := 0
	for hero_id in hero_after:
		hero_gain += maxi(0, int(hero_after[hero_id]) - int(hero_before.get(hero_id, 0)))
	if hero_gain > 0:
		return "单位战力 +%d  ·  当前军团战力 %d" % [hero_gain, team_after]
	return ""


func _power_summary(state: RefCounted) -> Dictionary:
	var stage_id := selected_stage_id
	if not StageCatalog.has_stage(stage_id) or not _stage_is_unlocked(stage_id, state):
		stage_id = String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	if not StageCatalog.has_stage(stage_id):
		stage_id = StageCatalog.DEFAULT_STAGE_ID
	var stage_config := StageCatalog.stage(stage_id)
	var current := CombatPower.formation_power(state)
	var recommended := int(stage_config.get("recommended_power", 0))
	var minimum := int(stage_config.get("minimum_power", recommended))
	return {
		"stage_id": stage_id,
		"current": current,
		"recommended": recommended,
		"readiness": CombatPower.readiness(current, recommended, minimum),
	}


func _readiness_color(readiness: String) -> Color:
	return COLOR_PRIMARY if readiness == "ready" else (COLOR_ACCENT if readiness == "challenge" else COLOR_DANGER)


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
	battle_power_label = null
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
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	var scaled_padding := int(padding * UI_SCALE)
	style.content_margin_left = scaled_padding
	style.content_margin_right = scaled_padding
	style.content_margin_top = scaled_padding
	style.content_margin_bottom = scaled_padding
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = COLOR_STROKE
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _accent_panel(color: Color, accent: Color, padding: int) -> PanelContainer:
	var panel := _panel(color, padding)
	var base := panel.get_theme_stylebox("panel") as StyleBoxFlat
	var style := base.duplicate() as StyleBoxFlat
	style.border_width_left = 4
	style.border_color = accent
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _progress_bar(value: float, maximum: float, color: Color, height: int = 8) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = maximum
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size.y = height * UI_SCALE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#0a1524")
	background.corner_radius_top_left = height
	background.corner_radius_top_right = height
	background.corner_radius_bottom_left = height
	background.corner_radius_bottom_right = height
	var fill := background.duplicate() as StyleBoxFlat
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _notification_summary(now_unix: int = -1) -> Dictionary:
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	return NotificationSummaryScript.derive(game.current_state(), now)


func _attach_notification_badge(target: Control, count: int, badge_name: String) -> Control:
	var badge := NotificationBadgeScript.new()
	badge.name = badge_name
	target.add_child(badge)
	badge.call("set_count", count)
	return badge


func _set_notification_badge(target: Control, count: int, badge_name: String) -> void:
	if target == null:
		return
	var badge := target.get_node_or_null(NodePath(badge_name)) as Control
	if badge == null:
		badge = _attach_notification_badge(target, count, badge_name)
	else:
		badge.call("set_count", count)


func _refresh_visible_notification_badges() -> void:
	if game == null:
		return
	var summary := _notification_summary()
	var factory_button := find_child("CampFactoryButton", true, false) as Control
	var goal_button := find_child("QuestEntryButton", true, false) as Control
	if factory_button != null:
		_set_notification_badge(factory_button, int(summary["factory_ready"]), "FactoryNotificationBadge")
		if int(summary["factory_ready"]) > 0:
			factory_button.visible = true
	if goal_button != null:
		_set_notification_badge(goal_button, int(summary["goal_claimable"]) + WarMeritTrack.claimable_count(game.current_state()), "GoalNotificationBadge")
		if int(summary["goal_claimable"]) > 0:
			goal_button.visible = true


func _button(text: String, color: Color, min_size: Vector2 = Vector2(120, 48), font_size: int = 16) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size * UI_SCALE
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.darkened(0.35) if state_name == "disabled" else color.lightened(0.10 if state_name == "hover" else (-0.08 if state_name == "pressed" else 0.0))
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
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
		elif state_name in ["normal", "hover"]:
			style.border_width_bottom = 2
			style.border_color = color.lightened(0.18)
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
	var skill_view := ActiveSkillCatalog.view(skill_id)
	return String(skill_view.get("short_label", "技"))


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

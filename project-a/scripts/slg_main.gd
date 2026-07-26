extends Node

class PanelVBox:
	extends VBoxContainer

	var panel_style: StyleBox

	func _draw() -> void:
		if panel_style != null:
			panel_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

const StageCatalog := preload("res://game/scripts/domain/content/stage_catalog.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const CombatPower := preload("res://game/scripts/domain/progression/combat_power.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const WarReadinessReport := preload("res://game/scripts/domain/progression/war_readiness_report.gd")
const WarZoneScreenScene := preload("res://game/scenes/screens/war_zone_screen.tscn")
const BattleResultScreenScene := preload("res://game/scenes/screens/battle_result_screen.tscn")
const BattleHudScreenScene := preload("res://game/scenes/screens/battle_hud_screen.tscn")
const LegionScreenScene := preload("res://game/scenes/screens/legion_screen.tscn")
const FactoryScreenScene := preload("res://game/scenes/screens/factory_screen.tscn")
const GoalsScreenScene := preload("res://game/scenes/screens/goals_screen.tscn")
const TitleScreenScene := preload("res://game/scenes/screens/title_screen.tscn")
const SettingsScreenScene := preload("res://game/scenes/screens/settings_screen.tscn")
const HelpScreenScene := preload("res://game/scenes/screens/help_screen.tscn")
const IntelligenceScreenScene := preload("res://game/scenes/screens/intelligence_screen.tscn")
const BlueprintScreenScene := preload("res://game/scenes/screens/blueprint_screen.tscn")
const EpilogueScreenScene := preload("res://game/scenes/screens/epilogue_screen.tscn")
const OnboardingService := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")
const OnboardingCatalog := preload("res://game/scripts/domain/onboarding/onboarding_catalog.gd")
const FactoryCatalog := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const LogisticsService := preload("res://game/scripts/domain/factory/logistics_service.gd")
const AchievementCatalog := preload("res://game/scripts/domain/achievement/achievement_catalog.gd")
const MetaCatalog := preload("res://game/scripts/domain/meta/meta_catalog.gd")
const MetaProgressionService := preload("res://game/scripts/domain/meta/meta_progression_service.gd")
const BattleWorldScript := preload("res://game/scripts/presentation_3d/battle_world.gd")
const SettingsStoreScript := preload("res://game/scripts/platform/settings_store.gd")
const WebRuntimeScript := preload("res://game/scripts/platform/web_runtime.gd")
const MobileViewportAdapterScript := preload("res://game/scripts/platform/mobile_viewport_adapter.gd")
const LocalPlaytestJournalScript := preload("res://game/scripts/platform/local_playtest_journal.gd")
const AudioDirectorScript := preload("res://game/scripts/presentation/audio_director.gd")
const CJKFont := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

enum Screen { BOOT, TITLE, SETTINGS, BASE, MAP, LEGION, GOALS, INTELLIGENCE, BATTLE, RESULT, EPILOGUE, HELP, BLUEPRINTS }

const BG := Color("#070b0f")
const PANEL := Color("#12171c")
const PANEL_2 := Color("#1a2228")
const LINE := Color("#3b454b")
const TEXT := Color("#f3ead8")
const MUTED := Color("#9c9990")
const CYAN := Color("#58c9c2")
const GOLD := Color("#e5a84b")
const RED := Color("#d95c4f")
const GREEN := Color("#78b982")
const EMBER := Color("#b65f35")
const FACILITY_NAMES := {
	"command_center": "指挥中心",
	"porcelain_plant": "陶瓷厂",
	"parts_workshop": "零件车间",
	"energy_station": "能源站",
	"repair_center": "训练中心",
	"research_lab": "研究所",
}
const FACILITY_COPY := {
	"command_center": "决定全局等级与城区权限",
	"porcelain_plant": "持续生产陶瓷，用于角色与设施升级",
	"parts_workshop": "加工机械零件，用于角色与设施升级",
	"energy_station": "产生污水能源，驱动培养与研究",
	"repair_center": "强化角色训练效率与成长规划",
	"research_lab": "消耗工业技术，解锁技能与星级节点",
}
const FACTORY_RESOURCE_NAMES := {
	"porcelain_plant": "陶瓷",
	"parts_workshop": "机械零件",
	"energy_station": "污水能源",
}
const FACTORY_BUILDING_POSITIONS := {
	"command_center": Vector3(0.0, 0.0, -1.2),
	"porcelain_plant": Vector3(-5.0, 0.0, -2.5),
	"parts_workshop": Vector3(5.0, 0.0, -2.3),
	"energy_station": Vector3(-5.0, 0.0, 2.8),
	"repair_center": Vector3(0.0, 0.0, 3.4),
	"research_lab": Vector3(5.0, 0.0, 2.7),
}
const FACTORY_GRID_RADIUS := 2
const FACTORY_GRID_SPACING := 3.05
const FACTORY_CAMERA_DRAG_THRESHOLD := 10.0
const FACTORY_CAMERA_ORBIT_SENSITIVITY := Vector2(0.008, 0.006)
const FACTORY_CAMERA_MIN_PITCH := deg_to_rad(24.0)
const FACTORY_CAMERA_MAX_PITCH := deg_to_rad(68.0)
const FACTORY_CAMERA_DISTANCE := 21.26
const FACTORY_CAMERA_MIN_SIZE := 12.0
const FACTORY_CAMERA_MAX_SIZE := 23.0
const FACTORY_BUILDING_COLORS := {
	"command_center": Color("#3b8e94"),
	"porcelain_plant": Color("#b9b5aa"),
	"parts_workshop": Color("#9a603b"),
	"energy_station": Color("#567d58"),
	"repair_center": Color("#9b4942"),
	"research_lab": Color("#66577f"),
}

@onready var world_host: Node3D = $WorldHost
@onready var ui_root: Control = $Interface/UIRoot

var game: Node
var screen: Screen = Screen.BOOT
var selected_stage_id: String = StageCatalog.DEFAULT_STAGE_ID
var selected_chapter: int = 1
var battle_world: Node3D
var active_battle_id: String = ""
var active_battle_stage: String = ""
var last_settlement: Dictionary = {}
var command_serial: int = 0
var goals_tab: String = "action"
var legion_tab: String = "formation"
var blueprint_branch: String = "ordinary"
var factory_hud_panel: String = "mission"
var ui_scroll_positions: Dictionary = {}
var ui_rebuild_generation: int = 0
var last_recruit_results: Array[Dictionary] = []
var last_research_breakthrough_results: Array[Dictionary] = []
var formation_edit_slot: String = ""
var toast: Label
var factory_camera: Camera3D
var selected_facility_id: String = "command_center"
var construction_facility_id: String = ""
var construction_cell: Vector2i = Vector2i(999, 999)
var factory_camera_yaw := 0.0
var factory_camera_pitch := deg_to_rad(41.2)
var factory_camera_size := 17.5
var factory_pointer_active := false
var factory_pointer_index := -1
var factory_pointer_start := Vector2.ZERO
var factory_pointer_last := Vector2.ZERO
var factory_pointer_dragged := false
var factory_touch_points: Dictionary = {}
var factory_pinch_active := false
var factory_pinch_distance := 0.0
var settings_store: RefCounted
var web_runtime: Node
var mobile_viewport: Node
var active_safe_margin: MarginContainer
var playtest_journal: RefCounted
var audio_director: Node
var settings_return_screen: Screen = Screen.TITLE
var help_return_screen: Screen = Screen.TITLE
var local_save_delete_armed: bool = false
var pending_save_import_text: String = ""
var pending_save_import_summary: Dictionary = {}
var battle_is_paused: bool = false
var battle_pause_button: Button
var battle_pause_overlay: Control
var battle_pause_resume_button: Button
var battle_status_label: Label
var battle_skill_buttons: Dictionary = {}
var battle_unit_hud: Dictionary = {}
var battle_auto_button: Button
var battle_hud_screen: BattleHudScreen
var battle_manual_skills: bool = false
var last_battle_runtime_result: Dictionary = {}
var pending_battle_settlement_payload: Dictionary = {}
var orientation_gate: Control
var orientation_gate_active: bool = false
var orientation_paused_battle: bool = false
var active_layout_profile: String = ""


func _ready() -> void:
	settings_store = SettingsStoreScript.new()
	settings_store.load_settings()
	web_runtime = WebRuntimeScript.new()
	web_runtime.name = "WebRuntime"
	add_child(web_runtime)
	web_runtime.runtime_state_changed.connect(_on_runtime_state_changed)
	web_runtime.text_file_imported.connect(_on_save_import_file_loaded)
	web_runtime.text_file_import_failed.connect(_on_save_import_file_failed)
	mobile_viewport = MobileViewportAdapterScript.new()
	mobile_viewport.name = "MobileViewportAdapter"
	add_child(mobile_viewport)
	mobile_viewport.layout_changed.connect(_on_mobile_layout_changed)
	playtest_journal = LocalPlaytestJournalScript.new()
	playtest_journal.set_enabled(
		settings_store.local_playtest_logging,
		String(ProjectSettings.get_setting("application/config/version", "dev"))
	)
	audio_director = AudioDirectorScript.new()
	audio_director.name = "AudioDirector"
	add_child(audio_director)
	_apply_settings_to_runtime()
	game = get_node_or_null("/root/Game")
	ui_root.theme = _theme()
	_build_orientation_gate()
	get_viewport().size_changed.connect(mobile_viewport.refresh)
	mobile_viewport.refresh(true)
	_refresh_orientation_gate()
	if game == null:
		_show_fatal("游戏服务未加载")
		return
	if not game.bootstrap_completed.is_connected(_on_bootstrap):
		game.bootstrap_completed.connect(_on_bootstrap)
	_on_bootstrap(String(game.bootstrap_status))


func _input(event: InputEvent) -> void:
	if orientation_gate_active:
		get_viewport().set_input_as_handled()
		return
	# Modal pause controls may consume ui_cancel before _unhandled_input.
	# Own this semantic action at the UI boundary so Escape/Android Back always toggles once.
	if screen == Screen.BATTLE and _is_battle_pause_event(event):
		_set_battle_paused(not battle_is_paused)
		get_viewport().set_input_as_handled()
		return
	if screen != Screen.BASE or factory_camera == null or not is_instance_valid(factory_camera):
		return
	if _handle_factory_pointer(event):
		get_viewport().set_input_as_handled()
	return


func _handle_factory_pointer(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and mouse_event.pressed:
			if not _is_factory_pointer_area(mouse_event.position):
				return false
			_zoom_factory_camera(0.9 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1)
			return true
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		if mouse_event.pressed:
			if not _is_factory_pointer_area(mouse_event.position):
				return false
			_begin_factory_pointer(mouse_event.position, -1)
			return true
		if not factory_pointer_active or factory_pointer_index != -1:
			return false
		_finish_factory_pointer(mouse_event.position)
		return true
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if not factory_pointer_active or factory_pointer_index != -1:
			return false
		_drag_factory_pointer(mouse_motion.position, mouse_motion.relative)
		return true
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			if not _is_factory_pointer_area(touch_event.position):
				return false
			factory_touch_points[touch_event.index] = touch_event.position
			if factory_touch_points.size() == 1:
				_begin_factory_pointer(touch_event.position, touch_event.index)
			elif factory_touch_points.size() == 2:
				factory_pinch_active = true
				factory_pointer_dragged = true
				factory_pinch_distance = _factory_touch_distance()
			return true
		if not factory_touch_points.has(touch_event.index):
			return false
		factory_touch_points.erase(touch_event.index)
		if factory_pinch_active:
			if factory_touch_points.is_empty():
				factory_pinch_active = false
				factory_pinch_distance = 0.0
				_reset_factory_pointer()
			return true
		if factory_pointer_active and factory_pointer_index == touch_event.index:
			_finish_factory_pointer(touch_event.position)
		return true
	if event is InputEventScreenDrag:
		var screen_drag := event as InputEventScreenDrag
		if not factory_touch_points.has(screen_drag.index):
			return false
		factory_touch_points[screen_drag.index] = screen_drag.position
		if factory_pinch_active and factory_touch_points.size() >= 2:
			var next_distance := _factory_touch_distance()
			if factory_pinch_distance > 0.0 and next_distance > 0.0:
				_zoom_factory_camera(factory_pinch_distance / next_distance)
			factory_pinch_distance = next_distance
			return true
		if not factory_pointer_active or factory_pointer_index != screen_drag.index:
			return false
		_drag_factory_pointer(screen_drag.position, screen_drag.relative)
		return true
	return false


func _is_factory_pointer_area(pointer_position: Vector2) -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return (
		pointer_position.x <= viewport_size.x * 0.62
		and pointer_position.y >= 54.0
		and pointer_position.y <= viewport_size.y - 54.0
	)


func _begin_factory_pointer(pointer_position: Vector2, pointer_index: int) -> void:
	factory_pointer_active = true
	factory_pointer_index = pointer_index
	factory_pointer_start = pointer_position
	factory_pointer_last = pointer_position
	factory_pointer_dragged = false


func _drag_factory_pointer(pointer_position: Vector2, relative: Vector2) -> void:
	if not factory_pointer_dragged and pointer_position.distance_to(factory_pointer_start) >= FACTORY_CAMERA_DRAG_THRESHOLD:
		factory_pointer_dragged = true
	if factory_pointer_dragged:
		_orbit_factory_camera(relative)
	factory_pointer_last = pointer_position


func _finish_factory_pointer(pointer_position: Vector2) -> void:
	if not factory_pointer_dragged and _is_factory_pointer_area(pointer_position):
		if not construction_facility_id.is_empty():
			var grid_cell := _factory_grid_cell_at(pointer_position)
			if grid_cell.x != 999:
				construction_cell = grid_cell
				_show_base()
		else:
			var collider := _factory_building_at(pointer_position)
			if collider != null:
				var facility_id := String(collider.get_meta("facility_id", ""))
				if not facility_id.is_empty():
					_activate_factory_building(facility_id)
	_reset_factory_pointer()


func _reset_factory_pointer() -> void:
	factory_pointer_active = false
	factory_pointer_index = -1
	factory_pointer_dragged = false


func _factory_touch_distance() -> float:
	var indices := factory_touch_points.keys()
	if indices.size() < 2:
		return 0.0
	return (factory_touch_points[indices[0]] as Vector2).distance_to(
		factory_touch_points[indices[1]] as Vector2
	)


func _zoom_factory_camera(factor: float) -> void:
	factory_camera_size = clampf(
		factory_camera_size * factor,
		FACTORY_CAMERA_MIN_SIZE,
		FACTORY_CAMERA_MAX_SIZE
	)
	if factory_camera != null and is_instance_valid(factory_camera):
		factory_camera.size = factory_camera_size


func _orbit_factory_camera(screen_delta: Vector2) -> void:
	if factory_camera == null or not is_instance_valid(factory_camera):
		return
	factory_camera_yaw = wrapf(
		factory_camera_yaw - screen_delta.x * FACTORY_CAMERA_ORBIT_SENSITIVITY.x,
		-PI,
		PI
	)
	factory_camera_pitch = clampf(
		factory_camera_pitch + screen_delta.y * FACTORY_CAMERA_ORBIT_SENSITIVITY.y,
		FACTORY_CAMERA_MIN_PITCH,
		FACTORY_CAMERA_MAX_PITCH
	)
	_apply_factory_camera_orbit()


func _apply_factory_camera_orbit() -> void:
	if factory_camera == null or not is_instance_valid(factory_camera):
		return
	var horizontal_distance := cos(factory_camera_pitch) * FACTORY_CAMERA_DISTANCE
	var camera_position := Vector3(
		sin(factory_camera_yaw) * horizontal_distance,
		sin(factory_camera_pitch) * FACTORY_CAMERA_DISTANCE,
		cos(factory_camera_yaw) * horizontal_distance
	)
	factory_camera.look_at_from_position(camera_position, Vector3(0.0, 0.0, 0.3))


func _is_battle_pause_event(event: InputEvent) -> bool:
	if event is InputEventAction:
		var action_event := event as InputEventAction
		return action_event.pressed and action_event.action == &"ui_cancel"
	return event.is_action_pressed("ui_cancel")


func _factory_building_at(screen_position: Vector2) -> CollisionObject3D:
	var origin := factory_camera.project_ray_origin(screen_position)
	var direction := factory_camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 80.0)
	query.collision_mask = 8
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := factory_camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider") as CollisionObject3D


func _factory_grid_cell_at(screen_position: Vector2) -> Vector2i:
	var origin := factory_camera.project_ray_origin(screen_position)
	var direction := factory_camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 80.0)
	query.collision_mask = 16
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := factory_camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return Vector2i(999, 999)
	var collider := result.get("collider") as CollisionObject3D
	if collider == null or not collider.has_meta("grid_cell"):
		return Vector2i(999, 999)
	return collider.get_meta("grid_cell") as Vector2i


func _activate_factory_building(facility_id: String) -> void:
	if not FACILITY_NAMES.has(facility_id):
		return
	selected_facility_id = facility_id
	factory_hud_panel = "facility"
	if int(game.current_state().factory.facilities.get(facility_id, 0)) <= 0:
		_show_base()
	elif FACTORY_RESOURCE_NAMES.has(facility_id):
		_claim_facility_output(facility_id)
	else:
		_show_base()


func _on_bootstrap(status: String) -> void:
	if status in ["created", "loaded"]:
		_migrate_visible_contract()
		_show_title()
	elif status != "not_started":
		_show_fatal("存档启动失败：%s" % status)


func _migrate_visible_contract() -> void:
	# 启动服务已经执行合同迁移；这里保留一道展示层保险，避免测试或热重载绕开启动门禁。
	var state: RefCounted = game.current_state()
	if state == null:
		return
	if String(state.content_version) == "toilet-factory-slg-v2":
		for hero in state.roster:
			if String(hero.archetype_id) == "gman":
				return
	game.reset_game(20260726, int(Time.get_unix_time_from_system()))


func _show_title() -> void:
	screen = Screen.TITLE
	local_save_delete_armed = false
	_clear()
	_build_factory_world()
	var shell := _shell("灰镜战线", "地下工厂信号已恢复", true)
	shell.name = "TitleShell"
	var title_screen := TitleScreenScene.instantiate() as Control
	title_screen.call("configure", _title_progress_snapshot())
	title_screen.connect("action_requested", _on_title_action_requested)
	shell.add_child(title_screen)


func _on_title_action_requested(action_id: String) -> void:
	_play_ui_click()
	match action_id:
		"primary":
			_show_base()
		"settings":
			_show_settings(Screen.TITLE)
		"help":
			_show_help(Screen.TITLE)


func _title_progress_snapshot() -> Dictionary:
	var state: RefCounted = game.current_state()
	var cleared_values: Array = state.stage_progress.get("cleared_stages", [])
	var cleared_count := 0
	for stage_id in StageCatalog.ACT1_STAGE_IDS:
		if cleared_values.has(stage_id):
			cleared_count += 1
	var hero_count := int(state.roster.size())
	var highest := String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	var objective := ""
	var primary_label := ""
	if cleared_count <= 0:
		primary_label = "唤醒 Gman"
		objective = "联盟尚未发现这座工厂"
	elif cleared_count >= StageCatalog.ACT1_STAGE_IDS.size():
		primary_label = "重返前线"
		objective = "灰镜防线已崩溃，战争仍未结束"
	else:
		primary_label = "返回指挥室"
		var next_config := StageCatalog.stage(highest)
		objective = "前线等待命令 · %s" % String(next_config.get("display_name", highest))
	return {
		"primary_label": primary_label,
		"summary": "已夺回 %d 座城镇 · %d 名战士仍在回应" % [cleared_count, hero_count],
		"objective": objective,
	}


func _show_settings(return_screen: Screen = Screen.BASE) -> void:
	settings_return_screen = return_screen
	screen = Screen.SETTINGS
	_clear()
	var shell := _shell("设置", "音频、画面辅助与战斗偏好")
	shell.name = "SettingsShell"
	var settings_screen := SettingsScreenScene.instantiate() as Control
	settings_screen.call("configure", _settings_view())
	settings_screen.connect("setting_changed", _on_settings_setting_changed)
	settings_screen.connect("action_requested", _on_settings_action_requested)
	shell.add_child(settings_screen)
	return


func _settings_view() -> Dictionary:
	var persistence := web_runtime.platform_capabilities() as Dictionary
	var persistent := bool(persistence.get("userfs_persistent", false))
	var journal_summary := playtest_journal.summary() as Dictionary
	var has_import := not pending_save_import_text.is_empty()
	var import_copy := ""
	if has_import:
		import_copy = "待导入：%d 城 · %d 名英雄 · 修订 %d（再次点击确认）" % [
			int(pending_save_import_summary.get("captured_cities", 0)),
			int(pending_save_import_summary.get("hero_count", 0)),
			int(pending_save_import_summary.get("revision", 0)),
		]
	return {
		"master_volume": settings_store.master_volume,
		"effects_quality": settings_store.effects_quality,
		"reduced_motion": settings_store.reduced_motion,
		"global_auto_skill": settings_store.global_auto_skill,
		"local_playtest_logging": settings_store.local_playtest_logging,
		"playtest_status": "首章里程碑 %d/%d · %d 条本地事件 · %d 分钟\n最长非战斗停滞 %d 秒 · 不含设备或账号标识" % [
			int(journal_summary.get("milestone_count", 0)),
			int(journal_summary.get("milestone_total", 8)),
			int(journal_summary.get("event_count", 0)),
			int(journal_summary.get("duration_seconds", 0)) / 60,
			int(journal_summary.get("longest_non_battle_gap_seconds", 0)),
		],
		"storage_persistent": persistent,
		"persistence_copy": (
			"浏览器存储当前可持久化；仍建议定期下载备份。"
			if persistent
			else "浏览器未确认持久存储，请立即下载备份，避免清理站点数据后丢失进度。"
		),
		"has_import_preview": has_import,
		"import_preview": import_copy,
		"delete_armed": local_save_delete_armed,
	}


func _on_settings_setting_changed(setting_id: String, value: Variant) -> void:
	match setting_id:
		"master_volume":
			settings_store.set_master_volume(float(value))
		"effects_quality":
			settings_store.set_effects_quality(String(value))
		"reduced_motion":
			settings_store.set_reduced_motion(bool(value))
		"global_auto_skill":
			settings_store.set_global_auto_skill(bool(value))
		"local_playtest_logging":
			_set_local_playtest_logging(bool(value))
			return
	_apply_settings_to_runtime()


func _on_settings_action_requested(action_id: String) -> void:
	_play_ui_click()
	match action_id:
		"help":
			_show_help(Screen.SETTINGS)
		"export_playtest":
			_export_local_playtest_report()
		"clear_playtest":
			_clear_local_playtest_report()
		"export_save":
			_export_local_save_backup()
		"import_save":
			_request_local_save_import()
		"delete_save":
			_request_delete_local_save()
		"save":
			_save_settings_from_ui()
		"back":
			_return_from_settings()



func _show_help(return_screen: Screen = Screen.TITLE) -> void:
	help_return_screen = return_screen
	screen = Screen.HELP
	_clear()
	var shell := _shell("玩法说明", "快速了解工厂、攻城、操作与本地数据")
	shell.name = "HelpShell"
	var help_screen := HelpScreenScene.instantiate() as Control
	help_screen.call("configure", {
		"version": String(ProjectSettings.get_setting("application/config/version", "dev")),
	})
	help_screen.connect("back_requested", _return_from_help)
	shell.add_child(help_screen)
	return



func _return_from_help() -> void:
	if help_return_screen == Screen.SETTINGS:
		_show_settings(settings_return_screen)
	else:
		_show_title()


func _settings_toggle(label_text: String, node_name: String, enabled: bool, callback: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 44
	var row_label := _label(label_text, 15, TEXT)
	row_label.custom_minimum_size.x = 110
	row.add_child(row_label)
	var toggle := CheckButton.new()
	toggle.name = node_name
	toggle.button_pressed = enabled
	toggle.custom_minimum_size = Vector2(180, 44)
	toggle.toggled.connect(func(value: bool) -> void: callback.call(value))
	row.add_child(toggle)
	return row


func _save_settings_from_ui() -> void:
	_apply_settings_to_runtime()
	_notify("设置已保存" if settings_store.save_settings() else "设置保存失败")


func _set_local_playtest_logging(enabled: bool) -> void:
	settings_store.set_local_playtest_logging(enabled)
	var persisted: bool = settings_store.save_settings()
	var journal_ready: bool = playtest_journal.set_enabled(
		enabled,
		String(ProjectSettings.get_setting("application/config/version", "dev"))
	)
	if not persisted or not journal_ready:
		_notify("试玩记录设置保存失败")
	call_deferred("_show_settings", settings_return_screen)


func _export_local_playtest_report() -> void:
	var result := playtest_journal.export_report() as Dictionary
	if not bool(result.get("ok", false)):
		_notify("试玩报告为空或生成失败")
		return
	var version := String(ProjectSettings.get_setting("application/config/version", "dev")).replace(".", "-")
	if not web_runtime.download_text_file("toilet-factory-playtest-%s.json" % version, String(result.get("text", ""))):
		_notify("当前平台无法下载试玩报告")
		return
	_notify("试玩报告已下载；文件只保存在你的设备")


func _clear_local_playtest_report() -> void:
	playtest_journal.clear()
	playtest_journal.set_enabled(
		true,
		String(ProjectSettings.get_setting("application/config/version", "dev"))
	)
	call_deferred("_show_settings", settings_return_screen)


func _return_from_settings() -> void:
	local_save_delete_armed = false
	pending_save_import_text = ""
	pending_save_import_summary.clear()
	if settings_return_screen == Screen.TITLE:
		_show_title()
	else:
		_show_base()


func _request_delete_local_save() -> void:
	if not local_save_delete_armed:
		local_save_delete_armed = true
		_show_settings(settings_return_screen)
		return
	local_save_delete_armed = false
	var result: Dictionary = game.reset_game(20260726, int(Time.get_unix_time_from_system()))
	if not bool(result.get("ok", false)):
		_notify("删除存档失败")
		return
	selected_stage_id = StageCatalog.DEFAULT_STAGE_ID
	selected_chapter = 1
	_show_title()


func _export_local_save_backup() -> void:
	var result: Dictionary = game.export_save_backup()
	if not bool(result.get("ok", false)):
		_notify("备份生成失败：%s" % String(result.get("error", "UNKNOWN")))
		return
	var state: RefCounted = game.current_state()
	var filename := "toilet-factory-save-r%d.json" % int(state.revision)
	if not web_runtime.download_text_file(filename, String(result.get("text", ""))):
		_notify("当前平台无法下载备份")
		return
	_notify("存档备份已下载")


func _request_local_save_import() -> void:
	if pending_save_import_text.is_empty():
		if not web_runtime.request_text_file_import():
			_notify("当前平台无法选择备份文件")
		return
		_notify("请选择 JSON 存档备份")
		return
	var result: Dictionary = game.restore_save_import(pending_save_import_text)
	if not bool(result.get("ok", false)):
		pending_save_import_text = ""
		pending_save_import_summary.clear()
		_show_settings(settings_return_screen)
		_notify("恢复失败：%s" % String(result.get("error", "UNKNOWN")))
		return
	pending_save_import_text = ""
	pending_save_import_summary.clear()
	selected_stage_id = StageCatalog.DEFAULT_STAGE_ID
	selected_chapter = 1
	_show_title()
	_notify("存档已恢复：%d 城 · %d 名英雄" % [
		int(result.get("captured_cities", 0)),
		int(result.get("hero_count", 0)),
	])


func _on_save_import_file_loaded(text: String) -> void:
	var preview: Dictionary = game.preview_save_import(text)
	if not bool(preview.get("ok", false)):
		pending_save_import_text = ""
		pending_save_import_summary.clear()
		_notify("备份无效：%s" % String(preview.get("error", "UNKNOWN")))
		return
	pending_save_import_text = text
	pending_save_import_summary = preview.duplicate()
	pending_save_import_summary.erase("state")
	_show_settings(settings_return_screen)


func _on_save_import_file_failed(error: String) -> void:
	_notify("读取备份失败：%s" % error)


func _apply_settings_to_runtime() -> void:
	if settings_store == null:
		return
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		var ratio := float(settings_store.master_volume) / 100.0
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(0.0001, ratio)))
		AudioServer.set_bus_mute(master_bus, settings_store.master_volume <= 0)
	if battle_world != null and is_instance_valid(battle_world):
		battle_world.configure_presentation(settings_store.effects_quality, settings_store.reduced_motion)


func _show_base() -> void:
	screen = Screen.BASE
	_clear()
	_build_factory_world()
	var shell := _shell("灰镜地下工厂", "战火仍在地表燃烧", true)
	var factory := FactoryScreenScene.instantiate() as FactoryScreen
	factory.panel_selected.connect(func(_panel_id: String) -> void: _play_ui_click())
	factory.panel_selected.connect(_set_factory_hud_panel)
	factory.action_requested.connect(func(_action_id: String, _payload: Dictionary) -> void: _play_ui_click())
	factory.action_requested.connect(_on_factory_action_requested)
	shell.add_child(factory)
	factory.configure(_factory_view())
	_add_nav(shell, Screen.BASE)
	_add_factory_world_labels.call_deferred()


func _factory_view() -> Dictionary:
	var state: RefCounted = game.current_state()
	var now_unix := int(Time.get_unix_time_from_system())
	var resources: Array[Dictionary] = []
	for resource in [
		{"id": "porcelain", "name": "陶瓷"},
		{"id": "parts", "name": "零件"},
		{"id": "sludge", "name": "能源"},
	]:
		var material_id := String(resource["id"])
		var current := int(state.factory.materials.get(material_id, 0))
		var capacity := int(state.factory.capacities.get(material_id, 0))
		var full_seconds := LogisticsService.seconds_until_full(state, material_id)
		resources.append({
			"id": material_id,
			"name": String(resource["name"]),
			"current": current,
			"capacity": capacity,
			"rate": LogisticsService.rate_per_minute(state, material_id),
			"status": "已满" if full_seconds == 0 else "%s 后存满" % _duration_copy(full_seconds),
			"full": current >= capacity,
		})
	var construction_options: Array[Dictionary] = []
	for facility_id in FACILITY_NAMES:
		if facility_id == "command_center" or int(state.factory.facilities.get(facility_id, 0)) > 0:
			continue
		var cost := int(LogisticsService.FACILITY_BUILD_COSTS.get(facility_id, 0))
		var eligible: bool = facility_id != "research_lab" or bool(state.factory.eligible_facilities.get("research_lab", false))
		construction_options.append({
			"facility_id": facility_id,
			"name": String(FACILITY_NAMES[facility_id]),
			"cost": cost,
			"copy": String(FACILITY_COPY[facility_id]) if eligible else "先挑战 1-4，让首败战报定位研究所方案。",
			"disabled": int(state.economy.toilet_coins) < cost or not state.factory.facility_work.is_empty() or not eligible,
		})
	var cell_selected := construction_cell.x != 999
	var occupied := cell_selected and _is_factory_cell_occupied(construction_cell)
	var facility := _factory_facility_view(state, selected_facility_id, now_unix)
	return {
		"compact": _layout_profile() == "compact_landscape",
		"panel": factory_hud_panel,
		"coins": int(state.economy.toilet_coins),
		"tech": int(state.economy.industrial_tech),
		"resources": resources,
		"task": OnboardingService.snapshot(state),
		"facility": facility,
		"construction": {
			"options": construction_options,
			"active_id": construction_facility_id,
			"active_name": String(FACILITY_NAMES.get(construction_facility_id, "")),
			"active_copy": String(FACILITY_COPY.get(construction_facility_id, "")),
			"cost": int(LogisticsService.FACILITY_BUILD_COSTS.get(construction_facility_id, 0)),
			"placement_copy": (
				"下一步：轻点网格选址；单指旋转，双指缩放。"
				if not cell_selected
				else "已选择格子 (%d, %d)；确认后才扣除资源。" % [construction_cell.x, construction_cell.y]
			),
			"can_confirm": cell_selected and not occupied,
			"occupied": occupied,
		},
	}


func _factory_facility_view(state: RefCounted, facility_id: String, now_unix: int) -> Dictionary:
	var level := int(state.factory.facilities.get(facility_id, 0))
	var facility_work := state.factory.facility_work as Dictionary
	var work: Dictionary = {}
	if not facility_work.is_empty():
		var work_facility_id := String(facility_work.get("facility_id", ""))
		var remaining := maxi(0, int(facility_work.get("completes_at_unix", 0)) - now_unix)
		var work_name := String(FACILITY_NAMES.get(work_facility_id, "设施"))
		var work_copy := "正在建造" if String(facility_work.get("work_type", "")) == "construction" else "正在升级"
		work = {
			"status": "%s%s · %s" % [
				work_name,
				work_copy,
				"可验收" if remaining == 0 else "剩余 %s" % _duration_copy(remaining),
			],
			"ready": remaining == 0,
			"blocks_panel": work_facility_id == facility_id or level <= 0,
		}
	var build_cost := int(LogisticsService.FACILITY_BUILD_COSTS.get(facility_id, 0))
	var eligible: bool = facility_id != "research_lab" or bool(state.factory.eligible_facilities.get("research_lab", false))
	var kind := "global"
	var resource_name := ""
	var output := 0
	if FACTORY_RESOURCE_NAMES.has(facility_id):
		kind = "resource"
		resource_name = String(FACTORY_RESOURCE_NAMES[facility_id])
		output = int(LogisticsService.facility_output_preview(state, facility_id, now_unix).get("amount", 0))
	elif facility_id == "repair_center":
		kind = "training"
	elif facility_id == "research_lab":
		kind = "research"
	return {
		"facility_id": facility_id,
		"name": String(FACILITY_NAMES.get(facility_id, facility_id)),
		"copy": String(FACILITY_COPY.get(facility_id, "")),
		"level": level,
		"work": work,
		"eligible": eligible,
		"eligibility_copy": "先带领 Gman 挑战 1-4；首败战报会指出研究所的援军方案。",
		"build_cost": build_cost,
		"enough_coins": int(state.economy.toilet_coins) >= build_cost,
		"can_build": eligible and int(state.economy.toilet_coins) >= build_cost and facility_work.is_empty(),
		"kind": kind,
		"resource_name": resource_name,
		"output": output,
		"upgrade_cost_copy": "升级消耗：金币 %d · 技术 %d · 陶瓷 %d · 零件 %d · 能源 %d" % [
			40 * level, 2 * level, 20 * level, 12 * level, 16 * level,
		],
		"upgrade_preview": _facility_upgrade_preview(facility_id, level) if level > 0 else "",
		"can_upgrade": level > 0 and level < 3 and facility_work.is_empty(),
	}


func _on_factory_action_requested(action_id: String, payload: Dictionary) -> void:
	match action_id:
		"claim_output":
			_claim_output()
		"claim_facility_output":
			_claim_facility_output(String(payload.get("facility_id", "")))
		"claim_task":
			_claim_task()
		"follow_task":
			_follow_task(String(payload.get("target", "map")), String(payload.get("stage_id", "")))
		"intelligence":
			_show_intelligence()
		"begin_construction":
			_begin_facility_construction(String(payload.get("facility_id", "")))
		"confirm_construction":
			_confirm_facility_construction()
		"cancel_construction":
			_cancel_facility_construction()
		"claim_work":
			_claim_facility_work()
		"upgrade_facility":
			_upgrade_facility(String(payload.get("facility_id", "")))
		"blueprints":
			_show_blueprints()
		"legion":
			legion_tab = "roster"
			_show_legion()


func _set_factory_hud_panel(panel_id: String) -> void:
	if panel_id not in ["mission", "facility", "build"]:
		return
	if factory_hud_panel == panel_id:
		return
	factory_hud_panel = panel_id
	_show_base()


func _facility_upgrade_preview(facility_id: String, level: int) -> String:
	match facility_id:
		"porcelain_plant", "parts_workshop", "energy_station":
			return "升级收益：产速与库存容量提升至当前的 %.1f 倍" % (float(level + 1) / float(level))
		"repair_center":
			return "升级收益：强化角色培养设施与后续训练扩展"
		"research_lab":
			return "升级收益：开放更高阶技能研究"
		_:
			return "升级收益：提高工厂全局等级与容量"


func _duration_copy(seconds: int) -> String:
	if seconds < 0:
		return "暂停"
	var hours := seconds / 3600
	var minutes := maxi(1, (seconds % 3600) / 60)
	if hours > 0:
		return "%d时%d分" % [hours, minutes]
	return "%d分" % minutes


func _show_intelligence() -> void:
	screen = Screen.INTELLIGENCE
	_clear()
	var state: RefCounted = game.current_state()
	var target_stage_id := String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	if not StageCatalog.has_stage(target_stage_id):
		target_stage_id = StageCatalog.DEFAULT_STAGE_ID
	var config := StageCatalog.stage(target_stage_id)
	var report := WarReadinessReport.derive(state, config)
	var shell := _shell("指挥情报", "用同一口径判断战力、成长投资与下一行动")
	shell.name = "WarIntelligenceShell"
	var intelligence := IntelligenceScreenScene.instantiate() as Control
	intelligence.call("configure", {
		"stage_id": target_stage_id,
		"report": report,
	})
	intelligence.connect("action_requested", _on_intelligence_action_requested)
	shell.add_child(intelligence)
	_add_nav(shell, Screen.INTELLIGENCE)
	return


func _on_intelligence_action_requested(action_id: String, payload: Dictionary) -> void:
	_play_ui_click()
	if action_id == "upgrade":
		_show_legion()
		return
	_start_stage_battle(String(payload.get("stage_id", selected_stage_id)))



func _show_map() -> void:
	screen = Screen.MAP
	_clear()
	var shell := _shell("灰镜战区", "联盟防线正在收缩")
	var state: RefCounted = game.current_state()
	var cleared: Array = state.stage_progress.get("cleared_stages", [])
	var highest := String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	var highest_config := StageCatalog.stage(highest)
	var highest_chapter := int(highest_config.get("chapter", 1))
	selected_chapter = clampi(selected_chapter, 1, maxi(1, highest_chapter))
	var visible_stage_ids: Array[String] = []
	if selected_chapter <= 5:
		for stage_number in range(1, 6):
			visible_stage_ids.append("stage_%d_%d" % [selected_chapter, stage_number])
	else:
		var endless_index := 1
		if highest.begins_with(StageCatalog.ENDLESS_PREFIX):
			endless_index = maxi(1, int(highest.trim_prefix(StageCatalog.ENDLESS_PREFIX)))
		for offset in range(5):
			visible_stage_ids.append("%s%d" % [StageCatalog.ENDLESS_PREFIX, maxi(1, endless_index - 2 + offset)])
	if not visible_stage_ids.has(selected_stage_id):
		selected_stage_id = visible_stage_ids[0]
	var stage_rows: Array[Dictionary] = []
	for stage_id in visible_stage_ids:
		var config := StageCatalog.stage(stage_id)
		var unlocked: bool = stage_id == StageCatalog.DEFAULT_STAGE_ID or cleared.has(stage_id) or stage_id == highest
		var status := "已夺回" if cleared.has(stage_id) else ("前线" if unlocked else "信号中断")
		stage_rows.append({
			"stage_id": stage_id,
			"display_name": String(config.get("display_name", stage_id)),
			"status": status,
			"unlocked": unlocked,
		})
	var selected_config := StageCatalog.stage(selected_stage_id)
	var selected_unlocked: bool = selected_stage_id == StageCatalog.DEFAULT_STAGE_ID or cleared.has(selected_stage_id) or selected_stage_id == highest
	var war_zone := WarZoneScreenScene.instantiate()
	war_zone.configure(
		highest_chapter,
		selected_chapter,
		selected_stage_id,
		stage_rows,
		selected_config,
		WarReadinessReport.derive(state, selected_config),
		selected_unlocked,
		cleared.has(selected_stage_id),
		_estimated_damage(selected_config)
	)
	war_zone.chapter_selected.connect(_select_chapter)
	war_zone.stage_selected.connect(_select_stage_card)
	war_zone.attack_requested.connect(_start_stage_battle)
	shell.add_child(war_zone)
	_add_nav(shell, Screen.MAP)


func _select_chapter(chapter: int) -> void:
	selected_chapter = clampi(chapter, 1, 6)
	selected_stage_id = "stage_%d_1" % selected_chapter if selected_chapter <= 5 else StageCatalog.ENDLESS_PREFIX + "1"
	_show_map()


func _select_stage_card(stage_id: String) -> void:
	selected_stage_id = stage_id
	_show_map()


func _start_stage_battle(stage_id: String) -> void:
	selected_stage_id = stage_id
	_start_battle()


func _show_legion() -> void:
	screen = Screen.LEGION
	_clear()
	var shell := _shell("军团整备区", "比较职责、战力变化与下一成长，再决定谁上阵")
	var legion := LegionScreenScene.instantiate() as LegionScreen
	legion.tab_selected.connect(func(_tab_id: String) -> void: _play_ui_click())
	legion.tab_selected.connect(_set_legion_tab)
	legion.action_requested.connect(func(_action_id: String, _payload: Dictionary) -> void: _play_ui_click())
	legion.action_requested.connect(_on_legion_action_requested)
	shell.add_child(legion)
	legion.configure(_legion_view())
	_add_nav(shell, Screen.LEGION)


func _legion_view() -> Dictionary:
	var state: RefCounted = game.current_state()
	var unlock_state := MetaCatalog.unlocks(state)
	var stage_id := String(state.stage_progress.get("highest_unlocked_stage", StageCatalog.DEFAULT_STAGE_ID))
	var target_stage := StageCatalog.stage(stage_id)
	var formation: Array[Dictionary] = []
	for slot_id in ["commander", "troop_1", "troop_2", "troop_3", "troop_4", "troop_5"]:
		var hero_id := String(state.formation.slots.get(slot_id, ""))
		var hero: RefCounted = state.hero_by_id(hero_id)
		formation.append({
			"slot_id": slot_id,
			"hero_id": hero_id,
			"display_name": String(hero.display_name) if hero != null else "空位",
			"role": _legion_role(String(hero.archetype_id)) if hero != null else "待命",
		})
	var deployed_id := String(state.formation.slots.get(formation_edit_slot, ""))
	var deployed_hero: RefCounted = state.hero_by_id(deployed_id)
	var deployed_power := CombatPower.hero_power(deployed_hero) if deployed_hero != null else 0
	var candidates: Array[Dictionary] = []
	var roster: Array[Dictionary] = []
	for hero in state.roster:
		var power := CombatPower.hero_power(hero)
		var specialty_id := String(LogisticsService.SPECIALTY_FACILITY.get(String(hero.archetype_id), "energy_station"))
		var next_growth := "升级提高基础属性"
		if int(hero.star) < 2:
			next_growth = "升至 2★ 解锁职责被动"
		elif int(hero.star) < 3:
			next_growth = "升至 3★ 触发技能质变"
		elif int(hero.active_skill_level) < 3:
			next_growth = "研究主动技能"
		candidates.append({
			"hero_id": String(hero.hero_id),
			"display_name": String(hero.display_name),
			"role": _legion_role(String(hero.archetype_id)),
			"power": power,
			"power_delta": power - deployed_power,
			"current": deployed_id == String(hero.hero_id),
		})
		roster.append({
			"hero_id": String(hero.hero_id),
			"display_name": String(hero.display_name),
			"archetype_id": String(hero.archetype_id),
			"role": _legion_role(String(hero.archetype_id)),
			"level": int(hero.level),
			"star": int(hero.star),
			"power": power,
			"skill_name": FactoryCatalog.active_skill_for_archetype(String(hero.archetype_id)),
			"skill_level": int(hero.active_skill_level),
			"owned_data": int(state.meta_progression.hero_data.get(String(hero.archetype_id), 0)),
			"next_star_data": 4 if int(hero.star) == 1 else 8,
			"next_growth": next_growth,
			"skill_research_allowed": int(hero.active_skill_level) + 1 <= int(state.factory.facilities.get("research_lab", 1)) + 1,
			"specialty_id": specialty_id,
			"specialty_name": String(FACILITY_NAMES.get(specialty_id, specialty_id)),
			"specialty_assigned": String(hero.assigned_facility_id) == specialty_id,
			"auto_skill": bool(hero.auto_skill_enabled),
		})
	var data_parts: Array[String] = []
	for archetype_id in state.meta_progression.hero_data:
		data_parts.append("%s×%d" % [
			HeroGenerator.archetype_display_name(String(archetype_id)),
			int(state.meta_progression.hero_data[archetype_id]),
		])
	var recruit_results: Array[Dictionary] = []
	for draw in last_recruit_results:
		recruit_results.append({
			"rarity": String(draw.get("rarity", "R")),
			"kind": String(draw.get("kind", "hero")),
			"display_name": HeroGenerator.archetype_display_name(String(draw.get("archetype_id", ""))),
			"amount": int(draw.get("amount", 0)),
		})
	var cleared: Array = state.stage_progress.get("cleared_stages", [])
	return {
		"tab": legion_tab,
		"formation_edit_slot": formation_edit_slot,
		"formation": formation,
		"candidates": candidates,
		"roster": roster,
		"team_power": CombatPower.formation_power(state),
		"target_stage_name": String(target_stage.get("display_name", stage_id)),
		"recommended_power": int(target_stage.get("recommended_power", 0)),
		"recruitment_unlocked": bool(unlock_state["recruitment"]),
		"recruitment_progress": "解锁进度 · 指挥官 Lv%d/4 · 关卡 1-5 %s" % [
			int(unlock_state["commander_level"]),
			"已通关" if cleared.has("stage_1_5") else "未通关",
		],
		"recruit_tickets": int(state.economy.recruit_tickets),
		"recruit_s_pity": int(state.meta_progression.recruit_s_pity),
		"recruit_target_guaranteed": bool(state.meta_progression.recruit_target_guaranteed),
		"hero_data_copy": "英雄数据：%s" % ("暂无（重复英雄将自动转化）" if data_parts.is_empty() else " · ".join(data_parts)),
		"recruit_results": recruit_results,
	}


func _legion_role(archetype_id: String) -> String:
	var roles := {
		"gman": "统帅 · 稳定输出",
		"assault": "突击 · 快速压制",
		"armored": "重装 · 承伤保护",
		"rocket": "远程 · 结构爆破",
		"bomber": "轰炸 · 范围清场",
		"repair": "支援 · 战线续航",
		"sonic": "控制 · 打断压制",
		"parasite": "召唤 · 持续增援",
		"saw": "近战 · 单体处决",
	}
	return String(roles.get(archetype_id, "战斗成员"))


func _on_legion_action_requested(action_id: String, payload: Dictionary) -> void:
	match action_id:
		"select_slot":
			_select_formation_slot(String(payload.get("slot", "")))
		"assign_slot":
			_assign_formation_slot(String(payload.get("slot", "")), String(payload.get("hero_id", "")))
		"recruit":
			_signal_recruit(int(payload.get("count", 1)))
		"upgrade":
			_upgrade_hero(String(payload.get("hero_id", "")))
		"star":
			_upgrade_star(String(payload.get("hero_id", "")))
		"skill":
			_research_active_skill(String(payload.get("hero_id", "")))
		"specialist":
			_assign_specialist(String(payload.get("hero_id", "")), String(payload.get("facility_id", "")))
		"auto":
			_toggle_auto_skill(String(payload.get("hero_id", "")), bool(payload.get("enabled", false)))


func _set_legion_tab(tab: String) -> void:
	if tab == legion_tab:
		return
	legion_tab = tab
	_show_legion()


func _show_blueprints() -> void:
	screen = Screen.BLUEPRINTS
	_clear()
	var shell := _shell("科技蓝图", "沿主干向外研究 · 两张基础蓝图各解锁一名永久马桶人")
	var blueprint_screen := BlueprintScreenScene.instantiate() as Control
	blueprint_screen.call("configure", _blueprint_view())
	blueprint_screen.connect("branch_selected", _set_blueprint_branch)
	blueprint_screen.connect("action_requested", _on_blueprint_action_requested)
	shell.add_child(blueprint_screen)
	return


func _blueprint_view() -> Dictionary:
	var state: RefCounted = game.current_state()
	var branches := {
		"ordinary": {"title": "突击枝", "recipes": ["ordinary.assault", "ordinary.sonic"]},
		"heavy": {"title": "重装枝", "recipes": ["heavy.armored", "heavy.saw"]},
		"flying": {"title": "飞行枝", "recipes": ["flying.rocket", "flying.bomber"]},
		"special": {"title": "支援枝", "recipes": ["special.repair", "special.parasite"]},
	}
	var branch_data := branches.get(blueprint_branch, branches["ordinary"]) as Dictionary
	var claimed := (state.onboarding.get("claimed", {}) as Dictionary).has(
		"reward.research_breakthrough_ten"
	)
	var lab_built := int(state.factory.facilities.get("research_lab", 0)) > 0
	var breakthrough := {
		"claimable": lab_built and not claimed,
		"copy": (
			"跨过灰镜高墙后的研究突破：本次免费，不消耗招募券，不推进长期保底。"
			if lab_built and not claimed
			else ("研究突破十连已完成 · 冲锋与装甲永久入列" if claimed else "")
		),
	}
	var result_views: Array[Dictionary] = []
	var resource_names := {
		"skill_chip": "技能芯片",
		"porcelain": "陶瓷",
		"parts": "零件",
		"sludge": "能源",
		"hero_data": "角色数据",
	}
	for item_value in last_research_breakthrough_results:
		var item := item_value as Dictionary
		var kind := String(item.get("kind", ""))
		var result_copy := ""
		if kind == "hero":
			result_copy = "%s\n%s\n永久援军" % [
				String(item.get("rarity", "A")),
				HeroGenerator.archetype_display_name(String(item.get("archetype_id", ""))),
			]
		else:
			result_copy = "%s\n%s\n+%d" % [
				String(item.get("rarity", "R")),
				String(resource_names.get(kind, "研究资源")),
				int(item.get("amount", 0)),
			]
		result_views.append({"rarity": String(item.get("rarity", "R")), "copy": result_copy})
	var nodes: Array[Dictionary] = []
	var active_research := state.factory.blueprint_research as Dictionary
	var now := int(Time.get_unix_time_from_system())
	for recipe_id_value in branch_data.get("recipes", []):
		var recipe_id := String(recipe_id_value)
		var recipe := FactoryCatalog.recipe(recipe_id)
		var unlocked := bool(state.factory.blueprints.get(recipe_id, false))
		var available := bool(state.factory.discovered_blueprints.get(recipe_id, false))
		var is_researching := String(active_research.get("recipe_id", "")) == recipe_id
		var ready := is_researching and now >= int(active_research.get("completes_at_unix", 0))
		var node := {
			"recipe_id": recipe_id,
			"display_name": String(recipe.get("display_name", recipe_id)),
			"status_id": "locked",
			"status_copy": "前置节点尚未开放",
			"action_id": "",
			"action_label": "",
			"action_name": "",
			"disabled": false,
		}
		if unlocked:
			node["status_id"] = "unlocked"
			node["status_copy"] = "已解锁 · 永久角色已入列"
		elif is_researching:
			node["status_id"] = "researching"
			node["status_copy"] = (
				"研发完成 · 等待领取"
				if ready
				else "研发中 · 剩余 %s" % _duration_copy(maxi(0, int(active_research.get("completes_at_unix", 0)) - now))
			)
			node["action_id"] = "claim_research"
			node["action_label"] = "领取新角色" if ready else "研发中…"
			node["action_name"] = "ClaimFoundationalBlueprint"
			node["disabled"] = not ready
		elif available:
			node["status_id"] = "available"
			node["status_copy"] = "可研发 · 耗时45秒"
			node["action_id"] = "start_research"
			node["action_label"] = "开始研发%s" % String(recipe.get("display_name", "蓝图"))
			node["action_name"] = "UnlockFoundationalBlueprint_%s" % recipe_id.replace(".", "_")
		nodes.append(node)
	return {
		"branch": blueprint_branch,
		"branch_title": String(branch_data.get("title", "研究分支")),
		"core_status": "首败信号已解析 · 选择两条基础树枝",
		"breakthrough": breakthrough,
		"results": result_views,
		"nodes": nodes,
	}


func _on_blueprint_action_requested(action_id: String, payload: Dictionary) -> void:
	_play_ui_click()
	match action_id:
		"claim_breakthrough":
			_claim_research_breakthrough()
		"open_legion":
			_show_legion()
		"start_research":
			_unlock_foundational_blueprint(String(payload.get("recipe_id", "")))
		"claim_research":
			_claim_foundational_blueprint()
		"back":
			_show_base()



func _set_blueprint_branch(branch_id: String) -> void:
	if branch_id == blueprint_branch:
		return
	blueprint_branch = branch_id
	_show_blueprints()


func _unlock_foundational_blueprint(recipe_id: String) -> void:
	var result := _command(
		"unlock_foundational_blueprint",
		{"recipe_id": recipe_id, "now_unix": int(Time.get_unix_time_from_system())},
		"foundational-blueprint:%s" % recipe_id
	)
	if bool(result.get("ok", false)):
		_notify("研发已开始，完成后即可领取新角色")
		_show_blueprints()


func _claim_foundational_blueprint() -> void:
	var result := _command("claim_blueprint_research", {"now_unix": int(Time.get_unix_time_from_system())})
	if bool(result.get("ok", false)):
		var hero_id := String((result.get("event", {}) as Dictionary).get("hero_id", ""))
		formation_edit_slot = "troop_1"
		for slot_id in ["troop_1", "troop_2", "troop_3", "troop_4", "troop_5"]:
			if String(game.current_state().formation.slots.get(slot_id, "")).is_empty():
				formation_edit_slot = slot_id
				break
		_notify("%s已解锁，可以上阵了" % String((result.get("event", {}) as Dictionary).get("display_name", "基础马桶人")))
		_show_legion()
		if not hero_id.is_empty():
			var candidate_panel := ui_root.find_child("FormationCandidatePanel", true, false)
			if candidate_panel != null:
					var hero_button := candidate_panel.find_child("FormationCandidate_%s" % hero_id, true, false)
					if hero_button is Button:
						(hero_button as Button).grab_focus()
	else:
		_notify(_error_copy(String(result.get("error", "解锁失败"))))


func _claim_research_breakthrough() -> void:
	var result := _command(
		"claim_research_breakthrough",
		{},
		"research-breakthrough-ten"
	)
	if not bool(result.get("ok", false)):
		_notify(_error_copy(String(result.get("error", "研究突破失败"))))
		return
	last_research_breakthrough_results.clear()
	for item in (result.get("event", {}) as Dictionary).get("results", []):
		last_research_breakthrough_results.append((item as Dictionary).duplicate(true))
	_notify("研究突破完成：冲锋与装甲两名永久援军已入列")
	_show_blueprints()


func _show_goals() -> void:
	_ensure_meta_refreshed()
	screen = Screen.GOALS
	_clear()
	var shell := _shell("目标与里程碑", "当前行动、章节进度与永久成就")
	var state: RefCounted = game.current_state()
	var goals: Control = GoalsScreenScene.instantiate()
	goals.connect("tab_selected", _set_goals_tab)
	goals.connect("action_requested", _on_goals_action_requested)
	goals.call("configure", _goals_view(state))
	shell.add_child(goals)
	_add_nav(shell, Screen.GOALS)


func _goals_view(state: RefCounted) -> Dictionary:
	var unlock_state := MetaCatalog.unlocks(state)
	var cleared := state.stage_progress.get("cleared_stages", []) as Array
	var task := OnboardingService.snapshot(state)
	var first_incomplete: Dictionary = {}
	for objective_value in task.get("objectives", []):
		var objective := objective_value as Dictionary
		if not bool(objective.get("completed", false)):
			first_incomplete = objective
			break
	var hierarchy := {
		"macro": (
			"推进第二章，扩大战争工厂"
			if cleared.has("stage_1_5")
			else "摧毁灰镜核心，完成第一章"
		),
		"medium": String(task.get("title", "建立下一条战线")),
		"small": (
			"选择下一座未占领城镇"
			if bool(task.get("finished", false))
			else String(first_incomplete.get("label", task.get("cta_label", "继续推进")))
		),
		"hurdle": OnboardingCatalog.hurdle_for_task(String(task.get("task_id", ""))),
		"finished": bool(task.get("finished", false)),
		"cta_label": String(task.get("cta_label", "继续")),
		"target": String(task.get("target", "expedition")),
		"stage_id": String(task.get("stage_id", "")),
	}
	var chapter_parts: Array[String] = []
	for chapter in range(1, 6):
		var chapter_clear := 0
		for stage_number in range(1, 6):
			if cleared.has("stage_%d_%d" % [chapter, stage_number]):
				chapter_clear += 1
		chapter_parts.append("第%d章 %d/5" % [chapter, chapter_clear])
	var missions: Array[Dictionary] = []
	for definition in MetaCatalog.DAILY:
		var mission := _goals_mission_view(state, definition)
		if not mission.is_empty():
			missions.append(mission)
	if bool(unlock_state["weekly"]):
		missions.append({"weekly_heading": true})
		for definition in MetaCatalog.WEEKLY:
			var weekly := _goals_mission_view(state, definition)
			if not weekly.is_empty():
				missions.append(weekly)
	var merit := int(state.meta_progression.season_merit)
	var reached := MetaCatalog.pass_level(merit)
	var pass_claimable := 0
	var pass_levels: Array[Dictionary] = []
	for level in range(1, MetaCatalog.PASS_MAX_LEVEL + 1):
		var key := "%s:%d" % [state.meta_progression.season_id, level]
		var claimed: bool = state.meta_progression.pass_claimed_levels.has(key)
		var claimable := level <= reached and not claimed
		if claimable:
			pass_claimable += 1
		pass_levels.append({
			"level": level,
			"claimed": claimed,
			"claimable": claimable,
			"reward": MetaCatalog.pass_reward(level),
		})
	var achievements: Array[Dictionary] = []
	var achievement_claimable := 0
	for definition in MetaCatalog.ACHIEVEMENTS:
		var achievement_id := String(definition["id"])
		var progress := int(state.meta_progression.achievement_progress.get(achievement_id, 0))
		var target := int(definition["target"])
		var claimed: bool = state.meta_progression.achievement_claimed.has(achievement_id)
		var complete := progress >= target
		if complete and not claimed:
			achievement_claimable += 1
		achievements.append({
			"achievement_id": achievement_id,
			"title": String(definition["title"]),
			"progress": progress,
			"target": target,
			"complete": complete,
			"claimed": claimed,
		})
	var xp := int(state.meta_progression.commander_xp)
	var commander_level := MetaCatalog.commander_level(xp)
	var commander_claimable := 0
	for reward_level in range(2, commander_level + 1):
		if not state.meta_progression.commander_claimed_levels.has(str(reward_level)):
			commander_claimable += 1
	return {
		"tab": goals_tab,
		"hierarchy": hierarchy,
		"campaign": {
			"cleared": cleared.size(),
			"chapters_copy": "  ·  ".join(chapter_parts),
		},
		"missions_unlocked": bool(unlock_state["missions"]),
		"weekly_unlocked": bool(unlock_state["weekly"]),
		"missions": missions,
		"mission_lock": _goals_lock_view(state, "行动任务", 2, "stage_1_1", "通关 1-1"),
		"pass_unlocked": bool(unlock_state["pass"]),
		"pass_lock": _goals_lock_view(state, "免费战役战令", 5, "stage_1_5", "通关 1-5"),
		"pass": {
			"merit": merit,
			"reached": reached,
			"claimable": pass_claimable,
			"levels": pass_levels,
		},
		"achievements_unlocked": bool(unlock_state["achievements"]),
		"achievement_lock": _goals_lock_view(state, "永久成就", 3, "stage_1_2", "通关 1-2"),
		"achievement_claimable": achievement_claimable,
		"achievements": achievements,
		"commander": {
			"xp": xp,
			"level": commander_level,
			"next_xp": MetaCatalog.COMMANDER_THRESHOLDS[mini(29, commander_level)],
			"claimable": commander_claimable,
		},
	}


func _goals_mission_view(state: RefCounted, definition: Dictionary) -> Dictionary:
	var mission_id := String(definition["id"])
	var record := state.meta_progression.missions.get(mission_id, {}) as Dictionary
	if record.is_empty():
		return {}
	var generation := int(record.get("generation", 0))
	var progress := int(record.get("progress", 0))
	var target := int(record.get("target", 1))
	return {
		"mission_id": mission_id,
		"title": String(definition["title"]),
		"generation": generation,
		"progress": progress,
		"target": target,
		"complete": progress >= target,
		"claimed": state.meta_progression.mission_claims.has("%s:%d" % [mission_id, generation]),
	}


func _goals_lock_view(
	state: RefCounted,
	title: String,
	required_level: int,
	stage_id: String,
	stage_copy: String
) -> Dictionary:
	return {
		"title": title,
		"level": MetaCatalog.commander_level(int(state.meta_progression.commander_xp)),
		"required_level": required_level,
		"stage_copy": stage_copy,
		"stage_complete": (state.stage_progress.get("cleared_stages", []) as Array).has(stage_id),
	}


func _on_goals_action_requested(action_id: String, payload: Dictionary) -> void:
	match action_id:
		"follow_task":
			_follow_task(String(payload.get("target", "expedition")), String(payload.get("stage_id", "")))
		"open_map":
			_show_map()
		"claim_mission":
			_claim_meta_mission(String(payload.get("mission_id", "")), int(payload.get("generation", 0)))
		"claim_pass_level":
			_claim_meta_pass(int(payload.get("level", 0)))
		"claim_all_pass":
			_claim_all_meta_pass()
		"claim_all_commander":
			_claim_all_commander_rewards()
		"claim_achievement":
			_claim_meta_achievement(String(payload.get("achievement_id", "")))
		"claim_all_achievements":
			_claim_all_meta_achievements()


func _ensure_meta_refreshed() -> void:
	var now_unix := int(Time.get_unix_time_from_system())
	var meta: RefCounted = game.current_state().meta_progression
	var day_key := str(now_unix / 86400)
	var week_key := str(now_unix / 604800)
	var season_key := "season_%d" % (now_unix / 2419200)
	if String(meta.daily_key) != day_key or String(meta.weekly_key) != week_key or String(meta.season_id) != season_key:
		_command("refresh_meta_progression", {"now_unix": now_unix})


func _set_goals_tab(tab: String) -> void:
	if tab == goals_tab:
		return
	goals_tab = tab
	_show_goals()


func _achievement_row(state: RefCounted, definition: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var achievement_id := String(definition["achievement_id"])
	var progress_record := (state.achievements.get("progress", {}) as Dictionary).get(achievement_id, {}) as Dictionary
	var value := int(progress_record.get("value", 0))
	var target := int(definition.get("target", 1))
	var claimed := (state.achievements.get("claimed", {}) as Dictionary).has(achievement_id)
	var completed := (state.achievements.get("completed", {}) as Dictionary).has(achievement_id)
	var copy := _label("%s    %d/%d%s" % [
		String(definition.get("title", achievement_id)),
		value,
		target,
		"  已领取" if claimed else "",
	], 14, GREEN if claimed else TEXT)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	if completed and not claimed:
		var claim := _button("领取", Callable(self, "_claim_achievement").bind(achievement_id), true)
		claim.custom_minimum_size.x = 100
		row.add_child(claim)
	return row


func _start_battle() -> void:
	var snapshots := _battle_snapshots()
	if snapshots.is_empty():
		_notify("当前编队没有可出战角色")
		return
	screen = Screen.BATTLE
	last_battle_runtime_result = {}
	battle_skill_buttons.clear()
	battle_unit_hud.clear()
	_clear()
	var config := StageCatalog.stage(selected_stage_id)
	var shell := _shell(
		String(config.get("display_name", selected_stage_id)),
		"选择技能时机改变本局战况 · 失败不会造成永久损失",
		true
	)
	var any_auto := false
	for snapshot in snapshots:
		any_auto = any_auto or bool(snapshot.get("auto_skill", false))
	battle_manual_skills = not any_auto
	battle_hud_screen = BattleHudScreenScene.instantiate() as BattleHudScreen
	battle_hud_screen.pause_requested.connect(_play_ui_click)
	battle_hud_screen.pause_requested.connect(_set_battle_paused.bind(true))
	battle_hud_screen.skill_mode_requested.connect(_play_ui_click)
	battle_hud_screen.skill_mode_requested.connect(_toggle_battle_skill_mode)
	battle_hud_screen.retreat_requested.connect(_play_ui_click)
	battle_hud_screen.retreat_requested.connect(_retreat)
	battle_hud_screen.skill_requested.connect(func(_unit_id: String) -> void: _play_ui_click())
	battle_hud_screen.skill_requested.connect(_request_battle_skill)
	shell.add_child(battle_hud_screen)
	battle_hud_screen.configure(snapshots, battle_manual_skills)
	battle_pause_button = battle_hud_screen.pause_button
	battle_status_label = battle_hud_screen.status_label
	battle_auto_button = battle_hud_screen.skill_mode_button
	battle_skill_buttons = battle_hud_screen.skill_buttons()
	get_viewport().msaa_3d = Viewport.MSAA_4X
	battle_world = BattleWorldScript.new()
	world_host.add_child(battle_world)
	battle_world.battle_finished.connect(_finish_battle)
	battle_world.battle_snapshot_updated.connect(_apply_battle_hud_snapshot)
	battle_world.configure_presentation(settings_store.effects_quality, settings_store.reduced_motion)
	_build_battle_pause_overlay()
	active_battle_stage = selected_stage_id
	active_battle_id = "siege-%s-%d" % [selected_stage_id, Time.get_ticks_msec()]
	battle_is_paused = false
	playtest_journal.record_event("battle_started", {
		"stage_id": selected_stage_id,
		"deployed_heroes": snapshots.size(),
		"manual_skills": battle_manual_skills,
	})
	battle_world.start_battle(snapshots, selected_stage_id, config)


func _toggle_battle_skill_mode() -> void:
	if battle_world == null or not is_instance_valid(battle_world):
		return
	battle_manual_skills = not battle_manual_skills
	for unit_id in battle_skill_buttons:
		battle_world.set_auto_skill(StringName(unit_id), not battle_manual_skills)
	if battle_hud_screen != null and is_instance_valid(battle_hud_screen):
		battle_hud_screen.set_manual_skills(battle_manual_skills)
	_refresh_battle_hud_once()


func _request_battle_skill(unit_id: String) -> void:
	if battle_world == null or not is_instance_valid(battle_world):
		return
	if battle_world.request_skill(StringName(unit_id)):
		_notify("已下达技能指令")
	else:
		_notify("技能尚未就绪")
	_refresh_battle_hud_once()


func _refresh_battle_hud_once() -> void:
	if screen != Screen.BATTLE or battle_world == null or not is_instance_valid(battle_world):
		return
	var snapshot := battle_world.call("snapshot") as Dictionary
	_apply_battle_hud_snapshot(snapshot)


func _apply_battle_hud_snapshot(snapshot: Dictionary) -> void:
	if screen != Screen.BATTLE:
		return
	if battle_hud_screen != null and is_instance_valid(battle_hud_screen):
		battle_hud_screen.apply_snapshot(snapshot)


func _set_battle_paused(paused: bool) -> void:
	if screen != Screen.BATTLE or battle_world == null or not is_instance_valid(battle_world):
		return
	battle_is_paused = paused
	battle_world.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	if battle_pause_overlay != null and is_instance_valid(battle_pause_overlay):
		battle_pause_overlay.visible = paused
	if battle_pause_button != null and is_instance_valid(battle_pause_button):
		battle_pause_button.text = "继续" if paused else "暂停"
		for connection in battle_pause_button.pressed.get_connections():
			battle_pause_button.pressed.disconnect(connection.callable)
		battle_pause_button.pressed.connect(Callable(self, "_set_battle_paused").bind(not paused))
	if paused and battle_pause_resume_button != null and is_instance_valid(battle_pause_resume_button):
		battle_pause_resume_button.grab_focus()


func _build_battle_pause_overlay() -> void:
	battle_pause_overlay = Control.new()
	battle_pause_overlay.name = "BattlePauseOverlay"
	battle_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	battle_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	battle_pause_overlay.z_index = 50
	battle_pause_overlay.visible = false
	ui_root.add_child(battle_pause_overlay)

	var shade := ColorRect.new()
	shade.color = Color(BG, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_pause_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_pause_overlay.add_child(center)
	var card := PanelContainer.new()
	card.name = "BattlePauseCard"
	card.custom_minimum_size = Vector2(410, 0)
	card.add_theme_stylebox_override("panel", _box(PANEL, 14, CYAN))
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	card.add_child(content)
	var title := _label("战斗已暂停", 24, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var hint := _label("战线与技能计时均已冻结", 13, GREEN)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)

	var volume_row := HBoxContainer.new()
	volume_row.custom_minimum_size.y = 48
	var volume_label := _label("主音量", 14, TEXT)
	volume_label.custom_minimum_size.x = 72
	volume_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_row.add_child(volume_label)
	var volume := HSlider.new()
	volume.name = "BattlePauseVolumeSlider"
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.value = settings_store.master_volume
	volume.custom_minimum_size = Vector2(250, 48)
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.value_changed.connect(func(value: float) -> void:
		settings_store.set_master_volume(value)
		_apply_settings_to_runtime()
	)
	volume.drag_ended.connect(func(_value_changed: bool) -> void:
		settings_store.save_settings()
	)
	volume_row.add_child(volume)
	content.add_child(volume_row)

	var reduced := CheckButton.new()
	reduced.name = "BattlePauseReducedMotionToggle"
	reduced.text = "减少动态效果"
	reduced.button_pressed = settings_store.reduced_motion
	reduced.custom_minimum_size.y = 48
	reduced.toggled.connect(func(enabled: bool) -> void:
		settings_store.set_reduced_motion(enabled)
		settings_store.save_settings()
		_apply_settings_to_runtime()
	)
	content.add_child(reduced)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	battle_pause_resume_button = _button("继续战斗", Callable(self, "_set_battle_paused").bind(false), true)
	battle_pause_resume_button.name = "BattlePauseResumeButton"
	battle_pause_resume_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(battle_pause_resume_button)
	var retreat := _button("撤退并结算", _retreat, false)
	retreat.name = "BattlePauseRetreatButton"
	retreat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(retreat)
	_apply_mobile_interactive_targets.call_deferred()


func _on_runtime_state_changed(state: Dictionary) -> void:
	if screen == Screen.BATTLE and not bool(state.get("is_interactive", true)):
		_set_battle_paused(true)


func _finish_battle(result: Dictionary) -> void:
	if screen != Screen.BATTLE:
		return
	last_battle_runtime_result = result.duplicate(true)
	playtest_journal.record_event("battle_finished", {
		"stage_id": active_battle_stage,
		"outcome": String(result.get("outcome", "defeat")),
		"ticks": maxi(1, int(result.get("ticks", 1))),
		"disabled_heroes": (result.get("dead_unit_ids", []) as Array).size(),
	})
	var deployed: Array = []
	for snapshot in _battle_snapshots():
		deployed.append(String(snapshot["hero_id"]))
	var disabled: Array = result.get("dead_unit_ids", [])
	pending_battle_settlement_payload = {
		"battle_id": active_battle_id,
		"stage_id": active_battle_stage,
		"outcome": String(result.get("outcome", "defeat")),
		"ticks": maxi(1, int(result.get("ticks", 1))),
		"deployed_unit_ids": deployed,
		"dead_unit_ids": disabled,
	}
	_submit_battle_settlement()


func _submit_battle_settlement() -> void:
	if pending_battle_settlement_payload.is_empty():
		_show_settlement_error("结算请求已经失效，请返回标题重新载入存档。")
		return
	var settlement := _command(
		"settle_battle",
		pending_battle_settlement_payload,
		String(pending_battle_settlement_payload.get("battle_id", active_battle_id))
	)
	last_settlement = settlement
	if not bool(settlement.get("ok", false)):
		_show_settlement_error(_error_copy(String(settlement.get("error", "UNKNOWN_ERROR"))))
		return
	pending_battle_settlement_payload.clear()
	_show_result()


func _show_settlement_error(reason: String) -> void:
	screen = Screen.RESULT
	_clear()
	var shell := _shell("战果尚未保存", "本次战斗结果仍保留在当前会话中")
	var panel := _panel_vbox("结算中断", 10)
	panel.name = "BattleSettlementErrorPanel"
	panel.add_child(_label("原因：%s" % reason, 15, RED))
	panel.add_child(_label("不要关闭页面。重试使用同一战斗编号，不会重复发放奖励。", 13, MUTED))
	var retry := _button("重新保存战果", _submit_battle_settlement, true)
	retry.name = "RetryBattleSettlementButton"
	panel.add_child(retry)
	shell.add_child(panel)


func _show_result() -> void:
	var event := last_settlement.get("event", {}) as Dictionary
	var outcome := String(event.get("outcome", "defeat"))
	if outcome == "victory" and String(event.get("stage_id", "")) == "stage_5_5":
		_show_epilogue(event)
		return
	screen = Screen.RESULT
	_clear()
	var won := outcome == "victory"
	audio_director.play_cue(
		&"victory" if won else (&"retreat" if outcome == "retreat" else &"defeat"),
		-7.0
	)
	var result_title := "城镇已占领" if won else ("已主动撤退" if outcome == "retreat" else "攻势受阻")
	var shell := _shell(result_title, "战果已结算，全员无损返回")
	var reward := event.get("reward", {}) as Dictionary
	var breakthrough := ""
	if int(event.get("hero_shards", 0)) > 0 or int(event.get("skill_chips", 0)) > 0:
		breakthrough = "突破战果：角色碎片 +%d  技能芯片 +%d" % [
			int(event.get("hero_shards", 0)),
			int(event.get("skill_chips", 0)),
		]
	var unlocked_hero := event.get("unlocked_hero", {}) as Dictionary
	var unlocked_copy := ""
	if not unlocked_hero.is_empty():
		unlocked_copy = "新永久角色加入：%s%s" % [
			String(unlocked_hero.get("display_name", "")),
			"（已编入空槽）" if bool(unlocked_hero.get("assigned_to_formation", false)) else "",
		]
	var combat_summary := ""
	var debrief := ""
	var contribution := ""
	if not last_battle_runtime_result.is_empty():
		combat_summary = "战斗复盘 · %d秒 · 击破%d个目标 · 消灭%d名守军" % [
			maxi(1, int(last_battle_runtime_result.get("ticks", 1)) / 5),
			int(last_battle_runtime_result.get("structures_destroyed", 0)),
			int(last_battle_runtime_result.get("enemies_defeated", 0)),
		]
		debrief = _battle_debrief_copy(last_battle_runtime_result, outcome)
		contribution = _battle_contribution_copy(last_battle_runtime_result)
	var next_stage_id := String(event.get("next_stage_id", ""))
	var cleared_stage_id := String(event.get("stage_id", ""))
	var onboarding := OnboardingService.snapshot(game.current_state())
	var qualification := ""
	var primary_label := ""
	var primary_action := ""
	var primary_payload: Dictionary = {}
	if (event.get("eligible_facilities", []) as Array).has("research_lab"):
		qualification = "已取得研究所建造资格"
		primary_label = "返回基地建造研究所"
		primary_action = "research_lab"
	elif won and cleared_stage_id == "stage_1_5":
		primary_label = "前往军团突破三星"
		primary_action = "legion"
	elif not bool(onboarding.get("finished", false)) and String(onboarding.get("target", "")) == "legion":
		primary_label = String(onboarding.get("cta_label", "比较成长路线"))
		primary_action = "legion"
	elif (
		not bool(onboarding.get("finished", false))
		and String(onboarding.get("target", "")) == "expedition"
		and not String(onboarding.get("stage_id", "")).is_empty()
	):
		primary_label = String(onboarding.get("cta_label", "继续进攻"))
		primary_action = "next_stage"
		primary_payload = {"stage_id": String(onboarding.get("stage_id", ""))}
	elif won and not next_stage_id.is_empty():
		primary_label = "进攻下一城镇"
		primary_action = "next_stage"
		primary_payload = {"stage_id": next_stage_id}
	else:
		primary_label = "培养角色"
		primary_action = "legion"
	var result_screen := BattleResultScreenScene.instantiate()
	result_screen.configure({
		"outcome_banner": "胜利 · 工厂与军团获得成长" if won else ("撤退 · 全员安全返回" if outcome == "retreat" else "失败 · 可立即调整后再战"),
		"outcome_color": "green" if won else ("gold" if outcome == "retreat" else "red"),
		"reward_headline": "金币 +%d    工业技术 +%d" % [
			int(reward.get("gold", 0)), int(event.get("industrial_tech", 0))
		],
		"materials": "陶瓷 +%d  零件 +%d  能源 +%d" % [
			int(reward.get("porcelain", 0)),
			int(reward.get("parts", 0)),
			int(reward.get("sludge", 0)),
		],
		"mission_progress": _onboarding_settlement_copy(event, onboarding),
		"breakthrough": breakthrough,
		"unlocked_hero": unlocked_copy,
		"combat_summary": combat_summary,
		"contribution": contribution,
		"debrief": debrief,
		"growth": _growth_opportunity_copy(event),
		"safety": "全员无损返回 · 无维修消耗 · 可立即再次出征",
		"qualification": qualification,
		"primary_label": primary_label,
		"primary_action": primary_action,
		"primary_payload": primary_payload,
	})
	result_screen.action_requested.connect(_on_result_action_requested)
	shell.add_child(result_screen)


func _onboarding_settlement_copy(event: Dictionary, next_task: Dictionary) -> String:
	var settlement := event.get("onboarding_settlement", {}) as Dictionary
	if settlement.is_empty():
		return ""
	var completed := OnboardingCatalog.task_by_id(String(settlement.get("task_id", "")))
	var completed_title := String(completed.get("title", "当前行动"))
	var reward := settlement.get("reward", {}) as Dictionary
	var reward_copy := ""
	if not reward.is_empty():
		reward_copy = " · 奖励已自动入账"
	if bool(next_task.get("finished", false)):
		return "%s完成%s · 首章训练闭环达成" % [completed_title, reward_copy]
	return "%s完成%s → 新目标：%s" % [
		completed_title,
		reward_copy,
		String(next_task.get("title", "继续推进")),
	]


func _on_result_action_requested(action_id: String, payload: Dictionary) -> void:
	match action_id:
		"research_lab":
			_open_research_lab()
		"legion":
			_show_legion()
		"next_stage":
			_start_stage_battle(String(payload.get("stage_id", "")))
		"factory", "base":
			_show_base()


func _battle_contribution_copy(runtime_result: Dictionary) -> String:
	var contribution := runtime_result.get("ally_damage_dealt_by_unit", {}) as Dictionary
	if contribution.is_empty():
		return ""
	var top_hero_id := ""
	var top_damage := 0
	var total_damage := 0
	for hero_id in contribution:
		var damage := maxi(0, int(contribution[hero_id]))
		total_damage += damage
		if damage > top_damage:
			top_damage = damage
			top_hero_id = String(hero_id)
	if top_hero_id.is_empty() or top_damage <= 0:
		return ""
	var hero: RefCounted = game.current_state().hero_by_id(top_hero_id)
	var hero_name := String(hero.display_name) if hero != null else "先锋单位"
	var share := int(round(float(top_damage) * 100.0 / maxi(1, total_damage)))
	return "核心贡献 · %s造成 %d 伤害，占编队输出 %d%%" % [hero_name, top_damage, share]


func _open_research_lab() -> void:
	selected_facility_id = "research_lab"
	factory_hud_panel = "facility"
	_show_base()


func _battle_debrief_copy(runtime_result: Dictionary, outcome: String) -> String:
	if int(runtime_result.get("cannon_hit_count", 0)) > 0:
		return "巨炮命中 %d 次：下次切换手动技能，在炮击倒计时内集中爆发。" % int(runtime_result["cannon_hit_count"])
	if int(runtime_result.get("cannon_suppressed_count", 0)) > 0:
		return "成功压制巨炮 %d 次：技能时机有效改善了本局生存与推进效率。" % int(runtime_result["cannon_suppressed_count"])
	if outcome == "retreat":
		return "全员安全撤退；调整阵位、技能或成长投资后即可再次挑战。"
	if outcome != "victory":
		return "攻势终止于第 %d 阶段；强化角色或工厂后可无损再战。" % (int(runtime_result.get("stage_reached", 0)) + 1)
	return "军团完成占领并无损返回；可连战，也可立即投入战果进行成长。"


func _growth_opportunity_copy(event: Dictionary) -> String:
	var gains: Array[String] = []
	var reward := event.get("reward", {}) as Dictionary
	if int(reward.get("gold", 0)) > 0:
		gains.append("金币可用于角色升级")
	if int(event.get("industrial_tech", 0)) > 0:
		gains.append("工业技术可用于扩建或技能研究")
	if int(event.get("hero_shards", 0)) > 0:
		gains.append("英雄数据可用于升星")
	return "下一步成长：%s" % ("继续挑战或选择一项永久升级" if gains.is_empty() else "；".join(gains))


func _show_epilogue(event: Dictionary = {}) -> void:
	screen = Screen.EPILOGUE
	_clear()
	var shell := _shell("第一幕完成 · 中央基地陷落", "五章战役终结，但无尽前线仍在呼叫")
	var state: RefCounted = game.current_state()
	var cleared_count := 0
	for stage_id in state.stage_progress.get("cleared_stages", []):
		if StageCatalog.ACT1_STAGE_IDS.has(String(stage_id)):
			cleared_count += 1
	var total_stars := 0
	var total_skill_levels := 0
	for hero in state.roster:
		total_stars += int(hero.star)
		total_skill_levels += int(hero.active_skill_level)
	var epilogue := EpilogueScreenScene.instantiate() as Control
	epilogue.call("configure", {
		"cleared_count": cleared_count,
		"roster_count": state.roster.size(),
		"total_stars": total_stars,
		"total_skill_levels": total_skill_levels,
		"battle_seconds": int(ceil(float(event.get("ticks", 0)) / 5.0)),
	})
	epilogue.connect("action_requested", _on_epilogue_action_requested)
	shell.add_child(epilogue)
	var credits := _label(
		"《马桶人工厂攻城》第一幕 · Godot 4.6 Web 版\n设计、程序与原创低模资产：本项目制作组",
		11,
		MUTED
	)
	credits.name = "CampaignCreditsLabel"
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.add_child(credits)


func _on_epilogue_action_requested(action_id: String) -> void:
	_play_ui_click()
	match action_id:
		"endless":
			_enter_endless_frontier()
		"goals":
			_show_goals()
		"base":
			_show_base()


func _enter_endless_frontier() -> void:
	selected_chapter = 6
	selected_stage_id = StageCatalog.ENDLESS_PREFIX + "1"
	_show_map()


func _battle_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	var state: RefCounted = game.current_state()
	for slot_index in state.formation.hero_ids().size():
		var hero_id: String = String(state.formation.hero_ids()[slot_index])
		var hero: RefCounted = state.hero_by_id(hero_id)
		if hero == null:
			continue
		var stats := HeroProgression.derived_battle_stats(hero)
		snapshots.append({
			"hero_id": hero.hero_id,
			"display_name": hero.display_name,
			"archetype_id": hero.archetype_id,
			"class_id": hero.class_id,
			"star": hero.star,
			"max_hp": maxi(1, int(stats["max_hp"])),
			"attack": maxi(1, maxi(int(stats["physical_atk"]), int(stats["magic_atk"]))),
			"defense": int(stats["defense"]),
			"speed_milli": int(stats["speed_milli"]),
			"crit_bp": int(stats["crit_bp"]),
			"slot": slot_index,
			"skill_id": FactoryCatalog.active_skill_for_archetype(hero.archetype_id),
			"skill_level": int(hero.active_skill_level),
			"auto_skill": bool(hero.auto_skill_enabled) or bool(settings_store.global_auto_skill),
		})
	return snapshots


func _claim_output() -> void:
	var result := _command("claim_factory_output", {"now_unix": int(Time.get_unix_time_from_system())})
	_after_action(result, _show_base)


func _claim_facility_output(facility_id: String) -> void:
	selected_facility_id = facility_id
	var result := _command("claim_facility_output", {
		"facility_id": facility_id,
		"now_unix": int(Time.get_unix_time_from_system()),
	})
	_after_action(result, _show_base)


func _upgrade_facility(facility_id: String) -> void:
	selected_facility_id = facility_id
	_after_action(_command("upgrade_facility", {
		"facility_id": facility_id,
		"now_unix": int(Time.get_unix_time_from_system()),
	}), _show_base)


func _claim_facility_work() -> void:
	_after_action(_command("claim_facility_work", {
		"now_unix": int(Time.get_unix_time_from_system()),
	}), _show_base)


func _begin_facility_construction(facility_id: String) -> void:
	factory_hud_panel = "build"
	construction_facility_id = facility_id
	construction_cell = Vector2i(999, 999)
	_reset_factory_pointer()
	_show_base()


func _cancel_facility_construction() -> void:
	construction_facility_id = ""
	construction_cell = Vector2i(999, 999)
	_reset_factory_pointer()
	_show_base()


func _confirm_facility_construction() -> void:
	if construction_facility_id.is_empty() or construction_cell.x == 999 or _is_factory_cell_occupied(construction_cell):
		audio_director.play_cue(&"error", -18.0)
		return
	var facility_id := construction_facility_id
	var confirmed_cell := construction_cell
	selected_facility_id = facility_id
	factory_hud_panel = "facility"
	construction_facility_id = ""
	construction_cell = Vector2i(999, 999)
	_reset_factory_pointer()
	var result := _command("construct_facility", {
		"facility_id": facility_id,
		"now_unix": int(Time.get_unix_time_from_system()),
		"grid_x": confirmed_cell.x,
		"grid_z": confirmed_cell.y,
	})
	audio_director.play_cue(&"build" if bool(result.get("ok", false)) else &"error", -9.0)
	_after_action(result, _show_base)


func _upgrade_hero(hero_id: String) -> void:
	_after_action(_command("upgrade_permanent_hero", {"hero_id": hero_id}), _show_legion)


func _upgrade_star(hero_id: String) -> void:
	_after_action(_command("upgrade_hero_star", {"hero_id": hero_id}), _show_legion)


func _research_active_skill(hero_id: String) -> void:
	_after_action(_command("research_active_skill", {"hero_id": hero_id}), _show_legion)


func _assign_specialist(hero_id: String, facility_id: String) -> void:
	_after_action(_command("assign_factory_specialist", {"hero_id": hero_id, "facility_id": facility_id}), _show_legion)


func _toggle_auto_skill(hero_id: String, enabled: bool) -> void:
	_after_action(_command("set_auto_skill_preference", {"hero_id": hero_id, "enabled": enabled}), _show_legion)


func _confirm_formation() -> void:
	var slots := game.current_state().formation.to_dict() as Dictionary
	var payload: Dictionary = {}
	for key in ["commander", "troop_1", "troop_2", "troop_3", "troop_4", "troop_5"]:
		payload[key] = String(slots.get(key, ""))
	_after_action(_command("set_formation", payload), _show_legion)


func _claim_task() -> void:
	var task := OnboardingService.snapshot(game.current_state())
	_after_action(_command("claim_onboarding_task", {"task_id": String(task.get("task_id", ""))}), _show_base)


func _claim_achievement(achievement_id: String) -> void:
	var request_id := "achievement:%s:%d" % [achievement_id, Time.get_ticks_msec()]
	_after_action(_command("claim_achievement", {
		"achievement_id": achievement_id,
		"generation": 0,
		"request_id": request_id,
	}, request_id), _show_goals)


func _claim_meta_mission(mission_id: String, generation: int) -> void:
	_after_action(_command("claim_meta_mission", {
		"mission_id": mission_id,
		"generation": generation,
	}, "meta-mission:%s:%d" % [mission_id, generation]), _show_goals)


func _claim_meta_pass(level: int) -> void:
	var season_id := String(game.current_state().meta_progression.season_id)
	_after_action(_command("claim_meta_pass_level", {"level": level}, "meta-pass:%s:%d" % [season_id, level]), _show_goals)


func _claim_all_meta_pass() -> void:
	var season_id := String(game.current_state().meta_progression.season_id)
	_after_action(_command("claim_all_meta_pass_levels", {}, "meta-pass-all:%s:%d" % [
		season_id,
		MetaCatalog.pass_level(int(game.current_state().meta_progression.season_merit)),
	]), _show_goals)


func _claim_all_commander_rewards() -> void:
	var level := MetaCatalog.commander_level(int(game.current_state().meta_progression.commander_xp))
	_after_action(_command("claim_all_commander_level_rewards", {}, "commander-rewards-through:%d" % level), _show_goals)


func _claim_all_meta_achievements() -> void:
	var state: RefCounted = game.current_state()
	var claimable := 0
	for definition in MetaCatalog.ACHIEVEMENTS:
		var achievement_id := String(definition["id"])
		if (
			not state.meta_progression.achievement_claimed.has(achievement_id)
			and int(state.meta_progression.achievement_progress.get(achievement_id, 0)) >= int(definition["target"])
		):
			claimable += 1
	_after_action(_command(
		"claim_all_meta_achievements",
		{},
		"meta-achievements:%d:%d" % [int(state.revision), claimable]
	), _show_goals)


func _claim_meta_achievement(achievement_id: String) -> void:
	_after_action(_command("claim_meta_achievement", {"achievement_id": achievement_id}, "meta-achievement:%s" % achievement_id), _show_goals)


func _select_formation_slot(slot: String) -> void:
	formation_edit_slot = slot
	_show_legion()


func _assign_formation_slot(slot: String, hero_id: String) -> void:
	_after_action(_command("assign_formation_slot", {
		"slot": slot,
		"hero_id": hero_id,
	}), _show_legion)


func _signal_recruit(count: int) -> void:
	var result := _command("signal_recruit", {
		"count": count,
		"target_archetype": "parasite",
	})
	if bool(result.get("ok", false)):
		var results := (result.get("event", {}) as Dictionary).get("results", []) as Array
		last_recruit_results.clear()
		var summaries: Array[String] = []
		for item in results:
			var draw := item as Dictionary
			last_recruit_results.append(draw.duplicate(true))
			summaries.append("%s %s" % [String(draw.get("rarity", "R")), HeroGenerator.archetype_display_name(String(draw.get("archetype_id", "")))])
		_notify("招募完成：%s" % "、".join(summaries))
		_show_legion()
	else:
		_notify(_error_copy(String(result.get("error", "招募失败"))))


func _follow_task(target: String, stage_id: String = "") -> void:
	match target:
		"factory", "repair":
			_show_base() if target == "factory" else _show_legion()
		"legion", "formation":
			_show_legion()
		"research":
			_open_research_lab()
		"expedition":
			if not stage_id.is_empty():
				selected_stage_id = stage_id
				_start_stage_battle(stage_id)
			else:
				_show_map()
		_:
			_show_map()


func _reward_text(reward: Dictionary) -> String:
	var labels := {
		"toilet_coins": "金币",
		"industrial_tech": "技术",
		"porcelain": "陶瓷",
		"parts": "零件",
		"sludge": "能源",
		"hero_shards": "碎片",
		"skill_chips": "芯片",
	}
	var values: Array[String] = []
	for key in ["toilet_coins", "industrial_tech", "porcelain", "parts", "sludge", "hero_shards", "skill_chips"]:
		if int(reward.get(key, 0)) > 0:
			values.append("%s +%d" % [labels[key], int(reward[key])])
	return "  ".join(values)


func _retreat() -> void:
	if battle_world != null:
		battle_world.request_retreat()


func _after_action(result: Dictionary, refresh: Callable) -> void:
	if bool(result.get("ok", false)):
		refresh.call()
		_notify(_success_copy(result))
	else:
		_notify(_error_copy(String(result.get("error", "操作失败"))))


func _success_copy(result: Dictionary) -> String:
	var event := result.get("event", {}) as Dictionary
	match String(event.get("type", "")):
		"factory_output_claimed":
			var material_copy := _reward_text(event.get("materials", {}) as Dictionary)
			var overflow_copy := _reward_text(event.get("overflow", {}) as Dictionary)
			return "已入库：%s%s" % [
				material_copy if not material_copy.is_empty() else "库存已满",
				" · 溢出 %s" % overflow_copy if not overflow_copy.is_empty() else "",
			]
		"facility_upgraded":
			return "%s已升至 Lv.%d" % [
				FACILITY_NAMES.get(String(event.get("facility_id", "")), "建筑"),
				int(event.get("level", 1)),
			]
		"facility_constructed":
			return "%s已落成，Lv.1 功能开始运转" % FACILITY_NAMES.get(
				String(event.get("facility_id", "")),
				"设施"
			)
		"facility_work_started":
			return "%s已进入%s队列，请等待完成" % [
				FACILITY_NAMES.get(String(event.get("facility_id", "")), "设施"),
				"建造" if String(event.get("work_type", "")) == "construction" else "升级",
			]
		"blueprint_research_started":
			return "角色研发已开始，完成后可领取"
		"hero_upgraded":
			return "角色已升至 Lv.%d，战力提升" % int(event.get("level", 1))
		"hero_repaired":
			return "维修完成，战备恢复至 %d%%" % int(event.get("readiness", 100))
		"onboarding_task_claimed":
			return "行动战果已领取"
		_:
			return "操作完成"


func _command(type: String, payload: Dictionary, business_key: String = "") -> Dictionary:
	command_serial += 1
	var command_id := "%s-%d-%d" % [type, Time.get_ticks_msec(), command_serial]
	var result: Dictionary = game.execute_command({
		"command_id": command_id,
		"type": type,
		"payload": payload,
		"business_key": business_key if not business_key.is_empty() else command_id,
		"expected_revision": game.current_state().revision,
		"requested_at": int(Time.get_unix_time_from_system()),
	})
	playtest_journal.record_event("command_result", {
		"command_type": type,
		"ok": bool(result.get("ok", false)),
		"error": String(result.get("error", "")),
		"revision_after": int(game.current_state().revision),
	})
	return result


func _shell(title_text: String, subtitle: String, reveal_world: bool = false) -> VBoxContainer:
	playtest_journal.record_event("screen_view", {"screen": _screen_id(screen)})
	var bg := ColorRect.new()
	bg.color = Color(BG, 0.18) if reveal_world else BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(bg)
	var safe := MarginContainer.new()
	safe.name = "MobileSafeArea"
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_safe_margin = safe
	_apply_safe_margins()
	ui_root.add_child(safe)
	var root := VBoxContainer.new()
	root.name = "AppShellRoot"
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(root)
	var header_panel := PanelContainer.new()
	header_panel.name = "AppShellHeader"
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_panel.add_theme_stylebox_override(
		"panel",
		_box(Color(PANEL, 0.9 if reveal_world else 0.82), 2, Color(EMBER, 0.55))
	)
	root.add_child(header_panel)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header_panel.add_child(header)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	var title_label := _label(title_text, 21, TEXT)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.add_theme_color_override("font_outline_color", Color(BG, 0.85))
	titles.add_child(title_label)
	var subtitle_label := _label(subtitle, 12, Color(MUTED, 0.9))
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	titles.add_child(subtitle_label)
	if screen not in [Screen.TITLE, Screen.SETTINGS, Screen.BATTLE, Screen.HELP]:
		var settings := _button("≡", Callable(self, "_show_settings").bind(screen), false)
		settings.name = "TopBarSettingsButton"
		settings.tooltip_text = "设置"
		settings.custom_minimum_size = Vector2(52, 48)
		header.add_child(settings)
	toast = _label("", 12, CYAN)
	toast.custom_minimum_size.y = 0
	toast.visible = false
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.offset_left = -210
	toast.offset_right = 210
	toast.offset_top = 72
	toast.offset_bottom = 98
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_constant_override("outline_size", 4)
	toast.add_theme_color_override("font_outline_color", Color(BG, 0.9))
	ui_root.add_child(toast)
	_apply_mobile_interactive_targets.call_deferred()
	return root


func _screen_id(value: Screen) -> String:
	match value:
		Screen.BOOT:
			return "boot"
		Screen.TITLE:
			return "title"
		Screen.SETTINGS:
			return "settings"
		Screen.BASE:
			return "base"
		Screen.MAP:
			return "map"
		Screen.LEGION:
			return "legion"
		Screen.GOALS:
			return "goals"
		Screen.INTELLIGENCE:
			return "intelligence"
		Screen.BATTLE:
			return "battle"
		Screen.RESULT:
			return "result"
		Screen.EPILOGUE:
			return "epilogue"
		Screen.HELP:
			return "help"
		_:
			return "unknown"


func _build_factory_world() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "FactoryEnvironment"
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color("#151a1c")
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color("#6e7775")
	environment_resource.ambient_light_energy = 0.46
	environment.environment = environment_resource
	world_host.add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.name = "FactorySun"
	sun.rotation_degrees = Vector3(-42.0, -34.0, 0.0)
	sun.light_color = Color("#e6a66c")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	world_host.add_child(sun)

	factory_camera = Camera3D.new()
	factory_camera.name = "FactoryCamera"
	factory_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	factory_camera.size = factory_camera_size
	_apply_factory_camera_orbit()
	factory_camera.current = true
	world_host.add_child(factory_camera)

	var island := MeshInstance3D.new()
	island.name = "FactoryIsland"
	var island_mesh := CylinderMesh.new()
	island_mesh.top_radius = 10.5
	island_mesh.bottom_radius = 9.3
	island_mesh.height = 0.7
	island_mesh.radial_segments = 16
	island.mesh = island_mesh
	island.position.y = -0.38
	island.material_override = _factory_material(Color("#303735"), 0.98)
	world_host.add_child(island)
	_add_factory_paths()
	_add_factory_grid()
	for facility_id in game.current_state().factory.facility_placements:
		if int(game.current_state().factory.facilities.get(facility_id, 0)) > 0:
			_add_factory_building(String(facility_id))
	if not construction_facility_id.is_empty() and construction_cell.x != 999:
		_add_construction_preview()


func _add_factory_grid() -> void:
	for grid_z in range(-FACTORY_GRID_RADIUS, FACTORY_GRID_RADIUS + 1):
		for grid_x in range(-FACTORY_GRID_RADIUS, FACTORY_GRID_RADIUS + 1):
			var cell := Vector2i(grid_x, grid_z)
			var body := StaticBody3D.new()
			body.name = "FactoryGridCell_%d_%d" % [grid_x, grid_z]
			body.position = _factory_cell_position(cell)
			body.set_meta("grid_cell", cell)
			body.collision_layer = 16
			body.collision_mask = 0
			world_host.add_child(body)
			var occupied := _is_factory_cell_occupied(cell)
			var selected := construction_cell == cell
			var color := Color("#a83f46") if selected and occupied else (CYAN if selected else Color("#456f68"))
			var tile := _factory_box(Vector3(2.82, 0.09, 2.82), Color(color, 0.82 if not construction_facility_id.is_empty() else 1.0))
			tile.position.y = 0.045
			tile.visible = not construction_facility_id.is_empty()
			body.add_child(tile)
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(2.86, 0.18, 2.86)
			collision.shape = shape
			collision.position.y = 0.09
			body.add_child(collision)


func _factory_cell_position(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * FACTORY_GRID_SPACING, 0.0, float(cell.y) * FACTORY_GRID_SPACING)


func _is_factory_cell_occupied(cell: Vector2i) -> bool:
	for facility_id in game.current_state().factory.facility_placements:
		if int(game.current_state().factory.facilities.get(facility_id, 0)) <= 0:
			continue
		var placement := game.current_state().factory.facility_placements[facility_id] as Array
		if placement.size() == 2 and int(placement[0]) == cell.x and int(placement[1]) == cell.y:
			return true
	return false


func _add_construction_preview() -> void:
	var preview := Node3D.new()
	preview.name = "ConstructionPreview"
	preview.position = _factory_cell_position(construction_cell)
	world_host.add_child(preview)
	var valid := not _is_factory_cell_occupied(construction_cell)
	var color: Color = FACTORY_BUILDING_COLORS[construction_facility_id] if valid else RED
	var ghost := _factory_box(Vector3(2.3, 1.7, 1.9), Color(color, 0.55))
	ghost.position.y = 1.0
	preview.add_child(ghost)


func _add_factory_paths() -> void:
	for path_data in [
		[Vector3(0.0, 0.02, 0.9), Vector3(1.6, 0.08, 7.8)],
		[Vector3(-2.6, 0.02, 0.2), Vector3(4.8, 0.08, 1.25)],
		[Vector3(2.6, 0.02, 0.2), Vector3(4.8, 0.08, 1.25)],
	]:
		var path := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = path_data[1]
		path.mesh = mesh
		path.position = path_data[0]
		path.material_override = _factory_material(Color("#555b58"), 1.0)
		world_host.add_child(path)


func _add_factory_building(facility_id: String) -> void:
	var level := int(game.current_state().factory.facilities.get(facility_id, 0))
	var root := StaticBody3D.new()
	root.name = "FactoryBuilding_%s" % facility_id
	var placement := game.current_state().factory.facility_placements.get(facility_id, [0, 0]) as Array
	root.position = _factory_cell_position(Vector2i(int(placement[0]), int(placement[1])))
	root.set_meta("facility_id", facility_id)
	root.collision_layer = 8
	root.collision_mask = 0
	world_host.add_child(root)

	var pad_color := CYAN.darkened(0.35) if selected_facility_id == facility_id else Color("#364853")
	var pad := _factory_box(Vector3(3.2, 0.28, 2.8), pad_color)
	pad.position.y = 0.14
	root.add_child(pad)
	if level <= 0:
		var foundation := _factory_box(Vector3(2.45, 0.16, 2.05), Color("#53636b"))
		foundation.position.y = 0.32
		root.add_child(foundation)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(3.2, 1.0, 2.9)
		collision.shape = shape
		collision.position.y = 0.5
		root.add_child(collision)
		return
	var building_color: Color = FACTORY_BUILDING_COLORS[facility_id]
	var height := 1.7 + float(level - 1) * 0.32
	var core := _factory_box(Vector3(2.3, height, 1.9), building_color)
	core.position.y = 0.28 + height * 0.5
	root.add_child(core)
	_add_building_silhouette(root, facility_id, building_color, height)
	_add_factory_activity(root, facility_id, building_color, height)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.2, 3.8, 2.9)
	collision.shape = shape
	collision.position.y = 1.9
	root.add_child(collision)

	var title := Label3D.new()
	title.name = "BuildingLabel"
	title.text = "%s  Lv.%d" % [FACILITY_NAMES[facility_id], level]
	title.font = CJKFont
	title.font_size = 34
	title.pixel_size = 0.0055
	title.outline_size = 8
	title.modulate = TEXT
	title.position = Vector3(0.0, 3.15 + float(level - 1) * 0.28, 0.0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.no_depth_test = true
	title.visible = false
	root.add_child(title)

	if FACTORY_RESOURCE_NAMES.has(facility_id):
		var preview := LogisticsService.facility_output_preview(
			game.current_state(),
			facility_id,
			int(Time.get_unix_time_from_system())
		)
		var amount := int(preview.get("amount", 0))
		var bubble := Label3D.new()
		bubble.name = "OutputBubble"
		bubble.text = "可收 %d" % amount
		bubble.font = CJKFont
		bubble.font_size = 28
		bubble.pixel_size = 0.0055
		bubble.outline_size = 8
		bubble.modulate = GOLD if amount > 0 else MUTED
		bubble.position = Vector3(0.0, 4.05 + float(level - 1) * 0.28, 0.0)
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.no_depth_test = true
		bubble.visible = false
		root.add_child(bubble)


func _add_factory_world_labels() -> void:
	var interaction_area := ui_root.find_child("FactoryWorldInteractionArea", true, false) as Control
	var interaction_rect := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	if interaction_area != null and interaction_area.size.x > 0.0 and interaction_area.size.y > 0.0:
		interaction_rect = interaction_area.get_global_rect()
	for facility_id_value in game.current_state().factory.facility_placements.keys():
		var facility_id := String(facility_id_value)
		var building := world_host.get_node_or_null("FactoryBuilding_%s" % facility_id) as Node3D
		if building == null:
			continue
		var level := int(game.current_state().factory.facilities.get(facility_id, 0))
		if level <= 0:
			continue
		var text := "%s  Lv.%d" % [FACILITY_NAMES[facility_id], level]
		if level > 0 and FACTORY_RESOURCE_NAMES.has(facility_id):
			var preview := LogisticsService.facility_output_preview(
				game.current_state(),
				facility_id,
				int(Time.get_unix_time_from_system())
			)
			text += "\n可收 %d" % int(preview.get("amount", 0))
		var marker := _button(
			text,
			Callable(self, "_activate_factory_building").bind(facility_id),
			selected_facility_id == facility_id
		)
		marker.name = "FactoryMarker_%s" % facility_id
		marker.add_theme_font_size_override("font_size", 12)
		marker.custom_minimum_size = Vector2(116, 42 if level <= 0 or FACTORY_RESOURCE_NAMES.has(facility_id) else 32)
		marker.size = marker.custom_minimum_size
		var projected := factory_camera.unproject_position(building.global_position + Vector3(0.0, 3.25, 0.0))
		var desired := projected - Vector2(marker.size.x * 0.5, marker.size.y * 0.5)
		marker.position = Vector2(
			clampf(desired.x, interaction_rect.position.x + 4.0, interaction_rect.end.x - marker.size.x - 4.0),
			clampf(desired.y, interaction_rect.position.y + 4.0, interaction_rect.end.y - marker.size.y - 4.0)
		)
		ui_root.add_child(marker)


func _add_building_silhouette(root: Node3D, facility_id: String, color: Color, height: float) -> void:
	match facility_id:
		"command_center":
			var tower := _factory_cylinder(0.45, 0.45, 1.8, color.lightened(0.12))
			tower.position = Vector3(0.0, height + 1.15, 0.0)
			root.add_child(tower)
			var beacon := _factory_cylinder(0.1, 0.1, 1.2, CYAN)
			beacon.position = Vector3(0.0, height + 2.55, 0.0)
			root.add_child(beacon)
		"porcelain_plant":
			for x in [-0.65, 0.65]:
				var tank := _factory_cylinder(0.48, 0.48, 1.45, Color("#f4f7f5"))
				tank.position = Vector3(x, height + 0.68, 0.0)
				root.add_child(tank)
		"parts_workshop":
			var chimney := _factory_cylinder(0.32, 0.4, 2.0, Color("#59646d"))
			chimney.position = Vector3(0.65, height + 0.9, 0.0)
			root.add_child(chimney)
		"energy_station":
			for x in [-0.62, 0.62]:
				var cell := _factory_cylinder(0.42, 0.42, 1.55, Color("#92e276"))
				cell.position = Vector3(x, height + 0.72, 0.0)
				root.add_child(cell)
		"repair_center":
			var cross_h := _factory_box(Vector3(1.35, 0.38, 0.22), Color.WHITE)
			cross_h.position = Vector3(0.0, height * 0.58, -1.0)
			root.add_child(cross_h)
			var cross_v := _factory_box(Vector3(0.38, 1.35, 0.22), Color.WHITE)
			cross_v.position = Vector3(0.0, height * 0.58, -1.02)
			root.add_child(cross_v)
		"research_lab":
			var dome := _factory_cylinder(0.85, 0.62, 1.2, color.lightened(0.2))
			dome.position = Vector3(0.0, height + 0.58, 0.0)
			root.add_child(dome)


func _add_factory_activity(root: Node3D, facility_id: String, color: Color, height: float) -> void:
	var activity := Node3D.new()
	activity.name = "Activity"
	activity.set_meta("motion_enabled", false)
	root.add_child(activity)
	if FACTORY_RESOURCE_NAMES.has(facility_id):
		var arm_a := _factory_box(Vector3(1.25, 0.12, 0.18), color.lightened(0.3))
		var arm_b := _factory_box(Vector3(0.18, 0.12, 1.25), color.lightened(0.3))
		activity.add_child(arm_a)
		activity.add_child(arm_b)
		activity.position = Vector3(0.0, height + 1.65, 0.0)
		if settings_store.reduced_motion:
			return
		activity.set_meta("motion_enabled", true)
		var spin := activity.create_tween().set_loops()
		spin.tween_property(activity, "rotation_degrees:y", 360.0, 3.2)
	elif facility_id == "repair_center":
		activity.position = Vector3(0.0, height + 0.22, -1.08)
		var pulse := _factory_box(Vector3(0.62, 0.62, 0.08), Color("#ff6b64"))
		activity.add_child(pulse)
		if settings_store.reduced_motion:
			return
		activity.set_meta("motion_enabled", true)
		var beat := activity.create_tween().set_loops()
		beat.tween_property(activity, "scale", Vector3(1.18, 1.18, 1.18), 0.45)
		beat.tween_property(activity, "scale", Vector3.ONE, 0.45)
	elif facility_id == "research_lab":
		activity.position = Vector3(0.0, height + 1.4, 0.0)
		var scanner := _factory_box(Vector3(1.8, 0.08, 0.16), Color("#cfb4ff"))
		activity.add_child(scanner)
		if settings_store.reduced_motion:
			return
		activity.set_meta("motion_enabled", true)
		var scan := activity.create_tween().set_loops()
		scan.tween_property(activity, "rotation_degrees:y", 360.0, 2.4)


func _factory_box(size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _factory_material(color, 0.82)
	return instance


func _factory_cylinder(top_radius: float, bottom_radius: float, height: float, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 10
	instance.mesh = mesh
	instance.material_override = _factory_material(color, 0.78)
	return instance


func _factory_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _add_nav(shell: VBoxContainer, active: Screen) -> void:
	var nav := HBoxContainer.new()
	nav.name = "PrimaryNavigation"
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 8)
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(nav)
	var entries: Array = [
		["工厂", Screen.BASE, _show_base],
		["战区", Screen.MAP, _show_map],
		["军团", Screen.LEGION, _show_legion],
		["行动", Screen.GOALS, _show_goals],
	]
	var goal_claimable := int(MetaProgressionService.claimable_summary(game.current_state())["total"])
	for entry in entries:
		var label := String(entry[0])
		if int(entry[1]) == Screen.GOALS and goal_claimable > 0:
			label = "%s  %d" % [label, goal_claimable]
		var button := _button(label, entry[2], int(entry[1]) == active)
		button.name = "TopNav%sButton" % String(entry[0])
		if int(entry[1]) == Screen.GOALS:
			button.tooltip_text = "%d 份战报待确认" % goal_claimable if goal_claimable > 0 else "暂无新战报"
		button.custom_minimum_size = Vector2(0, 46)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(button)


func _panel_vbox(title_text: String, separation: int) -> VBoxContainer:
	var box := PanelVBox.new()
	box.add_theme_constant_override("separation", separation)
	box.panel_style = _box(Color(PANEL, 0.94), 3, Color(LINE, 0.8))
	var heading := _label("  %s" % title_text, 17, GOLD)
	heading.custom_minimum_size.y = 28
	box.add_child(heading)
	return box


func _label(value: String, size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_override("font", CJKFont)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


func _status_pill(value: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(color, 0.16), 8, color))
	var label := _label(value, 14, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _segmented_tabs(
	specs: Array,
	active_key: String,
	callback: Callable,
	name_prefix: String
) -> HBoxContainer:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for spec_value in specs:
		var spec := spec_value as Array
		var key := String(spec[0])
		var button := _button(String(spec[1]), callback.bind(key), key == active_key)
		button.name = "%s%sTab" % [name_prefix, key.capitalize()]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = key == active_key
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
	return tabs


func _progress_bar(value: float, maximum: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maxf(1.0, maximum)
	bar.value = value
	bar.step = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#09131c")
	background.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _set_progress_fill(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill", fill)


func _button(value: String, callback: Callable, primary: bool) -> Button:
	var node := Button.new()
	node.text = value
	node.add_theme_font_override("font", CJKFont)
	node.add_theme_font_size_override("font_size", 15)
	node.custom_minimum_size.y = 48.0
	node.focus_mode = Control.FOCUS_ALL
	node.add_theme_stylebox_override("normal", _box(GOLD if primary else PANEL_2, 3, GOLD if primary else LINE))
	node.add_theme_stylebox_override("hover", _box(GOLD.lightened(0.12) if primary else PANEL_2.lightened(0.1), 3, GOLD))
	node.add_theme_stylebox_override("pressed", _box(GOLD.darkened(0.18) if primary else PANEL, 3, GOLD))
	node.add_theme_stylebox_override("focus", _box(Color(GOLD, 0.22), 3, Color.WHITE))
	node.add_theme_stylebox_override("disabled", _box(Color("#101417"), 3, Color("#2a3033")))
	node.add_theme_color_override("font_color", BG if primary else TEXT)
	node.add_theme_color_override("font_hover_color", BG if primary else TEXT)
	node.add_theme_color_override("font_pressed_color", BG if primary else TEXT)
	node.add_theme_color_override("font_disabled_color", Color("#60737d"))
	node.pressed.connect(_play_ui_click)
	node.pressed.connect(callback, CONNECT_DEFERRED)
	return node


func _play_ui_click() -> void:
	if audio_director != null:
		audio_director.play_cue(&"ui_click", -13.0)


func _box(color: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _theme() -> Theme:
	var value := Theme.new()
	value.default_font = CJKFont
	value.default_font_size = 15
	return value


func _clear() -> void:
	_remember_scroll_positions()
	ui_rebuild_generation += 1
	var restore_generation := ui_rebuild_generation
	_restore_scroll_positions.call_deferred(restore_generation)
	active_safe_margin = null
	get_viewport().gui_release_focus()
	for child in ui_root.get_children():
		child.name = "_RetiredUI%d" % child.get_instance_id()
		child.process_mode = Node.PROCESS_MODE_DISABLED
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		child.queue_free()
	for child in world_host.get_children():
		child.name = "_RetiredWorld%d" % child.get_instance_id()
		child.process_mode = Node.PROCESS_MODE_DISABLED
		child.queue_free()
	battle_world = null
	battle_pause_button = null
	battle_pause_overlay = null
	battle_pause_resume_button = null
	battle_status_label = null
	battle_auto_button = null
	battle_hud_screen = null
	battle_skill_buttons.clear()
	battle_unit_hud.clear()
	battle_is_paused = false
	factory_camera = null


func _remember_scroll_positions() -> void:
	var pending: Array[Node] = [ui_root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child in node.get_children():
			pending.append(child)
		if node is ScrollContainer and not String(node.name).is_empty():
			var scroll := node as ScrollContainer
			ui_scroll_positions[String(scroll.name)] = Vector2i(
				scroll.scroll_horizontal,
				scroll.scroll_vertical
			)


func _restore_scroll_positions(generation: int) -> void:
	await get_tree().process_frame
	if generation != ui_rebuild_generation:
		return
	var pending: Array[Node] = [ui_root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child in node.get_children():
			pending.append(child)
		if node is ScrollContainer:
			var scroll := node as ScrollContainer
			var saved := ui_scroll_positions.get(String(scroll.name), Vector2i.ZERO) as Vector2i
			scroll.scroll_horizontal = saved.x
			scroll.scroll_vertical = saved.y


func _build_orientation_gate() -> void:
	var interface := ui_root.get_parent()
	orientation_gate = Control.new()
	orientation_gate.name = "LandscapeOrientationGate"
	orientation_gate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	orientation_gate.mouse_filter = Control.MOUSE_FILTER_STOP
	orientation_gate.process_mode = Node.PROCESS_MODE_ALWAYS
	orientation_gate.z_index = 100
	interface.add_child(orientation_gate)

	var shade := ColorRect.new()
	shade.color = Color("#071018")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	orientation_gate.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orientation_gate.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 250)
	card.add_theme_stylebox_override("panel", _box(PANEL, 18, CYAN))
	center.add_child(card)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)
	var icon := _label("旋", 48, CYAN)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(icon)
	var title := _label("请旋转至横屏", 26, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var detail := _label("本游戏专为手机横屏设计\n旋转后将自动返回当前画面", 15, MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(detail)
	var hint := _label("进度已保留", 13, GREEN)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)


func _refresh_orientation_gate() -> void:
	if orientation_gate == null or not is_instance_valid(orientation_gate):
		return
	var should_gate: bool = bool(mobile_viewport.requires_landscape_gate()) if mobile_viewport != null else _requires_landscape_gate(_runtime_surface_size())
	if should_gate == orientation_gate_active:
		orientation_gate.visible = should_gate
		_set_web_orientation_overlay(should_gate)
		return
	orientation_gate_active = should_gate
	orientation_gate.visible = should_gate
	_set_web_orientation_overlay(should_gate)
	if should_gate and screen == Screen.BATTLE and not battle_is_paused:
		orientation_paused_battle = true
		_set_battle_paused(true)
	elif not should_gate:
		# 旋转回来后保持暂停，避免玩家在握持调整期间遭受战损。
		orientation_paused_battle = false


func _requires_landscape_gate(viewport_size: Vector2) -> bool:
	return MobileViewportAdapterScript.classify(viewport_size) == "portrait_blocked"


func _runtime_surface_size() -> Vector2:
	if mobile_viewport != null:
		return mobile_viewport.surface_size()
	return get_viewport().get_visible_rect().size


func _layout_profile() -> String:
	if not active_layout_profile.is_empty():
		return active_layout_profile
	return MobileViewportAdapterScript.classify(_runtime_surface_size())


func _on_mobile_layout_changed(snapshot: Dictionary) -> void:
	_apply_safe_margins()
	_apply_mobile_interactive_targets()
	_refresh_orientation_gate()
	var next_profile := String(snapshot.get("profile", _layout_profile()))
	if active_layout_profile.is_empty():
		active_layout_profile = next_profile
		return
	if next_profile == active_layout_profile:
		return
	active_layout_profile = next_profile
	if screen in [
		Screen.TITLE,
		Screen.SETTINGS,
		Screen.HELP,
		Screen.BASE,
		Screen.MAP,
		Screen.LEGION,
		Screen.GOALS,
		Screen.INTELLIGENCE,
		Screen.RESULT,
		Screen.BLUEPRINTS,
	]:
		_rebuild_screen_for_layout.call_deferred(screen)


func _rebuild_screen_for_layout(expected_screen: Screen) -> void:
	if screen != expected_screen or orientation_gate_active:
		return
	match screen:
		Screen.TITLE:
			_show_title()
		Screen.SETTINGS:
			_show_settings(settings_return_screen)
		Screen.HELP:
			_show_help(help_return_screen)
		Screen.BASE:
			_show_base()
		Screen.MAP:
			_show_map()
		Screen.LEGION:
			_show_legion()
		Screen.GOALS:
			_show_goals()
		Screen.INTELLIGENCE:
			_show_intelligence()
		Screen.RESULT:
			_show_result()
		Screen.BLUEPRINTS:
			_show_blueprints()


func _apply_safe_margins() -> void:
	if active_safe_margin == null or not is_instance_valid(active_safe_margin):
		return
	var margins := Vector4(12.0, 8.0, 12.0, 8.0)
	if mobile_viewport != null:
		margins = mobile_viewport.safe_margins()
	active_safe_margin.add_theme_constant_override("margin_left", roundi(margins.x))
	active_safe_margin.add_theme_constant_override("margin_top", roundi(margins.y))
	active_safe_margin.add_theme_constant_override("margin_right", roundi(margins.z))
	active_safe_margin.add_theme_constant_override("margin_bottom", roundi(margins.w))


func _touch_target_height() -> float:
	if mobile_viewport == null:
		return 48.0
	return maxf(48.0, mobile_viewport.touch_target_height())


func _apply_mobile_interactive_targets() -> void:
	if ui_root == null:
		return
	_apply_mobile_interactive_target_to_branch(ui_root, _touch_target_height())


func _apply_mobile_interactive_target_to_branch(branch: Node, target_height: float) -> void:
	if branch is BaseButton or branch is Slider or branch is LineEdit or branch is TextEdit:
		var control := branch as Control
		if not control.has_meta("mobile_base_min_height"):
			control.set_meta("mobile_base_min_height", control.custom_minimum_size.y)
		var base_height := float(control.get_meta("mobile_base_min_height", 0.0))
		control.custom_minimum_size.y = maxf(base_height, target_height)
	for child in branch.get_children():
		_apply_mobile_interactive_target_to_branch(child, target_height)


func _set_web_orientation_overlay(visible: bool) -> void:
	if not OS.has_feature("web"):
		return
	var display_value := "flex" if visible else "none"
	JavaScriptBridge.eval("""
		(() => {
			const id = "godot-landscape-gate";
			let gate = document.getElementById(id);
			if (!gate) {
				gate = document.createElement("div");
				gate.id = id;
				gate.setAttribute("role", "status");
				gate.setAttribute("aria-live", "polite");
				gate.innerHTML = `
					<div style="font-size:42px;line-height:1;color:#32d3c2">旋</div>
					<strong style="font-size:26px;color:#eef7f8">请旋转至横屏</strong>
					<span style="font-size:16px;color:#91a9b4">本游戏专为手机横屏设计</span>
					<small style="font-size:14px;color:#76d889">旋转后自动继续 · 进度已保留</small>`;
				Object.assign(gate.style, {
					position: "fixed", inset: "0", zIndex: "2147483647",
					background: "#071018", alignItems: "center", justifyContent: "center",
					flexDirection: "column", gap: "14px", textAlign: "center",
					fontFamily: "system-ui, -apple-system, sans-serif",
					padding: "env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)"
				});
				document.body.appendChild(gate);
			}
			gate.style.display = "%s";
		})()
	""" % display_value)


func _show_fatal(message: String) -> void:
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(center)
	center.add_child(_label(message, 24, RED))


func _notify(message: String) -> void:
	if toast != null and is_instance_valid(toast):
		toast.text = message
		toast.visible = true
		toast.modulate = Color.WHITE
		var tween := toast.create_tween()
		tween.tween_interval(1.6)
		tween.tween_property(toast, "modulate:a", 0.0, 0.35)
		tween.tween_callback(func() -> void:
			if toast != null and is_instance_valid(toast):
				toast.visible = false
		)


func _estimated_damage(config: Dictionary) -> String:
	var team := CombatPower.formation_power(game.current_state())
	var recommended := maxi(1, int(config.get("recommended_power", 1)))
	if team >= recommended:
		return "低"
	if team * 100 >= recommended * 95:
		return "中"
	return "高"

func _error_copy(code: String) -> String:
	var known := {
		"NO_FACTORY_OUTPUT_READY": "当前没有可收取的产出",
		"NOT_ENOUGH_TOILET_COINS": "金币不足，先攻占城镇",
		"NOT_ENOUGH_FACTORY_MATERIALS": "后勤材料不足，先收取工厂产出",
		"NOT_ENOUGH_REPAIR_MATERIALS": "维修材料不足，等待工厂生产",
		"NOT_ENOUGH_HERO_SHARDS": "角色碎片不足，推进至 1-2 或章节 Boss",
		"NOT_ENOUGH_SKILL_CHIPS": "技能芯片不足，击败章节 Boss 后获得",
		"HERO_STAR_CAP_REACHED": "当前角色已经达到三星上限",
		"SPECIALTY_REQUIRES_TWO_STARS": "角色达到二星后才能派驻工厂",
		"REPAIR_SLOTS_FULL": "维修槽已满，升级维修中心可开放第二槽",
		"HERO_ALREADY_IN_REPAIR": "该角色已经进入等待维修",
		"NO_REPAIRS_READY": "还没有完成的等待维修",
		"NOT_ENOUGH_INDUSTRIAL_TECH": "工业技术不足，先攻占新城镇",
		"RESEARCH_LAB_LEVEL_TOO_LOW": "研究所等级不足，升级至 Lv.2 可研究技能Ⅲ",
		"META_MISSIONS_LOCKED": "通关 1-1 且指挥官达到 Lv2 后开放行动任务",
		"META_WEEKLY_LOCKED": "指挥官达到 Lv10 后开放周任务",
		"META_PASS_LOCKED": "通关 1-5 且指挥官达到 Lv5 后开放战令",
		"META_ACHIEVEMENTS_LOCKED": "通关 1-2 且指挥官达到 Lv3 后开放成就",
		"SIGNAL_RECRUIT_LOCKED": "通关 1-3 且指挥官达到 Lv4 后开放信号招募",
		"PASS_NO_CLAIMABLE_REWARDS": "当前没有可领取的战令奖励",
		"COMMANDER_NO_CLAIMABLE_REWARDS": "当前没有可领取的指挥官等级奖励",
		"ACHIEVEMENT_NO_CLAIMABLE_REWARDS": "当前没有可领取的成就奖励",
		"FORMATION_SLOT_INVALID": "目标阵位无效",
		"HERO_ALREADY_IN_FORMATION_SLOT": "该英雄已经位于目标阵位",
		"ACTIVE_SKILL_LEVEL_CAP_REACHED": "主动技能已达到 Lv.3 上限",
		"HERO_ALREADY_READY": "该角色战备已经满额",
		"HERO_LEVEL_CAP_REACHED": "角色已达到当前等级上限",
		"FACILITY_LEVEL_CAP_REACHED": "设施已达到当前等级上限",
		"FACILITY_GRID_CELL_OUT_OF_BOUNDS": "该位置超出工厂建造范围",
		"FACILITY_GRID_CELL_OCCUPIED": "该格子已有建筑，请重新选址",
		"FACILITY_WORK_BUSY": "施工队正在忙，请先等待当前工程完成",
		"FACILITY_WORK_NOT_READY": "当前工程还未完成",
		"BLUEPRINT_RESEARCH_BUSY": "研究所正在研发其他角色",
		"BLUEPRINT_RESEARCH_NOT_READY": "角色研发还未完成",
		"SAVE_UNAVAILABLE": "本次操作未生效：存档服务不可用，请打开设置并下载备份",
		"SAVE_FAILED": "本次操作未生效：浏览器存储写入失败，请打开设置下载备份后再重试",
	}
	return String(known.get(code, code))

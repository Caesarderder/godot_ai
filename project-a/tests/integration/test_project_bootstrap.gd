extends GutTest

const MAIN_SCENE_PATH := "res://game/scenes/app/main.tscn"
const GAME_AUTOLOADS := [
	"SystemClock",
	"SaveManager",
	"ContentCatalog",
	"EventBus",
	"Game",
	"AppLifecycle",
]

const AUTOLOAD_PATHS := {
	"_mcp_game_helper": "*res://addons/godot_ai/runtime/game_helper.gd",
	"SystemClock": "*res://game/scripts/autoloads/system_clock.gd",
	"SaveManager": "*res://game/scripts/autoloads/save_manager.gd",
	"ContentCatalog": "*res://game/scripts/autoloads/content_catalog.gd",
	"EventBus": "*res://game/scripts/autoloads/event_bus.gd",
	"Game": "*res://game/scripts/autoloads/game.gd",
	"AppLifecycle": "*res://game/scripts/autoloads/app_lifecycle.gd",
}


class FakeGame:
	extends RefCounted
	@warning_ignore("unused_signal")
	signal game_ready
	var has_booted := true
	var state := {
		"save_id": "0123456789abcdef",
		"revision": 7,
		"economy": { "offline_seconds": 3661 },
		"offline_anchor_unix": 1_725_000_000,
	}


	func get_state() -> Dictionary:
		return state.duplicate(true)


func test_main_scene_is_registered_and_loadable() -> void:
	assert_eq(
			ProjectSettings.get_setting("application/run/main_scene"),
			MAIN_SCENE_PATH,
	)
	var scene := load(MAIN_SCENE_PATH) as PackedScene
	assert_not_null(scene)
	var instance := scene.instantiate()
	assert_eq(instance.name, "Main")
	instance.free()


func test_main_scene_keeps_touch_friendly_content_padding() -> void:
	var scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := scene.instantiate()
	add_child_autofree(instance)
	await get_tree().process_frame
	var safe_area := instance.get_node("SafeArea") as MarginContainer
	assert_eq(safe_area.get_theme_constant("margin_left"), 48)
	assert_eq(safe_area.get_theme_constant("margin_top"), 48)


func test_main_scene_exposes_the_m1_status_dashboard_instead_of_m0_placeholder() -> void:
	var scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := scene.instantiate()
	add_child_autofree(instance)
	await get_tree().process_frame

	assert_not_null(instance.get_script())
	assert_eq(instance.get_node("SafeArea/Content/Subtitle").text, "M1 · 事务与时间脊柱在线")
	assert_not_null(instance.get_node_or_null("SafeArea/Content/StateCard/StateContent/Revision"))
	assert_not_null(
		instance.get_node_or_null("SafeArea/Content/StateCard/StateContent/OfflineCredit")
	)
	var refresh := instance.get_node("SafeArea/Content/RefreshButton") as Button
	assert_false(refresh.disabled)
	assert_eq(refresh.text, "刷新 M1 状态")


func test_main_scene_renders_live_m1_state_and_refreshes_on_demand() -> void:
	var scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := scene.instantiate()
	add_child_autofree(instance)
	await get_tree().process_frame
	var fake_game := FakeGame.new()
	assert_true(instance.has_method("configure_game"))
	if instance.has_method("configure_game"):
		instance.configure_game(fake_game)

	assert_eq(instance.get_node("SafeArea/Content/Status").text, "M1 状态已加载")
	assert_eq(
		instance.get_node("SafeArea/Content/StateCard/StateContent/Persistence").text,
		"持久化：已安装快照",
	)
	assert_eq(
		instance.get_node("SafeArea/Content/StateCard/StateContent/SaveId").text,
		"存档：01234567…",
	)
	assert_eq(
		instance.get_node("SafeArea/Content/StateCard/StateContent/Revision").text,
		"状态版本：r7",
	)
	assert_eq(
		instance.get_node("SafeArea/Content/StateCard/StateContent/OfflineCredit").text,
		"累计离线收益：1小时 1分 1秒",
	)

	fake_game.state.revision = 8
	instance.get_node("SafeArea/Content/RefreshButton").pressed.emit()
	assert_eq(
		instance.get_node("SafeArea/Content/StateCard/StateContent/Revision").text,
		"状态版本：r8",
	)


func test_existing_tooling_and_game_autoloads_coexist_in_order() -> void:
	var root := get_tree().root
	assert_not_null(root.get_node_or_null("_mcp_game_helper"))
	var previous_index := root.get_node("_mcp_game_helper").get_index()
	for autoload_name: String in GAME_AUTOLOADS:
		var autoload := root.get_node_or_null(autoload_name)
		assert_not_null(autoload, "%s should be loaded" % autoload_name)
		assert_gt(autoload.get_index(), previous_index)
		previous_index = autoload.get_index()
	assert_true(Game.has_signal("game_ready"))
	assert_true(Game.has_method("get_state"))
	assert_true(Game.has_method("execute_command"))


func test_autoloads_point_to_owned_scripts() -> void:
	for autoload_name: String in AUTOLOAD_PATHS:
		assert_eq(
				ProjectSettings.get_setting("autoload/%s" % autoload_name),
				AUTOLOAD_PATHS[autoload_name],
		)


func test_mobile_portrait_contract() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1080)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/handheld/orientation"), 1)
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "mobile")


func test_android_back_notification_reaches_lifecycle_boundary() -> void:
	watch_signals(AppLifecycle)
	# gdlint-ignore-next-line private-access
	AppLifecycle._notification(AppLifecycle.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_signal_emitted(AppLifecycle, "back_navigation_requested")

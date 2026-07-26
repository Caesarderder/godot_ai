extends SceneTree

const AppBootstrapScript := preload("res://game/scripts/autoloads/app_bootstrap.gd")

class FakeGame:
	extends RefCounted
	var calls := 0
	var received_save: Object

	func bootstrap_with_manager(save_service: Object, _run_seed: int, _now_unix: int) -> String:
		calls += 1
		received_save = save_service
		return "created"


class FakeSave:
	extends RefCounted


func _init() -> void:
	var bootstrap := AppBootstrapScript.new()
	var game := FakeGame.new()
	var save := FakeSave.new()
	var status := bootstrap.initialize_with_services(game, save, 7, 11)
	if status != "created" or game.calls != 1 or game.received_save != save:
		push_error("APP_BOOTSTRAP_TESTS_FAIL: composition root did not wire services once")
		quit(1)
		return
	var repeated := bootstrap.initialize_with_services(game, save, 8, 12)
	if repeated != "created" or game.calls != 1:
		push_error("APP_BOOTSTRAP_TESTS_FAIL: initialization is not idempotent")
		quit(1)
		return
	var missing := AppBootstrapScript.new()
	if missing.initialize_with_services(null, save, 1, 1) != "game_service_unavailable":
		push_error("APP_BOOTSTRAP_TESTS_FAIL: missing game service is not explicit")
		quit(1)
		return
	print("APP_BOOTSTRAP_TESTS_OK")
	quit(0)

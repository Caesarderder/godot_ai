extends SceneTree

const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const SaveManagerCore := preload("res://game/scripts/persistence/save_manager.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := "user://factory_casualty_lifecycle_test.json"
	_cleanup(path)
	var manager: RefCounted = SaveManagerCore.new(path)
	var state: RefCounted = GameStateScript.create_new(20260726, 1000)
	var permanent_ids: Array[String] = state.roster_ids()
	_check(manager.save_state(state), "permanent-legion initial state persists")
	var executor: RefCounted = CommandExecutorScript.new(state, Callable(manager, "save_state"))
	var deployed: Array[String] = state.formation.hero_ids()
	var disabled: Array[String] = deployed.duplicate()
	var settled := _execute(executor, "lifecycle-defeat", "settle_battle", {
		"battle_id": "lifecycle-defeat",
		"stage_id": "stage_1_1",
		"outcome": "defeat",
		"ticks": 30,
		"deployed_unit_ids": deployed,
		"dead_unit_ids": disabled,
	})
	_check(bool(settled.get("ok", false)), "lossless settlement persists")
	_check(executor.state.roster_ids() == permanent_ids, "settlement never deletes permanent heroes")
	var loaded: Dictionary = manager.load_state()
	_check(bool(loaded.get("ok", false)), "lossless state reloads")
	if bool(loaded.get("ok", false)):
		executor = CommandExecutorScript.new(loaded["state"], Callable(manager, "save_state"))
		_check(executor.state.roster_ids() == permanent_ids, "permanent identities survive reload")
		for hero_id in disabled:
			_check(int(executor.state.hero_by_id(hero_id).readiness) == 100, "disabled hero reloads fully ready")
	var final_load: Dictionary = manager.load_state()
	_check(bool(final_load.get("ok", false)), "final state reloads")
	if bool(final_load.get("ok", false)):
		var final_state: RefCounted = final_load["state"]
		_check(int(final_state.schema_version) == 11, "final save remains schema v11")
		for hero_id in permanent_ids:
			_check(int(final_state.hero_by_id(hero_id).readiness) == 100, "all heroes remain lossless after reload")
		_check(final_state.factory.repair_orders.is_empty(), "legacy repair queue remains empty")
	_cleanup(path)
	if failures.is_empty():
		print("LIFECYCLE TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LIFECYCLE TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _execute(executor: RefCounted, command_id: String, command_type: String, payload: Dictionary) -> Dictionary:
	return executor.execute({
		"type": command_type,
		"command_id": command_id,
		"business_key": command_id,
		"expected_revision": int(executor.state.revision),
		"payload": payload,
	})


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _cleanup(path: String) -> void:
	for candidate in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(candidate)

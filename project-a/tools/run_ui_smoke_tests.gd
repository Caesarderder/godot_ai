extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	var scene := load("res://scenes/screens/main.tscn") as PackedScene
	if scene == null:
		_fail("main scene loads")
		_finish()
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	for _frame in 20:
		await process_frame
	_ok(root.size == Vector2i(844, 390), "viewport remains 844x390")
	_ok(instance.get_node_or_null("WorldHost") != null, "main scene has 3D host")
	_ok(instance.get_node_or_null("Interface/UIRoot") != null, "main scene has UI root")
	_ok(root.get_child_count() > 0, "main scene stays alive for mobile landscape smoke")
	instance.call("_show_factory")
	for _frame in 4:
		await process_frame
	var machine := instance.get_node_or_null("WorldHost/FactoryMachine_0")
	var factory_ui := instance.get_node("Interface/UIRoot").get_child(-1)
	_ok(machine != null, "factory view builds its 3D production machinery")
	await create_timer(0.65).timeout
	_ok(is_instance_valid(machine) and machine == instance.get_node_or_null("WorldHost/FactoryMachine_0"), "factory countdown refresh preserves machine and tween instances")
	_ok(is_instance_valid(factory_ui) and factory_ui.get_parent() != null, "factory countdown refresh preserves the current UI tree and interaction state")
	instance.call("_play_factory_claim_feedback", "smoke_hero", "ordinary.assault")
	await create_timer(0.22).timeout
	_ok(is_instance_valid(machine) and machine == instance.get_node_or_null("WorldHost/FactoryMachine_0"), "claim feedback runs against the existing factory world")
	_ok(instance.get_node_or_null("WorldHost/FactoryReveal") != null, "claim feedback exposes the produced hero before refresh")
	await create_timer(0.55).timeout
	_ok(is_instance_valid(machine), "full claim tween completes without an intermediate factory rebuild")
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("UI SMOKE TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("UI SMOKE TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	failures.append(message)

extends SceneTree

var failures: Array[String] = []
var game: FpsGame


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for action in [
		"move_forward",
		"move_back",
		"move_left",
		"move_right",
		"jump",
		"sprint",
		"fire",
		"reload",
		"restart_run",
	]:
		_check(InputMap.has_action(action), "semantic input action exists: %s" % action)

	var scene := load("res://game/fps_game.tscn") as PackedScene
	_check(scene != null, "real FPS scene loads")
	if scene == null:
		_finish()
		return
	game = scene.instantiate() as FpsGame
	root.add_child(game)
	await _wait_frames(5)

	_check(game.player != null, "scene owns a player")
	_check(game.get_enemies().size() == 4, "scene owns four sentries")
	_check(game.run_state.enemies_remaining == 4, "run begins with the full objective")
	_check(game.player.current_health == game.player.maximum_health, "player begins at full health")
	_check(game.player.rifle.ammo == 30 and game.player.rifle.reserve == 120, "rifle begins with authored ammo")

	var enemy := game.get_enemies()[0]
	var duplicate_data := DamageData.new(&"test", &"stable_attack", 17)
	var first_hit: Dictionary = enemy.apply_damage(duplicate_data)
	var duplicate_hit: Dictionary = enemy.apply_damage(duplicate_data)
	_check(bool(first_hit.get("accepted", false)), "first stable attack is accepted")
	_check(not bool(duplicate_hit.get("accepted", false)), "duplicate stable attack is rejected")
	_check(enemy.current_health == enemy.maximum_health - 17, "duplicate hit mutates health exactly once")

	game.restart_run()
	await _wait_frames(2)
	_check(enemy.current_health == enemy.maximum_health, "restart restores enemy health")
	_check(game.player.current_health == game.player.maximum_health, "restart restores player health")
	_check(game.run_state.shots_fired == 0 and game.run_state.hits == 0, "restart clears run statistics")

	var original_health_connections := game.player.get_signal_connection_list("health_changed").size()
	game.restart_run()
	game.restart_run()
	await _wait_frames(2)
	_check(
		game.player.get_signal_connection_list("health_changed").size() == original_health_connections,
		"restart does not duplicate player signal connections"
	)

	game.player.rifle.ammo = 10
	game.player.rifle.reserve = 8
	_check(game.player.rifle.reload(), "reload starts when magazine is not full")
	_check(not game.player.rifle.reload(), "reload cannot start twice")
	await create_timer(game.player.rifle.config.reload_seconds + 0.1).timeout
	_check(game.player.rifle.ammo == 18 and game.player.rifle.reserve == 0, "reload transfers reserve exactly once")

	game.restart_run()
	var expected_enemy_transforms: Array[Transform3D] = []
	for candidate in game.get_enemies():
		expected_enemy_transforms.append(candidate.global_transform)
		candidate.strafe_speed = 0.0
		candidate.attack_range = 0.1
	for target_index in game.get_enemies().size():
		var target := game.get_enemies()[target_index]
		target.global_position = Vector3(
			game.player.global_position.x,
			0.05,
			game.player.global_position.z - 5.0
		)
		await _wait_physics_frames(2)
		for shot_index in 3:
			game.player.rifle.set("_shot_cooldown", 0.0)
			var shot_result := game.player.rifle.fire_from(game.player.get_camera())
			_check(
				bool(shot_result.get("accepted", false))
					and bool(shot_result.get("hit", false)),
				"camera hitscan reaches sentry %d shot %d" % [target_index + 1, shot_index + 1]
			)
		await _wait_physics_frames(2)
	_check(game.run_state.outcome == FpsRunState.Outcome.VICTORY, "weapon-caused sentry eliminations reach victory")
	_check(game.run_state.enemies_remaining == 0, "weapon victory objective reaches zero remaining")
	_check(
		game.run_state.shots_fired == 12
			and game.run_state.hits >= 11
			and game.run_state.accuracy_percent() >= 90,
		"weapon victory records coherent shot and hit facts"
	)

	game.restart_run()
	await _wait_frames(24)
	var presentation_reset_ok := true
	for reset_index in game.get_enemies().size():
		presentation_reset_ok = (
			presentation_reset_ok
			and game.get_enemies()[reset_index].global_position.distance_to(
				expected_enemy_transforms[reset_index].origin
			) < 0.01
			and game.get_enemies()[reset_index].rotation.z == 0.0
			and game.get_enemies()[reset_index].body_mesh.scale.is_equal_approx(Vector3.ONE)
		)
	var signal_core := game.blacksite.find_child("SignalCore", true, false) as Node3D
	presentation_reset_ok = (
		presentation_reset_ok
		and signal_core != null
		and signal_core.scale.is_equal_approx(Vector3.ONE)
	)
	_check(presentation_reset_ok, "immediate restart cancels stale death and victory tweens")

	game.debug_defeat_player()
	await _wait_frames(2)
	_check(game.run_state.outcome == FpsRunState.Outcome.DEFEAT, "lethal player damage reaches defeat")
	_check(game.player.current_health == 0, "defeat clamps player health to zero")

	game.restart_run()
	await _wait_frames(2)
	_check(game.run_state.outcome == FpsRunState.Outcome.RUNNING, "restart returns to running outcome")
	_check(game.player.current_health == game.player.maximum_health, "post-defeat restart restores player")
	var all_enemies_restored := true
	for candidate in game.get_enemies():
		all_enemies_restored = (
			all_enemies_restored
			and candidate.current_health == candidate.maximum_health
		)
	_check(all_enemies_restored, "post-defeat restart restores every sentry")
	_finish()


func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("FPS_VERTICAL_SLICE_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FPS_VERTICAL_SLICE_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)

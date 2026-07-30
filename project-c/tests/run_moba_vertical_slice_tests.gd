extends SceneTree

const MobaGameScript = preload("res://game/moba_game.gd")
const LaneStateScript = preload("res://features/match/lane_state.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "arc_bolt", "phase_step", "restart_run"]:
		_check(InputMap.has_action(action), "input action exists: %s" % action)
	var packed := load("res://game/moba_game.tscn") as PackedScene
	_check(packed != null, "MOBA scene loads")
	if packed == null:
		_finish(); return
	var game: Variant = packed.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.minions.size() == 6, "lane begins with readable opposing minion waves")
	_check(game.state.player_hp == 100.0 and game.state.enemy_tower_hp == 180.0, "match starts from authored state")
	_check(game.cast_arc_bolt(game.enemy_pos), "arc bolt starts when ready")
	_check(not game.cast_arc_bolt(game.enemy_pos), "arc bolt respects cooldown")
	await _frames(70)
	_check(game.state.enemy_hp < 100.0 or game.minions.size() < 6, "arc bolt creates a combat consequence")
	var before_step: Vector2 = game.player_pos
	_check(game.cast_phase_step(Vector2(700, 390)), "phase step starts when ready")
	_check(game.player_pos.distance_to(before_step) > 100.0, "phase step repositions hero")
	game.restart_run()
	await _frames(2)
	_check(game.state.outcome == LaneStateScript.Outcome.RUNNING and game.minions.size() == 6, "restart restores deterministic lane state")
	game.debug_win_lane()
	await _frames(8)
	_check(game.state.outcome == LaneStateScript.Outcome.VICTORY, "tower resolution reaches a playable victory")
	game.restart_run()
	_check(game.state.player_hp == 100.0 and game.state.enemy_tower_hp == 180.0, "post-victory restart clears outcome state")
	_finish()

func _frames(count: int) -> void:
	for _index in count:
		await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("MOBA_VERTICAL_SLICE_TESTS_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		print("MOBA_VERTICAL_SLICE_TESTS_FAIL: %d" % failures.size())
		quit(1)

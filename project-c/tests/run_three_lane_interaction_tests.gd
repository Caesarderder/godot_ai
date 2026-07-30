extends SceneTree

const ArenaScript = preload("res://features/match/three_lane_match.gd")
const RulesScript = preload("res://features/match/match_rules.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ["arc_bolt", "phase_step", "buy_item", "move_up", "move_down", "cycle_hero", "restart_run"]:
		_check(InputMap.has_action(action), "production input exists: %s" % action)
	var packed := load("res://game/three_lane_arena.tscn") as PackedScene
	_check(packed != null, "three-lane production scene loads")
	if packed == null:
		_finish()
		return
	var game: Variant = packed.instantiate()
	root.add_child(game)
	await process_frame
	_send(game, "move_up")
	_check(game.player_lane == RulesScript.Lane.TOP, "W selects top lane through production input")
	_check(game.controlled_slot == 0 and String(game.arena.player_hero_by_slot(game.controlled_slot).hero_id) == "aerion", "W keeps lane selection compatible and selects its first Dawn hero")
	var aerion: Dictionary = game.arena.player_hero_by_slot(0)
	aerion.shield = 60.0
	var top_wave_before := int(game.arena.waves[RulesScript.Lane.TOP][ArenaScript.Team.DAWN])
	_send(game, "arc_bolt")
	_check(String(game.arena.last_ability_result.reason) == "NO_EFFECT", "full-shield Aerion publishes a zero-effect production result")
	_check(int(game.arena.waves[RulesScript.Lane.TOP][ArenaScript.Team.DAWN]) == top_wave_before, "zero-effect Q does not add lane pressure")
	_send(game, "move_down")
	_check(game.player_lane == RulesScript.Lane.BOTTOM, "S selects bottom lane through production input")
	_check(game.controlled_slot == 2 and String(game.arena.player_hero_by_slot(game.controlled_slot).hero_id) == "mira", "S selects bottom lane's first Dawn hero")
	_check(game.arena.last_ability_result.is_empty(), "changing selection clears stale ability HUD state")
	_send(game, "buy_item")
	_check(game.arena.inventory == ["pulse_lens"] and int(game.arena.gold[ArenaScript.Team.DAWN]) == 150, "F buys the real lens through production input")
	var enemies: Array[Dictionary] = game.arena.heroes.filter(func(hero: Dictionary) -> bool: return int(hero.team) == ArenaScript.Team.DUSK and int(hero.lane) == RulesScript.Lane.BOTTOM)
	var enemy_before := float(enemies[0].hp)
	var wave_before := int(game.arena.waves[RulesScript.Lane.BOTTOM][ArenaScript.Team.DAWN])
	_send(game, "arc_bolt")
	_check(enemies.all(func(enemy: Dictionary) -> bool: return float(enemy.hp) == enemy_before - 34.0), "Q applies Mira's inventory-enhanced area damage through production input")
	_check(String(game.arena.last_ability_result.effect) == "AREA_DAMAGE" and int(game.arena.last_ability_result.targets) == 2, "production input publishes the current hero's skill result for HUD")
	_check(int(game.arena.waves[RulesScript.Lane.BOTTOM][ArenaScript.Team.DAWN]) == wave_before + 1, "Q adds pressure only to selected lane")
	var cooldown_wave := int(game.arena.waves[RulesScript.Lane.BOTTOM][ArenaScript.Team.DAWN])
	_send(game, "arc_bolt")
	_check(String(game.arena.last_ability_result.reason) == "COOLDOWN", "repeat production Q exposes its cooldown rejection")
	_check(int(game.arena.waves[RulesScript.Lane.BOTTOM][ArenaScript.Team.DAWN]) == cooldown_wave, "cooldown rejection does not add lane pressure")
	var ally: Dictionary = game.arena.heroes.filter(func(hero: Dictionary) -> bool: return int(hero.team) == ArenaScript.Team.DAWN and int(hero.lane) == RulesScript.Lane.BOTTOM)[0]
	ally.hp = 50.0
	_send(game, "phase_step")
	_check(float(ally.hp) == 66.0, "E recovers selected-lane ally through production input")
	_send(game, "restart_run")
	_check(game.player_lane == RulesScript.Lane.MID, "R restores default selected lane")
	_check(game.controlled_slot == 1, "R restores Vesper as default controlled hero")
	_check(game.arena.inventory.is_empty() and int(game.arena.gold[ArenaScript.Team.DAWN]) == 500, "R restores inventory and gold")
	_send(game, "cycle_hero")
	_check(game.controlled_slot == 2 and game.player_lane == RulesScript.Lane.BOTTOM, "Tab cycles from Vesper to Mira and follows the hero's lane")
	_check(game.arena.last_ability_result.is_empty(), "Tab clears stale ability result state")
	_send(game, "cycle_hero")
	_check(game.controlled_slot == 3 and String(game.arena.player_hero_by_slot(game.controlled_slot).hero_id) == "orun", "Tab reaches the second hero sharing bottom lane")
	_send(game, "cycle_hero")
	_check(game.controlled_slot == 4 and game.player_lane == RulesScript.Lane.TOP, "Tab reaches Sable and updates the selected lane")
	_send(game, "cycle_hero")
	_check(game.controlled_slot == 0 and String(game.arena.player_hero_by_slot(game.controlled_slot).hero_id) == "aerion", "Tab wraps across all five Dawn heroes")
	var locked_ally: Dictionary = game.arena.player_hero_by_slot(0)
	var locked_enemy: Dictionary = game.arena.heroes.filter(func(hero: Dictionary) -> bool: return int(hero.team) == ArenaScript.Team.DUSK and int(hero.lane) == RulesScript.Lane.TOP)[0]
	locked_ally.hp = 50.0
	var locked_ally_hp := float(locked_ally.hp)
	var locked_enemy_hp := float(locked_enemy.hp)
	var locked_position := float(locked_ally.lane_position)
	var locked_wave := int(game.arena.waves[RulesScript.Lane.TOP][ArenaScript.Team.DAWN])
	var locked_gold := int(game.arena.gold[ArenaScript.Team.DAWN])
	var locked_event: String = String(game.arena.last_event)
	var locked_result: Dictionary = game.arena.last_ability_result.duplicate(true)
	game.arena.outcome = ArenaScript.Team.DAWN
	for action in ["arc_bolt", "phase_step", "buy_item", "move_down", "move_up", "cycle_hero"]:
		_send(game, action)
	_check(game.player_lane == RulesScript.Lane.TOP and game.controlled_slot == 0, "post-match lane and hero selection inputs are locked")
	_check(game.arena.inventory.is_empty() and int(game.arena.gold[ArenaScript.Team.DAWN]) == locked_gold, "post-match shop input cannot mutate inventory or gold")
	_check(
		is_equal_approx(float(locked_ally.hp), locked_ally_hp)
		and is_equal_approx(float(locked_enemy.hp), locked_enemy_hp)
		and is_equal_approx(float(locked_ally.lane_position), locked_position),
		"post-match Q and E inputs cannot mutate hero health or spatial state"
	)
	_check(int(game.arena.waves[RulesScript.Lane.TOP][ArenaScript.Team.DAWN]) == locked_wave, "post-match Q cannot add lane pressure")
	_check(game.arena.last_event == locked_event and game.arena.last_ability_result == locked_result, "post-match inputs preserve the frozen result presentation")
	_send(game, "restart_run")
	_check(game.arena.outcome == -1 and game.player_lane == RulesScript.Lane.MID and game.controlled_slot == 1, "R remains available after match completion and restores the default match state")
	_finish()

func _send(game: Variant, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	game._unhandled_input(event)

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("THREE_LANE_INTERACTION_TESTS_OK")
		quit(0)
		return
	for failure in failures: push_error(failure)
	print("THREE_LANE_INTERACTION_TESTS_FAIL: %d" % failures.size())
	quit(1)

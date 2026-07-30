class_name MobaGame
extends Node2D

## Thin composition root for the original 45-second lane slice.
const LaneState = preload("res://features/match/lane_state.gd")
const LaneAbility = preload("res://features/combat/lane_ability.gd")

signal run_finished(victory: bool, summary: Dictionary)

var state := LaneState.new()
var ability := LaneAbility.new()
var player_pos := Vector2(318, 390)
var aim_pos := Vector2(760, 350)
var enemy_pos := Vector2(755, 300)
var minions: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var combat_log := "LANE ONLINE · HOLD THE SIGNAL LINE"
var _enemy_shot_clock := 0.0
var _pulse := 0.0


func _ready() -> void:
	queue_redraw()
	restart_run()


func _process(delta: float) -> void:
	_pulse += delta
	if state.outcome != LaneState.Outcome.RUNNING:
		queue_redraw()
		return
	state.elapsed += delta
	_handle_player_input(delta)
	_update_minions(delta)
	_update_projectiles(delta)
	_update_enemy_pressure(delta)
	ability.tick(delta)
	if state.elapsed >= state.time_limit:
		_finish(false, "SIGNAL WINDOW CLOSED")
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_pos = event.position
	if event.is_action_pressed("arc_bolt"):
		cast_arc_bolt(aim_pos)
	if event.is_action_pressed("phase_step"):
		cast_phase_step(aim_pos)
	if event.is_action_pressed("restart_run"):
		restart_run()


func restart_run() -> void:
	state.reset()
	ability.reset()
	player_pos = Vector2(318, 390)
	aim_pos = Vector2(760, 350)
	enemy_pos = Vector2(755, 300)
	projectiles.clear()
	minions = [
		{"pos": Vector2(350, 348), "hp": 36.0, "side": 0},
		{"pos": Vector2(322, 390), "hp": 36.0, "side": 0},
		{"pos": Vector2(350, 432), "hp": 36.0, "side": 0},
		{"pos": Vector2(652, 348), "hp": 34.0, "side": 1},
		{"pos": Vector2(682, 390), "hp": 34.0, "side": 1},
		{"pos": Vector2(652, 432), "hp": 34.0, "side": 1},
	]
	_enemy_shot_clock = 0.0
	combat_log = "LANE ONLINE · HOLD THE SIGNAL LINE"
	queue_redraw()


func cast_arc_bolt(target: Vector2) -> bool:
	if state.outcome != LaneState.Outcome.RUNNING or not ability.cast_bolt():
		return false
	var direction := (target - player_pos).normalized()
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT
	projectiles.append({"pos": player_pos, "vel": direction * 860.0, "life": 0.82, "friendly": true})
	combat_log = "ARC BOLT · HIT THE FRONTLINE"
	return true


func cast_phase_step(target: Vector2) -> bool:
	if state.outcome != LaneState.Outcome.RUNNING or not ability.cast_step():
		return false
	var direction := (target - player_pos).normalized()
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT
	player_pos += direction * 145.0
	player_pos.x = clampf(player_pos.x, 130.0, 960.0)
	player_pos.y = clampf(player_pos.y, 190.0, 540.0)
	combat_log = "PHASE STEP · REPOSITION"
	return true


func debug_action_peak() -> void:
	cast_arc_bolt(enemy_pos)
	cast_phase_step(Vector2(520, 350))
	state.player_hp = 62.0
	var threat_direction := (player_pos - enemy_pos).normalized()
	projectiles.append({"pos": enemy_pos + threat_direction * 92.0, "vel": threat_direction * 305.0, "life": 1.25, "friendly": false})
	combat_log = "ACTION REVIEW · DODGE, BOLT, ADVANCE"


func debug_win_lane() -> void:
	state.enemy_tower_hp = 0.0
	_finish(true, "ENEMY RELAY DISABLED")


func _handle_player_input(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_pos += movement * 310.0 * delta
	player_pos.x = clampf(player_pos.x, 130.0, 960.0)
	player_pos.y = clampf(player_pos.y, 190.0, 540.0)


func _update_minions(delta: float) -> void:
	for minion in minions:
		var side: int = minion.side
		minion.pos.x += (1 if side == 0 else -1) * 32.0 * delta
		if absf(minion.pos.x - 515.0) < 58.0:
			minion.hp -= 7.0 * delta
	minions = minions.filter(func(minion: Dictionary) -> bool: return minion.hp > 0.0)
	var friendly_count := minions.filter(func(m: Dictionary) -> bool: return m.side == 0).size()
	if friendly_count > 0 and player_pos.x > 580.0:
		state.enemy_tower_hp = maxf(0.0, state.enemy_tower_hp - friendly_count * 3.5 * delta)
		if state.enemy_tower_hp <= 0.0:
			_finish(true, "ENEMY RELAY DISABLED")


func _update_projectiles(delta: float) -> void:
	for bolt in projectiles:
		bolt.pos += bolt.vel * delta
		bolt.life -= delta
		if bolt.friendly:
			if bolt.pos.distance_to(enemy_pos) < 38.0:
				state.enemy_hp = maxf(0.0, state.enemy_hp - 28.0)
				bolt.life = 0.0
				combat_log = "ARC BOLT HIT · ENEMY SHIELDED"
			for minion in minions:
				if minion.side == 1 and bolt.life > 0.0 and bolt.pos.distance_to(minion.pos) < 24.0:
					minion.hp -= 38.0
					bolt.life = 0.0
			if bolt.life > 0.0 and bolt.pos.x > 1005.0 and absf(bolt.pos.y - 390.0) < 170.0:
				state.enemy_tower_hp = maxf(0.0, state.enemy_tower_hp - 12.0)
				bolt.life = 0.0
				if state.enemy_tower_hp <= 0.0:
					_finish(true, "ENEMY RELAY DISABLED")
		else:
			if bolt.pos.distance_to(player_pos) < 25.0:
				state.player_hp = maxf(0.0, state.player_hp - 13.0)
				bolt.life = 0.0
				combat_log = "INCOMING FIRE · PHASE STEP TO EVADE"
				if state.player_hp <= 0.0:
					_finish(false, "PILOT DOWN · PRESS R TO RETRY")
	projectiles = projectiles.filter(func(bolt: Dictionary) -> bool: return bolt.life > 0.0)


func _update_enemy_pressure(delta: float) -> void:
	_enemy_shot_clock += delta
	if _enemy_shot_clock < 1.55 or player_pos.distance_to(enemy_pos) > 420.0:
		return
	_enemy_shot_clock = 0.0
	var direction := (player_pos - enemy_pos).normalized()
	projectiles.append({"pos": enemy_pos, "vel": direction * 305.0, "life": 1.6, "friendly": false})


func _finish(victory: bool, message: String) -> void:
	if state.outcome != LaneState.Outcome.RUNNING:
		return
	state.outcome = LaneState.Outcome.VICTORY if victory else LaneState.Outcome.DEFEAT
	combat_log = message
	run_finished.emit(victory, state.summary())


func _draw() -> void:
	# Original vector presentation; no copied assets or reference imagery.
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("071129"))
	_draw_grid()
	draw_rect(Rect2(120, 175, 925, 390), Color("0c2244"), true)
	draw_rect(Rect2(120, 175, 925, 390), Color("3970a0"), false, 3.0)
	draw_line(Vector2(120, 390), Vector2(1045, 390), Color("6fb6d8", 0.38), 2.0)
	draw_line(Vector2(515, 180), Vector2(515, 560), Color("f5c667", 0.18), 2.0)
	_draw_objective_callout()
	_draw_tower(Vector2(155, 390), Color("55e6ca"), state.player_tower_hp, "ALLY RELAY")
	_draw_tower(Vector2(1015, 390), Color("ff647c"), state.enemy_tower_hp, "ENEMY RELAY")
	for minion in minions:
		_draw_minion(minion.pos, Color("63e6cc") if minion.side == 0 else Color("ff758b"), minion.hp)
	_draw_hero(player_pos, Color("8cf5e2"), "YOU")
	_draw_hero(enemy_pos, Color("ff7e94"), "RIVAL")
	_draw_enemy_threat_telegraphs()
	for bolt in projectiles:
		draw_circle(bolt.pos, 8.0, Color("9ffff0") if bolt.friendly else Color("ffcc73"))
		draw_circle(bolt.pos, 15.0, Color("9ffff0", 0.18) if bolt.friendly else Color("ffcc73", 0.16))
	_draw_hud()


func _draw_enemy_threat_telegraphs() -> void:
	for bolt in projectiles:
		if bool(bolt.friendly):
			continue
		# The live projectile and its target warning use form and position, not color alone.
		draw_line(enemy_pos, player_pos, Color("ffc562", 0.82), 4.0)
		draw_arc(player_pos, 38.0, 0.0, TAU, 32, Color("ffc562", 0.95), 3.0)
		var direction := (player_pos - enemy_pos).normalized()
		var perpendicular := Vector2(-direction.y, direction.x)
		var tip := player_pos - direction * 40.0
		var base := tip - direction * 24.0
		draw_colored_polygon(PackedVector2Array([tip, base + perpendicular * 11.0, base - perpendicular * 11.0]), Color("ffc562"))
		var warning_position := enemy_pos.lerp(player_pos, 0.48) + Vector2(-48, -22)
		draw_string(ThemeDB.fallback_font, warning_position, "INCOMING", HORIZONTAL_ALIGNMENT_CENTER, 96, 13, Color("ffe2a1"))


func _draw_grid() -> void:
	for x in range(0, 1281, 64):
		draw_line(Vector2(x, 0), Vector2(x, 720), Color("17345d", 0.22), 1.0)
	for y in range(0, 721, 64):
		draw_line(Vector2(0, y), Vector2(1280, y), Color("17345d", 0.22), 1.0)


func _draw_objective_callout() -> void:
	var color := Color("ffb968")
	draw_string(ThemeDB.fallback_font, Vector2(735, 205), "OBJECTIVE: DISABLE ENEMY RELAY", HORIZONTAL_ALIGNMENT_CENTER, 285, 15, color)
	draw_line(Vector2(885, 214), Vector2(985, 300), color, 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(996, 310), Vector2(977, 303), Vector2(989, 290)]), color)


func _draw_tower(pos: Vector2, tint: Color, hp: float, label: String) -> void:
	draw_circle(pos, 72.0 + sin(_pulse * 2.0) * 2.0, Color(tint, 0.10))
	draw_rect(Rect2(pos - Vector2(19, 54), Vector2(38, 108)), tint)
	draw_rect(Rect2(pos - Vector2(31, 67), Vector2(62, 15)), tint.lightened(0.28))
	_draw_bar(pos + Vector2(-54, -96), 108.0, hp / 180.0, tint)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-48, 102), label, HORIZONTAL_ALIGNMENT_CENTER, 96, 13, Color("d9edff"))


func _draw_hero(pos: Vector2, tint: Color, label: String) -> void:
	draw_circle(pos, 42.0, Color(tint, 0.13))
	draw_circle(pos, 23.0, tint)
	draw_circle(pos + Vector2(0, -9), 12.0, tint.lightened(0.32))
	if label == "YOU":
		draw_line(pos, aim_pos, Color(tint, 0.28), 1.0)
	var health := state.player_hp if label == "YOU" else state.enemy_hp
	_draw_bar(pos + Vector2(-44, -72), 88.0, health / 100.0, tint)
	if label == "YOU":
		draw_string(ThemeDB.fallback_font, pos + Vector2(-44, -83), "YOU HP %.0f/100" % health, HORIZONTAL_ALIGNMENT_CENTER, 88, 12, Color("dffff7"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-48, 76), "Q %s   E %s" % [ability.bolt_text(), ability.step_text()], HORIZONTAL_ALIGNMENT_CENTER, 96, 12, Color("d1e9ff"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-30, 50), label, HORIZONTAL_ALIGNMENT_CENTER, 60, 13, Color.WHITE)


func _draw_minion(pos: Vector2, tint: Color, hp: float) -> void:
	draw_circle(pos, 15.0, tint.darkened(0.15))
	draw_circle(pos, 9.0, tint)
	_draw_bar(pos + Vector2(-14, -25), 28.0, hp / 36.0, tint)


func _draw_bar(pos: Vector2, width: float, ratio: float, tint: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, 7)), Color("050a17"))
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2((width - 2.0) * clampf(ratio, 0.0, 1.0), 5)), tint)


func _draw_hud() -> void:
	draw_rect(Rect2(24, 18, 1232, 112), Color("08152c", 0.92))
	draw_rect(Rect2(24, 18, 1232, 112), Color("416e9d"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(48, 51), "STARFALL // LANE PROTOCOL", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("9ffff0"))
	draw_string(ThemeDB.fallback_font, Vector2(48, 82), "45-SECOND RELAY CLASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("aabed8"))
	draw_string(ThemeDB.fallback_font, Vector2(555, 55), "%.0f : %.0f" % [state.player_tower_hp, state.enemy_tower_hp], HORIZONTAL_ALIGNMENT_CENTER, 170, 26, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(555, 84), "ALLY RELAY        ENEMY RELAY", HORIZONTAL_ALIGNMENT_CENTER, 170, 12, Color("b7cae4"))
	draw_string(ThemeDB.fallback_font, Vector2(1055, 53), "%02d" % maxi(0, ceili(state.time_limit - state.elapsed)), HORIZONTAL_ALIGNMENT_CENTER, 155, 31, Color("f6cf72"))
	draw_rect(Rect2(24, 602, 1232, 94), Color("08152c", 0.94))
	draw_string(ThemeDB.fallback_font, Vector2(48, 634), combat_log, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8f4ff"))
	draw_string(ThemeDB.fallback_font, Vector2(48, 670), "WASD MOVE     Q ARC BOLT  [%s]     E PHASE STEP  [%s]     R RESTART" % [ability.bolt_text(), ability.step_text()], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a9c3df"))
	if state.outcome != LaneState.Outcome.RUNNING:
		var color := Color("79f8d7") if state.outcome == LaneState.Outcome.VICTORY else Color("ff7b91")
		draw_rect(Rect2(328, 274, 624, 132), Color("08152c", 0.96))
		draw_rect(Rect2(328, 274, 624, 132), color, false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(370, 330), combat_log, HORIZONTAL_ALIGNMENT_CENTER, 540, 27, color)
		draw_string(ThemeDB.fallback_font, Vector2(370, 370), "PRESS R TO DEPLOY A CLEAN RUN", HORIZONTAL_ALIGNMENT_CENTER, 540, 17, Color.WHITE)

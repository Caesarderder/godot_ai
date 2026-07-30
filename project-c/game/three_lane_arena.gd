class_name ThreeLaneArena
extends Node2D

const Arena = preload("res://features/match/three_lane_match.gd")
const Rules = preload("res://features/match/match_rules.gd")
const ABILITY_FEEDBACK_SECONDS := 0.75
var arena := Arena.new()
var player_lane := Rules.Lane.MID
var controlled_slot := 1
var show_hero_labels := true
var ability_feedback_remaining := 0.0

func _process(delta: float) -> void:
	arena.tick(delta)
	ability_feedback_remaining = maxf(0.0, ability_feedback_remaining - delta)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_run"):
		arena.reset()
		player_lane = Rules.Lane.MID
		controlled_slot = 1
		ability_feedback_remaining = 0.0
		return
	if arena.outcome != -1:
		return
	if event.is_action_pressed("arc_bolt"):
		var result := arena.player_cast_for_slot(controlled_slot)
		if bool(result.get("ok", false)):
			ability_feedback_remaining = ABILITY_FEEDBACK_SECONDS
		var pressure_delta := int(result.get("pressure_delta", 0))
		if pressure_delta > 0:
			arena.set_wave(player_lane, Arena.Team.DAWN, int(arena.waves[player_lane][Arena.Team.DAWN]) + pressure_delta)
	if event.is_action_pressed("phase_step"): arena.player_phase(player_lane)
	if event.is_action_pressed("buy_item"): arena.player_buy("pulse_lens", player_lane)
	if event.is_action_pressed("move_up"): _select_lane(Rules.Lane.TOP)
	if event.is_action_pressed("move_down"): _select_lane(Rules.Lane.BOTTOM)
	if event.is_action_pressed("cycle_hero"): _cycle_hero()

func _select_lane(lane: int) -> void:
	player_lane = lane
	arena.clear_ability_result()
	ability_feedback_remaining = 0.0
	for slot in Arena.HERO_IDS.size():
		var hero := arena.player_hero_by_slot(slot)
		if not hero.is_empty() and int(hero.lane) == lane:
			controlled_slot = slot
			return

func _cycle_hero() -> void:
	controlled_slot = (controlled_slot + 1) % Arena.HERO_IDS.size()
	arena.clear_ability_result()
	ability_feedback_remaining = 0.0
	var hero := arena.player_hero_by_slot(controlled_slot)
	if not hero.is_empty():
		player_lane = int(hero.lane)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("071129"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 48), "STARFALL // THREE-LANE SKIRMISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("9ffff0"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 78), "Q SIGNATURE · TAB CYCLE HERO · E RECOVER · F BUY · W / S SELECT LANE · R RESET", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b8cbe2"))
	draw_string(ThemeDB.fallback_font, Vector2(1030, 48), "GOLD %d" % arena.gold[Arena.Team.DAWN], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffe19a"))
	draw_string(ThemeDB.fallback_font, Vector2(760, 78), "PULSE LENS · %d PURCHASED · OFFENSIVE SIGNATURE DAMAGE +%d" % [arena.inventory.size(), arena.player_attack_bonus], HORIZONTAL_ALIGNMENT_LEFT, 470, 14, Color("cba8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(470, 112), "KILLS %d — %d · %s" % [arena.team_kills[Arena.Team.DAWN], arena.team_kills[Arena.Team.DUSK], arena.last_event], HORIZONTAL_ALIGNMENT_CENTER, 640, 14, Color("d9edff"))
	var controlled: Dictionary = arena.player_hero_by_slot(controlled_slot)
	if not controlled.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(330, 140), "CONTROLLED · %s · %s · LEVEL %d · XP %d · %s" % [controlled.name, controlled.role, controlled.level, controlled.xp, controlled.signature], HORIZONTAL_ALIGNMENT_CENTER, 620, 13, Color("9ffff0"))
		var cooldown := float(controlled.ability_cooldown_remaining)
		var cooldown_ratio := clampf(cooldown / Arena.ABILITY_COOLDOWN_SECONDS, 0.0, 1.0)
		draw_rect(Rect2(42, 96, 176, 8), Color("132845"))
		draw_rect(Rect2(42, 96, 176.0 * (1.0 - cooldown_ratio), 8), Color("71f6d5") if cooldown <= 0.0 else Color("ffe19a"))
		draw_string(ThemeDB.fallback_font, Vector2(42, 122), "Q READY" if cooldown <= 0.0 else "Q COOLDOWN %.1fs" % cooldown, HORIZONTAL_ALIGNMENT_LEFT, 176, 12, Color("9ffff0") if cooldown <= 0.0 else Color("ffe19a"))
	if not arena.last_ability_result.is_empty():
		var result := arena.last_ability_result
		var result_text := "ABILITY · %s" % String(result.get("reason", "FAILED")).replace("_", " ")
		if bool(result.get("ok", false)):
			match String(result.get("effect", "")):
				"DASH":
					result_text = "ABILITY · %s · RANGE %.2f / %.2f · DASH %.2f" % [
						String(result.ability),
						float(result.get("distance", 0.0)),
						float(result.get("cast_range", 0.0)),
						float(result.get("travel", 0.0)),
					]
				"LONG_RANGE":
					result_text = "ABILITY · %s · RANGE %.2f / %.2f · DAMAGE %.0f" % [
						String(result.ability),
						float(result.get("distance", 0.0)),
						float(result.get("cast_range", 0.0)),
						float(result.amount),
					]
				_:
					result_text = "ABILITY · %s · %s %.0f · %d TARGET%s" % [
						String(result.ability),
						String(result.effect),
						float(result.amount),
						int(result.targets),
						"" if int(result.targets) == 1 else "S",
					]
		elif result.has("distance") and result.has("cast_range"):
			result_text += " · RANGE %.2f / %.2f" % [
				float(result.distance),
				float(result.cast_range),
			]
		draw_string(ThemeDB.fallback_font, Vector2(330, 159), result_text, HORIZONTAL_ALIGNMENT_CENTER, 620, 12, Color("ffe19a"))
	_draw_core(Vector2(90, 390), Color("55e6ca"), int(arena.core_hp[Arena.Team.DAWN]), "DAWN CORE")
	_draw_core(Vector2(1190, 390), Color("ff647c"), int(arena.core_hp[Arena.Team.DUSK]), "DUSK CORE")
	for lane in [Rules.Lane.TOP, Rules.Lane.MID, Rules.Lane.BOTTOM]:
		var y: float = 220.0 + float(lane) * 180.0
		var selected: bool = lane == player_lane
		draw_line(Vector2(175, y), Vector2(1105, y), Color("7de7d3") if selected else Color("335474"), 5.0 if selected else 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(190, y - 16), Rules.lane_name(lane), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		_draw_tower(Vector2(310, y), Color("55e6ca"), int(arena.tower_hp[lane][Arena.Team.DAWN]))
		_draw_tower(Vector2(970, y), Color("ff647c"), int(arena.tower_hp[lane][Arena.Team.DUSK]))
		for i in int(arena.waves[lane][Arena.Team.DAWN]): draw_circle(Vector2(390 + i * 18, y), 8, Color("63e6cc"))
		for i in int(arena.waves[lane][Arena.Team.DUSK]): draw_circle(Vector2(890 - i * 18, y), 8, Color("ff758b"))
		_draw_lane_ability_feedback(lane, y)
		_draw_lane_heroes(lane, y)
		if selected:
			draw_string(ThemeDB.fallback_font, Vector2(250, y + 65), "ALLY TOWER · MINION WAVE · HERO", HORIZONTAL_ALIGNMENT_CENTER, 310, 11, Color("9ffff0"))
			draw_string(ThemeDB.fallback_font, Vector2(720, y + 65), "ENEMY HERO · MINION WAVE · TOWER", HORIZONTAL_ALIGNMENT_CENTER, 310, 11, Color("ffb1bd"))
	if arena.outcome != -1:
		draw_string(ThemeDB.fallback_font, Vector2(370, 365), "MATCH COMPLETE: %s WINS" % ("DAWN" if arena.outcome == Arena.Team.DAWN else "DUSK"), HORIZONTAL_ALIGNMENT_CENTER, 540, 28, Color("ffe19a"))
	_draw_hero_key()

func _draw_core(pos: Vector2, tint: Color, hp: int, label: String) -> void:
	draw_circle(pos, 48, Color(tint, 0.2)); draw_circle(pos, 23, tint)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-76, 68), label + " HP %d" % hp, HORIZONTAL_ALIGNMENT_CENTER, 152, 13, Color.WHITE)

func _draw_lane_ability_feedback(lane: int, y: float) -> void:
	if ability_feedback_remaining <= 0.0 or arena.last_ability_result.is_empty():
		return
	var result := arena.last_ability_result
	if not bool(result.get("ok", false)):
		return
	var caster := arena.player_hero_by_slot(controlled_slot)
	if caster.is_empty() or int(caster.lane) != lane:
		return
	var pulse := 0.65 + 0.35 * (ability_feedback_remaining / ABILITY_FEEDBACK_SECONDS)
	var caster_pos := _hero_screen_position(caster)
	match String(result.effect):
		"SHIELD":
			var shield_center := caster_pos + Vector2(0, 5)
			draw_arc(shield_center, 31.0, 0.0, PI, 20, Color(0.55, 1.0, 0.95, pulse), 5.0)
			draw_arc(shield_center, 39.0, 0.0, PI, 20, Color(1.0, 0.88, 0.50, pulse), 2.0)
		"DASH":
			var from_pos := Vector2(_lane_x(float(result.get("from", caster.lane_position))), caster_pos.y)
			draw_line(from_pos, caster_pos, Color(0.70, 0.42, 1.0, 0.35), 14.0)
			draw_line(from_pos, caster_pos, Color(0.88, 0.76, 1.0, pulse), 3.0)
			draw_circle(from_pos, 18.0, Color(0.45, 0.25, 0.85, 0.22))
			for step in range(1, 4):
				var ghost := from_pos.lerp(caster_pos, float(step) / 4.0)
				draw_arc(ghost, 11.0, -PI * 0.4, PI * 0.4, 10, Color(0.78, 0.55, 1.0, 0.55), 2.0)
			draw_string(ThemeDB.fallback_font, (from_pos + caster_pos) * 0.5 + Vector2(-120, 36), "DASH %.2f" % float(result.get("travel", 0.0)), HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color("ead8ff"))
		"AREA_DAMAGE":
			for target in _lane_heroes(lane, Arena.Team.DUSK):
				if float(target.hp) > 0.0:
					var target_pos := _hero_screen_position(target)
					var effect_center := target_pos + Vector2(0, 6)
					draw_arc(effect_center, 30.0, 0.0, PI, 20, Color(0.50, 0.88, 1.0, pulse), 4.0)
					for ray in range(0, 5):
						var axis := Vector2.RIGHT.rotated(float(ray) * PI / 4.0)
						draw_line(effect_center + axis * 18.0, effect_center + axis * 37.0, Color(0.62, 0.92, 1.0, pulse), 2.0)
		"TEAM_HEAL":
			for ally in _lane_heroes(lane, Arena.Team.DAWN):
				if float(ally.hp) > 0.0:
					var ally_pos := _hero_screen_position(ally)
					var heal_center := ally_pos + Vector2(0, 5)
					draw_arc(heal_center, 30.0, 0.0, PI, 20, Color(0.42, 1.0, 0.62, pulse), 4.0)
					draw_line(heal_center + Vector2(-6, 38), heal_center + Vector2(6, 38), Color(0.70, 1.0, 0.78, pulse), 3.0)
					draw_line(heal_center + Vector2(0, 32), heal_center + Vector2(0, 44), Color(0.70, 1.0, 0.78, pulse), 3.0)
		"LONG_RANGE":
			var target := _find_hero(Arena.Team.DUSK, lane, int(result.get("target_slot", -1)))
			if not target.is_empty():
				var target_pos := _hero_screen_position(target)
				draw_line(caster_pos, target_pos, Color(1.0, 0.30, 0.72, 0.18), 13.0)
				draw_line(caster_pos, target_pos, Color(1.0, 0.78, 0.92, pulse), 3.0)
				var direction := (target_pos - caster_pos).normalized()
				for step in range(1, 5):
					var spark := caster_pos.lerp(target_pos, float(step) / 5.0)
					draw_circle(spark, 4.0, Color(1.0, 0.42, 0.78, pulse))
				draw_arc(target_pos, 28.0, 0.0, TAU, 32, Color(1.0, 0.45, 0.72, pulse), 4.0)
				draw_line(target_pos - direction.rotated(PI * 0.5) * 18.0, target_pos + direction.rotated(PI * 0.5) * 18.0, Color(1.0, 0.80, 0.92, pulse), 2.0)
				draw_string(ThemeDB.fallback_font, (caster_pos + target_pos) * 0.5 + Vector2(-72, 38), "RANGE %.2f / %.2f" % [float(result.get("distance", 0.0)), float(result.get("cast_range", 0.0))], HORIZONTAL_ALIGNMENT_CENTER, 144, 11, Color("ffd0e8"))

func _lane_x(lane_position: float) -> float:
	return 300.0 + lane_position * 680.0

func _lane_heroes(lane: int, team: int) -> Array[Dictionary]:
	return arena.heroes.filter(func(hero: Dictionary) -> bool: return int(hero.lane) == lane and int(hero.team) == team)

func _find_hero(team: int, lane: int, slot: int) -> Dictionary:
	for hero in arena.heroes:
		if int(hero.team) == team and int(hero.lane) == lane and int(hero.slot) == slot:
			return hero
	return {}

func _hero_screen_position(hero: Dictionary) -> Vector2:
	var lane := int(hero.lane)
	var team := int(hero.team)
	var lane_heroes := _lane_heroes(lane, team)
	var index := lane_heroes.find(hero)
	var y := 220.0 + float(lane) * 180.0
	return Vector2(_lane_x(float(hero.lane_position)), y + (-14.0 if index % 2 == 0 else 14.0))

func _draw_lane_heroes(lane: int, y: float) -> void:
	var controlled: Dictionary = arena.player_hero_by_slot(controlled_slot)
	for team in [Arena.Team.DAWN, Arena.Team.DUSK]:
		var lane_heroes := _lane_heroes(lane, team)
		for index in lane_heroes.size():
			var hero := lane_heroes[index]
			var pos := _hero_screen_position(hero)
			var is_controlled := not controlled.is_empty() and int(hero.team) == Arena.Team.DAWN and int(hero.slot) == int(controlled.slot)
			if float(hero.hp) <= 0.0:
				_draw_hero_marker(pos, hero, team, is_controlled, true)
				draw_string(ThemeDB.fallback_font, pos + Vector2(-48, -24), "%s DEAD" % String(hero.name), HORIZONTAL_ALIGNMENT_CENTER, 96, 10, Color("c3ccd8"))
				draw_string(ThemeDB.fallback_font, pos + Vector2(-48, 30), "RESPAWN %.1fs" % float(hero.respawn_remaining), HORIZONTAL_ALIGNMENT_CENTER, 96, 10, Color("9aa9bb"))
				continue
			_draw_hero_marker(pos, hero, team, is_controlled, false)
			if show_hero_labels:
				draw_string(ThemeDB.fallback_font, pos + Vector2(-52, -23), "%s L%d HP %.0f" % [hero.name, hero.level, hero.hp], HORIZONTAL_ALIGNMENT_CENTER, 104, 11, Color.WHITE)

func _draw_hero_marker(pos: Vector2, hero: Dictionary, team: int, controlled: bool, dead: bool) -> void:
	var team_tint := Color("63e6cc") if team == Arena.Team.DAWN else Color("ff758b")
	if dead: team_tint = Color("7789a3")
	if controlled:
		draw_arc(pos, 23.0, 0.0, TAU, 28, Color("ffe19a"), 3.0)
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, 31), pos + Vector2(-7, 41), pos + Vector2(7, 41)]), Color("ffe19a"))
	match String(hero.hero_id):
		"aerion":
			var shield := PackedVector2Array([pos + Vector2(0, -15), pos + Vector2(13, -8), pos + Vector2(10, 8), pos + Vector2(0, 16), pos + Vector2(-10, 8), pos + Vector2(-13, -8)])
			draw_colored_polygon(shield, Color("315e96") if not dead else Color("3f4b5c"))
			draw_polyline(PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[5], shield[0]]), team_tint, 3.0)
		"vesper":
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-15, -11), pos + Vector2(4, -4), pos + Vector2(15, -14), pos + Vector2(7, 3), pos + Vector2(15, 14), pos + Vector2(-4, 5), pos + Vector2(-15, 11), pos + Vector2(-7, 0)]), Color("624ba0") if not dead else Color("3f4b5c"))
			draw_line(pos + Vector2(-13, 0), pos + Vector2(13, 0), team_tint, 3.0)
		"mira":
			draw_circle(pos, 13.0, Color("3d75a8") if not dead else Color("3f4b5c"))
			draw_arc(pos, 16.0, 0.0, TAU, 24, team_tint, 3.0)
			for axis in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]: draw_line(pos + axis * 8.0, pos + axis * 17.0, team_tint, 2.0)
		"orun":
			var diamond := PackedVector2Array([pos + Vector2(0, -16), pos + Vector2(16, 0), pos + Vector2(0, 16), pos + Vector2(-16, 0)])
			draw_colored_polygon(diamond, Color("82613e") if not dead else Color("3f4b5c"))
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), team_tint, 3.0)
			draw_rect(Rect2(pos - Vector2(5, 5), Vector2(10, 10)), team_tint, false, 2.0)
		"sable":
			draw_circle(pos, 11.0, Color("8a3f62") if not dead else Color("3f4b5c"))
			draw_arc(pos, 16.0, 0.0, TAU, 24, team_tint, 3.0)
			draw_line(pos + Vector2(-20, 0), pos + Vector2(20, 0), team_tint, 2.0)
			draw_line(pos + Vector2(0, -20), pos + Vector2(0, 20), team_tint, 2.0)

func _draw_hero_key() -> void:
	draw_rect(Rect2(225, 654, 830, 60), Color("08152c", 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(240, 675), "HERO KEY", HORIZONTAL_ALIGNMENT_LEFT, 80, 12, Color("b8cbe2"))
	for slot in Arena.HERO_IDS.size():
		var hero: Dictionary = arena.heroes.filter(func(candidate: Dictionary) -> bool: return int(candidate.team) == Arena.Team.DAWN and int(candidate.slot) == slot)[0]
		var pos := Vector2(355.0 + float(slot) * 132.0, 681.0)
		_draw_hero_marker(pos, hero, Arena.Team.DAWN, false, false)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-48, 28), String(hero.name), HORIZONTAL_ALIGNMENT_CENTER, 96, 11, Color.WHITE)

func _draw_tower(pos: Vector2, tint: Color, hp: int) -> void:
	draw_rect(Rect2(pos - Vector2(9, 25), Vector2(18, 50)), tint)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-35, -35), str(hp), HORIZONTAL_ALIGNMENT_CENTER, 70, 12, Color("d9edff"))

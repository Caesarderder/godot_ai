class_name ThreeLaneMatch
extends RefCounted

const MatchRules = preload("res://features/match/match_rules.gd")
const ItemShop = preload("res://features/economy/item_shop.gd")
const HeroArchetypes = preload("res://features/actors/hero_archetypes.gd")

enum Team { DAWN, DUSK }
const HERO_DAMAGE_PER_SECOND := 3.0
const HERO_KILL_GOLD := 120
const HERO_RESPAWN_SECONDS := 8.0
const SPAWN_PROTECTION_SECONDS := 0.75
const HERO_DAMAGE_SCALE := 0.035
const HERO_KILL_XP := 100
const ABILITY_COOLDOWN_SECONDS := 2.0
const AERION_SHIELD := 28.0
const VESPER_DAMAGE := 34.0
const MIRA_DAMAGE := 22.0
const ORUN_HEAL := 24.0
const SABLE_DAMAGE := 52.0
const VESPER_CAST_RANGE := 0.40
const VESPER_DASH_STANDOFF := 0.16
const SABLE_CAST_RANGE := 0.70
const HERO_IDS: Array[String] = ["aerion", "vesper", "mira", "orun", "sable"]
const HERO_LANES: Array[int] = [MatchRules.Lane.TOP, MatchRules.Lane.MID, MatchRules.Lane.BOTTOM, MatchRules.Lane.BOTTOM, MatchRules.Lane.TOP]
var elapsed := 0.0
var outcome := -1
var core_hp := {Team.DAWN: MatchRules.CORE_HP, Team.DUSK: MatchRules.CORE_HP}
var tower_hp := {}
var waves := {}
var heroes: Array[Dictionary] = []
var gold := {Team.DAWN: MatchRules.STARTING_GOLD, Team.DUSK: MatchRules.STARTING_GOLD}
var inventory: Array[String] = []
var player_attack_bonus := 0
var team_kills := {Team.DAWN: 0, Team.DUSK: 0}
var last_event := "MATCH READY"
var last_ability_result: Dictionary = {}

func _init() -> void:
	reset()

func reset() -> void:
	elapsed = 0.0
	outcome = -1
	for lane in [MatchRules.Lane.TOP, MatchRules.Lane.MID, MatchRules.Lane.BOTTOM]:
		tower_hp[lane] = {Team.DAWN: MatchRules.OUTER_TOWER_HP, Team.DUSK: MatchRules.OUTER_TOWER_HP}
		waves[lane] = {Team.DAWN: 3, Team.DUSK: 3}
	core_hp = {Team.DAWN: MatchRules.CORE_HP, Team.DUSK: MatchRules.CORE_HP}
	gold = {Team.DAWN: MatchRules.STARTING_GOLD, Team.DUSK: MatchRules.STARTING_GOLD}
	inventory.clear()
	player_attack_bonus = 0
	team_kills = {Team.DAWN: 0, Team.DUSK: 0}
	last_event = "MATCH READY"
	last_ability_result = {}
	heroes = []
	for team in [Team.DAWN, Team.DUSK]:
		for slot in MatchRules.TEAM_SIZE:
			var hero_id: String = HERO_IDS[slot]
			var definition: Dictionary = HeroArchetypes.get_hero(hero_id)
			var lane_position := _initial_lane_position(team, HERO_LANES[slot], slot)
			heroes.append({
				"team": team,
				"slot": slot,
				"hero_id": hero_id,
				"lane": HERO_LANES[slot],
				"lane_position": lane_position,
				"spawn_lane_position": lane_position,
				"hp": 100.0,
				"max_hp": 100.0,
				"shield": 0.0,
				"attack": float(definition.attack),
				"role": String(definition.role),
				"signature": String(definition.signature),
				"level": 1,
				"xp": 0,
				"kills": 0,
				"respawn_remaining": 0.0,
				"spawn_protection": 0.0,
				"ability_cooldown_remaining": 0.0,
				"deaths": 0,
				"name": String(definition.name),
			})

func tick(delta: float) -> void:
	if outcome != -1: return
	elapsed += delta
	_tick_ability_cooldowns(delta)
	_tick_respawns(delta)
	for lane in waves:
		_tick_heroes(lane, delta)
		var dawn: int = waves[lane][Team.DAWN]
		var dusk: int = waves[lane][Team.DUSK]
		if dawn == dusk: continue
		var pushing_team := Team.DAWN if dawn > dusk else Team.DUSK
		var defending_team := Team.DUSK if pushing_team == Team.DAWN else Team.DAWN
		if tower_hp[lane][defending_team] > 0:
			tower_hp[lane][defending_team] = max(0, tower_hp[lane][defending_team] - int(abs(dawn - dusk) * 8.0 * delta))
		else:
			core_hp[defending_team] = max(0, core_hp[defending_team] - int(abs(dawn - dusk) * 12.0 * delta))
			if core_hp[defending_team] == 0: outcome = pushing_team

func set_wave(lane: MatchRules.Lane, team: Team, count: int) -> void:
	waves[lane][team] = maxi(0, count)

func player_cast(lane: int) -> bool:
	var caster := player_hero(lane)
	if caster.is_empty(): return false
	return bool(player_cast_for_slot(int(caster.slot)).get("ok", false))

func player_cast_for_slot(slot: int) -> Dictionary:
	if outcome != -1:
		return {
			"ok": false,
			"reason": "MATCH_COMPLETE",
			"hero_id": "",
			"pressure_delta": 0,
		}
	var caster := player_hero_by_slot(slot)
	if caster.is_empty():
		return _ability_failed("INVALID_SLOT")
	if float(caster.hp) <= 0.0:
		return _ability_failed("HERO_DEAD", caster)
	if float(caster.ability_cooldown_remaining) > 0.0:
		return _ability_failed("COOLDOWN", caster)
	var result: Dictionary
	match String(caster.hero_id):
		"aerion":
			var before := float(caster.shield)
			caster.shield = minf(60.0, before + AERION_SHIELD)
			if is_equal_approx(float(caster.shield), before):
				return _ability_failed("NO_EFFECT", caster)
			result = {
				"ok": true,
				"hero_id": "aerion",
				"ability": "Solar Guard",
				"effect": "SHIELD",
				"amount": float(caster.shield) - before,
				"targets": 1,
				"pressure_delta": 1,
			}
		"vesper":
			result = _vesper_dash(caster)
		"mira":
			var targets := _living_enemies(int(caster.lane))
			if targets.is_empty(): return _ability_failed("NO_TARGET", caster)
			for target in targets:
				_apply_damage(target, MIRA_DAMAGE + float(player_attack_bonus), Team.DAWN, caster)
			result = {
				"ok": true,
				"hero_id": "mira",
				"ability": "Comet Array",
				"effect": "AREA_DAMAGE",
				"amount": MIRA_DAMAGE + float(player_attack_bonus),
				"targets": targets.size(),
				"pressure_delta": 1,
			}
		"orun":
			var healed := 0.0
			var targets := 0
			for ally in heroes:
				if int(ally.team) != Team.DAWN or int(ally.lane) != int(caster.lane) or float(ally.hp) <= 0.0:
					continue
				var before := float(ally.hp)
				ally.hp = minf(float(ally.max_hp), before + ORUN_HEAL)
				healed += float(ally.hp) - before
				targets += 1
			if healed <= 0.0:
				return _ability_failed("NO_EFFECT", caster)
			result = {
				"ok": true,
				"hero_id": "orun",
				"ability": "Anchor Field",
				"effect": "TEAM_HEAL",
				"amount": healed,
				"targets": targets,
				"pressure_delta": 1,
			}
		"sable":
			result = _single_target_damage(caster, SABLE_DAMAGE, "Prism Shot", "LONG_RANGE", SABLE_CAST_RANGE)
		_:
			return _ability_failed("UNKNOWN_HERO", caster)
	if not bool(result.get("ok", false)):
		return result
	caster.ability_cooldown_remaining = ABILITY_COOLDOWN_SECONDS
	last_ability_result = result.duplicate(true)
	last_event = "%s · %s · %s x%d" % [
		String(caster.name).to_upper(),
		String(result.ability).to_upper(),
		String(result.effect),
		int(result.targets),
	]
	return result

func player_hero_by_slot(slot: int) -> Dictionary:
	for hero in heroes:
		if int(hero.team) == Team.DAWN and int(hero.slot) == slot:
			return hero
	return {}

func clear_ability_result() -> void:
	last_ability_result = {}

func player_hero(lane: int) -> Dictionary:
	for hero in heroes:
		if int(hero.team) == Team.DAWN and int(hero.lane) == lane and float(hero.hp) > 0.0:
			return hero
	return {}

func _vesper_dash(caster: Dictionary) -> Dictionary:
	var from_position := float(caster.lane_position)
	var target_result := _select_target_in_range(caster, VESPER_CAST_RANGE)
	if not bool(target_result.ok):
		return _ability_failed(String(target_result.reason), caster, target_result)
	var target: Dictionary = target_result.target
	var target_position := float(target.lane_position)
	var direction := signf(target_position - from_position)
	var to_position := clampf(target_position - direction * VESPER_DASH_STANDOFF, 0.0, 1.0)
	caster.lane_position = to_position
	var damage := VESPER_DAMAGE + float(player_attack_bonus)
	_apply_damage(target, damage, Team.DAWN, caster)
	return {
		"ok": true,
		"hero_id": String(caster.hero_id),
		"ability": "Rift Step",
		"effect": "DASH",
		"amount": damage,
		"targets": 1,
		"range": "MELEE",
		"cast_range": VESPER_CAST_RANGE,
		"from": from_position,
		"to": to_position,
		"travel": absf(to_position - from_position),
		"caster_position": to_position,
		"target_position": target_position,
		"target_slot": int(target.slot),
		"distance": float(target_result.distance),
		"pressure_delta": 1,
	}

func _single_target_damage(caster: Dictionary, amount: float, ability: String, effect: String, cast_range: float = VESPER_CAST_RANGE) -> Dictionary:
	var target_result := _select_target_in_range(caster, cast_range)
	if not bool(target_result.ok):
		return _ability_failed(String(target_result.reason), caster, target_result)
	var target: Dictionary = target_result.target
	var damage := amount + float(player_attack_bonus)
	_apply_damage(target, damage, Team.DAWN, caster)
	return {
		"ok": true,
		"hero_id": String(caster.hero_id),
		"ability": ability,
		"effect": effect,
		"amount": damage,
		"targets": 1,
		"range": "LONG" if effect == "LONG_RANGE" else "MELEE",
		"cast_range": cast_range,
		"caster_position": float(caster.lane_position),
		"target_position": float(target.lane_position),
		"target_slot": int(target.slot),
		"distance": float(target_result.distance),
		"pressure_delta": 1,
	}

func _select_target_in_range(caster: Dictionary, cast_range: float) -> Dictionary:
	var targets := _living_enemies(int(caster.lane))
	if targets.is_empty():
		return {"ok": false, "reason": "NO_TARGET"}
	var caster_position := float(caster.lane_position)
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_distance := absf(float(a.lane_position) - caster_position)
		var b_distance := absf(float(b.lane_position) - caster_position)
		if is_equal_approx(a_distance, b_distance):
			return int(a.slot) < int(b.slot)
		return a_distance < b_distance
	)
	var target: Dictionary = targets[0]
	var distance := absf(float(target.lane_position) - caster_position)
	if distance > cast_range:
		return {
			"ok": false,
			"reason": "OUT_OF_RANGE",
			"distance": distance,
			"cast_range": cast_range,
			"target_slot": int(target.slot),
			"caster_position": caster_position,
			"target_position": float(target.lane_position),
		}
	return {"ok": true, "target": target, "distance": distance}

func _living_enemies(lane: int) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for hero in heroes:
		if (
			int(hero.team) == Team.DUSK
			and int(hero.lane) == lane
			and float(hero.hp) > 0.0
			and float(hero.spawn_protection) <= 0.0
		):
			targets.append(hero)
	return targets

func _ability_failed(reason: String, caster: Dictionary = {}, details: Dictionary = {}) -> Dictionary:
	var result := {
		"ok": false,
		"reason": reason,
		"hero_id": String(caster.get("hero_id", "")),
		"pressure_delta": 0,
	}
	for key in ["distance", "cast_range", "target_slot", "caster_position", "target_position"]:
		if details.has(key):
			result[key] = details[key]
	last_ability_result = result.duplicate(true)
	last_event = "ABILITY FAILED · %s" % reason
	return result

func _tick_ability_cooldowns(delta: float) -> void:
	for hero in heroes:
		hero.ability_cooldown_remaining = maxf(0.0, float(hero.ability_cooldown_remaining) - delta)

func player_phase(lane: int) -> bool:
	for hero in heroes:
		if int(hero.team) == Team.DAWN and int(hero.lane) == lane and float(hero.hp) > 0.0:
			hero.hp = minf(float(hero.max_hp), float(hero.hp) + 16.0)
			last_event = "%s PHASE RECOVER +16" % String(hero.name)
			return true
	return false

func player_buy(item_id: String, lane: int) -> Dictionary:
	if inventory.size() >= 3:
		return {"ok": false, "reason": "INVENTORY_FULL"}
	var result := ItemShop.buy(item_id, int(gold[Team.DAWN]))
	if not bool(result.ok): return result
	gold[Team.DAWN] = int(result.gold)
	inventory.append(item_id)
	player_attack_bonus += int(result.item.get("attack", 0))
	var health_bonus := int(result.item.get("health", 0)) / 20
	for hero in heroes:
		if int(hero.team) == Team.DAWN and int(hero.lane) == lane:
			hero.hp = minf(float(hero.max_hp), float(hero.hp) + float(health_bonus))
	last_event = "PURCHASED %s · OFFENSIVE SIGNATURE +%d" % [String(result.item.name), int(result.item.get("attack", 0))]
	return {"ok": true, "item": result.item, "gold": gold[Team.DAWN]}

func _tick_heroes(lane: int, delta: float) -> void:
	var dawn: Array[Dictionary] = heroes.filter(func(hero: Dictionary) -> bool: return hero.team == Team.DAWN and hero.lane == lane and hero.hp > 0.0 and hero.spawn_protection <= 0.0)
	var dusk: Array[Dictionary] = heroes.filter(func(hero: Dictionary) -> bool: return hero.team == Team.DUSK and hero.lane == lane and hero.hp > 0.0 and hero.spawn_protection <= 0.0)
	if dawn.is_empty() or dusk.is_empty(): return
	var dawn_damage := _team_damage(dusk) * delta
	var dusk_damage := _team_damage(dawn) * delta
	for hero in dawn: _apply_damage(hero, dawn_damage, Team.DUSK, dusk[0])
	for hero in dusk: _apply_damage(hero, dusk_damage, Team.DAWN, dawn[0])

func _team_damage(attackers: Array[Dictionary]) -> float:
	var damage := 0.0
	for attacker in attackers: damage += float(attacker.attack) * HERO_DAMAGE_SCALE
	return maxf(HERO_DAMAGE_PER_SECOND, damage)

func _apply_damage(hero: Dictionary, amount: float, killer_team: Team, killer_hero: Dictionary = {}) -> bool:
	if float(hero.hp) <= 0.0 or amount <= 0.0: return false
	var absorbed := minf(float(hero.get("shield", 0.0)), amount)
	hero.shield = maxf(0.0, float(hero.get("shield", 0.0)) - absorbed)
	amount -= absorbed
	if amount <= 0.0: return false
	hero.hp = maxf(0.0, float(hero.hp) - amount)
	if float(hero.hp) > 0.0: return false
	hero.deaths = int(hero.deaths) + 1
	hero.respawn_remaining = HERO_RESPAWN_SECONDS
	team_kills[killer_team] = int(team_kills[killer_team]) + 1
	gold[killer_team] = int(gold[killer_team]) + HERO_KILL_GOLD
	if not killer_hero.is_empty():
		killer_hero.kills = int(killer_hero.kills) + 1
		killer_hero.xp = int(killer_hero.xp) + HERO_KILL_XP
		_apply_level_ups(killer_hero)
	last_event = "%s ELIMINATED · %s +%d GOLD" % [String(hero.name), "DAWN" if killer_team == Team.DAWN else "DUSK", HERO_KILL_GOLD]
	return true

func _apply_level_ups(hero: Dictionary) -> void:
	var required := int(hero.level) * HERO_KILL_XP
	while int(hero.xp) >= required:
		hero.xp = int(hero.xp) - required
		hero.level = int(hero.level) + 1
		hero.max_hp = float(hero.max_hp) + 10.0
		hero.hp = minf(float(hero.max_hp), float(hero.hp) + 10.0)
		hero.attack = float(hero.attack) + 3.0
		required = int(hero.level) * HERO_KILL_XP

func _tick_respawns(delta: float) -> void:
	for hero in heroes:
		if float(hero.hp) <= 0.0 and float(hero.respawn_remaining) > 0.0:
			hero.respawn_remaining = maxf(0.0, float(hero.respawn_remaining) - delta)
			if float(hero.respawn_remaining) <= 0.0001:
				hero.respawn_remaining = 0.0
				hero.hp = float(hero.max_hp)
				hero.spawn_protection = SPAWN_PROTECTION_SECONDS
				hero.lane_position = float(hero.spawn_lane_position)
				last_event = "%s REDEPLOYED" % String(hero.name)
		elif float(hero.spawn_protection) > 0.0:
			hero.spawn_protection = maxf(0.0, float(hero.spawn_protection) - delta)

func summary() -> Dictionary:
	return {
		"elapsed": elapsed,
		"outcome": outcome,
		"core_hp": core_hp.duplicate(true),
		"tower_hp": tower_hp.duplicate(true),
		"team_kills": team_kills.duplicate(true),
		"gold": gold.duplicate(true),
	}

func _initial_lane_position(team: Team, lane: int, slot: int) -> float:
	var same_lane_index := 0
	for candidate_slot in slot:
		if HERO_LANES[candidate_slot] == lane:
			same_lane_index += 1
	var offset := float(same_lane_index) * 0.12
	return 0.32 - offset if team == Team.DAWN else 0.68 + offset

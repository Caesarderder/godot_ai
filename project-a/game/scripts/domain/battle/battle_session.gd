class_name BattleSession
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

const TICKS_PER_SECOND: int = 5
const MAX_TICKS: int = 300
const TEAM_ALLY: int = 0
const TEAM_ENEMY: int = 1

const STAGE_NAMES: Array[String] = ["城市外围", "火力封锁区", "基地广场"]
const ROAD_END: int = 1000
const SKILL_COST: int = 100
const CANNON_FUSE_TICKS: int = 7

var tick_index: int = 0
var is_finished: bool = false
var result: Dictionary = {}

var _stage_index: int = 0
var _units: Array[Dictionary] = []
var _structures: Array[Dictionary] = []
var _pending_skills: Dictionary = {}
var _warnings: Array[Dictionary] = []
var _summon_serial: int = 0
var _revived_unit_ids: Dictionary = {}


func start(hero_snapshots: Array) -> void:
	tick_index = 0
	is_finished = false
	result = {}
	_stage_index = 0
	_units.clear()
	_structures = _make_structures()
	_pending_skills.clear()
	_warnings.clear()
	_summon_serial = 0
	_revived_unit_ids.clear()

	if hero_snapshots.size() != 6:
		is_finished = true
		result = _finish_result(false, "invalid_formation")
		result["ticks"] = 0
		return
	for slot in 6:
		var hero := _as_dictionary(hero_snapshots[slot])
		if not _is_known_archetype(String(hero.get("archetype_id", ""))):
			is_finished = true
			result = _finish_result(false, "unknown_archetype")
			result["ticks"] = 0
			_units.clear()
			return
		_units.append(_make_ally(hero, slot))
	_units.append_array(_make_enemies())


func request_skill(unit_id: StringName) -> bool:
	if is_finished:
		return false
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() or int(unit["team"]) != TEAM_ALLY or not bool(unit["alive"]) or bool(unit["temporary"]):
		return false
	if int(unit["energy"]) < SKILL_COST or _pending_skills.has(unit_id):
		return false
	_pending_skills[unit_id] = true
	return true


func set_auto_skill(unit_id: StringName, enabled: bool) -> bool:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() or int(unit["team"]) != TEAM_ALLY or bool(unit["temporary"]):
		return false
	unit["auto_skill"] = enabled
	return true


func advance_tick() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if is_finished:
		return events
	tick_index += 1
	_tick_status_effects()
	_resolve_cannon_warnings(events)
	_run_structure_defenses(events)
	_run_enemies(events)
	_run_allies(events)
	_update_stage(events)
	_resolve_battle(events)
	return events


func snapshot() -> Dictionary:
	var unit_snapshots: Array[Dictionary] = []
	var enemy_snapshots: Array[Dictionary] = []
	for unit in _units:
		if int(unit["team"]) == TEAM_ALLY:
			unit_snapshots.append(unit.duplicate(true))
		else:
			enemy_snapshots.append(unit.duplicate(true))
	var structure_snapshots: Array[Dictionary] = []
	for structure in _structures:
		structure_snapshots.append(structure.duplicate(true))
	return {
		"tick": tick_index,
		"max_ticks": MAX_TICKS,
		"finished": is_finished,
		"stage_index": _stage_index,
		"stage_name": STAGE_NAMES[_stage_index],
		"road_progress": _front_line(),
		"units": unit_snapshots,
		"enemies": enemy_snapshots,
		"structures": structure_snapshots,
		"warnings": _warnings.duplicate(true),
		"result": result.duplicate(true),
	}


func _run_allies(events: Array[Dictionary]) -> void:
	for unit in _units.duplicate():
		if int(unit["team"]) != TEAM_ALLY or not bool(unit["alive"]):
			continue
		_tick_common_combat(unit)
		var unit_id: StringName = unit["unit_id"]
		var wants_skill := _pending_skills.erase(unit_id)
		if not wants_skill and bool(unit["auto_skill"]) and int(unit["energy"]) >= SKILL_COST:
			wants_skill = true
		if wants_skill and int(unit["energy"]) >= SKILL_COST:
			_cast_skill(unit, events)
			continue
		var target := _current_target()
		if target.is_empty():
			continue
		if _move_toward_target(unit, target, events):
			continue
		if int(unit["cooldown_ticks"]) > 0:
			continue
		_damage_target(target, maxi(2, int(unit["attack"]) - _effective_defense(target)), unit_id, false, events)
		unit["cooldown_ticks"] = int(unit["attack_period_ticks"])
		var old_energy := int(unit["energy"])
		unit["energy"] = mini(SKILL_COST, old_energy + int(unit["energy_per_attack"]))
		events.append({"type": &"attack_started", "tick": tick_index, "unit_id": unit_id, "target_id": _target_id(target), "is_skill": false})
		if old_energy < SKILL_COST and int(unit["energy"]) == SKILL_COST:
			events.append({"type": &"skill_ready", "tick": tick_index, "unit_id": unit_id})


func _run_enemies(events: Array[Dictionary]) -> void:
	for enemy in _units.duplicate():
		if int(enemy["team"]) != TEAM_ENEMY or not bool(enemy["alive"]) or int(enemy["stage"]) != _stage_index:
			continue
		_tick_common_combat(enemy)
		if int(enemy.get("stun_ticks", 0)) > 0:
			continue
		if int(enemy["cooldown_ticks"]) > 0:
			continue
		var target := _select_enemy_target(enemy)
		if target.is_empty():
			continue
		var distance: int = absi(int(enemy["road_position"]) - int(target["road_position"]))
		if distance > int(enemy["range"]):
			enemy["road_position"] = maxi(int(target["road_position"]) + int(enemy["range"]), int(enemy["road_position"]) - int(enemy["move_per_tick"]))
			events.append({"type": &"unit_moved", "tick": tick_index, "unit_id": enemy["unit_id"], "road_position": enemy["road_position"]})
			continue
		var damage := int(enemy["attack"])
		if int(enemy.get("weakness_ticks", 0)) > 0:
			damage = int(damage * 65 / 100)
		_apply_unit_damage(target, damage, enemy["unit_id"], false, events)
		enemy["cooldown_ticks"] = int(enemy["attack_period_ticks"])
		events.append({"type": &"attack_started", "tick": tick_index, "unit_id": enemy["unit_id"], "target_id": target["unit_id"], "is_skill": false})


func _run_structure_defenses(events: Array[Dictionary]) -> void:
	for structure in _structures:
		if not bool(structure["alive"]) or int(structure["stage"]) > _stage_index:
			continue
		var kind := String(structure["kind"])
		if kind in ["turret", "battery"] and tick_index % int(structure["attack_period_ticks"]) == 0:
			_apply_unit_damage(_select_defense_target(int(structure["lane"])), int(structure["attack"]), structure["structure_id"], false, events)
		elif kind == "core" and _stage_index == 2:
			var living_batteries := _living_structure_count(["battery"])
			var period := 42 - living_batteries * 6
			if tick_index % period == 0:
				var lane := int(tick_index / period) % 3
				var warning := {
					"warning_id": "shell_%d" % tick_index,
					"impact_tick": tick_index + CANNON_FUSE_TICKS,
					"lane": lane,
					"damage": 46 + living_batteries * 9,
				}
				_warnings.append(warning)
				events.append({"type": &"artillery_warning", "tick": tick_index, "warning_id": warning["warning_id"], "lane": lane, "impact_tick": warning["impact_tick"]})


func _resolve_cannon_warnings(events: Array[Dictionary]) -> void:
	var remaining: Array[Dictionary] = []
	for warning in _warnings:
		if int(warning["impact_tick"]) > tick_index:
			remaining.append(warning)
			continue
		var hits := 0
		for unit in _units:
			if bool(unit["alive"]) and int(unit["team"]) == TEAM_ALLY and int(unit["lane"]) == int(warning["lane"]):
				_apply_unit_damage(unit, int(warning["damage"]), &"core_cannon", false, events)
				hits += 1
		events.append({"type": &"explosion", "tick": tick_index, "source_id": &"core_cannon", "lane": warning["lane"], "road_position": 865, "hits": hits})
		events.append({"type": &"artillery_impact", "tick": tick_index, "lane": warning["lane"], "hits": hits})
	_warnings = remaining


func _cast_skill(unit: Dictionary, events: Array[Dictionary]) -> void:
	var skill_id := String(unit["skill_id"])
	if not _known_skill_ids().has(skill_id):
		push_error("Unknown battle skill: %s" % skill_id)
		return
	var star := int(unit["star"])
	unit["energy"] = 0
	unit["cooldown_ticks"] = maxi(int(unit["cooldown_ticks"]), 2)
	events.append({
		"type": &"skill_used",
		"tick": tick_index,
		"unit_id": unit["unit_id"],
		"skill_id": skill_id,
		"archetype_id": unit["archetype_id"],
		"skill_tier": _skill_tier(unit),
	})
	match skill_id:
		"plunger_charge":
			var target := _first_living_enemy() if not _first_living_enemy().is_empty() else _current_target()
			if not target.is_empty():
				_damage_target(target, int(unit["attack"]) * (3 if star >= 3 else 2), unit["unit_id"], true, events)
			if star >= 2:
				_cleave_stage_enemies(unit, int(unit["attack"]), events)
			if star >= 3:
				var stun_target := _first_living_enemy()
				if not stun_target.is_empty():
					stun_target["stun_ticks"] = maxi(int(stun_target.get("stun_ticks", 0)), 10)
					events.append({"type": &"enemy_stunned", "tick": tick_index, "enemy_id": stun_target["unit_id"], "source_id": unit["unit_id"], "duration_ticks": 10})
		"sonic_disruptor":
			var sonic_targets: Array[Dictionary] = []
			for enemy in _living_stage_enemies():
				if star >= 2 or int(enemy["lane"]) == int(unit["lane"]):
					sonic_targets.append(enemy)
			for enemy in sonic_targets:
				enemy["weakness_ticks"] = 35 if star >= 2 else 22
				_damage_target(enemy, maxi(10, int(unit["attack"]) * (9 if star >= 3 else 5) / 10), unit["unit_id"], true, events)
				events.append({"type": &"enemy_weakened", "tick": tick_index, "enemy_id": enemy["unit_id"], "source_id": unit["unit_id"], "duration_ticks": enemy["weakness_ticks"]})
				if star >= 3 and not bool(enemy.get("elite", false)) and bool(enemy.get("alive", false)):
					enemy["stun_ticks"] = maxi(int(enemy.get("stun_ticks", 0)), 5)
					events.append({"type": &"enemy_stunned", "tick": tick_index, "enemy_id": enemy["unit_id"], "source_id": unit["unit_id"], "duration_ticks": 5})
		"rocket_salvo":
			var rocket_targets: Array[Dictionary] = []
			if star >= 2:
				rocket_targets = _current_stage_targets()
			else:
				var rocket_target := _current_target()
				if not rocket_target.is_empty():
					rocket_targets.append(rocket_target)
			for target in rocket_targets:
				_damage_target(target, maxi(18, int(unit["attack"]) * (18 if star >= 2 else 13) / 10), unit["unit_id"], true, events)
				if target.has("structure_id") and star >= 3:
					target["armor_break_ticks"] = 30
					events.append({"type": &"structure_armor_broken", "tick": tick_index, "structure_id": target["structure_id"], "source_id": unit["unit_id"], "duration_ticks": 30})
			events.append({"type": &"explosion", "tick": tick_index, "source_id": unit["unit_id"], "road_position": int(_current_target().get("road_position", _front_line())), "lane": 1, "hits": rocket_targets.size()})
		"suicide_dive":
			var target := _current_target()
			if not target.is_empty():
				_damage_target(target, int(unit["attack"]) * (5 if star >= 2 else 4), unit["unit_id"], true, events)
				if star >= 2:
					for extra in _current_stage_targets():
						if _target_id(extra) != _target_id(target):
							_damage_target(extra, int(unit["attack"]) * 8 / 10, unit["unit_id"], true, events)
				if star < 3:
					unit["hp"] = maxi(1, int(unit["max_hp"]) * 35 / 100)
		"siege_shield":
			for ally in _living_allies():
				ally["shield"] = int(ally["shield"]) + maxi(18, int(ally["max_hp"]) * (36 if star >= 3 else 26) / 100)
				ally["shield_ticks"] = 35
			if star >= 2:
				var gate := _structure_by_id(&"armored_gate")
				var target := gate if _is_structure_attackable(gate) else _current_target()
				if not target.is_empty():
					_damage_target(target, int(unit["attack"]) * 2, unit["unit_id"], true, events)
			if star >= 3:
				var elite := _elite_enemy_target()
				if not elite.is_empty():
					elite["taunt_target_id"] = unit["unit_id"]
					elite["taunt_ticks"] = 25
					events.append({"type": &"enemy_taunted", "tick": tick_index, "enemy_id": elite["unit_id"], "unit_id": unit["unit_id"], "duration_ticks": 25})
		"saw_rush":
			var target := _elite_enemy_target()
			if target.is_empty():
				target = _current_target()
			if not target.is_empty():
				var was_alive := bool(target["alive"])
				_damage_target(target, int(unit["attack"]) * (4 if star >= 2 else 3), unit["unit_id"], true, events)
				if star >= 2 and was_alive:
					_damage_target(target, int(unit["attack"]) * 2, unit["unit_id"], true, events)
				if star >= 3 and not bool(target.get("alive", true)):
					unit["energy"] = 55
		"field_repair":
			_heal_lowest_allies(unit, star, events)
		"parasite_swarm":
			if star >= 3 and _convert_enemy(unit, events):
				return
			_summon_parasites(unit, star, events)
		_:
			push_error("Unhandled known battle skill: %s" % skill_id)


func _damage_target(target: Dictionary, damage: int, source_id: StringName, is_skill: bool, events: Array[Dictionary]) -> void:
	if target.has("structure_id"):
		_damage_structure(target, damage, source_id, is_skill, events)
	elif target.has("unit_id"):
		_apply_unit_damage(target, damage, source_id, is_skill, events)


func _damage_structure(structure: Dictionary, damage: int, source_id: StringName, is_skill: bool, events: Array[Dictionary]) -> void:
	if structure.is_empty() or not bool(structure["alive"]) or not _is_structure_attackable(structure):
		return
	var actual := maxi(1, damage)
	if int(structure.get("armor_break_ticks", 0)) > 0:
		actual = int(actual * 125 / 100)
	var old_damage_stage := int(structure["damage_stage"])
	structure["hp"] = maxi(0, int(structure["hp"]) - actual)
	structure["damage_stage"] = _damage_stage(int(structure["hp"]), int(structure["max_hp"]))
	events.append({"type": &"structure_damaged", "tick": tick_index, "structure_id": structure["structure_id"], "source_id": source_id, "damage": actual, "hp": structure["hp"], "max_hp": structure["max_hp"], "is_skill": is_skill})
	if int(structure["damage_stage"]) != old_damage_stage:
		events.append({"type": &"structure_damage_stage_changed", "tick": tick_index, "structure_id": structure["structure_id"], "damage_stage": structure["damage_stage"]})
	if int(structure["hp"]) == 0:
		structure["alive"] = false
		events.append({"type": &"structure_destroyed", "tick": tick_index, "structure_id": structure["structure_id"], "road_position": structure["road_position"], "kind": structure["kind"]})
		events.append({"type": &"explosion", "tick": tick_index, "source_id": structure["structure_id"], "road_position": structure["road_position"], "lane": structure["lane"], "hits": 1})


func _apply_unit_damage(unit: Dictionary, raw_damage: int, source_id: StringName, is_skill: bool, events: Array[Dictionary]) -> void:
	if unit.is_empty() or not bool(unit["alive"]):
		return
	var damage := maxi(1, raw_damage - int(unit["defense"]) / 4)
	var absorbed := mini(int(unit.get("shield", 0)), damage)
	unit["shield"] = int(unit.get("shield", 0)) - absorbed
	damage -= absorbed
	unit["hp"] = maxi(0, int(unit["hp"]) - damage)
	if int(unit["team"]) == TEAM_ALLY:
		unit["energy"] = mini(SKILL_COST, int(unit["energy"]) + 8)
	events.append({"type": &"attack_hit", "tick": tick_index, "unit_id": unit["unit_id"], "source_id": source_id, "damage": damage, "absorbed": absorbed, "hp": unit["hp"], "max_hp": unit["max_hp"], "is_skill": is_skill})
	if int(unit["team"]) == TEAM_ENEMY:
		events.append({
			"type": &"enemy_damaged",
			"tick": tick_index,
			"enemy_id": unit["unit_id"],
			"unit_id": unit["unit_id"],
			"source_id": source_id,
			"damage": damage,
			"hp": unit["hp"],
			"max_hp": unit["max_hp"],
			"is_skill": is_skill,
		})
	if int(unit["hp"]) == 0:
		unit["alive"] = false
		events.append({"type": &"unit_died", "tick": tick_index, "unit_id": unit["unit_id"], "team": unit["team"]})
		if int(unit["team"]) == TEAM_ENEMY:
			events.append({"type": &"enemy_defeated", "tick": tick_index, "enemy_id": unit["unit_id"], "elite": unit["elite"]})


func _heal_lowest_allies(unit: Dictionary, star: int, events: Array[Dictionary]) -> void:
	if star >= 3:
		for ally in _units:
			if int(ally["team"]) == TEAM_ALLY and not bool(ally["alive"]) and not bool(ally["temporary"]) and not _revived_unit_ids.has(ally["unit_id"]):
				ally["alive"] = true
				ally["hp"] = int(ally["max_hp"]) * 35 / 100
				_revived_unit_ids[ally["unit_id"]] = true
				events.append({"type": &"unit_revived", "tick": tick_index, "unit_id": ally["unit_id"], "source_id": unit["unit_id"]})
				break
	var targets := _living_allies()
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["hp"]) * int(b["max_hp"]) < int(b["hp"]) * int(a["max_hp"]))
	var count := mini(targets.size(), 3 if star >= 2 else 1)
	for index in count:
		var ally := targets[index]
		var heal := maxi(22, int(unit["attack"]) * (16 if star >= 2 else 12) / 10)
		ally["hp"] = mini(int(ally["max_hp"]), int(ally["hp"]) + heal)
		events.append({"type": &"unit_healed", "tick": tick_index, "unit_id": ally["unit_id"], "source_id": unit["unit_id"], "heal": heal, "hp": ally["hp"]})


func _summon_parasites(owner: Dictionary, star: int, events: Array[Dictionary]) -> void:
	var count := 2 if star >= 2 else 1
	for _i in count:
		_summon_serial += 1
		var summon := _make_summon(owner, _summon_serial, "寄生幼体")
		_units.append(summon)
		events.append({"type": &"unit_summoned", "tick": tick_index, "unit_id": summon["unit_id"], "owner_id": owner["unit_id"]})


func _convert_enemy(owner: Dictionary, events: Array[Dictionary]) -> bool:
	for enemy in _living_stage_enemies():
		if not bool(enemy.get("elite", false)):
			enemy["team"] = TEAM_ALLY
			enemy["temporary"] = true
			enemy["display_name"] = "被寄生的%s" % enemy["display_name"]
			enemy["skill_id"] = ""
			events.append({"type": &"unit_converted", "tick": tick_index, "unit_id": enemy["unit_id"], "owner_id": owner["unit_id"]})
			return true
	return false


func _update_stage(events: Array[Dictionary]) -> void:
	var old_stage := _stage_index
	while _stage_index < 2 and _stage_cleared(_stage_index):
		_stage_index += 1
	if _stage_index != old_stage:
		events.append({"type": &"stage_changed", "tick": tick_index, "stage_index": _stage_index, "stage_name": STAGE_NAMES[_stage_index]})


func _resolve_battle(events: Array[Dictionary]) -> void:
	var main_allies_alive := _main_allies_alive()
	var reason := ""
	var victory := false
	if not _structure_alive(&"alliance_core"):
		reason = "core_destroyed"
		victory = true
	elif main_allies_alive == 0:
		reason = "main_squad_defeated"
	elif tick_index >= MAX_TICKS:
		reason = "timeout"
	else:
		return
	is_finished = true
	result = _finish_result(victory, reason)
	events.append({"type": &"battle_finished", "tick": tick_index, "result": result.duplicate(true)})


func _finish_result(victory: bool, reason: String) -> Dictionary:
	return {
		"outcome": "victory" if victory else ("timeout" if reason == "timeout" else "defeat"),
		"victory": victory,
		"reason": reason,
		"ticks": tick_index,
		"stage_reached": _stage_index,
		"road_progress": _front_line(),
		"main_allies_alive": _main_allies_alive(),
		"structures_destroyed": _destroyed_structure_count(),
		"enemies_defeated": _defeated_enemy_count(),
	}


func _current_target() -> Dictionary:
	var enemy := _first_living_enemy()
	if not enemy.is_empty():
		return enemy
	var structures := _attackable_stage_structures()
	if not structures.is_empty():
		return structures[0]
	return {}


func _current_stage_targets() -> Array[Dictionary]:
	var enemies := _living_stage_enemies()
	if not enemies.is_empty():
		return enemies
	return _attackable_stage_structures()


func _attackable_stage_structures() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for structure in _structures:
		if _is_structure_attackable(structure):
			targets.append(structure)
	return targets


func _is_structure_attackable(structure: Dictionary) -> bool:
	if structure.is_empty() or not bool(structure.get("alive", false)) or int(structure.get("stage", -1)) != _stage_index:
		return false
	if _stage_index != 2:
		return true
	var kind := String(structure.get("kind", ""))
	if kind == "battery":
		return true
	if String(structure.get("structure_id", "")) == "core_armor":
		return _living_structure_count(["battery"]) == 0
	if kind == "core":
		return _living_structure_count(["battery"]) == 0 and not _structure_alive(&"core_armor")
	return true


func _first_living_enemy() -> Dictionary:
	for unit in _units:
		if int(unit["team"]) == TEAM_ENEMY and bool(unit["alive"]) and int(unit["stage"]) == _stage_index:
			return unit
	return {}


func _elite_enemy_target() -> Dictionary:
	for unit in _living_stage_enemies():
		if bool(unit.get("elite", false)):
			return unit
	return {}


func _living_stage_enemies() -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	for unit in _units:
		if int(unit["team"]) == TEAM_ENEMY and bool(unit["alive"]) and int(unit["stage"]) == _stage_index:
			enemies.append(unit)
	return enemies


func _living_allies() -> Array[Dictionary]:
	var allies: Array[Dictionary] = []
	for unit in _units:
		if int(unit["team"]) == TEAM_ALLY and bool(unit["alive"]):
			allies.append(unit)
	return allies


func _select_enemy_target(enemy: Dictionary) -> Dictionary:
	if int(enemy.get("taunt_ticks", 0)) > 0:
		var taunt_target := _unit_by_id(StringName(String(enemy.get("taunt_target_id", ""))))
		if not taunt_target.is_empty() and int(taunt_target["team"]) == TEAM_ALLY and bool(taunt_target["alive"]):
			return taunt_target
	var best: Dictionary = {}
	var best_score := -2_147_483_648
	for unit in _units:
		if int(unit["team"]) != TEAM_ALLY or not bool(unit["alive"]):
			continue
		var score: int = -absi(int(enemy["road_position"]) - int(unit["road_position"])) * 10
		if int(unit["lane"]) == int(enemy["lane"]):
			score += 2000
		if not bool(unit["temporary"]):
			score += 600
		if best.is_empty() or score > best_score:
			best = unit
			best_score = score
	return best


func _select_defense_target(preferred_lane: int) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -2_147_483_648
	for unit in _units:
		if int(unit["team"]) != TEAM_ALLY or not bool(unit["alive"]):
			continue
		var score := int(unit["road_position"]) * 10
		if int(unit["lane"]) == preferred_lane:
			score += 5000
		if bool(unit["temporary"]):
			score -= 1000
		if best.is_empty() or score > best_score:
			best = unit
			best_score = score
	return best


func _move_toward_target(unit: Dictionary, target: Dictionary, events: Array[Dictionary]) -> bool:
	var distance := int(target["road_position"]) - int(unit["road_position"])
	if distance <= int(unit["range"]):
		return false
	var old_position := int(unit["road_position"])
	unit["road_position"] = mini(int(target["road_position"]) - int(unit["range"]), old_position + int(unit["move_per_tick"]))
	if int(unit["road_position"]) != old_position:
		events.append({"type": &"unit_moved", "tick": tick_index, "unit_id": unit["unit_id"], "road_position": unit["road_position"]})
	return true


func _tick_common_combat(unit: Dictionary) -> void:
	unit["cooldown_ticks"] = maxi(0, int(unit["cooldown_ticks"]) - 1)
	unit["shield_ticks"] = maxi(0, int(unit["shield_ticks"]) - 1)
	if int(unit["shield_ticks"]) == 0:
		unit["shield"] = 0


func _tick_status_effects() -> void:
	for unit in _units:
		unit["weakness_ticks"] = maxi(0, int(unit.get("weakness_ticks", 0)) - 1)
		unit["stun_ticks"] = maxi(0, int(unit.get("stun_ticks", 0)) - 1)
		unit["taunt_ticks"] = maxi(0, int(unit.get("taunt_ticks", 0)) - 1)
		if int(unit["taunt_ticks"]) == 0:
			unit["taunt_target_id"] = &""
	for structure in _structures:
		structure["armor_break_ticks"] = maxi(0, int(structure.get("armor_break_ticks", 0)) - 1)


func _cleave_stage_enemies(unit: Dictionary, damage: int, events: Array[Dictionary]) -> void:
	for enemy in _living_stage_enemies():
		_damage_target(enemy, damage, unit["unit_id"], true, events)


func _effective_defense(target: Dictionary) -> int:
	var defense := int(target.get("defense", 0))
	if int(target.get("weakness_ticks", 0)) > 0 or int(target.get("armor_break_ticks", 0)) > 0:
		defense = int(defense * 60 / 100)
	return defense


func _stage_cleared(stage: int) -> bool:
	for unit in _units:
		if int(unit["team"]) == TEAM_ENEMY and bool(unit["alive"]) and int(unit["stage"]) == stage:
			return false
	for structure in _structures:
		if bool(structure["alive"]) and int(structure["stage"]) == stage:
			return false
	return true


func _make_ally(hero: Dictionary, slot: int) -> Dictionary:
	var class_id := String(hero.get("class_id", "fighter"))
	var archetype_id := String(hero.get("archetype_id", class_id))
	var star := clampi(int(hero.get("star", 1)), 1, 5)
	var skill_id := _skill_for_archetype(archetype_id)
	var max_hp := maxi(90, int(hero.get("max_hp", 155)) + (star - 1) * 18)
	var attack := maxi(18, int(hero.get("attack", 38)) + (star - 1) * 5)
	var attack_range := _range_for_archetype(archetype_id, class_id)
	return {
		"unit_id": StringName(String(hero.get("hero_id", "ally_%02d" % slot))),
		"display_name": String(hero.get("display_name", "马桶主力 %d" % (slot + 1))),
		"archetype_id": archetype_id,
		"class_id": class_id,
		"star": star,
		"skill_id": skill_id,
		"team": TEAM_ALLY,
		"stage": 0,
		"elite": false,
		"slot": slot,
		"lane": slot % 3,
		"road_position": maxi(0, int(hero.get("road_position", 0)) - (slot / 3) * 18),
		"max_hp": max_hp,
		"hp": max_hp,
		"attack": attack,
		"defense": maxi(4, int(hero.get("defense", 14))),
		"range": attack_range,
		"move_per_tick": 10 if class_id != "guardian" else 8,
		"attack_period_ticks": 5 if class_id in ["ranger", "fighter"] else 6,
		"cooldown_ticks": 1 + slot % 3,
		"energy": clampi(int(hero.get("starting_energy", 0)), 0, SKILL_COST),
		"energy_per_attack": 20,
		"shield": 0,
		"shield_ticks": 0,
		"weakness_ticks": 0,
		"stun_ticks": 0,
		"taunt_ticks": 0,
		"taunt_target_id": &"",
		"auto_skill": bool(hero.get("auto_skill", hero.get("auto_skill_enabled", false))),
		"temporary": false,
		"alive": true,
	}


func _make_summon(owner: Dictionary, serial: int, display_name: String = "寄生幼体") -> Dictionary:
	return {
		"unit_id": StringName("summon_%02d" % serial),
		"display_name": display_name,
		"archetype_id": "summoned_grunt",
		"class_id": "fighter",
		"star": 1,
		"skill_id": "",
		"team": TEAM_ALLY,
		"stage": int(owner.get("stage", _stage_index)),
		"elite": false,
		"slot": 6 + serial,
		"lane": serial % 3,
		"road_position": maxi(0, int(owner["road_position"]) - 35),
		"max_hp": maxi(45, int(owner["max_hp"]) / 3),
		"hp": maxi(45, int(owner["max_hp"]) / 3),
		"attack": maxi(16, int(owner["attack"]) / 2),
		"defense": 4,
		"range": 28,
		"move_per_tick": 13,
		"attack_period_ticks": 4,
		"cooldown_ticks": 1,
		"energy": 0,
		"energy_per_attack": 0,
		"shield": 0,
		"shield_ticks": 0,
		"weakness_ticks": 0,
		"stun_ticks": 0,
		"taunt_ticks": 0,
		"taunt_target_id": &"",
		"auto_skill": false,
		"temporary": true,
		"alive": true,
	}


func _make_enemies() -> Array[Dictionary]:
	return [
		_enemy("cam_grunt_l", "联盟摄像兵", "fighter", 0, 230, 0, 115, 22, 7, 32, 8, false),
		_enemy("cam_grunt_c", "联盟摄像兵", "fighter", 0, 250, 1, 125, 23, 7, 32, 8, false),
		_enemy("speaker_grunt", "联盟音箱兵", "arcanist", 0, 270, 2, 105, 24, 5, 90, 9, false),
		_enemy("shield_captain", "盾阵队长", "guardian", 1, 505, 1, 230, 32, 14, 36, 8, true),
		_enemy("turret_guard_l", "火力守军", "ranger", 1, 480, 0, 145, 29, 8, 110, 7, false),
		_enemy("turret_guard_r", "火力守军", "ranger", 1, 520, 2, 145, 29, 8, 110, 7, false),
		_enemy("tv_elite", "电视精英", "arcanist", 2, 805, 1, 285, 36, 12, 100, 8, true),
		_enemy("core_guard_l", "核心近卫", "guardian", 2, 840, 0, 220, 31, 14, 38, 7, true),
		_enemy("core_guard_r", "核心近卫", "guardian", 2, 840, 2, 220, 31, 14, 38, 7, true),
	]


func _enemy(id: String, label: String, class_id: String, stage: int, road_position: int, lane: int, hp: int, attack: int, defense: int, attack_range: int, period: int, elite: bool) -> Dictionary:
	return {
		"unit_id": StringName(id),
		"display_name": label,
		"archetype_id": "alliance",
		"class_id": class_id,
		"star": 1,
		"skill_id": "",
		"team": TEAM_ENEMY,
		"stage": stage,
		"elite": elite,
		"slot": 20 + stage * 4 + lane,
		"lane": lane,
		"road_position": road_position,
		"max_hp": hp,
		"hp": hp,
		"attack": attack,
		"defense": defense,
		"range": attack_range,
		"move_per_tick": 4,
		"attack_period_ticks": period,
		"cooldown_ticks": 2 + lane,
		"energy": 0,
		"energy_per_attack": 0,
		"shield": 0,
		"shield_ticks": 0,
		"weakness_ticks": 0,
		"stun_ticks": 0,
		"taunt_ticks": 0,
		"taunt_target_id": &"",
		"auto_skill": false,
		"temporary": false,
		"alive": true,
	}


func _make_structures() -> Array[Dictionary]:
	return [
		_structure("outer_barricade", "外围路障", "structure", 0, 300, 1, 260, 11, 0, 0),
		_structure("fire_tower", "火力塔", "turret", 1, 560, 0, 440, 12, 18, 8),
		_structure("armored_gate", "装甲大门", "armored", 1, 640, 1, 700, 18, 0, 0),
		_structure("left_battery", "左防御设施", "battery", 2, 815, 0, 450, 13, 23, 9),
		_structure("right_battery", "右防御设施", "battery", 2, 815, 2, 450, 13, 23, 9),
		_structure("core_armor", "核心外层装甲", "armored", 2, 900, 1, 650, 20, 0, 0),
		_structure("alliance_core", "联盟核心巨炮", "core", 2, ROAD_END, 1, 900, 16, 0, 0),
	]


func _structure(id: String, label: String, kind: String, stage: int, road_position: int, lane: int, max_hp: int, defense: int, attack: int, attack_period_ticks: int) -> Dictionary:
	return {
		"structure_id": StringName(id),
		"display_name": label,
		"kind": kind,
		"stage": stage,
		"road_position": road_position,
		"lane": lane,
		"max_hp": max_hp,
		"hp": max_hp,
		"defense": defense,
		"attack": attack,
		"attack_period_ticks": attack_period_ticks,
		"armor_break_ticks": 0,
		"damage_stage": 0,
		"alive": true,
	}


func _skill_for_archetype(archetype_id: String) -> String:
	return FactoryCatalogScript.active_skill_for_archetype(archetype_id)


func _is_known_archetype(archetype_id: String) -> bool:
	return not FactoryCatalogScript.archetype(archetype_id).is_empty()


func _known_skill_ids() -> Array[String]:
	return [
		"plunger_charge",
		"sonic_disruptor",
		"rocket_salvo",
		"suicide_dive",
		"siege_shield",
		"saw_rush",
		"field_repair",
		"parasite_swarm",
	]


func _skill_tier(unit: Dictionary) -> int:
	var star := int(unit.get("star", 1))
	if star >= 3:
		return 3
	if star >= 2:
		return 2
	return 1


func _range_for_archetype(archetype_id: String, class_id: String) -> int:
	if archetype_id in ["rocket", "sonic", "parasite"]:
		return 110
	if class_id in ["ranger", "arcanist"]:
		return 86
	return 34


func _structure_alive(structure_id: StringName) -> bool:
	for structure in _structures:
		if structure["structure_id"] == structure_id:
			return bool(structure["alive"])
	return false


func _structure_by_id(structure_id: StringName) -> Dictionary:
	for structure in _structures:
		if structure["structure_id"] == structure_id:
			return structure
	return {}


func _living_structure_count(kinds: Array = []) -> int:
	var count := 0
	for structure in _structures:
		if bool(structure["alive"]) and (kinds.is_empty() or kinds.has(String(structure["kind"]))):
			count += 1
	return count


func _destroyed_structure_count() -> int:
	return _structures.size() - _living_structure_count()


func _defeated_enemy_count() -> int:
	var count := 0
	for unit in _units:
		if int(unit["team"]) == TEAM_ENEMY and not bool(unit["alive"]):
			count += 1
	return count


func _main_allies_alive() -> int:
	var count := 0
	for unit in _units:
		if bool(unit["alive"]) and int(unit["team"]) == TEAM_ALLY and not bool(unit["temporary"]):
			count += 1
	return count


func _damage_stage(hp: int, max_hp: int) -> int:
	if hp <= 0:
		return 3
	if hp * 4 <= max_hp:
		return 2
	if hp * 5 <= max_hp * 3:
		return 1
	return 0


func _front_line() -> int:
	var value := 0
	for unit in _units:
		if bool(unit["alive"]) and int(unit["team"]) == TEAM_ALLY:
			value = maxi(value, int(unit["road_position"]))
	return value


func _target_id(target: Dictionary) -> StringName:
	if target.has("unit_id"):
		return target["unit_id"]
	return target.get("structure_id", &"")


func _unit_by_id(unit_id: StringName) -> Dictionary:
	for unit in _units:
		if unit["unit_id"] == unit_id:
			return unit
	return {}


func _as_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	if value is Object and value.has_method("to_dict"):
		return (value.call("to_dict") as Dictionary).duplicate(true)
	return {}

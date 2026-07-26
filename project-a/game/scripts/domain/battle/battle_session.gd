class_name BattleSession
extends RefCounted

const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

const TICKS_PER_SECOND: int = 5
const TEAM_ALLY: int = 0
const TEAM_ENEMY: int = 1

const STAGE_NAMES: Array[String] = ["城市外围", "火力封锁区", "基地广场"]
const ROAD_END: int = 1000
const SKILL_COST: int = 100
const CANNON_FUSE_TICKS: int = 7
const DAMAGE_ENERGY_PER_MAX_HP_PERCENT: int = 1
const DAMAGE_ENERGY_PER_HIT_CAP: int = 10
const DAMAGE_ENERGY_PER_SECOND_CAP: int = 20
const GMAN_OVERRUN_BASE_DAMAGE_BP: int = 20000

var tick_index: int = 0
var is_finished: bool = false
var result: Dictionary = {}

var _stage_index: int = 0
var _stage_id: String = StageCatalogScript.DEFAULT_STAGE_ID
var _stage_config: Dictionary = {}
var _stage_names: Array[String] = StageCatalogScript.DEFAULT_STAGE_NAMES.duplicate()
var _final_structure_id: StringName = &"alliance_core"
var _units: Array[Dictionary] = []
var _structures: Array[Dictionary] = []
var _pending_skills: Dictionary = {}
var _warnings: Array[Dictionary] = []
var _suppressible_cannon: bool = false
var _cannon_suppression_target: int = 0
var _cannon_warning_ticks: int = CANNON_FUSE_TICKS
var _cannons_suppressed: int = 0
var _cannon_impacts: int = 0
var _cannon_impacts_guarded: int = 0
var _cannon_guard_counter_damage: int = 0
var _summon_serial: int = 0
var _revived_unit_ids: Dictionary = {}
var _ally_damage_taken: int = 0
var _troop_damage_taken: int = 0
var _ally_damage_dealt_by_unit: Dictionary = {}
var _assault_cleave_extra_hits: int = 0
var _started_solo: bool = false
var _solo_pressure_bp: int = 10000


func start(hero_snapshots: Array, stage_id: String = StageCatalogScript.DEFAULT_STAGE_ID, stage_config: Dictionary = {}) -> void:
	tick_index = 0
	is_finished = false
	result = {}
	_stage_index = 0
	_stage_id = stage_id
	_stage_config = stage_config.duplicate(true) if not stage_config.is_empty() else StageCatalogScript.stage(stage_id)
	if _stage_config.is_empty():
		_stage_id = StageCatalogScript.DEFAULT_STAGE_ID
		_stage_config = StageCatalogScript.stage(_stage_id)
	_stage_names = []
	for stage_name in _stage_config.get("stage_names", StageCatalogScript.DEFAULT_STAGE_NAMES):
		_stage_names.append(String(stage_name))
	if _stage_names.is_empty():
		_stage_names = StageCatalogScript.DEFAULT_STAGE_NAMES.duplicate()
	_final_structure_id = StringName(String(_stage_config.get("final_structure_id", "alliance_core")))
	_suppressible_cannon = bool(_stage_config.get("suppressible_cannon", false))
	_cannon_suppression_target = maxi(0, int(_stage_config.get("cannon_suppression_target", 0)))
	_cannon_warning_ticks = int(_stage_config.get("cannon_warning_ticks", CANNON_FUSE_TICKS))
	_solo_pressure_bp = maxi(10000, int(_stage_config.get("solo_pressure_bp", 10000)))
	if _cannon_warning_ticks <= 0:
		_cannon_warning_ticks = CANNON_FUSE_TICKS
	_units.clear()
	_structures = _make_structures()
	_pending_skills.clear()
	_warnings.clear()
	_cannons_suppressed = 0
	_cannon_impacts = 0
	_cannon_impacts_guarded = 0
	_cannon_guard_counter_damage = 0
	_summon_serial = 0
	_revived_unit_ids.clear()
	_ally_damage_taken = 0
	_troop_damage_taken = 0
	_ally_damage_dealt_by_unit.clear()
	_assault_cleave_extra_hits = 0
	_started_solo = false

	if hero_snapshots.is_empty() or hero_snapshots.size() > 6:
		is_finished = true
		result = _finish_result(false, "invalid_formation")
		result["ticks"] = 0
		return
	for slot in hero_snapshots.size():
		var hero := _as_dictionary(hero_snapshots[slot])
		if not _is_known_archetype(String(hero.get("archetype_id", ""))):
			is_finished = true
			result = _finish_result(false, "unknown_archetype")
			result["ticks"] = 0
			_units.clear()
			return
		_units.append(_make_ally(hero, slot))
	_started_solo = hero_snapshots.size() == 1
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


static func damage_energy_gain(damage: int, max_hp: int) -> int:
	if damage <= 0 or max_hp <= 0:
		return 0
	var lost_hp_percent := ceili(float(damage) * 100.0 / float(max_hp))
	return clampi(
		lost_hp_percent * DAMAGE_ENERGY_PER_MAX_HP_PERCENT,
		1,
		DAMAGE_ENERGY_PER_HIT_CAP
	)


func set_auto_skill(unit_id: StringName, enabled: bool) -> bool:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() or int(unit["team"]) != TEAM_ALLY or bool(unit["temporary"]):
		return false
	unit["auto_skill"] = enabled
	return true


func retreat() -> bool:
	if is_finished:
		return false
	is_finished = true
	result = _finish_result(false, "player_retreat")
	result["outcome"] = "retreat"
	return true


func advance_tick() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if is_finished:
		return events
	tick_index += 1
	_tick_status_effects()
	_resolve_cannon_warnings(events)
	_run_structure_defenses(events)
	_run_chapter_mechanics(events)
	_run_enemies(events)
	_run_allies(events)
	_update_stage(events)
	_resolve_battle(events)
	return events


func _run_chapter_mechanics(events: Array[Dictionary]) -> void:
	var chapter := int(_stage_config.get("chapter", 1))
	if chapter == 2 and tick_index % 35 == 0:
		var affected := 0
		for ally in _living_main_allies():
			ally["energy"] = maxi(0, int(ally["energy"]) - 18)
			ally["weakness_ticks"] = maxi(int(ally.get("weakness_ticks", 0)), 8)
			affected += 1
		events.append({"type": &"resonance_pulse", "tick": tick_index, "affected": affected})
	elif chapter == 3 and tick_index % 40 == 0:
		var target := _lowest_hp_ally()
		if not target.is_empty():
			target["stun_ticks"] = maxi(int(target.get("stun_ticks", 0)), 8)
			events.append({"type": &"screen_control", "tick": tick_index, "unit_id": target["unit_id"], "duration_ticks": 8})
	elif chapter >= 4 and tick_index % 30 == 0:
		var shielded := 0
		for enemy in _living_stage_enemies():
			if bool(enemy.get("elite", false)):
				enemy["shield"] = mini(90, int(enemy.get("shield", 0)) + 28)
				enemy["shield_ticks"] = 20
				shielded += 1
		if shielded > 0:
			events.append({"type": &"alliance_coordination", "tick": tick_index, "shielded": shielded})


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
	var warning_snapshots: Array[Dictionary] = []
	for warning in _warnings:
		var warning_snapshot := warning.duplicate(true)
		warning_snapshot["remaining_ticks"] = maxi(0, int(warning_snapshot.get("impact_tick", tick_index)) - tick_index)
		if bool(warning_snapshot.get("suppressible", false)):
			var target := int(warning_snapshot.get("suppression_target", 0))
			var damage := int(warning_snapshot.get("suppression_damage", 0))
			warning_snapshot["suppression_current"] = damage
			warning_snapshot["suppression_remaining"] = maxi(0, target - damage)
		warning_snapshots.append(warning_snapshot)
	return {
		"tick": tick_index,
		"finished": is_finished,
		"stage_id": _stage_id,
		"stage_index": _stage_index,
		"stage_count": _stage_names.size(),
		"stage_name": _stage_names[clampi(_stage_index, 0, _stage_names.size() - 1)],
		"road_progress": _front_line(),
		"units": unit_snapshots,
		"enemies": enemy_snapshots,
		"structures": structure_snapshots,
		"warnings": warning_snapshots,
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
		var attack_period := int(structure["attack_period_ticks"])
		if String(structure["structure_id"]) == "warning_turret" and (tick_index + 2) % attack_period == 0:
			events.append({
				"type": &"artillery_warning",
				"tick": tick_index,
				"warning_id": "light_shell_%d" % (tick_index + 2),
				"lane": int(structure["lane"]),
				"impact_tick": tick_index + 2,
				"suppressible": false,
				"source_structure_id": structure["structure_id"],
			})
		if kind in ["turret", "battery"] and tick_index % int(structure["attack_period_ticks"]) == 0:
			_apply_unit_damage(_select_defense_target(int(structure["lane"])), int(structure["attack"]), structure["structure_id"], false, events)
		elif kind == "core" and _stage_index == _stage_names.size() - 1:
			var living_batteries := _living_structure_count(["battery"])
			var period := 42 - living_batteries * 6
			if tick_index % period == 0:
				var lane := int(tick_index / period) % 3
				var is_suppressible := _is_suppressible_cannon_active()
				var warning_ticks := _cannon_warning_ticks if is_suppressible else CANNON_FUSE_TICKS
				var warning := {
					"warning_id": "shell_%d" % tick_index,
					"impact_tick": tick_index + warning_ticks,
					"lane": lane,
					"damage": 46 + living_batteries * 9,
					"suppressible": is_suppressible,
				}
				if is_suppressible:
					warning["source_structure_id"] = structure["structure_id"]
					warning["suppression_target"] = _cannon_suppression_target
					warning["suppression_damage"] = 0
					warning["suppression_current"] = 0
					warning["suppression_remaining"] = _cannon_suppression_target
				_warnings.append(warning)
				var event := {"type": &"artillery_warning", "tick": tick_index, "warning_id": warning["warning_id"], "lane": lane, "impact_tick": warning["impact_tick"], "suppressible": is_suppressible}
				if is_suppressible:
					event["suppression_target"] = _cannon_suppression_target
					event["suppression_current"] = 0
					event["remaining_ticks"] = warning_ticks
				events.append(event)


func _resolve_cannon_warnings(events: Array[Dictionary]) -> void:
	var remaining: Array[Dictionary] = []
	for warning in _warnings:
		if int(warning["impact_tick"]) > tick_index:
			remaining.append(warning)
			continue
		var hits := 0
		var guarded := false
		for unit in _units:
			if bool(unit["alive"]) and int(unit["team"]) == TEAM_ALLY and int(unit["lane"]) == int(warning["lane"]):
				guarded = guarded or int(unit.get("cannon_guard_ticks", 0)) > 0
				_apply_unit_damage(unit, int(warning["damage"]), &"core_cannon", false, events)
				hits += 1
		if guarded:
			var source_structure := _structure_by_id(StringName(String(warning.get("source_structure_id", ""))))
			if not source_structure.is_empty():
				_damage_structure(source_structure, 60, &"siege_shield_counter", true, events)
				_cannon_guard_counter_damage += 60
				events.append({
					"type": &"cannon_guard_counter",
					"tick": tick_index,
					"warning_id": warning.get("warning_id", ""),
					"structure_id": source_structure.get("structure_id", &""),
					"lane": int(warning.get("lane", 1)),
					"damage": 60,
				})
		events.append({"type": &"explosion", "tick": tick_index, "source_id": &"core_cannon", "lane": warning["lane"], "road_position": 865, "hits": hits})
		_cannon_impacts += 1
		if guarded:
			_cannon_impacts_guarded += 1
		events.append({"type": &"artillery_impact", "tick": tick_index, "warning_id": warning.get("warning_id", ""), "lane": warning["lane"], "hits": hits, "guarded": guarded})
	_warnings = remaining


func _is_suppressible_cannon_active() -> bool:
	return _suppressible_cannon and _stage_index == _stage_names.size() - 1 and _cannon_suppression_target > 0


func _record_cannon_suppression_damage(structure: Dictionary, actual_damage: int, events: Array[Dictionary]) -> void:
	if actual_damage <= 0 or not _is_suppressible_cannon_active() or int(structure.get("stage", -1)) != _stage_index:
		return
	if _warnings.is_empty():
		return
	var remaining: Array[Dictionary] = []
	for warning in _warnings:
		if not bool(warning.get("suppressible", false)) or int(warning.get("impact_tick", 0)) <= tick_index:
			remaining.append(warning)
			continue
		var target := int(warning.get("suppression_target", _cannon_suppression_target))
		var damage := int(warning.get("suppression_damage", 0)) + actual_damage
		warning["suppression_damage"] = damage
		warning["suppression_current"] = damage
		warning["suppression_remaining"] = maxi(0, target - damage)
		if damage >= target:
			_cannons_suppressed += 1
			events.append({
				"type": &"cannon_suppressed",
				"tick": tick_index,
				"warning_id": warning.get("warning_id", ""),
				"structure_id": structure.get("structure_id", &""),
				"damage": damage,
				"target": target,
			})
			continue
		remaining.append(warning)
	_warnings = remaining


func _cast_skill(unit: Dictionary, events: Array[Dictionary]) -> void:
	var skill_id := String(unit["skill_id"])
	if not _known_skill_ids().has(skill_id):
		push_error("Unknown battle skill: %s" % skill_id)
		return
	var star := int(unit["star"])
	var base_attack := int(unit["attack"])
	var skill_level := clampi(int(unit.get("skill_level", 1)), 1, 3)
	var casts_used := maxi(0, int(unit.get("skill_casts", 0)))
	unit["attack"] = int(round(float(base_attack) * float(10000 + (skill_level - 1) * 2000) / 10000.0))
	unit["energy"] = 0
	unit["skill_casts"] = casts_used + 1
	unit["cooldown_ticks"] = maxi(int(unit["cooldown_ticks"]), 2)
	events.append({
		"type": &"skill_used",
		"tick": tick_index,
		"unit_id": unit["unit_id"],
		"skill_id": skill_id,
		"archetype_id": unit["archetype_id"],
		"skill_tier": _skill_tier(unit),
		"skill_level": skill_level,
	})
	match skill_id:
		"gman_overrun":
			var opening_damage_bp := maxi(
				GMAN_OVERRUN_BASE_DAMAGE_BP,
				int(_stage_config.get("gman_opening_damage_bp", GMAN_OVERRUN_BASE_DAMAGE_BP))
			)
			var damage_bp := gman_overrun_damage_bp(casts_used, opening_damage_bp)
			for target in _current_stage_targets():
				_damage_target(
					target,
					int(unit["attack"]) * damage_bp / 10000,
					unit["unit_id"],
					true,
					events
				)
			unit["shield"] = maxi(int(unit.get("shield", 0)), 80)
			unit["shield_ticks"] = 20
		"plunger_charge":
			var target := _first_living_enemy() if not _first_living_enemy().is_empty() else _current_target()
			if not target.is_empty():
				_damage_target(target, int(unit["attack"]) * (3 if star >= 3 else 2), unit["unit_id"], true, events)
			if star >= 2:
				var cleave_targets := _living_stage_enemies().size()
				_cleave_stage_enemies(unit, int(unit["attack"]), events)
				_assault_cleave_extra_hits += maxi(0, cleave_targets - 1)
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
			var shield_percent := 48 if star >= 3 else (40 if star >= 2 else 26)
			for ally in _living_allies():
				var shield_gain := maxi(18, int(ally["max_hp"]) * shield_percent / 100)
				ally["shield"] = int(ally["shield"]) + shield_gain
				ally["shield_ticks"] = 35
				if star >= 2:
					# Two-star armor turns one well-timed warning cast into an
					# anti-artillery stance for the rest of the core assault.
					ally["cannon_guard_ticks"] = 300
				events.append({
					"type": &"unit_shielded",
					"tick": tick_index,
					"unit_id": ally["unit_id"],
					"source_id": unit["unit_id"],
					"shield": shield_gain,
					"shield_total": int(ally["shield"]),
					"cannon_guard": star >= 2,
				})
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
				unit["attack"] = base_attack
				return
			_summon_parasites(unit, star, events)
		_:
			push_error("Unhandled known battle skill: %s" % skill_id)
	unit["attack"] = base_attack


static func gman_overrun_damage_bp(casts_used: int, opening_damage_bp: int = GMAN_OVERRUN_BASE_DAMAGE_BP) -> int:
	return maxi(GMAN_OVERRUN_BASE_DAMAGE_BP, opening_damage_bp) if casts_used <= 0 else GMAN_OVERRUN_BASE_DAMAGE_BP


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
	var effective_damage := mini(int(structure["hp"]), actual)
	var old_damage_stage := int(structure["damage_stage"])
	structure["hp"] = maxi(0, int(structure["hp"]) - actual)
	structure["damage_stage"] = _damage_stage(int(structure["hp"]), int(structure["max_hp"]))
	_record_ally_damage_dealt(source_id, effective_damage)
	events.append({"type": &"structure_damaged", "tick": tick_index, "structure_id": structure["structure_id"], "source_id": source_id, "damage": actual, "effective_damage": effective_damage, "hp": structure["hp"], "max_hp": structure["max_hp"], "is_skill": is_skill})
	_record_cannon_suppression_damage(structure, actual, events)
	if int(structure["damage_stage"]) != old_damage_stage:
		events.append({"type": &"structure_damage_stage_changed", "tick": tick_index, "structure_id": structure["structure_id"], "damage_stage": structure["damage_stage"]})
	if int(structure["hp"]) == 0:
		structure["alive"] = false
		events.append({
			"type": &"structure_destroyed",
			"tick": tick_index,
			"structure_id": structure["structure_id"],
			"display_name": structure["display_name"],
			"road_position": structure["road_position"],
			"lane": structure["lane"],
			"kind": structure["kind"],
		})
		events.append({"type": &"explosion", "tick": tick_index, "source_id": structure["structure_id"], "road_position": structure["road_position"], "lane": structure["lane"], "hits": 1})


func _apply_unit_damage(unit: Dictionary, raw_damage: int, source_id: StringName, is_skill: bool, events: Array[Dictionary]) -> void:
	if unit.is_empty() or not bool(unit["alive"]):
		return
	if source_id == &"core_cannon" and int(unit.get("cannon_guard_ticks", 0)) > 0:
		raw_damage = int(ceil(float(raw_damage) * 0.5))
	if int(unit["team"]) == TEAM_ALLY and _started_solo:
		raw_damage = int(raw_damage * _solo_pressure_bp / 10000)
	var damage := maxi(1, raw_damage - int(unit["defense"]) / 4)
	var absorbed := mini(int(unit.get("shield", 0)), damage)
	unit["shield"] = int(unit.get("shield", 0)) - absorbed
	damage -= absorbed
	var effective_health_damage := mini(int(unit["hp"]), damage)
	unit["hp"] = maxi(0, int(unit["hp"]) - damage)
	var received_energy := 0
	if int(unit["team"]) == TEAM_ALLY:
		if damage > 0 and int(unit["hp"]) > 0:
			var window_second := int(tick_index / TICKS_PER_SECOND)
			if int(unit.get("damage_energy_window_second", -1)) != window_second:
				unit["damage_energy_window_second"] = window_second
				unit["damage_energy_in_window"] = 0
			var remaining_window := maxi(
				0,
				DAMAGE_ENERGY_PER_SECOND_CAP - int(unit.get("damage_energy_in_window", 0))
			)
			received_energy = mini(
				damage_energy_gain(damage, int(unit["max_hp"])),
				remaining_window
			)
			var old_energy := int(unit["energy"])
			unit["energy"] = mini(SKILL_COST, old_energy + received_energy)
			unit["damage_energy_in_window"] = int(unit.get("damage_energy_in_window", 0)) + received_energy
			if old_energy < SKILL_COST and int(unit["energy"]) == SKILL_COST:
				events.append({"type": &"skill_ready", "tick": tick_index, "unit_id": unit["unit_id"]})
		if not bool(unit.get("temporary", false)):
			_ally_damage_taken += damage
			if String(unit.get("archetype_id", "")) != "gman":
				_troop_damage_taken += damage
	events.append({"type": &"attack_hit", "tick": tick_index, "unit_id": unit["unit_id"], "source_id": source_id, "damage": damage, "absorbed": absorbed, "energy_gain": received_energy, "hp": unit["hp"], "max_hp": unit["max_hp"], "is_skill": is_skill})
	if int(unit["team"]) == TEAM_ENEMY:
		_record_ally_damage_dealt(source_id, effective_health_damage)
		events.append({
			"type": &"enemy_damaged",
			"tick": tick_index,
			"enemy_id": unit["unit_id"],
			"unit_id": unit["unit_id"],
			"source_id": source_id,
			"damage": damage,
			"effective_damage": effective_health_damage,
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
	while _stage_index < _stage_names.size() - 1 and _stage_cleared(_stage_index):
		_stage_index += 1
	if _stage_index != old_stage:
		events.append({"type": &"stage_changed", "tick": tick_index, "stage_index": _stage_index, "stage_name": _stage_names[_stage_index]})


func _resolve_battle(events: Array[Dictionary]) -> void:
	var main_allies_alive := _main_allies_alive()
	var reason := ""
	var victory := false
	if not _structure_alive(_final_structure_id):
		reason = "core_destroyed"
		victory = true
	elif main_allies_alive == 0:
		reason = "main_squad_defeated"
	else:
		return
	is_finished = true
	result = _finish_result(victory, reason)
	events.append({"type": &"battle_finished", "tick": tick_index, "result": result.duplicate(true)})


func _finish_result(victory: bool, reason: String) -> Dictionary:
	var gman_survived := false
	var gman_hp := 0
	var gman_max_hp := 0
	for unit in _units:
		if int(unit.get("team", TEAM_ENEMY)) == TEAM_ALLY and String(unit.get("archetype_id", "")) == "gman":
			gman_survived = bool(unit.get("alive", false))
			gman_hp = int(unit.get("hp", 0))
			gman_max_hp = int(unit.get("max_hp", 0))
			break
	var troop_damage_share_percent := 0
	var deployed_unit_ids: Array[String] = []
	var dead_unit_ids: Array[String] = []
	var surviving_unit_ids: Array[String] = []
	for unit in _units:
		if int(unit.get("team", TEAM_ENEMY)) != TEAM_ALLY or bool(unit.get("temporary", false)):
			continue
		var unit_id := String(unit.get("unit_id", ""))
		deployed_unit_ids.append(unit_id)
		if bool(unit.get("alive", false)):
			surviving_unit_ids.append(unit_id)
		else:
			dead_unit_ids.append(unit_id)
	if _ally_damage_taken > 0:
		troop_damage_share_percent = int(round(float(_troop_damage_taken) * 100.0 / float(_ally_damage_taken)))
	return {
		"outcome": "victory" if victory else "defeat",
		"stage_id": _stage_id,
		"victory": victory,
		"reason": reason,
		"ticks": tick_index,
		"stage_reached": _stage_index,
		"road_progress": _front_line(),
		"main_allies_alive": _main_allies_alive(),
		"structures_destroyed": _destroyed_structure_count(),
		"enemies_defeated": _defeated_enemy_count(),
		"cannons_suppressed": _cannons_suppressed,
		"cannon_impacts": _cannon_impacts,
		"cannon_suppressed_count": _cannons_suppressed,
		"cannon_hit_count": _cannon_impacts,
		"cannon_guarded_count": _cannon_impacts_guarded,
		"cannon_guard_counter_damage": _cannon_guard_counter_damage,
		"ally_damage_taken": _ally_damage_taken,
		"troop_damage_taken": _troop_damage_taken,
		"troop_damage_share_percent": troop_damage_share_percent,
		"ally_damage_dealt_by_unit": _ally_damage_dealt_by_unit.duplicate(true),
		"assault_cleave_extra_hits": _assault_cleave_extra_hits,
		"gman_survived": gman_survived,
		"gman_hp": gman_hp,
		"gman_max_hp": gman_max_hp,
		"deployed_unit_ids": deployed_unit_ids,
		"dead_unit_ids": dead_unit_ids,
		"surviving_unit_ids": surviving_unit_ids,
	}


func _record_ally_damage_dealt(source_id: StringName, damage: int) -> void:
	if damage <= 0:
		return
	var source := _unit_by_id(source_id)
	if source.is_empty() or int(source.get("team", TEAM_ENEMY)) != TEAM_ALLY:
		return
	if bool(source.get("temporary", false)):
		return
	var key := String(source_id)
	_ally_damage_dealt_by_unit[key] = int(_ally_damage_dealt_by_unit.get(key, 0)) + damage


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


func _living_main_allies() -> Array[Dictionary]:
	var allies: Array[Dictionary] = []
	for unit in _living_allies():
		if not bool(unit.get("temporary", false)):
			allies.append(unit)
	return allies


func _lowest_hp_ally() -> Dictionary:
	var target: Dictionary = {}
	var lowest_ratio := 2.0
	for ally in _living_main_allies():
		var ratio := float(int(ally["hp"])) / float(maxi(1, int(ally["max_hp"])))
		if target.is_empty() or ratio < lowest_ratio:
			target = ally
			lowest_ratio = ratio
	return target


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
		unit["cannon_guard_ticks"] = maxi(0, int(unit.get("cannon_guard_ticks", 0)) - 1)
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
		"skill_level": clampi(int(hero.get("skill_level", 1)), 1, 3),
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
		"skill_casts": 0,
		"damage_energy_window_second": -1,
		"damage_energy_in_window": 0,
		"shield": 0,
		"shield_ticks": 0,
		"cannon_guard_ticks": 0,
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
		"skill_casts": 0,
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
	var values: Array[Dictionary] = []
	for enemy_data in _stage_config.get("enemies", []):
		var enemy := enemy_data as Dictionary
		values.append(_enemy(
			String(enemy["unit_id"]),
			String(enemy["display_name"]),
			String(enemy["class_id"]),
			int(enemy["stage"]),
			int(enemy["road_position"]),
			int(enemy["lane"]),
			int(enemy["hp"]),
			int(enemy["attack"]),
			int(enemy["defense"]),
			int(enemy["range"]),
			int(enemy["attack_period_ticks"]),
			bool(enemy["elite"])
		))
	return values


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
	var values: Array[Dictionary] = []
	for structure_data in _stage_config.get("structures", []):
		var structure := structure_data as Dictionary
		values.append(_structure(
			String(structure["structure_id"]),
			String(structure["display_name"]),
			String(structure["kind"]),
			int(structure["stage"]),
			int(structure["road_position"]),
			int(structure["lane"]),
			int(structure["max_hp"]),
			int(structure["defense"]),
			int(structure["attack"]),
			int(structure["attack_period_ticks"])
		))
	return values


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
		"gman_overrun",
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
	if archetype_id in ["gman", "rocket", "sonic", "parasite"]:
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

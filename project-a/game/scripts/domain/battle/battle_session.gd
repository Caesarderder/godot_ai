class_name BattleSession
extends RefCounted

const TICK_SECONDS := 0.2
const MAX_TICKS_PER_FRAME := 5
const MAX_BACKLOG_TICKS := 10

var tick_index: int = 0
var accumulator: float = 0.0
var paused: bool = false
var units: Array[BattleUnit] = []
var result: BattleResult
var presentation_events: Array:
	get: return _presentation_events.duplicate(true)

var _rng: DeterministicBattleRng
var _events: Array = []
var _presentation_events: Array = []


func _init(seed_value: int, initial_units: Array[BattleUnit]) -> void:
	_rng = DeterministicBattleRng.new(seed_value)
	for unit in initial_units:
		units.append(unit)


func set_paused(value: bool) -> void:
	paused = value
	if paused:
		accumulator = 0.0


func queue_key_presentation(kind: String) -> void:
	assert(kind in ["wave", "key_skill"])
	_enqueue_presentation({"tick": tick_index, "kind": kind, "critical": true})


func advance_frame(delta: float) -> int:
	if paused or result != null:
		return 0
	accumulator += maxf(delta, 0.0)
	var available := int(floor((accumulator + 0.000000001) / TICK_SECONDS))
	var count := mini(available, MAX_TICKS_PER_FRAME)
	var processed := 0
	for unused in count:
		if result != null:
			break
		_tick()
		processed += 1
	accumulator -= processed * TICK_SECONDS
	if accumulator < 0.000000001:
		accumulator = 0.0
	return processed


func _tick() -> void:
	tick_index += 1
	for unit in units:
		if unit.is_alive():
			unit.action_meter += unit.speed
	var ready: Array[BattleUnit] = []
	for unit in units:
		if unit.is_alive() and unit.action_meter >= BattleUnit.ACTION_THRESHOLD:
			ready.append(unit)
	ready.sort_custom(_acts_before)
	for actor in ready:
		if not actor.is_alive():
			continue
		actor.action_meter -= BattleUnit.ACTION_THRESHOLD
		var targets: Array[BattleUnit] = []
		for candidate in units:
			if candidate.is_alive() and candidate.team != actor.team:
				targets.append(candidate)
		if targets.is_empty():
			break
		targets.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
			if a.slot != b.slot:
				return a.slot < b.slot
			return a.unit_id < b.unit_id
		)
		var front_slot := targets[0].slot
		var tied: Array[BattleUnit] = []
		for target in targets:
			if target.slot == front_slot:
				tied.append(target)
		var target := tied[_rng.choose_index(tied.size())]
		target.hp = maxi(0, target.hp - actor.attack)
		_events.append([tick_index, actor.unit_id, target.unit_id, actor.attack, target.hp])
		_enqueue_presentation({"tick": tick_index, "kind": "normal_attack", "critical": false})
		if target.hp == 0:
			_enqueue_presentation({"tick": tick_index, "kind": "death", "critical": true})
	_finish_if_complete()
	_prune_presentation()


func _acts_before(a: BattleUnit, b: BattleUnit) -> bool:
	var a_overflow := a.action_meter - BattleUnit.ACTION_THRESHOLD
	var b_overflow := b.action_meter - BattleUnit.ACTION_THRESHOLD
	if a_overflow != b_overflow:
		return a_overflow > b_overflow
	if a.speed != b.speed:
		return a.speed > b.speed
	if a.slot != b.slot:
		return a.slot < b.slot
	return a.unit_id < b.unit_id


func _finish_if_complete() -> void:
	var alive_teams: Dictionary = {}
	for unit in units:
		if unit.is_alive():
			alive_teams[unit.team] = true
	if alive_teams.size() > 1:
		return
	var winner := -1 if alive_teams.is_empty() else int(alive_teams.keys()[0])
	var snapshots: Array = []
	for unit in units:
		snapshots.append(unit.snapshot())
	snapshots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["unit_id"] < b["unit_id"]
	)
	result = BattleResult.new(winner, tick_index, snapshots, _events, _rng.next_int(0, 9_999))
	_enqueue_presentation({"tick": tick_index, "kind": "result", "critical": true})


func _enqueue_presentation(event: Dictionary) -> void:
	_presentation_events.append(event)


func _prune_presentation() -> void:
	var minimum_tick := tick_index - MAX_BACKLOG_TICKS + 1
	var retained: Array = []
	for event in _presentation_events:
		if bool(event["critical"]) or int(event["tick"]) >= minimum_tick:
			retained.append(event)
	_presentation_events = retained

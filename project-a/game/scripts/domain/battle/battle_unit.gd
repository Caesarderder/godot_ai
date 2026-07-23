class_name BattleUnit
extends RefCounted

const ACTION_THRESHOLD := 100_000

var unit_id: String
var team: int
var slot: int
var speed: int
var hp: int
var attack: int
var action_meter: int = 0


func _init(
	id: String, unit_team: int, formation_slot: int, unit_speed: int, health: int, damage: int
) -> void:
	unit_id = id
	team = unit_team
	slot = formation_slot
	speed = unit_speed
	hp = health
	attack = damage


func is_alive() -> bool:
	return hp > 0


func snapshot() -> Dictionary:
	return {
		"action_meter": action_meter,
		"attack": attack,
		"hp": hp,
		"slot": slot,
		"speed": speed,
		"team": team,
		"unit_id": unit_id,
	}

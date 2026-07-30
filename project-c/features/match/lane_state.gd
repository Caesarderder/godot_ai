class_name LaneState
extends RefCounted

enum Outcome { RUNNING, VICTORY, DEFEAT }

var outcome := Outcome.RUNNING
var elapsed := 0.0
var time_limit := 45.0
var player_hp := 100.0
var enemy_hp := 100.0
var player_tower_hp := 180.0
var enemy_tower_hp := 180.0

func reset() -> void:
	outcome = Outcome.RUNNING
	elapsed = 0.0
	player_hp = 100.0
	enemy_hp = 100.0
	player_tower_hp = 180.0
	enemy_tower_hp = 180.0

func summary() -> Dictionary:
	return {"outcome": outcome, "elapsed": elapsed, "player_hp": player_hp, "enemy_tower_hp": enemy_tower_hp}

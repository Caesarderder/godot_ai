class_name FpsRunState
extends RefCounted

enum Outcome {
	RUNNING,
	VICTORY,
	DEFEAT,
}

var outcome: Outcome = Outcome.RUNNING
var total_enemies: int = 0
var enemies_remaining: int = 0
var shots_fired: int = 0
var hits: int = 0
var elapsed_seconds: float = 0.0


func reset(enemy_count: int) -> void:
	outcome = Outcome.RUNNING
	total_enemies = enemy_count
	enemies_remaining = enemy_count
	shots_fired = 0
	hits = 0
	elapsed_seconds = 0.0


func register_shot() -> void:
	if outcome == Outcome.RUNNING:
		shots_fired += 1


func register_hit() -> void:
	if outcome == Outcome.RUNNING:
		hits += 1


func register_enemy_down() -> bool:
	if outcome != Outcome.RUNNING:
		return false
	enemies_remaining = maxi(0, enemies_remaining - 1)
	if enemies_remaining == 0:
		outcome = Outcome.VICTORY
		return true
	return false


func register_defeat() -> bool:
	if outcome != Outcome.RUNNING:
		return false
	outcome = Outcome.DEFEAT
	return true


func accuracy_percent() -> int:
	if shots_fired <= 0:
		return 0
	return int(round(float(hits) / float(shots_fired) * 100.0))


func summary() -> Dictionary:
	return {
		"elapsed_seconds": elapsed_seconds,
		"shots_fired": shots_fired,
		"hits": hits,
		"accuracy_percent": accuracy_percent(),
		"enemies_down": total_enemies - enemies_remaining,
	}

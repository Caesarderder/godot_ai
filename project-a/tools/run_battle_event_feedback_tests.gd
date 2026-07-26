extends SceneTree

const BattleWorldScript := preload("res://game/scripts/presentation_3d/battle_world.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := BattleWorldScript.new()
	root.add_child(world)
	await process_frame
	var holder := {"events": [], "emissions": 0}
	world.battle_events_applied.connect(func(events: Array[Dictionary]) -> void:
		holder["events"] = events
		holder["emissions"] = int(holder["emissions"]) + 1
	)
	var source_events: Array[Dictionary] = [{
		"type": &"skill_used",
		"unit_id": &"hero_test",
		"skill_id": "siege_shield",
		"skill_tier": 2,
	}]
	world.call("_apply_events", source_events)
	var received := holder.get("events", []) as Array
	_check(received.size() == 1, "BattleWorld publishes accepted tick events once")
	if received.size() == 1:
		_check(String((received[0] as Dictionary).get("skill_id", "")) == "siege_shield", "published fact preserves the stable skill ID")
	source_events[0]["skill_id"] = "mutated_after_emit"
	if received.size() == 1:
		_check(
			String((received[0] as Dictionary).get("skill_id", "")) == "siege_shield",
			"published events are detached from the combat event array"
		)
	var ordinary_events: Array[Dictionary] = [{
		"type": &"attack_hit",
		"unit_id": &"enemy_test",
		"source_id": &"hero_test",
		"damage": 12,
		"is_skill": false,
	}]
	world.call("_apply_events", ordinary_events)
	_check(int(holder["emissions"]) == 1, "ordinary 5Hz combat ticks do not emit HUD skill facts")
	world.queue_free()
	await process_frame
	if failures.is_empty():
		print("BATTLE_EVENT_FEEDBACK_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

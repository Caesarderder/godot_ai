extends SceneTree

const BattleWorldScript := preload("res://game/scripts/presentation_3d/battle_world.gd")
const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

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
	await _check_real_skill_request_pipeline()
	if failures.is_empty():
		print("BATTLE_EVENT_FEEDBACK_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_real_skill_request_pipeline() -> void:
	var world := BattleWorldScript.new()
	root.add_child(world)
	await process_frame
	var holder := {"events": []}
	world.battle_events_applied.connect(func(events: Array[Dictionary]) -> void:
		holder["events"] = events
	)
	world.start_battle([{
		"hero_id": "real_skill_hero",
		"display_name": "真实技能测试",
		"archetype_id": "gman",
		"class_id": "commander",
		"skill_id": "gman_overrun",
		"starting_energy": 100,
		"attack": 24,
		"auto_skill": false,
	}])
	world.set_process(false)
	_check(world.request_skill(&"real_skill_hero"), "full-energy skill request is accepted through BattleWorld public API")
	world.call("_process", 0.2)
	var events := holder.get("events", []) as Array
	var has_skill_used := false
	var effective_damage := 0
	var skill_hit_count := 0
	for event_value in events:
		var event := event_value as Dictionary
		if StringName(event.get("type", &"")) == &"skill_used" and event.get("unit_id", &"") == &"real_skill_hero":
			has_skill_used = true
		if (
			StringName(event.get("type", &"")) in [&"structure_damaged", &"enemy_damaged"]
			and event.get("source_id", &"") == &"real_skill_hero"
		):
			effective_damage += int(event.get("effective_damage", 0))
			skill_hit_count += 1
	_check(has_skill_used, "accepted request emits the real deterministic skill_used fact")
	_check(skill_hit_count == 2, "G-Man overrun reaches both current-stage structures in the opening fixture")
	_check(effective_damage == 144, "three-times G-Man overrun produces deterministic opening-fixture damage")
	_check(int(StageCatalogScript.stage("stage_1_1").get("gman_opening_damage_bp", 0)) == 30000, "opening power fantasy is authored on stage 1-1")
	_check(not StageCatalogScript.stage("stage_1_2").has("gman_opening_damage_bp"), "ordinary stages do not inherit the tutorial burst")
	_check(BattleSessionScript.gman_overrun_damage_bp(0, 30000) == 30000, "authored opening battle can grant one visible G-Man burst")
	_check(BattleSessionScript.gman_overrun_damage_bp(0) == 20000, "ordinary battles keep the sustained G-Man multiplier")
	_check(BattleSessionScript.gman_overrun_damage_bp(1, 30000) == 20000, "repeat G-Man orders return to the sustained multiplier")
	var snapshot := world.snapshot()
	var hero := (snapshot.get("units", []) as Array)[0] as Dictionary
	_check(int(hero.get("energy", -1)) == 0, "accepted skill consumes authoritative energy in the post-skill snapshot")
	world.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

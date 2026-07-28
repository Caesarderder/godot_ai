extends SceneTree

const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")

var failures: Array[String] = []


func _init() -> void:
	_check_catalog()
	_check_counter_research()
	if failures.is_empty():
		print("CAMPAIGN_60_STAGE_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("CAMPAIGN_60_STAGE_TESTS_FAIL: %d" % failures.size())
	quit(1)


func _check_catalog() -> void:
	var ids := StageCatalogScript.all_stage_ids()
	_check(ids.size() == 60, "campaign owns exactly 60 stages")
	_check(_unique_count(ids) == 60, "all campaign stage ids are unique")
	_check(StageCatalogScript.next_stage_id("stage_1_12") == "stage_2_1", "chapter boundary is contiguous")
	_check(StageCatalogScript.next_stage_id("stage_5_12") == "endless_1", "final boss opens endless")
	for chapter in range(1, 6):
		var previous_power := 0
		for stage_number in range(1, 13):
			var stage_id := "stage_%d_%d" % [chapter, stage_number]
			var config := StageCatalogScript.stage(stage_id)
			_check(not config.is_empty(), "%s resolves" % stage_id)
			_check(String(config.get("display_name", "")).contains("%d-%d" % [chapter, stage_number]), "%s has coordinate display name" % stage_id)
			var power := int(config.get("recommended_power", 0))
			_check(power >= previous_power, "%s recommendation is monotonic" % stage_id)
			previous_power = power
			var expected_tier := (
				"boss" if stage_number == 12
				else ("elite" if stage_number in [3, 6, 9] else ("checkpoint" if stage_number % 3 == 2 else "normal"))
			)
			_check(String(config.get("encounter_tier", "")) == expected_tier, "%s tier follows 3-stage rhythm" % stage_id)
			if stage_number in [9, 12]:
				_check(not String(config.get("required_counter_tech", "")).is_empty(), "%s requires chapter counter tech" % stage_id)


func _check_counter_research() -> void:
	var state := GameStateScript.create_new(20260729, 1000, false)
	state.factory.materials["porcelain"] = 100
	state.stage_progress["cleared_stages"] = ["stage_1_8"]
	var executor := CommandExecutorScript.new(state, func(_candidate: RefCounted) -> bool: return true)
	var envelope := {
		"type": "research_counter_tech",
		"command_id": "counter-tech-test",
		"business_key": "counter-tech:counter.sunglasses",
		"expected_revision": state.revision,
		"payload": {"tech_id": "counter.sunglasses", "chapter": 1},
	}
	var result := executor.execute(envelope)
	_check(bool(result.get("ok", false)), "eligible sunglasses research succeeds")
	var current := executor.state
	_check(int(current.factory.materials["porcelain"]) == 82, "research deducts exact industrial cost")
	_check((current.receipt_ledgers["durable"] as Dictionary).has("counter_tech:counter.sunglasses"), "research writes durable ownership")
	var replay := executor.execute(envelope)
	_check(bool(replay.get("ok", false)), "exact command replay returns prior result")
	_check(int(executor.state.factory.materials["porcelain"]) == 82, "replay cannot double-charge")


func _unique_count(values: Array[String]) -> int:
	var seen: Dictionary = {}
	for value in values:
		seen[value] = true
	return seen.size()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

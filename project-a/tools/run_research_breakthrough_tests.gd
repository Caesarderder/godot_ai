extends SceneTree

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")

var failures: Array[String] = []
var serial: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: RefCounted = GameStateScript.create_new(20260727, 1000, false)
	var executor: RefCounted = CommandExecutorScript.new(
		state,
		func(_candidate: RefCounted) -> bool: return true
	)
	var locked := _command(executor, "claim_research_breakthrough", {})
	_check(not bool(locked.get("ok", false)), "breakthrough requires a built research lab")
	executor.state.factory.facilities["research_lab"] = 1
	executor.state.factory.facility_placements["research_lab"] = [2, 1]
	var pity_before := int(executor.state.meta_progression.recruit_a_pity)
	var result := _command(executor, "claim_research_breakthrough", {})
	_check(bool(result.get("ok", false)), "built lab unlocks the free breakthrough: %s" % str(result))
	var event := result.get("event", {}) as Dictionary
	var results := event.get("results", []) as Array
	_check(results.size() == 10, "breakthrough reveals exactly ten cards")
	_check(event.get("guaranteed_archetypes", []) == ["assault", "armored"], "ten-pull declares both deterministic reinforcements")
	_check(not bool(event.get("pity_advanced", true)), "onboarding celebration does not manipulate paid-pool pity")
	_check(int(executor.state.meta_progression.recruit_a_pity) == pity_before, "long-term A pity remains unchanged")
	_check(_hero_for(executor.state, "assault") != null, "assault reinforcement is permanent")
	_check(_hero_for(executor.state, "armored") != null, "armored reinforcement is permanent")
	_check(bool(executor.state.factory.blueprints.get("ordinary.assault", false)), "assault blueprint becomes durable")
	_check(bool(executor.state.factory.blueprints.get("heavy.armored", false)), "armored blueprint becomes durable")
	var duplicate := _command(executor, "claim_research_breakthrough", {})
	_check(not bool(duplicate.get("ok", false)), "a second business action cannot duplicate the reward")
	var replay: Dictionary = executor.execute({
		"command_id": String(result.get("command_id", "")),
		"type": "claim_research_breakthrough",
		"payload": {},
		"business_key": "research-breakthrough-test-2",
		"expected_revision": 0,
	})
	_check(bool(replay.get("ok", false)), "the original durable receipt replays safely")
	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(executor.state))
	_check(bool(decoded.get("ok", false)), "breakthrough state survives save roundtrip")
	if bool(decoded.get("ok", false)):
		_check(
			(decoded["state"].onboarding.get("claimed", {}) as Dictionary).has(
				"reward.research_breakthrough_ten"
			),
			"one-time claim marker persists"
		)
	_check(executor.state.validate().is_empty(), "breakthrough preserves game-state invariants")
	if failures.is_empty():
		print("RESEARCH_BREAKTHROUGH_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("RESEARCH_BREAKTHROUGH_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _command(executor: RefCounted, command_type: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return executor.execute({
		"command_id": "research-breakthrough-test-%d" % serial,
		"type": command_type,
		"payload": payload,
		"business_key": "research-breakthrough-test-%d" % serial,
		"expected_revision": executor.state.revision,
		"requested_at": 1000,
	})


func _hero_for(state: RefCounted, archetype_id: String) -> RefCounted:
	for hero in state.roster:
		if String(hero.archetype_id) == archetype_id:
			return hero
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

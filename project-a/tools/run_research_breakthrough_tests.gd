extends SceneTree

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const ResearchBreakthroughCatalogScript := preload(
	"res://game/scripts/content/research_breakthrough_catalog.gd"
)
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

var failures: Array[String] = []
var serial: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var content_errors := ResearchBreakthroughCatalogScript.validate_all()
	_check(
		content_errors.is_empty(),
		"typed foundational signal cards validate: %s" % ", ".join(content_errors)
	)
	_check(
		ResearchBreakthroughCatalogScript.material_grant()
			== {"porcelain": 0, "parts": 0, "sludge": 0},
		"foundational signal contains no industrial materials"
	)
	_check(
		ResearchBreakthroughCatalogScript.skill_chip_grant() == 0,
		"foundational signal contains no skill chips"
	)
	for recipe in FactoryCatalogScript.recipes():
		_check(
			String(recipe.get("rating", "")) in ["B", "A", "S"],
			"every toilet design uses only the B/A/S rating model"
		)
	var state: RefCounted = GameStateScript.create_new(20260727, 1000, false)
	var executor: RefCounted = CommandExecutorScript.new(
		state,
		func(_candidate: RefCounted) -> bool: return true
	)
	var retired_research_pull := _command(executor, "claim_research_breakthrough", {})
	_check(
		not bool(retired_research_pull.get("ok", false))
			and String(retired_research_pull.get("error", "")) == "UNKNOWN_COMMAND",
		"the retired research-lab ten-pull command is no longer reachable"
	)
	var locked := _command(executor, "claim_foundational_signal", {})
	_check(not bool(locked.get("ok", false)), "foundational signal requires the first-wall detection")
	executor.state.factory.eligible_facilities["research_lab"] = true
	var pity_before := int(executor.state.meta_progression.recruit_a_pity)
	var materials_before := (executor.state.factory.materials as Dictionary).duplicate(true)
	var skill_chips_before := int(executor.state.economy.skill_chips)
	var legion_data_before := int(executor.state.economy.hero_shards)
	var roster_before: int = executor.state.roster.size()
	var result := _command(executor, "claim_foundational_signal", {})
	_check(bool(result.get("ok", false)), "first-wall detection unlocks the free blueprint signal: %s" % str(result))
	var event := result.get("event", {}) as Dictionary
	var results := event.get("results", []) as Array
	_check(results.size() == 10, "foundational signal reveals exactly ten blueprint cards")
	_check(
		event.get("guaranteed_recipe_ids", []) == ["ordinary.assault", "heavy.armored"],
		"ten-pull declares both deterministic foundational designs"
	)
	_check(not bool(event.get("pity_advanced", true)), "onboarding signal does not manipulate long-term pity")
	_check(int(executor.state.meta_progression.recruit_a_pity) == pity_before, "long-term A pity remains unchanged")
	_check(executor.state.roster.size() == roster_before, "signal reception does not create permanent heroes")
	_check(bool(executor.state.factory.discovered_blueprints.get("ordinary.assault", false)), "assault design enters the research inventory")
	_check(bool(executor.state.factory.discovered_blueprints.get("heavy.armored", false)), "armored design enters the research inventory")
	_check(not bool(executor.state.factory.blueprints.get("ordinary.assault", false)), "assault remains unresearched after the signal")
	_check(
		executor.state.factory.materials == materials_before,
		"signal does not cross-subsidize the industrial-material ledger"
	)
	_check(
		int(executor.state.economy.skill_chips) == skill_chips_before,
		"signal does not grant a skill chip"
	)
	_check(
		int(executor.state.economy.hero_shards) == legion_data_before,
		"eight foundational fragments do not inject long-term legion data"
	)
	_check(
		executor.state.factory.blueprint_data.is_empty(),
		"foundational signal never writes the retired blueprint-data ledger"
	)
	var complete_designs := 0
	var design_fragments := 0
	for item_value in results:
		var item := item_value as Dictionary
		if String(item.get("kind", "")) == "blueprint":
			complete_designs += 1
		elif String(item.get("kind", "")) == "blueprint_fragment":
			design_fragments += 1
	_check(
		complete_designs == 2 and design_fragments == 8,
		"foundational signal resolves as two complete designs plus eight non-funding fragments"
	)
	var duplicate := _command(executor, "claim_foundational_signal", {})
	_check(not bool(duplicate.get("ok", false)), "a second business action cannot duplicate the reward")
	var replay: Dictionary = executor.execute({
		"command_id": String(result.get("command_id", "")),
		"type": "claim_foundational_signal",
		"payload": {},
		"business_key": String(result.get("command_id", "")),
		"expected_revision": 0,
	})
	_check(bool(replay.get("ok", false)), "the original durable receipt replays safely")
	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(executor.state))
	_check(bool(decoded.get("ok", false)), "breakthrough state survives save roundtrip")
	if bool(decoded.get("ok", false)):
		_check(
			(decoded["state"].onboarding.get("claimed", {}) as Dictionary).has(
				"reward.foundational_signal_ten"
			),
			"one-time claim marker persists"
		)
	_check(executor.state.validate().is_empty(), "breakthrough preserves game-state invariants")
	executor.state.factory.facilities["research_lab"] = 1
	executor.state.factory.facility_placements["research_lab"] = [2, 1]
	var start_assault := _command(executor, "unlock_foundational_blueprint", {
		"recipe_id": "ordinary.assault",
		"now_unix": 1000,
	})
	_check(bool(start_assault.get("ok", false)), "research lab starts the owned assault design")
	var claim_assault := _command(executor, "claim_blueprint_research", {"now_unix": 1045})
	_check(bool(claim_assault.get("ok", false)), "research completion creates the assault hero")
	_check(_hero_for(executor.state, "assault") != null, "assault becomes permanent only after research")
	var start_armored := _command(executor, "unlock_foundational_blueprint", {
		"recipe_id": "heavy.armored",
		"now_unix": 1045,
	})
	_check(bool(start_armored.get("ok", false)), "research lab starts the owned armored design")
	var claim_armored := _command(executor, "claim_blueprint_research", {"now_unix": 1090})
	_check(bool(claim_armored.get("ok", false)), "research completion creates the armored hero")
	_check(_hero_for(executor.state, "armored") != null, "armored becomes permanent only after research")
	_check(
		String(_hero_for(executor.state, "assault").aptitude_id) == "B"
			and String(_hero_for(executor.state, "armored").aptitude_id) == "A",
		"researched heroes inherit the canonical B/A ratings"
	)
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

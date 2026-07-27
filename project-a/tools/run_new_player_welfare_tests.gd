extends SceneTree

const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")
const NewPlayerWelfareServiceScript := preload("res://game/scripts/domain/meta/new_player_welfare_service.gd")
const OnboardingCatalogScript := preload("res://game/scripts/domain/onboarding/onboarding_catalog.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")

var failures: Array[String] = []
var save_calls: int = 0


func _init() -> void:
	_run()
	if failures.is_empty():
		print("NEW PLAYER WELFARE TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("NEW PLAYER WELFARE TESTS FAIL: %d issue(s)" % failures.size())
	quit(1)


func _run() -> void:
	_test_claim_open_and_core_contract()
	_test_save_failure_is_atomic()


func _test_claim_open_and_core_contract() -> void:
	var state: RefCounted = GameStateScript.create_new(20260727, 1000, false)
	var executor := CommandExecutorScript.new(state, Callable(self, "_save_success"))
	var locked := _execute(executor, "welfare-locked", "claim_new_player_welfare", {}, "welfare-locked")
	_eq(locked.get("error", ""), "NEW_PLAYER_WELFARE_LOCKED", "welfare stays locked before clearing 1-5")
	state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
	]
	state.onboarding["active_index"] = OnboardingCatalogScript.count()
	var economy_before: Dictionary = state.economy.to_dict()
	var materials_before: Dictionary = state.factory.materials.duplicate(true)
	var first := _execute(
		executor,
		"welfare-claim",
		"claim_new_player_welfare",
		{},
		"new-player-welfare:claim:v1"
	)
	_ok(bool(first.get("ok", false)), "post-chapter welfare claim succeeds")
	state = executor.state
	_eq(state.economy.to_dict(), economy_before, "claim grants no ordinary economy resources")
	_eq(state.factory.materials, materials_before, "claim grants no factory materials directly")
	_eq(
		NewPlayerWelfareServiceScript.item_balance(state, NewPlayerWelfareServiceScript.STAR_CORE_ITEM_ID),
		1,
		"claim grants one contraband star core"
	)
	_eq(
		NewPlayerWelfareServiceScript.item_balance(state, NewPlayerWelfareServiceScript.LOGISTICS_CASE_ITEM_ID),
		1,
		"claim grants one smuggled logistics case"
	)
	var revision_after_claim := int(state.revision)
	var replay := executor.execute({
		"command_id": "welfare-claim",
		"type": "claim_new_player_welfare",
		"payload": {},
		"business_key": "new-player-welfare:claim:v1",
		"expected_revision": 0,
	})
	_ok(bool(replay.get("ok", false)), "same command envelope replays the persisted receipt")
	_eq(state.revision, revision_after_claim, "receipt replay does not advance revision")
	var duplicate := _execute(
		executor,
		"welfare-claim-duplicate",
		"claim_new_player_welfare",
		{},
		"new-player-welfare:claim:other"
	)
	_eq(
		duplicate.get("error", ""),
		"NEW_PLAYER_WELFARE_ALREADY_CLAIMED",
		"fixed durable ledger rejects a second claim with new ids"
	)
	var opened := _execute(
		executor,
		"welfare-case",
		"open_smuggled_logistics_case",
		{},
		"new-player-welfare:logistics-case:v1"
	)
	_ok(bool(opened.get("ok", false)), "claimed logistics case opens")
	state = executor.state
	for material_id in NewPlayerWelfareServiceScript.LOGISTICS_CASE_REWARD:
		_eq(
			int(state.factory.materials[material_id]),
			int(materials_before[material_id]) + int(NewPlayerWelfareServiceScript.LOGISTICS_CASE_REWARD[material_id]),
			"logistics case grants fixed %s amount" % material_id
		)
	_eq(
		NewPlayerWelfareServiceScript.item_balance(state, NewPlayerWelfareServiceScript.LOGISTICS_CASE_ITEM_ID),
		0,
		"opening consumes the logistics case"
	)
	var hero: RefCounted = HeroGeneratorScript.generate_archetype(20260727, 2, "armored", "guardian")
	state.roster.append(hero)
	state.meta_progression.hero_fragments["armored"] = 0
	state.factory.materials = {"porcelain": 0, "parts": 0, "sludge": 0}
	var normal_quote := LogisticsServiceScript.star_upgrade_quote(state, String(hero.hero_id))
	var welfare_quote := LogisticsServiceScript.star_upgrade_quote(state, String(hero.hero_id), true)
	_eq(normal_quote.get("error", ""), "NOT_ENOUGH_HERO_FRAGMENTS", "normal quote requires matching character fragments")
	_ok(bool(welfare_quote.get("ok", false)), "welfare quote replaces only the matching-fragment gate")
	_eq(
		(welfare_quote.get("cost", {}) as Dictionary).get("hero_fragments", -1),
		0,
		"welfare quote charges no character fragments"
	)
	_eq(
		(welfare_quote.get("waived_cost", {}) as Dictionary),
		{"hero_fragments": 30},
		"welfare quote marks the exact A-rarity fragment cost as replaced"
	)
	var materials_before_core: Dictionary = state.factory.materials.duplicate(true)
	var core_result := _execute(
		executor,
		"welfare-core",
		"use_welfare_star_core",
		{"hero_id": hero.hero_id},
		"new-player-welfare:star-core:%s" % hero.hero_id
	)
	_ok(bool(core_result.get("ok", false)), "core upgrades an eligible one-star hero")
	state = executor.state
	hero = state.hero_by_id(String(hero.hero_id))
	_eq(hero.star, 2, "core upgrades exactly from one star to two stars")
	_eq(int(state.meta_progression.hero_fragments.get("armored", 0)), 0, "core does not require character fragments")
	_eq(state.factory.materials, materials_before_core, "star growth never spends industrial materials")
	var event := core_result.get("event", {}) as Dictionary
	_eq(event.get("source", ""), "new_player_welfare", "core event exposes its welfare source")
	_eq(
		(event.get("cost", {}) as Dictionary).get("hero_fragments", -1),
		0,
		"core event records zero charged character fragments"
	)
	_eq(
		(event.get("waived_cost", {}) as Dictionary),
		{"hero_fragments": 30},
		"core event exposes the exact replaced A-rarity fragment cost"
	)
	_eq(
		NewPlayerWelfareServiceScript.item_balance(state, NewPlayerWelfareServiceScript.STAR_CORE_ITEM_ID),
		0,
		"successful core use consumes exactly one core"
	)
	var no_core := _execute(
		executor,
		"welfare-core-again",
		"use_welfare_star_core",
		{"hero_id": state.roster[0].hero_id},
		"new-player-welfare:star-core:again"
	)
	_eq(no_core.get("error", ""), "NO_CONTRABAND_STAR_CORE", "spent core cannot be reused")
	var decoded := SaveCodecScript.decode(SaveCodecScript.encode(state))
	_ok(bool(decoded.get("ok", false)), "welfare state roundtrips through strict save codec")
	if bool(decoded.get("ok", false)):
		var restored: RefCounted = decoded["state"]
		var welfare := NewPlayerWelfareServiceScript.snapshot(restored)
		_ok(bool(welfare.get("claimed", false)), "save/load preserves exact-once claim receipt")
		_ok(bool(welfare.get("case_opened", false)), "save/load preserves opened-case receipt")
		_eq(int(welfare.get("star_core_count", -1)), 0, "save/load preserves consumed core balance")


func _test_save_failure_is_atomic() -> void:
	var state: RefCounted = GameStateScript.create_new(20260728, 1000, false)
	state.stage_progress["cleared_stages"] = ["stage_1_5"]
	var executor := CommandExecutorScript.new(state, Callable(self, "_save_failure"))
	var result := _execute(
		executor,
		"welfare-save-fail",
		"claim_new_player_welfare",
		{},
		"new-player-welfare:claim:v1"
	)
	_eq(result.get("error", ""), "SAVE_FAILED", "failed persistence rejects welfare claim")
	_eq(
		NewPlayerWelfareServiceScript.item_balance(executor.state, NewPlayerWelfareServiceScript.STAR_CORE_ITEM_ID),
		0,
		"failed persistence does not publish granted core"
	)
	_ok(
		not (executor.state.receipt_ledgers["durable"] as Dictionary).has(
			NewPlayerWelfareServiceScript.CLAIM_LEDGER_KEY
		),
		"failed persistence does not publish durable claim receipt"
	)


func _execute(
	executor: RefCounted,
	command_id: String,
	command_type: String,
	payload: Dictionary,
	business_key: String
) -> Dictionary:
	return executor.execute({
		"command_id": command_id,
		"type": command_type,
		"payload": payload,
		"business_key": business_key,
		"expected_revision": int(executor.state.revision),
	})


func _save_success(_state: RefCounted) -> bool:
	save_calls += 1
	return true


func _save_failure(_state: RefCounted) -> bool:
	return false


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

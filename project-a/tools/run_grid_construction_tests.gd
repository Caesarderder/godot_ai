extends SceneTree

const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")
const FactoryServiceScript := preload("res://game/scripts/domain/factory/factory_service.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")

var failures := 0


func _initialize() -> void:
	for facility_id in LogisticsServiceScript.FACILITY_BUILD_SECONDS:
		_expect(
			int(LogisticsServiceScript.FACILITY_BUILD_SECONDS[facility_id]) == 5,
			"%s uses the five-second early construction contract" % facility_id
		)
	var state: RefCounted = GameStateScript.create_new(71, 1000, false)
	state.economy.toilet_coins = 10000
	_expect(not bool(LogisticsServiceScript.construct_facility(
		state, "porcelain_plant", 1000, 3, 0
	).get("ok", false)), "out-of-bounds placement is rejected")
	_expect(not bool(LogisticsServiceScript.construct_facility(
		state, "porcelain_plant", 1000, 0, -1
	).get("ok", false)), "occupied placement is rejected")
	var result := LogisticsServiceScript.construct_facility(state, "porcelain_plant", 1000, -1, 0)
	_expect(bool(result.get("ok", false)), "empty placement starts facility construction")
	_expect(int(state.factory.facilities["porcelain_plant"]) == 0, "construction does not complete immediately")
	_expect(state.factory.facility_placements.get("porcelain_plant", []) == [], "placement is not committed before completion")
	_expect(
		int((result.get("event", {}) as Dictionary).get("duration_seconds", 0)) == 5,
		"early facility construction advertises the five-second contract"
	)
	_expect(not bool(LogisticsServiceScript.claim_facility_work(state, 1004).get("ok", false)), "construction cannot be claimed before five seconds")
	var completed := LogisticsServiceScript.claim_facility_work(state, 1005)
	_expect(bool(completed.get("ok", false)), "construction can be claimed at its completion time")
	_expect(int(state.factory.facilities["porcelain_plant"]) == 1, "claiming completed work activates level one")
	_expect(state.factory.facility_placements.get("porcelain_plant", []) == [-1, 0], "completed placement is authoritative state")
	var commissioning := LogisticsServiceScript.facility_output_preview(state, "porcelain_plant", 1005)
	_expect(int(commissioning.get("amount", 0)) == 3, "new producer exposes one minute of commissioning output without a wait gate")
	var collected := LogisticsServiceScript.claim_facility_output(state, "porcelain_plant", 1005)
	_expect(bool(collected.get("ok", false)), "commissioning output can be collected immediately")
	_expect(
		int(((collected.get("event", {}) as Dictionary).get("materials", {}) as Dictionary).get("porcelain", 0)) == 3,
		"commissioning collection grants the authoritative L1 industrial-material rate"
	)
	state.factory.facilities["repair_center"] = 0
	state.factory.facility_work = {
		"work_type": "construction",
		"facility_id": "repair_center",
		"started_at_unix": 2000,
		"completes_at_unix": 2060,
		"target_level": 1,
		"grid_x": 1,
		"grid_z": 0,
	}
	_expect(
		not bool(LogisticsServiceScript.claim_facility_work(state, 2004).get("ok", false)),
		"legacy long construction still requires the first five seconds"
	)
	_expect(
		bool(LogisticsServiceScript.claim_facility_work(state, 2005).get("ok", false)),
		"legacy in-progress construction adopts the five-second completion contract"
	)
	_expect(
		LogisticsServiceScript.facility_work_completes_at({
			"work_type": "upgrade",
			"started_at_unix": 3000,
			"completes_at_unix": 3060,
		}) == 3005,
		"legacy facility upgrades adopt the five-second debug contract"
	)
	var decoded := SaveCodecScript.decode(state.to_dict())
	_expect(bool(decoded.get("ok", false)), "placement survives strict save decoding")
	if bool(decoded.get("ok", false)):
		_expect(decoded["state"].factory.facility_placements.get("porcelain_plant", []) == [-1, 0], "placement survives save round-trip")
	var mint_state: RefCounted = GameStateScript.create_new(72, 4000, false)
	mint_state.factory.materials["porcelain"] = 100
	_expect(
			FactoryServiceScript.apply_battle_unlocks(mint_state, "victory", 1, "stage_2_11").is_empty(),
		"coin mint does not unlock before the chapter-two boss"
	)
	_expect(
		not bool(LogisticsServiceScript.construct_facility(mint_state, "coin_mint", 4000, 1, 0).get("ok", false)),
		"coin mint stays locked before the chapter-two boss"
	)
	var mint_unlocks := FactoryServiceScript.apply_battle_unlocks(mint_state, "victory", 1, "stage_2_12")
	_expect(mint_unlocks == ["coin_mint"], "first 2-12 victory unlocks the coin mint")
	_expect(
		FactoryServiceScript.apply_battle_unlocks(mint_state, "victory", 2, "stage_2_12").is_empty(),
		"coin mint unlock is exact-once"
	)
	var mint_build := LogisticsServiceScript.construct_facility(mint_state, "coin_mint", 4000, 1, 0)
	_expect(bool(mint_build.get("ok", false)), "eligible coin mint starts real grid construction")
	_expect(int(mint_state.factory.materials["porcelain"]) == 40, "coin mint spends 60 industrial materials")
	_expect(bool(LogisticsServiceScript.claim_facility_work(mint_state, 4005).get("ok", false)), "coin mint completes after five seconds")
	var coins_before := int(mint_state.economy.toilet_coins)
	_expect(int(LogisticsServiceScript.facility_output_preview(mint_state, "coin_mint", 4124).get("amount", 0)) == 0, "coin mint does not round partial production upward")
	var mint_preview := LogisticsServiceScript.facility_output_preview(mint_state, "coin_mint", 4125)
	_expect(int(mint_preview.get("amount", 0)) == 1, "level-one coin mint produces 30 coins per hour")
	var mint_claim := LogisticsServiceScript.claim_facility_output(mint_state, "coin_mint", 4125)
	_expect(bool(mint_claim.get("ok", false)), "coin mint output can be claimed")
	_expect(int(mint_state.economy.toilet_coins) == coins_before + 1, "coin mint credits the authoritative coin ledger")
	mint_state.factory.facility_output_anchors["coin_mint"] = 5000
	_expect(
		int(LogisticsServiceScript.facility_output_preview(mint_state, "coin_mint", 5000 + 24 * 60 * 60).get("amount", 0)) == 360,
		"coin mint offline output is capped at twelve hours"
	)
	mint_state.factory.facility_output_anchors["coin_mint"] = 6000
	var all_claim_coins_before := int(mint_state.economy.toilet_coins)
	var all_claim := LogisticsServiceScript.claim_output(mint_state, 6120)
	_expect(bool(all_claim.get("ok", false)), "global factory collection includes the coin mint")
	_expect(int(mint_state.economy.toilet_coins) == all_claim_coins_before + 1, "global collection credits minted coins")
	var mint_decoded := SaveCodecScript.decode(mint_state.to_dict())
	_expect(bool(mint_decoded.get("ok", false)), "coin mint survives strict save decoding")
	if bool(mint_decoded.get("ok", false)):
		_expect(int(mint_decoded["state"].factory.facilities.get("coin_mint", 0)) == 1, "coin mint level survives save round-trip")
	if failures == 0:
		print("GRID CONSTRUCTION TESTS PASS")
		quit(0)
	else:
		push_error("GRID CONSTRUCTION TESTS FAIL: %d failure(s)" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

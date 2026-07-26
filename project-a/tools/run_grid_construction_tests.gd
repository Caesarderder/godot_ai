extends SceneTree

const FactoryStateScript := preload("res://game/scripts/state/factory_state.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")

var failures := 0


func _initialize() -> void:
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
	_expect(not bool(LogisticsServiceScript.claim_facility_work(state, 1029).get("ok", false)), "construction cannot be claimed early")
	var completed := LogisticsServiceScript.claim_facility_work(state, 1030)
	_expect(bool(completed.get("ok", false)), "construction can be claimed at its completion time")
	_expect(int(state.factory.facilities["porcelain_plant"]) == 1, "claiming completed work activates level one")
	_expect(state.factory.facility_placements.get("porcelain_plant", []) == [-1, 0], "completed placement is authoritative state")
	var decoded := SaveCodecScript.decode(state.to_dict())
	_expect(bool(decoded.get("ok", false)), "placement survives strict save decoding")
	if bool(decoded.get("ok", false)):
		_expect(decoded["state"].factory.facility_placements.get("porcelain_plant", []) == [-1, 0], "placement survives save round-trip")
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

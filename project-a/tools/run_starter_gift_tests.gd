extends SceneTree

const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const StarterGiftServiceScript := preload("res://game/scripts/domain/meta/starter_gift_service.gd")

var failures: Array[String] = []


func _init() -> void:
	var state: RefCounted = GameStateScript.create_new(20260728, 1000, false)
	var executor := CommandExecutorScript.new(state, func(_state: RefCounted) -> bool: return true)
	_eq(state.economy.toilet_coins, 20, "opening coins are deliberately scarce")
	_eq(state.factory.materials.get("porcelain", -1), 30, "opening materials equal one research lab")
	var locked := _command(executor, "claim_starter_gift", {"gift_id": "rookie_departure_v1"}, "locked")
	_eq(locked.get("error", ""), "STARTER_GIFT_LOCKED", "gift cannot be claimed before its milestone")
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	var first := _command(executor, "claim_starter_gift", {"gift_id": "rookie_departure_v1"}, "first")
	_ok(bool(first.get("ok", false)), "research milestone unlocks newcomer gift")
	_eq(executor.state.economy.toilet_coins, 50, "newcomer gift grants its exact coin amount")
	var duplicate := _command(executor, "claim_starter_gift", {"gift_id": "rookie_departure_v1"}, "duplicate")
	_eq(duplicate.get("error", ""), "STARTER_GIFT_ALREADY_CLAIMED", "gift durable ledger rejects duplicate claims")
	executor.state.stage_progress["cleared_stages"] = ["stage_1_3"]
	var second := _command(executor, "claim_starter_gift", {"gift_id": "new_game_supply_v1"}, "second")
	_ok(bool(second.get("ok", false)), "1-3 milestone unlocks new-game supply")
	_eq(executor.state.economy.toilet_coins, 100, "second gift grants its exact coin amount")
	_eq(executor.state.factory.materials.get("porcelain", -1), 60, "second gift grants its exact material amount")
	var unknown := _command(executor, "claim_starter_gift", {"gift_id": "unknown"}, "unknown")
	_eq(unknown.get("error", ""), "STARTER_GIFT_NOT_FOUND", "unknown gift ids are rejected")
	var decoded := SaveCodecScript.decode(SaveCodecScript.encode(executor.state))
	_ok(bool(decoded.get("ok", false)), "gift receipts survive strict save codec")
	if bool(decoded.get("ok", false)):
		var snapshot := StarterGiftServiceScript.snapshot(decoded["state"])
		_eq(snapshot.get("claimable_count", -1), 0, "restored gifts stay claimed")
	if failures.is_empty():
		print("STARTER_GIFT_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("STARTER_GIFT_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _command(executor: RefCounted, type: String, payload: Dictionary, suffix: String) -> Dictionary:
	return executor.execute({
		"command_id": "starter-gift-%s" % suffix,
		"type": type,
		"payload": payload,
		"business_key": "starter-gift-test:%s" % suffix,
		"expected_revision": int(executor.state.revision),
	})


func _ok(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])

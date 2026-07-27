class_name StarterGiftService
extends RefCounted

const GIFT_DEFINITIONS: Array[Dictionary] = [
	{
		"gift_id": "rookie_departure_v1",
		"title": "新手启程礼包",
		"unlock_kind": "facility",
		"unlock_id": "research_lab",
		"unlock_copy": "研究所落成后解锁",
		"reward": {"toilet_coins": 30},
		"reward_copy": "金币 ×30",
		"reason_copy": "第一座设施落成奖励",
	},
	{
		"gift_id": "new_game_supply_v1",
		"title": "新游补给礼包",
		"unlock_kind": "stage",
		"unlock_id": "stage_1_3",
		"unlock_copy": "首次通关 1-3 后解锁",
		"reward": {"toilet_coins": 50, "porcelain": 30},
		"reward_copy": "金币 ×50 · 工业材料 ×30",
		"reason_copy": "下一座工业设施启动资金",
	},
]


static func snapshot(state: RefCounted) -> Dictionary:
	var gifts: Array[Dictionary] = []
	var claimable_count := 0
	for definition in GIFT_DEFINITIONS:
		var gift_id := String(definition["gift_id"])
		var unlocked := state != null and _is_unlocked(state, definition)
		var claimed := state != null and _durable_ledger(state).has(_ledger_key(gift_id))
		var claimable := unlocked and not claimed
		if claimable:
			claimable_count += 1
		gifts.append({
			"gift_id": gift_id,
			"title": String(definition["title"]),
			"unlock_copy": String(definition["unlock_copy"]),
			"reward_copy": String(definition["reward_copy"]),
			"reason_copy": String(definition["reason_copy"]),
			"unlocked": unlocked,
			"claimed": claimed,
			"claimable": claimable,
		})
	return {"gifts": gifts, "claimable_count": claimable_count}


static func claim(state: RefCounted, gift_id: String) -> Dictionary:
	var definition := _definition(gift_id)
	if definition.is_empty():
		return {"ok": false, "error": "STARTER_GIFT_NOT_FOUND"}
	if not _is_unlocked(state, definition):
		return {"ok": false, "error": "STARTER_GIFT_LOCKED"}
	var ledger := _durable_ledger(state)
	var ledger_key := _ledger_key(gift_id)
	if ledger.has(ledger_key):
		return {"ok": false, "error": "STARTER_GIFT_ALREADY_CLAIMED"}
	var reward := (definition["reward"] as Dictionary).duplicate(true)
	if reward.has("toilet_coins"):
		state.economy.grant({"toilet_coins": int(reward["toilet_coins"])})
	if reward.has("porcelain"):
		state.factory.grant({"porcelain": int(reward["porcelain"])})
	var event := {
		"type": "starter_gift_claimed",
		"source": "starter_gift",
		"gift_id": gift_id,
		"reward": reward,
	}
	ledger[ledger_key] = {
		"kind": "starter_gift_claim",
		"event": event.duplicate(true),
	}
	return {"ok": true, "event": event}


static func business_key(gift_id: String) -> String:
	return _ledger_key(gift_id)


static func _definition(gift_id: String) -> Dictionary:
	for definition in GIFT_DEFINITIONS:
		if String(definition["gift_id"]) == gift_id:
			return definition
	return {}


static func _is_unlocked(state: RefCounted, definition: Dictionary) -> bool:
	match String(definition["unlock_kind"]):
		"facility":
			return int(state.factory.facilities.get(String(definition["unlock_id"]), 0)) > 0
		"stage":
			return (state.stage_progress.get("cleared_stages", []) as Array).has(
				String(definition["unlock_id"])
			)
	return false


static func _ledger_key(gift_id: String) -> String:
	return "starter-gift:%s" % gift_id


static func _durable_ledger(state: RefCounted) -> Dictionary:
	if not state.receipt_ledgers.has("durable") or typeof(state.receipt_ledgers["durable"]) != TYPE_DICTIONARY:
		state.receipt_ledgers["durable"] = {}
	return state.receipt_ledgers["durable"] as Dictionary

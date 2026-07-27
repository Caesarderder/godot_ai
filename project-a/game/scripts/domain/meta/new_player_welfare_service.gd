class_name NewPlayerWelfareService
extends RefCounted

const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")

const REQUIRED_STAGE_ID: String = "stage_1_5"
const CLAIM_LEDGER_KEY: String = "new-player-welfare:claim:v1"
const CASE_LEDGER_KEY: String = "new-player-welfare:logistics-case:v1"
const STAR_CORE_ITEM_ID: String = "contraband_star_core"
const LOGISTICS_CASE_ITEM_ID: String = "smuggled_logistics_case"
const LOGISTICS_CASE_REWARD: Dictionary = {
	"porcelain": 25,
}


static func snapshot(state: RefCounted) -> Dictionary:
	if state == null:
		return {
			"unlocked": false,
			"claimable": false,
			"claimed": false,
			"case_openable": false,
			"case_opened": false,
			"star_core_count": 0,
			"logistics_case_count": 0,
		}
	var unlocked := _chapter_one_cleared(state)
	var durable := _durable_ledger(state)
	var claimed := durable.has(CLAIM_LEDGER_KEY)
	var case_opened := durable.has(CASE_LEDGER_KEY)
	var star_core_count := item_balance(state, STAR_CORE_ITEM_ID)
	var logistics_case_count := item_balance(state, LOGISTICS_CASE_ITEM_ID)
	return {
		"unlocked": unlocked,
		"claimable": unlocked and not claimed,
		"claimed": claimed,
		"case_openable": unlocked and claimed and logistics_case_count > 0 and not case_opened,
		"case_opened": case_opened,
		"star_core_count": star_core_count,
		"logistics_case_count": logistics_case_count,
		"case_reward": LOGISTICS_CASE_REWARD.duplicate(true),
	}


static func claim(state: RefCounted) -> Dictionary:
	if not _chapter_one_cleared(state):
		return {"ok": false, "error": "NEW_PLAYER_WELFARE_LOCKED"}
	var durable := _durable_ledger(state)
	if durable.has(CLAIM_LEDGER_KEY):
		return {"ok": false, "error": "NEW_PLAYER_WELFARE_ALREADY_CLAIMED"}
	_add_item(state, STAR_CORE_ITEM_ID, 1)
	_add_item(state, LOGISTICS_CASE_ITEM_ID, 1)
	var event := {
		"type": "new_player_welfare_claimed",
		"source": "new_player_welfare",
		"gift_id": "black_market_aid_v1",
		"items": {
			STAR_CORE_ITEM_ID: 1,
			LOGISTICS_CASE_ITEM_ID: 1,
		},
	}
	durable[CLAIM_LEDGER_KEY] = {
		"kind": "new_player_welfare_claim",
		"event": event.duplicate(true),
	}
	return {"ok": true, "event": event}


static func open_logistics_case(state: RefCounted) -> Dictionary:
	if not _chapter_one_cleared(state):
		return {"ok": false, "error": "NEW_PLAYER_WELFARE_LOCKED"}
	var durable := _durable_ledger(state)
	if not durable.has(CLAIM_LEDGER_KEY):
		return {"ok": false, "error": "NEW_PLAYER_WELFARE_NOT_CLAIMED"}
	if durable.has(CASE_LEDGER_KEY):
		return {"ok": false, "error": "SMUGGLED_LOGISTICS_CASE_ALREADY_OPENED"}
	if item_balance(state, LOGISTICS_CASE_ITEM_ID) < 1:
		return {"ok": false, "error": "NO_SMUGGLED_LOGISTICS_CASE"}
	for material_id in LOGISTICS_CASE_REWARD:
		if (
			int(state.factory.materials.get(material_id, 0))
			+ int(LOGISTICS_CASE_REWARD[material_id])
			> int(state.factory.capacities.get(material_id, 0))
		):
			return {"ok": false, "error": "SMUGGLED_LOGISTICS_CASE_STORAGE_FULL"}
	_add_item(state, LOGISTICS_CASE_ITEM_ID, -1)
	state.factory.grant(LOGISTICS_CASE_REWARD)
	var event := {
		"type": "smuggled_logistics_case_opened",
		"source": "new_player_welfare",
		"item_id": LOGISTICS_CASE_ITEM_ID,
		"materials": LOGISTICS_CASE_REWARD.duplicate(true),
	}
	durable[CASE_LEDGER_KEY] = {
		"kind": "smuggled_logistics_case_opened",
		"event": event.duplicate(true),
	}
	return {"ok": true, "event": event}


static func use_star_core(state: RefCounted, hero_id: String) -> Dictionary:
	if not _chapter_one_cleared(state):
		return {"ok": false, "error": "NEW_PLAYER_WELFARE_LOCKED"}
	if not _durable_ledger(state).has(CLAIM_LEDGER_KEY):
		return {"ok": false, "error": "NEW_PLAYER_WELFARE_NOT_CLAIMED"}
	if item_balance(state, STAR_CORE_ITEM_ID) < 1:
		return {"ok": false, "error": "NO_CONTRABAND_STAR_CORE"}
	var hero: RefCounted = state.hero_by_id(hero_id)
	if hero == null:
		return {"ok": false, "error": "HERO_NOT_FOUND"}
	if int(hero.star) != 1:
		return {"ok": false, "error": "CONTRABAND_CORE_REQUIRES_ONE_STAR"}
	var result := LogisticsServiceScript.upgrade_star_with_core(state, hero_id)
	if not bool(result.get("ok", false)):
		return result
	_add_item(state, STAR_CORE_ITEM_ID, -1)
	var event := result.get("event", {}) as Dictionary
	event["source"] = "new_player_welfare"
	event["item_id"] = STAR_CORE_ITEM_ID
	event["item_balance_after"] = item_balance(state, STAR_CORE_ITEM_ID)
	return {"ok": true, "event": event}


static func item_balance(state: RefCounted, item_id: String) -> int:
	_ensure_inventory(state)
	return int((state.inventory["items"] as Dictionary).get(item_id, 0))


static func _add_item(state: RefCounted, item_id: String, amount: int) -> void:
	_ensure_inventory(state)
	var items := state.inventory["items"] as Dictionary
	items[item_id] = maxi(0, int(items.get(item_id, 0)) + amount)


static func _chapter_one_cleared(state: RefCounted) -> bool:
	return (state.stage_progress.get("cleared_stages", []) as Array).has(REQUIRED_STAGE_ID)


static func _ensure_inventory(state: RefCounted) -> void:
	if not state.inventory.has("items") or typeof(state.inventory["items"]) != TYPE_DICTIONARY:
		state.inventory["items"] = {}


static func _durable_ledger(state: RefCounted) -> Dictionary:
	if not state.receipt_ledgers.has("durable") or typeof(state.receipt_ledgers["durable"]) != TYPE_DICTIONARY:
		state.receipt_ledgers["durable"] = {}
	return state.receipt_ledgers["durable"] as Dictionary

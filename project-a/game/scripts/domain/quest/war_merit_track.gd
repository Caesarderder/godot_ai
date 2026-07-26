class_name WarMeritTrack
extends RefCounted

const QuestCatalogScript := preload("res://game/scripts/domain/quest/quest_catalog.gd")

const CLAIMED_KEY: String = "war_merit_claimed_levels"


static func reward_for_level(level: int) -> Dictionary:
	if level < 1 or level > QuestCatalogScript.MAX_RANK:
		return {}
	var reward := {
		"toilet_coins": 10 + int((level - 1) / 5) * 5,
		"toilet_gems": 5 if level % 5 == 0 else 0,
		"porcelain": 5 if level % 3 == 0 else 0,
		"parts": 3 if level % 3 == 0 else 0,
		"sludge": 3 if level % 3 == 0 else 0,
	}
	if level % 10 == 0:
		reward["toilet_coins"] = int(reward["toilet_coins"]) + 40
	return reward


static func reached_level(state: RefCounted) -> int:
	var items := state.inventory.get("items", {}) as Dictionary
	return QuestCatalogScript.rank_for_merit(int(items.get(QuestCatalogScript.WAR_MERIT_ITEM_ID, 0)))


static func claimed_levels(state: RefCounted) -> Dictionary:
	var claimed_bucket := state.quests.get("claimed", {}) as Dictionary
	var value := claimed_bucket.get(CLAIMED_KEY, {}) as Dictionary
	return value if value != null else {}


static func is_claimed(state: RefCounted, level: int) -> bool:
	return claimed_levels(state).has(str(level))


static func claimable_count(state: RefCounted) -> int:
	var count := 0
	var reached := reached_level(state)
	for level in range(1, reached + 1):
		if not is_claimed(state, level):
			count += 1
	return count


static func claim_reward(state: RefCounted, request_id: String, level: int) -> Dictionary:
	if request_id.is_empty():
		return {"ok": false, "error": "MERIT_REQUEST_ID_REQUIRED"}
	var reward := reward_for_level(level)
	if reward.is_empty():
		return {"ok": false, "error": "MERIT_LEVEL_INVALID"}
	if reached_level(state) < level:
		return {"ok": false, "error": "MERIT_LEVEL_NOT_REACHED"}
	var ledger := state.receipt_ledgers.get("durable", {}) as Dictionary
	var ledger_key := "war_merit_reward:%s" % request_id
	var fingerprint := "%s|%d" % [request_id, level]
	if ledger.has(ledger_key):
		var old := ledger[ledger_key] as Dictionary
		if String(old.get("fingerprint", "")) != fingerprint:
			return {"ok": false, "error": "MERIT_REQUEST_ID_REUSE_MISMATCH"}
		return {"ok": true, "event": (old.get("event", {}) as Dictionary).duplicate(true)}
	if is_claimed(state, level):
		return {"ok": false, "error": "MERIT_REWARD_ALREADY_CLAIMED"}
	var claimed := claimed_levels(state).duplicate(true)
	claimed[str(level)] = true
	var claimed_bucket := (state.quests.get("claimed", {}) as Dictionary).duplicate(true)
	claimed_bucket[CLAIMED_KEY] = claimed
	state.quests["claimed"] = claimed_bucket
	state.economy.grant({
		"toilet_coins": int(reward.get("toilet_coins", 0)),
		"toilet_gems": int(reward.get("toilet_gems", 0)),
	})
	state.factory.grant({
		"porcelain": int(reward.get("porcelain", 0)),
		"parts": int(reward.get("parts", 0)),
		"sludge": int(reward.get("sludge", 0)),
	})
	var event := {
		"type": "war_merit_reward_claimed",
		"request_id": request_id,
		"level": level,
		"reward": reward.duplicate(true),
	}
	ledger[ledger_key] = {
		"kind": "war_merit_reward",
		"fingerprint": fingerprint,
		"event": event.duplicate(true),
	}
	state.receipt_ledgers["durable"] = ledger
	return {"ok": true, "event": event}

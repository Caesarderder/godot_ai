class_name GoldShopService
extends RefCounted

const GoldShopCatalogScript := preload("res://game/scripts/domain/economy/gold_shop_catalog.gd")


static func purchase(state: RefCounted, request_id: String, offer_id: String) -> Dictionary:
	if request_id.is_empty():
		return {"ok": false, "error": "SHOP_REQUEST_ID_REQUIRED"}
	var offer := GoldShopCatalogScript.offer(offer_id)
	if offer.is_empty():
		return {"ok": false, "error": "SHOP_OFFER_NOT_FOUND"}
	var ledger := state.receipt_ledgers.get("durable", {}) as Dictionary
	var ledger_key := "gold_shop:%s" % request_id
	var fingerprint := "%s|%s" % [request_id, offer_id]
	if ledger.has(ledger_key):
		var old := ledger[ledger_key] as Dictionary
		if String(old.get("fingerprint", "")) != fingerprint:
			return {"ok": false, "error": "SHOP_REQUEST_ID_REUSE_MISMATCH"}
		return {"ok": true, "event": (old.get("event", {}) as Dictionary).duplicate(true)}
	var gold_cost := int(offer["gold_cost"])
	if int(state.economy.gold) < gold_cost:
		return {"ok": false, "error": "NOT_ENOUGH_GOLD"}
	state.economy.gold -= gold_cost
	var economy_grant := (offer.get("economy_grant", {}) as Dictionary).duplicate(true)
	var factory_grant := (offer.get("factory_grant", {}) as Dictionary).duplicate(true)
	state.economy.grant(economy_grant)
	state.factory.grant(factory_grant)
	var event := {
		"type": "gold_shop_purchase",
		"request_id": request_id,
		"offer_id": offer_id,
		"gold_cost": gold_cost,
		"economy_grant": economy_grant,
		"factory_grant": factory_grant,
	}
	ledger[ledger_key] = {
		"kind": "gold_shop_purchase",
		"fingerprint": fingerprint,
		"event": event.duplicate(true),
	}
	state.receipt_ledgers["durable"] = ledger
	return {"ok": true, "event": event}

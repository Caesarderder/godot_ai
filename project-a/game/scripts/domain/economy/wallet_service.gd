class_name WalletService
extends RefCounted

const SalvageCatalogScript := preload("res://game/scripts/domain/economy/salvage_catalog.gd")


static func grant_alliance_scrap(state: RefCounted, request_id: String, amount: int, reason_code: String, context: Dictionary = {}) -> Dictionary:
	if request_id.is_empty():
		return {"ok": false, "error": "WALLET_REQUEST_ID_REQUIRED"}
	if amount < 0:
		return {"ok": false, "error": "WALLET_AMOUNT_MUST_NOT_BE_NEGATIVE"}
	if reason_code.is_empty():
		return {"ok": false, "error": "WALLET_REASON_REQUIRED"}
	var fingerprint_payload := {
		"kind": "grant_alliance_scrap",
		"item_id": SalvageCatalogScript.ITEM_ID,
		"amount": amount,
		"reason": reason_code,
		"context": context.duplicate(true),
	}
	var fingerprint := _fingerprint(fingerprint_payload)
	var replay := _ledger_replay(state, request_id, fingerprint)
	if not replay.is_empty():
		return replay
	var before := _item_balance(state, SalvageCatalogScript.ITEM_ID)
	var after := before + amount
	_set_item_balance(state, SalvageCatalogScript.ITEM_ID, after)
	var receipt := {
		"request_id": request_id,
		"fingerprint": fingerprint,
		"kind": "grant_alliance_scrap",
		"reason": reason_code,
		"item_id": SalvageCatalogScript.ITEM_ID,
		"amount": amount,
		"balance_before": before,
		"balance_after": after,
		"context": context.duplicate(true),
	}
	_store_receipt(state, request_id, receipt)
	return {"ok": true, "receipt": receipt, "idempotent": false}


static func exchange_salvage(state: RefCounted, request_id: String, offer_id: String) -> Dictionary:
	if request_id.is_empty():
		return {"ok": false, "error": "WALLET_REQUEST_ID_REQUIRED"}
	if offer_id.is_empty():
		return {"ok": false, "error": "SALVAGE_OFFER_ID_REQUIRED"}
	if not SalvageCatalogScript.has_offer(offer_id):
		return {"ok": false, "error": "UNKNOWN_SALVAGE_OFFER"}
	var offer := SalvageCatalogScript.offer(offer_id)
	var cost := int(offer.get("cost", 0))
	var grant := offer.get("grant", {}) as Dictionary
	var fingerprint_payload := {
		"kind": "exchange_salvage",
		"offer_id": offer_id,
		"item_id": SalvageCatalogScript.ITEM_ID,
		"cost": cost,
		"grant": grant.duplicate(true),
		"reason": String(offer.get("reason", "")),
	}
	var fingerprint := _fingerprint(fingerprint_payload)
	var replay := _ledger_replay(state, request_id, fingerprint)
	if not replay.is_empty():
		if bool(replay.get("ok", false)):
			var receipt := replay.get("receipt", {}) as Dictionary
			return {"ok": true, "event": _exchange_event(receipt, true)}
		return replay
	var before := _item_balance(state, SalvageCatalogScript.ITEM_ID)
	if before < cost:
		return {"ok": false, "error": "NOT_ENOUGH_ALLIANCE_SCRAP"}
	var economy_grant := (grant.get("economy", {}) as Dictionary).duplicate(true)
	var factory_grant := (grant.get("factory", {}) as Dictionary).duplicate(true)
	var after := before - cost
	_set_item_balance(state, SalvageCatalogScript.ITEM_ID, after)
	if not economy_grant.is_empty():
		state.economy.grant(economy_grant)
	if not factory_grant.is_empty():
		state.factory.grant(factory_grant)
	var receipt := {
		"request_id": request_id,
		"fingerprint": fingerprint,
		"kind": "exchange_salvage",
		"reason": String(offer.get("reason", "")),
		"offer_id": offer_id,
		"item_id": SalvageCatalogScript.ITEM_ID,
		"cost": cost,
		"balance_before": before,
		"balance_after": after,
		"grant": grant.duplicate(true),
	}
	_store_receipt(state, request_id, receipt)
	return {"ok": true, "event": _exchange_event(receipt, false)}


static func alliance_scrap_balance(state: RefCounted) -> int:
	return _item_balance(state, SalvageCatalogScript.ITEM_ID)


static func _ledger_replay(state: RefCounted, request_id: String, fingerprint: String) -> Dictionary:
	var durable := _durable_ledger(state)
	if not durable.has(request_id):
		return {}
	var receipt := durable[request_id] as Dictionary
	if String(receipt.get("fingerprint", "")) != fingerprint:
		return {"ok": false, "error": "WALLET_REQUEST_ID_REUSE_MISMATCH"}
	return {"ok": true, "receipt": receipt.duplicate(true), "idempotent": true}


static func _exchange_event(receipt: Dictionary, idempotent: bool) -> Dictionary:
	return {
		"type": "salvage_exchanged",
		"request_id": String(receipt.get("request_id", "")),
		"offer_id": String(receipt.get("offer_id", "")),
		"cost": int(receipt.get("cost", 0)),
		"grant": (receipt.get("grant", {}) as Dictionary).duplicate(true),
		"balance_after": int(receipt.get("balance_after", 0)),
		"ledger_receipt": receipt.duplicate(true),
		"idempotent": idempotent,
	}


static func _item_balance(state: RefCounted, item_id: String) -> int:
	_ensure_inventory(state)
	return int((state.inventory["items"] as Dictionary).get(item_id, 0))


static func _set_item_balance(state: RefCounted, item_id: String, amount: int) -> void:
	_ensure_inventory(state)
	(state.inventory["items"] as Dictionary)[item_id] = amount


static func _ensure_inventory(state: RefCounted) -> void:
	if not state.inventory.has("items") or typeof(state.inventory["items"]) != TYPE_DICTIONARY:
		state.inventory["items"] = {}


static func _durable_ledger(state: RefCounted) -> Dictionary:
	if not state.receipt_ledgers.has("durable") or typeof(state.receipt_ledgers["durable"]) != TYPE_DICTIONARY:
		state.receipt_ledgers["durable"] = {}
	return state.receipt_ledgers["durable"] as Dictionary


static func _store_receipt(state: RefCounted, request_id: String, receipt: Dictionary) -> void:
	var durable := _durable_ledger(state)
	durable[request_id] = receipt.duplicate(true)


static func _fingerprint(payload: Variant) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(_canonical(payload).to_utf8_buffer())
	return ctx.finish().hex_encode()


static func _canonical(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if bool(value) else "false"
		TYPE_INT:
			return str(int(value))
		TYPE_STRING:
			return JSON.stringify(String(value))
		TYPE_ARRAY:
			var array_parts: Array[String] = []
			for item in value:
				array_parts.append(_canonical(item))
			return "[" + ",".join(array_parts) + "]"
		TYPE_DICTIONARY:
			var dict := value as Dictionary
			var keys: Array[String] = []
			for key in dict.keys():
				keys.append(String(key))
			keys.sort()
			var dict_parts: Array[String] = []
			for key in keys:
				dict_parts.append("%s:%s" % [JSON.stringify(key), _canonical(dict[key])])
			return "{" + ",".join(dict_parts) + "}"
		_:
			return JSON.stringify(str(value))

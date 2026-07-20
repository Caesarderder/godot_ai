class_name ReceiptLedger
extends RefCounted

const STATUS_MISS := "MISS"
const STATUS_MATCH := "MATCH"
const ERROR_COMMAND_ID_REUSE := "COMMAND_ID_REUSE_MISMATCH"
const ERROR_BUSINESS_KEY_REUSE := "BUSINESS_KEY_REUSE_MISMATCH"


static func create_empty() -> Dictionary:
	return {
		"value_by_command": {},
		"value_by_business": {},
		"causal_by_command": {},
		"causal_by_business": {},
		"reversible_by_command": {},
		"reversible_by_business": {},
		"reversible_order": [],
	}


static func lookup(
	state: Dictionary,
	command_id: String,
	fingerprint: String,
	business_key: String
) -> Dictionary:
	var ledgers := _ensure_ledgers(state)
	for command_index_name in [
		"value_by_command",
		"causal_by_command",
		"reversible_by_command",
	]:
		var by_command: Dictionary = ledgers[command_index_name]
		if by_command.has(command_id):
			var receipt: Dictionary = by_command[command_id]
			if receipt.get("fingerprint", "") == fingerprint:
				return {"status": STATUS_MATCH, "receipt": receipt.duplicate(true)}
			return {"status": ERROR_COMMAND_ID_REUSE}

	if not business_key.is_empty():
		for business_index_name in [
			"value_by_business",
			"causal_by_business",
			"reversible_by_business",
		]:
			var by_business: Dictionary = ledgers[business_index_name]
			if by_business.has(business_key):
				var receipt: Dictionary = by_business[business_key]
				if receipt.get("fingerprint", "") == fingerprint:
					return {"status": STATUS_MATCH, "receipt": receipt.duplicate(true)}
				return {"status": ERROR_BUSINESS_KEY_REUSE}

	return {"status": STATUS_MISS}


static func record_value(state: Dictionary, receipt: Dictionary) -> void:
	_record_lifetime(state, receipt, "value_by_command", "value_by_business")


static func record_causal(state: Dictionary, receipt: Dictionary) -> void:
	_record_lifetime(state, receipt, "causal_by_command", "causal_by_business")


static func record_reversible(
	state: Dictionary,
	receipt: Dictionary,
	capacity: int = 512
) -> void:
	var ledgers := _ensure_ledgers(state)
	var command_id := str(receipt.get("command_id", ""))
	var stored_receipt := receipt.duplicate(true)
	ledgers.reversible_by_command[command_id] = stored_receipt
	var business_key := str(receipt.get("business_key", ""))
	if not business_key.is_empty():
		ledgers.reversible_by_business[business_key] = stored_receipt
	ledgers.reversible_order.erase(command_id)
	ledgers.reversible_order.append(command_id)

	while ledgers.reversible_order.size() > max(0, capacity):
		var evicted_id: String = ledgers.reversible_order.pop_front()
		var evicted: Dictionary = ledgers.reversible_by_command.get(evicted_id, {})
		ledgers.reversible_by_command.erase(evicted_id)
		var evicted_key := str(evicted.get("business_key", ""))
		if not evicted_key.is_empty():
			ledgers.reversible_by_business.erase(evicted_key)


static func _record_lifetime(
	state: Dictionary,
	receipt: Dictionary,
	command_index_name: String,
	business_index_name: String
) -> void:
	var ledgers := _ensure_ledgers(state)
	var stored_receipt := receipt.duplicate(true)
	var command_id := str(stored_receipt.get("command_id", ""))
	ledgers[command_index_name][command_id] = stored_receipt
	var business_key := str(stored_receipt.get("business_key", ""))
	if not business_key.is_empty():
		ledgers[business_index_name][business_key] = stored_receipt


static func _ensure_ledgers(state: Dictionary) -> Dictionary:
	if not state.has("receipt_ledgers") or not state.receipt_ledgers is Dictionary:
		state.receipt_ledgers = create_empty()
	var ledgers: Dictionary = state.receipt_ledgers
	var defaults := create_empty()
	for key: String in defaults:
		if not ledgers.has(key):
			ledgers[key] = defaults[key]
	return ledgers

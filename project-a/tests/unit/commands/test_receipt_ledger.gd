extends GutTest

const ReceiptLedger := preload("res://game/scripts/state/receipt_ledger.gd")


func _empty_state() -> Dictionary:
	return {"receipt_ledgers": ReceiptLedger.create_empty()}


func _receipt(index: int, fingerprint := "fp", business_key := "") -> Dictionary:
	return {
		"command_id": "command-%d" % index,
		"fingerprint": fingerprint,
		"business_key": business_key,
		"result": {"ok": true, "index": index},
	}


func test_value_receipt_matches_replay_and_rejects_reuse_mismatches() -> void:
	var state := _empty_state()
	ReceiptLedger.record_value(state, _receipt(1, "same", "reward:1"))

	assert_eq(ReceiptLedger.lookup(state, "command-1", "same", "reward:1").status, "MATCH")
	assert_eq(
		ReceiptLedger.lookup(state, "command-1", "changed", "reward:1").status,
		"COMMAND_ID_REUSE_MISMATCH"
	)
	assert_eq(
		ReceiptLedger.lookup(state, "other", "changed", "reward:1").status,
		"BUSINESS_KEY_REUSE_MISMATCH"
	)


func test_causal_receipts_are_not_evicted_after_six_hundred_commands() -> void:
	var state := _empty_state()
	for index in range(600):
		ReceiptLedger.record_causal(state, _receipt(index, "fp-%d" % index))

	for retained_index in [0, 255, 511, 599]:
		assert_eq(
			ReceiptLedger.lookup(
				state,
				"command-%d" % retained_index,
				"fp-%d" % retained_index,
				""
			).status,
			"MATCH"
		)


func test_reversible_receipts_keep_only_the_latest_five_hundred_twelve() -> void:
	var state := _empty_state()
	for index in range(600):
		ReceiptLedger.record_reversible(state, _receipt(index, "fp-%d" % index))

	assert_eq(state.receipt_ledgers.reversible_order.size(), 512)
	assert_eq(ReceiptLedger.lookup(state, "command-0", "fp-0", "").status, "MISS")
	assert_eq(ReceiptLedger.lookup(state, "command-88", "fp-88", "").status, "MATCH")
	assert_eq(ReceiptLedger.lookup(state, "command-599", "fp-599", "").status, "MATCH")

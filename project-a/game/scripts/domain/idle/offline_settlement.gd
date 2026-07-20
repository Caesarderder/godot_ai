class_name OfflineSettlement
extends RefCounted

const MAX_CREDIT_SECONDS := 8 * 60 * 60


static func calculate(state: Dictionary, now_unix: int) -> Dictionary:
	var anchor := int(state.get("offline_anchor_unix", now_unix))
	var effective_end := maxi(anchor, now_unix)
	var elapsed_seconds := effective_end - anchor
	return {
		"effective_end": effective_end,
		"elapsed_seconds": elapsed_seconds,
		"credited_seconds": mini(elapsed_seconds, MAX_CREDIT_SECONDS),
	}

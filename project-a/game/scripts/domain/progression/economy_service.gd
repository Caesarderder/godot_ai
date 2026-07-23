class_name EconomyService
extends RefCounted

const RESOURCE_IDS: Array[String] = [
	"gold",
	"recruit_tickets",
	"experience_books",
	"forge_stones",
]


static func normalize(economy: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for resource_id: String in RESOURCE_IDS:
		normalized[resource_id] = max(0, int(economy.get(resource_id, 0)))
	return normalized


static func apply_delta(economy: Dictionary, delta: Dictionary) -> Dictionary:
	var normalized := normalize(economy)
	var updated := normalized.duplicate(true)
	for resource_id: String in RESOURCE_IDS:
		if not delta.has(resource_id):
			continue
		var next_value := int(updated[resource_id]) + int(delta[resource_id])
		if next_value < 0:
			return {"ok": false, "code": "NEGATIVE_BALANCE", "economy": normalized}
		updated[resource_id] = next_value
	return {"ok": true, "code": "OK", "economy": updated}

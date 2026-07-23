class_name PityState
extends RefCounted

const LootGeneratorScript := preload("res://game/scripts/domain/loot/loot_generator.gd")
const Definitions := preload("res://game/scripts/domain/loot/equipment_definitions.gd")

const PITY_THRESHOLD: int = 8
const FIRST_GUARANTEE_STAGE_ID: String = "stage-1-3"


static func create_empty() -> Dictionary:
	return {
		"qualifying_drops": 0,
		"qualifying_drop_count": 0,
		"first_guarantee_claimed": false,
	}


static func resolve_qualifying_drop(
	pity: Dictionary,
	item: Dictionary,
	stage_id: String = "",
	preferred_template_ids: Array = []
) -> Dictionary:
	var updated := _normalize(pity)
	var resolved_item := item.duplicate(true)
	var guaranteed := false
	var rank := Definitions.quality_rank(String(item.get("quality", "white")))
	if rank >= Definitions.quality_rank("blue"):
		updated["qualifying_drops"] = 0
		updated["qualifying_drop_count"] = 0
		updated["first_guarantee_claimed"] = true
		return {"pity": updated, "item": resolved_item, "guaranteed": false}

	var next_count := int(updated.get("qualifying_drops", 0)) + 1
	var should_first_guarantee := (
		stage_id == FIRST_GUARANTEE_STAGE_ID and not bool(updated.get("first_guarantee_claimed", false))
	)
	if should_first_guarantee or next_count >= PITY_THRESHOLD:
		resolved_item = _upgrade_to_blue(resolved_item, preferred_template_ids)
		updated["qualifying_drops"] = 0
		updated["qualifying_drop_count"] = 0
		updated["first_guarantee_claimed"] = true
		guaranteed = true
	else:
		updated["qualifying_drops"] = next_count
		updated["qualifying_drop_count"] = next_count
	return {"pity": updated, "item": resolved_item, "guaranteed": guaranteed}


static func _normalize(pity: Dictionary) -> Dictionary:
	var count := int(pity.get("qualifying_drops", pity.get("qualifying_drop_count", 0)))
	return {
		"qualifying_drops": count,
		"qualifying_drop_count": count,
		"first_guarantee_claimed": bool(pity.get("first_guarantee_claimed", false)),
	}


static func _upgrade_to_blue(item: Dictionary, preferred_template_ids: Array) -> Dictionary:
	var template_id := String(item.get("template_id", "guardian_blade"))
	if not preferred_template_ids.is_empty():
		template_id = String(preferred_template_ids[0])
	var upgraded := LootGeneratorScript.create_item(
		int(item.get("seed", 0)),
		int(item.get("drop_index", 0)),
		template_id,
		"blue",
		item.get("affix_ids", [])
	)
	if upgraded.affix_ids.is_empty():
		upgraded.affix_ids = ["strength"]
	return upgraded

class_name LootGenerator
extends RefCounted

const Definitions := preload("res://game/scripts/domain/loot/equipment_definitions.gd")


static func create_item(
	seed_value: int,
	drop_index: int,
	template_id: String,
	quality: String,
	affix_ids: Array = []
) -> Dictionary:
	var normalized_affixes: Array[String] = []
	for affix_id: Variant in affix_ids:
		normalized_affixes.append(String(affix_id))
	var slot := Definitions.template_slot(template_id)
	return {
		"id": _item_id(seed_value, drop_index, template_id),
		"seed": seed_value,
		"drop_index": drop_index,
		"template_id": template_id,
		"slot": slot,
		"quality": quality,
		"affix_ids": normalized_affixes,
		"enhancement": 0,
	}


static func _item_id(seed_value: int, drop_index: int, template_id: String) -> String:
	var bytes := "%d:%d:%s" % [seed_value, drop_index, template_id]
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes.to_utf8_buffer())
	return "item-%s" % context.finish().hex_encode().substr(0, 16)

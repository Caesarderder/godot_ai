class_name StageDefinitionCatalog
extends RefCounted

const ACT_ONE_OPENING: Array[Resource] = [
	preload("res://game/resources/definitions/stages/act_1/stage_1_1.tres"),
	preload("res://game/resources/definitions/stages/act_1/stage_1_2.tres"),
	preload("res://game/resources/definitions/stages/act_1/stage_1_3.tres"),
	preload("res://game/resources/definitions/stages/act_1/stage_1_4.tres"),
	preload("res://game/resources/definitions/stages/act_1/stage_1_5.tres"),
]


static func definition(stage_id: String) -> Resource:
	for item in ACT_ONE_OPENING:
		if String(item.stage_id) == stage_id:
			return item
	return null


static func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	for item in ACT_ONE_OPENING:
		if item == null:
			errors.append("stage definition preload returned null")
			continue
		var stage_id := String(item.stage_id)
		if ids.has(stage_id):
			errors.append("duplicate stage definition id: %s" % stage_id)
		ids[stage_id] = true
		for error in item.validation_errors():
			errors.append(String(error))
	if ACT_ONE_OPENING.size() != 5:
		errors.append("opening catalog must contain exactly five first-chapter stages")
	return errors

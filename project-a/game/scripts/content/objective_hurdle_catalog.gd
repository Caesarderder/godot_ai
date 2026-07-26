class_name ObjectiveHurdleCatalog
extends RefCounted

const FIRST_CHAPTER: Array[Resource] = [
	preload("res://game/resources/definitions/objectives/hurdles/lone_vanguard.tres"),
	preload("res://game/resources/definitions/objectives/hurdles/keep_advancing.tres"),
	preload("res://game/resources/definitions/objectives/hurdles/high_wall.tres"),
	preload("res://game/resources/definitions/objectives/hurdles/research_reinforcements.tres"),
	preload("res://game/resources/definitions/objectives/hurdles/counterattack.tres"),
	preload("res://game/resources/definitions/objectives/hurdles/choose_growth.tres"),
	preload("res://game/resources/definitions/objectives/hurdles/chapter_boss.tres"),
]


static func definition(task_id: String) -> Resource:
	for item in FIRST_CHAPTER:
		if String(item.task_id) == task_id:
			return item
	return null


static func hurdle_view(task_id: String) -> Dictionary:
	var item := definition(task_id)
	if item == null:
		return {}
	return {
		"scale": String(item.scale),
		"title": String(item.title),
		"reason": String(item.reason),
		"recovery": String(item.recovery),
	}


static func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	for item in FIRST_CHAPTER:
		if item == null:
			errors.append("objective hurdle preload returned null")
			continue
		var task_id := String(item.task_id)
		if ids.has(task_id):
			errors.append("duplicate objective hurdle task_id: %s" % task_id)
		ids[task_id] = true
		for error in item.validation_errors():
			errors.append(String(error))
	if FIRST_CHAPTER.size() != 7:
		errors.append("first chapter must contain exactly seven hurdle definitions")
	return errors

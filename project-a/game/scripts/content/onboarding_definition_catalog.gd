class_name OnboardingDefinitionCatalog
extends RefCounted

const FIRST_CHAPTER: Array[Resource] = [
	preload("res://game/resources/definitions/onboarding/tasks/lone_vanguard.tres"),
	preload("res://game/resources/definitions/onboarding/tasks/keep_advancing.tres"),
	preload("res://game/resources/definitions/onboarding/tasks/high_wall.tres"),
	preload("res://game/resources/definitions/onboarding/tasks/research_reinforcements.tres"),
	preload("res://game/resources/definitions/onboarding/tasks/counterattack.tres"),
	preload("res://game/resources/definitions/onboarding/tasks/choose_growth.tres"),
	preload("res://game/resources/definitions/onboarding/tasks/chapter_boss.tres"),
]


static func count() -> int:
	return FIRST_CHAPTER.size() if validate_all().is_empty() else 0


static func task_view_at(index: int) -> Dictionary:
	if not validate_all().is_empty() or index < 0 or index >= FIRST_CHAPTER.size():
		return {}
	return FIRST_CHAPTER[index].to_view().duplicate(true)


static func task_view(task_id: String) -> Dictionary:
	if not validate_all().is_empty():
		return {}
	for definition in FIRST_CHAPTER:
		if String(definition.task_id) == task_id:
			return definition.to_view().duplicate(true)
	return {}


static func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	var task_ids: Dictionary = {}
	var objective_ids: Dictionary = {}
	var objective_count := 0
	for definition in FIRST_CHAPTER:
		if definition == null:
			errors.append("onboarding task preload returned null")
			continue
		var task_id := String(definition.task_id)
		if task_ids.has(task_id):
			errors.append("duplicate onboarding task_id: %s" % task_id)
		task_ids[task_id] = true
		for error in definition.validation_errors():
			errors.append(String(error))
		for objective in definition.objectives:
			if objective == null:
				continue
			objective_count += 1
			var objective_id := String(objective.objective_id)
			if objective_ids.has(objective_id):
				errors.append("duplicate onboarding objective_id: %s" % objective_id)
			objective_ids[objective_id] = true
	if FIRST_CHAPTER.size() != 7:
		errors.append("first chapter must contain exactly seven onboarding tasks")
	if objective_count != 10:
		errors.append("first chapter must contain exactly ten onboarding objectives")
	return errors

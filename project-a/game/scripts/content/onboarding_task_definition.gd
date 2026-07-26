class_name OnboardingTaskDefinition
extends Resource

@export var task_id: StringName
@export var title: String = ""
@export_multiline var lesson: String = ""
@export var objectives: Array[Resource] = []
@export_group("Reward")
@export_range(0, 100000, 1) var toilet_coins: int = 0
@export_range(0, 100000, 1) var industrial_tech: int = 0
@export_range(0, 100000, 1) var hero_shards: int = 0
@export_range(0, 100000, 1) var skill_chips: int = 0
@export_range(0, 100000, 1) var porcelain: int = 0
@export_range(0, 100000, 1) var parts: int = 0
@export_range(0, 100000, 1) var sludge: int = 0


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var id := String(task_id)
	if id.is_empty():
		errors.append("task_id is required")
	elif not id.begins_with("operation."):
		errors.append("%s task_id must use the operation namespace" % id)
	if title.strip_edges().is_empty():
		errors.append("%s title is required" % id)
	if lesson.strip_edges().is_empty():
		errors.append("%s lesson is required" % id)
	if objectives.is_empty():
		errors.append("%s requires at least one objective" % id)
	for objective in objectives:
		if objective == null or not objective.has_method("validation_errors"):
			errors.append("%s contains an invalid objective Resource" % id)
			continue
		for error in objective.validation_errors():
			errors.append("%s: %s" % [id, String(error)])
	for amount in [
		toilet_coins, industrial_tech, hero_shards, skill_chips, porcelain, parts, sludge
	]:
		if amount < 0:
			errors.append("%s reward amounts must be non-negative" % id)
	return errors


func reward_view() -> Dictionary:
	var reward := {}
	_append_reward(reward, "toilet_coins", toilet_coins)
	_append_reward(reward, "industrial_tech", industrial_tech)
	_append_reward(reward, "hero_shards", hero_shards)
	_append_reward(reward, "skill_chips", skill_chips)
	_append_reward(reward, "porcelain", porcelain)
	_append_reward(reward, "parts", parts)
	_append_reward(reward, "sludge", sludge)
	return reward


func to_view() -> Dictionary:
	var objective_views: Array[Dictionary] = []
	for objective in objectives:
		objective_views.append(objective.to_view())
	return {
		"id": String(task_id),
		"title": title,
		"lesson": lesson,
		"reward": reward_view(),
		"objectives": objective_views,
	}


func _append_reward(reward: Dictionary, key: String, amount: int) -> void:
	if amount > 0:
		reward[key] = amount

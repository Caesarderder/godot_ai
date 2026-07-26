class_name OnboardingService
extends RefCounted

const OnboardingCatalogScript := preload("res://game/scripts/domain/onboarding/onboarding_catalog.gd")
const ResearchBreakthroughCatalogScript := preload(
	"res://game/scripts/content/research_breakthrough_catalog.gd"
)


static func default_state() -> Dictionary:
	return {
		"catalog_version": OnboardingCatalogScript.CATALOG_VERSION,
		"active_index": 0,
		"progress": {},
		"completed": {},
		"claimed": {},
		"event_keys": {},
	}


static func normalize(state: RefCounted) -> void:
	if typeof(state.onboarding) != TYPE_DICTIONARY:
		state.onboarding = default_state()
	var current := state.onboarding as Dictionary
	if int(current.get("catalog_version", 0)) != OnboardingCatalogScript.CATALOG_VERSION:
		state.onboarding = default_state()
		current = state.onboarding
	for key in ["progress", "completed", "claimed", "event_keys"]:
		if typeof(current.get(key, {})) != TYPE_DICTIONARY:
			current[key] = {}
	current["active_index"] = clampi(int(current.get("active_index", 0)), 0, OnboardingCatalogScript.count())
	state.onboarding = current


static func snapshot(state: RefCounted) -> Dictionary:
	normalize(state)
	var data := state.onboarding as Dictionary
	var index := int(data.get("active_index", 0))
	if index >= OnboardingCatalogScript.count():
		return {
			"finished": true,
			"step": OnboardingCatalogScript.count(),
			"total": OnboardingCatalogScript.count(),
			"title": "新兵训练完成",
			"lesson": "工厂供养军团，军团战果扩建工厂。",
			"cta_label": "继续推进",
			"target": "expedition",
			"progress": 1,
			"target_value": 1,
			"completed": true,
			"claimed": true,
			"reward": {},
		}
	var definition := OnboardingCatalogScript.task_at(index)
	var task_id := String(definition["id"])
	var claimed := (data["claimed"] as Dictionary).has(task_id)
	var objectives: Array[Dictionary] = []
	var first_incomplete: Dictionary = {}
	var all_objectives_complete := true
	for objective_value in definition.get("objectives", []):
		var objective := objective_value as Dictionary
		var objective_key := _objective_key(task_id, String(objective["id"]))
		var objective_done := (
			int((data["progress"] as Dictionary).get(objective_key, 0)) >= 1
			or _objective_satisfied_by_state(state, objective)
		)
		var view := objective.duplicate(true)
		view["completed"] = objective_done
		objectives.append(view)
		if not objective_done and first_incomplete.is_empty():
			first_incomplete = objective
		if not objective_done:
			all_objectives_complete = false
	var completed := (data["completed"] as Dictionary).has(task_id) or (
		not objectives.is_empty() and all_objectives_complete
	)
	if first_incomplete.is_empty() and not objectives.is_empty():
		first_incomplete = objectives.back()
	return {
		"finished": false,
		"step": index + 1,
		"total": OnboardingCatalogScript.count(),
		"task_id": task_id,
		"title": String(definition["title"]),
		"lesson": String(definition["lesson"]),
		"cta_label": "领取行动战果" if completed and not claimed else String(first_incomplete.get("cta_label", "继续")),
		"target": String(first_incomplete.get("target", "factory")),
		"stage_id": String(first_incomplete.get("stage_target", "")),
		"progress": _completed_objective_count(objectives),
		"target_value": objectives.size(),
		"objectives": objectives,
		"completed": completed,
		"claimed": claimed,
		"reward": (definition.get("reward", {}) as Dictionary).duplicate(true),
	}


static func apply_event(state: RefCounted, event: Dictionary) -> Dictionary:
	normalize(state)
	_reconcile_current_task(state)
	var data := state.onboarding as Dictionary
	var index := int(data.get("active_index", 0))
	if index >= OnboardingCatalogScript.count():
		return {}
	var definition := OnboardingCatalogScript.task_at(index)
	var task_id := String(definition["id"])
	if (data["completed"] as Dictionary).has(task_id):
		if not (data["claimed"] as Dictionary).has(task_id):
			return _settle_with_catch_up(state, definition, task_id, index)
		return {}
	var event_key := _event_key(event)
	if not event_key.is_empty():
		var keys := data["event_keys"] as Dictionary
		if keys.has(event_key):
			return {}
		keys[event_key] = true
	var progress := data["progress"] as Dictionary
	var matched := false
	for objective_value in definition.get("objectives", []):
		var objective := objective_value as Dictionary
		var key := _objective_key(task_id, String(objective["id"]))
		if int(progress.get(key, 0)) >= 1 or not _matches(objective, event):
			continue
		progress[key] = 1
		matched = true
	if not matched:
		return {}
	var all_complete := true
	for objective_value in definition.get("objectives", []):
		var objective := objective_value as Dictionary
		if int(progress.get(_objective_key(task_id, String(objective["id"])), 0)) < 1:
			all_complete = false
			break
	if all_complete:
		(data["completed"] as Dictionary)[task_id] = true
		return _settle_with_catch_up(state, definition, task_id, index)
	return {}


static func claim_current(state: RefCounted, task_id: String) -> Dictionary:
	normalize(state)
	_reconcile_current_task(state)
	var data := state.onboarding as Dictionary
	var index := int(data.get("active_index", 0))
	var definition := OnboardingCatalogScript.task_at(index)
	if definition.is_empty() or String(definition["id"]) != task_id:
		return {"ok": false, "error": "ONBOARDING_TASK_NOT_ACTIVE"}
	if not (data["completed"] as Dictionary).has(task_id):
		return {"ok": false, "error": "ONBOARDING_TASK_NOT_COMPLETED"}
	if (data["claimed"] as Dictionary).has(task_id):
		return {"ok": false, "error": "ONBOARDING_TASK_ALREADY_CLAIMED"}
	var settlement := _settle_with_catch_up(state, definition, task_id, index)
	return {
		"ok": true,
		"event": {
			"type": "onboarding_task_claimed",
			"task_id": task_id,
			"reward": settlement.get("reward", {}),
			"next_index": index + 1,
		},
	}


static func _settle_completed_task(
	state: RefCounted,
	definition: Dictionary,
	task_id: String,
	index: int
) -> Dictionary:
	var data := state.onboarding as Dictionary
	if (data["claimed"] as Dictionary).has(task_id):
		return {}
	var reward := (definition.get("reward", {}) as Dictionary).duplicate(true)
	_grant_reward(state, reward)
	(data["claimed"] as Dictionary)[task_id] = true
	data["active_index"] = index + 1
	return {
		"task_id": task_id,
		"reward": reward,
		"next_index": index + 1,
		"auto_settled": true,
	}


static func _settle_with_catch_up(
	state: RefCounted,
	definition: Dictionary,
	task_id: String,
	index: int
) -> Dictionary:
	var primary := _settle_completed_task(state, definition, task_id, index)
	var catch_up_tasks: Array[String] = []
	while true:
		_reconcile_current_task(state)
		var data := state.onboarding as Dictionary
		var next_index := int(data.get("active_index", 0))
		if next_index >= OnboardingCatalogScript.count():
			break
		var next_definition := OnboardingCatalogScript.task_at(next_index)
		var next_task_id := String(next_definition.get("id", ""))
		if (
			not (data["completed"] as Dictionary).has(next_task_id)
			or (data["claimed"] as Dictionary).has(next_task_id)
		):
			break
		_settle_completed_task(state, next_definition, next_task_id, next_index)
		catch_up_tasks.append(next_task_id)
	if not catch_up_tasks.is_empty():
		primary["catch_up_tasks"] = catch_up_tasks
	return primary


static func validate(data: Dictionary) -> String:
	for key in ["progress", "completed", "claimed", "event_keys"]:
		if typeof(data.get(key, {})) != TYPE_DICTIONARY:
			return "onboarding.%s must be dictionary" % key
	var index := int(data.get("active_index", 0))
	if index < 0 or index > OnboardingCatalogScript.count():
		return "onboarding.active_index out of range"
	if int(data.get("catalog_version", 0)) != OnboardingCatalogScript.CATALOG_VERSION:
		return "onboarding.catalog_version mismatch"
	return ""


static func _matches(definition: Dictionary, event: Dictionary) -> bool:
	var accepted_types: Array = definition.get("event_types", [definition.get("event_type", "")])
	if not accepted_types.has(String(event.get("type", ""))):
		return false
	for key in ["stage_id", "outcome", "repair_mode", "facility_id", "recipe_id", "enabled", "star"]:
		if definition.has(key) and event.get(key) != definition[key]:
			return false
	if definition.has("facility_ids") and not (definition["facility_ids"] as Array).has(String(event.get("facility_id", ""))):
		return false
	if definition.has("archetype_ids") and not (definition["archetype_ids"] as Array).has(String(event.get("archetype_id", ""))):
		return false
	return true


static func _reconcile_current_task(state: RefCounted) -> void:
	var data := state.onboarding as Dictionary
	var index := int(data.get("active_index", 0))
	if index >= OnboardingCatalogScript.count():
		return
	var definition := OnboardingCatalogScript.task_at(index)
	var task_id := String(definition.get("id", ""))
	if task_id.is_empty() or (data["completed"] as Dictionary).has(task_id):
		return
	var progress := data["progress"] as Dictionary
	var all_complete := true
	for objective_value in definition.get("objectives", []):
		var objective := objective_value as Dictionary
		var key := _objective_key(task_id, String(objective.get("id", "")))
		if int(progress.get(key, 0)) < 1 and _objective_satisfied_by_state(state, objective):
			progress[key] = 1
		if int(progress.get(key, 0)) < 1:
			all_complete = false
	if all_complete and not (definition.get("objectives", []) as Array).is_empty():
		(data["completed"] as Dictionary)[task_id] = true


static func _objective_satisfied_by_state(state: RefCounted, objective: Dictionary) -> bool:
	var event_type := String(objective.get("event_type", ""))
	var event_types: Array = objective.get("event_types", [])
	if event_types.has("hero_star_upgraded"):
		for hero in state.roster:
			if String(hero.archetype_id) in ["assault", "armored"] and int(hero.star) >= 2:
				return true
		return false
	match event_type:
		"battle_settled":
			var stage_id := String(objective.get("stage_id", ""))
			if stage_id.is_empty():
				return false
			var cleared := state.stage_progress.get("cleared_stages", []) as Array
			# A durable clear is stronger evidence than an earlier challenge outcome.
			# This lets late-appearing victory and defeat/tutorial objectives catch up.
			return cleared.has(stage_id)
		"facility_constructed":
			for facility_id_value in objective.get("facility_ids", []):
				if int(state.factory.facilities.get(String(facility_id_value), 0)) > 0:
					return true
			return false
		"foundational_blueprint_unlocked":
			var recipe_id := String(objective.get("recipe_id", ""))
			return not recipe_id.is_empty() and bool(state.factory.blueprints.get(recipe_id, false))
		"research_breakthrough_resolved":
			return (state.onboarding.get("claimed", {}) as Dictionary).has(
				ResearchBreakthroughCatalogScript.CLAIM_KEY
			)
	return false


static func _objective_key(task_id: String, objective_id: String) -> String:
	return "%s/%s" % [task_id, objective_id]


static func _completed_objective_count(objectives: Array[Dictionary]) -> int:
	var count := 0
	for objective in objectives:
		if bool(objective.get("completed", false)):
			count += 1
	return count


static func _event_key(event: Dictionary) -> String:
	for key in ["battle_id", "request_id", "order_id", "command_id"]:
		var value := String(event.get(key, ""))
		if not value.is_empty():
			return "%s:%s:%s" % [String(event.get("type", "")), key, value]
	return ""


static func _grant_reward(state: RefCounted, reward: Dictionary) -> void:
	var economy_reward: Dictionary = {}
	var material_reward: Dictionary = {}
	for key in reward.keys():
		var amount := int(reward[key])
		if ["toilet_coins", "toilet_gems", "gold", "industrial_tech", "skill_chips", "hero_shards"].has(String(key)):
			economy_reward[key] = amount
		elif ["porcelain", "parts", "sludge"].has(String(key)):
			material_reward[key] = amount
	state.economy.grant(economy_reward)
	state.factory.grant(material_reward)

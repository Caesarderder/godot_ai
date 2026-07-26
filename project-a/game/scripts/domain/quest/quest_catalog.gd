class_name QuestCatalog
extends RefCounted

const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

const WAR_MERIT_ITEM_ID: String = "war_merit"
const MAX_RANK: int = 30
const MINOR_SLOT_COUNT: int = 3

const MINOR_TEMPLATES: Array[Dictionary] = [
	{"template_id": "battle_settled_once", "event_type": "battle_settled", "target": 1, "reward": {"merit": 10, "toilet_coins": 8, "toilet_gems": 0}, "title": "完成一场战斗"},
	{"template_id": "victory_once", "event_type": "battle_settled", "outcome": "victory", "target": 1, "reward": {"merit": 15, "toilet_coins": 15, "toilet_gems": 1}, "title": "赢下一场攻城"},
	{"template_id": "production_started_once", "event_type": "production_started", "target": 1, "reward": {"merit": 8, "toilet_coins": 6, "toilet_gems": 0}, "title": "启动一次生产"},
	{"template_id": "production_claimed_once", "event_type": "production_claimed", "target": 1, "reward": {"merit": 10, "toilet_coins": 8, "toilet_gems": 0}, "title": "领取一个单位"},
	{"template_id": "model_tech_upgraded_once", "event_type": "model_tech_upgraded", "target": 1, "reward": {"merit": 20, "toilet_coins": 20, "toilet_gems": 2}, "title": "升级一次型号科技"},
]


static func major_quest_id(stage_id: String) -> String:
	return "major.%s" % stage_id


static func major_quests() -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for stage_id in StageCatalogScript.all_stage_ids():
		values.append(major_quest(stage_id))
	return values


static func major_quest(stage_id: String) -> Dictionary:
	var config := StageCatalogScript.stage(stage_id)
	if config.is_empty():
		return {}
	var is_boss := int(config.get("stage_in_chapter", 0)) == 5
	return {
		"quest_id": major_quest_id(stage_id),
		"kind": "major",
		"tier": "major",
		"stage_id": stage_id,
		"generation": 0,
		"title": "首次摧毁 %s" % String(config.get("display_name", stage_id)),
		"reward": _major_reward(stage_id, is_boss),
	}


static func _major_reward(stage_id: String, is_boss: bool) -> Dictionary:
	var reward := {
		"merit": 120 if is_boss else 40,
		"toilet_coins": 30 if is_boss else 10,
		"toilet_gems": 10 if is_boss else 0,
	}
	var milestone_blueprints := {
		"stage_1_5": "ordinary.sonic",
		"stage_2_5": "flying.bomber",
		"stage_3_5": "heavy.saw",
	}
	if milestone_blueprints.has(stage_id):
		reward["blueprint_id"] = String(milestone_blueprints[stage_id])
	return reward


static func minor_template(index: int) -> Dictionary:
	if MINOR_TEMPLATES.is_empty():
		return {}
	var wrapped := posmod(index, MINOR_TEMPLATES.size())
	return MINOR_TEMPLATES[wrapped].duplicate(true)


static func make_minor_slot(slot: int, generation: int) -> Dictionary:
	var template := minor_template(slot + generation)
	var template_id := String(template.get("template_id", "unknown"))
	return {
		"quest_id": "minor.%d.%d.%s" % [slot, generation, template_id],
		"kind": "minor",
		"tier": "minor",
		"slot": slot,
		"generation": generation,
		"template_id": template_id,
		"event_type": String(template.get("event_type", "")),
		"outcome": String(template.get("outcome", "")),
		"title": String(template.get("title", "")),
		"progress": 0,
		"target": int(template.get("target", 1)),
		"reward": (template.get("reward", {}) as Dictionary).duplicate(true),
	}


static func rank_for_merit(total_merit: int) -> int:
	var rank := 1
	var remaining := maxi(0, total_merit)
	while rank < MAX_RANK:
		var required := rank_requirement(rank)
		if remaining < required:
			break
		remaining -= required
		rank += 1
	return rank


static func rank_requirement(level: int) -> int:
	return 100 + (level - 1) * 40


static func validate_definitions() -> Array[String]:
	var errors: Array[String] = []
	for quest in major_quests():
		errors.append_array(_validate_reward(quest.get("reward", {}), String(quest.get("quest_id", ""))))
	for template in MINOR_TEMPLATES:
		var event_type := String(template.get("event_type", ""))
		if not ["battle_settled", "production_started", "production_claimed", "model_tech_upgraded"].has(event_type):
			errors.append("minor template has unknown event_type %s" % event_type)
		if typeof(template.get("target", 0)) != TYPE_INT or int(template.get("target", 0)) <= 0:
			errors.append("minor template target must be positive int")
		errors.append_array(_validate_reward(template.get("reward", {}), String(template.get("template_id", ""))))
	return errors


static func validate_reward_definition(reward: Variant, label: String = "reward") -> Array[String]:
	return _validate_reward(reward, label)


static func _validate_reward(value: Variant, label: String) -> Array[String]:
	var errors: Array[String] = []
	if typeof(value) != TYPE_DICTIONARY:
		return ["%s reward must be dictionary" % label]
	var reward := value as Dictionary
	for key in reward.keys():
		if typeof(key) != TYPE_STRING or not ["merit", "toilet_coins", "toilet_gems", "blueprint_id"].has(String(key)):
			errors.append("%s reward has unknown key %s" % [label, str(key)])
			continue
		if String(key) == "blueprint_id":
			if typeof(reward[key]) != TYPE_STRING or String(reward[key]).is_empty():
				errors.append("%s reward.blueprint_id must be non-empty string" % label)
			continue
		if typeof(reward[key]) != TYPE_INT:
			errors.append("%s reward.%s must be int" % [label, String(key)])
		elif int(reward[key]) < 0:
			errors.append("%s reward.%s must not be negative" % [label, String(key)])
	return errors

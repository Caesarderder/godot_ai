extends SceneTree

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ids := StageCatalogScript.all_stage_ids()
	_check(ids.size() == 25, "Act I contains exactly 25 stages")
	var previous_id := ""
	var chapter_feedback_values: Array[String] = []
	var recommendation_signatures: Array[String] = []
	var boss_suppression_targets: Array[int] = []
	for stage_id in ids:
		var config := StageCatalogScript.stage(stage_id)
		_check(not config.is_empty(), "%s has a definition" % stage_id)
		_check(String(config.get("stage_id", "")) == stage_id, "%s identity is stable" % stage_id)
		_check((config.get("enemies", []) as Array).size() >= 6, "%s has an enemy composition" % stage_id)
		_check((config.get("structures", []) as Array).size() >= 5, "%s has a three-phase structure route" % stage_id)
		_check(config.has("unlock_preview"), "%s exposes an unlock preview field" % stage_id)
		_check(not String(config.get("threat_summary", "")).is_empty(), "%s explains its main threat" % stage_id)
		_check(not String(config.get("counter_hint", "")).is_empty(), "%s explains a counter hint" % stage_id)
		_check(not String(config.get("chapter_feedback", "")).is_empty(), "%s explains chapter feedback" % stage_id)
		_check_recommendation_fields(stage_id, config)
		var recommendation_signature := ",".join(_string_array(config.get("recommended_recipe_ids", [])))
		if not recommendation_signatures.has(recommendation_signature):
			recommendation_signatures.append(recommendation_signature)
		var stage_in_chapter := int(config.get("stage_in_chapter", 0))
		if stage_in_chapter == 5:
			_check(String(config.get("threat_summary", "")).contains("章节 Boss"), "%s marks boss threat readability" % stage_id)
			_check(String(config.get("counter_hint", "")).contains("Boss 战"), "%s marks boss counter readability" % stage_id)
			_check(bool(config.get("suppressible_cannon", false)), "%s enables suppressible core cannon" % stage_id)
			_check(int(config.get("cannon_warning_ticks", 0)) == 20, "%s uses a four-second boss cannon warning")
			_check(int(config.get("cannon_suppression_target", 0)) > 0, "%s has a positive cannon suppression target" % stage_id)
			boss_suppression_targets.append(int(config.get("cannon_suppression_target", 0)))
		else:
			_check(not String(config.get("threat_summary", "")).contains("章节 Boss"), "%s keeps ordinary threat readability distinct from bosses" % stage_id)
			_check(not bool(config.get("suppressible_cannon", false)), "%s keeps suppressible core cannon disabled outside chapter bosses" % stage_id)
			_check(int(config.get("cannon_suppression_target", 0)) == 0, "%s has no ordinary-stage suppression target" % stage_id)
		var feedback := String(config.get("chapter_feedback", ""))
		if not chapter_feedback_values.has(feedback):
			chapter_feedback_values.append(feedback)
		if not previous_id.is_empty():
			_check(StageCatalogScript.next_stage_id(previous_id) == stage_id, "%s unlocks %s" % [previous_id, stage_id])
		previous_id = stage_id
		var session: RefCounted = BattleSessionScript.new()
		session.start(_release_roster(), stage_id, config)
		var safety := 0
		while not session.is_finished and safety < int(config.get("max_ticks", 300)) + 2:
			session.advance_tick()
			safety += 1
		_check(session.is_finished, "%s resolves within its configured time budget" % stage_id)
		_check(String(session.result.get("stage_id", "")) == stage_id, "%s result preserves stage identity" % stage_id)
		_check(["victory", "defeat", "timeout"].has(String(session.result.get("outcome", ""))), "%s produces a valid outcome" % stage_id)
		_check(String(session.result.get("outcome", "")) == "victory", "%s is clearable by the documented three-star release roster" % stage_id)
	_check(chapter_feedback_values.size() == 5, "Act I has distinct chapter feedback for five chapters")
	_check(recommendation_signatures.size() >= 5, "Act I recommendations differ across at least five chapter beats")
	_check(boss_suppression_targets == [70, 85, 100, 115, 130], "boss cannon suppression targets increase across Act I")
	_test_unlock_previews()
	_check(StageCatalogScript.next_stage_id("stage_5_5").is_empty(), "Act I finale has no phantom next stage")
	var undertrained: RefCounted = BattleSessionScript.new()
	undertrained.start(_undertrained_roster(), "stage_5_5", StageCatalogScript.stage("stage_5_5"))
	while not undertrained.is_finished:
		undertrained.advance_tick()
	_check(String(undertrained.result.get("outcome", "")) != "victory", "Act I finale rejects an untrained one-star squad")
	if failures.is_empty():
		print("CAMPAIGN TESTS PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("CAMPAIGN TESTS FAIL: %d failure(s)" % failures.size())
		quit(1)


func _check_recommendation_fields(stage_id: String, config: Dictionary) -> void:
	_check(config.has("recommended_recipe_ids"), "%s exposes recommended recipe ids" % stage_id)
	_check(config.has("fallback_recipe_ids"), "%s exposes fallback recipe ids" % stage_id)
	_check(config.has("recommendation_reason"), "%s exposes a recommendation reason" % stage_id)
	var recommended := _string_array(config.get("recommended_recipe_ids", []))
	var fallback := _string_array(config.get("fallback_recipe_ids", []))
	_check(not recommended.is_empty(), "%s has at least one primary recommendation" % stage_id)
	_check(not String(config.get("recommendation_reason", "")).is_empty(), "%s has a non-empty recommendation reason" % stage_id)
	for recipe_id in recommended:
		_check(FactoryCatalogScript.has_recipe(recipe_id), "%s recommended recipe exists: %s" % [stage_id, recipe_id])
	for recipe_id in fallback:
		_check(FactoryCatalogScript.has_recipe(recipe_id), "%s fallback recipe exists: %s" % [stage_id, recipe_id])
	var intended_unlocked := _intended_unlocked_before(stage_id)
	for recipe_id in recommended:
		_check(intended_unlocked.has(recipe_id), "%s primary recommendation is unlocked before the stage: %s" % [stage_id, recipe_id])
	if stage_id == "stage_1_1":
		for recipe_id in recommended:
			_check(["ordinary.assault", "ordinary.sonic"].has(recipe_id), "stage_1_1 primary recommendation only uses starting blueprints")


func _intended_unlocked_before(stage_id: String) -> Array[String]:
	var values: Array[String] = ["ordinary.assault", "ordinary.sonic"]
	var stage_index := StageCatalogScript.all_stage_ids().find(stage_id)
	var unlock_schedule := {
		"stage_1_3": "heavy.armored",
		"stage_1_5": "flying.rocket",
		"stage_2_3": "flying.bomber",
		"stage_2_5": "special.repair",
		"stage_3_3": "special.parasite",
		"stage_4_3": "heavy.saw",
	}
	for unlock_stage_id in unlock_schedule.keys():
		if stage_index > StageCatalogScript.all_stage_ids().find(String(unlock_stage_id)):
			values.append(String(unlock_schedule[unlock_stage_id]))
	return values


func _string_array(value: Variant) -> Array[String]:
	var values: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return values
	for item in value:
		values.append(String(item))
	return values


func _test_unlock_previews() -> void:
	var expected_labels := {
		"stage_1_1": ["火箭飞行马桶人", "装甲冲城马桶人"],
		"stage_1_3": ["装甲冲城马桶人"],
		"stage_1_5": ["火箭飞行马桶人"],
		"stage_2_3": ["自爆飞行马桶人"],
		"stage_2_5": ["维修马桶人"],
		"stage_3_3": ["寄生母体马桶人"],
		"stage_4_3": ["双锯重装马桶人"],
	}
	for stage_id in expected_labels.keys():
		var preview := String(StageCatalogScript.stage(String(stage_id)).get("unlock_preview", ""))
		_check(not preview.is_empty(), "%s has a non-empty key blueprint unlock preview" % stage_id)
		for label in expected_labels[stage_id]:
			_check(preview.contains(String(label)), "%s unlock preview mentions %s" % [stage_id, label])
	_check(String(StageCatalogScript.stage("stage_1_2").get("unlock_preview", "")) == "", "Non-unlock stages keep an empty unlock preview")
	_check(String(StageCatalogScript.stage("stage_5_5").get("unlock_preview", "")) == "", "Act I finale keeps an empty unlock preview")


func _release_roster() -> Array[Dictionary]:
	var archetypes: Array[String] = ["armored", "assault", "saw", "rocket", "repair", "parasite"]
	var classes: Array[String] = ["guardian", "fighter", "fighter", "ranger", "guardian", "arcanist"]
	var values: Array[Dictionary] = []
	for index in 6:
		values.append({
			"hero_id": "campaign_%d" % index,
			"display_name": archetypes[index],
			"archetype_id": archetypes[index],
			"class_id": classes[index],
			"star": 3,
			"max_hp": 320 if classes[index] == "guardian" else 235,
			"attack": 82,
			"defense": 34 if classes[index] == "guardian" else 23,
			"slot": index,
			"auto_skill": true,
		})
	return values


func _undertrained_roster() -> Array[Dictionary]:
	var values := _release_roster()
	for hero in values:
		hero["star"] = 1
		hero["max_hp"] = 145
		hero["attack"] = 34
		hero["defense"] = 11
		hero["auto_skill"] = false
	return values


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

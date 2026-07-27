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
	var display_names: Array[String] = []
	for stage_id in ids:
		var config := StageCatalogScript.stage(stage_id)
		_check(not config.is_empty(), "%s has a definition" % stage_id)
		_check(String(config.get("stage_id", "")) == stage_id, "%s identity is stable" % stage_id)
		var display_name := String(config.get("display_name", ""))
		_check(not display_name.is_empty(), "%s exposes a player-facing encounter name" % stage_id)
		_check(not display_names.has(display_name), "%s does not reuse another stage's encounter name" % stage_id)
		display_names.append(display_name)
		if stage_id == "stage_1_1":
			_check((config.get("enemies", []) as Array).is_empty(), "stage_1_1 has no alliance defenders")
			_check((config.get("structures", []) as Array).size() == 2, "stage_1_1 teaches obstacle then city destruction")
			_check(String((config.get("structures", []) as Array)[0].get("kind", "")) == "structure", "stage_1_1 opens with an abandoned barricade")
			_check(String((config.get("structures", []) as Array)[1].get("kind", "")) == "city", "stage_1_1 ends on the city target")
		elif stage_id == "stage_1_2":
			_check((config.get("enemies", []) as Array).size() == 2, "stage_1_2 introduces only two temporary alliance guards")
			_check((config.get("enemies", []) as Array).all(func(item: Dictionary) -> bool: return String(item.get("class_id", "")) == "ranger"), "stage_1_2 guards introduce remote pressure")
			_check((config.get("structures", []) as Array).size() == 1, "stage_1_2 still centers on one city")
		elif stage_id == "stage_1_3":
			_check((config.get("enemies", []) as Array).size() == 4, "stage_1_3 forms the first organized alliance")
			_check((config.get("structures", []) as Array).any(func(item: Dictionary) -> bool: return String(item.get("structure_id", "")) == "warning_turret"), "stage_1_3 introduces one weak warning turret")
		else:
			_check((config.get("enemies", []) as Array).size() >= 6, "%s has an enemy composition" % stage_id)
			_check((config.get("structures", []) as Array).size() >= 5, "%s has a three-phase structure route" % stage_id)
		_check(config.has("unlock_preview"), "%s exposes an unlock preview field" % stage_id)
		_check(config.has("defense_evolution"), "%s exposes defense evolution metadata" % stage_id)
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
			var expected_warning_ticks := 25 if int(config.get("chapter", 0)) == 1 else 20
			_check(
				int(config.get("cannon_warning_ticks", 0)) == expected_warning_ticks,
				"%s uses the authored %d-second boss cannon warning" % [stage_id, int(expected_warning_ticks / 5)]
			)
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
		while not session.is_finished and safety < 5000:
			session.advance_tick()
			safety += 1
		_check(session.is_finished, "%s resolves without relying on an attack countdown" % stage_id)
		_check(String(session.result.get("stage_id", "")) == stage_id, "%s result preserves stage identity" % stage_id)
		_check(["victory", "defeat"].has(String(session.result.get("outcome", ""))), "%s produces a valid outcome" % stage_id)
		_check(String(session.result.get("outcome", "")) == "victory", "%s is clearable by the documented three-star release roster" % stage_id)
	_check(chapter_feedback_values.size() == 5, "Act I has distinct chapter feedback for five chapters")
	_check(display_names.size() == 25, "all twenty-five Act I stages keep distinct player-facing identities")
	_check(recommendation_signatures.size() >= 5, "Act I recommendations differ across at least five chapter beats")
	_check(
		boss_suppression_targets.size() == 5
			and boss_suppression_targets[0] < boss_suppression_targets[1]
			and boss_suppression_targets[1] < boss_suppression_targets[2]
			and boss_suppression_targets[2] < boss_suppression_targets[3]
			and boss_suppression_targets[3] < boss_suppression_targets[4],
		"boss cannon suppression targets increase across Act I"
	)
	var chapter_two_counter := String(StageCatalogScript.stage("stage_2_1").get("counter_hint", ""))
	_check(chapter_two_counter.contains("永久军团"), "chapter two handoff preserves the permanent-hero formation model")
	_check(not chapter_two_counter.contains("六名小兵") and not chapter_two_counter.contains("回厂补"), "chapter two handoff removes the retired disposable-unit formation copy")
	_check(StageCatalogScript.breakthrough_reward("stage_1_2", false) == {"hero_shards": 4}, "first chapter introduces the first two-star breakthrough")
	for chapter in range(1, 6):
		var mid_stage := "stage_%d_3" % chapter
		var boss_stage := "stage_%d_5" % chapter
		_check(int(StageCatalogScript.breakthrough_reward(mid_stage, false)["hero_shards"]) == 4, "%s grants controlled mid-chapter shards" % mid_stage)
		_check(StageCatalogScript.breakthrough_reward(boss_stage, false) == {"hero_shards": 16}, "%s grants a full mastery breakthrough" % boss_stage)
		_check(StageCatalogScript.breakthrough_reward(boss_stage, true) == {"hero_shards": 0}, "%s breakthrough reward is first-clear only" % boss_stage)
	_test_opening_defense_curve()
	_test_unlock_previews()
	_check(StageCatalogScript.next_stage_id("stage_5_5") == "endless_1", "Act I finale continues into the endless frontier")
	var finale_modes: Array[String] = []
	for stage_number in range(1, 6):
		var finale_config := StageCatalogScript.stage("stage_5_%d" % stage_number)
		finale_modes.append(String(finale_config.get("finale_mode", "")))
		_check(int(finale_config.get("finale_limit", 0)) > 0, "finale stage %d has a finite authored mechanic cap" % stage_number)
	_check(
		finale_modes == ["retreat", "armor", "titan", "combined", "final_exam"],
		"the final chapter escalates through five distinct observable encounter jobs"
	)
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
	_check(stage_id in ["stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4"] or not recommended.is_empty(), "%s has an appropriate primary recommendation" % stage_id)
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
		"stage_1_4": "heavy.armored",
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
	for stage_id in StageCatalogScript.all_stage_ids():
		var config := StageCatalogScript.stage(stage_id)
		_check(String(config.get("unlock_preview", "")) == "", "%s does not advertise a stage blueprint drop" % stage_id)
		_check((config.get("unlock_on_victory", []) as Array).is_empty(), "%s victory does not unlock a blueprint" % stage_id)
		_check((config.get("unlock_on_defeat", []) as Array).is_empty(), "%s defeat does not unlock a blueprint" % stage_id)


func _test_opening_defense_curve() -> void:
	var expected_tiers: Array[String] = ["unguarded_city", "city_alarm", "alliance_militia", "turret_line"]
	var opening_power: Array[int] = []
	for index in expected_tiers.size():
		var stage_id := "stage_1_%d" % (index + 1)
		var config := StageCatalogScript.stage(stage_id)
		var defense := config.get("defense_evolution", {}) as Dictionary
		_check(String(defense.get("tier", "")) == expected_tiers[index], "%s advances the opening defense tier" % stage_id)
		_check(not (defense.get("features", []) as Array).is_empty(), "%s names visible defense features" % stage_id)
		var has_turret := (config.get("structures", []) as Array).any(
			func(item: Dictionary) -> bool: return String(item.get("kind", "")) in ["turret", "battery"]
		)
		if index < 2:
			_check(not has_turret, "%s does not introduce fixed turret fire early" % stage_id)
		elif index == 2:
			_check(has_turret, "stage_1_3 previews turret fire with a weak warning emplacement")
		else:
			_check(has_turret, "stage_1_4 visibly upgrades the warning shot into the first turret wall")
		opening_power.append(int(config.get("power_bp", 0)))
	_check(opening_power[0] < opening_power[1] and opening_power[1] < opening_power[2], "opening three stages rise gently")
	_check(opening_power[3] > opening_power[2], "stage 1-4 keeps a higher three-unit combat load than stage 1-3")
	_check(int(StageCatalogScript.stage("stage_1_4").get("solo_pressure_bp", 10000)) >= 20000, "stage 1-4 creates the intended solo turret power wall")
	_check(int(StageCatalogScript.stage("stage_1_4").get("factory_production_target", 0)) == 0, "stage 1-4 does not require a legacy nine-unit merge batch")
	_check((StageCatalogScript.stage("stage_1_4").get("unlock_on_victory", []) as Array).is_empty(), "stage 1-4 does not drop the armored blueprint")
	var wall_counter := String(StageCatalogScript.stage("stage_1_4").get("counter_hint", ""))
	_check(wall_counter.contains("1-2、1-3") and wall_counter.contains("图纸") and wall_counter.contains("研究所"), "stage 1-4 reconnaissance names the stage-blueprint-to-research recovery")
	_check(wall_counter.contains("永久") and wall_counter.contains("装甲") and wall_counter.contains("冲锋"), "stage 1-4 reconnaissance explains the permanent two-role counter")
	_check(wall_counter.contains("图纸") and not wall_counter.contains("生产 9") and not wall_counter.contains("三合一"), "stage 1-4 reconnaissance uses the new blueprint research path")
	var boss_counter := String(StageCatalogScript.stage("stage_1_5").get("counter_hint", ""))
	_check(boss_counter.contains("冲锋马桶人升到二星") and boss_counter.contains("装甲马桶人升到二星"), "stage 1-5 reconnaissance preserves both verified mastery routes")
	var boss_recommendations := _string_array(StageCatalogScript.stage("stage_1_5").get("recommended_recipe_ids", []))
	_check(boss_recommendations == ["heavy.armored", "ordinary.assault"], "stage 1-5 recommendations contain only the two verified first-growth heroes")


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

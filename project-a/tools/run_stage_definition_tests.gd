extends SceneTree

const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const StageDefinitionCatalogScript := preload("res://game/scripts/content/stage_definition_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	var validation_errors := StageDefinitionCatalogScript.validate_all()
	_check(validation_errors.is_empty(), "typed stage definitions validate: %s" % ", ".join(validation_errors))
	var expected := {
		"stage_1_1": [1950, 6200, 10000],
		"stage_1_2": [2000, 7200, 10000],
		"stage_1_3": [2020, 8400, 13000],
		"stage_1_4": [5700, 9000, 22000],
		"stage_1_5": [6500, 10750, 10000],
	}
	for stage_id in expected:
		var definition: Resource = StageDefinitionCatalogScript.definition(stage_id)
		var config := StageCatalogScript.stage(stage_id)
		_check(definition != null, "%s has a typed authored definition" % stage_id)
		_check(int(config.get("recommended_power", 0)) == int(expected[stage_id][0]), "%s recommendation comes from authored content" % stage_id)
		_check(int(config.get("enemy_power_bp", 0)) == int(expected[stage_id][1]), "%s enemy multiplier remains inspectable" % stage_id)
		_check(int(config.get("solo_pressure_bp", 0)) == int(expected[stage_id][2]), "%s solo pressure remains inspectable" % stage_id)
		_check(String(config.get("threat_summary", "")).strip_edges() != "", "%s owns player-facing threat copy" % stage_id)
		_check(String(config.get("counter_hint", "")).strip_edges() != "", "%s owns player-facing counter copy" % stage_id)
	var boss := StageCatalogScript.stage("stage_1_5")
	var opening := StageCatalogScript.stage("stage_1_1")
	_check(int(opening.get("structure_hp_bp", 0)) == 9500, "opening effective durability multiplier is authored")
	_check(int(boss.get("structure_hp_bp", 0)) == 8500, "boss effective durability multiplier is authored")
	if failures.is_empty():
		print("STAGE_DEFINITION_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("STAGE_DEFINITION_TESTS_FAIL: %d" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

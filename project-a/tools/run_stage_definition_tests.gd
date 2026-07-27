extends SceneTree

const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const StageDefinitionCatalogScript := preload("res://game/scripts/content/stage_definition_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	var validation_errors := StageDefinitionCatalogScript.validate_all()
	_check(validation_errors.is_empty(), "typed stage definitions validate: %s" % ", ".join(validation_errors))
	var expected := {
		"stage_1_1": [1650, 6200, 10000],
		"stage_1_2": [1650, 7200, 10000],
		"stage_1_3": [1650, 8400, 13000],
		"stage_1_4": [5000, 9000, 22000],
		"stage_1_5": [5400, 10750, 10000],
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
	_check_early_camera_archetypes_are_stable()
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


func _check_early_camera_archetypes_are_stable() -> void:
	var signatures: Dictionary = {}
	for stage_number in range(2, 6):
		var stage_id := "stage_1_%d" % stage_number
		var config := StageCatalogScript.stage(stage_id)
		for enemy_value in config.get("enemies", []):
			var enemy := enemy_value as Dictionary
			var archetype_id := String(enemy.get("archetype_id", ""))
			_check(not archetype_id.is_empty(), "%s enemy exposes a stable archetype id" % stage_id)
			var signature := [
				String(enemy.get("display_name", "")),
				String(enemy.get("class_id", "")),
				int(enemy.get("max_hp", enemy.get("hp", 0))),
				int(enemy.get("attack", 0)),
				int(enemy.get("defense", 0)),
				int(enemy.get("range", 0)),
				int(enemy.get("attack_period_ticks", 0)),
			]
			if signatures.has(archetype_id):
				_check(
					signatures[archetype_id] == signature,
					"%s keeps one stat line across early stages" % archetype_id
				)
			else:
				signatures[archetype_id] = signature

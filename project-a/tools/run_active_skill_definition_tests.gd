extends SceneTree

const ActiveSkillCatalogScript := preload("res://game/scripts/content/active_skill_catalog.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for error in ActiveSkillCatalogScript.validate_all():
		_check(false, String(error))
	_check(
		ActiveSkillCatalogScript.DEFINITIONS.size() == FactoryCatalogScript.archetypes().size(),
		"catalog contains one active skill for every archetype"
	)
	for archetype_id in FactoryCatalogScript.archetypes():
		var skill_id := FactoryCatalogScript.active_skill_for_archetype(String(archetype_id))
		var view := ActiveSkillCatalogScript.view(skill_id)
		_check(not view.is_empty(), "%s resolves a player-facing skill" % archetype_id)
		_check(String(view.get("display_name", "")) != skill_id, "%s does not expose its internal ID" % skill_id)
		_check(not String(view.get("effect_copy", "")).is_empty(), "%s explains its effect" % skill_id)
		_check(not String(view.get("timing_copy", "")).is_empty(), "%s explains its timing" % skill_id)
		view["display_name"] = "被测试修改"
		_check(
			String(ActiveSkillCatalogScript.view(skill_id).get("display_name", "")) != "被测试修改",
			"%s view is detached from authored content" % skill_id
		)
	_check(ActiveSkillCatalogScript.view("unknown_skill").is_empty(), "unknown skill fails closed")
	if failures.is_empty():
		print("ACTIVE_SKILL_DEFINITION_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

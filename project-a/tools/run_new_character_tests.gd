extends SceneTree

const ActiveSkillCatalogScript := preload("res://game/scripts/content/active_skill_catalog.gd")
const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactionCatalogScript := preload("res://game/scripts/domain/content/faction_catalog.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const SignalRecruitServiceScript := preload("res://game/scripts/domain/recruitment/signal_recruit_service.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

const CASES: Array[Dictionary] = [
	{"id": "signal_purifier", "class": "arcanist", "skill": "signal_cleanse", "metric": "purifier_cleanse_targets"},
	{"id": "anchor_bastion", "class": "guardian", "skill": "formation_anchor", "metric": "anchor_protected_targets"},
	{"id": "magnetic_conductor", "class": "ranger", "skill": "magnetic_convergence", "metric": "magnetic_grouped_targets"},
	{"id": "phase_tunneler", "class": "fighter", "skill": "phase_breach", "metric": "phase_backline_hits"},
	{"id": "protocol_weaver", "class": "arcanist", "skill": "protocol_hijack", "metric": "protocol_hijack_targets"},
	{"id": "ram_breaker", "class": "fighter", "skill": "ram_shatter", "metric": "new_character_effects"},
	{"id": "smoke_screen", "class": "arcanist", "skill": "caustic_smokescreen", "metric": "new_character_effects"},
	{"id": "mortar", "class": "ranger", "skill": "sewer_mortar", "metric": "new_character_effects"},
	{"id": "interceptor", "class": "ranger", "skill": "warning_intercept", "metric": "new_character_effects"},
	{"id": "bulwark", "class": "guardian", "skill": "linked_bulwark", "metric": "new_character_effects"},
	{"id": "crusher", "class": "fighter", "skill": "hydraulic_crush", "metric": "new_character_effects"},
	{"id": "echo_mimic", "class": "arcanist", "skill": "allied_echo", "metric": "new_character_effects"},
	{"id": "drain_engine", "class": "guardian", "skill": "energy_siphon", "metric": "new_character_effects"},
	{"id": "swarm_beacon", "class": "arcanist", "skill": "decoy_bloom", "metric": "new_character_effects"},
	{"id": "chronolock", "class": "arcanist", "skill": "chrono_lock", "metric": "new_character_effects"},
]

var failures: Array[String] = []


func _init() -> void:
	for case in CASES:
		_test_character(case)
	if failures.is_empty():
		print("NEW_CHARACTER_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_character(case: Dictionary) -> void:
	var archetype_id := String(case["id"])
	var recipe := FactoryCatalogScript.recipe_for_archetype(archetype_id)
	_check(not recipe.is_empty(), "%s has a production recipe" % archetype_id)
	_check(
		(SignalRecruitServiceScript.POOLS[String(recipe.get("rating", "B"))] as Array).has(archetype_id),
		"%s is in the matching live recruit pool" % archetype_id
	)
	_check(not FactionCatalogScript.faction_for(archetype_id).is_empty(), "%s has a faction" % archetype_id)
	_check(
		String(FactoryCatalogScript.active_skill_for_archetype(archetype_id)) == String(case["skill"]),
		"%s maps to its authored active skill" % archetype_id
	)
	_check(not ActiveSkillCatalogScript.view(String(case["skill"])).is_empty(), "%s has player-facing skill copy" % archetype_id)
	var hero: RefCounted = HeroGeneratorScript.generate_archetype(20260728, 1, archetype_id, String(case["class"]))
	_check(String(hero.archetype_id) == archetype_id, "%s can be generated as a permanent hero" % archetype_id)
	var session: RefCounted = BattleSessionScript.new()
	session.start([{
		"hero_id": "probe_%s" % archetype_id,
		"display_name": HeroGeneratorScript.archetype_display_name(archetype_id),
		"archetype_id": archetype_id,
		"class_id": String(case["class"]),
		"star": 3,
		"max_hp": 900,
		"attack": 120,
		"defense": 45,
		"speed_milli": 100000,
		"crit_bp": 1000,
		"skill_level": 3,
	}], "stage_4_4", StageCatalogScript.stage("stage_4_4"))
	_check(not session.is_finished, "%s is accepted by BattleSession" % archetype_id)
	session._units[0]["energy"] = BattleSessionScript.SKILL_COST
	_check(session.request_skill(session._units[0]["unit_id"]), "%s accepts a manual skill request" % archetype_id)
	var events: Array[Dictionary] = session.advance_tick()
	var found_skill_event := false
	for event in events:
		if (
			String(event.get("type", "")) == "skill_used"
			and String(event.get("skill_id", "")) == String(case["skill"])
		):
			found_skill_event = true
			break
	_check(found_skill_event, "%s emits its real skill event" % archetype_id)
	var result_probe := session._finish_result(false, "probe") as Dictionary
	_check(int(result_probe.get(String(case["metric"]), 0)) > 0, "%s records its qualitative battle metric" % archetype_id)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

extends SceneTree

const ActiveSkillCatalogScript := preload("res://game/scripts/content/active_skill_catalog.gd")
const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactionCatalogScript := preload("res://game/scripts/domain/content/faction_catalog.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const SignalRecruitServiceScript := preload("res://game/scripts/domain/recruitment/signal_recruit_service.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

const CASES: Array[Dictionary] = [
	{"id": "signal_purifier", "class": "arcanist", "skill": "signal_cleanse", "metric": "purifier_cleanse_targets"},
	{"id": "anchor_bastion", "class": "guardian", "skill": "formation_anchor", "metric": "anchor_protected_targets"},
	{"id": "magnetic_conductor", "class": "ranger", "skill": "magnetic_convergence", "metric": "magnetic_grouped_targets"},
	{"id": "phase_tunneler", "class": "fighter", "skill": "phase_breach", "metric": "phase_backline_hits"},
	{"id": "protocol_weaver", "class": "arcanist", "skill": "protocol_hijack", "metric": "protocol_hijack_targets"},
	{"id": "ram_breaker", "class": "fighter", "skill": "ram_shatter", "metric": "new_character_effects", "first_hour": true},
	{"id": "smoke_screen", "class": "arcanist", "skill": "caustic_smokescreen", "metric": "new_character_effects", "first_hour": true},
	{"id": "mortar", "class": "ranger", "skill": "sewer_mortar", "metric": "new_character_effects", "first_hour": true},
	{"id": "interceptor", "class": "ranger", "skill": "warning_intercept", "metric": "new_character_effects", "first_hour": true},
	{"id": "bulwark", "class": "guardian", "skill": "linked_bulwark", "metric": "new_character_effects", "first_hour": true},
	{"id": "crusher", "class": "fighter", "skill": "hydraulic_crush", "metric": "new_character_effects", "first_hour": true},
	{"id": "echo_mimic", "class": "arcanist", "skill": "allied_echo", "metric": "new_character_effects", "first_hour": true},
	{"id": "drain_engine", "class": "guardian", "skill": "energy_siphon", "metric": "new_character_effects", "first_hour": true},
	{"id": "swarm_beacon", "class": "arcanist", "skill": "decoy_bloom", "metric": "new_character_effects", "first_hour": true},
	{"id": "chronolock", "class": "arcanist", "skill": "chrono_lock", "metric": "new_character_effects", "first_hour": true},
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
	if bool(case.get("first_hour", false)):
		var rating := String(recipe.get("rating", "B"))
		var first_hour_pool := (
			SignalRecruitServiceScript.FACTION_CORE_POOLS.get(rating, [])
			if rating in ["B", "A"]
			else SignalRecruitServiceScript.POOLS.get(rating, [])
		) as Array
		_check(
			first_hour_pool.has(archetype_id),
			"%s is obtainable from the first-hour signal route" % archetype_id
		)
		_test_first_hour_stars(case)
		_test_save_roundtrip(case, hero, recipe)
		return
	_test_skill_cast(case, 3, "stage_4_4")


func _test_first_hour_stars(case: Dictionary) -> void:
	for star in [1, 2, 3]:
		_test_skill_cast(case, star, "stage_2_4")


func _test_skill_cast(case: Dictionary, star: int, stage_id: String) -> void:
	var archetype_id := String(case["id"])
	var session: RefCounted = BattleSessionScript.new()
	session.start([{
		"hero_id": "probe_%s" % archetype_id,
		"display_name": HeroGeneratorScript.archetype_display_name(archetype_id),
		"archetype_id": archetype_id,
		"class_id": String(case["class"]),
		"star": star,
		"max_hp": 900,
		"attack": 120,
		"defense": 45,
		"speed_milli": 100000,
		"crit_bp": 1000,
		"skill_level": 3,
	}], stage_id, StageCatalogScript.stage(stage_id))
	_check(not session.is_finished, "%s %d-star is accepted in the first-hour battle" % [archetype_id, star])
	session._units[0]["energy"] = BattleSessionScript.SKILL_COST
	_check(session.request_skill(session._units[0]["unit_id"]), "%s %d-star accepts a manual skill request" % [archetype_id, star])
	var events: Array[Dictionary] = session.advance_tick()
	var found_skill_event := false
	for event in events:
		if (
			String(event.get("type", "")) == "skill_used"
			and String(event.get("skill_id", "")) == String(case["skill"])
		):
			found_skill_event = true
			break
	_check(found_skill_event, "%s %d-star emits its real skill event" % [archetype_id, star])
	var result_probe := session._finish_result(false, "probe") as Dictionary
	_check(int(result_probe.get(String(case["metric"]), 0)) > 0, "%s %d-star records its qualitative battle metric" % [archetype_id, star])


func _test_save_roundtrip(case: Dictionary, hero: RefCounted, recipe: Dictionary) -> void:
	var archetype_id := String(case["id"])
	var state: RefCounted = GameStateScript.create_new(20260729, 1000, false)
	hero.hero_id = "first_hour_%s" % archetype_id
	state.roster.append(hero)
	state.factory.discovered_blueprints[String(recipe["recipe_id"])] = true
	state.meta_progression.hero_fragments[archetype_id] = int(
		SignalRecruitServiceScript.DUPLICATE_FRAGMENTS[String(recipe["rating"])]
	)
	state.formation.slots["troop_1"] = hero.hero_id
	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(state))
	_check(bool(decoded.get("ok", false)), "%s first-hour save roundtrip decodes" % archetype_id)
	if not bool(decoded.get("ok", false)):
		return
	var restored: RefCounted = decoded["state"]
	_check(restored.hero_by_id(hero.hero_id) != null, "%s permanent hero survives save" % archetype_id)
	_check(
		bool(restored.factory.discovered_blueprints.get(String(recipe["recipe_id"]), false)),
		"%s blueprint survives save" % archetype_id
	)
	_check(
		int(restored.meta_progression.hero_fragments.get(archetype_id, 0))
			== int(SignalRecruitServiceScript.DUPLICATE_FRAGMENTS[String(recipe["rating"])]),
		"%s fragments survive save" % archetype_id
	)
	_check(String(restored.formation.slots["troop_1"]) == hero.hero_id, "%s formation survives save" % archetype_id)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

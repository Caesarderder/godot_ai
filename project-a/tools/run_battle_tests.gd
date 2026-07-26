extends SceneTree

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const TEST_SAFETY_TICKS: int = 5000

var failures: Array[String] = []


func _init() -> void:
	_test_requires_one_to_seven_known_archetypes()
	_test_three_layer_siege_with_enemy_contact()
	_test_manual_and_auto_skill_contract()
	_test_damage_energy_normalization()
	_test_eight_archetype_skill_families()
	_test_star_tiers_change_skill_output()
	_test_active_skill_research_scales_skill_output()
	_test_core_cannon_and_destruction_feedback()
	_test_opening_warning_turret_teaches_the_signal()
	_test_boss_cannon_suppression_window()
	_test_boss_cannon_suppression_high_output()
	_test_boss_cannon_low_output_impacts()
	_test_normal_stage_has_no_suppressible_warning()
	_test_boss_cannon_determinism()
	_test_same_input_same_result()
	_test_battle_has_no_time_limit()
	_test_act_one_stage_catalog_and_config_start()
	if failures.is_empty():
		print("BATTLE TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("BATTLE TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _test_damage_energy_normalization() -> void:
	_check(BattleSessionScript.damage_energy_gain(0, 200) == 0, "zero health damage grants no energy")
	_check(BattleSessionScript.damage_energy_gain(1, 200) == 1, "chip damage grants the minimum one energy")
	_check(BattleSessionScript.damage_energy_gain(10, 200) == 5, "damage energy scales with lost max-health percentage")
	_check(BattleSessionScript.damage_energy_gain(100, 200) == 10, "one hit cannot exceed the damage-energy cap")
	var session: RefCounted = BattleSessionScript.new()
	var config := StageCatalogScript.stage("stage_1_3")
	session.start(_siege_heroes().slice(0, 1), "stage_1_3", config)
	var energy_by_second: Dictionary = {}
	var received_energy := 0
	while not session.is_finished:
		for event in session.advance_tick():
			var gain := int(event.get("energy_gain", 0))
			if gain <= 0:
				continue
			var second := int(event.get("tick", 0)) / BattleSessionScript.TICKS_PER_SECOND
			energy_by_second[second] = int(energy_by_second.get(second, 0)) + gain
			received_energy += gain
	_check(received_energy > 0, "taking health damage contributes deterministic skill energy")
	for second in energy_by_second:
		_check(
			int(energy_by_second[second]) <= BattleSessionScript.DAMAGE_ENERGY_PER_SECOND_CAP,
			"damage energy respects the per-second anti-multihit cap"
		)


func _test_requires_one_to_seven_known_archetypes() -> void:
	var empty_session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(empty_session, [])
	_check(empty_session.is_finished, "empty formation is rejected immediately")
	_check(String(empty_session.result.get("reason", "")) == "invalid_formation", "empty formation exposes invalid_formation")
	var short_session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(short_session, _siege_heroes().slice(0, 5))
	_check(not short_session.is_finished, "five-unit army is valid during gradual factory growth")
	_check((short_session.snapshot().get("units", []) as Array).size() == 5, "variable army contains only explicitly deployed units")
	var unknown_session: RefCounted = BattleSessionScript.new()
	var bad := _siege_heroes()
	bad[0]["archetype_id"] = "not_a_toilet"
	_start_standard_battle(unknown_session, bad)
	_check(unknown_session.is_finished, "unknown archetype is rejected")
	_check(String(unknown_session.result.get("reason", "")) == "unknown_archetype", "unknown archetype is explicit, not silently mapped to a fallback skill")


func _test_three_layer_siege_with_enemy_contact() -> void:
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, _siege_heroes())
	for hero in _siege_heroes():
		session.set_auto_skill(StringName(hero["hero_id"]), true)
	var stages: Array[int] = [0]
	var destroyed: Array[String] = []
	var enemy_contact_seen := false
	var elite_seen := false
	var structure_damage_seen_after_enemy := false
	var core_layers_respected := true
	while not session.is_finished:
		for event in session.advance_tick():
			if event["type"] == &"stage_changed":
				stages.append(int(event["stage_index"]))
			elif event["type"] == &"structure_destroyed":
				destroyed.append(String(event["structure_id"]))
				structure_damage_seen_after_enemy = structure_damage_seen_after_enemy or enemy_contact_seen
			elif event["type"] == &"enemy_damaged":
				enemy_contact_seen = true
			elif event["type"] == &"enemy_defeated" and bool(event.get("elite", false)):
				elite_seen = true
		var live_snapshot: Dictionary = session.snapshot()
		var left_battery := _snapshot_structure(live_snapshot, "left_battery")
		var right_battery := _snapshot_structure(live_snapshot, "right_battery")
		var core_armor := _snapshot_structure(live_snapshot, "core_armor")
		var core := _snapshot_structure(live_snapshot, "alliance_core")
		if not core_armor.is_empty() and int(core_armor["hp"]) < int(core_armor["max_hp"]):
			core_layers_respected = core_layers_respected and not bool(left_battery["alive"]) and not bool(right_battery["alive"])
		if not core.is_empty() and int(core["hp"]) < int(core["max_hp"]):
			core_layers_respected = core_layers_respected and not bool(left_battery["alive"]) and not bool(right_battery["alive"]) and not bool(core_armor["alive"])
	var final_snapshot: Dictionary = session.snapshot()
	_check(String(session.result.get("outcome", "")) == "victory", "six-unit archetype squad completes the siege")
	_check(stages == [0, 1, 2], "battle advances through outskirts, fire zone, then base plaza")
	_check(enemy_contact_seen, "battle has unit-vs-unit contact before pure structure race")
	_check(elite_seen, "battle includes and defeats an alliance elite")
	_check(structure_damage_seen_after_enemy, "facility breakthrough happens after enemy contact")
	_check(destroyed.size() == 7, "all seven defensive modules are destroyed")
	_check(destroyed.front() == "outer_barricade", "outer barricade is the first blocking structure")
	_check(destroyed.back() == "alliance_core", "alliance core is the final target")
	_check(core_layers_respected, "stage-three AOE cannot damage batteries, core armor, and alliance core out of order")
	_check(int(session.result.get("ticks", 0)) > 0, "completed battle records its elapsed ticks without using them as a failure condition")
	_check(int(session.result.get("ally_damage_taken", 0)) > 0, "battle result exposes actual allied health damage")
	_check(
		int(session.result.get("troop_damage_taken", 0)) <= int(session.result.get("ally_damage_taken", 0)),
		"troop damage is a bounded subset of all allied damage"
	)
	var contribution := session.result.get("ally_damage_dealt_by_unit", {}) as Dictionary
	var recorded_damage := 0
	for unit_damage in contribution.values():
		recorded_damage += int(unit_damage)
	_check(recorded_damage > 0, "battle result exposes per-hero contribution for the result screen")
	_check(contribution.has("hero_0"), "deployed hero ids remain stable contribution keys")
	_check(int(final_snapshot.get("road_progress", 0)) <= BattleSessionScript.ROAD_END, "road progress remains in integer road bounds")
	_check((final_snapshot.get("enemies", []) as Array).size() >= 8, "enemy snapshots are separated from six ally HUD units")


func _test_manual_and_auto_skill_contract() -> void:
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, _six_of("assault", 1))
	_check(not session.request_skill(&"hero_0"), "skill cannot be requested before energy is full")
	var ready_unit: StringName = &""
	var skill_used_before_request := false
	while ready_unit == &"" and not session.is_finished:
		for event in session.advance_tick():
			if event["type"] == &"skill_used":
				skill_used_before_request = true
			if event["type"] == &"skill_ready":
				ready_unit = event["unit_id"]
	_check(not skill_used_before_request, "auto skill defaults to false")
	_check(ready_unit != &"", "a manual-test unit reaches full energy")
	_check(session.request_skill(ready_unit), "full-energy manual request is accepted")
	var manual_used := false
	for event in session.advance_tick():
		if event["type"] == &"skill_used" and event["unit_id"] == ready_unit:
			manual_used = true
	_check(manual_used, "manual skill request releases on the next deterministic tick")

	var auto_session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(auto_session, _siege_heroes())
	_check(auto_session.set_auto_skill(&"hero_1", true), "auto skill can be enabled per unit")
	var auto_used := false
	while not auto_session.is_finished and not auto_used:
		for event in auto_session.advance_tick():
			if event["type"] == &"skill_used" and event["unit_id"] == &"hero_1":
				auto_used = true
	_check(auto_used, "enabled auto skill releases after energy fills")


func _test_active_skill_research_scales_skill_output() -> void:
	var level_one_heroes := _mechanic_heroes("assault", 1)
	level_one_heroes[0]["skill_level"] = 1
	var level_three_heroes := _mechanic_heroes("assault", 1)
	level_three_heroes[0]["skill_level"] = 3
	var level_one_damage := _first_skill_damage(level_one_heroes)
	var level_three_damage := _first_skill_damage(level_three_heroes)
	_check(level_one_damage > 0, "level-one active skill produces measurable combat output")
	_check(level_three_damage > level_one_damage, "researched active skill level increases deterministic skill output")


func _first_skill_damage(heroes: Array[Dictionary]) -> int:
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, heroes)
	_check(session.request_skill(&"hero_0"), "full-energy research probe accepts the active skill")
	var total := 0
	for event in session.advance_tick():
		if not bool(event.get("is_skill", false)):
			continue
		if event.get("type") in [&"attack_hit", &"structure_damaged"]:
			total += int(event.get("damage", 0))
	return total


func _test_eight_archetype_skill_families() -> void:
	var expected := {
		"assault": "plunger_charge",
		"sonic": "sonic_disruptor",
		"rocket": "rocket_salvo",
		"bomber": "suicide_dive",
		"armored": "siege_shield",
		"saw": "saw_rush",
		"repair": "field_repair",
		"parasite": "parasite_swarm",
	}
	for archetype_id in expected.keys():
		_check(FactoryCatalogScript.active_skill_for_archetype(archetype_id) == expected[archetype_id], "%s has canonical skill metadata" % archetype_id)
		var session: RefCounted = BattleSessionScript.new()
		_start_standard_battle(session, _six_of(archetype_id, 2))
		for hero in _six_of(archetype_id, 2):
			session.set_auto_skill(StringName(hero["hero_id"]), true)
		var used := false
		var safety := 0
		while not session.is_finished and not used and safety < TEST_SAFETY_TICKS:
			safety += 1
			for event in session.advance_tick():
				if event["type"] == &"skill_used":
					used = used or String(event["skill_id"]) == expected[archetype_id]
		_check(used, "%s uses its own archetype skill instead of a four-class folded skill" % archetype_id)
		var resolved := _first_skill_event(_mechanic_heroes(archetype_id, 2), &"hero_0")
		var has_effect := (
			int(resolved.get("skill_target_hits", 0)) > 0
			or int(resolved.get("total_shield", 0)) > 0
			or int(resolved.get("allies_healed", 0)) > 0
			or int(resolved.get("units_summoned", 0)) > 0
			or int(resolved.get("units_converted", 0)) > 0
		)
		_check(has_effect, "%s canonical skill resolves a measurable mechanic, not only skill_used metadata" % archetype_id)


func _test_star_tiers_change_skill_output() -> void:
	var star1 := _first_skill_event(_six_of("armored", 1), &"hero_0")
	var star2 := _first_skill_event(_six_of("armored", 2), &"hero_0")
	var star3 := _first_skill_event(_six_of("armored", 3), &"hero_0")
	_check(int(star1.get("skill_tier", 0)) == 1, "1-star skill emits tier 1")
	_check(int(star2.get("skill_tier", 0)) == 2, "2-star skill emits tier 2")
	_check(int(star3.get("skill_tier", 0)) == 3, "3-star skill emits tier 3")
	_check(int(star3.get("total_shield", 0)) > int(star1.get("total_shield", 0)), "3-star siege shield creates stronger measurable shield than 1-star")
	var assault1 := _first_skill_event(_mechanic_heroes("assault", 1), &"hero_0")
	var assault2 := _first_skill_event(_mechanic_heroes("assault", 2), &"hero_0")
	var assault3 := _first_skill_event(_mechanic_heroes("assault", 3), &"hero_0")
	_check(int(assault2.get("skill_enemy_hits", 0)) > int(assault1.get("skill_enemy_hits", 0)), "2-star assault adds a cleave target instead of only scaling damage")
	_check(int(assault3.get("enemy_stunned", 0)) > 0, "3-star assault adds crowd-control")
	var rocket1 := _first_skill_event(_mechanic_heroes("rocket", 1), &"hero_0")
	var rocket2 := _first_skill_event(_mechanic_heroes("rocket", 2), &"hero_0")
	_check(int(rocket2.get("skill_target_hits", 0)) > int(rocket1.get("skill_target_hits", 0)), "2-star rocket changes from single-target to area salvo")
	var sonic1 := _first_skill_event(_mechanic_heroes("sonic", 1), &"hero_0")
	var sonic2 := _first_skill_event(_mechanic_heroes("sonic", 2), &"hero_0")
	var sonic3 := _first_skill_event(_mechanic_heroes("sonic", 3), &"hero_0")
	_check(int(sonic2.get("enemies_weakened", 0)) > int(sonic1.get("enemies_weakened", 0)), "2-star sonic expands disruption across lanes")
	_check(int(sonic3.get("enemy_stunned", 0)) > 0, "3-star sonic adds control to basic defenders")
	var bomber1 := _first_skill_event(_mechanic_heroes("bomber", 1), &"hero_0")
	var bomber2 := _first_skill_event(_mechanic_heroes("bomber", 2), &"hero_0")
	var bomber3 := _first_skill_event(_mechanic_heroes("bomber", 3), &"hero_0")
	_check(int(bomber2.get("skill_target_hits", 0)) > int(bomber1.get("skill_target_hits", 0)), "2-star bomber adds area damage")
	_check(int(bomber3.get("caster_hp", 0)) > int(bomber2.get("caster_hp", 0)), "3-star bomber removes self-damage")
	var saw_values := _mechanic_heroes("saw", 3)
	saw_values[0]["attack"] = 500
	var saw3 := _first_skill_event(saw_values, &"hero_0")
	var saw1_values := _mechanic_heroes("saw", 1)
	var saw2_values := _mechanic_heroes("saw", 2)
	saw1_values[0]["attack"] = 10
	saw2_values[0]["attack"] = 10
	var saw1 := _first_skill_event(saw1_values, &"hero_0")
	var saw2 := _first_skill_event(saw2_values, &"hero_0")
	_check(int(saw2.get("skill_enemy_hits", 0)) > int(saw1.get("skill_enemy_hits", 0)), "2-star saw adds a second strike to its priority target")
	_check(int(saw3.get("caster_energy", 0)) == 55, "3-star saw refunds energy after a skill kill")
	var repair1 := _first_skill_event(_mechanic_heroes("repair", 1), &"hero_0")
	var repair2 := _first_skill_event(_mechanic_heroes("repair", 2), &"hero_0")
	_check(int(repair2.get("allies_healed", 0)) > int(repair1.get("allies_healed", 0)), "2-star repair changes from one target to three targets")
	_check(_repair_restores_actual_hp(), "repair skill restores missing HP in a real combat state")
	_check(_repair_revives_fallen(), "3-star repair revives one fallen permanent ally")
	var parasite1 := _first_skill_event(_mechanic_heroes("parasite", 1), &"hero_0")
	var parasite2 := _first_skill_event(_mechanic_heroes("parasite", 2), &"hero_0")
	var parasite3 := _first_skill_event(_mechanic_heroes("parasite", 3), &"hero_0")
	_check(int(parasite2.get("units_summoned", 0)) > int(parasite1.get("units_summoned", 0)), "2-star parasite changes summon count")
	_check(int(parasite3.get("units_converted", 0)) > 0, "3-star parasite converts a basic alliance defender")


func _test_core_cannon_and_destruction_feedback() -> void:
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, _siege_heroes())
	for hero in _siege_heroes():
		session.set_auto_skill(StringName(hero["hero_id"]), true)
	var warning_seen := false
	var impact_seen := false
	var explosion_seen := false
	var structure_damage_seen := false
	while not session.is_finished:
		for event in session.advance_tick():
			warning_seen = warning_seen or event["type"] == &"artillery_warning"
			impact_seen = impact_seen or event["type"] == &"artillery_impact"
			explosion_seen = explosion_seen or event["type"] == &"explosion"
			structure_damage_seen = structure_damage_seen or event["type"] == &"structure_damaged"
	_check(warning_seen, "core cannon emits a readable warning")
	_check(impact_seen, "core cannon warning resolves into an impact")
	_check(explosion_seen, "destruction and cannon impacts emit lightweight explosion events")
	_check(structure_damage_seen, "structure damage is exposed as presentation events")


func _test_opening_warning_turret_teaches_the_signal() -> void:
	var session: RefCounted = BattleSessionScript.new()
	var config := StageCatalogScript.stage("stage_1_3")
	session.start(_siege_heroes().slice(0, 1), "stage_1_3", config)
	session._stage_index = 1
	for structure in session._structures:
		if String(structure.get("structure_id", "")) == "warning_turret":
			structure["stage"] = 1
	session.tick_index = 5
	var events: Array[Dictionary] = session.advance_tick()
	var warning := _first_event(events, &"artillery_warning")
	_check(not warning.is_empty(), "stage 1-3 light turret emits the player's first artillery warning")
	_check(String(warning.get("source_structure_id", "")) == "warning_turret", "opening warning identifies the weak teaching turret")
	_check(int(warning.get("impact_tick", 0)) - int(warning.get("tick", 0)) == 2, "opening warning provides a short readable fuse")
	_check((session.snapshot().get("warnings", []) as Array).is_empty(), "teaching warning does not masquerade as a suppressible boss cannon")


func _test_same_input_same_result() -> void:
	var first := _run_to_result(_siege_heroes())
	var second := _run_to_result(_siege_heroes())
	_check(first == second, "same six-unit snapshot produces the same result")


func _test_battle_has_no_time_limit() -> void:
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, _siege_heroes())
	session.tick_index = 100000
	session.advance_tick()
	_check(not session.is_finished, "elapsed ticks never end a living battle")
	_check(not session.snapshot().has("max_ticks"), "battle snapshot exposes no attack countdown")


func _test_act_one_stage_catalog_and_config_start() -> void:
	_check(StageCatalogScript.all_stage_ids().size() == 25, "act one catalog exposes twenty-five stages")
	_check(StageCatalogScript.has_stage("stage_5_5"), "act one catalog includes final 5-5")
	var config := StageCatalogScript.stage("stage_2_5")
	_check(String(config.get("stage_id", "")) == "stage_2_5", "stage catalog returns requested stage id")
	_check(not config.has("max_ticks"), "stage definitions do not contain attack time limits")
	_check((config.get("enemies", []) as Array).size() >= 6, "stage config owns enemy content")
	_check((config.get("structures", []) as Array).size() >= 5, "stage config owns structure content")
	var session: RefCounted = BattleSessionScript.new()
	session.start(_siege_heroes(), "stage_2_5", config)
	var snapshot: Dictionary = session.snapshot()
	_check(String(snapshot.get("stage_id", "")) == "stage_2_5", "battle snapshot exposes configured stage id")
	_check(not snapshot.has("max_ticks"), "battle snapshot remains free of hidden time limits")
	_check((snapshot.get("enemies", []) as Array).size() == (config.get("enemies", []) as Array).size(), "battle enemies come from stage config")
	_check((snapshot.get("structures", []) as Array).size() == (config.get("structures", []) as Array).size(), "battle structures come from stage config")


func _test_boss_cannon_suppression_window() -> void:
	var session := _forced_final_stage_session("stage_1_5", _low_pressure_heroes())
	var events: Array[Dictionary] = session.advance_tick()
	var warning := _first_event(events, &"artillery_warning")
	_check(not warning.is_empty(), "chapter boss emits a cannon warning in the final base phase")
	_check(bool(warning.get("suppressible", false)), "chapter boss cannon warning is suppressible")
	_check(int(warning.get("suppression_target", 0)) == 70, "chapter one boss suppression target is 70")
	_check(int(warning.get("impact_tick", 0)) - int(warning.get("tick", 0)) == 25, "chapter one boss cannon warning lasts twenty-five ticks at five hertz")
	var warnings := session.snapshot().get("warnings", []) as Array
	_check(warnings.size() == 1, "unsuppressed boss warning remains visible in the snapshot")
	if not warnings.is_empty():
		var snapshot_warning := warnings[0] as Dictionary
		_check(int(snapshot_warning.get("remaining_ticks", 0)) == 25, "boss warning snapshot exposes remaining ticks")
		_check(int(snapshot_warning.get("suppression_remaining", 0)) == 70, "boss warning snapshot exposes suppression remaining")


func _test_boss_cannon_suppression_high_output() -> void:
	var session := _forced_final_stage_session("stage_1_5", _burst_pressure_heroes())
	var events: Array[Dictionary] = session.advance_tick()
	var suppressed := _first_event(events, &"cannon_suppressed")
	_check(not suppressed.is_empty(), "high structure output can interrupt the boss cannon before impact")
	_check((session.snapshot().get("warnings", []) as Array).is_empty(), "suppressed boss warning is removed immediately")
	_defeat_main_allies(session)
	session.advance_tick()
	_check(int(session.result.get("cannons_suppressed", 0)) == 1, "battle result records suppressed boss cannon count")
	_check(int(session.result.get("cannon_impacts", -1)) == 0, "suppressed boss cannon does not also impact")


func _test_boss_cannon_low_output_impacts() -> void:
	var session := _forced_final_stage_session("stage_1_5", _low_pressure_heroes())
	var impact_seen := false
	var suppressed_seen := false
	for _i in 27:
		for event in session.advance_tick():
			impact_seen = impact_seen or event["type"] == &"artillery_impact"
			suppressed_seen = suppressed_seen or event["type"] == &"cannon_suppressed"
	_defeat_main_allies(session)
	session.advance_tick()
	_check(impact_seen, "low output fails the suppression race and receives cannon impact")
	_check(not suppressed_seen, "low output does not emit cannon_suppressed")
	_check(int(session.result.get("cannon_impacts", 0)) > 0, "battle result records cannon impacts")


func _test_normal_stage_has_no_suppressible_warning() -> void:
	var session := _forced_final_stage_session("stage_1_4", _low_pressure_heroes())
	var events: Array[Dictionary] = session.advance_tick()
	var warning := _first_event(events, &"artillery_warning")
	_check(not warning.is_empty(), "normal final-base phase keeps legacy cannon warning")
	_check(not bool(warning.get("suppressible", false)), "normal stages do not expose suppressible cannon UI state")
	_check(int(warning.get("impact_tick", 0)) - int(warning.get("tick", 0)) == BattleSessionScript.CANNON_FUSE_TICKS, "normal cannon warning keeps the legacy fuse")
	var warnings := session.snapshot().get("warnings", []) as Array
	if not warnings.is_empty():
		_check(not bool((warnings[0] as Dictionary).get("suppressible", false)), "normal warning snapshot remains non-suppressible")
		_check(int((warnings[0] as Dictionary).get("suppression_target", 0)) == 0, "normal warning snapshot has no positive suppression target")


func _test_boss_cannon_determinism() -> void:
	var first := _boss_cannon_trace(_burst_pressure_heroes())
	var second := _boss_cannon_trace(_burst_pressure_heroes())
	_check(first == second, "same boss cannon pressure sequence is deterministic")


func _boss_cannon_trace(heroes: Array[Dictionary]) -> Array[String]:
	var session := _forced_final_stage_session("stage_1_5", heroes)
	var trace: Array[String] = []
	for _i in 25:
		for event in session.advance_tick():
			if [&"artillery_warning", &"cannon_suppressed", &"artillery_impact"].has(event["type"]):
				trace.append("%s:%s:%d" % [String(event["type"]), String(event.get("warning_id", "")), int(event.get("tick", 0))])
	return trace


func _forced_final_stage_session(stage_id: String, heroes: Array[Dictionary]) -> RefCounted:
	var session: RefCounted = BattleSessionScript.new()
	var config := StageCatalogScript.stage(stage_id)
	session.start(heroes, stage_id, config)
	session._stage_index = 2
	var battery_count := 0
	for structure in session._structures:
		if String(structure.get("kind", "")) == "battery":
			battery_count += 1
	session.tick_index = (42 - battery_count * 6) - 1
	for unit in session._units:
		if int(unit["team"]) == BattleSessionScript.TEAM_ENEMY:
			unit["alive"] = false
	for structure in session._structures:
		if int(structure["stage"]) < 2:
			structure["alive"] = false
	for unit in session._units:
		if int(unit["team"]) == BattleSessionScript.TEAM_ALLY:
			unit["stage"] = 2
			unit["road_position"] = 780
			unit["cooldown_ticks"] = 0
	return session


func _first_event(events: Array[Dictionary], event_type: StringName) -> Dictionary:
	for event in events:
		if event["type"] == event_type:
			return event
	return {}


func _first_skill_event(heroes: Array[Dictionary], unit_id: StringName) -> Dictionary:
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, heroes)
	session.set_auto_skill(unit_id, true)
	while not session.is_finished:
		var events: Array[Dictionary] = session.advance_tick()
		for event in events:
			if event["type"] == &"skill_used" and event["unit_id"] == unit_id:
				var total_shield := 0
				for unit in session.snapshot()["units"]:
					total_shield += int(unit.get("shield", 0))
				var enriched: Dictionary = event.duplicate(true)
				enriched["total_shield"] = total_shield
				enriched["skill_enemy_hits"] = 0
				enriched["skill_target_hits"] = 0
				enriched["enemy_stunned"] = 0
				enriched["enemies_weakened"] = 0
				enriched["allies_healed"] = 0
				enriched["units_summoned"] = 0
				enriched["units_converted"] = 0
				for resolution_event in events:
					if resolution_event["type"] == &"enemy_damaged" and bool(resolution_event.get("is_skill", false)):
						enriched["skill_enemy_hits"] = int(enriched["skill_enemy_hits"]) + 1
						enriched["skill_target_hits"] = int(enriched["skill_target_hits"]) + 1
					elif resolution_event["type"] == &"structure_damaged" and bool(resolution_event.get("is_skill", false)):
						enriched["skill_target_hits"] = int(enriched["skill_target_hits"]) + 1
					elif resolution_event["type"] == &"enemy_stunned":
						enriched["enemy_stunned"] = int(enriched["enemy_stunned"]) + 1
					elif resolution_event["type"] == &"enemy_weakened":
						enriched["enemies_weakened"] = int(enriched["enemies_weakened"]) + 1
					elif resolution_event["type"] == &"unit_healed":
						enriched["allies_healed"] = int(enriched["allies_healed"]) + 1
					elif resolution_event["type"] == &"unit_summoned":
						enriched["units_summoned"] = int(enriched["units_summoned"]) + 1
					elif resolution_event["type"] == &"unit_converted":
						enriched["units_converted"] = int(enriched["units_converted"]) + 1
				for snapshot_unit in session.snapshot()["units"]:
					if snapshot_unit["unit_id"] == unit_id:
						enriched["caster_hp"] = int(snapshot_unit["hp"])
						enriched["caster_energy"] = int(snapshot_unit["energy"])
						break
				return enriched
	return {}


func _repair_restores_actual_hp() -> bool:
	var heroes := _mechanic_heroes("repair", 2)
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, heroes)
	var damaged := false
	while not session.is_finished and not damaged:
		session.advance_tick()
		for unit in session.snapshot()["units"]:
			damaged = damaged or int(unit["hp"]) < int(unit["max_hp"])
	if not damaged:
		return false
	var before := 0
	for unit in session.snapshot()["units"]:
		before += int(unit["hp"])
	if not session.request_skill(&"hero_0"):
		return false
	session.advance_tick()
	var after := 0
	for unit in session.snapshot()["units"]:
		after += int(unit["hp"])
	return after > before


func _repair_revives_fallen() -> bool:
	var heroes := _mechanic_heroes("repair", 3)
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, heroes)
	session._units[1]["hp"] = 0
	session._units[1]["alive"] = false
	session.set_auto_skill(&"hero_0", true)
	for event in session.advance_tick():
		if event["type"] == &"unit_revived" and event["unit_id"] == &"hero_1":
			return true
	return false


func _run_to_result(heroes: Array[Dictionary]) -> Dictionary:
	var session: RefCounted = BattleSessionScript.new()
	_start_standard_battle(session, heroes)
	for hero in heroes:
		session.set_auto_skill(StringName(hero["hero_id"]), true)
	while not session.is_finished:
		session.advance_tick()
	return session.result.duplicate(true)


func _snapshot_structure(snapshot: Dictionary, structure_id: String) -> Dictionary:
	for structure in snapshot.get("structures", []):
		if String((structure as Dictionary).get("structure_id", "")) == structure_id:
			return structure
	return {}


func _start_standard_battle(session: RefCounted, heroes: Array) -> void:
	# Combat-mechanics tests use an explicit mature siege fixture. The real default
	# stage is intentionally the one-city, zero-defender Gman tutorial.
	var config := StageCatalogScript.stage("stage_1_5")
	config["suppressible_cannon"] = false
	config["cannon_suppression_target"] = 0
	config["cannon_warning_ticks"] = BattleSessionScript.CANNON_FUSE_TICKS
	session.start(heroes, "stage_1_5", config)


func _defeat_main_allies(session: RefCounted) -> void:
	for unit in session._units:
		if int(unit.get("team", BattleSessionScript.TEAM_ENEMY)) == BattleSessionScript.TEAM_ALLY and not bool(unit.get("temporary", false)):
			unit["hp"] = 0
			unit["alive"] = false


func _siege_heroes() -> Array[Dictionary]:
	return [
		_hero(0, "armored", "guardian", 3, 330, 70, 32),
		_hero(1, "assault", "fighter", 2, 255, 72, 20),
		_hero(2, "rocket", "ranger", 2, 230, 78, 15),
		_hero(3, "saw", "fighter", 2, 260, 82, 20),
		_hero(4, "repair", "guardian", 2, 245, 62, 24),
		_hero(5, "parasite", "arcanist", 2, 225, 66, 15),
	]


func _low_pressure_heroes() -> Array[Dictionary]:
	var values := _six_of("assault", 1).slice(0, 1) as Array[Dictionary]
	for hero in values:
		hero["attack"] = 1
		hero["max_hp"] = 500
		hero["defense"] = 40
	return values


func _burst_pressure_heroes() -> Array[Dictionary]:
	var values := _six_of("rocket", 3)
	for hero in values:
		hero["attack"] = 220
		hero["max_hp"] = 500
		hero["defense"] = 40
		hero["starting_energy"] = 0
	return values


func _six_of(archetype_id: String, star: int) -> Array[Dictionary]:
	var class_id := String({
		"armored": "guardian",
		"repair": "guardian",
		"assault": "fighter",
		"saw": "fighter",
		"rocket": "ranger",
		"bomber": "ranger",
		"sonic": "arcanist",
		"parasite": "arcanist",
	}.get(archetype_id, "fighter"))
	var values: Array[Dictionary] = []
	for slot in 6:
		values.append(_hero(slot, archetype_id, class_id, star, 300, 90, 24))
	return values


func _mechanic_heroes(archetype_id: String, star: int) -> Array[Dictionary]:
	var values := _six_of(archetype_id, star)
	for slot in values.size():
		values[slot]["max_hp"] = 500
		values[slot]["defense"] = 28
		values[slot]["attack"] = 32 if slot == 0 else 1
		values[slot]["starting_energy"] = 100 if slot == 0 else 0
	return values


func _hero(slot: int, archetype_id: String, class_id: String, star: int, hp: int, attack: int, defense: int) -> Dictionary:
	return {
		"hero_id": "hero_%d" % slot,
		"display_name": "%s_%d" % [archetype_id, slot],
		"archetype_id": archetype_id,
		"class_id": class_id,
		"star": star,
		"max_hp": hp,
		"attack": attack,
		"defense": defense,
		"slot": slot,
		"skill_id": "legacy_input_must_be_ignored",
	}


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

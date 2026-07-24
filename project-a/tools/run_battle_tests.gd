extends SceneTree

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_requires_exact_six_known_archetypes()
	_test_three_layer_siege_with_enemy_contact()
	_test_manual_and_auto_skill_contract()
	_test_eight_archetype_skill_families()
	_test_star_tiers_change_skill_output()
	_test_core_cannon_and_destruction_feedback()
	_test_same_input_same_result()
	_test_timeout_contract()
	if failures.is_empty():
		print("BATTLE TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("BATTLE TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _test_requires_exact_six_known_archetypes() -> void:
	var empty_session: RefCounted = BattleSessionScript.new()
	empty_session.start([])
	_check(empty_session.is_finished, "empty formation is rejected immediately")
	_check(String(empty_session.result.get("reason", "")) == "invalid_formation", "empty formation exposes invalid_formation")
	var short_session: RefCounted = BattleSessionScript.new()
	short_session.start(_siege_heroes().slice(0, 5))
	_check(short_session.is_finished, "five-unit formation is rejected instead of receiving hidden fallback units")
	_check((short_session.snapshot().get("units", []) as Array).is_empty(), "invalid formation contains no fabricated units")
	var unknown_session: RefCounted = BattleSessionScript.new()
	var bad := _siege_heroes()
	bad[0]["archetype_id"] = "not_a_toilet"
	unknown_session.start(bad)
	_check(unknown_session.is_finished, "unknown archetype is rejected")
	_check(String(unknown_session.result.get("reason", "")) == "unknown_archetype", "unknown archetype is explicit, not silently mapped to a fallback skill")


func _test_three_layer_siege_with_enemy_contact() -> void:
	var session: RefCounted = BattleSessionScript.new()
	session.start(_siege_heroes())
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
	_check(int(session.result.get("ticks", 999)) <= BattleSessionScript.MAX_TICKS, "default battle finishes before timeout")
	_check(int(final_snapshot.get("road_progress", 0)) <= BattleSessionScript.ROAD_END, "road progress remains in integer road bounds")
	_check((final_snapshot.get("enemies", []) as Array).size() >= 8, "enemy snapshots are separated from six ally HUD units")


func _test_manual_and_auto_skill_contract() -> void:
	var session: RefCounted = BattleSessionScript.new()
	session.start(_six_of("assault", 1))
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
	auto_session.start(_siege_heroes())
	_check(auto_session.set_auto_skill(&"hero_1", true), "auto skill can be enabled per unit")
	var auto_used := false
	while not auto_session.is_finished and not auto_used:
		for event in auto_session.advance_tick():
			if event["type"] == &"skill_used" and event["unit_id"] == &"hero_1":
				auto_used = true
	_check(auto_used, "enabled auto skill releases after energy fills")


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
		session.start(_six_of(archetype_id, 2))
		for hero in _six_of(archetype_id, 2):
			session.set_auto_skill(StringName(hero["hero_id"]), true)
		var used := false
		var safety := 0
		while not session.is_finished and not used and safety < BattleSessionScript.MAX_TICKS:
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
	session.start(_siege_heroes())
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


func _test_same_input_same_result() -> void:
	var first := _run_to_result(_siege_heroes())
	var second := _run_to_result(_siege_heroes())
	_check(first == second, "same six-unit snapshot produces the same result")


func _test_timeout_contract() -> void:
	var session: RefCounted = BattleSessionScript.new()
	session.start(_siege_heroes())
	session.tick_index = BattleSessionScript.MAX_TICKS - 1
	session.advance_tick()
	_check(session.is_finished, "maximum tick closes the battle")
	_check(String(session.result.get("outcome", "")) == "timeout", "living squad at maximum tick times out")


func _first_skill_event(heroes: Array[Dictionary], unit_id: StringName) -> Dictionary:
	var session: RefCounted = BattleSessionScript.new()
	session.start(heroes)
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
	session.start(heroes)
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
	session.start(heroes)
	session._units[1]["hp"] = 0
	session._units[1]["alive"] = false
	session.set_auto_skill(&"hero_0", true)
	for event in session.advance_tick():
		if event["type"] == &"unit_revived" and event["unit_id"] == &"hero_1":
			return true
	return false


func _run_to_result(heroes: Array[Dictionary]) -> Dictionary:
	var session: RefCounted = BattleSessionScript.new()
	session.start(heroes)
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


func _siege_heroes() -> Array[Dictionary]:
	return [
		_hero(0, "armored", "guardian", 3, 330, 70, 32),
		_hero(1, "assault", "fighter", 2, 255, 72, 20),
		_hero(2, "rocket", "ranger", 2, 230, 78, 15),
		_hero(3, "saw", "fighter", 2, 260, 82, 20),
		_hero(4, "repair", "guardian", 2, 245, 62, 24),
		_hero(5, "parasite", "arcanist", 2, 225, 66, 15),
	]


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

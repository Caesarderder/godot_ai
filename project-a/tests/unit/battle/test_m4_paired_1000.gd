extends GutTest

const Runner := preload("res://game/scripts/domain/battle/m4_canonical_battle_runner.gd")
const Catalog := preload("res://game/scripts/presentation/m3_stage_catalog.gd")


func test_stage_1_4_formation_pair_meets_distribution_gate() -> void:
	var scenario: Dictionary = Catalog.scenarios()["stage-1-4"]
	var before_wins := 0
	var after_wins := 0
	for run_seed in 1000:
		var before := Runner.materialize(scenario, run_seed, false)
		var after := Runner.materialize(scenario, run_seed, true)
		assert_true(Runner.validate_formation_only(before, after))
		before_wins += int(Runner.run(before).winner == 0)
		after_wins += int(Runner.run(after).winner == 0)
	assert_between(before_wins, 350, 500)
	assert_between(after_wins, 750, 900)


func test_stage_1_5_equipment_pair_meets_distribution_gate() -> void:
	var scenario: Dictionary = Catalog.scenarios()["stage-1-5"]
	var before_wins := 0
	var after_wins := 0
	for run_seed in 1000:
		var before := Runner.materialize(scenario, run_seed, false)
		var after := Runner.materialize(scenario, run_seed, true)
		assert_true(Runner.validate_equipment_only(before, after))
		before_wins += int(Runner.run(before).winner == 0)
		after_wins += int(Runner.run(after).winner == 0)
	assert_between(before_wins, 100, 250)
	assert_gte(after_wins - before_wins, 300)


func test_m4_pair_validators_reject_non_whitelisted_changes() -> void:
	var scenarios := Catalog.scenarios()
	var formation_before := Runner.materialize(scenarios["stage-1-4"], 7, false)
	var formation_after := Runner.materialize(scenarios["stage-1-4"], 7, true)
	formation_after["combat_stats"][formation_after["active_hero_ids"][0]]["hp"] += 1
	assert_false(Runner.validate_formation_only(formation_before, formation_after))

	var equipment_before := Runner.materialize(scenarios["stage-1-5"], 7, false)
	var equipment_after := Runner.materialize(scenarios["stage-1-5"], 7, true)
	equipment_after["formation"]["front_1"] = equipment_after["active_hero_ids"][1]
	assert_false(Runner.validate_equipment_only(equipment_before, equipment_after))

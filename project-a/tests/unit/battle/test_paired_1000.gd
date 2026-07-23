extends GutTest

const Runner := preload("res://game/scripts/domain/battle/m4_canonical_battle_runner.gd")
const Preflight := preload("res://game/scripts/domain/battle/manifest_preflight.gd")


func test_signed_manifest_drives_absolute_and_paired_gates() -> void:
	var manifest := _load_manifest()
	var unsigned := manifest.duplicate(true)
	unsigned.erase("signature")
	assert_eq(BattleResult._sha256(BattleResult._canonical(unsigned)), manifest["signature"])
	assert_eq(manifest["schema"], "paired-battle-manifest-v5")
	assert_eq(manifest["generator_version"], Preflight.GENERATOR_VERSION)
	assert_false(str(manifest["generated_at"]).is_empty())
	assert_true(Preflight.verify_artifacts(manifest))
	assert_eq(manifest["build_artifact_hash"], manifest["content_hash"])
	assert_eq(BattleResult._sha256(BattleResult._canonical(manifest["artifact_hashes"])), manifest["content_hash"])
	assert_eq(Preflight.file_sha256("res://game/scripts/domain/battle/battle_manifest_generator.gd"), manifest["generator_source_hash"])
	assert_string_contains(manifest["generation_command"], "battle_manifest_generator.gd")
	for required_path in [
		"res://game/scripts/domain/battle/battle_session.gd",
		"res://game/scripts/domain/battle/battle_unit.gd",
		"res://game/scripts/domain/battle/deterministic_rng.gd",
		"res://game/scripts/domain/battle/m4_canonical_battle_runner.gd",
		"res://game/scripts/domain/battle/stable_seed.gd",
		"res://game/scripts/domain/battle/battle_result.gd",
		"res://game/scripts/domain/formation/formation_reducer.gd",
	]:
		assert_has(manifest["artifact_hashes"].keys(), required_path)
	var seeds: Array = manifest["run_seeds"]
	var recipes: Array = []
	for shard in manifest["recipe_hash_shards"]:
		var shard_file := FileAccess.open(shard["path"], FileAccess.READ)
		assert_not_null(shard_file)
		var shard_records: Array = JSON.parse_string(shard_file.get_as_text())
		assert_eq(shard_records.size(), int(shard["count"]))
		assert_eq(BattleResult._sha256(BattleResult._canonical(shard_records)), shard["sha256"])
		recipes.append_array(shard_records)
	assert_eq(seeds.size(), 1000)
	assert_eq(recipes.size(), 1000)

	var scenarios: Dictionary = manifest["scenarios"]
	for scenario in scenarios.values():
		assert_eq(Runner.stage_snapshot_hash(scenario), scenario["stage_snapshot_hash"])
	var wins: Dictionary = {"stage-1-1": 0, "stage-1-2": 0}
	var paired_wins: Dictionary = {
		"stage-1-3": {"before": 0, "after": 0},
		"stage-1-4": {"before": 0, "after": 0},
		"stage-1-5": {"before": 0, "after": 0},
	}
	for index in seeds.size():
		var run_seed := int(seeds[index])
		for stage_id in wins.keys():
			var scenario: Dictionary = scenarios[stage_id]
			var stage_snapshot := Runner.materialize(scenario, run_seed, false)
			assert_eq(Runner.recipe_hash(stage_snapshot), recipes[index][_recipe_field(stage_id, "before")])
			wins[stage_id] += int(Runner.run(stage_snapshot).winner == 0)
		assert_eq(int(recipes[index]["run_seed"]), run_seed)
		for stage_id in paired_wins.keys():
			var paired: Dictionary = scenarios[stage_id]
			var before: Dictionary = Runner.materialize(paired, run_seed, false)
			var after: Dictionary = Runner.materialize(paired, run_seed, true)
			assert_eq(Runner.recipe_hash(before), recipes[index][_recipe_field(stage_id, "before")])
			assert_eq(Runner.recipe_hash(after), recipes[index][_recipe_field(stage_id, "after")])
			if paired["intervention"]["type"] == "equip_item":
				assert_true(Runner.validate_equipment_only(before, after))
			else:
				assert_true(Runner.validate_formation_only(before, after))
			assert_eq(before["roster"].size(), 8)
			assert_eq(before["active_hero_ids"].size(), 4)
			paired_wins[stage_id]["before"] += int(Runner.run(before).winner == 0)
			paired_wins[stage_id]["after"] += int(Runner.run(after).winner == 0)

	_assert_absolute(wins["stage-1-1"], scenarios["stage-1-1"]["thresholds"])
	_assert_absolute(wins["stage-1-2"], scenarios["stage-1-2"]["thresholds"])
	_assert_paired_delta(paired_wins["stage-1-3"], scenarios["stage-1-3"]["thresholds"])
	_assert_paired_absolute(paired_wins["stage-1-4"], scenarios["stage-1-4"]["thresholds"])
	_assert_paired_delta(paired_wins["stage-1-5"], scenarios["stage-1-5"]["thresholds"])
	print("paired1000 signed: 1-1=", wins["stage-1-1"], " 1-2=", wins["stage-1-2"], " 1-3=", paired_wins["stage-1-3"], " 1-4=", paired_wins["stage-1-4"], " 1-5=", paired_wins["stage-1-5"])


func test_intervention_is_predeclared_set_formation_and_reducer_rejects_tampering() -> void:
	var scenario: Dictionary = _load_manifest()["scenarios"]["stage-1-3"]
	assert_eq(scenario["intervention"]["type"], "set_formation")
	var indices: Array = scenario["intervention"]["slots_from_roster_indices"].map(func(value: Variant) -> int: return int(value))
	assert_eq(indices, [1, 0, 2, 3])
	var before := Runner.materialize(scenario, 7, false)
	var after := Runner.materialize(scenario, 7, true)
	after["roster"][0]["level"] = 2
	assert_false(Runner.validate_formation_only(before, after))


func _assert_absolute(wins: int, thresholds: Dictionary) -> void:
	assert_between(wins * 10, int(thresholds["win_rate_min_bp"]), int(thresholds["win_rate_max_bp"]))


func _assert_paired_delta(wins: Dictionary, thresholds: Dictionary) -> void:
	assert_between(int(wins["before"]) * 10, int(thresholds["before_min_bp"]), int(thresholds["before_max_bp"]))
	assert_gte((int(wins["after"]) - int(wins["before"])) * 10, int(thresholds["delta_min_bp"]))


func _assert_paired_absolute(wins: Dictionary, thresholds: Dictionary) -> void:
	assert_between(int(wins["before"]) * 10, int(thresholds["before_min_bp"]), int(thresholds["before_max_bp"]))
	assert_between(int(wins["after"]) * 10, int(thresholds["after_min_bp"]), int(thresholds["after_max_bp"]))


func _recipe_field(stage_id: String, phase: String) -> String:
	return "%s_%s" % [stage_id.replace("-", "_"), phase]


func _load_manifest() -> Dictionary:
	var file := FileAccess.open("res://tests/fixtures/battle/paired_1000_v1.json", FileAccess.READ)
	assert_not_null(file)
	return JSON.parse_string(file.get_as_text())

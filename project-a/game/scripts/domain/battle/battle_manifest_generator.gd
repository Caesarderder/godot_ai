class_name BattleManifestGenerator
extends SceneTree

const GENERATOR_VERSION := "m5-preflight-v5"
const SHARD_SIZE := 100
const SCHEMA := "paired-battle-manifest-v5"

const Catalog := preload("res://game/scripts/presentation/m3_stage_catalog.gd")
const M4Runner := preload("res://game/scripts/domain/battle/m4_canonical_battle_runner.gd")

const ARTIFACT_PATHS: Array[String] = [
	"res://game/scripts/domain/battle/battle_result.gd",
	"res://game/scripts/domain/battle/battle_session.gd",
	"res://game/scripts/domain/battle/battle_unit.gd",
	"res://game/scripts/domain/battle/canonical_battle_runner.gd",
	"res://game/scripts/domain/battle/deterministic_rng.gd",
	"res://game/scripts/domain/battle/m4_canonical_battle_runner.gd",
	"res://game/scripts/domain/battle/stable_seed.gd",
	"res://game/scripts/domain/formation/formation_reducer.gd",
	"res://game/scripts/domain/heroes/hero_catalog.gd",
	"res://game/scripts/domain/heroes/hero_generator.gd",
]


func _init() -> void:
	var output_dir := "res://tests/fixtures/battle"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_dir = argument.trim_prefix("--output=")
	var source := FileAccess.open(output_dir.path_join("paired_1000_v1.json"), FileAccess.READ)
	assert(source != null, "generator requires an existing reviewed manifest template")
	generate(JSON.parse_string(source.get_as_text()), output_dir)
	quit()


# This generator intentionally never calls CanonicalBattleRunner.run(). It only
# materializes pre-outcome snapshots, writes their hashes, and signs the manifest.
static func generate(template: Dictionary, output_dir: String) -> Dictionary:
	var artifact_hashes := _artifact_hashes()
	var content_hash := BattleResult._sha256(BattleResult._canonical(artifact_hashes))
	var scenarios := _scenarios_with_hashes(content_hash)
	var manifest := {
		"artifact_hashes": artifact_hashes,
		"build_artifact_hash": content_hash,
		"content_hash": content_hash,
		"generated_at": "2026-07-22T00:00:00+08:00",
		"generation_command": "godot --headless --path project-a -s res://game/scripts/domain/battle/battle_manifest_generator.gd -- --output=res://tests/fixtures/battle",
		"generator_source_hash": BattleManifestPreflight.file_sha256("res://game/scripts/domain/battle/battle_manifest_generator.gd"),
		"generator_version": GENERATOR_VERSION,
		"run_seeds": template["run_seeds"],
		"scenarios": scenarios,
		"schema": SCHEMA,
	}
	var seeds: Array = manifest["run_seeds"]
	var shard_metadata: Array = []
	for offset in range(0, seeds.size(), SHARD_SIZE):
		var records: Array = []
		for index in range(offset, mini(offset + SHARD_SIZE, seeds.size())):
			var seed := int(seeds[index])
			records.append(_recipe_record(scenarios, seed))
		@warning_ignore("integer_division")
		var shard_number := int(offset / SHARD_SIZE) + 1
		var path := output_dir.path_join("paired_1000_recipes_%d.json" % shard_number)
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(records))
		shard_metadata.append({"path": path, "count": records.size(), "sha256": BattleResult._sha256(BattleResult._canonical(records))})
	manifest["recipe_hash_shards"] = shard_metadata
	manifest["signature"] = BattleResult._sha256(BattleResult._canonical(manifest))
	var manifest_file := FileAccess.open(output_dir.path_join("paired_1000_v1.json"), FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest))
	return manifest


static func _artifact_hashes() -> Dictionary:
	var hashes: Dictionary = {}
	for path in ARTIFACT_PATHS:
		hashes[path] = BattleManifestPreflight.file_sha256(path)
	return hashes


static func _scenarios_with_hashes(content_hash: String) -> Dictionary:
	var scenarios: Dictionary = Catalog.scenarios()
	for stage_id in scenarios.keys():
		var scenario: Dictionary = scenarios[stage_id]
		scenario["content_hash"] = content_hash
		scenario["stage_snapshot_hash"] = CanonicalBattleRunner.stage_snapshot_hash(scenario)
	return scenarios


static func _recipe_record(scenarios: Dictionary, seed: int) -> Dictionary:
	var record := {"run_seed": seed}
	for stage_id in ["stage-1-1", "stage-1-2", "stage-1-3", "stage-1-4", "stage-1-5"]:
		var scenario: Dictionary = scenarios[stage_id]
		var field_prefix: String = stage_id.replace("-", "_")
		record["%s_before" % field_prefix] = CanonicalBattleRunner.recipe_hash(M4Runner.materialize(scenario, seed, false))
		if scenario["intervention"] != null:
			record["%s_after" % field_prefix] = CanonicalBattleRunner.recipe_hash(M4Runner.materialize(scenario, seed, true))
	return record

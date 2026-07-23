extends GutTest

const StableSeedScript := preload("res://game/scripts/domain/battle/stable_seed.gd")


func test_length_prefixed_sha256_matches_registered_golden() -> void:
	var file := FileAccess.open("res://tests/fixtures/golden/seed_hash_v1.json", FileAccess.READ)
	var fixture: Dictionary = JSON.parse_string(file.get_as_text())
	var parts := PackedStringArray(fixture["parts"])
	assert_eq(StableSeedScript.sha256_hex(parts), fixture["sha256"])
	assert_eq(StableSeedScript.signed_seed(parts), int(fixture["signed_seed"]))
	var stage_1_5: Dictionary = fixture["stage_1_5"]
	var parts_1_5 := PackedStringArray(stage_1_5["parts"])
	assert_eq(StableSeedScript.sha256_hex(parts_1_5), stage_1_5["sha256"])
	assert_eq(StableSeedScript.signed_seed(parts_1_5), int(stage_1_5["signed_seed"]))


func test_save_id_is_not_part_of_battle_seed() -> void:
	var a := StableSeedScript.battle_parts("content-v1", "stage-1-3", 0, "onboarding-v1")
	var b := StableSeedScript.battle_parts("content-v1", "stage-1-3", 0, "onboarding-v1")
	assert_eq(StableSeedScript.sha256_hex(a), StableSeedScript.sha256_hex(b))
	var copied_state := {"save_id": "renamed-copy", "content_version": "content-v1", "stage_id": "stage-1-3", "attempt": 0, "run_seed_token": "onboarding-v1"}
	var original_state := copied_state.duplicate(true)
	original_state["save_id"] = "original-save"
	var original_parts := StableSeedScript.battle_parts(original_state["content_version"], original_state["stage_id"], original_state["attempt"], original_state["run_seed_token"])
	var copied_parts := StableSeedScript.battle_parts(copied_state["content_version"], copied_state["stage_id"], copied_state["attempt"], copied_state["run_seed_token"])
	assert_eq(StableSeedScript.signed_seed(original_parts), StableSeedScript.signed_seed(copied_parts))

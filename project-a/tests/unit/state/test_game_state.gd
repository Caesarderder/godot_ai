extends GutTest

@warning_ignore("shadowed_global_identifier")
const GameState := preload("res://game/scripts/state/game_state.gd")

const EXPECTED_KEYS := [
	"schema_version",
	"content_version",
	"save_id",
	"run_seed",
	"revision",
	"roster",
	"inventory",
	"formation",
	"economy",
	"camp",
	"quest",
	"pity",
	"stage_progress",
	"attempt_counters",
	"receipt_ledgers",
	"saved_at_unix",
	"last_seen_wall_unix",
	"last_settled_unix",
	"offline_anchor_unix",
]


func test_create_new_has_complete_v1_schema_and_first_boot_times() -> void:
	var state := GameState.create_new(1_725_000_000, "save-alpha", 42)
	var keys := state.keys()
	keys.sort()
	var expected := EXPECTED_KEYS.duplicate()
	expected.sort()

	assert_eq(keys, expected)
	assert_eq(state.schema_version, 1)
	assert_eq(state.content_version, 1)
	assert_eq(state.save_id, "save-alpha")
	assert_eq(state.run_seed, 42)
	assert_eq(state.revision, 0)
	assert_eq(state.last_seen_wall_unix, 1_725_000_000)
	assert_eq(state.offline_anchor_unix, 1_725_000_000)
	assert_eq(state.last_settled_unix, 0)
	assert_eq(state.saved_at_unix, 0)
	for key: String in [
		"roster",
		"inventory",
		"formation",
		"economy",
		"camp",
		"quest",
		"pity",
		"stage_progress",
		"attempt_counters",
		"receipt_ledgers",
	]:
		assert_eq(state[key], { }, "%s should start as an empty deterministic container" % key)


func test_clone_is_deeply_isolated() -> void:
	var original := GameState.create_new(100, "save-alpha", 42)
	original.roster = { "heroes": [{ "id": "hero-1" }] }
	var copied := GameState.clone(original)

	copied.roster.heroes[0].id = "hero-2"
	copied.roster.heroes.append({ "id": "hero-3" })

	assert_eq(original.roster.heroes, [{ "id": "hero-1" }])
	assert_eq(copied.roster.heroes.size(), 2)


func test_validate_accepts_only_serializable_primitive_graphs() -> void:
	var state := GameState.create_new(100, "save-alpha", 42)
	state.inventory = {
		"flags": [null, true, false],
		"counts": [0, -2, 17],
		"names": ["sword", "剑"],
		"nested": { "ok": true },
	}

	assert_eq(GameState.validate(state), { "ok": true, "code": "OK" })

	state.inventory.bad_float = 1.5
	assert_eq(GameState.validate(state), { "ok": false, "code": "INVALID_VALUE" })
	state.inventory.erase("bad_float")
	state.inventory.bad_object = Node.new()
	assert_eq(GameState.validate(state), { "ok": false, "code": "INVALID_VALUE" })
	state.inventory.bad_object.free()


func test_validate_rejects_non_string_dictionary_keys() -> void:
	var state := GameState.create_new(100, "save-alpha", 42)
	state.inventory = { 7: "not allowed" }

	assert_eq(GameState.validate(state), { "ok": false, "code": "INVALID_VALUE" })


func test_validate_rejects_missing_and_negative_revision() -> void:
	var state := GameState.create_new(100, "save-alpha", 42)
	state.erase("revision")
	assert_eq(GameState.validate(state), { "ok": false, "code": "MISSING_KEY" })

	state.revision = -1
	assert_eq(GameState.validate(state), { "ok": false, "code": "INVALID_REVISION" })

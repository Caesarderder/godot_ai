extends GutTest

const GameState := preload("res://game/scripts/state/game_state.gd")
const SaveCodec := preload("res://game/scripts/persistence/save_codec.gd")
const SaveMigrations := preload("res://game/scripts/persistence/save_migrations.gd")


func test_v1_round_trip_preserves_every_field() -> void:
	var state := GameState.create_new(100, "save-alpha", 42)
	state.revision = 7
	state.saved_at_unix = 123
	state.roster = { "heroes": [{ "id": "hero-1", "locked": true }] }
	state.economy = { "gold": 99 }

	var decoded := SaveCodec.decode(SaveCodec.encode(state))

	assert_true(decoded.ok)
	assert_eq(decoded.code, "OK")
	assert_eq(decoded.state, state)


func test_encoding_is_canonical_for_dictionary_insertion_order() -> void:
	var first := GameState.create_new(100, "save-alpha", 42)
	var second := GameState.create_new(100, "save-alpha", 42)
	first.inventory = { "z": 1, "a": { "two": 2, "one": 1 } }
	second.inventory = { "a": { "one": 1, "two": 2 }, "z": 1 }

	assert_eq(SaveCodec.encode(first), SaveCodec.encode(second))


func test_decode_migrates_v0_fixture_with_deterministic_defaults() -> void:
	var fixture := FileAccess.get_file_as_string("res://tests/fixtures/saves/save_v0.json")
	var decoded := SaveCodec.decode(fixture)

	assert_true(decoded.ok)
	assert_eq(decoded.state.schema_version, 1)
	assert_eq(decoded.state.content_version, 3)
	assert_eq(decoded.state.save_id, "legacy-save")
	assert_eq(decoded.state.run_seed, 77)
	assert_eq(decoded.state.revision, 4)
	assert_eq(decoded.state.economy, { "gold": 25 })
	assert_eq(decoded.state.last_seen_wall_unix, 900)
	assert_eq(decoded.state.offline_anchor_unix, 900)
	assert_eq(decoded.state.last_settled_unix, 0)
	assert_eq(decoded.state.receipt_ledgers, { })
	assert_eq(SaveMigrations.to_current(decoded.state), decoded.state)


func test_decode_rejects_invalid_json_and_invalid_state() -> void:
	var corrupt := FileAccess.get_file_as_string("res://tests/fixtures/saves/save_corrupt.json")
	assert_eq(SaveCodec.decode(corrupt).code, "INVALID_JSON")

	var incomplete := JSON.stringify({ "schema_version": 1, "revision": 0 })
	assert_eq(SaveCodec.decode(incomplete).code, "MISSING_KEY")


func test_encode_rejects_engine_objects() -> void:
	var state := GameState.create_new(100, "save-alpha", 42)
	state.inventory = { "node": Node.new() }

	assert_eq(SaveCodec.encode(state), "")
	state.inventory.node.free()

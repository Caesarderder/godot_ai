class_name SaveMigrations
extends RefCounted

const GameStateScript := preload("res://game/scripts/state/game_state.gd")

const CURRENT_SCHEMA_VERSION := 1
const CONTAINER_KEYS := [
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
]


static func to_current(raw: Dictionary) -> Dictionary:
	var schema_version: Variant = raw.get("schema_version", -1)
	if typeof(schema_version) != TYPE_INT:
		return { }
	if schema_version == CURRENT_SCHEMA_VERSION:
		return raw.duplicate(true)
	if schema_version != 0:
		return { }
	return _migrate_v0(raw)


static func _migrate_v0(raw: Dictionary) -> Dictionary:
	var last_seen := _integer(raw.get("last_seen_wall_unix", raw.get("last_seen_unix", 0)), 0)
	var state := GameStateScript.create_new(
			last_seen,
			_string(raw.get("save_id", ""), ""),
			_integer(raw.get("run_seed", 0), 0),
	)
	state.content_version = _integer(raw.get("content_version", 1), 1)
	state.revision = _integer(raw.get("revision", raw.get("state_revision", 0)), 0)
	for key: String in CONTAINER_KEYS:
		var value: Variant = raw.get(key, { })
		if typeof(value) == TYPE_DICTIONARY:
			state[key] = value.duplicate(true)
	state.saved_at_unix = _integer(raw.get("saved_at_unix", 0), 0)
	state.last_seen_wall_unix = last_seen
	state.last_settled_unix = _integer(raw.get("last_settled_unix", 0), 0)
	state.offline_anchor_unix = _integer(raw.get("offline_anchor_unix", last_seen), last_seen)
	return state


static func _integer(value: Variant, fallback: int) -> int:
	return value if typeof(value) == TYPE_INT else fallback


static func _string(value: Variant, fallback: String) -> String:
	return value if typeof(value) == TYPE_STRING else fallback

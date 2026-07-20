class_name GameState
extends RefCounted

const SCHEMA_VERSION := 1
const CONTENT_VERSION := 1

const REQUIRED_KEYS := [
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


static func create_new(now_unix: int, save_id: String, run_seed: int) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"content_version": CONTENT_VERSION,
		"save_id": save_id,
		"run_seed": run_seed,
		"revision": 0,
		"roster": { },
		"inventory": { },
		"formation": { },
		"economy": { },
		"camp": { },
		"quest": { },
		"pity": { },
		"stage_progress": { },
		"attempt_counters": { },
		"receipt_ledgers": { },
		"saved_at_unix": 0,
		"last_seen_wall_unix": now_unix,
		"last_settled_unix": 0,
		"offline_anchor_unix": now_unix,
	}


static func clone(state: Dictionary) -> Dictionary:
	return state.duplicate(true)


static func validate(state: Dictionary) -> Dictionary:
	for key: String in REQUIRED_KEYS:
		if not state.has(key):
			return _failure("MISSING_KEY")
	if typeof(state["revision"]) != TYPE_INT or state["revision"] < 0:
		return _failure("INVALID_REVISION")
	if not _is_persistent_value(state):
		return _failure("INVALID_VALUE")
	return { "ok": true, "code": "OK" }


static func _is_persistent_value(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_ARRAY:
			for item: Variant in value:
				if not _is_persistent_value(item):
					return false
			return true
		TYPE_DICTIONARY:
			for key: Variant in value:
				if typeof(key) != TYPE_STRING or not _is_persistent_value(value[key]):
					return false
			return true
		_:
			return false


static func _failure(code: String) -> Dictionary:
	return { "ok": false, "code": code }

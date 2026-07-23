class_name GameState
extends RefCounted

const CampService := preload("res://game/scripts/domain/camp/camp_service.gd")
const QuestService := preload("res://game/scripts/domain/quests/quest_service.gd")
const HeroGenerator := preload("res://game/scripts/domain/heroes/hero_generator.gd")
const FormationReducer := preload("res://game/scripts/domain/formation/formation_reducer.gd")
const PityState := preload("res://game/scripts/domain/loot/pity_state.gd")

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
]

const RECEIPT_INDEX_KEYS := [
	"value_by_command",
	"value_by_business",
	"causal_by_command",
	"causal_by_business",
	"reversible_by_command",
	"reversible_by_business",
]

const TIME_KEYS := [
	"saved_at_unix",
	"last_seen_wall_unix",
	"last_settled_unix",
	"offline_anchor_unix",
]


static func create_new(now_unix: int, save_id: String, run_seed: int) -> Dictionary:
	var roster := _initial_roster(run_seed)
	return {
		"schema_version": SCHEMA_VERSION,
		"content_version": CONTENT_VERSION,
		"save_id": save_id,
		"run_seed": run_seed,
		"revision": 0,
		"roster": roster,
		"inventory": { "items": { } },
		"formation": { "slots": _initial_formation(roster) },
		"economy": {
			"gold": 250,
			"recruit_ticket": 4,
			"xp_book": 2,
			"forge_stone": 0,
			"recruit_tickets": 4,
			"experience_books": 2,
			"forge_stones": 0,
		},
		"camp": { "facilities": CampService.create_default() },
		"quest": QuestService.create_default(),
		"pity": PityState.create_empty(),
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


static func _initial_roster(run_seed: int) -> Dictionary:
	var roster: Dictionary = {}
	for hero: Dictionary in HeroGenerator.generate_roster(run_seed, 4):
		hero["equipment"] = {}
		roster[str(hero.id)] = hero
	return roster


static func _initial_formation(roster: Dictionary) -> Dictionary:
	var hero_ids: Array = roster.keys()
	hero_ids.sort()
	var slots: Dictionary = {}
	for index: int in FormationReducer.SLOT_ORDER.size():
		slots[FormationReducer.SLOT_ORDER[index]] = str(hero_ids[index])
	return slots


static func validate(state: Dictionary) -> Dictionary:
	for key: String in REQUIRED_KEYS:
		if not state.has(key):
			return _failure("MISSING_KEY")
	if typeof(state.schema_version) != TYPE_INT or state.schema_version != SCHEMA_VERSION:
		return _failure("INVALID_SCHEMA_VERSION")
	if typeof(state.content_version) != TYPE_INT or state.content_version < 0:
		return _failure("INVALID_CONTENT_VERSION")
	if typeof(state.save_id) != TYPE_STRING or state.save_id.is_empty():
		return _failure("INVALID_IDENTITY")
	if typeof(state.run_seed) != TYPE_INT:
		return _failure("INVALID_IDENTITY")
	if typeof(state["revision"]) != TYPE_INT or state["revision"] < 0:
		return _failure("INVALID_REVISION")
	for key: String in CONTAINER_KEYS:
		if typeof(state[key]) != TYPE_DICTIONARY:
			return _failure("INVALID_CONTAINER")
	for key: String in TIME_KEYS:
		if typeof(state[key]) != TYPE_INT or state[key] < 0:
			return _failure("INVALID_TIME")
	if not _valid_receipt_ledgers(state.receipt_ledgers):
		return _failure("INVALID_RECEIPT_LEDGERS")
	if not _is_persistent_value(state):
		return _failure("INVALID_VALUE")
	return { "ok": true, "code": "OK" }


static func _valid_receipt_ledgers(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var ledgers: Dictionary = value
	if ledgers.is_empty():
		return true
	for key: String in RECEIPT_INDEX_KEYS:
		if typeof(ledgers.get(key)) != TYPE_DICTIONARY:
			return false
		for receipt_key: Variant in ledgers[key]:
			if typeof(receipt_key) != TYPE_STRING:
				return false
			if typeof(ledgers[key][receipt_key]) != TYPE_DICTIONARY:
				return false
	if typeof(ledgers.get("reversible_order")) != TYPE_ARRAY:
		return false
	for command_id: Variant in ledgers.reversible_order:
		if typeof(command_id) != TYPE_STRING:
			return false
	return true


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

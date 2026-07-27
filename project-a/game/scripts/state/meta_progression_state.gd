class_name MetaProgressionState
extends RefCounted

const MAX_EVENT_KEYS: int = 4096

var commander_xp: int = 0
var commander_claimed_levels: Dictionary = {}
var daily_generation: int = 0
var weekly_generation: int = 0
var daily_key: String = ""
var weekly_key: String = ""
var missions: Dictionary = {}
var mission_claims: Dictionary = {}
var season_id: String = "season_1"
var season_merit: int = 0
var pass_claimed_levels: Dictionary = {}
var achievement_progress: Dictionary = {}
var achievement_claimed: Dictionary = {}
var event_keys: Dictionary = {}
var recruit_draw_count: int = 0
var recruit_s_pity: int = 0
var recruit_a_pity: int = 0
var recruit_target_guaranteed: bool = false
var recruit_pool_id: String = "signal_standard_1"
var hero_data: Dictionary = {}
var hero_fragments: Dictionary = {}


static func create_starting() -> MetaProgressionState:
	return MetaProgressionState.new()


func to_dict() -> Dictionary:
	return {
		"commander_xp": commander_xp,
		"commander_claimed_levels": commander_claimed_levels.duplicate(true),
		"daily_generation": daily_generation,
		"weekly_generation": weekly_generation,
		"daily_key": daily_key,
		"weekly_key": weekly_key,
		"missions": missions.duplicate(true),
		"mission_claims": mission_claims.duplicate(true),
		"season_id": season_id,
		"season_merit": season_merit,
		"pass_claimed_levels": pass_claimed_levels.duplicate(true),
		"achievement_progress": achievement_progress.duplicate(true),
		"achievement_claimed": achievement_claimed.duplicate(true),
		"event_keys": event_keys.duplicate(true),
		"recruit_draw_count": recruit_draw_count,
		"recruit_s_pity": recruit_s_pity,
		"recruit_a_pity": recruit_a_pity,
		"recruit_target_guaranteed": recruit_target_guaranteed,
		"recruit_pool_id": recruit_pool_id,
		"hero_data": hero_data.duplicate(true),
		"hero_fragments": hero_fragments.duplicate(true),
	}


static func from_dict(data: Dictionary) -> MetaProgressionState:
	var value := MetaProgressionState.new()
	value.commander_xp = maxi(0, int(data.get("commander_xp", 0)))
	value.commander_claimed_levels = (data.get("commander_claimed_levels", {}) as Dictionary).duplicate(true)
	value.daily_generation = maxi(0, int(data.get("daily_generation", 0)))
	value.weekly_generation = maxi(0, int(data.get("weekly_generation", 0)))
	value.daily_key = String(data.get("daily_key", ""))
	value.weekly_key = String(data.get("weekly_key", ""))
	value.missions = (data.get("missions", {}) as Dictionary).duplicate(true)
	value.mission_claims = (data.get("mission_claims", {}) as Dictionary).duplicate(true)
	value.season_id = String(data.get("season_id", "season_1"))
	value.season_merit = maxi(0, int(data.get("season_merit", 0)))
	value.pass_claimed_levels = (data.get("pass_claimed_levels", {}) as Dictionary).duplicate(true)
	value.achievement_progress = (data.get("achievement_progress", {}) as Dictionary).duplicate(true)
	value.achievement_claimed = (data.get("achievement_claimed", {}) as Dictionary).duplicate(true)
	value.event_keys = (data.get("event_keys", {}) as Dictionary).duplicate(true)
	value.recruit_draw_count = maxi(0, int(data.get("recruit_draw_count", 0)))
	value.recruit_s_pity = clampi(int(data.get("recruit_s_pity", 0)), 0, 59)
	value.recruit_a_pity = clampi(int(data.get("recruit_a_pity", 0)), 0, 9)
	value.recruit_target_guaranteed = bool(data.get("recruit_target_guaranteed", false))
	value.recruit_pool_id = String(data.get("recruit_pool_id", "signal_standard_1"))
	value.hero_data = (data.get("hero_data", {}) as Dictionary).duplicate(true)
	value.hero_fragments = {}
	for archetype_id_value in (data.get("hero_fragments", {}) as Dictionary):
		var archetype_id := String(archetype_id_value)
		value.hero_fragments[archetype_id] = maxi(
			0,
			int((data.get("hero_fragments", {}) as Dictionary)[archetype_id_value])
		)
	return value


func validate() -> Array[String]:
	var errors: Array[String] = []
	if commander_xp < 0 or season_merit < 0:
		errors.append("meta progression values must not be negative")
	if recruit_s_pity < 0 or recruit_s_pity >= 60:
		errors.append("recruit_s_pity must be 0..59")
	if recruit_a_pity < 0 or recruit_a_pity >= 10:
		errors.append("recruit_a_pity must be 0..9")
	if season_id.is_empty() or recruit_pool_id.is_empty():
		errors.append("meta progression identifiers are required")
	if event_keys.size() > MAX_EVENT_KEYS:
		errors.append("meta progression event ledger exceeds cap")
	for bucket in [commander_claimed_levels, missions, mission_claims, pass_claimed_levels, achievement_progress, achievement_claimed, event_keys, hero_data, hero_fragments]:
		if typeof(bucket) != TYPE_DICTIONARY:
			errors.append("meta progression bucket must be dictionary")
	for archetype_id_value in hero_fragments:
		if typeof(archetype_id_value) != TYPE_STRING or String(archetype_id_value).is_empty():
			errors.append("hero fragment keys must be non-empty strings")
		if typeof(hero_fragments[archetype_id_value]) != TYPE_INT or int(hero_fragments[archetype_id_value]) < 0:
			errors.append("hero fragment balances must be non-negative integers")
	return errors

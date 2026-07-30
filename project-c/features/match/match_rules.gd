class_name MatchRules
extends RefCounted

## Authoritative local-match facts for the original three-lane mode.
enum Lane { TOP, MID, BOTTOM }
const TEAM_SIZE := 5
const STARTING_GOLD := 500
const CORE_HP := 2400
const OUTER_TOWER_HP := 900

static func lane_name(lane: Lane) -> String:
	return ["TOP", "MID", "BOTTOM"][lane]

static func is_valid_team_roster(hero_ids: Array[String]) -> bool:
	if hero_ids.size() != TEAM_SIZE:
		return false
	var seen := {}
	for hero_id in hero_ids:
		if hero_id.is_empty() or seen.has(hero_id):
			return false
		seen[hero_id] = true
	return true

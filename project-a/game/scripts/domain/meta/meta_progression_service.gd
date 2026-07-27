class_name MetaProgressionService
extends RefCounted

const MetaCatalogScript := preload("res://game/scripts/domain/meta/meta_catalog.gd")


static func claimable_summary(state: RefCounted) -> Dictionary:
	var summary := {
		"commander": 0,
		"missions": 0,
		"pass": 0,
		"achievements": 0,
		"total": 0,
	}
	if state == null or state.get("meta_progression") == null:
		return summary
	var meta: RefCounted = state.meta_progression
	var unlock_state := MetaCatalogScript.unlocks(state)
	var commander_level := MetaCatalogScript.commander_level(int(meta.commander_xp))
	for level in range(2, commander_level + 1):
		if not meta.commander_claimed_levels.has(str(level)):
			summary["commander"] = int(summary["commander"]) + 1
	if bool(unlock_state["missions"]):
		for mission_id in meta.missions:
			var record := meta.missions[mission_id] as Dictionary
			var generation := int(record.get("generation", -1))
			var claim_key := "%s:%d" % [String(mission_id), generation]
			var weekly_locked := String(mission_id).begins_with("weekly.") and not bool(unlock_state["weekly"])
			if (
				not weekly_locked
				and not meta.mission_claims.has(claim_key)
				and int(record.get("progress", 0)) >= int(record.get("target", 1))
			):
				summary["missions"] = int(summary["missions"]) + 1
	if bool(unlock_state["pass"]):
		var reached := MetaCatalogScript.pass_level(int(meta.season_merit))
		for level in range(1, reached + 1):
			if not meta.pass_claimed_levels.has("%s:%d" % [meta.season_id, level]):
				summary["pass"] = int(summary["pass"]) + 1
	if bool(unlock_state["achievements"]):
		for definition in MetaCatalogScript.ACHIEVEMENTS:
			var achievement_id := String(definition["id"])
			if (
				not meta.achievement_claimed.has(achievement_id)
				and int(meta.achievement_progress.get(achievement_id, 0)) >= int(definition["target"])
			):
				summary["achievements"] = int(summary["achievements"]) + 1
	summary["total"] = (
		int(summary["commander"])
		+ int(summary["missions"])
		+ int(summary["pass"])
		+ int(summary["achievements"])
	)
	return summary


static func refresh(state: RefCounted, now_unix: int) -> Dictionary:
	var meta: RefCounted = state.meta_progression
	var day_key := str(maxi(0, now_unix) / 86400)
	var week_key := str(maxi(0, now_unix) / 604800)
	var season_key := "season_%d" % (maxi(0, now_unix) / 2419200)
	var previous_season := String(meta.season_id)
	var rollover := {"levels": [], "reward": _empty_reward_total()}
	if meta.season_id != season_key:
		rollover = _grant_unclaimed_pass_rewards(state)
		meta.season_id = season_key
		meta.season_merit = 0
		meta.pass_claimed_levels.clear()
	if meta.daily_key != day_key:
		meta.daily_key = day_key
		meta.daily_generation += 1
		_replace_scope(meta, MetaCatalogScript.DAILY, "daily", meta.daily_generation)
	if meta.weekly_key != week_key:
		meta.weekly_key = week_key
		meta.weekly_generation += 1
		_replace_scope(meta, MetaCatalogScript.WEEKLY, "weekly", meta.weekly_generation)
	_backfill_achievements(state)
	return {
		"ok": true,
		"event": {
			"type": "meta_refreshed",
			"daily_key": day_key,
			"weekly_key": week_key,
			"season_id": season_key,
			"previous_season_id": previous_season,
			"rollover_claimed_levels": rollover["levels"],
			"rollover_reward": rollover["reward"],
		},
	}


static func apply_gameplay_event(state: RefCounted, event: Dictionary, event_key: String) -> void:
	var meta: RefCounted = state.meta_progression
	if meta.missions.is_empty():
		refresh(state, maxi(0, int(state.saved_at_unix)))
	if event_key.is_empty() or meta.event_keys.has(event_key):
		return
	meta.event_keys[event_key] = true
	if meta.event_keys.size() > meta.MAX_EVENT_KEYS:
		meta.event_keys.erase(meta.event_keys.keys()[0])
	var old_level := MetaCatalogScript.commander_level(meta.commander_xp)
	var event_type := String(event.get("type", ""))
	if event_type == "battle_settled" and String(event.get("reward_tier", "")) == "first_victory":
		var stage_id := String(event.get("stage_id", ""))
		var first_chapter_xp := {"stage_1_1": 20, "stage_1_2": 25, "stage_1_3": 30, "stage_1_4": 40, "stage_1_5": 60}
		meta.commander_xp += int(first_chapter_xp.get(stage_id, 20))
	elif event_type == "onboarding_task_claimed":
		meta.commander_xp += 40
	var new_level := MetaCatalogScript.commander_level(meta.commander_xp)
	if old_level < 4 and new_level >= 4:
		state.economy.grant({"recruit_tickets": 1})
	var deltas := _event_metrics(event)
	for metric in deltas:
		_increment_missions(meta, String(metric), int(deltas[metric]))
		_increment_achievements(meta, String(metric), int(deltas[metric]))
	if String(event.get("type", "")) in ["hero_upgraded", "permanent_hero_upgraded", "hero_trained"]:
		_set_achievement_metric(meta, "max_hero_level", _max_hero_level(state))
	if String(event.get("type", "")) in ["hero_star_upgraded", "permanent_hero_star_upgraded"]:
		_set_achievement_metric(meta, "max_hero_star", _max_hero_star(state))
	_set_achievement_metric(meta, "roster_size", state.roster.size())


static func claim_mission(state: RefCounted, mission_id: String, generation: int) -> Dictionary:
	var unlock_state := MetaCatalogScript.unlocks(state)
	if not bool(unlock_state["missions"]):
		return {"ok": false, "error": "META_MISSIONS_LOCKED"}
	if mission_id.begins_with("weekly.") and not bool(unlock_state["weekly"]):
		return {"ok": false, "error": "META_WEEKLY_LOCKED"}
	var meta: RefCounted = state.meta_progression
	if not meta.missions.has(mission_id):
		return {"ok": false, "error": "META_MISSION_NOT_FOUND"}
	var record := meta.missions[mission_id] as Dictionary
	if int(record.get("generation", -1)) != generation:
		return {"ok": false, "error": "META_MISSION_GENERATION_MISMATCH"}
	var claim_key := "%s:%d" % [mission_id, generation]
	if meta.mission_claims.has(claim_key):
		return {"ok": false, "error": "META_MISSION_ALREADY_CLAIMED"}
	if int(record.get("progress", 0)) < int(record.get("target", 1)):
		return {"ok": false, "error": "META_MISSION_NOT_COMPLETED"}
	var definition := MetaCatalogScript.mission_def(mission_id)
	if definition.is_empty():
		return {"ok": false, "error": "META_MISSION_DEFINITION_MISSING"}
	meta.commander_xp += int(definition.get("xp", 0))
	meta.season_merit += int(definition.get("merit", 0))
	state.economy.grant({"toilet_coins": int(definition.get("gold", 0)), "recruit_tickets": int(definition.get("tickets", 0))})
	meta.mission_claims[claim_key] = true
	return {"ok": true, "event": {"type": "meta_mission_claimed", "mission_id": mission_id, "generation": generation, "reward": definition}}


static func claim_pass_level(state: RefCounted, level: int) -> Dictionary:
	if not bool(MetaCatalogScript.unlocks(state)["pass"]):
		return {"ok": false, "error": "META_PASS_LOCKED"}
	var meta: RefCounted = state.meta_progression
	if MetaCatalogScript.commander_level(meta.commander_xp) < 5:
		return {"ok": false, "error": "PASS_LOCKED"}
	if level < 1 or level > MetaCatalogScript.pass_level(meta.season_merit):
		return {"ok": false, "error": "PASS_LEVEL_NOT_REACHED"}
	var key := "%s:%d" % [meta.season_id, level]
	if meta.pass_claimed_levels.has(key):
		return {"ok": false, "error": "PASS_LEVEL_ALREADY_CLAIMED"}
	var reward := MetaCatalogScript.pass_reward(level)
	state.economy.grant(reward)
	state.factory.grant(reward)
	meta.pass_claimed_levels[key] = true
	return {"ok": true, "event": {"type": "pass_reward_claimed", "level": level, "season_id": meta.season_id, "reward": reward}}


static func claim_all_pass_levels(state: RefCounted) -> Dictionary:
	var meta: RefCounted = state.meta_progression
	if MetaCatalogScript.commander_level(meta.commander_xp) < 5:
		return {"ok": false, "error": "PASS_LOCKED"}
	var reached := MetaCatalogScript.pass_level(meta.season_merit)
	var claimed: Array[int] = []
	var total := _empty_reward_total()
	for level in range(1, reached + 1):
		var key := "%s:%d" % [meta.season_id, level]
		if meta.pass_claimed_levels.has(key):
			continue
		var reward := MetaCatalogScript.pass_reward(level)
		state.economy.grant(reward)
		state.factory.grant(reward)
		for resource_id in total:
			total[resource_id] = int(total[resource_id]) + int(reward.get(resource_id, 0))
		meta.pass_claimed_levels[key] = true
		claimed.append(level)
	if claimed.is_empty():
		return {"ok": false, "error": "PASS_NO_CLAIMABLE_REWARDS"}
	return {"ok": true, "event": {"type": "pass_rewards_claimed", "levels": claimed, "season_id": meta.season_id, "reward": total}}


static func claim_commander_level(state: RefCounted, level: int) -> Dictionary:
	var meta: RefCounted = state.meta_progression
	if level < 2 or level > MetaCatalogScript.commander_level(meta.commander_xp):
		return {"ok": false, "error": "COMMANDER_LEVEL_NOT_REACHED"}
	if meta.commander_claimed_levels.has(str(level)):
		return {"ok": false, "error": "COMMANDER_LEVEL_ALREADY_CLAIMED"}
	var reward := MetaCatalogScript.commander_reward(level)
	state.economy.grant(reward)
	state.factory.grant(reward)
	meta.commander_claimed_levels[str(level)] = true
	return {"ok": true, "event": {"type": "commander_level_reward_claimed", "level": level, "reward": reward}}


static func claim_all_commander_levels(state: RefCounted) -> Dictionary:
	var meta: RefCounted = state.meta_progression
	var reached := MetaCatalogScript.commander_level(meta.commander_xp)
	var claimed: Array[int] = []
	var total := _empty_reward_total()
	for level in range(2, reached + 1):
		if meta.commander_claimed_levels.has(str(level)):
			continue
		var reward := MetaCatalogScript.commander_reward(level)
		state.economy.grant(reward)
		state.factory.grant(reward)
		for resource_id in total:
			total[resource_id] = int(total[resource_id]) + int(reward.get(resource_id, 0))
		meta.commander_claimed_levels[str(level)] = true
		claimed.append(level)
	if claimed.is_empty():
		return {"ok": false, "error": "COMMANDER_NO_CLAIMABLE_REWARDS"}
	return {"ok": true, "event": {"type": "commander_level_rewards_claimed", "levels": claimed, "reward": total}}


static func _grant_unclaimed_pass_rewards(state: RefCounted) -> Dictionary:
	var meta: RefCounted = state.meta_progression
	var reached := MetaCatalogScript.pass_level(meta.season_merit)
	var levels: Array[int] = []
	var total := _empty_reward_total()
	for level in range(1, reached + 1):
		var key := "%s:%d" % [meta.season_id, level]
		if meta.pass_claimed_levels.has(key):
			continue
		var reward := MetaCatalogScript.pass_reward(level)
		state.economy.grant(reward)
		state.factory.grant(reward)
		for resource_id in total:
			total[resource_id] = int(total[resource_id]) + int(reward.get(resource_id, 0))
		levels.append(level)
	return {"levels": levels, "reward": total}


static func _empty_reward_total() -> Dictionary:
	return {
		"toilet_coins": 0,
		"porcelain": 0,
		"recruit_tickets": 0,
		"hero_shards": 0,
	}


static func claim_achievement(state: RefCounted, achievement_id: String) -> Dictionary:
	if not bool(MetaCatalogScript.unlocks(state)["achievements"]):
		return {"ok": false, "error": "META_ACHIEVEMENTS_LOCKED"}
	var meta: RefCounted = state.meta_progression
	var definition := MetaCatalogScript.achievement_def(achievement_id)
	if definition.is_empty():
		return {"ok": false, "error": "META_ACHIEVEMENT_NOT_FOUND"}
	if meta.achievement_claimed.has(achievement_id):
		return {"ok": false, "error": "META_ACHIEVEMENT_ALREADY_CLAIMED"}
	if int(meta.achievement_progress.get(achievement_id, 0)) < int(definition["target"]):
		return {"ok": false, "error": "META_ACHIEVEMENT_NOT_COMPLETED"}
	meta.commander_xp += int(definition.get("xp", 0))
	state.economy.grant({"recruit_tickets": int(definition.get("tickets", 0))})
	meta.achievement_claimed[achievement_id] = true
	return {"ok": true, "event": {"type": "meta_achievement_claimed", "achievement_id": achievement_id, "reward": definition}}


static func claim_all_achievements(state: RefCounted) -> Dictionary:
	if not bool(MetaCatalogScript.unlocks(state)["achievements"]):
		return {"ok": false, "error": "META_ACHIEVEMENTS_LOCKED"}
	var meta: RefCounted = state.meta_progression
	var claimed: Array[String] = []
	var total_xp := 0
	var total_tickets := 0
	for definition in MetaCatalogScript.ACHIEVEMENTS:
		var achievement_id := String(definition["id"])
		if meta.achievement_claimed.has(achievement_id):
			continue
		if int(meta.achievement_progress.get(achievement_id, 0)) < int(definition["target"]):
			continue
		total_xp += int(definition.get("xp", 0))
		total_tickets += int(definition.get("tickets", 0))
		meta.achievement_claimed[achievement_id] = true
		claimed.append(achievement_id)
	if claimed.is_empty():
		return {"ok": false, "error": "ACHIEVEMENT_NO_CLAIMABLE_REWARDS"}
	meta.commander_xp += total_xp
	state.economy.grant({"recruit_tickets": total_tickets})
	return {"ok": true, "event": {
		"type": "meta_achievements_claimed",
		"achievement_ids": claimed,
		"reward": {"xp": total_xp, "recruit_tickets": total_tickets},
	}}


static func _replace_scope(meta: RefCounted, definitions: Array[Dictionary], scope: String, generation: int) -> void:
	for old_id in meta.missions.keys().duplicate():
		if String(old_id).begins_with(scope + "."):
			meta.missions.erase(old_id)
	for definition in definitions:
		meta.missions[String(definition["id"])] = {
			"generation": generation,
			"progress": 0,
			"target": int(definition["target"]),
		}


static func _event_metrics(event: Dictionary) -> Dictionary:
	var event_type := String(event.get("type", ""))
	match event_type:
		"facility_output_claimed":
			return {"facility_claims": 1}
		"factory_output_claimed":
			return {"facility_claims": 3}
		"facility_upgraded":
			return {"facility_upgrades": 1, "growth_actions": 1}
		"hero_upgraded", "permanent_hero_upgraded", "hero_trained", "hero_star_upgraded", "permanent_hero_star_upgraded", "active_skill_researched":
			return {"cultivation_actions": 1, "growth_actions": 1}
		"hero_repaired", "timed_repairs_claimed":
			return {"repairs": 1, "growth_actions": 1}
		"battle_settled":
			var values := {"battles": 1}
			if String(event.get("outcome", "")) == "victory":
				values["victories"] = 1
				if String(event.get("reward_tier", "")) == "first_victory":
					values["first_clears"] = 1
			return values
		"signal_recruit_resolved":
			return {"recruit_draws": int(event.get("count", 1))}
	return {}


static func _increment_missions(meta: RefCounted, metric: String, amount: int) -> void:
	for mission_id in meta.missions:
		var definition := MetaCatalogScript.mission_def(String(mission_id))
		if String(definition.get("metric", "")) != metric:
			continue
		var record := meta.missions[mission_id] as Dictionary
		record["progress"] = mini(int(record["target"]), int(record.get("progress", 0)) + amount)


static func _increment_achievements(meta: RefCounted, metric: String, amount: int) -> void:
	for definition in MetaCatalogScript.ACHIEVEMENTS:
		if String(definition["metric"]) == metric:
			var id := String(definition["id"])
			meta.achievement_progress[id] = mini(int(definition["target"]), int(meta.achievement_progress.get(id, 0)) + amount)


static func _set_achievement_metric(meta: RefCounted, metric: String, value: int) -> void:
	for definition in MetaCatalogScript.ACHIEVEMENTS:
		if String(definition["metric"]) == metric:
			var id := String(definition["id"])
			meta.achievement_progress[id] = mini(int(definition["target"]), maxi(int(meta.achievement_progress.get(id, 0)), value))


static func _backfill_achievements(state: RefCounted) -> void:
	var meta: RefCounted = state.meta_progression
	_set_achievement_metric(meta, "first_clears", (state.stage_progress.get("cleared_stages", []) as Array).size())
	_set_achievement_metric(meta, "max_hero_level", _max_hero_level(state))
	_set_achievement_metric(meta, "max_hero_star", _max_hero_star(state))
	_set_achievement_metric(meta, "roster_size", state.roster.size())


static func _max_hero_level(state: RefCounted) -> int:
	var value := 1
	for hero in state.roster:
		value = maxi(value, int(hero.level))
	return value


static func _max_hero_star(state: RefCounted) -> int:
	var value := 1
	for hero in state.roster:
		value = maxi(value, int(hero.star))
	return value

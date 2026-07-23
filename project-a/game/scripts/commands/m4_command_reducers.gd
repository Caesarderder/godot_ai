class_name M4CommandReducers
extends RefCounted

const CampService := preload("res://game/scripts/domain/camp/camp_service.gd")
const QuestService := preload("res://game/scripts/domain/quests/quest_service.gd")
const HeroGenerator := preload("res://game/scripts/domain/heroes/hero_generator.gd")
const HeroProgression := preload("res://game/scripts/domain/heroes/hero_progression.gd")
const FormationReducer := preload("res://game/scripts/domain/formation/formation_reducer.gd")
const EquipmentService := preload("res://game/scripts/domain/loot/equipment_service.gd")
const LootGenerator := preload("res://game/scripts/domain/loot/loot_generator.gd")
const PityState := preload("res://game/scripts/domain/loot/pity_state.gd")

const STAGE_REWARDS := {
	"stage-1-1": {
		"first_win": {"gold": 120},
	},
	"stage-1-2": {
		"first_win": {"gold": 180},
	},
	"stage-1-3": {
		"first_loss": {"gold": 100, "xp_book": 2},
		"first_win": {"gold": 300, "xp_book": 2, "forge_stone": 1},
	},
	"stage-1-4": {
		"first_win": {"gold": 430, "xp_book": 3, "forge_stone": 3},
	},
	"stage-1-5": {
		"first_loss": {"gold": 150, "xp_book": 1, "forge_stone": 2},
		"first_win": {"gold": 400, "xp_book": 1, "forge_stone": 3},
	},
}


static func supported_commands() -> Array[StringName]:
	return [
		&"recruit_hero",
		&"train_hero",
		&"enhance_item",
		&"upgrade_facility",
		&"claim_reward",
		&"settle_battle_result",
		&"settle_offline",
		&"reserve_battle_attempt",
		&"set_formation",
		&"equip_item",
	]


static func reduce(command_type: StringName, candidate: Dictionary, payload: Dictionary) -> Dictionary:
	match command_type:
		&"recruit_hero":
			return _recruit_hero(candidate, payload)
		&"train_hero":
			return _train_hero(candidate, payload)
		&"enhance_item":
			return _enhance_item(candidate, payload)
		&"upgrade_facility":
			return _upgrade_facility(candidate, payload)
		&"claim_reward":
			return _claim_reward(candidate, payload)
		&"settle_battle_result":
			return _settle_battle_result(candidate, payload)
		&"settle_offline":
			return _settle_offline(candidate, payload)
		&"reserve_battle_attempt":
			return _reserve_battle_attempt(candidate, payload)
		&"set_formation":
			return _set_formation(candidate, payload)
		&"equip_item":
			return _equip_item(candidate, payload)
	return {"ok": false, "code": "UNKNOWN_COMMAND"}


static func _recruit_hero(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var roster: Dictionary = candidate.get("roster", {})
	var economy: Dictionary = candidate.get("economy", {})
	var ticket_key := _first_existing_key(economy, ["recruit_ticket", "recruit_tickets"])
	if int(economy.get(ticket_key, 0)) < 1:
		return {"ok": false, "code": "INSUFFICIENT_RECRUIT_TICKETS"}
	var seed := int(payload.get("seed", candidate.get("run_seed", 0)))
	var index := maxi(0, int(payload.get("index", roster.size())))
	var generated: Array[Dictionary] = HeroGenerator.generate_roster(seed, index + 1)
	if generated.is_empty():
		return {"ok": false, "code": "GENERATION_FAILED"}
	var hero: Dictionary = generated[index].duplicate(true)
	if payload.has("hero_id"):
		hero["id"] = str(payload.hero_id)
	if roster.has(str(hero.id)):
		return {"ok": false, "code": "HERO_ALREADY_EXISTS"}
	if not hero.has("equipment") or not hero.equipment is Dictionary:
		hero["equipment"] = {}
	_set_resource_pair(
		economy,
		"recruit_ticket",
		"recruit_tickets",
		int(economy.get(ticket_key, 0)) - 1
	)
	roster[str(hero.id)] = hero
	candidate["roster"] = roster
	candidate["economy"] = economy
	return {
		"ok": true,
		"result": {"hero_id": str(hero.id), "hero": hero.duplicate(true)},
		"events": [{
			"event_id": "hero:%s:recruited" % str(hero.id),
			"type": "hero_recruited",
			"amount": 1,
		}],
	}


static func _train_hero(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var hero_id := str(payload.get("hero_id", ""))
	var roster: Dictionary = candidate.get("roster", {})
	if not roster.has(hero_id):
		return {"ok": false, "code": "UNKNOWN_HERO"}
	var xp_amount := maxi(0, int(payload.get("xp_amount", 40)))
	var xp_books := maxi(0, int(payload.get("xp_books", 1 if not payload.has("xp_amount") else 0)))
	var gold_cost := maxi(0, int(payload.get("gold_cost", xp_books * 60)))
	var economy: Dictionary = candidate.get("economy", {})
	var book_key := _first_existing_key(economy, ["xp_book", "experience_books"])
	if xp_books > 0:
		if int(economy.get(book_key, 0)) < xp_books:
			return {"ok": false, "code": "INSUFFICIENT_XP_BOOKS"}
	if int(economy.get("gold", 0)) < gold_cost:
		return {"ok": false, "code": "INSUFFICIENT_GOLD"}
	_set_resource_pair(
		economy,
		"xp_book",
		"experience_books",
		int(economy.get(book_key, 0)) - xp_books
	)
	economy["gold"] = int(economy.get("gold", 0)) - gold_cost
	var before_level := int(roster[hero_id].get("level", 1))
	var trained: Dictionary = HeroProgression.add_xp(roster[hero_id], xp_amount)
	roster[hero_id] = trained
	candidate["roster"] = roster
	candidate["economy"] = economy
	return {
		"ok": true,
		"result": {
			"hero_id": hero_id,
			"level": int(trained.get("level", 1)),
			"xp": int(trained.get("xp", 0)),
			"xp_spent": xp_amount,
			"xp_books_spent": xp_books,
			"gold_spent": gold_cost,
		},
		"events": [{
			"event_id": "hero:%s:xp:%d" % [hero_id, int(trained.get("xp", 0))],
			"type": "hero_trained",
			"amount": maxi(1, int(trained.get("level", 1)) - before_level),
		}],
	}


static func _enhance_item(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var item_id := str(payload.get("item_id", ""))
	var normalized := _with_plural_economy_aliases(candidate)
	var enhanced: Dictionary = EquipmentService.enhance(normalized, item_id)
	if not enhanced.get("ok", false):
		return {"ok": false, "code": str(enhanced.get("code", "INVARIANT_FAILED"))}
	_copy_state(candidate, enhanced.state)
	_sync_singular_from_plural(candidate)
	return {
		"ok": true,
		"result": {
			"item_id": item_id,
			"enhancement": int(candidate.inventory.items[item_id].enhancement),
		},
		"events": _events_with_ids(enhanced.events, "item:%s:enhanced:%d" % [
			item_id,
			int(candidate.inventory.items[item_id].enhancement),
		]),
	}


static func _upgrade_facility(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var facility_id := str(payload.get("facility_id", ""))
	var camp_root: Dictionary = candidate.get("camp", {})
	var facilities: Dictionary = camp_root.get("facilities", {})
	var upgraded: Dictionary = CampService.upgrade(
		facilities,
		facility_id,
		int(candidate.get("economy", {}).get("gold", 0))
	)
	if not upgraded.get("ok", false):
		return {"ok": false, "code": str(upgraded.get("code", "INVARIANT_FAILED"))}
	camp_root["facilities"] = upgraded.camp
	candidate["camp"] = camp_root
	var economy: Dictionary = candidate.get("economy", {})
	economy["gold"] = int(upgraded.gold)
	candidate["economy"] = economy
	return {
		"ok": true,
		"result": {
			"facility_id": facility_id,
			"level": int(upgraded.camp[facility_id].level),
			"spent": int(upgraded.spent),
		},
		"events": [{
			"event_id": "facility:%s:level:%d" % [facility_id, int(upgraded.camp[facility_id].level)],
			"type": "facility_upgraded",
			"amount": 1,
		}],
	}


static func _claim_reward(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var quest_id := str(payload.get("quest_id", ""))
	var claimed: Dictionary = QuestService.claim_reward(candidate.get("quest", {}), quest_id)
	if not claimed.get("ok", false):
		return {"ok": false, "code": str(claimed.get("code", "INVARIANT_FAILED"))}
	var economy_result := _apply_economy_delta(
		candidate.get("economy", {}),
		claimed.get("reward", {})
	)
	if not economy_result.ok:
		return economy_result
	candidate["quest"] = claimed.quest_state
	candidate["economy"] = economy_result.economy
	return {
		"ok": true,
		"result": {
			"quest_id": quest_id,
			"reward": claimed.reward.duplicate(true),
		},
		"events": _reward_events(quest_id, claimed.reward),
	}


static func _settle_battle_result(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var stage_id := str(payload.get("stage_id", ""))
	var outcome := str(payload.get("outcome", ""))
	if stage_id.is_empty() or outcome.is_empty():
		return {"ok": false, "code": "INVALID_PAYLOAD"}
	if not ["win", "victory", "loss", "defeat", "draw"].has(outcome):
		return {"ok": false, "code": "INVALID_OUTCOME"}
	var stage_progress: Dictionary = candidate.get("stage_progress", {})
	var stage: Dictionary = stage_progress.get(stage_id, {})
	if not stage.has("rewards_claimed") or not stage.rewards_claimed is Dictionary:
		stage["rewards_claimed"] = {}
	stage["attempted"] = true
	stage["last_outcome"] = outcome
	if outcome == "win" or outcome == "victory":
		stage["cleared"] = true
		if bool(payload.get("first_clear", false)):
			stage["first_clear"] = true
	stage_progress[stage_id] = stage
	candidate["stage_progress"] = stage_progress

	var events: Array = [{
		"event_id": "battle:%s:%s" % [stage_id, outcome],
		"type": "battle_won" if (outcome == "win" or outcome == "victory") else "battle_completed",
		"amount": 1,
	}]
	if stage.get("cleared", false):
		events.append({
			"event_id": "stage:%s:completed" % stage_id,
			"type": "stage_completed",
			"amount": 1,
		})
	var reward_key := "first_win" if (outcome == "win" or outcome == "victory") else "first_loss"
	var reward: Dictionary = _claim_stage_reward(candidate, stage_id, reward_key)
	if not reward.get("ok", false):
		return reward
	events.append_array(reward.get("events", []))
	return {
		"ok": true,
		"result": {
			"stage_id": stage_id,
			"outcome": outcome,
			"cleared": bool(stage.get("cleared", false)),
			"reward": reward.get("reward", {}),
		},
		"events": events,
	}


static func _settle_offline(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var credited := maxi(0, int(payload.get("credited_seconds", payload.get("seconds", 0))))
	var economy: Dictionary = candidate.get("economy", {})
	economy["offline_seconds"] = int(economy.get("offline_seconds", 0)) + credited
	candidate["economy"] = economy
	return {
		"ok": true,
		"result": {"credited_seconds": credited},
		"events": [{
			"event_id": "offline:%d" % int(payload.get("now_unix", credited)),
			"type": "offline_settled",
			"amount": 1,
		}],
	}


static func _reserve_battle_attempt(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var stage_id := str(payload.get("stage_id", ""))
	if not QuestService.can_start_stage(stage_id, candidate.get("quest", {})):
		return {"ok": false, "code": "STAGE_LOCKED"}
	var attempts: Dictionary = candidate.get("attempt_counters", {})
	var count := int(attempts.get(stage_id, 0)) + 1
	attempts[stage_id] = count
	candidate["attempt_counters"] = attempts
	return {
		"ok": true,
		"result": {"stage_id": stage_id, "attempt": count},
		"events": [{
			"event_id": "stage:%s:attempt:%d" % [stage_id, count],
			"type": "battle_started",
			"amount": 1,
		}],
	}


static func _set_formation(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var slots_variant: Variant = payload.get("slots", {})
	if not slots_variant is Dictionary:
		return {"ok": false, "code": "INVALID_PAYLOAD"}
	var roster_ids: Array[String] = _roster_ids(candidate.get("roster", {}))
	var validation: Dictionary = FormationReducer.validate(slots_variant, roster_ids)
	if not bool(validation.valid):
		return {"ok": false, "code": "INVALID_FORMATION", "detail": str(validation.errors)}
	var changed: Dictionary = FormationReducer.set_formation(
		candidate.get("formation", {}),
		slots_variant,
		roster_ids
	)
	candidate["formation"] = changed
	return {
		"ok": true,
		"result": {"slots": changed.get("slots", {}).duplicate(true)},
		"events": [{
			"event_id": "formation:%s" % _stable_slots_key(changed.get("slots", {})),
			"type": "formation_changed",
			"amount": 1,
		}],
	}


static func _equip_item(candidate: Dictionary, payload: Dictionary) -> Dictionary:
	var hero_id := str(payload.get("hero_id", ""))
	var item_id := str(payload.get("item_id", ""))
	var equipped: Dictionary = EquipmentService.equip(candidate, hero_id, item_id)
	if not equipped.get("ok", false):
		return {"ok": false, "code": str(equipped.get("code", "INVARIANT_FAILED"))}
	_copy_state(candidate, equipped.state)
	return {
		"ok": true,
		"result": {"hero_id": hero_id, "item_id": item_id},
		"events": _events_with_ids(equipped.events, "item:%s:equipped:%s" % [item_id, hero_id]),
	}


static func _apply_economy_delta(economy: Dictionary, delta: Dictionary) -> Dictionary:
	var result := economy.duplicate(true)
	for resource: String in delta:
		var next_value := int(result.get(resource, 0)) + int(delta[resource])
		if next_value < 0:
			return {"ok": false, "code": "NEGATIVE_BALANCE", "economy": economy}
		result[resource] = next_value
	return {"ok": true, "code": "OK", "economy": result}


static func _claim_stage_reward(
	candidate: Dictionary,
	stage_id: String,
	reward_key: String
) -> Dictionary:
	var reward_table: Dictionary = STAGE_REWARDS.get(stage_id, {})
	var reward_delta: Dictionary = reward_table.get(reward_key, {})
	if reward_delta.is_empty():
		return {"ok": true, "code": "OK", "reward": {}, "events": []}
	var stage_progress: Dictionary = candidate.get("stage_progress", {})
	var stage: Dictionary = stage_progress.get(stage_id, {})
	var claimed: Dictionary = stage.get("rewards_claimed", {})
	if bool(claimed.get(reward_key, false)):
		return {"ok": true, "code": "OK", "reward": {}, "events": []}
	var economy_result := _apply_economy_delta(candidate.get("economy", {}), reward_delta)
	if not economy_result.ok:
		return economy_result
	candidate["economy"] = economy_result.economy
	_sync_plural_from_singular(candidate)
	claimed[reward_key] = true
	stage["rewards_claimed"] = claimed
	stage_progress[stage_id] = stage
	candidate["stage_progress"] = stage_progress
	var events := _reward_events("%s:%s" % [stage_id, reward_key], reward_delta)
	if stage_id == "stage-1-3" and reward_key == "first_win":
		var item_result := _grant_stage_one_three_guarantee(candidate)
		events.append_array(item_result.events)
	return {
		"ok": true,
		"code": "OK",
		"reward": reward_delta.duplicate(true),
		"events": events,
	}


static func _grant_stage_one_three_guarantee(candidate: Dictionary) -> Dictionary:
	var inventory: Dictionary = candidate.get("inventory", {})
	var items: Dictionary = inventory.get("items", {})
	var drop_index := items.size() + 1
	var base_item := LootGenerator.create_item(
		int(candidate.get("run_seed", 0)),
		drop_index,
		"guardian_blade",
		"white",
		[]
	)
	var resolved: Dictionary = PityState.resolve_qualifying_drop(
		candidate.get("pity", {}),
		base_item,
		"stage-1-3",
		["guardian_blade"]
	)
	var item: Dictionary = resolved.item
	items[str(item.id)] = item
	inventory["items"] = items
	candidate["inventory"] = inventory
	candidate["pity"] = resolved.pity
	return {
		"events": [{
			"event_id": "stage:stage-1-3:guaranteed-blue:%s" % str(item.id),
			"type": "item_dropped",
			"amount": 1,
			"item_id": str(item.id),
			"quality": str(item.quality),
			"guaranteed": bool(resolved.guaranteed),
		}]
	}


static func _reward_events(source_id: String, reward: Dictionary) -> Array:
	var events: Array = []
	for resource: String in reward:
		var amount := int(reward[resource])
		if amount <= 0:
			continue
		events.append({
			"event_id": "reward:%s:%s" % [source_id, resource],
			"type": "%s_earned" % resource,
			"amount": amount,
		})
	return events


static func _roster_ids(roster: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for hero_id: String in roster:
		ids.append(hero_id)
	return ids


static func _copy_state(target: Dictionary, source: Dictionary) -> void:
	for key: String in source:
		target[key] = source[key]


static func _with_plural_economy_aliases(state: Dictionary) -> Dictionary:
	var result := state.duplicate(true)
	var economy: Dictionary = result.get("economy", {}).duplicate(true)
	if economy.has("forge_stone") and not economy.has("forge_stones"):
		economy["forge_stones"] = int(economy.forge_stone)
	if economy.has("recruit_ticket") and not economy.has("recruit_tickets"):
		economy["recruit_tickets"] = int(economy.recruit_ticket)
	if economy.has("xp_book") and not economy.has("experience_books"):
		economy["experience_books"] = int(economy.xp_book)
	result["economy"] = economy
	return result


static func _sync_singular_from_plural(state: Dictionary) -> void:
	var economy: Dictionary = state.get("economy", {})
	if economy.has("forge_stones"):
		economy["forge_stone"] = int(economy.forge_stones)
	if economy.has("recruit_tickets"):
		economy["recruit_ticket"] = int(economy.recruit_tickets)
	if economy.has("experience_books"):
		economy["xp_book"] = int(economy.experience_books)
	state["economy"] = economy


static func _sync_plural_from_singular(state: Dictionary) -> void:
	var economy: Dictionary = state.get("economy", {})
	if economy.has("forge_stone"):
		economy["forge_stones"] = int(economy.forge_stone)
	if economy.has("recruit_ticket"):
		economy["recruit_tickets"] = int(economy.recruit_ticket)
	if economy.has("xp_book"):
		economy["experience_books"] = int(economy.xp_book)
	state["economy"] = economy


static func _set_resource_pair(
	economy: Dictionary,
	singular: String,
	plural: String,
	value: int
) -> void:
	economy[singular] = value
	economy[plural] = value


static func _first_existing_key(economy: Dictionary, keys: Array[String]) -> String:
	for key: String in keys:
		if economy.has(key):
			return key
	return keys[0]


static func _events_with_ids(events: Array, fallback_id: String) -> Array:
	var result: Array = []
	for index: int in range(events.size()):
		if not events[index] is Dictionary:
			continue
		var event: Dictionary = events[index].duplicate(true)
		if str(event.get("event_id", "")).is_empty():
			event["event_id"] = fallback_id if index == 0 else "%s:%d" % [fallback_id, index]
		if not event.has("amount"):
			event["amount"] = 1
		result.append(event)
	return result


static func _stable_slots_key(slots: Dictionary) -> String:
	var parts: Array[String] = []
	for slot: String in FormationReducer.SLOT_ORDER:
		parts.append("%s=%s" % [slot, str(slots.get(slot, ""))])
	return "|".join(parts)

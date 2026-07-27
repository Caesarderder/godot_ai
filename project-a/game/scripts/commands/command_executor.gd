class_name CommandExecutor
extends RefCounted

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGenerator := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const HeroProgression := preload("res://game/scripts/domain/progression/hero_progression.gd")
const FormationService := preload("res://game/scripts/domain/formation/formation_service.gd")
const FormationStateScript := preload("res://game/scripts/state/formation_state.gd")
const FactoryService := preload("res://game/scripts/domain/factory/factory_service.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const WalletServiceScript := preload("res://game/scripts/domain/economy/wallet_service.gd")
const SalvageCatalogScript := preload("res://game/scripts/domain/economy/salvage_catalog.gd")
const GoldShopCatalogScript := preload("res://game/scripts/domain/economy/gold_shop_catalog.gd")
const GoldShopServiceScript := preload("res://game/scripts/domain/economy/gold_shop_service.gd")
const BlueprintDrawServiceScript := preload("res://game/scripts/domain/economy/blueprint_draw_service.gd")
const QuestCatalogScript := preload("res://game/scripts/domain/quest/quest_catalog.gd")
const QuestServiceScript := preload("res://game/scripts/domain/quest/quest_service.gd")
const WarMeritTrackScript := preload("res://game/scripts/domain/quest/war_merit_track.gd")
const AchievementServiceScript := preload("res://game/scripts/domain/achievement/achievement_service.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")
const CommandClassRegistryScript := preload("res://game/scripts/commands/command_class_registry.gd")
const CommandFingerprintScript := preload("res://game/scripts/commands/command_fingerprint.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")
const OnboardingServiceScript := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")
const MetaProgressionServiceScript := preload("res://game/scripts/domain/meta/meta_progression_service.gd")
const SignalRecruitServiceScript := preload("res://game/scripts/domain/recruitment/signal_recruit_service.gd")
const ResearchBreakthroughServiceScript := preload("res://game/scripts/domain/recruitment/research_breakthrough_service.gd")
const NewPlayerWelfareServiceScript := preload("res://game/scripts/domain/meta/new_player_welfare_service.gd")

var state: RefCounted = GameStateScript.create_new()
var save_callback: Callable = Callable()


func _init(initial_state: RefCounted = null, injected_save_callback: Callable = Callable()) -> void:
	if initial_state != null:
		state = initial_state
	save_callback = injected_save_callback


func execute(envelope: Dictionary) -> Dictionary:
	var command_type := String(envelope.get("type", ""))
	var command_id := String(envelope.get("command_id", ""))
	var business_key := String(envelope.get("business_key", ""))
	var payload: Variant = envelope.get("payload", {})
	if command_id.is_empty():
		return _error("COMMAND_ID_REQUIRED")
	if envelope.has("class"):
		return _error("COMMAND_CLASS_OVERRIDE_REJECTED")
	if not CommandClassRegistryScript.has_command(command_type):
		return _error("UNKNOWN_COMMAND")
	var payload_error := _validate_payload(command_type, payload)
	if not payload_error.is_empty():
		return _error(payload_error)
	var fp_result := CommandFingerprintScript.build(command_type, payload, business_key)
	if not bool(fp_result["ok"]):
		return _error(String(fp_result["error"]))
	var fingerprint := String(fp_result["fingerprint"])
	if state.command_receipts.has(command_id):
		var old_command_receipt := state.command_receipts[command_id] as Dictionary
		if String(old_command_receipt["fingerprint"]) != fingerprint:
			return _error("COMMAND_ID_REUSE_MISMATCH")
		return (old_command_receipt["result"] as Dictionary).duplicate(true)
	if not business_key.is_empty() and state.business_receipts.has(business_key):
		var old_business_receipt := state.business_receipts[business_key] as Dictionary
		if String(old_business_receipt["fingerprint"]) != fingerprint:
			return _error("BUSINESS_KEY_REUSE_MISMATCH")
		return (old_business_receipt["result"] as Dictionary).duplicate(true)
	if not envelope.has("expected_revision") or typeof(envelope["expected_revision"]) != TYPE_INT:
		return _error("EXPECTED_REVISION_REQUIRED")
	if int(envelope["expected_revision"]) != int(state.revision):
		return _error("STALE_REVISION")
	if not save_callback.is_valid():
		return _error("SAVE_UNAVAILABLE")

	var candidate: RefCounted = state.deep_clone()
	var event: Dictionary = _apply_reducer(candidate, command_type, payload)
	if not bool(event.get("ok", false)):
		return _error(String(event.get("error", "COMMAND_FAILED")))
	if not ["refresh_quests", "claim_quest"].has(command_type):
		QuestServiceScript.apply_event(candidate, event.get("event", {}) as Dictionary)
	if command_type != "claim_onboarding_task":
		var onboarding_settlement := OnboardingServiceScript.apply_event(
			candidate,
			event.get("event", {}) as Dictionary
		)
		if not onboarding_settlement.is_empty():
			(event.get("event", {}) as Dictionary)["onboarding_settlement"] = onboarding_settlement
	if not ["refresh_achievements", "claim_achievement"].has(command_type):
		AchievementServiceScript.apply_event(
			candidate,
			event.get("event", {}) as Dictionary,
			"%s:%s" % [command_type, command_id]
		)
	if not ["refresh_meta_progression", "claim_meta_mission", "claim_meta_pass_level", "claim_all_meta_pass_levels", "claim_commander_level_reward", "claim_all_commander_level_rewards", "claim_meta_achievement", "claim_all_meta_achievements"].has(command_type):
		MetaProgressionServiceScript.apply_gameplay_event(
			candidate,
			event.get("event", {}) as Dictionary,
			"%s:%s" % [command_type, command_id]
		)
	var invariant_errors: Array[String] = candidate.validate()
	if not invariant_errors.is_empty():
		return _error("INVARIANT_FAILED: %s" % "; ".join(invariant_errors))
	candidate.revision += 1
	var result := {
		"ok": true,
		"command_id": command_id,
		"type": command_type,
		"state_revision": candidate.revision,
		"event": event.get("event", {}),
	}
	var receipt := {
		"command_id": command_id,
		"business_key": business_key,
		"type": command_type,
		"class": CommandClassRegistryScript.command_class(command_type),
		"fingerprint": fingerprint,
		"canonical_payload": String(fp_result["canonical_payload"]),
		"result": result.duplicate(true),
	}
	candidate.command_receipts[command_id] = receipt
	if not business_key.is_empty():
		candidate.business_receipts[business_key] = receipt
	if not _save_candidate(candidate):
		return _error("SAVE_FAILED")
	state = candidate
	return result


func _apply_reducer(candidate: RefCounted, command_type: String, payload: Variant) -> Dictionary:
	var data := payload as Dictionary
	match command_type:
		"grant_resources":
			var resources := data.get("resources", {}) as Dictionary
			candidate.economy.grant(resources)
			if resources.has("porcelain"):
				candidate.factory.grant({"porcelain": int(resources["porcelain"])})
			return {"ok": true, "event": {"type": "resources_granted"}}
		"settle_battle":
			var battle_id := String(data.get("battle_id", ""))
			var outcome := String(data.get("outcome", ""))
			var ticks := int(data.get("ticks", 0))
			var stage_id := String(data.get("stage_id", StageCatalogScript.DEFAULT_STAGE_ID))
			var prior_attempts := int(candidate.attempt_counters.get(stage_id, 0))
			var cleared_before: Array = candidate.stage_progress.get("cleared_stages", [])
			var already_cleared := cleared_before.has(stage_id)
			var deployed_values := data.get("deployed_unit_ids", candidate.formation.hero_ids()) as Array
			var disabled_values := data.get("dead_unit_ids", []) as Array
			var damage_manifest := LogisticsServiceScript.apply_battle_damage(candidate, deployed_values, disabled_values, outcome)
			var reward := StageCatalogScript.reward_for_context(stage_id, outcome, prior_attempts, already_cleared)
			var reward_tier := StageCatalogScript.reward_tier(outcome, prior_attempts, already_cleared)
			var unlocked_blueprints: Array[Dictionary] = []
			if reward.is_empty():
				return {"ok": false, "error": "STAGE_NOT_FOUND"}
			if outcome == "victory":
				reward = _randomize_victory_reward(candidate.run_seed, battle_id, stage_id, reward)
			else:
				reward = {"gold": 0}
			var was_first_victory := false
			if outcome == "victory":
				var cleared: Array = candidate.stage_progress.get("cleared_stages", [])
				was_first_victory = not cleared.has(stage_id)
				if not cleared.has(stage_id):
					cleared.append(stage_id)
				candidate.stage_progress["cleared_stages"] = cleared
				var next_stage := StageCatalogScript.next_stage_id(stage_id)
				if not next_stage.is_empty():
					candidate.stage_progress["highest_unlocked_stage"] = _max_stage_id(String(candidate.stage_progress.get("highest_unlocked_stage", StageCatalogScript.DEFAULT_STAGE_ID)), next_stage)
			if outcome == "victory":
				candidate.economy.grant({"toilet_coins": int(reward.get("gold", 0))})
				var breakthrough := StageCatalogScript.breakthrough_reward(stage_id, already_cleared)
				candidate.economy.grant(breakthrough)
				var campaign_blueprint := _unlock_campaign_blueprint(candidate, stage_id, already_cleared)
				if not campaign_blueprint.is_empty():
					unlocked_blueprints.append(campaign_blueprint)
			for deployed_value in deployed_values:
				var deployed_hero: RefCounted = candidate.hero_by_id(String(deployed_value))
				if deployed_hero != null:
					deployed_hero.xp = mini(320, int(deployed_hero.xp) + (30 if outcome == "victory" else 8))
			var alliance_scrap_granted := 0
			var alliance_scrap_receipt: Dictionary = {}
			candidate.attempt_counters[stage_id] = int(candidate.attempt_counters.get(stage_id, 0)) + 1
			var eligible_facilities := FactoryService.apply_battle_unlocks(candidate, outcome, int(candidate.attempt_counters[stage_id]), stage_id)
			return {
				"ok": true,
				"event": {
					"type": "battle_settled",
					"battle_id": battle_id,
					"stage_id": stage_id,
					"outcome": outcome,
					"ticks": ticks,
					"reward": reward,
					"reward_tier": reward_tier,
					"unlocked_blueprints": unlocked_blueprints,
					"eligible_facilities": eligible_facilities,
					"next_stage_id": StageCatalogScript.next_stage_id(stage_id) if outcome == "victory" else "",
					"alliance_scrap_granted": alliance_scrap_granted,
					"alliance_scrap_receipt": alliance_scrap_receipt,
					"dead_unit_ids": [],
					"surviving_unit_ids": candidate.formation.hero_ids(),
					"damage_manifest": damage_manifest,
					"hero_shards": int(StageCatalogScript.breakthrough_reward(stage_id, already_cleared).get("hero_shards", 0)) if outcome == "victory" else 0,
					"unlocked_hero": {},
					"campaign_completed": outcome == "victory" and stage_id == "stage_5_5",
					"first_campaign_completion": outcome == "victory" and stage_id == "stage_5_5" and was_first_victory,
				},
			}
		"claim_factory_output":
			return LogisticsServiceScript.claim_output(candidate, int(data["now_unix"]))
		"claim_facility_output":
			return LogisticsServiceScript.claim_facility_output(candidate, String(data["facility_id"]), int(data["now_unix"]))
		"upgrade_permanent_hero":
			return LogisticsServiceScript.upgrade_hero(candidate, String(data["hero_id"]))
		"upgrade_hero_star":
			return LogisticsServiceScript.upgrade_star(candidate, String(data["hero_id"]))
		"research_active_skill":
			return LogisticsServiceScript.research_active_skill(candidate, String(data["hero_id"]))
		"assign_factory_specialist":
			return LogisticsServiceScript.assign_specialist(candidate, String(data["hero_id"]), String(data["facility_id"]))
		"upgrade_facility":
			return LogisticsServiceScript.upgrade_facility(candidate, String(data["facility_id"]), int(data["now_unix"]))
		"construct_facility":
			return LogisticsServiceScript.construct_facility(
				candidate,
				String(data["facility_id"]),
				int(data["now_unix"]),
				int(data["grid_x"]),
				int(data["grid_z"])
			)
		"claim_facility_work":
			return LogisticsServiceScript.claim_facility_work(candidate, int(data["now_unix"]))
		"claim_onboarding_task":
			return OnboardingServiceScript.claim_current(candidate, String(data["task_id"]))
		"claim_new_player_welfare":
			return NewPlayerWelfareServiceScript.claim(candidate)
		"open_smuggled_logistics_case":
			return NewPlayerWelfareServiceScript.open_logistics_case(candidate)
		"use_welfare_star_core":
			return NewPlayerWelfareServiceScript.use_star_core(candidate, String(data["hero_id"]))
		"exchange_salvage":
			return WalletServiceScript.exchange_salvage(candidate, String(data["request_id"]), String(data["offer_id"]))
		"purchase_gold_shop":
			return GoldShopServiceScript.purchase(candidate, String(data["request_id"]), String(data["offer_id"]))
		"claim_war_merit_reward":
			return WarMeritTrackScript.claim_reward(candidate, String(data["request_id"]), int(data["level"]))
		"refresh_quests":
			return QuestServiceScript.refresh_quests(candidate)
		"claim_quest":
			return QuestServiceScript.claim_quest(candidate, String(data["quest_id"]), int(data["generation"]), String(data["request_id"]))
		"refresh_achievements":
			return AchievementServiceScript.refresh_achievements(candidate)
		"claim_achievement":
			return AchievementServiceScript.claim_achievement(candidate, String(data["achievement_id"]), int(data["generation"]), String(data["request_id"]))
		"refresh_meta_progression":
			return MetaProgressionServiceScript.refresh(candidate, int(data["now_unix"]))
		"claim_meta_mission":
			return MetaProgressionServiceScript.claim_mission(candidate, String(data["mission_id"]), int(data["generation"]))
		"claim_meta_pass_level":
			return MetaProgressionServiceScript.claim_pass_level(candidate, int(data["level"]))
		"claim_all_meta_pass_levels":
			return MetaProgressionServiceScript.claim_all_pass_levels(candidate)
		"claim_commander_level_reward":
			return MetaProgressionServiceScript.claim_commander_level(candidate, int(data["level"]))
		"claim_all_commander_level_rewards":
			return MetaProgressionServiceScript.claim_all_commander_levels(candidate)
		"claim_meta_achievement":
			return MetaProgressionServiceScript.claim_achievement(candidate, String(data["achievement_id"]))
		"claim_all_meta_achievements":
			return MetaProgressionServiceScript.claim_all_achievements(candidate)
		"signal_recruit":
			return SignalRecruitServiceScript.recruit(candidate, int(data["count"]), String(data["target_archetype"]))
		"claim_foundational_signal":
			return ResearchBreakthroughServiceScript.claim(candidate)
		"start_production":
			return FactoryService.start_production(candidate, String(data["recipe_id"]), int(data["now_unix"]))
		"unlock_foundational_blueprint":
			return FactoryService.unlock_foundational_blueprint(candidate, String(data["recipe_id"]), int(data["now_unix"]))
		"start_blueprint_research":
			return FactoryService.start_blueprint_research(candidate, String(data["recipe_id"]), int(data["now_unix"]))
		"claim_blueprint_research":
			return FactoryService.claim_foundational_blueprint(candidate, int(data["now_unix"]))
		"claim_production":
			return FactoryService.claim_production(candidate, String(data["order_id"]), int(data["now_unix"]))
		"claim_ready_productions":
			return FactoryService.claim_ready_productions(candidate, int(data["now_unix"]))
		"draw_blueprints":
			return BlueprintDrawServiceScript.draw(candidate, int(data["count"]), String(data["target_s_recipe_id"]), String(data["pool_id"]))
		"upgrade_model_tech":
			return FactoryService.upgrade_model_tech(candidate, String(data["recipe_id"]))
		"claim_scrap_recovery":
			if not candidate.roster.is_empty():
				return {"ok": false, "error": "RECOVERY_REQUIRES_EMPTY_UNIT_INVENTORY"}
			const RECOVERY_FLOOR: int = 10
			var current_material := int(candidate.factory.materials.get("porcelain", 0))
			if current_material >= RECOVERY_FLOOR:
				return {"ok": false, "error": "RECOVERY_NOT_NEEDED"}
			var recovery := {"porcelain": RECOVERY_FLOOR - current_material}
			candidate.factory.grant(recovery)
			return {"ok": true, "event": {"type": "scrap_recovery_claimed", "materials": recovery}}
		"merge_heroes":
			var hero_ids: Array[String] = []
			for hero_id in data["hero_ids"]:
				hero_ids.append(String(hero_id))
			return FactoryService.merge_heroes(candidate, hero_ids)
		"recruit_hero":
			if candidate.economy.recruit_tickets < 1:
				return {"ok": false, "error": "NOT_ENOUGH_RECRUIT_TICKETS"}
			candidate.economy.recruit_tickets -= 1
			var hero: RefCounted = HeroGenerator.generate_hero(candidate.run_seed, candidate.allocate_hero_index())
			candidate.roster.append(hero)
			return {"ok": true, "event": {"type": "hero_recruited", "hero_id": hero.hero_id}}
		"train_hero":
			var hero_id := String(data.get("hero_id", ""))
			var book_count := int(data.get("book_count", 0))
			if book_count <= 0:
				return {"ok": false, "error": "BOOK_COUNT_REQUIRED"}
			var hero: RefCounted = candidate.hero_by_id(hero_id)
			if hero == null:
				return {"ok": false, "error": "HERO_NOT_FOUND"}
			if book_count > HeroProgression.max_trainable_books(hero):
				return {"ok": false, "error": "TRAINING_EXCEEDS_MAX_XP"}
			var gold_cost := HeroProgression.training_gold_cost(hero, book_count)
			if candidate.economy.xp_books < book_count:
				return {"ok": false, "error": "NOT_ENOUGH_XP_BOOKS"}
			if candidate.economy.gold < gold_cost:
				return {"ok": false, "error": "NOT_ENOUGH_GOLD"}
			candidate.economy.xp_books -= book_count
			candidate.economy.gold -= gold_cost
			HeroProgression.train_with_books(hero, book_count)
			return {
				"ok": true,
				"event": {
					"type": "hero_trained",
					"hero_id": hero_id,
					"book_count": book_count,
					"gold_cost": gold_cost,
					"level": hero.level,
					"xp": hero.xp,
				},
			}
		"set_formation":
			var formation := FormationService.build_from_payload(data)
			var errors: Array[String] = formation.validate(candidate.roster_ids())
			if not errors.is_empty():
				return {"ok": false, "error": "INVALID_FORMATION: %s" % "; ".join(errors)}
			candidate.formation = formation
			return {"ok": true, "event": {"type": "formation_changed"}}
		"assign_formation_slot":
			return FormationService.assign_slot(candidate, String(data["slot"]), String(data["hero_id"]))
		"refill_formation":
			var assigned: Array[String] = []
			var deployed: Array[String] = candidate.formation.hero_ids()
			for hero in candidate.roster:
				var hero_id := String(hero.hero_id)
				if deployed.has(hero_id):
					continue
				if String(candidate.formation.slots.get("commander", "")).is_empty():
					candidate.formation.slots["commander"] = hero_id
					deployed.append(hero_id)
					assigned.append(hero_id)
				elif candidate.formation.assign_next_troop(hero_id):
					deployed.append(hero_id)
					assigned.append(hero_id)
			return {"ok": true, "event": {"type": "formation_refilled", "assigned_unit_ids": assigned}}
		"set_auto_skill_preference":
			var hero_id := String(data["hero_id"])
			var hero: RefCounted = candidate.hero_by_id(hero_id)
			if hero == null:
				return {"ok": false, "error": "HERO_NOT_FOUND"}
			hero.auto_skill_enabled = bool(data["enabled"])
			candidate.auto_skill_preferences[hero_id] = hero.auto_skill_enabled
			return {"ok": true, "event": {"type": "auto_skill_preference_changed", "hero_id": hero_id, "enabled": hero.auto_skill_enabled}}
		_:
			return {"ok": false, "error": "UNKNOWN_COMMAND"}


func _save_candidate(candidate: RefCounted) -> bool:
	if save_callback.is_valid():
		return bool(save_callback.call(candidate))
	return false


func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}


func _validate_payload(command_type: String, payload: Variant) -> String:
	if typeof(payload) != TYPE_DICTIONARY:
		return "PAYLOAD_MUST_BE_DICTIONARY"
	var data := payload as Dictionary
	match command_type:
		"grant_resources":
			var error := _exact_keys(data, ["resources"], "grant_resources")
			if not error.is_empty():
				return error
			if typeof(data["resources"]) != TYPE_DICTIONARY:
				return "grant_resources.resources must be dictionary"
			var resources := data["resources"] as Dictionary
			for key in resources.keys():
				if typeof(key) != TYPE_STRING:
					return "grant_resources resource keys must be strings"
				if not ["toilet_coins", "hero_shards", "porcelain", "recruit_tickets"].has(String(key)):
					return "UNKNOWN_RESOURCE_KEY"
				if typeof(resources[key]) != TYPE_INT:
					return "RESOURCE_AMOUNT_MUST_BE_INT"
				if int(resources[key]) < 0:
					return "RESOURCE_AMOUNT_MUST_NOT_BE_NEGATIVE"
			return ""
		"claim_factory_output":
			var factory_claim_error := _exact_keys(data, ["now_unix"], "claim_factory_output")
			if not factory_claim_error.is_empty():
				return factory_claim_error
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_factory_output.now_unix must be non-negative int"
			return ""
		"claim_facility_output":
			var facility_claim_error := _exact_keys(data, ["facility_id", "now_unix"], "claim_facility_output")
			if not facility_claim_error.is_empty():
				return facility_claim_error
			if typeof(data["facility_id"]) != TYPE_STRING or String(data["facility_id"]).is_empty():
				return "claim_facility_output.facility_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_facility_output.now_unix must be non-negative int"
			return ""
		"upgrade_permanent_hero":
			var hero_upgrade_error := _exact_keys(data, ["hero_id"], "upgrade_permanent_hero")
			if not hero_upgrade_error.is_empty():
				return hero_upgrade_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "upgrade_permanent_hero.hero_id must be non-empty string"
			return ""
		"upgrade_hero_star":
			var star_error := _exact_keys(data, ["hero_id"], "upgrade_hero_star")
			if not star_error.is_empty():
				return star_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "upgrade_hero_star.hero_id must be non-empty string"
			return ""
		"research_active_skill":
			var research_skill_error := _exact_keys(data, ["hero_id"], "research_active_skill")
			if not research_skill_error.is_empty():
				return research_skill_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "research_active_skill.hero_id must be non-empty string"
			return ""
		"assign_factory_specialist":
			var assign_error := _exact_keys(data, ["hero_id", "facility_id"], "assign_factory_specialist")
			if not assign_error.is_empty():
				return assign_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "assign_factory_specialist.hero_id must be non-empty string"
			if typeof(data["facility_id"]) != TYPE_STRING or String(data["facility_id"]).is_empty():
				return "assign_factory_specialist.facility_id must be non-empty string"
			return ""
		"repair_hero":
			var repair_error := _exact_keys(data, ["hero_id", "repair_mode"], "repair_hero")
			if not repair_error.is_empty():
				return repair_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "repair_hero.hero_id must be non-empty string"
			if typeof(data["repair_mode"]) != TYPE_STRING or String(data["repair_mode"]) not in ["quick", "full"]:
				return "repair_hero.repair_mode invalid"
			return ""
		"start_timed_repair":
			var timed_error := _exact_keys(data, ["hero_id", "now_unix"], "start_timed_repair")
			if not timed_error.is_empty():
				return timed_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "start_timed_repair.hero_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "start_timed_repair.now_unix must be non-negative int"
			return ""
		"claim_timed_repairs":
			var timed_claim_error := _exact_keys(data, ["now_unix"], "claim_timed_repairs")
			if not timed_claim_error.is_empty():
				return timed_claim_error
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_timed_repairs.now_unix must be non-negative int"
			return ""
		"upgrade_facility":
			var facility_error := _exact_keys(data, ["facility_id", "now_unix"], "upgrade_facility")
			if not facility_error.is_empty():
				return facility_error
			if typeof(data["facility_id"]) != TYPE_STRING or String(data["facility_id"]).is_empty():
				return "upgrade_facility.facility_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "upgrade_facility.now_unix must be non-negative int"
			return ""
		"construct_facility":
			var construction_error := _exact_keys(data, ["facility_id", "now_unix", "grid_x", "grid_z"], "construct_facility")
			if not construction_error.is_empty():
				return construction_error
			if typeof(data["facility_id"]) != TYPE_STRING or String(data["facility_id"]).is_empty():
				return "construct_facility.facility_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "construct_facility.now_unix must be non-negative int"
			if typeof(data["grid_x"]) != TYPE_INT or typeof(data["grid_z"]) != TYPE_INT:
				return "construct_facility grid coordinates must be ints"
			return ""
		"claim_facility_work":
			var facility_work_error := _exact_keys(data, ["now_unix"], "claim_facility_work")
			if not facility_work_error.is_empty():
				return facility_work_error
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_facility_work.now_unix must be non-negative int"
			return ""
		"claim_onboarding_task":
			var onboarding_error := _exact_keys(data, ["task_id"], "claim_onboarding_task")
			if not onboarding_error.is_empty():
				return onboarding_error
			if typeof(data["task_id"]) != TYPE_STRING or String(data["task_id"]).is_empty():
				return "claim_onboarding_task.task_id must be non-empty string"
			return ""
		"claim_new_player_welfare":
			return _exact_keys(data, [], "claim_new_player_welfare")
		"open_smuggled_logistics_case":
			return _exact_keys(data, [], "open_smuggled_logistics_case")
		"use_welfare_star_core":
			var welfare_core_error := _exact_keys(data, ["hero_id"], "use_welfare_star_core")
			if not welfare_core_error.is_empty():
				return welfare_core_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "use_welfare_star_core.hero_id must be non-empty string"
			return ""
		"recruit_hero":
			return _exact_keys(data, [], "recruit_hero")
		"settle_battle":
			var expected_keys: Array[String] = ["battle_id", "outcome", "ticks"]
			if data.has("stage_id"):
				expected_keys.append("stage_id")
			if data.has("deployed_unit_ids"):
				expected_keys.append("deployed_unit_ids")
			if data.has("dead_unit_ids"):
				expected_keys.append("dead_unit_ids")
			var battle_error := _exact_keys(data, expected_keys, "settle_battle")
			if not battle_error.is_empty():
				return battle_error
			if typeof(data["battle_id"]) != TYPE_STRING or String(data["battle_id"]).is_empty():
				return "settle_battle.battle_id must be non-empty string"
			if data.has("stage_id") and (typeof(data["stage_id"]) != TYPE_STRING or not StageCatalogScript.has_stage(String(data["stage_id"]))):
				return "settle_battle.stage_id must be a known stage"
			if typeof(data["outcome"]) != TYPE_STRING or not ["victory", "defeat", "timeout", "retreat", "wipe"].has(String(data["outcome"])):
				return "settle_battle.outcome invalid"
			if typeof(data["ticks"]) != TYPE_INT or int(data["ticks"]) <= 0:
				return "settle_battle.ticks must be a positive int"
			for list_key in ["deployed_unit_ids", "dead_unit_ids"]:
				if data.has(list_key):
					if typeof(data[list_key]) != TYPE_ARRAY:
						return "settle_battle.%s must be array" % list_key
					for unit_id in data[list_key]:
						if typeof(unit_id) != TYPE_STRING or String(unit_id).is_empty():
							return "settle_battle.%s entries must be non-empty strings" % list_key
			return ""
		"exchange_salvage":
			var exchange_error := _exact_keys(data, ["request_id", "offer_id"], "exchange_salvage")
			if not exchange_error.is_empty():
				return exchange_error
			if typeof(data["request_id"]) != TYPE_STRING or String(data["request_id"]).is_empty():
				return "exchange_salvage.request_id must be non-empty string"
			if typeof(data["offer_id"]) != TYPE_STRING or String(data["offer_id"]).is_empty():
				return "exchange_salvage.offer_id must be non-empty string"
			if not SalvageCatalogScript.has_offer(String(data["offer_id"])):
				return "UNKNOWN_SALVAGE_OFFER"
			return ""
		"purchase_gold_shop":
			var shop_error := _exact_keys(data, ["request_id", "offer_id"], "purchase_gold_shop")
			if not shop_error.is_empty():
				return shop_error
			if typeof(data["request_id"]) != TYPE_STRING or String(data["request_id"]).is_empty():
				return "purchase_gold_shop.request_id must be non-empty string"
			if typeof(data["offer_id"]) != TYPE_STRING or not GoldShopCatalogScript.has_offer(String(data["offer_id"])):
				return "purchase_gold_shop.offer_id must be known string"
			return ""
		"claim_war_merit_reward":
			var merit_error := _exact_keys(data, ["request_id", "level"], "claim_war_merit_reward")
			if not merit_error.is_empty():
				return merit_error
			if typeof(data["request_id"]) != TYPE_STRING or String(data["request_id"]).is_empty():
				return "claim_war_merit_reward.request_id must be non-empty string"
			if typeof(data["level"]) != TYPE_INT or int(data["level"]) < 1 or int(data["level"]) > QuestCatalogScript.MAX_RANK:
				return "claim_war_merit_reward.level must be 1..30"
			return ""
		"refresh_quests":
			return _exact_keys(data, [], "refresh_quests")
		"claim_quest":
			var claim_quest_error := _exact_keys(data, ["quest_id", "generation", "request_id"], "claim_quest")
			if not claim_quest_error.is_empty():
				return claim_quest_error
			if typeof(data["quest_id"]) != TYPE_STRING or String(data["quest_id"]).is_empty():
				return "claim_quest.quest_id must be non-empty string"
			if typeof(data["generation"]) != TYPE_INT or int(data["generation"]) < 0:
				return "claim_quest.generation must be non-negative int"
			if typeof(data["request_id"]) != TYPE_STRING or String(data["request_id"]).is_empty():
				return "claim_quest.request_id must be non-empty string"
			return ""
		"refresh_achievements":
			return _exact_keys(data, [], "refresh_achievements")
		"claim_achievement":
			var claim_achievement_error := _exact_keys(data, ["achievement_id", "generation", "request_id"], "claim_achievement")
			if not claim_achievement_error.is_empty():
				return claim_achievement_error
			if typeof(data["achievement_id"]) != TYPE_STRING or String(data["achievement_id"]).is_empty():
				return "claim_achievement.achievement_id must be non-empty string"
			if typeof(data["generation"]) != TYPE_INT or int(data["generation"]) != 0:
				return "claim_achievement.generation must be zero"
			if typeof(data["request_id"]) != TYPE_STRING or String(data["request_id"]).is_empty():
				return "claim_achievement.request_id must be non-empty string"
			return ""
		"refresh_meta_progression":
			var refresh_meta_error := _exact_keys(data, ["now_unix"], "refresh_meta_progression")
			if not refresh_meta_error.is_empty():
				return refresh_meta_error
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "refresh_meta_progression.now_unix must be non-negative int"
			return ""
		"claim_meta_mission":
			var meta_mission_error := _exact_keys(data, ["mission_id", "generation"], "claim_meta_mission")
			if not meta_mission_error.is_empty():
				return meta_mission_error
			if typeof(data["mission_id"]) != TYPE_STRING or String(data["mission_id"]).is_empty():
				return "claim_meta_mission.mission_id must be non-empty string"
			if typeof(data["generation"]) != TYPE_INT or int(data["generation"]) < 0:
				return "claim_meta_mission.generation must be non-negative int"
			return ""
		"claim_meta_pass_level":
			var meta_pass_error := _exact_keys(data, ["level"], "claim_meta_pass_level")
			if not meta_pass_error.is_empty():
				return meta_pass_error
			if typeof(data["level"]) != TYPE_INT or int(data["level"]) < 1 or int(data["level"]) > 30:
				return "claim_meta_pass_level.level must be 1..30"
			return ""
		"claim_all_meta_pass_levels":
			return _exact_keys(data, [], "claim_all_meta_pass_levels")
		"claim_commander_level_reward":
			var commander_level_error := _exact_keys(data, ["level"], "claim_commander_level_reward")
			if not commander_level_error.is_empty():
				return commander_level_error
			if typeof(data["level"]) != TYPE_INT or int(data["level"]) < 2 or int(data["level"]) > 30:
				return "claim_commander_level_reward.level must be 2..30"
			return ""
		"claim_all_commander_level_rewards":
			return _exact_keys(data, [], "claim_all_commander_level_rewards")
		"claim_meta_achievement":
			var meta_achievement_error := _exact_keys(data, ["achievement_id"], "claim_meta_achievement")
			if not meta_achievement_error.is_empty():
				return meta_achievement_error
			if typeof(data["achievement_id"]) != TYPE_STRING or String(data["achievement_id"]).is_empty():
				return "claim_meta_achievement.achievement_id must be non-empty string"
			return ""
		"claim_all_meta_achievements":
			return _exact_keys(data, [], "claim_all_meta_achievements")
		"signal_recruit":
			var signal_recruit_error := _exact_keys(data, ["count", "target_archetype"], "signal_recruit")
			if not signal_recruit_error.is_empty():
				return signal_recruit_error
			if typeof(data["count"]) != TYPE_INT or int(data["count"]) not in [1, 10]:
				return "signal_recruit.count must be 1 or 10"
			if typeof(data["target_archetype"]) != TYPE_STRING or String(data["target_archetype"]).is_empty():
				return "signal_recruit.target_archetype must be non-empty string"
			return ""
		"claim_foundational_signal":
			return _exact_keys(data, [], "claim_foundational_signal")
		"start_production":
			var start_error := _exact_keys(data, ["recipe_id", "now_unix"], "start_production")
			if not start_error.is_empty():
				return start_error
			if typeof(data["recipe_id"]) != TYPE_STRING or String(data["recipe_id"]).is_empty():
				return "start_production.recipe_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "start_production.now_unix must be non-negative int"
			return ""
		"unlock_foundational_blueprint":
			var foundational_error := _exact_keys(data, ["recipe_id", "now_unix"], "unlock_foundational_blueprint")
			if not foundational_error.is_empty():
				return foundational_error
			if typeof(data["recipe_id"]) != TYPE_STRING or String(data["recipe_id"]).is_empty():
				return "unlock_foundational_blueprint.recipe_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "unlock_foundational_blueprint.now_unix must be non-negative int"
			return ""
		"start_blueprint_research":
			var research_error := _exact_keys(data, ["recipe_id", "now_unix"], "start_blueprint_research")
			if not research_error.is_empty():
				return research_error
			if typeof(data["recipe_id"]) != TYPE_STRING or String(data["recipe_id"]).is_empty():
				return "start_blueprint_research.recipe_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "start_blueprint_research.now_unix must be non-negative int"
			return ""
		"claim_blueprint_research":
			var research_claim_error := _exact_keys(data, ["now_unix"], "claim_blueprint_research")
			if not research_claim_error.is_empty():
				return research_claim_error
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_blueprint_research.now_unix must be non-negative int"
			return ""
		"claim_production":
			var claim_error := _exact_keys(data, ["order_id", "now_unix"], "claim_production")
			if not claim_error.is_empty():
				return claim_error
			if typeof(data["order_id"]) != TYPE_STRING or String(data["order_id"]).is_empty():
				return "claim_production.order_id must be non-empty string"
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_production.now_unix must be non-negative int"
			return ""
		"claim_ready_productions":
			var claim_ready_error := _exact_keys(data, ["now_unix"], "claim_ready_productions")
			if not claim_ready_error.is_empty():
				return claim_ready_error
			if typeof(data["now_unix"]) != TYPE_INT or int(data["now_unix"]) < 0:
				return "claim_ready_productions.now_unix must be non-negative int"
			return ""
		"draw_blueprints":
			var draw_error := _exact_keys(data, ["count", "target_s_recipe_id", "pool_id"], "draw_blueprints")
			if not draw_error.is_empty():
				return draw_error
			if typeof(data["count"]) != TYPE_INT or not [1, 10].has(int(data["count"])):
				return "draw_blueprints.count must be 1 or 10"
			for key in ["target_s_recipe_id", "pool_id"]:
				if typeof(data[key]) != TYPE_STRING or String(data[key]).is_empty():
					return "draw_blueprints.%s must be non-empty string" % key
			return ""
		"upgrade_model_tech":
			var tech_error := _exact_keys(data, ["recipe_id"], "upgrade_model_tech")
			if not tech_error.is_empty():
				return tech_error
			if typeof(data["recipe_id"]) != TYPE_STRING or String(data["recipe_id"]).is_empty():
				return "upgrade_model_tech.recipe_id must be non-empty string"
			return ""
		"claim_scrap_recovery":
			return _exact_keys(data, [], "claim_scrap_recovery")
		"merge_heroes":
			var merge_error := _exact_keys(data, ["hero_ids"], "merge_heroes")
			if not merge_error.is_empty():
				return merge_error
			if typeof(data["hero_ids"]) != TYPE_ARRAY or (data["hero_ids"] as Array).size() != 3:
				return "merge_heroes.hero_ids must contain exactly three entries"
			for hero_id in data["hero_ids"]:
				if typeof(hero_id) != TYPE_STRING or String(hero_id).is_empty():
					return "merge_heroes.hero_ids entries must be non-empty strings"
			return ""
		"train_hero":
			var train_error := _exact_keys(data, ["hero_id", "book_count"], "train_hero")
			if not train_error.is_empty():
				return train_error
			if typeof(data["hero_id"]) != TYPE_STRING:
				return "train_hero.hero_id must be string"
			if typeof(data["book_count"]) != TYPE_INT:
				return "train_hero.book_count must be int"
			if int(data["book_count"]) <= 0:
				return "train_hero.book_count must be positive"
			return ""
		"set_formation":
			var slots: Array[String] = ["commander", "troop_1", "troop_2", "troop_3", "troop_4", "troop_5", "troop_6"]
			var formation_error := _exact_keys(data, slots, "set_formation")
			if not formation_error.is_empty():
				return formation_error
			for slot in slots:
				if typeof(data[slot]) != TYPE_STRING:
					return "set_formation.%s must be string" % slot
			return ""
		"assign_formation_slot":
			var assign_slot_error := _exact_keys(data, ["slot", "hero_id"], "assign_formation_slot")
			if not assign_slot_error.is_empty():
				return assign_slot_error
			if typeof(data["slot"]) != TYPE_STRING or not FormationStateScript.ACTIVE_SLOTS.has(String(data["slot"])):
				return "assign_formation_slot.slot invalid"
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "assign_formation_slot.hero_id must be non-empty string"
			return ""
		"refill_formation":
			return _exact_keys(data, [], "refill_formation")
		"set_auto_skill_preference":
			var auto_error := _exact_keys(data, ["hero_id", "enabled"], "set_auto_skill_preference")
			if not auto_error.is_empty():
				return auto_error
			if typeof(data["hero_id"]) != TYPE_STRING or String(data["hero_id"]).is_empty():
				return "set_auto_skill_preference.hero_id must be non-empty string"
			if typeof(data["enabled"]) != TYPE_BOOL:
				return "set_auto_skill_preference.enabled must be bool"
			return ""
		_:
			return "UNKNOWN_COMMAND"


func _exact_keys(data: Dictionary, expected: Array[String], label: String) -> String:
	var actual: Array[String] = []
	for key in data.keys():
		if typeof(key) != TYPE_STRING:
			return "%s keys must be strings" % label
		actual.append(String(key))
	actual.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	if actual != sorted_expected:
		return "%s payload keys mismatch" % label
	return ""


func _max_stage_id(current_stage_id: String, candidate_stage_id: String) -> String:
	if candidate_stage_id.begins_with(StageCatalogScript.ENDLESS_PREFIX):
		if not current_stage_id.begins_with(StageCatalogScript.ENDLESS_PREFIX):
			return candidate_stage_id
		var current_endless := int(current_stage_id.trim_prefix(StageCatalogScript.ENDLESS_PREFIX))
		var candidate_endless := int(candidate_stage_id.trim_prefix(StageCatalogScript.ENDLESS_PREFIX))
		return candidate_stage_id if candidate_endless > current_endless else current_stage_id
	var current_index := StageCatalogScript.all_stage_ids().find(current_stage_id)
	var candidate_index := StageCatalogScript.all_stage_ids().find(candidate_stage_id)
	if candidate_index > current_index:
		return candidate_stage_id
	return current_stage_id


func _unlock_campaign_blueprint(candidate: RefCounted, stage_id: String, already_cleared: bool) -> Dictionary:
	if already_cleared:
		return {}
	var unlocks := {
		"stage_2_5": "flying.bomber",
		"stage_3_5": "heavy.saw",
	}
	if not unlocks.has(stage_id):
		return {}
	var recipe_id := String(unlocks[stage_id])
	var recipe := FactoryCatalogScript.recipe(recipe_id)
	return SignalRecruitServiceScript.grant_design(
		candidate,
		recipe_id,
		String(recipe.get("rating", "B")),
		int(SignalRecruitServiceScript.DUPLICATE_DATA.get(String(recipe.get("rating", "B")), 2))
	)


func _apply_casualties(candidate: RefCounted, deployed_values: Array, dead_values: Array) -> String:
	var deployed: Array[String] = []
	var dead: Array[String] = []
	for value in deployed_values:
		var unit_id := String(value)
		if deployed.has(unit_id):
			return "DEPLOYED_UNIT_IDS_MUST_BE_UNIQUE"
		if candidate.hero_by_id(unit_id) == null:
			return "DEPLOYED_UNIT_NOT_FOUND"
		deployed.append(unit_id)
	for value in dead_values:
		var unit_id := String(value)
		if dead.has(unit_id):
			return "DEAD_UNIT_IDS_MUST_BE_UNIQUE"
		if not deployed.has(unit_id):
			return "DEAD_UNIT_NOT_DEPLOYED"
		dead.append(unit_id)
	for unit_id in dead:
		for index in range(candidate.roster.size() - 1, -1, -1):
			if String(candidate.roster[index].hero_id) == unit_id:
				candidate.roster.remove_at(index)
				break
		for slot in candidate.formation.slots.keys():
			if String(candidate.formation.slots[slot]) == unit_id:
				candidate.formation.slots[slot] = ""
			candidate.auto_skill_preferences.erase(unit_id)
	return ""


func _randomize_victory_reward(run_seed: int, battle_id: String, stage_id: String, base_reward: Dictionary) -> Dictionary:
	var reward := base_reward.duplicate(true)
	for key in ["gold"]:
		var base_amount := int(base_reward.get(key, 0))
		if base_amount <= 0:
			reward[key] = 0
			continue
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(("%d|%s|%s|%s" % [run_seed, battle_id, stage_id, key]).to_utf8_buffer())
		var bytes := context.finish()
		var variance_percent := (int(bytes[0]) % 41) - 20
		reward[key] = maxi(1, base_amount * (100 + variance_percent) / 100)
	return reward

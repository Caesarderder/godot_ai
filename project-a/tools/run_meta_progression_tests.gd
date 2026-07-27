extends SceneTree

const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const MetaCatalogScript := preload("res://game/scripts/domain/meta/meta_catalog.gd")
const MetaProgressionServiceScript := preload("res://game/scripts/domain/meta/meta_progression_service.gd")
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const SignalRecruitServiceScript := preload("res://game/scripts/domain/recruitment/signal_recruit_service.gd")
const QuestServiceScript := preload("res://game/scripts/domain/quest/quest_service.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")

var executor: RefCounted
var failures: Array[String] = []
var serial: int = 0


func _initialize() -> void:
	executor = CommandExecutorScript.new(GameStateScript.create_new(20260726, 1000), func(_state: RefCounted) -> bool: return true)
	_run()
	if failures.is_empty():
		print("META_PROGRESSION_TESTS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	var legacy_v6 := GameStateScript.create_new(11, 1000).to_dict()
	legacy_v6["schema_version"] = 6
	legacy_v6.erase("meta_progression")
	var migrated := SaveCodecScript.decode(legacy_v6)
	_ok(migrated.get("ok", false), "schema v6 save migrates without reset")
	if migrated.get("ok", false):
		_eq(int(migrated["state"].schema_version), 11, "migration writes schema v11")
		_eq(int(migrated["state"].meta_progression.commander_xp), 0, "migration initializes safe meta defaults")
	var legacy_v7 := GameStateScript.create_new(12, 1000).to_dict()
	legacy_v7["schema_version"] = 7
	(legacy_v7["meta_progression"] as Dictionary).erase("commander_claimed_levels")
	var migrated_v7 := SaveCodecScript.decode(legacy_v7)
	_ok(migrated_v7.get("ok", false), "schema v7 save gains commander reward claims without reset")
	_ok(_command("refresh_meta_progression", {"now_unix": 1000}).get("ok", false), "meta refresh succeeds")
	_eq(executor.state.meta_progression.missions.size(), 8, "refresh creates daily and weekly missions")
	_eq(MetaCatalogScript.ACHIEVEMENTS.size(), 30, "catalog ships thirty permanent achievements")
	_ok(_command("claim_facility_output", {"facility_id": "porcelain_plant", "now_unix": 1600}).get("ok", false), "first facility claim succeeds")
	_ok(_command("claim_facility_output", {"facility_id": "parts_workshop", "now_unix": 1600}).get("ok", false), "second facility claim succeeds")
	var daily := executor.state.meta_progression.missions["daily.collect"] as Dictionary
	_eq(int(daily["progress"]), 2, "gameplay event advances daily mission")
	_ok(not _command("claim_meta_mission", {"mission_id": "daily.collect", "generation": int(daily["generation"])}, "daily-locked").get("ok", false), "daily mission cannot claim before dual unlock")
	executor.state.meta_progression.commander_xp = 40
	(executor.state.stage_progress["cleared_stages"] as Array).append("stage_1_1")
	var xp_before := int(executor.state.meta_progression.commander_xp)
	var claimed := _command("claim_meta_mission", {"mission_id": "daily.collect", "generation": int(daily["generation"])}, "daily-claim")
	_ok(claimed.get("ok", false), "completed daily mission claims")
	_eq(int(executor.state.meta_progression.commander_xp), xp_before + 15, "mission grants commander xp")
	_eq(int(executor.state.meta_progression.season_merit), 10, "mission grants season merit")
	var replay: Dictionary = executor.execute({
		"type": "claim_meta_mission", "command_id": String(claimed["command_id"]),
		"business_key": "daily-claim", "expected_revision": 0,
		"payload": {"mission_id": "daily.collect", "generation": int(daily["generation"])},
	})
	_ok(replay.get("ok", false), "command receipt replays mission claim")
	_eq(int(executor.state.meta_progression.commander_xp), xp_before + 15, "mission replay does not duplicate xp")

	executor.state.meta_progression.commander_xp = 300
	for stage_id in ["stage_1_2", "stage_1_3"]:
		(executor.state.stage_progress["cleared_stages"] as Array).append(stage_id)
	_ok(not bool(MetaCatalogScript.unlocks(executor.state)["recruitment"]), "recruitment stays hidden until the deterministic first chapter closes")
	(executor.state.stage_progress["cleared_stages"] as Array).append("stage_1_5")
	_ok(bool(MetaCatalogScript.unlocks(executor.state)["recruitment"]), "first chapter victory unlocks recruitment for long-term play")
	executor.state.meta_progression.season_merit = 100
	var coins_before_pass := int(executor.state.economy.toilet_coins)
	_ok(_command("claim_meta_pass_level", {"level": 1}, "season1-level1").get("ok", false), "reached pass level claims")
	_ok(not _command("claim_meta_pass_level", {"level": 1}, "season1-level1-other").get("ok", false), "same pass level cannot claim twice")
	_eq(int(executor.state.economy.toilet_coins), coins_before_pass + 30, "pass reward uses active toilet coin ledger")
	executor.state.meta_progression.season_merit = 300
	var pass_batch := _command("claim_all_meta_pass_levels", {}, "pass-batch-3")
	_ok(pass_batch.get("ok", false), "batch claim collects all remaining reached pass levels")
	_eq((pass_batch.get("event", {}) as Dictionary).get("levels", []), [2, 3], "batch pass claim excludes already claimed level")
	var commander_batch := _command("claim_all_commander_level_rewards", {}, "commander-batch-5")
	_ok(commander_batch.get("ok", false), "batch commander reward claim succeeds")
	_eq((commander_batch.get("event", {}) as Dictionary).get("levels", []), [2, 3, 4, 5], "commander batch claims each reached level once")
	_eq(int(((commander_batch.get("event", {}) as Dictionary).get("reward", {}) as Dictionary).get("toilet_coins", 0)), 80, "commander rewards report active toilet coins")
	_ok(_command("refresh_meta_progression", {"now_unix": 1000}, "achievement-backfill").get("ok", false), "refresh backfills newly cleared achievements")
	_ok(_command("claim_meta_achievement", {"achievement_id": "meta.campaign.first"}, "achievement-first").get("ok", false), "unlocked completed achievement claims")

	executor.state.economy.recruit_tickets = 60
	var roster_before_recruit: int = executor.state.roster.size()
	var recruit := _command("signal_recruit", {"count": 10, "target_archetype": "parasite"}, "recruit-ten")
	_ok(recruit.get("ok", false), "ten signal recruits succeed: %s" % str(recruit))
	var results := (recruit.get("event", {}) as Dictionary).get("results", []) as Array
	var has_a := false
	for result in results:
		has_a = has_a or String((result as Dictionary).get("rarity", "B")) in ["A", "S"]
	_ok(has_a, "ten recruits guarantee A or above")
	for batch in 5:
		var batch_result := _command("signal_recruit", {"count": 10, "target_archetype": "parasite"}, "recruit-batch-%d" % batch)
		_ok(batch_result.get("ok", false), "recruit batch succeeds: %s" % str(batch_result))
	_ok(
		int(executor.state.meta_progression.recruit_s_pity) < 60,
		"sixty pulls resolve every reached hard pity before retaining later progress"
	)
	_eq(executor.state.roster.size(), roster_before_recruit, "signal recruitment never creates a permanent hero")
	_ok(
		not executor.state.factory.discovered_blueprints.is_empty()
			or not executor.state.meta_progression.hero_fragments.is_empty(),
		"sixty signals produce design blueprints or archetype-specific fragments"
	)
	var duplicate_recipe_id := "ordinary.assault"
	executor.state.factory.discovered_blueprints[duplicate_recipe_id] = true
	var duplicate_fragments_before := int(executor.state.meta_progression.hero_fragments.get("assault", 0))
	var duplicate_design := SignalRecruitServiceScript.grant_design(
		executor.state,
		duplicate_recipe_id,
		"B",
		20
	)
	_eq(String(duplicate_design.get("kind", "")), "hero_fragments", "duplicate signal designs report the dedicated fragment result kind")
	_eq(int(duplicate_design.get("amount", 0)), 20, "B duplicate signal design grants twenty assault fragments")
	_eq(int(executor.state.meta_progression.hero_fragments.get("assault", 0)), duplicate_fragments_before + 20, "duplicate signal design credits only its archetype ledger")
	_eq(int(executor.state.factory.blueprint_data.get(duplicate_recipe_id, 0)), 0, "duplicate signal design never writes blueprint data")
	var research_recipe_id := ""
	for recipe_id in executor.state.factory.discovered_blueprints:
		research_recipe_id = String(recipe_id)
		break
	_ok(not research_recipe_id.is_empty(), "signal recruitment leaves at least one new design for research")
	var researched_hero: RefCounted = null
	if not research_recipe_id.is_empty():
		_ok(_command("unlock_foundational_blueprint", {
			"recipe_id": research_recipe_id, "now_unix": 1000,
		}, "signal-design-research").get("ok", false), "research lab starts a signal-acquired design")
		var research_claim := _command(
			"claim_blueprint_research",
			{"now_unix": 1045},
			"signal-design-claim"
		)
		_ok(research_claim.get("ok", false), "research lab turns the design into one permanent hero")
		researched_hero = executor.state.hero_by_id(
			String((research_claim.get("event", {}) as Dictionary).get("hero_id", ""))
		)
	_ok(researched_hero != null, "researched signal design joins the roster")
	if researched_hero != null:
		var research_recipe := FactoryCatalogScript.recipe(research_recipe_id)
		_eq(String(researched_hero.aptitude_id), String(research_recipe.get("rating", "B")), "researched hero inherits the B/A/S catalog rating")
		var star_quote := LogisticsServiceScript.star_upgrade_quote(
			executor.state,
			String(researched_hero.hero_id)
		)
		executor.state.meta_progression.hero_fragments[researched_hero.archetype_id] = int(
			(star_quote.get("cost", {}) as Dictionary).get("hero_fragments", 0)
		)
		var star_result := _command("upgrade_hero_star", {"hero_id": researched_hero.hero_id}, "researched-data-star")
		_ok(star_result.get("ok", false), "matching archetype fragments can fund star upgrade: %s" % str(star_result))
		_eq(int(executor.state.meta_progression.hero_fragments.get(researched_hero.archetype_id, 0)), 0, "star upgrade consumes only matching archetype fragments")
	_test_quest_blueprint_reward_conversion()
	var reserve_hero: RefCounted = null
	for hero in executor.state.roster:
		if not executor.state.formation.hero_ids().has(String(hero.hero_id)):
			reserve_hero = hero
			break
	_ok(reserve_hero != null, "research creates at least one reserve hero")
	if reserve_hero != null:
		var formation_result := _command("assign_formation_slot", {"slot": "troop_5", "hero_id": reserve_hero.hero_id})
		_ok(formation_result.get("ok", false), "researched reserve can be deployed into a selected slot")
		_eq(String(executor.state.formation.slots["troop_5"]), String(reserve_hero.hero_id), "formation slot stores researched permanent hero")
	executor.state.meta_progression.achievement_progress["meta.factory.claim_1"] = 1
	executor.state.meta_progression.achievement_progress["meta.collection.five"] = 5
	var claimable_before := MetaProgressionServiceScript.claimable_summary(executor.state)
	_ok(int(claimable_before["achievements"]) >= 2, "claimable summary exposes completed permanent achievements")
	_ok(int(claimable_before["total"]) >= int(claimable_before["achievements"]), "claimable summary aggregates all meta reward sources")
	var achievement_batch := _command("claim_all_meta_achievements", {}, "achievement-batch")
	_ok(achievement_batch.get("ok", false), "completed achievements support batch claim")
	_ok((achievement_batch.get("event", {}) as Dictionary).get("achievement_ids", []).size() >= 2, "batch achievement claim returns a detailed id list")
	var claimable_after := MetaProgressionServiceScript.claimable_summary(executor.state)
	_eq(int(claimable_after["achievements"]), 0, "batch claim clears the achievement notification count")

	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(executor.state))
	var final_xp := int(executor.state.meta_progression.commander_xp)
	_ok(decoded.get("ok", false), "schema v11 meta state roundtrips")
	if decoded.get("ok", false):
		_eq(int(decoded["state"].meta_progression.recruit_draw_count), 60, "recruit counter persists")
		_eq(int(decoded["state"].meta_progression.commander_xp), final_xp, "commander xp persists")
	_eq(MetaCatalogScript.commander_level(450), 6, "commander level curve reaches level six at 450 xp")
	_run_cycle_rollover_tests()


func _test_quest_blueprint_reward_conversion() -> void:
	var first_state: RefCounted = GameStateScript.create_new(20260728, 1000, false)
	(first_state.stage_progress["cleared_stages"] as Array).append("stage_1_5")
	var first_refresh := QuestServiceScript.refresh_quests(first_state)
	_ok(bool(first_refresh.get("ok", false)), "quest refresh exposes the first chapter blueprint reward")
	var first_shards := int(first_state.economy.hero_shards)
	var first_claim := QuestServiceScript.claim_quest(
		first_state,
		"major.stage_1_5",
		0,
		"quest-blueprint-first"
	)
	_ok(bool(first_claim.get("ok", false)), "first milestone blueprint reward claims: %s" % str(first_claim))
	_ok(
		bool(first_state.factory.discovered_blueprints.get("ordinary.sonic", false)),
		"first milestone blueprint enters the research inventory"
	)
	_ok(
		not bool(first_state.factory.blueprints.get("ordinary.sonic", false)),
		"quest blueprint still requires research before becoming a permanent design"
	)
	_eq(int(first_state.economy.hero_shards), first_shards, "first blueprint does not grant legion data")
	_eq(
		int(first_state.factory.blueprint_data.get("ordinary.sonic", 0)),
		0,
		"first quest blueprint never writes the retired blueprint-data ledger"
	)

	var duplicate_state: RefCounted = GameStateScript.create_new(20260729, 1000, false)
	duplicate_state.factory.discovered_blueprints["ordinary.sonic"] = true
	(duplicate_state.stage_progress["cleared_stages"] as Array).append("stage_1_5")
	var duplicate_refresh := QuestServiceScript.refresh_quests(duplicate_state)
	_ok(bool(duplicate_refresh.get("ok", false)), "duplicate blueprint quest refresh succeeds")
	var duplicate_fragments := int(duplicate_state.meta_progression.hero_fragments.get("sonic", 0))
	var duplicate_claim := QuestServiceScript.claim_quest(
		duplicate_state,
		"major.stage_1_5",
		0,
		"quest-blueprint-duplicate"
	)
	_ok(bool(duplicate_claim.get("ok", false)), "duplicate milestone blueprint reward claims: %s" % str(duplicate_claim))
	_eq(
		int(duplicate_state.meta_progression.hero_fragments.get("sonic", 0)),
		duplicate_fragments + 10,
		"duplicate quest blueprint converts to sonic-specific fragments"
	)
	_eq(
		int(duplicate_state.factory.blueprint_data.get("ordinary.sonic", 0)),
		0,
		"duplicate quest blueprint never writes blueprint data"
	)


func _run_cycle_rollover_tests() -> void:
	executor = CommandExecutorScript.new(GameStateScript.create_new(20260727, 1000), func(_state: RefCounted) -> bool: return true)
	_ok(_command("refresh_meta_progression", {"now_unix": 1000}, "cycle-initial").get("ok", false), "cycle fixture initializes")
	var meta: RefCounted = executor.state.meta_progression
	var daily_generation := int(meta.daily_generation)
	var weekly_generation := int(meta.weekly_generation)
	meta.commander_xp = 1350
	executor.state.stage_progress["cleared_stages"] = ["stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5"]
	(meta.missions["daily.collect"] as Dictionary)["progress"] = 2
	_ok(_command("claim_meta_mission", {
		"mission_id": "daily.collect",
		"generation": daily_generation,
	}, "cycle-daily-claim").get("ok", false), "current daily generation claims")
	_ok(_command("refresh_meta_progression", {"now_unix": 86401}, "cycle-next-day").get("ok", false), "next day refresh succeeds")
	meta = executor.state.meta_progression
	_eq(int(meta.daily_generation), daily_generation + 1, "daily generation advances exactly once")
	_eq(int((meta.missions["daily.collect"] as Dictionary)["progress"]), 0, "new daily mission starts at zero")
	_ok(not _command("claim_meta_mission", {
		"mission_id": "daily.collect",
		"generation": daily_generation,
	}, "cycle-stale-daily").get("ok", false), "stale daily generation cannot claim")
	_ok(_command("refresh_meta_progression", {"now_unix": 604801}, "cycle-next-week").get("ok", false), "next week refresh succeeds")
	meta = executor.state.meta_progression
	_eq(int(meta.weekly_generation), weekly_generation + 1, "weekly generation advances exactly once")
	meta.season_merit = 250
	meta.recruit_s_pity = 17
	var first_pass := _command("claim_meta_pass_level", {"level": 1}, "cycle-pass-one")
	_ok(first_pass.get("ok", false), "one earned season level claims before rollover")
	var coins_before_rollover := int(executor.state.economy.toilet_coins)
	var rollover := _command("refresh_meta_progression", {"now_unix": 2419201}, "cycle-next-season")
	_ok(rollover.get("ok", false), "next season refresh succeeds")
	meta = executor.state.meta_progression
	var rollover_event := rollover.get("event", {}) as Dictionary
	_eq(rollover_event.get("rollover_claimed_levels", []), [2], "season rollover auto-grants only unclaimed earned levels")
	_eq(int(executor.state.economy.toilet_coins), coins_before_rollover + 30, "rollover reward reaches active coin ledger")
	_eq(int(meta.season_merit), 0, "new season starts with zero merit")
	_eq(int(meta.recruit_s_pity), 17, "season rollover preserves recruitment pity")
	_ok(meta.pass_claimed_levels.is_empty(), "new season starts with a clean pass claim set")


func _command(command_type: String, payload: Dictionary, business_key: String = "") -> Dictionary:
	serial += 1
	return executor.execute({
		"type": command_type,
		"command_id": "meta-test-%d" % serial,
		"business_key": business_key,
		"expected_revision": int(executor.state.revision),
		"payload": payload,
	})


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

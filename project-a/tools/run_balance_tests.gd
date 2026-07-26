extends SceneTree

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const CombatPowerScript := preload("res://game/scripts/domain/progression/combat_power.gd")
const EconomyValuationScript := preload("res://game/scripts/domain/economy/economy_valuation.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const HeroProgressionScript := preload("res://game/scripts/domain/progression/hero_progression.gd")
const GrowthPlanScript := preload("res://game/scripts/domain/progression/growth_plan.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")
const WarReadinessReportScript := preload("res://game/scripts/domain/progression/war_readiness_report.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_stage_curve()
	_test_war_readiness_report()
	_test_power_contract()
	_test_permanent_upgrade_contract()
	_test_growth_plan()
	_test_gman_reward_ceiling()
	if failures.is_empty():
		print("BALANCE TESTS PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("BALANCE TESTS FAIL: %d failure(s)" % failures.size())
		quit(1)


func _test_war_readiness_report() -> void:
	var state: RefCounted = GameStateScript.create_new(20260726, 1000, false)
	var config := StageCatalogScript.stage("stage_1_1")
	var healthy := WarReadinessReportScript.derive(state, config)
	_check(int(healthy.get("cp_full", 0)) > 0, "war report derives positive formation power")
	_eq(int(healthy.get("cp_ready", 0)), int(healthy.get("cp_full", 0)), "lossless compatibility power fields remain equal")
	_eq(int(healthy.get("ready_count", 0)), state.formation.hero_ids().size(), "war report counts every deployable permanent hero")
	state.roster[0].readiness = 25
	var legacy_readiness := WarReadinessReportScript.derive(state, config)
	_eq(int(legacy_readiness.get("cp_ready", 0)), int(legacy_readiness.get("cp_full", 0)), "legacy readiness cannot lower current formation power")
	_eq(int(legacy_readiness.get("repair_burden", -1)), 0, "lossless report has no repair burden")
	_check(String((legacy_readiness.get("next_action", {}) as Dictionary).get("id", "")) != "repair", "lossless report never recommends repair")
	state.factory.materials = {"porcelain": 100, "parts": 1, "sludge": 100}
	var scarce := WarReadinessReportScript.derive(state, config)
	_eq(String(scarce.get("weakest_resource_id", "")), "parts", "war report identifies the weakest capacity-adjusted resource")
	var first_wall := WarReadinessReportScript.derive(state, StageCatalogScript.stage("stage_1_4"))
	_eq(String((first_wall.get("next_action", {}) as Dictionary).get("id", "")), "discover", "first 1-4 encounter prioritizes the authored information battle over generic growth")
	_check(String((first_wall.get("next_action", {}) as Dictionary).get("title", "")).contains("试探炮台"), "first 1-4 encounter names the discovery action")
	state.attempt_counters["stage_1_4"] = 1
	state.factory.eligible_facilities["research_lab"] = true
	var known_wall := WarReadinessReportScript.derive(state, StageCatalogScript.stage("stage_1_4"))
	_eq(String((known_wall.get("next_action", {}) as Dictionary).get("id", "")), "research", "known 1-4 wall routes to research instead of generic growth")
	_check(String((known_wall.get("next_action", {}) as Dictionary).get("title", "")).contains("建造研究所"), "known 1-4 wall names the first executable recovery")
	state.factory.facilities["research_lab"] = 1
	var lab_ready := WarReadinessReportScript.derive(state, StageCatalogScript.stage("stage_1_4"))
	_check(String((lab_ready.get("next_action", {}) as Dictionary).get("title", "")).contains("免费突破十连"), "built lab advances the recovered action to the deterministic breakthrough")
	var assault: RefCounted = HeroGeneratorScript.generate_archetype(20260726, 2, "assault", "fighter")
	var armored: RefCounted = HeroGeneratorScript.generate_archetype(20260726, 3, "armored", "guardian")
	state.roster.append(assault)
	state.roster.append(armored)
	var reinforcements_ready := WarReadinessReportScript.derive(state, StageCatalogScript.stage("stage_1_4"))
	_eq(String((reinforcements_ready.get("next_action", {}) as Dictionary).get("id", "")), "formation", "claimed breakthrough advances the recovered action to formation")
	state.formation.slots["troop_1"] = armored.hero_id
	state.formation.slots["troop_2"] = assault.hero_id
	var counterattack_ready := WarReadinessReportScript.derive(state, StageCatalogScript.stage("stage_1_4"))
	_check(String((counterattack_ready.get("next_action", {}) as Dictionary).get("id", "")) not in ["research", "formation", "upgrade"], "deployed reinforcements release the player to counterattack")


func _test_economy_valuation() -> void:
	_eq(EconomyValuationScript.resource_value_gold("xp_books"), 60, "one training book has a stable 60-gold base value")
	_eq(EconomyValuationScript.bundle_value_gold({"porcelain": 40}), 128, "porcelain salvage offer is worth 128 gold")
	_eq(EconomyValuationScript.bundle_value_gold({"parts": 28, "sludge": 20}), 192, "mixed salvage offer is worth 192 gold")
	_eq(EconomyValuationScript.bundle_value_gold({"gold": 120, "xp_books": 2}), 240, "training salvage offer is worth 240 gold")
	_eq(EconomyValuationScript.resource_value_gold("salvage") * 8, 128, "eight salvage equals the porcelain offer")
	_eq(EconomyValuationScript.resource_value_gold("salvage") * 12, 192, "twelve salvage equals the mixed offer")
	_eq(EconomyValuationScript.resource_value_gold("salvage") * 15, 240, "fifteen salvage equals the training offer")
	for recipe_id in ["ordinary.assault", "flying.rocket", "heavy.saw", "special.parasite"]:
		_check(EconomyValuationScript.recipe_cost_gold(recipe_id) > 0, "%s has a material gold cost" % recipe_id)
		_check(EconomyValuationScript.blueprint_value_gold(recipe_id) > EconomyValuationScript.recipe_cost_gold(recipe_id), "%s blueprint value exceeds one production batch" % recipe_id)


func _test_power_contract() -> void:
	var gman: RefCounted = HeroGeneratorScript.create_initial_roster(20260726)[0]
	var level_one_power := CombatPowerScript.hero_power(gman)
	HeroProgressionScript.train_with_books(gman, 16)
	var max_level_power := CombatPowerScript.hero_power(gman)
	_check(level_one_power > 0, "Gman has positive combat power")
	_check(max_level_power > level_one_power, "training increases Gman combat power")
	_check(max_level_power < level_one_power * 2, "L1-L5 training cannot double Gman power")
	var two_star := HeroGeneratorScript.generate_archetype(20260726, 1, "assault", "fighter")
	var one_star_power := CombatPowerScript.hero_power(two_star)
	var projected_two_star_power := CombatPowerScript.projected_hero_power_for_star(two_star, 2)
	_eq(int(two_star.star), 1, "star projection never mutates permanent hero state")
	two_star.star = 2
	_check(CombatPowerScript.hero_power(two_star) > one_star_power, "star promotion increases displayed combat power")
	_eq(projected_two_star_power, CombatPowerScript.hero_power(two_star), "star choice preview uses the canonical post-upgrade combat power")
	_eq(CombatPowerScript.STAR_SKILL_BP[3], CombatPowerScript.STAR_SKILL_BP[5], "skill power multiplier caps when skill tier caps at three stars")


func _test_permanent_upgrade_contract() -> void:
	var state: RefCounted = GameStateScript.create_new(20260726, 1000)
	var hero_id := String(state.formation.hero_ids()[0])
	var hero: RefCounted = state.hero_by_id(hero_id)
	var level_before := int(hero.level)
	var xp_before := int(hero.xp)
	var stats_before := (hero.base_stats as Dictionary).duplicate(true)
	var power_before := CombatPowerScript.hero_power(hero)
	state.economy.toilet_coins = 999
	state.factory.materials = {"porcelain": 999, "parts": 999, "sludge": 999}
	var result := LogisticsServiceScript.upgrade_hero(state, hero_id)
	_check(bool(result.get("ok", false)), "permanent hero upgrade succeeds with sufficient resources")
	_eq(int(hero.level), level_before + 1, "permanent upgrade advances exactly one level")
	_check(int(hero.xp) > xp_before, "permanent upgrade advances XP to the target threshold")
	_check(hero.base_stats != stats_before, "permanent upgrade applies deterministic base-stat growth")
	_check(CombatPowerScript.hero_power(hero) > power_before, "permanent upgrade produces positive combat power")
	var event := result.get("event", {}) as Dictionary
	_eq(int(event.get("power_gain", 0)), CombatPowerScript.hero_power(hero) - power_before, "upgrade event reports the canonical power delta")


func _test_progression_cost_curve() -> void:
	var gman: RefCounted = HeroGeneratorScript.create_initial_roster(20260726)[0]
	_eq(HeroProgressionScript.next_book_gold_cost(gman), 20, "L1 training starts at twenty gold")
	_eq(HeroProgressionScript.books_to_next_level(gman), 2, "planner budgets the full two-book L1 level milestone")
	_eq(HeroProgressionScript.training_gold_cost(gman, 2), 40, "two L1 books cost forty gold")
	HeroProgressionScript.train_with_books(gman, 2)
	_eq(HeroProgressionScript.next_book_gold_cost(gman), 35, "L2 training rises to thirty-five gold")
	_eq(HeroProgressionScript.books_to_next_level(gman), 3, "L2 milestone requires three books")
	_eq(HeroProgressionScript.training_gold_cost(gman, 14), 860, "remaining L2-L5 training has a steep gold sink")
	HeroProgressionScript.train_with_books(gman, 14)
	_eq(HeroProgressionScript.max_trainable_books(gman), 0, "max-level hero cannot consume extra books")
	_eq(HeroProgressionScript.books_to_next_level(gman), 0, "max-level hero has no next-level milestone")
	_eq(HeroProgressionScript.next_book_gold_cost(gman), 0, "max-level hero has no phantom training cost")
	var first_reward := StageCatalogScript.reward_for_context("stage_1_1", "victory", 0, false)
	var repeat_reward := StageCatalogScript.reward_for_context("stage_1_1", "victory", 1, true)
	_eq(int(first_reward.get("xp_books", -1)), 0, "opening victories no longer inflate Gman training")
	_eq(int(repeat_reward.get("xp_books", -1)), 0, "repeat victories never grant training books")
	_check(EconomyValuationScript.bundle_value_gold(repeat_reward) < EconomyValuationScript.bundle_value_gold(first_reward) / 2, "repeat victory value stays below half of first clear")
	_eq(StageCatalogScript.reward_for_context("stage_2_2", "defeat", 1, false), {"gold": 0, "xp_books": 0, "porcelain": 0, "parts": 0, "sludge": 0}, "repeat defeat cannot be farmed for growth")


func _test_growth_plan() -> void:
	var state: RefCounted = GameStateScript.create_new(20260726, 0)
	var first_wall := GrowthPlanScript.for_stage(state, StageCatalogScript.stage("stage_1_4"))
	_eq(first_wall["action"], "challenge", "first turret-wall attempt asks for reconnaissance instead of Gman overtraining")
	state.attempt_counters["stage_1_4"] = 1
	state.factory.discovered_blueprints["ordinary.assault"] = true
	var research_plan := GrowthPlanScript.for_stage(state, StageCatalogScript.stage("stage_1_4"))
	_eq(research_plan["action"], "research", "post-defeat plan routes to the assault blueprint")
	_eq(int(research_plan["estimated_gold_value"]), 0, "owned blueprint value is not misreported as future spending")
	state.factory.blueprint_research = {
		"recipe_id": "ordinary.assault",
		"started_at_unix": 0,
		"completes_at_unix": 5,
	}
	var active_research_plan := GrowthPlanScript.for_stage(state, StageCatalogScript.stage("stage_1_4"))
	_eq(active_research_plan["action"], "research_wait", "active Doctor research blocks duplicate research advice")
	state.factory.blueprint_research.clear()
	state.factory.discovered_blueprints.clear()
	state.economy.toilet_coins = 0
	state.factory.materials = {"porcelain": 0, "parts": 0, "sludge": 0}
	var resource_plan := GrowthPlanScript.for_stage(state, StageCatalogScript.stage("stage_2_2"))
	_eq(resource_plan["action"], "collect", "unaffordable permanent upgrade routes to resource collection")
	_check(String(resource_plan["detail"]).contains("马桶币") and String(resource_plan["detail"]).contains("陶瓷"), "upgrade shortfall preserves independent resource gates")
	state.economy.toilet_coins = 999
	state.factory.blueprints["ordinary.assault"] = true
	state.factory.materials = {"porcelain": 999, "parts": 999, "sludge": 999}
	for index in 3:
		state.factory.production_queue.append({
			"order_id": "busy_%d" % index,
			"recipe_id": "ordinary.assault",
			"started_at_unix": 0,
			"completes_at_unix": 100,
		})
	var queue_full_plan := GrowthPlanScript.for_stage(state, StageCatalogScript.stage("stage_1_4"))
	_check(queue_full_plan["action"] != "produce", "full production queue blocks impossible production advice")
	var merge_state: RefCounted = GameStateScript.create_new(20260727, 0)
	for index in 3:
		merge_state.roster.append(HeroGeneratorScript.generate_archetype(20260727, index + 1, "assault", "fighter"))
	var merge_plan := GrowthPlanScript.for_stage(merge_state, StageCatalogScript.stage("stage_2_2"))
	_eq(merge_plan["action"], "merge", "safe inventory merge is recommended")
	_eq(int(merge_plan["estimated_gold_value"]), 0, "available merge has no invented future gold cost")
	for index in 3:
		merge_state.formation.slots["troop_%d" % (index + 1)] = String(merge_state.roster[index + 1].hero_id)
	var unsafe_merge_plan := GrowthPlanScript.for_stage(merge_state, StageCatalogScript.stage("stage_2_2"))
	_check(unsafe_merge_plan["action"] != "merge", "planner rejects a merge that cannot refill deployed slots")


func _test_stage_curve() -> void:
	var previous_recommended := 0
	var previous_enemy_bp := 0
	for stage_id in StageCatalogScript.all_stage_ids():
		var config := StageCatalogScript.stage(stage_id)
		var recommended := int(config.get("recommended_power", 0))
		var minimum := int(config.get("minimum_power", 0))
		var enemy_bp := int(config.get("power_bp", 0))
		_check(recommended > previous_recommended, "%s recommended power rises monotonically" % stage_id)
		_check(enemy_bp > previous_enemy_bp, "%s enemy scaling rises monotonically" % stage_id)
		_eq(minimum, int(recommended * 85 / 100), "%s minimum power is the 85%% challenge line" % stage_id)
		previous_recommended = recommended
		previous_enemy_bp = enemy_bp
	_check(int(StageCatalogScript.stage("stage_2_2").get("power_bp", 0)) >= 20000, "2-2 is a real post-tutorial growth wall")
	_check(int(StageCatalogScript.stage("stage_5_5").get("power_bp", 0)) >= 37500, "Act I finale is not reachable on the old shallow curve")
	var release_power := CombatPowerScript.snapshots_power(_release_roster())
	var final_config := StageCatalogScript.stage("stage_5_5")
	_check(release_power >= int(final_config["recommended_power"]), "three-star release roster meets the displayed finale recommendation")
	var undertrained_power := CombatPowerScript.snapshots_power(_undertrained_roster())
	_check(undertrained_power < int(final_config["minimum_power"]), "one-star squad is visibly below the finale challenge line")


func _test_gman_reward_ceiling() -> void:
	var gman: RefCounted = HeroGeneratorScript.create_initial_roster(20260726)[0]
	HeroProgressionScript.train_with_books(gman, 16)
	var stats := HeroProgressionScript.derived_battle_stats(gman)
	var snapshot: Dictionary = {
		"hero_id": gman.hero_id,
		"display_name": gman.display_name,
		"archetype_id": gman.archetype_id,
		"class_id": gman.class_id,
		"star": gman.star,
		"max_hp": stats["max_hp"],
		"attack": maxi(int(stats["physical_atk"]), int(stats["magic_atk"])),
		"defense": stats["defense"],
		"slot": 0,
		"auto_skill": true,
	}
	for stage_id in ["stage_1_4", "stage_2_2", "stage_5_5"]:
		var session: RefCounted = BattleSessionScript.new()
		session.start([snapshot], stage_id, StageCatalogScript.stage(stage_id))
		var safety := 0
		while not session.is_finished and safety < 10000:
			session.advance_tick()
			safety += 1
		_check(session.is_finished, "%s max-level Gman simulation resolves" % stage_id)
		_check(String(session.result.get("outcome", "")) != "victory", "%s cannot be cleared by putting all training rewards into Gman" % stage_id)


func _release_roster() -> Array[Dictionary]:
	var archetypes: Array[String] = ["armored", "assault", "saw", "rocket", "repair", "parasite"]
	var values: Array[Dictionary] = []
	for index in archetypes.size():
		var guardian := index in [0, 4]
		values.append({
			"archetype_id": archetypes[index],
			"star": 3,
			"max_hp": 320 if guardian else 235,
			"attack": 82,
			"defense": 34 if guardian else 23,
			"speed_milli": 80000,
			"crit_bp": 1000,
		})
	return values


func _undertrained_roster() -> Array[Dictionary]:
	var values := _release_roster()
	for hero in values:
		hero["star"] = 1
		hero["max_hp"] = 145
		hero["attack"] = 34
		hero["defense"] = 11
	return values


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

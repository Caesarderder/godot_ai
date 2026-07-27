extends SceneTree

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const CombatPowerScript := preload("res://game/scripts/domain/progression/combat_power.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const FactoryCatalogScript := preload("res://game/scripts/domain/factory/factory_catalog.gd")
const FactionCatalogScript := preload("res://game/scripts/domain/content/faction_catalog.gd")
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const HeroProgressionScript := preload("res://game/scripts/domain/progression/hero_progression.gd")
const LogisticsServiceScript := preload("res://game/scripts/domain/factory/logistics_service.gd")
const RecruitmentResultProjectionScript := preload(
	"res://game/scripts/domain/recruitment/recruitment_result_projection.gd"
)
const SaveCodecScript := preload("res://game/scripts/persistence/save_codec.gd")
const SignalRecruitServiceScript := preload(
	"res://game/scripts/domain/recruitment/signal_recruit_service.gd"
)
const StageCatalogScript := preload("res://game/scripts/domain/content/stage_catalog.gd")

const RUN_SEEDS: Array[int] = [20260721, 20260722, 20260723, 20260724, 20260725, 20260726, 20260727]
const TICKS_PER_SECOND := 5
const INTERACTION_SECONDS := 8
const POST_CHAPTER_SESSION_CEILING_SECONDS := 1200

var failures: Array[String] = []
var executor: RefCounted
var serial: int = 0
var late_wall_routes: int = 0


func _init() -> void:
	for run_seed in RUN_SEEDS:
		_run_seed(run_seed)
	_ok(
		late_wall_routes >= RUN_SEEDS.size() - 1,
		"at least six of seven faction routes retain the authored growth wall while one perfect manual route may earn a skill shortcut"
	)
	_test_s_one_star_value()
	_test_free_ten_hard_pity_edge()
	_test_faction_core_choice_is_durable_and_exclusive()
	_test_tier_two_doctrine_choice_is_durable_and_exclusive()
	if failures.is_empty():
		print("POST_30M_FACTION_TESTS_OK: %d seeded faction journeys" % RUN_SEEDS.size())
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("POST_30M_FACTION_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _run_seed(run_seed: int) -> void:
	executor = CommandExecutorScript.new(
		_post_chapter_one_state(run_seed),
		func(_state: RefCounted) -> bool: return true
	)
	serial = 0
	var welfare := _command(
		"claim_new_player_welfare",
		{},
		"post30-welfare"
	)
	_ok(bool(welfare.get("ok", false)), "seed %d post-chapter welfare is claimable" % run_seed)
	var welfare_target_id := ""
	for starter in executor.state.roster:
		if int(starter.star) == 1 and String(starter.archetype_id) in ["assault", "armored"]:
			welfare_target_id = String(starter.hero_id)
			break
	var welfare_star := _command(
		"use_welfare_star_core",
		{"hero_id": welfare_target_id},
		"post30-welfare-star"
	)
	_ok(
		bool(welfare_star.get("ok", false)),
		"seed %d welfare core turns the unchosen starter into a second faction option" % run_seed
	)
	var shared_data_before := int(executor.state.economy.hero_shards)
	var draw_count_before := int(executor.state.meta_progression.recruit_draw_count)
	var claim := _command(
		"claim_faction_signal",
		{},
		"post30-free-faction-ten"
	)
	_ok(bool(claim.get("ok", false)), "seed %d free faction ten succeeds: %s" % [run_seed, str(claim)])
	if not bool(claim.get("ok", false)):
		return
	var event := claim.get("event", {}) as Dictionary
	var results := event.get("results", []) as Array
	_eq(results.size(), 10, "seed %d free faction ten has exactly ten results" % run_seed)
	_eq(
		int(executor.state.meta_progression.recruit_draw_count),
		draw_count_before + 10,
		"seed %d free faction ten advances exactly ten long-term draws" % run_seed
	)
	var has_a := false
	var new_archetypes: Array[String] = []
	var fragment_archetypes: Array[String] = []
	for result_value in results:
		var result := result_value as Dictionary
		has_a = has_a or String(result.get("rarity", "B")) in ["A", "S"]
		if String(result.get("kind", "")) == "blueprint":
			new_archetypes.append(String(result.get("archetype_id", "")))
		elif String(result.get("kind", "")) == "hero_fragments":
			fragment_archetypes.append(String(result.get("archetype_id", "")))
	_ok(has_a, "seed %d free faction ten guarantees A or S" % run_seed)
	_ok(not new_archetypes.is_empty(), "seed %d free faction ten reveals a new archetype" % run_seed)
	var guaranteed_archetype := String(event.get("guaranteed_duplicate_archetype", ""))
	var core_candidates := event.get("faction_core_candidates", []) as Array
	var first_core_recipe := (
		FactoryCatalogScript.recipe_for_archetype(String(core_candidates[0]))
		if core_candidates.size() == 2
		else {}
	)
	var second_core_recipe := (
		FactoryCatalogScript.recipe_for_archetype(String(core_candidates[1]))
		if core_candidates.size() == 2
		else {}
	)
	_ok(
		not guaranteed_archetype.is_empty()
			and new_archetypes.has(guaranteed_archetype)
			and fragment_archetypes.has(guaranteed_archetype),
		"seed %d one new archetype also receives a matching duplicate" % run_seed
	)
	_ok(
		core_candidates.size() == 2
			and String(core_candidates[0]) != String(core_candidates[1])
			and fragment_archetypes.has(String(core_candidates[0]))
			and fragment_archetypes.has(String(core_candidates[1])),
		"seed %d free faction ten guarantees two distinct, star-ready core choices" % run_seed
	)
	_ok(
		core_candidates.size() == 2
			and String(first_core_recipe.get("rating", ""))
				== String(second_core_recipe.get("rating", ""))
			and String(first_core_recipe.get("rating", ""))
				== String(event.get("faction_core_rating", ""))
			and FactionCatalogScript.faction_for(String(core_candidates[0]))
				!= FactionCatalogScript.faction_for(String(core_candidates[1])),
		"seed %d core choice compares playstyles at the same visible rating" % run_seed
	)
	_ok(
		int(executor.state.economy.hero_shards) >= shared_data_before,
		"seed %d onboarding rewards remain valid while duplicates use separate fragments" % run_seed
	)

	var deterministic_state := _post_chapter_one_state(run_seed)
	var deterministic_executor := CommandExecutorScript.new(
		deterministic_state,
		func(_state: RefCounted) -> bool: return true
	)
	var deterministic_claim := deterministic_executor.execute({
		"type": "claim_faction_signal",
		"command_id": "deterministic-claim",
		"business_key": "post30-free-faction-ten",
		"expected_revision": 0,
		"payload": {},
	})
	_eq(
		(deterministic_claim.get("event", {}) as Dictionary).get("results", []),
		results,
		"seed %d free faction ten is deterministic" % run_seed
	)

	var chosen_archetype := (
		String(core_candidates[run_seed % 2])
		if core_candidates.size() == 2
		else guaranteed_archetype
	)
	var core_choice := _command(
		"choose_faction_core",
		{"archetype_id": chosen_archetype},
		"post30-faction-core-choice"
	)
	_ok(bool(core_choice.get("ok", false)), "seed %d player can choose either offered core" % run_seed)
	_eq(
		RecruitmentResultProjectionScript.selected_faction_core(executor.state),
		chosen_archetype,
		"seed %d chosen core becomes the durable faction authority" % run_seed
	)
	var recipe := FactoryCatalogScript.recipe_for_archetype(chosen_archetype)
	_ok(not recipe.is_empty(), "seed %d guaranteed archetype resolves to a recipe" % run_seed)
	if recipe.is_empty():
		return
	var recipe_id := String(recipe["recipe_id"])
	var research_start := _command(
		"unlock_foundational_blueprint",
		{"recipe_id": recipe_id, "now_unix": 2000},
		"post30-research:%s" % recipe_id
	)
	_ok(bool(research_start.get("ok", false)), "seed %d selected faction design starts research" % run_seed)
	var research_claim := _command(
		"claim_blueprint_research",
		{"now_unix": 2005},
		"post30-research-claim:%s" % recipe_id
	)
	_ok(bool(research_claim.get("ok", false)), "seed %d selected faction design becomes a permanent hero" % run_seed)
	if not bool(research_claim.get("ok", false)):
		return
	var hero_id := String((research_claim.get("event", {}) as Dictionary).get("hero_id", ""))
	var hero: RefCounted = executor.state.hero_by_id(hero_id)
	_ok(hero != null, "seed %d researched faction hero exists" % run_seed)
	if hero == null:
		return
	var assign := _command(
		"assign_formation_slot",
		{"slot": "troop_3", "hero_id": hero_id},
		"post30-formation:%s" % hero_id
	)
	_ok(bool(assign.get("ok", false)), "seed %d selected faction hero joins the six-slot formation" % run_seed)
	var one_star_chapter := _simulate_chapter_two(executor.state)

	var wrong_archetype := "rocket" if chosen_archetype != "rocket" else "repair"
	var correct_balance := int(executor.state.meta_progression.hero_fragments.get(chosen_archetype, 0))
	executor.state.meta_progression.hero_fragments[chosen_archetype] = 0
	executor.state.meta_progression.hero_fragments[wrong_archetype] = 999
	var wrong_fragments := _command(
		"upgrade_hero_star",
		{"hero_id": hero_id},
		"post30-wrong-fragments:%s" % hero_id
	)
	_ok(
		not bool(wrong_fragments.get("ok", false))
			and String(wrong_fragments.get("error", "")) == "NOT_ENOUGH_HERO_FRAGMENTS",
		"seed %d another archetype's fragments cannot upgrade the selected hero" % run_seed
	)
	executor.state.meta_progression.hero_fragments[chosen_archetype] = correct_balance
	var quote := LogisticsServiceScript.star_upgrade_quote(executor.state, hero_id)
	_ok(bool(quote.get("ok", false)), "seed %d guaranteed duplicate funds the selected hero's 2-star quote" % run_seed)
	var star := _command(
		"upgrade_hero_star",
		{"hero_id": hero_id},
		"post30-star:%s" % hero_id
	)
	_ok(bool(star.get("ok", false)), "seed %d selected faction hero reaches two stars" % run_seed)
	hero = executor.state.hero_by_id(hero_id)
	_eq(int(hero.star), 2, "seed %d selected faction hero records the two-star transformation" % run_seed)
	_ok(
		hero.skill_ids.has("%s_passive" % chosen_archetype),
		"seed %d two-star hero owns its qualitative passive unlock" % run_seed
	)

	var two_star_chapter := _simulate_chapter_two(executor.state)
	var battle := two_star_chapter[0] as Dictionary
	_ok(
		["victory", "defeat"].has(String(battle.get("outcome", "")))
			and int(battle.get("ticks", 0)) > 0,
		"seed %d faction formation completes a real second-chapter battle" % run_seed
	)
	var qualitative_metric := _qualitative_metric_for(chosen_archetype)
	var qualitative_events := 0
	for chapter_result in two_star_chapter:
		qualitative_events += int((chapter_result as Dictionary).get(qualitative_metric, 0))
	_ok(
		not qualitative_metric.is_empty() and qualitative_events > 0,
		"seed %d two-star faction mechanic leaves visible battle evidence for %s"
			% [run_seed, chosen_archetype]
	)
	# Three first clears provide 90 combat XP and cover level two before 2-4.
	hero.xp = 90
	executor.state.economy.toilet_coins += 200
	var level_two := LogisticsServiceScript.upgrade_hero(executor.state, hero_id)
	var grown_gate := _simulate_stage(executor.state, "stage_2_4")
	# Clearing 2-4 raises the faction core to 120 XP, funding level three for the Boss.
	hero.xp = 120
	var level_three := LogisticsServiceScript.upgrade_hero(executor.state, hero_id)
	_ok(
		bool(level_two.get("ok", false)) and bool(level_three.get("ok", false)),
		"seed %d chapter-two victories fund the faction core through level three" % run_seed
	)
	var grown_boss := _simulate_stage(executor.state, "stage_2_5")
	var chapter_three_opening := _simulate_stage(
		executor.state,
		"stage_3_1",
		FactionCatalogScript.tech_preview_for(chosen_archetype)
	)
	_ok(
		not String(chapter_three_opening.get("faction_protocol_id", "")).is_empty()
			and int(chapter_three_opening.get("faction_protocol_affected", 0)) > 0,
		"seed %d chapter-three opening visibly cashes in the recruited faction protocol" % run_seed
	)
	for stage_index in 3:
		_eq(
			String((one_star_chapter[stage_index] as Dictionary).get("outcome", "")),
			"victory",
			"seed %d one-star faction core establishes value through 2-%d" % [run_seed, stage_index + 1]
		)
	var hit_late_wall := (
		String((one_star_chapter[3] as Dictionary).get("outcome", "")) == "defeat"
		or String((one_star_chapter[4] as Dictionary).get("outcome", "")) == "defeat"
	)
	if hit_late_wall:
		late_wall_routes += 1
	_eq(
		String(grown_gate.get("outcome", "")),
		"victory",
		"seed %d earned level-two faction core clears the 2-4 gate" % run_seed
	)
	_eq(
		String(grown_boss.get("outcome", "")),
		"victory",
		"seed %d two-star level-three faction core defeats 2-5" % run_seed
	)
	_ok(
		int(grown_boss.get("ticks", 10001)) <= 900,
		"seed %d mastered 2-5 route resolves within the three-minute finale ceiling" % run_seed
	)
	_ok(
		int(grown_gate.get("ticks", 10001)) <= 900,
		"seed %d mastered 2-4 gate resolves within the same three-minute attention ceiling" % run_seed
	)
	_ok(
		int(grown_gate.get("manual_skill_uses", 0)) > 0
			and int(grown_boss.get("manual_skill_uses", 0)) > 0,
		"seed %d default manual route resolves real player skill requests" % run_seed
	)
	_ok(
		int(grown_gate.get("manual_burst_actions", 0))
				< int(grown_gate.get("manual_skill_uses", 0))
			and int(grown_boss.get("manual_burst_actions", 0))
				< int(grown_boss.get("manual_skill_uses", 0))
			and int(grown_boss.get("manual_burst_actions", 100)) <= 40,
		"seed %d squad burst reduces repeated taps while preserving real manual timing" % run_seed
	)
	var first_wall_index := -1
	for stage_index in one_star_chapter.size():
		if String((one_star_chapter[stage_index] as Dictionary).get("outcome", "")) == "defeat":
			first_wall_index = stage_index
			break
	var journey_battle_ticks := 0
	var modeled_interactions := 10
	if first_wall_index < 0:
		for row in one_star_chapter:
			journey_battle_ticks += int((row as Dictionary).get("ticks", 0))
		modeled_interactions += one_star_chapter.size()
	else:
		journey_battle_ticks = int(grown_boss.get("ticks", 0))
		if first_wall_index <= 3:
			journey_battle_ticks += int(grown_gate.get("ticks", 0))
		for stage_index in range(first_wall_index + 1):
			journey_battle_ticks += int(
				(one_star_chapter[stage_index] as Dictionary).get("ticks", 0)
			)
		modeled_interactions += first_wall_index + 1
	var modeled_journey_seconds := int(ceil(
		float(journey_battle_ticks) / float(TICKS_PER_SECOND)
	)) + modeled_interactions * INTERACTION_SECONDS + 5
	_ok(
		modeled_journey_seconds <= POST_CHAPTER_SESSION_CEILING_SECONDS,
		"seed %d post-chapter critical path stays within twenty modeled minutes" % run_seed
	)
	print(JSON.stringify({
		"seed": run_seed,
		"archetype": chosen_archetype,
		"one_star": one_star_chapter,
		"two_star": two_star_chapter,
		"grown_gate": grown_gate,
		"grown_boss": grown_boss,
		"first_wall_stage": (
			"none_manual_skill_shortcut"
			if first_wall_index < 0
			else "stage_2_%d" % (first_wall_index + 1)
		),
		"modeled_journey_seconds": modeled_journey_seconds,
	}))

	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(executor.state))
	_ok(bool(decoded.get("ok", false)), "seed %d faction state survives schema v11 save roundtrip" % run_seed)
	if bool(decoded.get("ok", false)):
		var loaded: RefCounted = decoded["state"]
		_eq(
			loaded.meta_progression.hero_fragments,
			executor.state.meta_progression.hero_fragments,
			"seed %d save preserves every archetype-fragment balance" % run_seed
		)
		_eq(int(loaded.hero_by_id(hero_id).star), 2, "seed %d save preserves the selected two-star hero" % run_seed)
		_eq(
			RecruitmentResultProjectionScript.latest_results(loaded),
			results,
			"seed %d refresh can restore the exact latest recruit result from durable receipts" % run_seed
		)


func _post_chapter_one_state(run_seed: int) -> RefCounted:
	var state: RefCounted = GameStateScript.create_new(run_seed, 1000, false)
	state.meta_progression.commander_xp = 450
	state.stage_progress = {
		"highest_unlocked_stage": "stage_2_1",
		"cleared_stages": [
			"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4", "stage_1_5",
		],
	}
	state.factory.facilities["research_lab"] = 1
	state.factory.facility_placements["research_lab"] = [2, 1]
	state.factory.blueprints["ordinary.assault"] = true
	state.factory.blueprints["heavy.armored"] = true
	var assault: RefCounted = HeroGeneratorScript.generate_archetype(run_seed, 1, "assault", "fighter")
	var armored: RefCounted = HeroGeneratorScript.generate_archetype(run_seed, 2, "armored", "guardian")
	if run_seed % 2 == 0:
		armored.star = 2
	else:
		assault.star = 2
	state.roster.append(assault)
	state.roster.append(armored)
	state.factory.next_hero_sequence = 4
	state.formation.slots["troop_1"] = assault.hero_id
	state.formation.slots["troop_2"] = armored.hero_id
	return state


func _test_s_one_star_value() -> void:
	var s_hero: RefCounted = HeroGeneratorScript.generate_archetype(3001, 1, "saw", "fighter")
	var b_hero: RefCounted = HeroGeneratorScript.generate_archetype(3001, 1, "assault", "fighter")
	b_hero.star = 2
	_ok(
		CombatPowerScript.hero_power(s_hero) >= CombatPowerScript.hero_power(b_hero),
		"S one-star base power is immediately competitive with a B two-star peer"
	)
	_ok(
		not FactoryCatalogScript.active_skill_for_archetype("saw").is_empty(),
		"S one-star owns a complete active skill without requiring a duplicate"
	)


func _test_free_ten_hard_pity_edge() -> void:
	var state: RefCounted = _post_chapter_one_state(20260721)
	state.meta_progression.recruit_s_pity = 50
	var result := SignalRecruitServiceScript.recruit_free_faction_ten(state)
	_ok(bool(result.get("ok", false)), "free ten resolves when its tenth response reaches S hard pity")
	if not bool(result.get("ok", false)):
		return
	var values := (result.get("event", {}) as Dictionary).get("results", []) as Array
	_eq(values.size(), 10, "hard-pity free ten still presents exactly ten response cards")
	_eq(int(state.meta_progression.recruit_draw_count), 10, "hard-pity free ten advances ten draw indices")
	_eq(int(state.meta_progression.recruit_s_pity), 0, "tenth response consumes the 60-draw S guarantee")
	var final_response := values[9] as Dictionary
	_ok(
		String(final_response.get("rarity", "")) == "S"
			or not (final_response.get("pity_bonus", {}) as Dictionary).is_empty(),
		"tenth response exposes the guaranteed S without delaying the shared pity"
	)


func _test_faction_core_choice_is_durable_and_exclusive() -> void:
	executor = CommandExecutorScript.new(
		_post_chapter_one_state(20260729),
		func(_state: RefCounted) -> bool: return true
	)
	serial = 0
	var before_signal := _command(
		"choose_faction_core",
		{"archetype_id": "rocket"},
		"core-before-signal"
	)
	_eq(
		String(before_signal.get("error", "")),
		"FACTION_CORE_SIGNAL_MISSING",
		"faction core cannot be invented before the free signal"
	)
	var claim := _command("claim_faction_signal", {}, "core-choice-signal")
	var candidates := (claim.get("event", {}) as Dictionary).get(
		"faction_core_candidates",
		[]
	) as Array
	_ok(candidates.size() == 2, "core choice fixture receives two candidates")
	var invalid := _command(
		"choose_faction_core",
		{"archetype_id": "gman"},
		"core-invalid-choice"
	)
	_eq(
		String(invalid.get("error", "")),
		"FACTION_CORE_INVALID",
		"core choice rejects a character outside the drawn candidates"
	)
	var selected := String(candidates[1]) if candidates.size() == 2 else ""
	var chosen := _command(
		"choose_faction_core",
		{"archetype_id": selected},
		"core-valid-choice"
	)
	_ok(bool(chosen.get("ok", false)), "player can choose the second drawn candidate")
	var overwrite := _command(
		"choose_faction_core",
		{"archetype_id": String(candidates[0]) if candidates.size() == 2 else ""},
		"core-overwrite"
	)
	_eq(
		String(overwrite.get("error", "")),
		"FACTION_CORE_ALREADY_CHOSEN",
		"the alternative candidate cannot overwrite the durable identity"
	)
	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(executor.state))
	_ok(bool(decoded.get("ok", false)), "chosen faction core survives save roundtrip")
	if bool(decoded.get("ok", false)):
		_eq(
			RecruitmentResultProjectionScript.selected_faction_core(decoded["state"]),
			selected,
			"save roundtrip restores the exact player-selected core"
		)


func _test_tier_two_doctrine_choice_is_durable_and_exclusive() -> void:
	executor = CommandExecutorScript.new(
		_post_chapter_one_state(20260728),
		func(_state: RefCounted) -> bool: return true
	)
	serial = 0
	var claim := _command("claim_faction_signal", {}, "doctrine-faction-core")
	_ok(bool(claim.get("ok", false)), "doctrine test obtains one durable faction core")
	var candidates := (claim.get("event", {}) as Dictionary).get(
		"faction_core_candidates",
		[]
	) as Array
	var core := _command(
		"choose_faction_core",
		{"archetype_id": String(candidates[0]) if not candidates.is_empty() else ""},
		"doctrine-core-choice"
	)
	_ok(bool(core.get("ok", false)), "doctrine test preserves the chosen faction core")
	var locked := _command(
		"choose_faction_doctrine",
		{"doctrine_id": "coordination"},
		"doctrine-before-third-boss"
	)
	_eq(
		String(locked.get("error", "")),
		"FACTION_DOCTRINE_LOCKED",
		"Tier 2 doctrine stays locked before the third-chapter Boss"
	)
	var cleared := executor.state.stage_progress.get("cleared_stages", []) as Array
	cleared.append("stage_3_5")
	executor.state.stage_progress["cleared_stages"] = cleared
	var chosen := _command(
		"choose_faction_doctrine",
		{"doctrine_id": "coordination"},
		"doctrine-tier-two"
	)
	_ok(
		bool(chosen.get("ok", false))
			and String((chosen.get("event", {}) as Dictionary).get("doctrine_id", ""))
				== "coordination",
		"chapter-three completion permits one explicit Tier 2 doctrine"
	)
	var second_choice := _command(
		"choose_faction_doctrine",
		{"doctrine_id": "specialization"},
		"doctrine-tier-two-second-attempt"
	)
	_eq(
		String(second_choice.get("error", "")),
		"FACTION_DOCTRINE_ALREADY_CHOSEN",
		"the alternative Tier 2 doctrine cannot overwrite the durable opportunity cost"
	)
	var decoded := SaveCodecScript.from_json_text(SaveCodecScript.to_json_text(executor.state))
	_ok(bool(decoded.get("ok", false)), "chosen Tier 2 doctrine survives schema v11 save roundtrip")
	if bool(decoded.get("ok", false)):
		var found_choice := false
		for receipt_value in decoded["state"].command_receipts.values():
			var receipt := receipt_value as Dictionary
			if String(receipt.get("type", "")) != "choose_faction_doctrine":
				continue
			var event := ((receipt.get("result", {}) as Dictionary).get("event", {}) as Dictionary)
			found_choice = String(event.get("doctrine_id", "")) == "coordination"
		_ok(found_choice, "save roundtrip preserves the exact chosen Tier 2 doctrine")


func _simulate_stage(
	state: RefCounted,
	stage_id: String,
	faction_protocol: Dictionary = {}
) -> Dictionary:
	var snapshots: Array[Dictionary] = []
	for slot in state.formation.hero_ids().size():
		var hero: RefCounted = state.hero_by_id(String(state.formation.hero_ids()[slot]))
		var stats := HeroProgressionScript.derived_battle_stats(hero)
		snapshots.append({
			"hero_id": hero.hero_id,
			"display_name": hero.display_name,
			"archetype_id": hero.archetype_id,
			"class_id": hero.class_id,
			"star": hero.star,
			"max_hp": int(stats["hp"]),
			"attack": int(stats["attack"]),
			"defense": int(stats["defense"]),
			"speed_milli": int(stats["speed_milli"]),
			"crit_bp": int(stats["crit_bp"]),
			"slot": slot,
			"skill_id": FactoryCatalogScript.active_skill_for_archetype(hero.archetype_id),
			"skill_level": int(hero.active_skill_level),
			"auto_skill": false,
		})
	var session: RefCounted = BattleSessionScript.new()
	var config := StageCatalogScript.stage(stage_id)
	if not faction_protocol.is_empty():
		config["faction_protocol"] = faction_protocol.duplicate(true)
	session.start(snapshots, stage_id, config)
	var safety := 0
	var manual_skill_uses := 0
	var manual_burst_actions := 0
	while not session.is_finished and safety < 10000:
		var snapshot := session.snapshot() as Dictionary
		var has_ready_unit := false
		for unit_value in snapshot.get("units", []):
			var unit := unit_value as Dictionary
			if (
				not bool(unit.get("temporary", false))
				and bool(unit.get("alive", false))
				and int(unit.get("energy", 0)) >= BattleSessionScript.SKILL_COST
			):
				has_ready_unit = true
				break
		if (
			has_ready_unit
			and int(snapshot.get("burst_window_remaining_ticks", 0)) == 0
			and session.request_burst()
		):
			manual_burst_actions += 1
		var events: Array = session.advance_tick()
		for event_value in events:
			if String((event_value as Dictionary).get("type", "")) == "skill_used":
				manual_skill_uses += 1
		safety += 1
	var row: Dictionary = session.result.duplicate(true)
	row["outcome"] = String(session.result.get("outcome", ""))
	row["ticks"] = int(session.result.get("ticks", safety))
	row["manual_skill_uses"] = manual_skill_uses
	row["manual_burst_actions"] = manual_burst_actions
	for structure in session._structures:
		if String(structure.get("structure_id", "")) == "alliance_core":
			row["final_core_hp"] = int(structure.get("hp", 0))
			row["final_core_max_hp"] = int(structure.get("max_hp", 0))
			break
	return row


func _simulate_chapter_two(state: RefCounted) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for stage_id in ["stage_2_1", "stage_2_2", "stage_2_3", "stage_2_4", "stage_2_5"]:
		var row := _simulate_stage(state, stage_id)
		row["stage_id"] = stage_id
		rows.append(row)
	return rows


func _qualitative_metric_for(archetype_id: String) -> String:
	return String({
		"assault": "assault_cleave_extra_hits",
		"sonic": "sonic_cross_lane_extra_targets",
		"rocket": "rocket_salvo_extra_targets",
		"bomber": "bomber_splash_extra_targets",
		"armored": "armored_group_shield_extra_targets",
		"saw": "saw_followup_hits",
		"repair": "repair_group_extra_targets",
		"parasite": "parasite_extra_summons",
	}.get(archetype_id, ""))


func _command(command_type: String, payload: Dictionary, business_key: String) -> Dictionary:
	serial += 1
	return executor.execute({
		"type": command_type,
		"command_id": "post30-%d" % serial,
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

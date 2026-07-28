extends SceneTree

const GameState := preload("res://game/scripts/state/game_state.gd")
const CommandExecutor := preload("res://game/scripts/commands/command_executor.gd")
const OnboardingService := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")
const LogisticsService := preload("res://game/scripts/domain/factory/logistics_service.gd")
const GameService := preload("res://game/scripts/autoloads/game.gd")
const SaveManagerCore := preload("res://game/scripts/persistence/save_manager.gd")

var executor: RefCounted
var serial: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	executor = CommandExecutor.new(GameState.create_new(20260726, 1000, false), func(_state: RefCounted) -> bool: return true)
	_run_contract()
	if failures.is_empty():
		print("SLG_LOOP_TESTS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run_contract() -> void:
	_verify_legacy_save_migration()
	_verify_objective_event_guards()
	_verify_late_onboarding_objective_reconciliation()
	_verify_independent_facility_collection()
	_verify_factory_capacity_contract()
	_verify_skill_research_contract()
	_expect(executor.state.content_version == "toilet-factory-slg-v3-factions", "new saves use the faction-progression contract")
	_expect(executor.state.roster.size() == 1, "new game owns only permanent G-Man")
	var permanent_ids: Array[String] = executor.state.roster_ids()
	_expect(executor.state.formation.hero_ids() == permanent_ids, "new game deploys only its unlocked hero")

	var hero_id := String(permanent_ids[0])
	_expect_ok(_command("construct_facility", {
		"facility_id": "research_lab",
		"now_unix": 1000,
		"grid_x": 2,
		"grid_z": 1,
	}), "player starts by constructing the research lab")
	_expect_ok(_command("claim_facility_work", {"now_unix": 1005}), "opening research lab completes")
	_expect_task("operation.lone_vanguard", false, 1)
	var first_battle := _settle("stage_1_1", "victory", permanent_ids)
	_expect_ok(first_battle, "first town settles")
	_expect(executor.state.roster_ids() == permanent_ids, "battle never deletes heroes")
	_expect(int(executor.state.hero_by_id(hero_id).readiness) == 100, "battle leaves every permanent hero fully ready")
	_expect((first_battle["event"]["damage_manifest"] as Dictionary).is_empty(), "battle settlement has no persistent damage manifest")
	_expect(int(executor.state.economy.industrial_tech) == 0, "town victory does not recreate retired expansion technology")
	_expect(
		String((first_battle["event"]["onboarding_settlement"] as Dictionary).get("task_id", "")) == "operation.lone_vanguard",
		"first action reward settles inside the authoritative battle command"
	)
	_expect_task("operation.keep_advancing", false, 0)

	_expect_ok(_settle("stage_1_2", "victory", permanent_ids), "second town settles")
	_expect_task("operation.keep_advancing", false, 1)
	_expect_ok(_settle("stage_1_3", "victory", permanent_ids), "third town settles")
	_expect_task("operation.high_wall", false, 0)
	_expect_ok(_command("claim_starter_gift", {
		"gift_id": "new_game_supply_v1",
	}), "1-3 supply gift funds the next industrial choice")

	var high_wall_defeat := _settle("stage_1_4", "defeat", permanent_ids)
	_expect_ok(high_wall_defeat, "Gman first high-wall attempt settles as defeat")
	_expect_task("operation.research_reinforcements", false, 0)
	_expect(int(executor.state.factory.facilities["research_lab"]) == 1, "opening research lab remains available after the high-wall defeat")
	_expect_ok(_command("unlock_foundational_blueprint", {
		"recipe_id": "ordinary.assault", "now_unix": 1015,
	}), "research lab starts the assault design")
	var assault_research := _command("claim_blueprint_research", {"now_unix": 1060})
	_expect_ok(assault_research, "assault research creates the permanent hero")
	_expect_task("operation.research_reinforcements", false, 1)
	_expect_ok(_command("unlock_foundational_blueprint", {
		"recipe_id": "heavy.armored", "now_unix": 1060,
	}), "research lab starts the armored design")
	var armored_research := _command("claim_blueprint_research", {"now_unix": 1105})
	_expect_ok(armored_research, "armored research creates the permanent hero")
	_expect_task("operation.counterattack", false, 0)

	var assault_id := String((assault_research.get("event", {}) as Dictionary).get("hero_id", ""))
	var armored_id := String((armored_research.get("event", {}) as Dictionary).get("hero_id", ""))
	_expect_ok(_command("assign_formation_slot", {"slot": "troop_1", "hero_id": assault_id}), "assault toilet joins the formation")
	_expect_ok(_command("assign_formation_slot", {"slot": "troop_2", "hero_id": armored_id}), "armored toilet joins the formation")
	_expect(executor.state.formation.hero_ids().size() == 3, "Gman and both researched toilets form the counterattack squad")
	_expect_ok(_settle("stage_1_4", "victory", executor.state.formation.hero_ids()), "reinforced squad captures the high wall")
	_expect_task("operation.choose_growth", false, 0)
	var construct_support := _command("construct_facility", {
		"facility_id": "porcelain_plant",
		"now_unix": 1110,
		"grid_x": -2,
		"grid_z": 1,
	})
	_expect_ok(construct_support, "player chooses a real industrial support facility before the boss")
	_expect_ok(_command("claim_facility_work", {"now_unix": 1115}), "support facility completes its five-second commissioning run")
	_expect_task("operation.choose_growth", false, 1)
	_expect_ok(_command("claim_facility_output", {
		"facility_id": "porcelain_plant",
		"now_unix": 1115,
	}), "player collects the first real factory output")
	_expect_task("operation.choose_growth", false, 2)
	_expect_ok(_command("upgrade_hero_star", {"hero_id": armored_id}), "player chooses one visible combat growth before the boss")
	_expect_task("operation.chapter_boss", false, 0)

	_expect_ok(_settle("stage_1_5", "victory", executor.state.formation.hero_ids()), "chapter boss settles with breakthrough rewards")
	var snapshot := OnboardingService.snapshot(executor.state)
	_expect(bool(snapshot.get("finished", false)), "seven-operation first chapter guidance completes")
	var chapter_two_boss := _settle("stage_2_12", "victory", executor.state.formation.hero_ids())
	_expect_ok(chapter_two_boss, "second chapter boss settles")
	var chapter_two_blueprints := chapter_two_boss["event"]["unlocked_blueprints"] as Array
	_expect(chapter_two_blueprints.size() == 1 and String((chapter_two_blueprints[0] as Dictionary).get("recipe_id", "")) == "flying.bomber", "second chapter boss grants the bomber design blueprint")
	_expect(executor.state.roster.size() == 3, "campaign blueprint never bypasses research to create a hero")
	_expect_ok(_command("unlock_foundational_blueprint", {
		"recipe_id": "flying.bomber", "now_unix": 1200,
	}), "research lab starts the boss-earned bomber design")
	_expect_ok(_command("claim_blueprint_research", {"now_unix": 1245}), "research lab creates the permanent bomber")
	_expect(executor.state.roster.size() == 4 and executor.state.formation.hero_ids().size() == 3, "researched bomber joins the roster without silently changing formation")
	var chapter_three_boss := _settle("stage_3_12", "victory", executor.state.formation.hero_ids())
	_expect_ok(chapter_three_boss, "third chapter boss settles")
	var chapter_three_blueprints := chapter_three_boss["event"]["unlocked_blueprints"] as Array
	_expect(chapter_three_blueprints.size() == 1 and String((chapter_three_blueprints[0] as Dictionary).get("recipe_id", "")) == "heavy.saw", "third chapter boss grants the saw design blueprint")
	_expect(executor.state.roster.size() == 4, "later campaign blueprint also waits for research")
	_expect_ok(_command("unlock_foundational_blueprint", {
		"recipe_id": "heavy.saw", "now_unix": 1300,
	}), "research lab starts the boss-earned saw design")
	_expect_ok(_command("claim_blueprint_research", {"now_unix": 1345}), "research lab creates the permanent saw hero")
	_expect(executor.state.roster.size() == 5 and executor.state.formation.hero_ids().size() == 3, "researched campaign designs grow the permanent roster without silently changing formation")
	var unlocked_ids: Array[String] = executor.state.roster_ids()
	var unique_unlocked_ids: Dictionary = {}
	for unlocked_id in unlocked_ids:
		unique_unlocked_ids[unlocked_id] = true
	_expect(unique_unlocked_ids.size() == unlocked_ids.size(), "campaign unlock paths allocate unique stable hero ids")
	_expect(int(executor.state.factory.next_hero_sequence) > executor.state.roster.size(), "hero sequence advances beyond every allocated campaign hero")
	_expect_ok(_settle("stage_3_12", "victory", executor.state.formation.hero_ids()), "replaying the third boss is safe")
	_expect(executor.state.roster.size() == 5, "boss replay never duplicates permanent hero unlocks")


func _verify_late_onboarding_objective_reconciliation() -> void:
	var probe_state: RefCounted = GameState.create_new(20260727, 1000, false)
	probe_state.stage_progress["cleared_stages"] = [
		"stage_1_1", "stage_1_2", "stage_1_3", "stage_1_4",
	]
	probe_state.onboarding["active_index"] = 1
	var coins_before := int(probe_state.economy.toilet_coins)
	var late_stage_task := OnboardingService.snapshot(probe_state)
	_expect(bool(late_stage_task.get("completed", false)), "late stage task completes from durable cleared stages")
	_expect(int(late_stage_task.get("progress", 0)) == 2, "all already-cleared stage objectives reconcile")
	_expect(int(probe_state.economy.toilet_coins) == coins_before, "state reconciliation never grants task rewards before claim")

	var probe := CommandExecutor.new(probe_state, func(_state: RefCounted) -> bool: return true)
	var late_claim := probe.execute({
		"command_id": "late-onboarding-claim",
		"type": "claim_onboarding_task",
		"payload": {"task_id": "operation.keep_advancing"},
		"business_key": "late-onboarding-claim",
		"expected_revision": probe.state.revision,
		"requested_at": 1000,
	})
	_expect_ok(late_claim, "late-completed task reward can be claimed immediately")
	_expect(
		int(probe.state.economy.toilet_coins) == coins_before + 30,
		"late catch-up atomically settles the already-proven high-wall reward exactly once"
	)
	var replay := probe.execute({
		"command_id": "late-onboarding-claim-replay",
		"type": "claim_onboarding_task",
		"payload": {"task_id": "operation.keep_advancing"},
		"business_key": "late-onboarding-claim",
		"expected_revision": 0,
		"requested_at": 1000,
	})
	_expect_ok(replay, "late task reward claim replays idempotently")

	var passed_wall := OnboardingService.snapshot(probe.state)
	_expect(
		String(passed_wall.get("task_id", "")) == "operation.research_reinforcements",
		"catch-up skips completed bureaucracy and exposes the next unfinished action"
	)
	_expect(not bool(passed_wall.get("completed", true)), "research remains a real unfinished player action")

	probe.state.onboarding["active_index"] = 3
	probe.state.factory.blueprints["ordinary.assault"] = true
	probe.state.factory.blueprints["heavy.armored"] = true
	var late_research := OnboardingService.snapshot(probe.state)
	_expect(bool(late_research.get("completed", false)), "late research task completes from durable researched designs")
	_expect(int(late_research.get("progress", 0)) == 2, "both stage-earned research objectives reconcile")


func _verify_independent_facility_collection() -> void:
	var probe := CommandExecutor.new(GameState.create_new(77, 1000), func(_state: RefCounted) -> bool: return true)
	probe.state.factory.facility_output_anchors = {
		"porcelain_plant": 1000,
		"parts_workshop": 1000,
		"energy_station": 1000,
		"coin_mint": 1000,
	}
	var before := (probe.state.factory.materials as Dictionary).duplicate(true)
	var porcelain := probe.execute({
		"command_id": "facility-porcelain-1",
		"type": "claim_facility_output",
		"payload": {"facility_id": "porcelain_plant", "now_unix": 1600},
		"business_key": "facility-porcelain-1",
		"expected_revision": probe.state.revision,
		"requested_at": 1600,
	})
	_expect_ok(porcelain, "a resource building can be collected independently")
	_expect(int(probe.state.factory.materials["porcelain"]) > int(before["porcelain"]), "porcelain building grants only its stored material")
	_expect(int(probe.state.factory.materials["parts"]) == int(before["parts"]), "collecting porcelain does not reset or grant parts")
	var after_first_line := int(probe.state.factory.materials["porcelain"])
	var duplicate := probe.execute({
		"command_id": "facility-porcelain-2",
		"type": "claim_facility_output",
		"payload": {"facility_id": "porcelain_plant", "now_unix": 1600},
		"business_key": "facility-porcelain-2",
		"expected_revision": probe.state.revision,
		"requested_at": 1600,
	})
	_expect(not bool(duplicate.get("ok", false)), "an already collected building cannot grant the same elapsed production twice")
	var parts := probe.execute({
		"command_id": "facility-parts-1",
		"type": "claim_facility_output",
		"payload": {"facility_id": "parts_workshop", "now_unix": 1600},
		"business_key": "facility-parts-1",
		"expected_revision": probe.state.revision,
		"requested_at": 1600,
	})
	_expect_ok(parts, "another building keeps its own unclaimed production window")
	_expect(int(probe.state.factory.materials["porcelain"]) > after_first_line, "second production line grants industrial material after the first was collected")


func _verify_factory_capacity_contract() -> void:
	var probe := CommandExecutor.new(GameState.create_new(88, 1000), func(_state: RefCounted) -> bool: return true)
	var initial_capacity := int(probe.state.factory.capacities["porcelain"])
	probe.state.factory.materials["porcelain"] = initial_capacity - 1
	probe.state.factory.facility_output_anchors["porcelain_plant"] = 1000
	var result := probe.execute({
		"command_id": "capacity-claim",
		"type": "claim_facility_output",
		"payload": {"facility_id": "porcelain_plant", "now_unix": 1600},
		"business_key": "capacity-claim",
		"expected_revision": probe.state.revision,
		"requested_at": 1600,
	})
	_expect_ok(result, "factory output can be collected near capacity")
	_expect(int(probe.state.factory.materials["porcelain"]) == initial_capacity, "collection clamps inventory to capacity")
	_expect(int(result["event"]["materials"]["porcelain"]) == 1, "claim event reports only accepted inventory")
	_expect(int(result["event"]["overflow"]["porcelain"]) > 0, "claim event reports production lost to overflow")
	probe.state.economy.toilet_coins = 9999
	var upgrade := probe.execute({
		"command_id": "capacity-upgrade",
		"type": "upgrade_facility",
		"payload": {"facility_id": "porcelain_plant", "now_unix": 1601},
		"business_key": "capacity-upgrade",
		"expected_revision": probe.state.revision,
		"requested_at": 1601,
	})
	_expect_ok(upgrade, "resource facility upgrade starts in capacity probe")
	var upgrade_claim := probe.execute({
		"command_id": "capacity-upgrade-claim",
		"type": "claim_facility_work",
		"payload": {"now_unix": 1661},
		"business_key": "capacity-upgrade-claim",
		"expected_revision": probe.state.revision,
		"requested_at": 1661,
	})
	_expect_ok(upgrade_claim, "resource facility upgrade completes after its timer")
	_expect(int(probe.state.factory.capacities["porcelain"]) > initial_capacity, "resource facility upgrade expands matching capacity")
	var encoded := preload("res://game/scripts/persistence/save_codec.gd").encode(probe.state)
	var decoded := preload("res://game/scripts/persistence/save_codec.gd").decode(encoded)
	_expect_ok(decoded, "capacity state survives strict save decode")
	if bool(decoded.get("ok", false)):
		_expect(int(decoded["state"].factory.capacities["porcelain"]) == int(probe.state.factory.capacities["porcelain"]), "capacity survives save round-trip")


func _verify_skill_research_contract() -> void:
	var probe := CommandExecutor.new(GameState.create_new(89, 1000), func(_state: RefCounted) -> bool: return true)
	var hero_id := String(probe.state.roster[0].hero_id)
	probe.state.economy.hero_shards = 20
	probe.state.economy.toilet_coins = 999
	var quote := LogisticsService.active_skill_research_quote(probe.state, hero_id)
	_expect_ok(quote, "active-skill quote recognizes an affordable level-two research")
	_expect(
		quote.get("cost", {}) == {
			"toilet_coins": 80,
			"hero_shards": 4,
		},
		"active-skill quote exposes the coin-and-legion-data cost used by the transaction"
	)
	var level_two := probe.execute({
		"command_id": "skill-research-2",
		"type": "research_active_skill",
		"payload": {"hero_id": hero_id},
		"business_key": "skill-research-2",
		"expected_revision": probe.state.revision,
		"requested_at": 1700,
	})
	_expect_ok(level_two, "research lab upgrades a permanent hero active skill")
	_expect(int(probe.state.hero_by_id(hero_id).active_skill_level) == 2, "first research reaches active skill level two")
	var gated := probe.execute({
		"command_id": "skill-research-gated",
		"type": "research_active_skill",
		"payload": {"hero_id": hero_id},
		"business_key": "skill-research-gated",
		"expected_revision": probe.state.revision,
		"requested_at": 1701,
	})
	_expect(not bool(gated.get("ok", false)) and String(gated.get("error", "")).contains("RESEARCH_LAB_LEVEL_TOO_LOW"), "skill level three requires a level-two research lab")
	probe.state.factory.facilities["research_lab"] = 2
	var level_three := probe.execute({
		"command_id": "skill-research-3",
		"type": "research_active_skill",
		"payload": {"hero_id": hero_id},
		"business_key": "skill-research-3",
		"expected_revision": probe.state.revision,
		"requested_at": 1702,
	})
	_expect_ok(level_three, "upgraded research lab unlocks active skill level three")
	_expect(int(probe.state.hero_by_id(hero_id).active_skill_level) == 3, "active skill research stops at level three")
	var encoded := preload("res://game/scripts/persistence/save_codec.gd").encode(probe.state)
	var decoded := preload("res://game/scripts/persistence/save_codec.gd").decode(encoded)
	_expect_ok(decoded, "active skill research survives strict save decode")
	if bool(decoded.get("ok", false)):
		_expect(int(decoded["state"].hero_by_id(hero_id).active_skill_level) == 3, "active skill level survives save round-trip")


func _verify_objective_event_guards() -> void:
	var probe: RefCounted = GameState.create_new(99, 1000, false)
	OnboardingService.apply_event(probe, {
		"type": "battle_settled",
		"battle_id": "future-boss",
		"stage_id": "stage_1_5",
		"outcome": "victory",
	})
	var untouched := OnboardingService.snapshot(probe)
	_expect(int(untouched.get("progress", -1)) == 0, "future operation events cannot skip the active operation")
	OnboardingService.apply_event(probe, {
		"type": "facility_constructed",
		"facility_id": "research_lab",
		"request_id": "opening-research-lab",
	})
	var opening_settlement := OnboardingService.apply_event(probe, {
		"type": "battle_settled",
		"battle_id": "opening-win",
		"stage_id": "stage_1_1",
		"outcome": "victory",
	})
	_expect(
		String(opening_settlement.get("task_id", "")) == "operation.lone_vanguard",
		"the opening attack completes and settles the first operation"
	)
	var advanced := OnboardingService.snapshot(probe)
	_expect(String(advanced.get("task_id", "")) == "operation.keep_advancing", "auto-settlement immediately exposes the next real action")
	OnboardingService.apply_event(probe, {
		"type": "battle_settled",
		"battle_id": "opening-win",
		"stage_id": "stage_1_1",
		"outcome": "victory",
	})
	_expect(int(OnboardingService.snapshot(probe).get("progress", -1)) == 0, "duplicate prior-task events cannot advance the next objective")
	probe.onboarding["active_index"] = 5
	probe.factory.facilities["porcelain_plant"] = 1
	OnboardingService.apply_event(probe, {
		"type": "facility_constructed",
		"facility_id": "porcelain_plant",
		"request_id": "support-built",
	})
	OnboardingService.apply_event(probe, {
		"type": "factory_output_claimed",
		"facility_id": "porcelain_plant",
		"request_id": "support-collected",
	})
	OnboardingService.apply_event(probe, {
		"type": "hero_star_upgraded",
		"hero_id": "gman-probe",
		"archetype_id": "gman",
		"star": 2,
	})
	_expect(
		int(OnboardingService.snapshot(probe).get("progress", -1)) == 2,
		"Gman star-up cannot satisfy the verified reinforcement choice after industrial setup"
	)
	var growth_settlement := OnboardingService.apply_event(probe, {
		"type": "hero_star_upgraded",
		"hero_id": "assault-probe",
		"archetype_id": "assault",
		"star": 2,
	})
	_expect(
		String(growth_settlement.get("task_id", "")) == "operation.choose_growth",
		"assault star-up satisfies and settles the verified growth choice"
	)


func _verify_legacy_save_migration() -> void:
	var manager := SaveManagerCore.new("user://slg_migration_contract_test.json")
	manager.delete_local_save()
	var legacy: RefCounted = GameState.create_new(1, 100)
	legacy.content_version = "toilet-factory-siege-v6"
	while legacy.roster.size() > 1:
		legacy.roster.remove_at(legacy.roster.size() - 1)
	legacy.formation = preload("res://game/scripts/state/formation_state.gd").from_heroes(legacy.roster_ids())
	_expect(manager.save_state(legacy), "legacy fixture can be persisted")
	var service := GameService.new()
	var status := service.bootstrap_with_manager(manager, 20260726, 200)
	_expect(status == "created", "legacy contract is replaced before entering UI")
	_expect(service.current_state().content_version == "toilet-factory-slg-v3-factions", "migration creates active faction content version")
	_expect(service.current_state().roster.size() == 1, "replaced legacy contract starts with only permanent G-Man")
	manager.delete_local_save()
	service.free()


func _settle(stage_id: String, outcome: String, deployed: Array[String]) -> Dictionary:
	return _command("settle_battle", {
		"battle_id": "test-%s-%d" % [stage_id, serial],
		"stage_id": stage_id,
		"outcome": outcome,
		"ticks": 30,
		"deployed_unit_ids": deployed,
		"dead_unit_ids": [],
	})


func _expect_task(task_id: String, completed: bool, progress: int) -> void:
	var snapshot := OnboardingService.snapshot(executor.state)
	_expect(String(snapshot.get("task_id", "")) == task_id, "active task is %s" % task_id)
	_expect(bool(snapshot.get("completed", false)) == completed, "%s completion state is correct" % task_id)
	_expect(int(snapshot.get("progress", -1)) == progress, "%s objective progress is %d" % [task_id, progress])


func _command(type: String, payload: Dictionary) -> Dictionary:
	serial += 1
	return executor.execute({
		"command_id": "test-command-%d" % serial,
		"type": type,
		"payload": payload,
		"business_key": "test-business-%d" % serial,
		"expected_revision": executor.state.revision,
		"requested_at": 1000 + serial,
	})


func _expect_ok(result: Dictionary, message: String) -> void:
	_expect(bool(result.get("ok", false)), "%s: %s" % [message, result.get("error", "")])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

extends SceneTree

const GameState := preload("res://game/scripts/state/game_state.gd")
const CommandExecutor := preload("res://game/scripts/commands/command_executor.gd")
const OnboardingService := preload("res://game/scripts/domain/onboarding/onboarding_service.gd")
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
	_expect(executor.state.content_version == "toilet-factory-slg-v2", "new saves use revised first-session contract")
	_expect(executor.state.roster.size() == 1, "new game owns only permanent G-Man")
	var permanent_ids: Array[String] = executor.state.roster_ids()
	_expect(executor.state.formation.hero_ids() == permanent_ids, "new game deploys only its unlocked hero")

	var hero_id := String(permanent_ids[0])
	var first_battle := _settle("stage_1_1", "victory", permanent_ids)
	_expect_ok(first_battle, "first town settles")
	_expect(executor.state.roster_ids() == permanent_ids, "battle never deletes heroes")
	_expect(int(executor.state.hero_by_id(hero_id).readiness) == 100, "battle leaves every permanent hero fully ready")
	_expect((first_battle["event"]["damage_manifest"] as Dictionary).is_empty(), "battle settlement has no persistent damage manifest")
	_expect(int(executor.state.economy.industrial_tech) >= 4, "town victory grants expansion technology")
	_expect_task("operation.lone_vanguard", true, 1)
	_claim_current_task()

	_expect_ok(_settle("stage_1_2", "victory", permanent_ids), "second town settles")
	_expect_task("operation.keep_advancing", false, 1)
	_expect_ok(_settle("stage_1_3", "victory", permanent_ids), "third town settles")
	_expect_task("operation.keep_advancing", true, 2)
	_claim_current_task()

	var high_wall_defeat := _settle("stage_1_4", "defeat", permanent_ids)
	_expect_ok(high_wall_defeat, "Gman first high-wall attempt settles as defeat")
	_expect_task("operation.high_wall", true, 1)
	_expect(int(executor.state.factory.facilities["research_lab"]) == 0, "high-wall defeat does not auto-build the research lab")
	_expect(bool(executor.state.factory.eligible_facilities.get("research_lab", false)), "high-wall defeat grants research-lab eligibility")
	_claim_current_task()

	var construct_lab := _command("construct_facility", {
		"facility_id": "research_lab",
		"now_unix": 1010,
		"grid_x": 2,
		"grid_z": 1,
	})
	_expect_ok(construct_lab, "player actively constructs the eligible research lab")
	_expect(int(executor.state.factory.facilities["research_lab"]) == 0, "research lab remains inactive while construction runs")
	_expect_ok(_command("claim_facility_work", {"now_unix": 1085}), "player accepts the completed research lab")
	_expect(int(executor.state.factory.facilities["research_lab"]) == 1, "research lab becomes built only after timed construction")
	var breakthrough := _command("claim_research_breakthrough", {})
	_expect_ok(breakthrough, "research breakthrough ten-pull grants both foundational heroes")
	_expect(int(((breakthrough.get("event", {}) as Dictionary).get("results", []) as Array).size()) == 10, "research breakthrough reveals ten results")
	_expect_task("operation.research_reinforcements", true, 1)
	_claim_current_task()

	var assault_id := ""
	var armored_id := ""
	for item_value in (breakthrough.get("event", {}) as Dictionary).get("results", []):
		var item := item_value as Dictionary
		if String(item.get("archetype_id", "")) == "assault":
			assault_id = String(item.get("hero_id", ""))
		elif String(item.get("archetype_id", "")) == "armored":
			armored_id = String(item.get("hero_id", ""))
	_expect_ok(_command("assign_formation_slot", {"slot": "troop_1", "hero_id": assault_id}), "assault toilet joins the formation")
	_expect_ok(_command("assign_formation_slot", {"slot": "troop_2", "hero_id": armored_id}), "armored toilet joins the formation")
	_expect(executor.state.formation.hero_ids().size() == 3, "Gman and both researched toilets form the counterattack squad")
	_expect_ok(_settle("stage_1_4", "victory", executor.state.formation.hero_ids()), "reinforced squad captures the high wall")
	_expect_task("operation.counterattack", true, 1)
	_claim_current_task()

	_expect_task("operation.choose_growth", false, 0)
	_expect_ok(_command("upgrade_hero_star", {"hero_id": armored_id}), "player chooses one visible combat growth before the boss")
	_expect_task("operation.choose_growth", true, 1)
	_claim_current_task()

	_expect_ok(_settle("stage_1_5", "victory", executor.state.formation.hero_ids()), "chapter boss settles with breakthrough rewards")
	_expect_task("operation.chapter_boss", true, 1)
	_claim_current_task()
	var snapshot := OnboardingService.snapshot(executor.state)
	_expect(bool(snapshot.get("finished", false)), "seven-operation first chapter guidance completes")
	var chapter_two_boss := _settle("stage_2_5", "victory", executor.state.formation.hero_ids())
	_expect_ok(chapter_two_boss, "second chapter boss settles")
	_expect(String((chapter_two_boss["event"]["unlocked_hero"] as Dictionary).get("archetype_id", "")) == "bomber", "second chapter unlocks the permanent bomber")
	_expect(executor.state.roster.size() == 4 and executor.state.formation.hero_ids().size() == 4, "first campaign unlock joins roster and empty formation slot")
	var chapter_three_boss := _settle("stage_3_5", "victory", executor.state.formation.hero_ids())
	_expect_ok(chapter_three_boss, "third chapter boss settles")
	_expect(String((chapter_three_boss["event"]["unlocked_hero"] as Dictionary).get("archetype_id", "")) == "saw", "third chapter unlocks the permanent saw hero")
	_expect(executor.state.roster.size() == 5 and executor.state.formation.hero_ids().size() == 5, "campaign grows the legion through later hero unlocks")
	var unlocked_ids: Array[String] = executor.state.roster_ids()
	var unique_unlocked_ids: Dictionary = {}
	for unlocked_id in unlocked_ids:
		unique_unlocked_ids[unlocked_id] = true
	_expect(unique_unlocked_ids.size() == unlocked_ids.size(), "campaign unlock paths allocate unique stable hero ids")
	_expect(int(executor.state.factory.next_hero_sequence) > executor.state.roster.size(), "hero sequence advances beyond every allocated campaign hero")
	_expect_ok(_settle("stage_3_5", "victory", executor.state.formation.hero_ids()), "replaying the third boss is safe")
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
	_expect(int(probe.state.economy.toilet_coins) == coins_before, "material-only late task keeps unrelated coin balance")
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
	_expect(String(passed_wall.get("task_id", "")) == "operation.high_wall", "claim advances to high-wall task")
	_expect(bool(passed_wall.get("completed", false)), "a durable stage clear satisfies an earlier defeat tutorial objective")

	probe.state.onboarding["active_index"] = 3
	(probe.state.onboarding["claimed"] as Dictionary)["reward.research_breakthrough_ten"] = true
	var late_research := OnboardingService.snapshot(probe.state)
	_expect(bool(late_research.get("completed", false)), "late research task completes from durable breakthrough receipt")
	_expect(int(late_research.get("progress", 0)) == 1, "durable breakthrough objective reconciles")


func _verify_independent_facility_collection() -> void:
	var probe := CommandExecutor.new(GameState.create_new(77, 1000), func(_state: RefCounted) -> bool: return true)
	probe.state.factory.facility_output_anchors = {
		"porcelain_plant": 1000,
		"parts_workshop": 1000,
		"energy_station": 1000,
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
	_expect(int(probe.state.factory.materials["parts"]) > int(before["parts"]), "parts workshop grants its stored parts after porcelain was collected")


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
	probe.state.economy.industrial_tech = 999
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
	probe.state.economy.industrial_tech = 99
	probe.state.economy.skill_chips = 9
	probe.state.economy.toilet_coins = 999
	probe.state.factory.materials = {"porcelain": 999, "parts": 999, "sludge": 999}
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
	var probe: RefCounted = GameState.create_new(99, 1000)
	OnboardingService.apply_event(probe, {
		"type": "battle_settled",
		"battle_id": "future-boss",
		"stage_id": "stage_1_5",
		"outcome": "victory",
	})
	var untouched := OnboardingService.snapshot(probe)
	_expect(int(untouched.get("progress", -1)) == 0, "future operation events cannot skip the active operation")
	OnboardingService.apply_event(probe, {
		"type": "battle_settled",
		"battle_id": "opening-win",
		"stage_id": "stage_1_1",
		"outcome": "victory",
	})
	var completed := OnboardingService.snapshot(probe)
	_expect(bool(completed.get("completed", false)), "the opening attack completes the first operation")
	OnboardingService.apply_event(probe, {
		"type": "battle_settled",
		"battle_id": "opening-win",
		"stage_id": "stage_1_1",
		"outcome": "victory",
	})
	_expect(int(OnboardingService.snapshot(probe).get("progress", -1)) == 1, "duplicate events cannot overcount objectives")
	probe.onboarding["active_index"] = 5
	OnboardingService.apply_event(probe, {
		"type": "hero_star_upgraded",
		"hero_id": "gman-probe",
		"archetype_id": "gman",
		"star": 2,
	})
	_expect(int(OnboardingService.snapshot(probe).get("progress", -1)) == 0, "Gman star-up cannot satisfy the two verified reinforcement routes")
	OnboardingService.apply_event(probe, {
		"type": "hero_star_upgraded",
		"hero_id": "assault-probe",
		"archetype_id": "assault",
		"star": 2,
	})
	_expect(bool(OnboardingService.snapshot(probe).get("completed", false)), "assault star-up satisfies the verified growth choice")


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
	_expect(service.current_state().content_version == "toilet-factory-slg-v2", "migration creates active content version")
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


func _claim_current_task() -> void:
	var snapshot := OnboardingService.snapshot(executor.state)
	_expect_ok(_command("claim_onboarding_task", {"task_id": String(snapshot.get("task_id", ""))}), "completed task reward claims")


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

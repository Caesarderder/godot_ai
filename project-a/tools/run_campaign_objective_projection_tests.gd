extends SceneTree

const CampaignObjectiveProjectionScript := preload(
	"res://game/scripts/domain/objectives/campaign_objective_projection.gd"
)
const GameStateScript := preload("res://game/scripts/state/game_state.gd")
const CommandExecutorScript := preload("res://game/scripts/commands/command_executor.gd")
const HeroGeneratorScript := preload("res://game/scripts/domain/recruitment/hero_generator.gd")
const ResearchBreakthroughServiceScript := preload(
	"res://game/scripts/domain/recruitment/research_breakthrough_service.gd"
)

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_first_chapter_projection()
	_test_faction_journey_projection()
	_test_second_chapter_growth_projection()
	_test_second_chapter_reconnaissance_projection()
	if failures.is_empty():
		print("CAMPAIGN_OBJECTIVE_PROJECTION_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("CAMPAIGN_OBJECTIVE_PROJECTION_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _test_first_chapter_projection() -> void:
	var state: RefCounted = GameStateScript.create_new(20260727, 1000, false)
	var onboarding := {
		"finished": false,
		"task_id": "operation.first_siege",
		"title": "行动一：摧毁第一座城",
		"cta_label": "进攻 1-1",
		"target": "expedition",
		"stage_id": "stage_1_1",
		"objectives": [{
			"id": "clear_first_city",
			"label": "完成 1-1 首次攻城",
			"completed": false,
		}],
	}
	var projection := CampaignObjectiveProjectionScript.derive(state, onboarding)
	var title := projection.get("title", {}) as Dictionary
	var hierarchy := projection.get("hierarchy", {}) as Dictionary
	_check(String(title.get("primary_label", "")).contains("进入 E07"), "new save title exposes the first canon-anchored action")
	_check(String(title.get("objective", "")).contains("摧毁联盟前哨 1-1"), "new save title names the first concrete battle objective")
	_check(String(hierarchy.get("macro", "")).contains("摧毁 E11 联盟核心巨炮"), "first chapter retains one macro goal")
	_check(String(hierarchy.get("small", "")).contains("完成 1-1"), "first chapter retains the current executable objective")
	_check((projection.get("factory_task", {}) as Dictionary) == onboarding, "unfinished onboarding remains the factory task source")


func _test_second_chapter_growth_projection() -> void:
	var state := _chapter_two_state()
	var projection := CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	var title := projection.get("title", {}) as Dictionary
	var hierarchy := projection.get("hierarchy", {}) as Dictionary
	var task := projection.get("factory_task", {}) as Dictionary
	_check(bool(projection.get("chapter_one_complete", false)), "projection recognizes chapter one independently from the full 25-stage catalog")
	_check(bool(projection.get("needs_growth", false)), "underpowered chapter-two formation produces a growth state")
	_check(int(projection.get("challenge_gap", 0)) > 0, "growth state quantifies the canonical challenge-line gap")
	_check(String(title.get("objective", "")).contains("第二章备战"), "title resumes the same chapter-two goal")
	_check(String(hierarchy.get("cta_label", "")) == "先培养军团", "goal center routes the growth state to the legion")
	_check(String(task.get("cta_label", "")) == "先培养军团", "factory task uses the same semantic action")
	_check(String(hierarchy.get("small", "")) == String((task.get("objectives", []) as Array)[0]["label"]), "goal center and factory share the exact small goal")


func _test_faction_journey_projection() -> void:
	var state := _chapter_two_state()
	var claimed := state.onboarding.get("claimed", {}) as Dictionary
	claimed.erase(ResearchBreakthroughServiceScript.FACTION_CLAIM_KEY)
	state.onboarding["claimed"] = claimed
	state.meta_progression.commander_xp = 450
	var executor := CommandExecutorScript.new(
		state,
		func(_state: RefCounted) -> bool: return true
	)
	var claim := executor.execute({
		"type": "claim_faction_signal",
		"command_id": "objective-faction-claim",
		"business_key": "objective-faction-claim",
		"expected_revision": state.revision,
		"payload": {},
	})
	_check(bool(claim.get("ok", false)), "faction objective fixture receives the durable free ten")
	if not bool(claim.get("ok", false)):
		return
	state = executor.state
	var core_candidates := (
		(claim.get("event", {}) as Dictionary).get("faction_core_candidates", [])
		as Array
	)
	_check(core_candidates.size() == 2, "objective fixture exposes two durable core candidates")
	var projection := CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	var hierarchy := projection.get("hierarchy", {}) as Dictionary
	_check(
		String(hierarchy.get("cta_label", "")).contains("选择我的阵营核心")
			and String(hierarchy.get("target", "")) == "recruit",
		"post-ten objective waits for the player's faction decision"
	)
	state.economy.recruit_tickets = 1
	var later_recruit := executor.execute({
		"type": "signal_recruit",
		"command_id": "objective-later-standard-recruit",
		"business_key": "objective-later-standard-recruit",
		"expected_revision": state.revision,
		"payload": {"count": 1, "target_archetype": "parasite"},
	})
	_check(bool(later_recruit.get("ok", false)), "later standard recruit fixture succeeds")
	state = executor.state
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(
		String(hierarchy.get("cta_label", "")).contains("选择我的阵营核心"),
		"later standard recruitment cannot erase the pending faction choice"
	)
	var archetype_id := String(core_candidates[1]) if core_candidates.size() == 2 else ""
	var choose_core := executor.execute({
		"type": "choose_faction_core",
		"command_id": "objective-faction-core",
		"business_key": "objective-faction-core",
		"expected_revision": state.revision,
		"payload": {"archetype_id": archetype_id},
	})
	_check(bool(choose_core.get("ok", false)), "objective fixture durably selects the second candidate")
	state = executor.state
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	var task := projection.get("factory_task", {}) as Dictionary
	_check(String(hierarchy.get("target", "")) == "blueprints", "post-ten goal opens the selected core's exact blueprint branch")
	_check(String(hierarchy.get("medium", "")).contains(archetype_id) == false, "player-facing faction goal uses names rather than internal archetype ids")
	_check(String(hierarchy.get("small", "")).contains("研发为永久角色"), "research step explains that a blueprint is not yet a hero")
	_check(String(task.get("small", "")) == "", "factory task stays a compact action projection")
	_check(
		String((task.get("objectives", []) as Array)[0]["label"])
			== String(hierarchy.get("small", "")),
		"base and goal center share the exact faction research objective"
	)

	var hero: RefCounted = HeroGeneratorScript.generate_archetype(
		20260728,
		9,
		archetype_id,
		"fighter"
	)
	state.roster.append(hero)
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(hierarchy.get("target", "")) == "formation", "researched faction core routes to formation")
	_check(String(hierarchy.get("hero_id", "")) == String(hero.hero_id), "formation step keeps the exact faction hero identity")

	state.formation.slots["troop_3"] = hero.hero_id
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(hierarchy.get("target", "")) == "map", "deployed one-star core routes to its battlefield proof")
	_check(String(hierarchy.get("milestone", "")).contains("阵营初阵已成"), "first battlefield proof celebrates formation completion")
	_check(String(hierarchy.get("small", "")).contains("已完成 0/3"), "one-star route exposes an observable three-battle target")
	_check(String(hierarchy.get("small", "")).contains("第1场磨合"), "one-star route turns the counter into the next concrete attempt")
	_check(String(hierarchy.get("proof_focus", "")).contains("首战观察"), "one-star proof explains what the player should learn in battle")
	_check(String(hierarchy.get("cta_label", "")).contains("开始第1场出击"), "one-star route exposes one explicit first-battle action")

	(state.stage_progress["cleared_stages"] as Array).append("stage_2_1")
	state.stage_progress["highest_unlocked_stage"] = "stage_2_2"
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(hierarchy.get("proof_focus", "")).contains("第2场观察"), "second proof advances from role recognition to skill timing")
	_check(String(hierarchy.get("proof_focus", "")).contains("共振加快"), "second proof names its stronger resonance pressure")

	(state.stage_progress["cleared_stages"] as Array).append("stage_2_2")
	state.stage_progress["highest_unlocked_stage"] = "stage_2_3"
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(hierarchy.get("proof_focus", "")).contains("第3场观察"), "third proof advances to sustained execution")
	_check(String(hierarchy.get("proof_focus", "")).contains("广播增援"), "third proof names the added reinforcement pressure")

	(state.stage_progress["cleared_stages"] as Array).append("stage_2_3")
	state.stage_progress["highest_unlocked_stage"] = "stage_2_4"
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(projection.get("faction_phase", "")) == "probe_late_wall", "projection exposes the durable pressure-test phase to reconnaissance UI")
	_check(String(hierarchy.get("target", "")) == "map", "three battlefield proofs first route to a lossless late-line probe")
	_check(String(hierarchy.get("stage_id", "")) == "stage_2_4", "late-line probe focuses the exact 2-4 pressure test")
	_check(String(hierarchy.get("small", "")).contains("保持1★"), "probe preserves one-star state so growth has an experienced cause")
	state.stage_progress["cleared_stages"].append("stage_2_4")
	state.attempt_counters["stage_2_4"] = 1
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(hierarchy.get("target", "")) == "map", "a one-star 2-4 victory continues to the actual 2-5 pressure wall")
	_check(String(hierarchy.get("stage_id", "")) == "stage_2_5", "winning the first probe focuses the chapter boss without premature growth")
	state.stage_progress["cleared_stages"].erase("stage_2_4")
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(hierarchy.get("target", "")) == "legion", "a failed 2-4 probe unlocks the selected core's star growth")
	_check(String(hierarchy.get("hero_id", "")) == String(hero.hero_id), "star step preserves the exact hero for roster focus")
	_check(String(hierarchy.get("small", "")).contains("专属碎片"), "star step explains the duplicate-to-specific-character causality")

	hero.star = 2
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(hierarchy.get("target", "")) == "legion", "two-star transformation first routes to the affordable level-two preparation")
	_check(String(hierarchy.get("small", "")).contains("升至2级"), "level-two phase explains the first post-star power step")
	hero.level = 2
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(projection.get("faction_phase", "")) == "breakthrough_gate", "projection exposes the two-star growth-validation phase")
	_check(String(hierarchy.get("target", "")) == "map", "two-star level-two core routes back to the exact 2-4 validation")
	_check(String(hierarchy.get("stage_id", "")) == "stage_2_4", "level-two validation does not skip the encountered gate")

	state.stage_progress["cleared_stages"].append("stage_2_4")
	state.stage_progress["highest_unlocked_stage"] = "stage_2_5"
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(hierarchy.get("target", "")) == "legion", "2-4 victory routes to the exact level-three boss preparation")
	_check(String(hierarchy.get("small", "")).contains("升至3级"), "level-three phase explains how 2-4 battle rewards fund the boss step")
	hero.level = 3
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(String(projection.get("faction_phase", "")) == "breakthrough", "projection exposes the chapter-boss validation phase")
	_check(String(hierarchy.get("target", "")) == "map", "two-star level-three core routes to final chapter-two validation")
	_check(String(hierarchy.get("small", "")).contains("击毁2-5核心"), "final faction step names the chapter boss proof")

	state.stage_progress["cleared_stages"].append("stage_2_5")
	state.stage_progress["highest_unlocked_stage"] = "stage_3_1"
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(not String(hierarchy.get("medium", "")).contains("阵营核心"), "completed second chapter releases the player into the next campaign goal")
	_check(String(hierarchy.get("macro", "")).contains("电视控制链"), "third chapter replaces the resolved second-chapter promise with a new macro threat")
	_check(String(hierarchy.get("medium", "")).contains("第三章"), "third-chapter objective identifies the current chapter instead of repeating chapter two")
	_check(String((hierarchy.get("hurdle", {}) as Dictionary).get("reason", "")).contains("控制关键成员"), "third-chapter hurdle explains the new point-kill pressure")
	state.stage_progress["cleared_stages"] = (
		state.stage_progress.get("cleared_stages", []) as Array
	) + ["stage_3_1", "stage_3_2", "stage_3_3", "stage_3_4", "stage_3_5"]
	state.stage_progress["highest_unlocked_stage"] = "stage_4_1"
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	var title := projection.get("title", {}) as Dictionary
	task = projection.get("factory_task", {}) as Dictionary
	_check(
		String(hierarchy.get("target", "")) == "blueprints"
			and String(hierarchy.get("cta_label", "")).contains("二阶科技"),
		"refreshing after 3-5 restores doctrine selection instead of skipping to chapter four"
	)
	_check(
		String(title.get("objective", "")).contains("二阶科技")
			and String(task.get("target", "")) == "blueprints",
		"title, base, and goals share the same pending doctrine decision"
	)
	var doctrine := executor.execute({
		"type": "choose_faction_doctrine",
		"command_id": "objective-tier-two-doctrine",
		"business_key": "objective-tier-two-doctrine",
		"expected_revision": state.revision,
		"payload": {"doctrine_id": "specialization"},
	})
	_check(bool(doctrine.get("ok", false)), "objective fixture durably chooses one second-tier doctrine")
	state = executor.state
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(
		String(hierarchy.get("target", "")) != "blueprints"
			and String(hierarchy.get("medium", "")).contains("第四章"),
		"chosen doctrine releases the unified objective into chapter-four preparation"
	)


func _test_second_chapter_reconnaissance_projection() -> void:
	var state := _chapter_two_state()
	var hero: RefCounted = state.roster[0]
	hero.base_stats = {"hp": 1200, "attack": 1200, "defense": 1200, "speed_milli": 120000, "crit_bp": 1200}
	hero.star = 5
	var projection := CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	var title := projection.get("title", {}) as Dictionary
	var hierarchy := projection.get("hierarchy", {}) as Dictionary
	var task := projection.get("factory_task", {}) as Dictionary
	_check(not bool(projection.get("needs_growth", true)), "formation above the challenge line advances beyond generic growth")
	_check(String(hierarchy.get("target", "")) == "map", "ready state routes to reconnaissance rather than starting battle")
	_check(String(task.get("target", "")) == "map", "factory and goal center preserve the same reconnaissance target")
	_check(String(hierarchy.get("cta_label", "")).contains("侦察 2-1"), "ready state names the exact next stage")
	_check(String(title.get("objective", "")).contains("下一行动"), "returning title advances from the resolved power gap to the next action")


func _chapter_two_state() -> RefCounted:
	var state: RefCounted = GameStateScript.create_new(20260727, 1000, false)
	state.stage_progress["cleared_stages"] = [
		"stage_1_1",
		"stage_1_2",
		"stage_1_3",
		"stage_1_4",
		"stage_1_5",
	]
	state.stage_progress["highest_unlocked_stage"] = "stage_2_1"
	var claimed := state.onboarding.get("claimed", {}) as Dictionary
	claimed[ResearchBreakthroughServiceScript.FACTION_CLAIM_KEY] = true
	state.onboarding["claimed"] = claimed
	return state


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

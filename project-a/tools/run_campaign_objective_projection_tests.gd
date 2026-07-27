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
	_check(String(title.get("primary_label", "")).contains("启动反攻"), "new save title exposes the first executable promise")
	_check(String(title.get("objective", "")).contains("摧毁联盟前哨 1-1"), "new save title names the first concrete battle objective")
	_check(String(hierarchy.get("macro", "")).contains("摧毁灰镜核心"), "first chapter retains one macro goal")
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
	var archetype_id := String(
		(claim.get("event", {}) as Dictionary).get("guaranteed_duplicate_archetype", "")
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
	var projection := CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	var hierarchy := projection.get("hierarchy", {}) as Dictionary
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
	_check(String(hierarchy.get("small", "")).contains("实战证明 0/3"), "one-star proof exposes an observable three-battle target")

	state.stage_progress["cleared_stages"] = (
		state.stage_progress.get("cleared_stages", []) as Array
	) + ["stage_2_1", "stage_2_2", "stage_2_3"]
	state.stage_progress["highest_unlocked_stage"] = "stage_2_4"
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
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
	_check(String(hierarchy.get("target", "")) == "map", "two-star transformation routes back to battle validation")
	_check(String(hierarchy.get("small", "")).contains("击毁2-5核心"), "final faction step names the chapter boss proof")

	state.stage_progress["cleared_stages"].append("stage_2_4")
	state.stage_progress["cleared_stages"].append("stage_2_5")
	state.stage_progress["highest_unlocked_stage"] = "stage_3_1"
	projection = CampaignObjectiveProjectionScript.derive(state, {"finished": true})
	hierarchy = projection.get("hierarchy", {}) as Dictionary
	_check(not String(hierarchy.get("medium", "")).contains("阵营核心"), "completed second chapter releases the player into the next campaign goal")
	_check(String(hierarchy.get("macro", "")).contains("电视控制链"), "third chapter replaces the resolved second-chapter promise with a new macro threat")
	_check(String(hierarchy.get("medium", "")).contains("第三章"), "third-chapter objective identifies the current chapter instead of repeating chapter two")
	_check(String((hierarchy.get("hurdle", {}) as Dictionary).get("reason", "")).contains("控制关键成员"), "third-chapter hurdle explains the new point-kill pressure")


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

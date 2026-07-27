extends SceneTree

const CampaignObjectiveProjectionScript := preload(
	"res://game/scripts/domain/objectives/campaign_objective_projection.gd"
)
const GameStateScript := preload("res://game/scripts/state/game_state.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_first_chapter_projection()
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
	return state


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

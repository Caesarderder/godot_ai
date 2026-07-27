extends SceneTree

const Catalog := preload("res://game/scripts/content/onboarding_definition_catalog.gd")
const CompatibilityCatalog := preload(
	"res://game/scripts/domain/onboarding/onboarding_catalog.gd"
)

const EXPECTED_TASK_IDS: Array[String] = [
	"operation.lone_vanguard",
	"operation.keep_advancing",
	"operation.high_wall",
	"operation.research_reinforcements",
	"operation.counterattack",
	"operation.choose_growth",
	"operation.chapter_boss",
]
const EXPECTED_REWARD_TOTALS := {
	"toilet_coins": 60,
	"hero_shards": 12,
	"porcelain": 24,
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors := Catalog.validate_all()
	_check(errors.is_empty(), "typed onboarding definitions validate: %s" % ", ".join(errors))
	_check(Catalog.count() == 7, "first chapter exposes exactly seven ordered tasks")
	var objective_count := 0
	var reward_totals := {}
	for index in EXPECTED_TASK_IDS.size():
		var view := Catalog.task_view_at(index)
		_check(
			String(view.get("id", "")) == EXPECTED_TASK_IDS[index],
			"task %d keeps its stable operation ID" % (index + 1)
		)
		var objectives := view.get("objectives", []) as Array
		objective_count += objectives.size()
		_check(not objectives.is_empty(), "%s has a player-visible next action" % EXPECTED_TASK_IDS[index])
		for objective_value in objectives:
			var objective := objective_value as Dictionary
			_check(
				not String(objective.get("label", "")).is_empty()
					and not String(objective.get("cta_label", "")).is_empty(),
				"%s objective exposes both purpose and CTA" % EXPECTED_TASK_IDS[index]
			)
		for key in (view.get("reward", {}) as Dictionary):
			reward_totals[key] = int(reward_totals.get(key, 0)) + int(view["reward"][key])
	_check(objective_count == 12, "seven tasks compose exactly twelve granular objectives")
	_check(reward_totals == EXPECTED_REWARD_TOTALS, "task rewards fund battle growth without duplicating factory output")

	var high_wall := Catalog.task_view("operation.high_wall")
	_check(
		String((high_wall["objectives"] as Array)[0].get("outcome", "")) == "defeat",
		"1-4 forced loss remains an explicit major-hurdle objective"
	)
	var research := Catalog.task_view("operation.research_reinforcements")
	_check(
		String((research["objectives"] as Array)[0].get("target", "")) == "legion",
		"forced loss routes to the foundational signal before research"
	)
	_check(
		(research["objectives"] as Array).size() == 3,
		"signal reception and two deterministic blueprint researches are distinct goals"
	)
	var growth := Catalog.task_view("operation.choose_growth")
	_check(
		(growth.get("objectives", []) as Array).size() == 3,
		"dual-track growth keeps star, build and collect micro goals"
	)
	_check(
		(((growth.get("objectives", []) as Array)[0] as Dictionary).get("event_types", []) as Array)
			.has("hero_star_upgraded"),
		"battle-earned hero growth happens before the independent factory expansion"
	)
	high_wall["title"] = "mutated"
	(high_wall["objectives"] as Array)[0]["label"] = "mutated"
	_check(
		String(Catalog.task_view("operation.high_wall").get("title", "")) == "行动三：撞击高墙",
		"callers cannot mutate shared task Resources"
	)
	_check(
		String(
			((Catalog.task_view("operation.high_wall")["objectives"] as Array)[0] as Dictionary)
			.get("label", "")
		).contains("失败原因"),
		"nested objective views are detached"
	)
	_check(
		CompatibilityCatalog.task_by_id("operation.unknown").is_empty(),
		"unknown task IDs fail closed through the compatibility facade"
	)
	if failures.is_empty():
		print("ONBOARDING_DEFINITION_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("ONBOARDING_DEFINITION_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

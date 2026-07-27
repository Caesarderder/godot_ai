extends SceneTree

const ObjectiveHurdleCatalogScript := preload(
	"res://game/scripts/content/objective_hurdle_catalog.gd"
)
const OnboardingCatalogScript := preload(
	"res://game/scripts/domain/onboarding/onboarding_catalog.gd"
)

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var validation_errors := ObjectiveHurdleCatalogScript.validate_all()
	_check(
		validation_errors.is_empty(),
		"typed objective hurdle definitions validate: %s" % ", ".join(validation_errors)
	)
	_check(
		ObjectiveHurdleCatalogScript.FIRST_CHAPTER.size() == OnboardingCatalogScript.count(),
		"every first-chapter onboarding operation has one hurdle definition"
	)
	for index in OnboardingCatalogScript.count():
		var task := OnboardingCatalogScript.task_at(index)
		var task_id := String(task.get("id", ""))
		var definition: Resource = ObjectiveHurdleCatalogScript.definition(task_id)
		_check(definition != null, "%s resolves to a typed hurdle definition" % task_id)
		var view := ObjectiveHurdleCatalogScript.hurdle_view(task_id)
		_check(
			["小坎", "中坎", "大坎"].has(String(view.get("scale", ""))),
			"%s exposes a valid player-facing hurdle scale" % task_id
		)
		_check(
			not String(view.get("reason", "")).is_empty()
				and not String(view.get("recovery", "")).is_empty(),
			"%s explains both the obstacle and a recovery path" % task_id
		)
	var high_wall := ObjectiveHurdleCatalogScript.hurdle_view("operation.high_wall")
	_check(String(high_wall.get("scale", "")) == "大坎", "the first forced loss remains a major hurdle")
	_check(
		String(high_wall.get("recovery", "")).contains("研发冲锋")
			and String(high_wall.get("recovery", "")).contains("研究所"),
		"the first forced loss points to its deterministic stage-reward-to-research recovery"
	)
	high_wall["title"] = "mutated view"
	_check(
		String(ObjectiveHurdleCatalogScript.hurdle_view("operation.high_wall").get("title", ""))
			== "1-4 灰镜高墙",
		"callers receive a detached view and cannot mutate the shared Resource"
	)
	_check(
		ObjectiveHurdleCatalogScript.hurdle_view("operation.unknown").is_empty(),
		"unknown operation IDs fail closed"
	)
	if failures.is_empty():
		print("OBJECTIVE_HURDLE_DEFINITION_TESTS_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("OBJECTIVE_HURDLE_DEFINITION_TESTS_FAIL: %d issue(s)" % failures.size())
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

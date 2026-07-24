extends SceneTree

const TEST_SCRIPTS: Array[String] = [
    "res://recipes/architecture/feature-slice/tests/test.gd",
    "res://recipes/architecture/resource-runtime-pair/tests/test.gd",
    "res://recipes/architecture/signal-boundary/tests/test.gd",
    "res://recipes/architecture/scene-transition/tests/test.gd",
    "res://recipes/architecture/save-envelope/tests/test.gd",
    "res://recipes/gameplay/state-machine-basic/tests/test.gd",
    "res://recipes/gameplay/interaction/tests/test.gd",
    "res://recipes/gameplay/damage-pipeline/tests/test.gd",
    "res://recipes/ui/theme-tokens/tests/test.gd",
    "res://recipes/ui/responsive-screen-shell/tests/test.gd",
    "res://recipes/ui/component-gallery-core/tests/test.gd",
    "res://recipes/testing/scene-contract/tests/test.gd",
]


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var failures: Array[String] = []
    for test_path in TEST_SCRIPTS:
        var test_script: Script = load(test_path)
        if test_script == null:
            failures.append("%s: failed to load" % test_path)
            continue
        var test_case: Object = test_script.new()
        var result: Variant = await test_case.call("run", self)
        if result is Array:
            for failure: Variant in result:
                failures.append("%s: %s" % [test_path, str(failure)])
        else:
            failures.append("%s: run() did not return an Array" % test_path)

    if failures.is_empty():
        print("[OK] %d micro-recipe tests passed" % TEST_SCRIPTS.size())
        quit(0)
        return

    for failure in failures:
        push_error(failure)
    quit(1)

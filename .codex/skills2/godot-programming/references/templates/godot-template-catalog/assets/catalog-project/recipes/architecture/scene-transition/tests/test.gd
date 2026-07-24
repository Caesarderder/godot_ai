extends RefCounted


func run(tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var demo: PackedScene = load("res://recipes/architecture/scene-transition/demo.tscn")
    var router: TemplateSceneRouter = demo.instantiate()
    tree.root.add_child(router)
    var target: PackedScene = load("res://recipes/architecture/scene-transition/target_scene.tscn")
    if not router.transition_to(target):
        failures.append("valid transition failed")
    elif router.current_scene == null or router.current_scene.name != &"LoadedTarget":
        failures.append("router did not install the requested scene")
    if router.transition_to(null):
        failures.append("missing scene did not fail closed")
    router.queue_free()
    return failures

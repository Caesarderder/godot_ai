extends RefCounted


func run(tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var scene: PackedScene = load("res://recipes/gameplay/interaction/demo.tscn")
    var demo: Node = scene.instantiate()
    tree.root.add_child(demo)
    var interactor := demo.get_node("Interactor") as TemplateInteractor
    var high := demo.get_node("HighPriority") as TemplateInteractable
    if interactor.selected != high:
        failures.append("highest-priority candidate was not selected")
    if not interactor.execute_selected() or high.execution_count != 1:
        failures.append("selected interaction did not execute exactly once")
    interactor.cancel()
    if interactor.selected != null:
        failures.append("cancel did not clear selection")
    demo.queue_free()
    return failures

extends RefCounted


func run(tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var scene: PackedScene = load("res://recipes/architecture/signal-boundary/demo.tscn")
    var mediator: TemplateSignalMediator = scene.instantiate()
    tree.root.add_child(mediator)
    mediator.source.request(4)
    if mediator.total != 4:
        failures.append("mediator did not own the requested state change")
    mediator.queue_free()
    return failures

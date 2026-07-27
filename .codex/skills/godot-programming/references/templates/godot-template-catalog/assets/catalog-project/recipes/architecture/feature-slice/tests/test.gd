extends RefCounted


func run(_tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var scene: PackedScene = load("res://recipes/architecture/feature-slice/counter_feature.tscn")
    var feature: TemplateCounterFeature = scene.instantiate()
    if feature.increment(2) != 2:
        failures.append("counter did not increment")
    if feature.increment(5) != 3:
        failures.append("counter did not clamp to its Resource maximum")
    feature.free()
    return failures

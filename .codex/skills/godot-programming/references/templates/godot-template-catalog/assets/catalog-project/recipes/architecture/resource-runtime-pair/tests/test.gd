extends RefCounted


func run(_tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var definition: TemplateMeterDefinition = load(
        "res://recipes/architecture/resource-runtime-pair/meter_definition.tres"
    )
    var first := TemplateMeterRuntime.new(definition)
    var second := TemplateMeterRuntime.new(definition)
    first.spend(30)
    if first.current != 50:
        failures.append("runtime did not spend from its initial value")
    if second.current != 80:
        failures.append("runtime instances shared mutable state")
    if definition.initial != 80:
        failures.append("runtime mutation changed the shared Resource")
    return failures

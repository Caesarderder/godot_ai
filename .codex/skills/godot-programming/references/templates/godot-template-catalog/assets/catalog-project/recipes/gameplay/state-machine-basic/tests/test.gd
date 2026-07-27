extends RefCounted


func run(tree: SceneTree) -> Array[String]:
    var failures: Array[String] = []
    var scene: PackedScene = load("res://recipes/gameplay/state-machine-basic/demo.tscn")
    var machine: TemplateStateMachine = scene.instantiate()
    tree.root.add_child(machine)
    var idle := machine.get_node("Idle") as TemplateIdleState
    var active := machine.get_node("Active") as TemplateActiveState
    if machine.current_state != idle or idle.entered_count != 1:
        failures.append("initial state did not enter exactly once")
    if not machine.transition_to(active):
        failures.append("valid transition was rejected")
    elif machine.current_state != active or active.entered_count != 1:
        failures.append("target state did not become current")
    machine.queue_free()
    return failures

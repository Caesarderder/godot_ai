# State Machine Examples

Reference for `skills/animation-system/SKILL.md` — the canonical GDScript state machine example (CharacterBody2D driving `AnimationNodeStateMachinePlayback`).

> ← Back to [SKILL.md](../SKILL.md)

---

### State Machine — GDScript

```gdscript
extends CharacterBody2D

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/playback"]

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    if input_dir != Vector2.ZERO:
        velocity = input_dir * 200.0
        state_machine.travel("walk")
    else:
        velocity = Vector2.ZERO
        state_machine.travel("idle")

    move_and_slide()

func attack() -> void:
    # travel() transitions smoothly; use start() for immediate switch
    state_machine.travel("attack")

func get_current_state() -> StringName:
    return state_machine.get_current_node()
```

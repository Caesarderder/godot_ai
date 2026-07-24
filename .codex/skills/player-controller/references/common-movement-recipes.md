> ← Back to [SKILL.md](../SKILL.md)

# Common Movement Recipes

Two recipes that come up in almost every platformer: **Dash** (timer-based velocity override for a short burst) and **Wall Jump** (vertical wall slide + bounce off `get_wall_normal()` when jump is pressed). Both apply to a `CharacterBody2D` and slot into the standard `_physics_process` loop alongside gravity and horizontal movement.

---

## Dash (GDScript)

```gdscript
extends CharacterBody2D

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2

var is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed("dash") and not is_dashing:
        is_dashing = true
        _dash_timer = dash_duration
        # Dash in input direction, or forward if no input
        _dash_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
        if _dash_direction == Vector2.ZERO:
            _dash_direction = Vector2.RIGHT.rotated(rotation)

    if is_dashing:
        _dash_timer -= delta
        velocity = _dash_direction * dash_speed
        if _dash_timer <= 0.0:
            is_dashing = false

    move_and_slide()
```



---

## Wall Jump (GDScript)

```gdscript
extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var wall_jump_velocity: Vector2 = Vector2(250.0, -350.0)

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += _gravity * delta

    # Wall jump: bounce off in the direction of the wall normal
    if Input.is_action_just_pressed("ui_accept"):
        if is_on_floor():
            velocity.y = jump_velocity
        elif is_on_wall():
            var wall_normal: Vector2 = get_wall_normal()
            velocity = wall_normal * wall_jump_velocity.x + Vector2(0, wall_jump_velocity.y)

    var input_x: float = Input.get_axis("ui_left", "ui_right")
    velocity.x = move_toward(velocity.x, input_x * speed, 1000.0 * delta)

    move_and_slide()
```

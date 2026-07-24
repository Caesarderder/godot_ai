# StaticBody Recipes

Reference for `skills/physics-system/SKILL.md` — Conveyor belts (StaticBody2D constant_linear_velocity) and moving platforms (AnimatableBody3D).

> ← Back to [SKILL.md](../SKILL.md)

---
## 3. StaticBody2D/3D

StaticBodies are not moved by the physics engine but can impart motion to other bodies via constant velocities. They are ideal for walls, floors, and moving platforms.

### Conveyor Belt

```gdscript
extends StaticBody2D

## Speed in pixels/sec — bodies touching this surface slide along it.
@export var belt_speed: float = 100.0

func _ready() -> void:
    constant_linear_velocity = Vector2(belt_speed, 0)
```

### Moving Platform (AnimatableBody)

For platforms that move via code and push other bodies, use `AnimatableBody2D`/`3D` (extends StaticBody):

```gdscript
extends AnimatableBody2D

@export var travel: Vector2 = Vector2(0, -200)
@export var duration: float = 2.0

var _start_position: Vector2

func _ready() -> void:
    _start_position = position
    var tween: Tween = create_tween().set_loops()
    tween.tween_property(self, "position", _start_position + travel, duration)
    tween.tween_property(self, "position", _start_position, duration)
```


> **Note:** `AnimatableBody2D`/`3D` is the correct node for moving platforms. A plain `StaticBody` moved by code will not push CharacterBodies reliably.

---

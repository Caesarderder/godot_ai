# `super()` in inherited callbacks

Overriding a method in a GDScript subclass replaces the script base implementation unless the child calls `super()`.

```gdscript
# enemy_base.gd
class_name EnemyBase
extends CharacterBody2D

func _ready() -> void:
    add_to_group("enemies")
    health_component.health_depleted.connect(_on_health_depleted)
```

```gdscript
# special_enemy.gd
extends EnemyBase

func _ready() -> void:
    super()
    navigation_agent.velocity_computed.connect(_on_velocity_computed)
```

Use this decision process:

1. Inspect the immediate script base class.
2. If it implements the same method and the child extends that behavior, call `super()`.
3. If the child intentionally replaces the behavior, omit `super()` and document the replacement when it is not obvious.
4. Do not add `super()` blindly to every engine callback. Some engine virtuals have no user-script base behavior, and a few special methods have engine-defined inheritance semantics.

The position of `super()` depends on the contract. Call it first when the base establishes invariants needed by the child; call it later only when the base explicitly expects child preparation.

Missing `super()` can skip base group registration, signal connections, state initialization performed in the callback, or per-frame behavior. It does not prevent the base script's `@onready` member initialization; those values initialize independently before that script instance's ready callback.

# Abstract classes and methods (Godot 4.5+)

Use an abstract class when a shared GDScript base must not be instantiated and subclasses must provide selected behavior.

For a named script class, place `@abstract` before `class_name`:

```gdscript
@abstract
class_name BaseEnemy
extends Node

var health: int = 100

@abstract func perform_attack() -> void

@abstract func get_display_name() -> String

func take_damage(amount: int) -> void:
    health = maxi(health - amount, 0)
```

A concrete subclass implements every inherited abstract method:

```gdscript
class_name MeleeEnemy
extends BaseEnemy

func perform_attack() -> void:
    print("Melee attack")

func get_display_name() -> String:
    return "Melee Enemy"
```

For an unnamed abstract script, put the annotation before `extends`:

```gdscript
@abstract
extends Node

@abstract func run() -> void
```

For an inner abstract class, use:

```gdscript
@abstract class Command:
    @abstract func execute() -> void
```

Important boundaries:

- Do not attach an abstract script to a node; it cannot be instantiated.
- A class with an abstract method is itself abstract even if the class annotation is omitted, but annotate the class explicitly to make intent visible.
- Keep shared concrete behavior in the base; do not use abstract methods only to imitate an interface when simple composition is clearer.
- Abstract classes are a language contract, not a substitute for verifying scene ownership and runtime wiring.

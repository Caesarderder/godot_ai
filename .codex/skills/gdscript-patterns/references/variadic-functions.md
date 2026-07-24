# Variadic Functions (Godot 4.5+)

Reference for `gdscript-patterns/SKILL.md` — the `...args` syntax for trailing-argument arrays and when to prefer an explicit Array.

> ← Back to [SKILL.md](../SKILL.md)

---
## Variadic functions (Godot 4.5+)

Godot 4.5 adds variadic function support to GDScript. Append `...` before the last parameter name to collect all trailing arguments passed at the call site into an `Array`. This replaces patterns that required callers to pass an explicit array literal.

```gdscript
# The ...args parameter collects any number of trailing arguments as an Array.
func log_message(level: String, ...args) -> void:
    var text := " ".join(args.map(func(a) -> String: return str(a)))
    print("[%s] %s" % [level, text])

# Call with any number of trailing arguments — no array literal needed.
log_message("INFO", "Player", "joined", "the", "game")
log_message("WARN", "Health low:", current_health)


# Variadic math helper
func sum(...values) -> float:
    var total := 0.0
    for v in values:
        total += float(v)
    return total

print(sum(1, 2, 3, 4, 5))  # 15.0


# Combine required parameters with variadic trailing args
func spawn_enemies(scene: PackedScene, ...positions) -> void:
    for pos in positions:
        var enemy: Node2D = scene.instantiate()
        enemy.global_position = pos
        add_child(enemy)

spawn_enemies(enemy_scene,
    Vector2(100, 200),
    Vector2(300, 200),
    Vector2(500, 200),
)
```

> **Rules:** The rest parameter must be last. Excess arguments arrive in an `Array`. A function may have at most one rest parameter, and GDScript does not support spreading an Array into positional call arguments.

Prefer an explicit typed `Array[Type]` parameter when callers already own a collection or element type validation matters more than call-site convenience.

---

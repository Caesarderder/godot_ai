# Sharing vs Unique Resources


> ← Back to [SKILL.md](../SKILL.md)

---
## 8. Sharing vs Unique

Resources loaded from the same path are **shared**. Every node that loads `res://data/enemies/goblin.tres` gets the exact same object in memory.

```gdscript
# Both variables point to the same object — modifying one modifies the other.
var a: EnemyStats = load("res://data/enemies/goblin.tres")
var b: EnemyStats = load("res://data/enemies/goblin.tres")
print(a == b)  # true
```

**For per-instance mutable state, call `duplicate()`:**

```gdscript
func _ready() -> void:
    # Shallow duplicate — nested Resources are still shared
    stats = stats.duplicate()

    # Deep duplicate — all nested Resources are also copied
    stats = stats.duplicate(true)
```



**Make Unique in the Inspector:** A sub-resource slot can expose a **Make Unique** action. It embeds a private copy into the parent scene instead of referencing the shared file. This is editor UI, not a callable GDScript API. At runtime, use `duplicate()` and assign its return value.

**Guideline:**
- Read-only data (item definitions, level config) — share freely, no duplication needed.
- Mutable runtime state (current health, active buffs) — always `duplicate()` in `_ready()`.

---

# Resource as Configuration


> ← Back to [SKILL.md](../SKILL.md)

---
## 5. Resource as Configuration

Use Resources to define enemy tuning parameters. Designers can tweak values in the Inspector without touching code. The `@export_range` annotation enforces bounds and surfaces sliders.

### GDScript

```gdscript
# enemy_stats.gd
class_name EnemyStats
extends Resource

@export_group("Combat")
@export_range(1,    5000, 1)    var health:          int   = 100
@export_range(0.0,  500.0, 0.1) var speed:           float = 80.0
@export_range(0,    999,   1)   var damage:          int   = 10
@export_range(0.0,  1.0,  0.01) var crit_chance:     float = 0.05
@export_range(0.1, 10.0,  0.1)  var attack_interval: float = 1.5

@export_group("Drops")
## Each entry must be a Resource subclass that describes a drop (e.g. DropEntry).
@export var drop_table: Array[Resource] = []
@export_range(0.0,  1.0,  0.01) var drop_chance: float = 0.3
```

```gdscript
# enemy.gd — consumes EnemyStats
class_name Enemy
extends CharacterBody2D

@export var stats: EnemyStats

var _current_health: int


func _ready() -> void:
    # duplicate() returns an instance-local mutable copy.
    stats = stats.duplicate()
    _current_health = stats.health


func take_damage(amount: int) -> void:
    _current_health -= amount
    if _current_health <= 0:
        _die()


func _die() -> void:
    _roll_drops()
    queue_free()


func _roll_drops() -> void:
    if randf() > stats.drop_chance:
        return
    for drop: Resource in stats.drop_table:
        # Spawn drop — implementation depends on project drop system
        pass
```




---

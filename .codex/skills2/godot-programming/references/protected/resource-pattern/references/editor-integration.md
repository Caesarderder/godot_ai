# Editor Integration


> ← Back to [SKILL.md](../SKILL.md)

---
## 4. Editor Integration

Export annotations control how properties appear in the Inspector.

### GDScript

```gdscript
class_name AbilityData
extends Resource

# Groups collapse related fields under a named header
@export_group("Identity")
@export var ability_name: String = ""
@export var description:  String = ""
@export var icon:         Texture2D

# Category draws a bold separator (not collapsible)
@export_category("Tuning")

# Range clamps the value and shows a slider in the Inspector
@export_range(0.0, 60.0, 0.1, "suffix:s") var cooldown:   float = 1.0
@export_range(1,   999,   1)               var mana_cost:  int   = 10
@export_range(0.0, 1.0,  0.01)             var crit_chance: float = 0.05

# Enum shows a dropdown in the Inspector
enum DamageType { PHYSICAL, FIRE, ICE, LIGHTNING }
@export var damage_type: DamageType = DamageType.PHYSICAL

@export_group("Flags")
@export var is_passive:     bool = false
@export var requires_target: bool = true
```

| Annotation | Effect |
|---|---|
| `@export` | Exposes any typed property in the Inspector |
| `@export_range(min, max, step)` | Adds a slider, clamps input |
| `@export_enum("A","B","C")` | Dropdown for `int` when no enum type available |
| `@export_group("Label")` | Collapsible header grouping following properties |
| `@export_category("Label")` | Bold non-collapsible separator |



---

---
name: resource-pattern
description: Use when creating custom Resources for configuration, items, stats, sharing, duplication, collections, and editor integration in Godot 4.6 GDScript Web projects
---

# Resource Pattern in Godot 4.6

Use Resources as typed Godot 4.6 GDScript data containers for configuration, item definitions, character stats, and other data outside the scene tree.

> **Related skills:** **inventory-system** for Resource-based item definitions, **save-load** for Resource serialization, and **godot-architecture** for ownership of data-driven gameplay configuration.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

---

## 1. What Are Resources

A `Resource` is a reference-counted data object that:

- Is saved as a `.tres` (text) or `.res` (binary) file on disk
- Is editable directly in the Godot Inspector
- Is **loaded once and shared by default** — every node that loads the same path gets the same in-memory object
- Can be nested inside other Resources and PackedScenes
- Survives scene changes (unlike Node state, which is discarded on scene reload)

Because Resources are shared by default, they are ideal for read-only data (item definitions, audio settings, ability blueprints). For per-instance mutable runtime state, assign the result of `duplicate()` or `duplicate(true)` — see section 8. “Make Unique” is an Inspector action, not a GDScript method.

---

## 2. When to Use Resources

| Use Case | Example Resource | Alternative |
|---|---|---|
| Item definitions | `ItemData` with name, icon, value | Dictionary (loses type safety) |
| Enemy configuration | `EnemyStats` with health, speed, damage | Exported vars on Node (not reusable) |
| Character stats | `CharacterStats` with base values | Autoload (global state, hard to test) |
| Ability definitions | `AbilityData` with cooldown, cost, effect | Hardcoded constants |
| Level metadata | `LevelConfig` with music, time limit, goals | JSON (no editor integration) |
| Audio / visual themes | `UIThemeData` with color palette, fonts | Theme resource (same idea, built-in) |
| Dialogue trees | `DialogueLine` referencing next line | JSON (no type checking) |

Use a custom Resource any time you want **Inspector editing + typed data + sharing across scenes**.

---

## 3. Basic Custom Resource

### GDScript

```gdscript
# item_data.gd
class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOUR, CONSUMABLE, QUEST }

@export var name:        String   = ""
@export var description: String   = ""
@export var icon:        Texture2D
@export var value:       int      = 0
@export var item_type:   ItemType = ItemType.CONSUMABLE
```

Create an instance in the editor: **right-click** the FileSystem panel → **New Resource** → choose `ItemData`. Fill in the Inspector fields and save as `res://data/items/health_potion.tres`.

Load it at runtime:

```gdscript
var potion: ItemData = load("res://data/items/health_potion.tres")
print(potion.name)        # "Health Potion"
print(potion.value)       # 50
```

---

## 4. Editor Integration

Use `class_name`, `@tool`, and `@icon` to make custom Resources first-class in the Inspector — they appear in the Resource picker, can be created via right-click "New Resource", show a custom icon. `@export_group` and `@export_subgroup` organize properties.

> See [references/editor-integration.md](references/editor-integration.md) for the GDScript pattern with `class_name`, `@icon`, and `@export_group`.

---

## 5. Resource as Configuration

The strongest use case: data-driven game content. Loot tables, enemy stats, ability definitions, item catalogs all become custom Resources. Designers tweak `.tres` files in the Inspector; programmers wire the loader. Avoids JSON's loose schema and stringly-typed parsing.

> See [references/configuration-pattern.md](references/configuration-pattern.md) for a GDScript LootTable and DropEntry example.

---

## 6. Resource Collections

`@export var entries: Array[Entry] = []` exposes a typed array in the Inspector — drag and drop multiple Resource files. For startup-loaded sets, use `ResourcePreloader`. For asset-folder discovery at runtime, walk `DirAccess`.

> See [references/collections.md](references/collections.md) for typed-array exports, `ResourcePreloader` setup, and the directory-walking loader pattern.

---

## 7. Resource vs Node

| Aspect | Resource | Node |
|---|---|---|
| Purpose | Data storage and configuration | Behavior, rendering, physics, input |
| Scene tree | Not in the tree | Lives in the scene tree |
| Lifecycle hooks | None (`_init` only) | `_ready`, `_process`, `_physics_process`, etc. |
| Sharing | Shared by default (same path = same object) | Each instance is independent |
| Serialization | Saved as `.tres` / `.res`, Inspector-editable | Saved inside `.tscn` |
| Signals | Supported | Supported |
| Use for | Item data, stats, config, ability blueprints | Player, enemy, UI widgets, cameras |
| Avoid for | Anything needing per-frame updates or scene queries | Static data that never changes at runtime |

**Rule of thumb:** if it has no behavior and no need to exist in the scene tree, make it a Resource. If it needs to move, render, receive input, or run per-frame logic, make it a Node.

---

## 8. Sharing vs Unique

By default, Resources are shared by reference. Two scenes referencing `res://items/sword.tres` see the SAME instance — mutating one mutates both. Use `.duplicate()` (shallow) or `.duplicate(true)` (deep) for instance-local state.

> See [references/sharing-vs-unique.md](references/sharing-vs-unique.md) for the GDScript sharing and duplication pattern.

---

## 9. Saving Custom Resources

`ResourceSaver.save(resource, path)` writes to a `.tres` (text) or `.res` (binary) file. Use for save games (where the schema lives in code as a Resource subclass) instead of hand-rolled JSON when you want strong typing.

> See [references/saving-resources.md](references/saving-resources.md) for the GDScript save/load pattern and security caveat.

---

## 10. Anti-patterns

### Mutable shared Resources without `duplicate()` — accidental shared state

```gdscript
# BAD — all enemies share the same EnemyStats object.
# Damaging one enemy damages all of them.
class_name Enemy
extends CharacterBody2D

@export var stats: EnemyStats  # loaded from .tres, shared

func take_damage(amount: int) -> void:
    stats.health -= amount  # mutates the shared Resource!
```

```gdscript
# GOOD — each enemy owns its own copy.
func _ready() -> void:
    stats = stats.duplicate()  # now safe to mutate
```

### Game logic inside Resources

```gdscript
# BAD — Resources have no scene tree access, no _process, no signals from nodes.
class_name EnemyStats
extends Resource

func update_health_regen(delta: float) -> void:
    # Can't call get_tree(), can't read Input, can't access nodes.
    # This logic belongs in a Node.
    health = min(health + regen_rate * delta, max_health)
```

```gdscript
# GOOD — keep logic in Nodes, data in Resources.
# enemy.gd
func _process(delta: float) -> void:
    _current_health = minf(_current_health + stats.regen_rate * delta, stats.max_health)
```

### Giant monolithic Resources

```gdscript
# BAD — one Resource holds everything; impossible to reuse parts.
class_name GameConfig
extends Resource

@export var player_health: int
@export var player_speed: float
@export var enemy_goblin_health: int
@export var enemy_goblin_speed: float
@export var enemy_troll_health: int
# ... 200 more properties
```

```gdscript
# GOOD — small focused Resources, composed together.
class_name PlayerConfig
extends Resource

@export var health: int   = 100
@export var speed:  float = 200.0
```

```gdscript
class_name EnemyConfig
extends Resource

@export var health: int   = 50
@export var speed:  float = 80.0
```

---

## 11. Checklist

- [ ] Resource subclass uses `class_name` so the editor can find it for **New Resource**
- [ ] All Inspector-editable fields use `@export` / `[Export]`
- [ ] `@export_range` used on numeric fields with designer-tunable bounds
- [ ] `@export_group` and `@export_category` used to organize Inspector layout for Resources with many fields
- [ ] Per-instance mutable Resources are `duplicate()`-d in `_ready()`
- [ ] Read-only shared Resources (definitions, blueprints) are **not** duplicated
- [ ] Game logic (per-frame updates, scene queries) lives in Nodes, not Resources
- [ ] Large data sets split into focused single-responsibility Resources
- [ ] `.tres` used during development; `.res` considered for shipped production data
- [ ] `ResourceSaver.save()` return value checked and errors reported with `push_error()`
- [ ] `.tres` / `.res` files never loaded from untrusted external sources

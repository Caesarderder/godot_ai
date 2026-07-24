# Save Architecture Pattern

Reference for `skills/save-load/SKILL.md` — `SaveableComponent` per-node pattern with `Callable`-based save/restore hooks.

> ← Back to [SKILL.md](../SKILL.md)

---
## 4. Save Architecture Pattern

For complex games, use the "saveable" group pattern. SaveManager collects serialized data from all registered nodes on save, then distributes data back to them on load.

```
SaveManager.save_game()
    │
    ├─► get_nodes_in_group("saveable")
    │       └─► node.serialize.call()  →  { id, data }
    │
    └─► write combined dict to disk

SaveManager.load_game()
    │
    ├─► read dict from disk
    │
    └─► get_nodes_in_group("saveable")
            └─► node.deserialize.call(data[node.id])
```

### SaveableComponent Pattern

Add this component to any node that needs to participate in saving.

**GDScript (`saveable_component.gd`)**

```gdscript
# Attach to any node that should save/load its own state.
class_name SaveableComponent
extends Node

## Unique stable ID for this saveable object (set in the Inspector).
@export var save_id: String = ""

## Assign a Callable that returns a Dictionary of state to save.
var serialize: Callable = func() -> Dictionary:
	push_error("SaveableComponent: serialize not set on '%s'" % get_parent().name)
	return {}

## Assign a Callable that accepts a Dictionary to restore state from.
var deserialize: Callable = func(_data: Dictionary) -> void:
	push_error("SaveableComponent: deserialize not set on '%s'" % get_parent().name)


func _ready() -> void:
	add_to_group("saveable")
```

**Example — Chest node using SaveableComponent:**

```gdscript
# chest.gd
extends Node3D

@onready var saveable: SaveableComponent = $SaveableComponent

var is_open: bool = false
var contents: Array = ["sword", "potion"]


func _ready() -> void:
	saveable.serialize   = _serialize
	saveable.deserialize = _deserialize


func _serialize() -> Dictionary:
	return {"is_open": is_open, "contents": contents.duplicate()}


func _deserialize(data: Dictionary) -> void:
	is_open  = data["is_open"]
	contents = data["contents"].duplicate()
	if is_open:
		_play_open_animation()
```






---

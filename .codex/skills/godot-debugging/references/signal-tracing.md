# Signal Tracing

Reference for `skills/godot-debugging/SKILL.md` — inspecting signal connections at runtime, common signal issues catalog. GDScript.

> ← Back to [SKILL.md](../SKILL.md)

---
## 3. Signal Debugging

### Inspecting Connections at Runtime

```gdscript
# List all connections on a signal
func _ready() -> void:
    var connections := health_component.get_signal_connection_list("health_changed")
    for conn in connections:
        print("Signal 'health_changed' connected to: ", conn["callable"])

# Check whether a specific callable is connected
if health_component.is_connected("health_changed", _on_health_changed):
    print("Connected")
else:
    push_warning("health_changed signal not connected — UI will not update")

# List all signals a node has emitted connections for
for sig in get_signal_list():
    var conns := get_signal_connection_list(sig["name"])
    if conns.size() > 0:
        print("Signal '%s': %d connection(s)" % [sig["name"], conns.size()])
```

### Common Signal Issues

**Signal connected but not firing**

```gdscript
# WRONG — connecting to a signal that does not exist on the node
enemy.connect("dead", _on_enemy_dead)   # typo or wrong node type

# RIGHT — verify signal exists before connecting, or use typed references
assert("dead" in enemy.get_signal_list().map(func(s): return s["name"]),
    "Signal 'dead' not found on %s" % enemy.name)
enemy.dead.connect(_on_enemy_dead)
```


**Wrong argument count or types**

```gdscript
# Signal declared with one argument
signal item_picked_up(item: Item)

# WRONG receiver — missing argument causes "Expected 1 arguments" error
func _on_item_picked_up() -> void:
    print("picked up something")

# RIGHT — signature must match
func _on_item_picked_up(item: Item) -> void:
    print("picked up: ", item.display_name)
```


**Signal connected to a freed node**

```gdscript
# Use CONNECT_ONE_SHOT for single-fire connections to avoid stale connections
enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)

# Or disconnect explicitly before freeing
func _exit_tree() -> void:
    if health_component.is_connected("health_changed", _on_health_changed):
        health_component.disconnect("health_changed", _on_health_changed)

# Prefer a named callable when the connection needs explicit lifecycle control.
func _ready() -> void:
    some_node.some_signal.connect(_on_some_signal)

func _exit_tree() -> void:
    if is_instance_valid(some_node) and some_node.some_signal.is_connected(_on_some_signal):
        some_node.some_signal.disconnect(_on_some_signal)

func _on_some_signal() -> void:
    _do_work()
```


**Signal emitted before receiver is ready**

```gdscript
# Autoload emits a signal during _ready before the main scene is fully loaded
# FIX — defer emission to the next frame
func _ready() -> void:
    call_deferred("_emit_ready_signal")

func _emit_ready_signal() -> void:
    game_ready.emit()
```


---

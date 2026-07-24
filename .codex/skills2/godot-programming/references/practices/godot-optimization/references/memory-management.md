# Memory Management & Object Pooling

Reference for `skills/godot-optimization/SKILL.md` — runtime memory monitoring, ResourceLoader caching, freeing semantics, and object pooling for high-churn entities.

> ← Back to [SKILL.md](../SKILL.md)

---

## Memory Management

### Monitoring Memory at Runtime

```gdscript
# Query engine memory monitors via Performance singleton
func _print_memory_stats() -> void:
    var static_mem := Performance.get_monitor(Performance.MEMORY_STATIC)
    var video_ram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
    var obj_count := Performance.get_monitor(Performance.OBJECT_COUNT)
    var resource_count := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
    var node_count := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)

    print("Static RAM: %.2f MB" % (static_mem / 1_048_576.0))
    print("Video RAM : %.2f MB" % (video_ram / 1_048_576.0))
    print("Objects   : %d" % obj_count)
    print("Resources : %d" % resource_count)
    print("Nodes     : %d" % node_count)
```


If `MEMORY_STATIC` keeps growing across repeated runs of the same scene transition,
inspect long-lived references and resource ownership; a single sample is not proof
of a leak.

### ResourceLoader Caching Behaviour

Godot's resource loader caches resources by path. Subsequent loads can return the
same instance. This means:

- Resources are shared by default — modifying one instance modifies all users.
- Use `resource.duplicate()` when you need a per-instance copy (e.g. per-enemy stats).
- A resource can remain alive while another owner or the loader cache retains it.

```gdscript
# Shared resource — all enemies use the same stats object (intended for read-only data)
const EnemyStats: Resource = preload("res://data/enemy_stats.tres")

# Per-instance copy — each enemy gets its own mutable copy
func _ready() -> void:
    _stats = EnemyStats.duplicate()
    _stats.health = _stats.max_health  # safe to modify
```

There is no general-purpose synchronous cache-eviction or manual garbage-collection
call to use here. For a temporary resource, avoid storing it in an autoload or other
long-lived owner, release your references when finished, and confirm behavior with
the runtime monitors. Builda's single-thread Web target uses synchronous loading;
split large content into smaller scenes or resources and load it at controlled
transition points.

### Freeing Unused Resources

```gdscript
# Nodes: always use queue_free() unless you need synchronous teardown
func _on_enemy_died() -> void:
    queue_free()  # safe — deferred until end of current frame processing

# Nodes: free() is synchronous and immediate — only use when you are certain
# no other code will access the node in the same frame
func _force_remove_node(node: Node) -> void:
    node.free()  # dangerous if called from a signal emitted by `node` itself

# Non-node RefCounted resources are freed automatically when the last
# reference is released — no manual call needed.
var texture: ImageTexture = ImageTexture.new()
# texture is freed when it goes out of scope or is set to null

# Non-node Object (not RefCounted) — must be freed manually
var raw_obj := Object.new()
raw_obj.free()
```

### queue_free vs free

| Method | Timing | Safe inside callbacks | Use when |
|---|---|---|---|
| `queue_free()` | End of current frame | Yes | Normal node removal |
| `free()` | Immediate | Only if not inside own signal | Synchronous teardown, editor tools |

Prefer `queue_free()` for nodes created during gameplay. Immediate `free()` makes
later accesses in the current callback or frame invalid, so reserve it for tightly
controlled teardown.

---

## Object Pooling

Calling `instantiate()` and `queue_free()` repeatedly for short-lived objects (bullets, hit effects, particles) is expensive because each cycle allocates and deallocates memory and re-runs `_ready()`. A pool pre-allocates a fixed set of instances and recycles them.

### GDScript Pool

```gdscript
# object_pool.gd
class_name ObjectPool
extends Node

@export var scene: PackedScene
@export var initial_size: int = 20
@export var grow_size: int = 10

var _available: Array[Node2D] = []

func _ready() -> void:
    _grow(initial_size)

## Return an available instance from the pool, growing the pool if needed.
func get_instance() -> Node2D:
    if _available.is_empty():
        push_warning("ObjectPool: pool exhausted, growing by %d" % grow_size)
        _grow(grow_size)
    if _available.is_empty():
        return null
    var instance := _available.pop_back()
    _activate(instance)
    return instance

## Return an instance to the pool by deactivating it.
func release(instance: Node2D) -> void:
    if instance == null or _available.has(instance):
        return
    instance.visible = false
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    instance.global_position = Vector2(-10_000, -10_000)
    _available.append(instance)

# --- private ---

func _grow(count: int) -> void:
    for i in count:
        var created := scene.instantiate()
        if not created is Node2D:
            push_error("ObjectPool scene root must inherit Node2D")
            created.free()
            continue
        var instance := created as Node2D
        add_child(instance)
        release(instance)

func _activate(instance: Node2D) -> void:
    instance.visible = true
    instance.process_mode = Node.PROCESS_MODE_INHERIT
    if instance.has_method("reset_for_pool"):
        instance.call("reset_for_pool")
```

**Usage:**

```gdscript
# bullet_spawner.gd
@onready var _pool: ObjectPool = $BulletPool

func _fire(direction: Vector2) -> void:
    var bullet := _pool.get_instance() as Bullet
    if bullet == null:
        return
    bullet.global_position = $Muzzle.global_position
    bullet.direction = direction
    bullet.speed = 600.0

# In bullet.gd — return self to pool when done
func _on_hit_something() -> void:
    # Do not queue_free — return to pool instead
    _pool.release(self)
```

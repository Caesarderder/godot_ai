# CPU Bottlenecks (Script-Side Hot Paths)

Reference for `skills/godot-optimization/SKILL.md` — GDScript performance patterns: avoiding allocations, StringName, typed arrays, static typing, preload vs load.

> ← Back to [SKILL.md](../SKILL.md)

---


### Avoid Allocations in _process

Allocating new objects (Arrays, Dictionaries, Vector2/3 via constructor, Strings) inside `_process` or `_physics_process` triggers the garbage collector more frequently and creates per-frame heap pressure.

```gdscript
# WRONG — allocates a new Array every frame
func _process(_delta: float) -> void:
    var nearby := get_tree().get_nodes_in_group("enemies")  # new Array each call
    for enemy in nearby:
        _check_aggro(enemy)

# RIGHT — cache the group query result, or use an Area2D overlap list
var _enemies: Array[Node] = []

func _ready() -> void:
    _enemies = get_tree().get_nodes_in_group("enemies")
    get_tree().node_added.connect(_on_node_added)
    get_tree().node_removed.connect(_on_node_removed)

func _on_node_added(node: Node) -> void:
    if node.is_in_group("enemies"):
        _enemies.append(node)

func _on_node_removed(node: Node) -> void:
    _enemies.erase(node)

func _process(_delta: float) -> void:
    for enemy in _enemies:  # no allocation
        _check_aggro(enemy)
```



```gdscript
# WRONG — constructing temporary vectors in a tight loop
func _process(_delta: float) -> void:
    for i in range(100):
        var offset := Vector2(i * 10.0, 0.0)  # 100 allocations per frame
        _draw_marker(position + offset)

# RIGHT — reuse a variable declared outside the loop
var _offset := Vector2.ZERO

func _process(_delta: float) -> void:
    for i in range(100):
        _offset.x = i * 10.0
        _offset.y = 0.0
        _draw_marker(position + _offset)
```



### Use StringName for Comparisons

`StringName` uses interned hashing; comparing two `StringName` values is an O(1) integer comparison. Comparing `String` values is O(n) and allocates temporaries.

```gdscript
# WRONG — String comparison in a hot path
func _on_body_entered(body: Node) -> void:
    if body.name == "Player":  # String comparison
        _start_aggro()

# RIGHT — StringName literal (&"...") is interned at compile time
func _on_body_entered(body: Node) -> void:
    if body.name == &"Player":  # O(1) hash comparison
        _start_aggro()
```



```gdscript
# Cache StringName constants at the class level for repeated use
const ACTION_JUMP := &"jump"
const ACTION_FIRE := &"fire"
const GROUP_ENEMIES := &"enemies"

func _process(_delta: float) -> void:
    if Input.is_action_pressed(ACTION_JUMP):
        _jump()
    if Input.is_action_just_pressed(ACTION_FIRE):
        _fire()
```



### Typed Arrays

Typed arrays (`Array[Node]`, `Array[int]`) skip per-element type checks and allow the VM to use more efficient access paths.

```gdscript
# Untyped — element type checked at every access
var bullets = []

# Typed — no per-element type check; also self-documents intent
var bullets: Array[Bullet] = []

# PackedArrays are the most efficient for value types — stored as contiguous memory
var positions: PackedVector2Array = PackedVector2Array()
var velocities: PackedFloat32Array = PackedFloat32Array()
```



### Static Typing Benefits

Static typing enables the GDScript VM to emit more efficient bytecode and catches errors at parse time rather than runtime.

```gdscript
# Untyped — every operation goes through dynamic dispatch
func move(delta):
    velocity = direction * speed
    position += velocity * delta

# Typed — the compiler knows the exact types, generates faster bytecode
func move(delta: float) -> void:
    velocity = direction * speed
    position += velocity * delta
```

Type inference with `:=` is equivalent to explicit types — use whichever is more readable.

### preload vs load

`preload` resolves the resource path at **parse time** and embeds it into the script binary. `load` resolves at **runtime** and may trigger a disk read (or cache lookup).

```gdscript
# preload — resolved at compile time; safe to use at class scope
const BulletScene: PackedScene = preload("res://scenes/bullet.tscn")
const HitSound: AudioStream = preload("res://audio/hit.ogg")

# load — resolved at runtime; use for dynamic paths or optional resources
func _load_skin(skin_name: String) -> Texture2D:
    return load("res://skins/%s.png" % skin_name)

# WRONG — load() inside _process reads from disk (or cache) every frame
func _process(_delta: float) -> void:
    var tex = load("res://icon.svg")  # repeated runtime resolution
    $Sprite2D.texture = tex

# RIGHT — preload at class scope, assign once in _ready()
const IconTexture: Texture2D = preload("res://icon.svg")

func _ready() -> void:
    $Sprite2D.texture = IconTexture
```

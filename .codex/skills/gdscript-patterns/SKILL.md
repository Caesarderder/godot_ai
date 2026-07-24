---
name: gdscript-patterns
description: Write, repair, or review runtime GDScript for Builda's Godot 4.6.x single-threaded Web projects. Use for typed GDScript, signals and Callables, await/coroutine lifecycle, lambdas, match, exports, class structure, inheritance, runtime object lifetime, Resources, dynamic dispatch, or profiler-confirmed language hot spots. Do not use for C#, newer-engine migration, @tool/editor plugins, threads, or general game architecture when no GDScript language issue is involved.
---

# GDScript Patterns

Use this as the single language-level entry point for Builda projects. Target Godot 4.6.x, GDScript, and the single-threaded Web runtime.

## Runtime boundary

- Write GDScript only. Do not add C# parity examples.
- Use APIs available in Godot 4.6.x. Do not prescribe behavior or migration workarounds from newer engine releases.
- Keep runtime code compatible with the no-threads Web export. Do not use `Thread`, `WorkerThreadPool`, or thread-dependent designs.
- Treat `@tool`, `EditorPlugin`, import plugins, and editor lifecycle as outside this skill.
- Verify project conventions and the concrete node/resource types before changing code.

## Working sequence

1. Inspect the script, its base class, relevant scene ownership, connected signals, and call sites.
2. Identify the language concern: types, initialization, lifetime, async flow, Callable/signal use, collection behavior, or hot-path allocation.
3. Apply the smallest pattern that preserves current behavior.
4. Re-check every boundary crossed by an `await`, deferred call, signal, or shared `Resource`.
5. Parse-check changed scripts with the repository's pinned Godot 4.6 executable when available; then run the smallest relevant scene or project test.

## Organize scripts by responsibility

- Use `snake_case.gd` filenames and directories; use `PascalCase` for `class_name` types and scene
  node names.
- Co-locate a scene script with the feature scene it controls. Name reusable scripts by role, such
  as `health_component.gd`, `spawn_service.gd`, or `item_definition.gd`, rather than generic
  `manager.gd`, `utils.gd`, or `common.gd`.
- Keep one primary responsibility per script. Split by ownership, lifecycle, change reason, reuse,
  or test seam—not by an arbitrary line count.
- Keep `main.gd` limited to top-level composition, scene switching, and application lifecycle. Put
  gameplay, input, physics, UI, save, audio, and asset implementation in their owning scripts.
- Use `class_name` only for a type that needs project-wide identity; private feature scripts can
  remain path-local.

Read [references/script-organization.md](references/script-organization.md) when creating a script,
renaming a type, or deciding whether to split a file.

## 1. Type the contract

Type public state, parameters, return values, signals, node references, and collections. Use inference only when the inferred type is obvious and stable.

```gdscript
signal health_changed(current: int, maximum: int)

const MAX_HEALTH: int = 100

@export_range(0.0, 1000.0, 1.0) var speed: float = 200.0
@onready var sprite: Sprite2D = $Sprite2D

var health: int = MAX_HEALTH
var enemies: Array[Enemy] = []
var inventory: Dictionary[String, int] = {}

func take_damage(amount: int) -> void:
    health = maxi(health - amount, 0)
    health_changed.emit(health, MAX_HEALTH)
```

An empty literal does not infer an element type:

```gdscript
var names: Array[String] = []
var metadata: Dictionary[String, Variant] = {}
```

For an uncertain object type, check before casting. `as` returns `null` on an incompatible object cast.

```gdscript
func _on_body_entered(body: Node2D) -> void:
    if body is Player:
        var player := body as Player
        player.take_damage(10)
```

Do not enable new warning-as-error categories across a legacy project as part of an unrelated fix. Match the repository's existing warning policy.

## 2. Respect initialization order

Member initializers and `_init()` run before the node enters the tree. `@onready` values initialize immediately before that script's `_ready()` body. Child `_ready()` callbacks run before the parent's `_ready()` callback.

```gdscript
@onready var health_bar: ProgressBar = %HealthBar

func _ready() -> void:
    _configure_children()

func _configure_children() -> void:
    health_bar.max_value = max_health
```

Do not read `@onready` members from `_init()` or another member initializer. When a child needs parent-owned state, have the parent call an explicit setup method rather than relying on the parent's `_ready()` having already run.

## 3. Make `await` lifecycle explicit

`await` returns control immediately and resumes later. Every `await` is a lifecycle boundary: the scene may change, nodes referenced before the wait may be freed or leave the tree, and a newer request may supersede the old one.

Keep required values before the boundary and revalidate external objects after it:

```gdscript
func flash_target(target: CanvasItem) -> void:
    if not is_instance_valid(target):
        return

    target.modulate = Color.WHITE
    await get_tree().create_timer(0.15).timeout

    if not is_instance_valid(target) or not target.is_inside_tree():
        return
    target.modulate = Color.RED
```

Do not use `is_instance_valid(self)` as a universal post-`await` fix. The running method already needs a live instance to resume; validate the external objects and scene membership that can change.

Use a generation token when an older async operation must not overwrite newer state:

```gdscript
var _load_generation: int = 0

func show_profile(user_id: String) -> void:
    _load_generation += 1
    var generation := _load_generation
    var profile: Dictionary = await profile_service.fetch_profile(user_id)

    if generation != _load_generation or not is_inside_tree():
        return
    _render_profile(profile)
```

Check the completion precondition before awaiting a signal. GDScript 4.6 has no built-in `Signal.any()` race helper; do not invent one. If an operation needs timeout or cancellation, model that explicitly with one owner that emits a single completion result.

Avoid long initialization awaits inside `_ready()`. Start an explicit async method after synchronous invariants and child setup are established:

```gdscript
func _ready() -> void:
    _initialize_synchronously()
    _load_content()

func _load_content() -> void:
    var data: Dictionary = await content_service.load_content()
    if not is_inside_tree():
        return
    _apply_content(data)
```

Read [references/async-lifecycle.md](references/async-lifecycle.md) when an async path can overlap, be cancelled, outlive a scene, or wait on several possible outcomes.

## 4. Choose signals and Callables deliberately

Use a signal when zero to many listeners may observe an event. Use a direct method for a known owner/child command. Use a `Callable` for an injected strategy, comparator, or deferred callback.

Prefer named methods for durable signal connections:

```gdscript
func _ready() -> void:
    health_component.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, maximum: int) -> void:
    health_bar.value = float(current) / float(maximum)
```

Use lambdas for small local transformations and truly local one-shot callbacks. Local scalar values are captured by value when the lambda is created; reassigning the outer variable does not update the capture. Arrays, dictionaries, and objects still expose shared referenced content.

```gdscript
var threshold: int = 10
var is_large := func(value: int) -> bool: return value >= threshold
threshold = 100
print(is_large.call(20)) # true: the lambda captured 10
```

Use `bind()` when each callback needs a distinct loop value:

```gdscript
var callbacks: Array[Callable] = []
for index in range(5):
    callbacks.append((func(value: int) -> void: print(value)).bind(index))
```

Store a lambda Callable if it must later be disconnected. Signal connections to a freed target object are removed, but referenced containers or long-lived owners can still retain Callables and captured objects.

## 5. Use data-oriented language features

Use `match` when patterns make the accepted shapes clearer, and include a fallback for external or evolving data:

```gdscript
match command:
    ["move", var direction]:
        move(direction)
    {"type": "damage", "amount": var amount}:
        take_damage(amount)
    _:
        push_warning("Unsupported command: %s" % [command])
```

Use typed Resources for designer-authored definitions, but separate shared definitions from per-instance runtime state. Loaded Resource assets are shared by reference.

```gdscript
@export var item_definition: ItemDefinition

var durability: int

func _ready() -> void:
    durability = item_definition.max_durability
```

Duplicate a Resource only when the instance is intentionally mutable and independent; choose whether subresources also need deep duplication.

Use `class_name` for types that genuinely need project-wide visibility. Prefer local script references for private implementation details. Use inner classes for small result/value objects that do not need global registration.

Read these references only when needed:

- [references/export-annotations.md](references/export-annotations.md) for Inspector-facing properties.
- [references/abstract-classes.md](references/abstract-classes.md) for Godot 4.5+ abstract bases.
- [references/variadic-functions.md](references/variadic-functions.md) for Godot 4.5+ rest parameters.
- [references/common-idioms.md](references/common-idioms.md) for collections, formatting, properties, and validity checks.

## 6. Preserve inheritance behavior

When overriding a callback implemented by a script base class, call `super()` if the child extends rather than replaces the base behavior. Do not assume every engine virtual requires `super()`; inspect the actual base implementation.

```gdscript
extends EnemyBase

func _ready() -> void:
    super()
    navigation_agent.velocity_computed.connect(_on_velocity_computed)
```

Read [references/super-in-virtual-methods.md](references/super-in-virtual-methods.md) before changing an inheritance chain.

## 7. Keep dynamic dispatch bounded

Prefer direct typed calls. If a method name and arguments come from save data, network input, mods, or other untrusted content, allowlist the method and validate the complete argument schema before `call()` or `callv()`.

```gdscript
const ALLOWED_ACTIONS: Array[StringName] = [&"take_damage", &"apply_buff"]
const ALLOWED_BUFFS: Array[StringName] = [&"shield", &"haste"]

func dispatch_action(target: Object, action: StringName, args: Array) -> void:
    if not is_instance_valid(target) or action not in ALLOWED_ACTIONS or not target.has_method(action):
        push_warning("Rejected action: %s" % action)
        return

    var normalized_args: Array[Variant] = []
    match action:
        &"take_damage":
            # Damage is an integer protocol field; reject fractional input
            # instead of silently rounding it differently across producers.
            if args.size() != 1 or typeof(args[0]) != TYPE_INT:
                push_warning("Rejected take_damage arguments")
                return
            var amount: int = args[0]
            if amount < 0 or amount > 10_000:
                push_warning("Rejected damage amount")
                return
            normalized_args = [amount]
        &"apply_buff":
            # JSON produces a String, not StringName. Convert only after the
            # string value and numeric duration pass validation.
            if args.size() != 2 or typeof(args[0]) != TYPE_STRING or typeof(args[1]) not in [TYPE_INT, TYPE_FLOAT]:
                push_warning("Rejected apply_buff arguments")
                return
            var buff_id := StringName(String(args[0]))
            var duration := float(args[1])
            if buff_id not in ALLOWED_BUFFS or not is_finite(duration) or duration <= 0.0 or duration > 300.0:
                push_warning("Rejected buff values")
                return
            normalized_args = [buff_id, duration]

    target.callv(action, normalized_args)
```

Use `call_deferred()` for scene-tree mutations that must wait until the idle step, not as a general performance or concurrency primitive.

## 8. Optimize only from evidence

Profile first. In confirmed hot paths:

- Cache stable node references instead of resolving paths each frame.
- Avoid rebuilding Strings, Arrays, and Dictionaries every frame when inputs did not change.
- Prefer `Packed*Array` for large homogeneous engine buffers, not automatically for ordinary gameplay collections.
- Move event-driven UI updates out of `_process()`.
- Use integer vectors for integer domains such as grid coordinates because they express the correct data contract; do not claim an unmeasured speedup.
- Remember that static variables live for the script/engine lifetime, not the current scene.

Read [references/runtime-pitfalls.md](references/runtime-pitfalls.md) for Resource sharing, static lifetime, deferred work, and profiler-driven examples.

## 9. Validate the result

- Parse-check every changed `.gd` file with Godot 4.6.x when the project provides a pinned executable.
- Run the smallest relevant scene or headless test; a parser pass does not validate scene paths, signal wiring, or lifecycle behavior.
- Exercise cancellation or replacement paths for async work.
- Exercise scene reload when static state or shared Resources are involved.
- Exercise the actual Web preview for browser-only behavior; desktop headless success is not Web-runtime proof.

## Checklist

- [ ] Code is GDScript for Godot 4.6.x and does not depend on threads or editor execution.
- [ ] Script and directory names use `snake_case`; node and global type names use `PascalCase`.
- [ ] Each script has one clear owner and primary responsibility; `main.gd` remains a thin
      composition root.
- [ ] Public contracts and collections are typed without forcing unrelated warning-policy changes.
- [ ] Initialization respects child-before-parent `_ready()` order.
- [ ] Every `await` revalidates the external state that can change and handles stale requests where necessary.
- [ ] Signals, direct calls, and Callables match ownership and listener cardinality.
- [ ] Lambda captures follow GDScript's value-capture rules.
- [ ] Shared Resources are not mutated as accidental per-instance state.
- [ ] Dynamic method names are allowlisted, and argument count, types, and value bounds are validated before dispatch.
- [ ] Optimizations are tied to profiler evidence.
- [ ] Godot parse checks and relevant runtime checks pass.

# Dependency wiring recipes

Choose the narrowest recipe matching the dependency lifetime.

## Editor-authored required dependency

Expose a typed reference and validate it at startup with a release-safe path:

```gdscript
class_name WeaponController
extends Node

@export var muzzle: Marker2D
@export var projectile_scene: PackedScene

var _configured := false

func _ready() -> void:
	if muzzle == null or projectile_scene == null:
		push_error("WeaponController requires a muzzle and projectile scene")
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	_configured = true


func fire() -> void:
	if not _configured:
		return
	var projectile := projectile_scene.instantiate() as Node2D
	if projectile == null:
		push_error("WeaponController projectile root must inherit Node2D")
		return
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = muzzle.global_transform
```

This keeps the dependency visible in the Inspector and supports alternate scene
layouts without path guessing. Assertions may supplement this check during
development, but release correctness must not depend on `assert()`.
`PROCESS_MODE_DISABLED` does not block direct method calls or connected signals;
public entries still need the configuration guard shown above. Connect dependency
signals only after validation succeeds, or disconnect them on the failure path.

## Runtime construction

Let the creator complete setup before enabling behavior:

```gdscript
class_name EnemyController
extends Node

var target: Node2D
var _configured := false


func setup(next_target: Node2D) -> void:
	if _configured:
		push_error("EnemyController.setup must run once")
		return
	if next_target == null:
		push_error("EnemyController requires a target")
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	target = next_target
	_configured = true


func _physics_process(_delta: float) -> void:
	if not _configured or not is_instance_valid(target):
		return
	# Move toward target here.
```

```gdscript
if enemy_scene == null or actors == null or not is_instance_valid(player):
	push_error("Enemy creation requires a scene, actors owner, and live player")
	return
var enemy := enemy_scene.instantiate() as Node2D
if enemy == null:
	push_error("Enemy scene root must inherit Node2D")
	return
actors.add_child(enemy)
var controller := enemy.get_node_or_null("EnemyController") as EnemyController
if controller == null:
	push_error("Enemy scene requires an EnemyController child")
	enemy.queue_free()
	return
controller.setup(player)
```

If setup must happen before `_ready()`, assign properties before `add_child()` or make the node inactive until setup completes.

## Parent wires siblings

Sibling discovery belongs in the owner, not inside reusable children:

```gdscript
@onready var health: HealthComponent = %HealthComponent
@onready var receiver: DamageReceiver = %DamageReceiver


func _ready() -> void:
	receiver.setup(health)
	health.depleted.connect(_on_depleted)
```

The receiver must allow owner-driven setup after its own `_ready()` and remain inactive until configured:

```gdscript
var _health: HealthComponent
var _configured := false


func setup(next_health: HealthComponent) -> void:
	if _health != null or next_health == null:
		push_error("DamageReceiver requires one valid setup call")
		return
	_health = next_health
	_configured = true


func receive_damage(amount: int) -> void:
	if not _configured:
		return
	_health.take_damage(amount)
```

Godot calls child `_ready()` methods before the parent's `_ready()`, so do not assert this runtime-injected dependency in the child's `_ready()`. Direct sibling references are acceptable in the scene root because it owns both nodes and documents their relationship.

## Optional collaborator

Make absence part of the contract:

```gdscript
@export var hit_effects: HitEffects


func receive_damage(amount: int) -> void:
	health.take_damage(amount)
	if hit_effects != null:
		hit_effects.play_hit()
```

Do not silently use `get_tree().get_first_node_in_group()` as a fallback for a required dependency. Groups are appropriate for discovering a changing set of peers, not hiding one mandatory collaborator.

## Scene-owned service

Create a session or level service at the nearest common owner and inject it into consumers. This avoids turning short-lived state into an application-wide Autoload and makes scene replacement clean up the service automatically.

## Test seam

Prefer a small behavioral collaborator that can be substituted with a lightweight test node. Inject it through the same property or setup method used in production. Test observable state, emitted signals, and owner reactions; do not require a global registry merely to make tests possible.

Godot does not provide interface types for GDScript nodes. Use a documented method/signal contract and fail early when a required method is absent:

```gdscript
var _clock: Node
var _configured := false


func setup(clock: Node) -> void:
	if clock == null or not clock.has_method("now_seconds"):
		push_error("Clock must implement now_seconds()")
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	_clock = clock
	_configured = true


func now_seconds() -> float:
	if not _configured:
		return 0.0
	return float(_clock.call("now_seconds"))
```

Use this structural contract sparingly. Prefer concrete typed classes when only one implementation is expected.

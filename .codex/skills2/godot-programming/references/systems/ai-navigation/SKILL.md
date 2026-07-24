---
name: ai-navigation
description: Use when implementing Godot 4.6 navigation movement with NavigationRegion2D/3D, NavigationAgent2D/3D, steering, avoidance, and patrol paths
---

# AI Navigation for Godot 4.6 Web

Builda defaults to Godot 4.6.x, GDScript, Compatibility rendering, and a single-threaded Web export. This skill owns movement and path-following only. Decision architecture belongs to **state-machine**; third-party behavior-tree addons are outside the default catalog.

## 1. Establish the Navigation Surface

Use a `NavigationRegion2D` with `NavigationPolygon` or a `NavigationRegion3D` with `NavigationMesh`. Bake static navigation data in the editor whenever possible. Runtime rebakes run on the main thread in the default Web profile, so keep them bounded and schedule them outside active gameplay.

```text
World
├── NavigationRegion2D
│   └── walkable geometry
└── Enemy (CharacterBody2D)
    └── NavigationAgent2D
```

Set matching `navigation_layers` on regions and agents. A mismatch is a common cause of empty paths.

Do not disable navigation servers to trim exports. Builda uses standard export templates, and other scenes or engine features may depend on those servers. Treat export-template customization as platform work outside this skill.

## 2. NavigationAgent2D

```gdscript
extends CharacterBody2D

@export var speed := 120.0
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
    if navigation_agent.avoidance_enabled:
        navigation_agent.velocity_computed.connect(_on_velocity_computed)


func set_target(world_position: Vector2) -> void:
    navigation_agent.target_position = world_position


func _physics_process(_delta: float) -> void:
    var navigation_map := navigation_agent.get_navigation_map()
    if not navigation_map.is_valid() or NavigationServer2D.map_get_iteration_id(navigation_map) == 0:
        if navigation_agent.avoidance_enabled:
            navigation_agent.velocity = Vector2.ZERO
        velocity = Vector2.ZERO
        return

    # This call updates the agent's internal path state; call it before
    # checking whether navigation finished.
    var next_position := navigation_agent.get_next_path_position()
    if navigation_agent.is_navigation_finished():
        if navigation_agent.avoidance_enabled:
            navigation_agent.velocity = Vector2.ZERO
        velocity = Vector2.ZERO
        return

    var direction := global_position.direction_to(next_position)
    var desired_velocity := direction * speed

    if navigation_agent.avoidance_enabled:
        navigation_agent.velocity = desired_velocity
    else:
        velocity = desired_velocity
        move_and_slide()


func _on_velocity_computed(safe_velocity: Vector2) -> void:
    if navigation_agent.is_navigation_finished():
        velocity = Vector2.ZERO
        return
    velocity = safe_velocity
    move_and_slide()
```

Call `get_next_path_position()` every physics tick while following a path. Throttle target updates for moving targets instead of resetting `target_position` every frame.

## 3. NavigationAgent3D

Keep gravity separate from horizontal path velocity:

```gdscript
extends CharacterBody3D

@export var speed := 4.0
@export var gravity := 9.8
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
    if navigation_agent.avoidance_enabled:
        navigation_agent.velocity_computed.connect(_on_velocity_computed)


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    var navigation_map := navigation_agent.get_navigation_map()
    if not navigation_map.is_valid() or NavigationServer3D.map_get_iteration_id(navigation_map) == 0:
        if navigation_agent.avoidance_enabled:
            navigation_agent.velocity = Vector3.ZERO
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    # Query first so the target creates/updates its path after map sync.
    var next_position := navigation_agent.get_next_path_position()
    if navigation_agent.is_navigation_finished():
        if navigation_agent.avoidance_enabled:
            navigation_agent.velocity = Vector3.ZERO
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    var direction := next_position - global_position
    direction.y = 0.0
    direction = direction.normalized()
    var desired_velocity := Vector3(direction.x * speed, 0.0, direction.z * speed)

    if navigation_agent.avoidance_enabled:
        navigation_agent.velocity = desired_velocity
    else:
        velocity = desired_velocity
        move_and_slide()


func _on_velocity_computed(safe_velocity: Vector3) -> void:
    if navigation_agent.is_navigation_finished():
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return
    velocity.x = safe_velocity.x
    velocity.z = safe_velocity.z
    move_and_slide()
```

Connect `velocity_computed` only when avoidance is enabled. Tune `radius`, `max_speed`, and time horizons against the real crowd density; avoidance is not collision detection.

## 4. Steering and Patrol

Steering behaviors produce velocity targets without a navigation mesh. Use them for open-space seek, flee, arrive, or wander movement. See [references/steering-behaviors.md](references/steering-behaviors.md).

For authored patrol routes, use `Marker2D` waypoints plus a `Timer`, and advance the waypoint only after `is_navigation_finished()`. See [references/patrol-patterns.md](references/patrol-patterns.md).

If chase/attack decisions become stateful, keep only target selection and movement in this skill. Route transitions, cooldown ownership, and state lifecycle to **state-machine**; do not build a second FSM here.

## 5. Runtime Rebakes in Single-Thread Web

Prefer edit-time baking. If geometry changes at runtime:

1. Coalesce several geometry edits into one rebake.
2. Pause or gate agents that depend on the affected region.
3. Invoke the synchronous bake during a loading transition or other controlled frame.
4. Resume agents only after the region is ready and verify paths again.

The old async-baking reference is retained only as a compatibility warning: [references/async-baking.md](references/async-baking.md).

## 6. Diagnose Before Changing Code

| Symptom | Check |
|---|---|
| Agent never moves | Region is baked; region and agent layers match; target is reachable |
| Empty path on startup | Wait until the map iteration ID is nonzero; call `get_next_path_position()` before testing completion |
| Jitter at destination | Check `is_navigation_finished()` and tune desired distances |
| Doorway is unreachable | Compare agent radius with the baked corridor width |
| Crowd oscillates | Measure crowd density, then tune avoidance radius, speed, and time horizons |
| Frame hitch after geometry change | Remove repeated rebakes; rebake once at a controlled transition |
| 3D agent floats | Preserve gravity on Y and use navigation only for horizontal direction |

## Checklist

- [ ] Region has a valid baked polygon or mesh before agents request paths.
- [ ] Region and agent `navigation_layers` match.
- [ ] Agent is a child of the moving body; the map iteration is ready before querying, and `get_next_path_position()` runs before the completion check.
- [ ] Moving targets are throttled instead of assigned every frame.
- [ ] Avoidance uses `velocity_computed`; non-avoidance movement calls `move_and_slide()` directly.
- [ ] Runtime rebakes are bounded and scheduled on the single Web main thread.
- [ ] BT and FSM ownership is routed to their dedicated skills rather than copied here.

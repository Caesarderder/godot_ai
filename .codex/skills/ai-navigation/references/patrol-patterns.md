# Patrol Patterns

Reference for `skills/ai-navigation/SKILL.md` — waypoint-chain patrol with wait timers using `NavigationAgent2D`.

> ← Back to [SKILL.md](../SKILL.md)

---

### GDScript

```gdscript
extends CharacterBody2D

@export var waypoints: Array[Marker2D] = []
@export var speed: float = 80.0
@export var wait_time: float = 1.0  # seconds to pause at each waypoint

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var wait_timer: Timer = $WaitTimer

var _current_index: int = 0
var _waiting: bool = false

func _ready() -> void:
	wait_timer.wait_time = wait_time
	wait_timer.one_shot = true
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	await get_tree().physics_frame
	_go_to_current_waypoint()

func _physics_process(_delta: float) -> void:
	if _waiting or waypoints.is_empty():
		return

	var navigation_map := nav_agent.get_navigation_map()
	if not navigation_map.is_valid() or NavigationServer2D.map_get_iteration_id(navigation_map) == 0:
		velocity = Vector2.ZERO
		return

	var next_pos: Vector2 = nav_agent.get_next_path_position()
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		_waiting = true
		wait_timer.start()
		return

	velocity = (next_pos - global_position).normalized() * speed
	move_and_slide()

func _on_wait_timer_timeout() -> void:
	_waiting = false
	_current_index = (_current_index + 1) % waypoints.size()
	_go_to_current_waypoint()

func _go_to_current_waypoint() -> void:
	if waypoints.is_empty():
		return
	nav_agent.target_position = waypoints[_current_index].global_position
```

**Scene setup:** add a `Timer` node named `WaitTimer` as a child. Assign `Marker2D` nodes to the `waypoints` export array in the Inspector.

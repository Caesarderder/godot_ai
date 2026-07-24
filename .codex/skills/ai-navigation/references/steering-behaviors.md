# Steering Behaviors

Reference for `skills/ai-navigation/SKILL.md` — full implementations of seek, flee, arrive, and wander steering behaviors.

> ← Back to [SKILL.md](../SKILL.md)

---

Steering behaviors are lightweight calculations that run every physics frame. Combine them to produce natural-looking movement without a full navigation mesh.

### GDScript

```gdscript
extends CharacterBody2D

@export var speed: float = 120.0
@export var arrive_radius: float = 80.0    # start slowing down at this distance
@export var arrive_stop: float = 8.0       # stop at this distance
@export var wander_angle_change: float = 0.4  # radians per frame max

var _wander_angle: float = 0.0

# ── Seek ────────────────────────────────────────────────────────────────────
# Accelerate toward target at full speed.
func seek(target_pos: Vector2) -> Vector2:
	return (target_pos - global_position).normalized() * speed

# ── Flee ────────────────────────────────────────────────────────────────────
# Accelerate directly away from target at full speed.
func flee(target_pos: Vector2) -> Vector2:
	return (global_position - target_pos).normalized() * speed

# ── Arrive ──────────────────────────────────────────────────────────────────
# Like seek, but smoothly decelerates inside arrive_radius.
func arrive(target_pos: Vector2) -> Vector2:
	var to_target: Vector2 = target_pos - global_position
	var dist: float = to_target.length()
	if dist < arrive_stop:
		return Vector2.ZERO
	var ramped_speed: float = speed * (dist / arrive_radius)
	var clamped_speed: float = minf(ramped_speed, speed)
	return to_target.normalized() * clamped_speed

# ── Wander ──────────────────────────────────────────────────────────────────
# Project a circle ahead of the agent, then jitter a point on its edge.
func wander() -> Vector2:
	var circle_distance: float = 60.0
	var circle_radius: float = 30.0
	_wander_angle += randf_range(-wander_angle_change, wander_angle_change)
	var circle_center: Vector2 = velocity.normalized() * circle_distance
	if circle_center == Vector2.ZERO:
		circle_center = Vector2.RIGHT * circle_distance
	var displacement: Vector2 = Vector2(
		cos(_wander_angle) * circle_radius,
		sin(_wander_angle) * circle_radius
	)
	return (circle_center + displacement).normalized() * speed

# ── Usage example ────────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	# Swap the desired behavior:
	velocity = arrive(get_tree().get_first_node_in_group("player").global_position)
	# velocity = flee(...)
	# velocity = wander()
	move_and_slide()
```

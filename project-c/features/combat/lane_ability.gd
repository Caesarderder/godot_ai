class_name LaneAbility
extends RefCounted

var bolt_cooldown := 0.0
var step_cooldown := 0.0

func reset() -> void:
	bolt_cooldown = 0.0
	step_cooldown = 0.0

func tick(delta: float) -> void:
	bolt_cooldown = maxf(0.0, bolt_cooldown - delta)
	step_cooldown = maxf(0.0, step_cooldown - delta)

func cast_bolt() -> bool:
	if bolt_cooldown > 0.0:
		return false
	bolt_cooldown = 1.1
	return true

func cast_step() -> bool:
	if step_cooldown > 0.0:
		return false
	step_cooldown = 5.0
	return true

func bolt_text() -> String:
	return "READY" if bolt_cooldown <= 0.0 else "%.1fs" % bolt_cooldown

func step_text() -> String:
	return "READY" if step_cooldown <= 0.0 else "%.1fs" % step_cooldown

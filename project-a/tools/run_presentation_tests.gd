extends SceneTree

const BattleWorldScript := preload("res://game/scripts/presentation_3d/battle_world.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_reduced_motion_low_quality()
	await _check_high_quality_budget()
	await _check_cannon_suppressed_feedback()
	await _check_cannon_suppressed_low_reduced_budget()
	_finish()


func _check_reduced_motion_low_quality() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("low", true)
	root.add_child(world)
	await process_frame
	_ok(world.get("_effects_quality") == "low", "low quality is accepted")
	_ok(bool(world.get("_reduced_motion")), "reduced motion flag is stored")
	_ok(int(world.get("_max_high_vfx")) == 2, "low quality caps high-cost effects")
	_ok(int(world.get("_fragment_count")) == 3, "low quality reduces explosion fragments")
	_ok(float(world.get("_shake_scale")) == 0.0, "reduced motion disables shake scale")
	world.call("_add_camera_shake", 1.0, 1.0)
	_ok(float(world.get("_shake_time")) == 0.0, "reduced motion blocks camera shake")
	for _index in range(5):
		world.call("_spawn_explosion", 500, 1)
	_ok(int(world.get("_active_high_vfx")) <= 2, "low quality explosion cap is enforced")
	await _dispose_world(world)


func _check_high_quality_budget() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("high", false)
	root.add_child(world)
	await process_frame
	_ok(world.get("_effects_quality") == "high", "high quality is accepted")
	_ok(int(world.get("_max_high_vfx")) == 8, "high quality raises high-cost effect cap")
	_ok(int(world.get("_fragment_count")) == 14, "high quality raises fragment count")
	world.configure_presentation("invalid", false)
	_ok(world.get("_effects_quality") == "medium", "invalid quality falls back to medium")
	_ok(int(world.get("_max_high_vfx")) == 6, "medium quality restores default cap")
	await _dispose_world(world)


func _check_cannon_suppressed_feedback() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("medium", false)
	root.add_child(world)
	await process_frame
	var events: Array[Dictionary] = [{"type": &"cannon_suppressed", "warning_id": "shell_120"}]
	world.call("_apply_events", events)
	var records: Array = world.get("_presentation_records")
	_ok(records.size() == 1, "cannon_suppressed appends one presentation record")
	if records.size() == 1:
		_eq(records[0]["type"], "cannon_suppressed", "cannon_suppressed record type is testable")
		_eq(records[0]["warning_id"], "shell_120", "cannon_suppressed preserves warning identity")
	var vfx_root := world.get_node("LightweightVFX")
	var feedback := vfx_root.get_node_or_null("CannonSuppressedFeedback")
	_ok(feedback != null, "cannon_suppressed creates feedback node")
	if feedback != null:
		_ok(feedback.get_node_or_null("CyanSuppressionRing") != null, "cannon_suppressed uses cyan suppression ring")
		_ok(feedback.get_node_or_null("PowerCutFlash") != null, "medium quality includes power-cut flash")
	_ok(float(world.get("_shake_time")) > 0.0, "normal motion allows brief suppression shake")
	await _dispose_world(world)


func _check_cannon_suppressed_low_reduced_budget() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("low", true)
	root.add_child(world)
	await process_frame
	var events: Array[Dictionary] = [{"type": &"cannon_suppressed", "warning": "low"}]
	world.call("_apply_events", events)
	var vfx_root := world.get_node("LightweightVFX")
	var feedback := vfx_root.get_node_or_null("CannonSuppressedFeedback")
	_ok(feedback != null, "low reduced cannon_suppressed creates lightweight feedback")
	if feedback != null:
		_ok(feedback.get_child_count() == 1, "low reduced cannon_suppressed only creates one visual child")
		_ok(feedback.get_node_or_null("CyanSuppressionRing") != null, "low reduced cannon_suppressed keeps distinct cyan ring")
		_ok(feedback.get_node_or_null("PowerCutFlash") == null, "low reduced cannon_suppressed skips flash")
	_ok(int(world.get("_active_high_vfx")) <= int(world.get("_max_high_vfx")), "low reduced cannon_suppressed respects high-vfx cap")
	_ok(float(world.get("_shake_time")) == 0.0, "reduced motion keeps cannon_suppressed from shaking camera")
	await _dispose_world(world)


func _dispose_world(world: Node) -> void:
	if is_instance_valid(world):
		if world.has_method("_clear_runtime_views"):
			world.call("_clear_runtime_views")
		world.queue_free()
	for _frame in range(8):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("PRESENTATION TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PRESENTATION TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

extends SceneTree

const BattleWorldScript := preload("res://game/scripts/presentation_3d/battle_world.gd")
const AudioDirectorScript := preload("res://game/scripts/presentation/audio_director.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_audio_asset_pool()
	await _check_reduced_motion_low_quality()
	await _check_high_quality_budget()
	await _check_snapshot_signal_reuse()
	await _check_cannon_suppressed_feedback()
	await _check_cannon_suppressed_low_reduced_budget()
	await _check_cannon_guard_counter_feedback()
	await _check_cannon_guard_counter_low_reduced_budget()
	await _check_structure_breakthrough_feedback()
	await _check_structure_breakthrough_low_reduced_budget()
	_finish()


func _check_audio_asset_pool() -> void:
	var audio := AudioDirectorScript.new()
	root.add_child(audio)
	await process_frame
	_eq(audio.get_child_count(), 8, "audio feedback uses a bounded eight-voice pool")
	for cue_id in [
		&"ui_click", &"build", &"victory", &"defeat",
		&"warning", &"skill", &"hit", &"explosion", &"cannon_suppressed", &"cannon_guard_counter",
	]:
		_ok(audio.has_cue(cue_id), "audio cue is backed by an imported asset: %s" % cue_id)
	for child in audio.get_children():
		var player := child as AudioStreamPlayer
		_ok(player != null and player.name.begins_with("Sfx_"), "audio pool contains only named stream players")
	audio.play_cue(&"ui_click")
	_ok((audio.get("_last_played_msec") as Dictionary).has(&"ui_click"), "first UI gesture schedules an audible cue")
	audio.play_cue(&"missing")
	_ok(not (audio.get("_last_played_msec") as Dictionary).has(&"missing"), "unknown cues fail silently without allocating voices")
	audio.stop_all()
	audio.queue_free()
	for _frame in range(3):
		await process_frame


func _check_reduced_motion_low_quality() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("low", true)
	root.add_child(world)
	await process_frame
	_ok(world.get("_effects_quality") == "low", "low quality is accepted")
	_ok(bool(world.get("_reduced_motion")), "reduced motion flag is stored")
	var environment_node := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_ok(
		environment_node != null
			and environment_node.environment != null
			and environment_node.environment.fog_density <= 0.01,
		"battle fog keeps silhouettes readable"
	)
	_ok(int(world.get("_max_high_vfx")) == 2, "low quality caps high-cost effects")
	_ok(int(world.get("_fragment_count")) == 3, "low quality reduces explosion fragments")
	_ok(float(world.get("_shake_scale")) == 0.0, "reduced motion disables shake scale")
	world.call("_add_camera_shake", 1.0, 1.0)
	_ok(float(world.get("_shake_time")) == 0.0, "reduced motion blocks camera shake")
	var unit_view_script: Script = load("res://game/scripts/presentation_3d/toilet_unit_view.gd")
	var unit_view := unit_view_script.new() as Node3D
	unit_view.call("setup", {
		"unit_id": &"reduced_motion_unit",
		"display_name": "减少动态测试",
		"team": &"ally",
		"slot": 0,
		"hp": 100,
		"max_hp": 100,
		"alive": true,
	})
	world.get_node("AttackingArmy").add_child(unit_view)
	unit_view.call("set_reduced_motion", true)
	unit_view.call("play_battle_event", {
		"type": &"skill_used",
		"unit_id": &"reduced_motion_unit",
		"skill_id": "test_skill",
	})
	unit_view.call("_process", 0.2)
	var body_pivot := unit_view.get_node("BodyPivot") as Node3D
	_eq(body_pivot.position, Vector3.ZERO, "reduced motion removes unit bob and attack lunge")
	_eq(body_pivot.scale, Vector3.ONE, "reduced motion removes unit hit and skill squash")
	world.configure_presentation("low", false)
	world.set("_shake_time", 0.5)
	world.configure_presentation("low", true)
	_ok(float(world.get("_shake_time")) == 0.0, "live reduced-motion toggle clears active camera shake")
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


func _check_snapshot_signal_reuse() -> void:
	var world := BattleWorldScript.new()
	root.add_child(world)
	await process_frame
	world.set_meta("snapshot_signal_count", 0)
	world.battle_snapshot_updated.connect(func(snapshot: Dictionary) -> void:
		world.set_meta("snapshot_signal_count", int(world.get_meta("snapshot_signal_count", 0)) + 1)
		world.set_meta("last_snapshot_tick", int(snapshot.get("tick", -1)))
	)
	world.start_battle([{
		"hero_id": "presentation_signal_hero",
		"display_name": "信号测试角色",
		"archetype_id": "gman",
		"class_id": "guardian",
		"star": 1,
		"max_hp": 200,
		"attack": 40,
		"defense": 15,
		"skill_level": 1,
		"auto_skill": false,
	}])
	_eq(int(world.get_meta("snapshot_signal_count", 0)), 1, "battle start emits the same initial snapshot used by presentation")
	world.call("_process", 0.2)
	_ok(int(world.get_meta("snapshot_signal_count", 0)) >= 2, "each deterministic battle tick emits a reusable HUD snapshot")
	_ok(int(world.get_meta("last_snapshot_tick", -1)) >= 1, "snapshot signal advances with the battle tick")
	world.set_process(false)
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


func _check_cannon_guard_counter_feedback() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("medium", false)
	root.add_child(world)
	await process_frame
	var events: Array[Dictionary] = [{
		"type": &"cannon_guard_counter",
		"warning_id": "shell_guard_120",
		"lane": 2,
		"damage": 60,
	}]
	world.call("_apply_events", events)
	var records: Array = world.get("_presentation_records")
	_ok(records.size() == 1, "guard counter appends one presentation record")
	if records.size() == 1:
		_eq(records[0]["type"], "cannon_guard_counter", "guard counter record type is testable")
		_eq(records[0]["damage"], 60, "guard counter record preserves reflected damage")
	var feedback := world.get_node("LightweightVFX").get_node_or_null("CannonGuardCounterFeedback")
	_ok(feedback != null, "guard counter creates world-space feedback")
	if feedback != null:
		_ok(feedback.get_node_or_null("CyanGuardRing") != null, "guard counter uses a distinct cyan defense ring")
		var label := feedback.get_node_or_null("GuardCounterLabel") as Label3D
		_ok(label != null and label.text.contains("格挡 · 反震 60"), "guard counter names the successful player action without relying on color")
		_ok(feedback.get_node_or_null("CounterImpactFlash") != null, "medium quality shows the reflected core impact")
	_ok(float(world.get("_shake_time")) > 0.0, "normal motion gives guard counter a bounded impact shake")
	await _dispose_world(world)


func _check_cannon_guard_counter_low_reduced_budget() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("low", true)
	root.add_child(world)
	await process_frame
	var events: Array[Dictionary] = [{
		"type": &"cannon_guard_counter",
		"warning_id": "shell_guard_low",
		"lane": 1,
		"damage": 60,
	}]
	world.call("_apply_events", events)
	var feedback := world.get_node("LightweightVFX").get_node_or_null("CannonGuardCounterFeedback")
	_ok(feedback != null, "low reduced guard counter keeps critical feedback")
	if feedback != null:
		_ok(feedback.get_node_or_null("CyanGuardRing") != null, "low reduced guard counter keeps the defense ring")
		_ok(feedback.get_node_or_null("GuardCounterLabel") != null, "low reduced guard counter keeps the semantic label")
		_ok(feedback.get_node_or_null("CounterImpactFlash") == null, "low quality omits the secondary reflected flash")
	_ok(int(world.get("_active_high_vfx")) <= int(world.get("_max_high_vfx")), "guard counter respects the high-vfx cap")
	_ok(float(world.get("_shake_time")) == 0.0, "reduced motion removes guard counter camera shake")
	await _dispose_world(world)


func _check_structure_breakthrough_feedback() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("medium", false)
	root.add_child(world)
	await process_frame
	var events: Array[Dictionary] = [{
		"type": &"structure_destroyed",
		"structure_id": "opening_barricade",
		"display_name": "废弃路障",
		"road_position": 430,
		"lane": 1,
		"kind": "structure",
	}]
	world.call("_apply_events", events)
	var feedback := world.get_node("LightweightVFX").get_node_or_null("StructureBreakthroughFeedback")
	_ok(feedback != null, "destroyed structure creates a bounded breakthrough feedback node")
	if feedback != null:
		var label := feedback.get_node_or_null("BreakthroughLabel") as Label3D
		_ok(label != null and label.text == "防线突破 · 废弃路障", "breakthrough feedback names the completed micro-objective")
		_ok(feedback.get_node_or_null("BreakthroughRing") != null, "medium quality adds one lightweight breakthrough ring")
	var records: Array = world.get("_presentation_records")
	_ok(records.size() == 1 and records[0]["headline"] == "防线突破", "breakthrough feedback appends one testable presentation record")
	await _dispose_world(world)


func _check_structure_breakthrough_low_reduced_budget() -> void:
	var world := BattleWorldScript.new()
	world.configure_presentation("low", true)
	root.add_child(world)
	await process_frame
	var events: Array[Dictionary] = [{
		"type": &"structure_destroyed",
		"structure_id": "alliance_core",
		"display_name": "灰镜核心巨炮",
		"road_position": 1000,
		"lane": 1,
		"kind": "core",
	}]
	world.call("_apply_events", events)
	var feedback := world.get_node("LightweightVFX").get_node_or_null("StructureBreakthroughFeedback")
	_ok(feedback != null, "low reduced mode keeps textual structure completion feedback")
	if feedback != null:
		var label := feedback.get_node_or_null("BreakthroughLabel") as Label3D
		_ok(label != null and label.text == "核心摧毁 · 灰镜核心巨炮", "core completion remains understandable without motion or color alone")
		_ok(feedback.get_child_count() == 1, "low reduced mode omits the optional breakthrough ring")
	_ok(float(world.get("_shake_time")) == 0.0, "reduced motion suppresses destruction shake while preserving text")
	await _dispose_world(world)


func _dispose_world(world: Node) -> void:
	if is_instance_valid(world):
		if world.has_method("_clear_runtime_views"):
			world.call("_clear_runtime_views")
		world.queue_free()
	for _frame in range(8):
		await process_frame
	await create_timer(0.08).timeout


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

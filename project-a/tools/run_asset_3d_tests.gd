extends SceneTree

const ToiletUnitViewScript := preload("res://game/scripts/presentation_3d/toilet_unit_view.gd")

const ARCHETYPES: Array[String] = [
	"assault",
	"sonic",
	"rocket",
	"bomber",
	"armored",
	"saw",
	"repair",
	"parasite",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for archetype_id in ARCHETYPES:
		await _check_ally_archetype(archetype_id)
	await _check_gman_toilet_model()
	await _check_camera_enemy_model()
	await _check_enemy_fallback()
	_finish()


func _snapshot(archetype_id: String, team: int) -> Dictionary:
	return {
		"unit_id": StringName("%s_%d" % [archetype_id, team]),
		"team": team,
		"slot": 0,
		"hp": 100,
		"max_hp": 100,
		"lane": 1,
		"road_position": 0,
		"alive": true,
		"class_id": "fighter",
		"archetype_id": archetype_id,
		"display_name": archetype_id,
		"elite": false,
	}


func _check_ally_archetype(archetype_id: String) -> void:
	var view := ToiletUnitViewScript.new()
	root.add_child(view)
	view.setup(_snapshot(archetype_id, 0))
	await process_frame
	var body_pivot := view.get_node_or_null("BodyPivot")
	_ok(body_pivot != null, "%s creates BodyPivot" % archetype_id)
	if body_pivot != null:
		var external := body_pivot.get_node_or_null("ExternalModel_%s" % archetype_id)
		_ok(external != null, "%s instantiates external GLB" % archetype_id)
		if external != null:
			_ok(_mesh_count(external) > 0, "%s external GLB contains meshes" % archetype_id)
		var procedural_base := body_pivot.get_node_or_null("Base") as VisualInstance3D
		_ok(procedural_base != null and not procedural_base.visible, "%s hides procedural fallback" % archetype_id)
		var name_label := body_pivot.get_node_or_null("NameLabel") as Label3D
		var health_label := body_pivot.get_node_or_null("HealthLabel") as Label3D
		_ok(name_label != null and name_label.font_size >= 60 and name_label.pixel_size < 0.003, "%s uses a high-resolution world-space name label" % archetype_id)
		_ok(health_label != null and health_label.font_size >= 52 and health_label.pixel_size < 0.003, "%s uses a high-resolution world-space health label" % archetype_id)
	view.queue_free()
	await process_frame


func _check_gman_toilet_model() -> void:
	var view := ToiletUnitViewScript.new()
	root.add_child(view)
	view.setup(_snapshot("gman", 0))
	await process_frame
	var body_pivot := view.get_node_or_null("BodyPivot")
	_ok(body_pivot != null, "gman creates BodyPivot")
	if body_pivot != null:
		_ok(body_pivot.get_node_or_null("ExternalModel_gman") == null, "gman does not use an external surveillance-unit model")
		var procedural_base := body_pivot.get_node_or_null("Base") as VisualInstance3D
		var procedural_bowl := body_pivot.get_node_or_null("Bowl") as VisualInstance3D
		var procedural_head := body_pivot.get_node_or_null("Head") as VisualInstance3D
		_ok(
			procedural_base != null and procedural_base.visible
			and procedural_bowl != null and procedural_bowl.visible
			and procedural_head != null and procedural_head.visible,
			"gman keeps the procedural toilet-person model visible"
		)
	view.queue_free()
	await process_frame


func _check_camera_enemy_model() -> void:
	var view := ToiletUnitViewScript.new()
	root.add_child(view)
	view.setup(_snapshot("camera_trooper", 1))
	await process_frame
	var body_pivot := view.get_node_or_null("BodyPivot")
	_ok(body_pivot != null, "camera enemy creates BodyPivot")
	if body_pivot != null:
		var external := body_pivot.get_node_or_null("ExternalEnemyModel_camera_trooper")
		_ok(external != null, "camera enemy instantiates the cameraman GLB")
		if external != null:
			_ok(_mesh_count(external) > 0, "camera enemy GLB contains meshes")
		var procedural_base := body_pivot.get_node_or_null("Base") as VisualInstance3D
		_ok(procedural_base != null and not procedural_base.visible, "camera enemy hides the procedural toilet fallback")
	view.queue_free()
	await process_frame


func _check_enemy_fallback() -> void:
	var view := ToiletUnitViewScript.new()
	root.add_child(view)
	view.setup(_snapshot("assault", 1))
	await process_frame
	var body_pivot := view.get_node_or_null("BodyPivot")
	_ok(body_pivot != null, "enemy creates BodyPivot")
	if body_pivot != null:
		_ok(body_pivot.get_node_or_null("ExternalModel_assault") == null, "enemy does not use ally GLB")
		var procedural_base := body_pivot.get_node_or_null("Base") as VisualInstance3D
		_ok(procedural_base != null and procedural_base.visible, "enemy keeps procedural fallback visible")
	view.queue_free()
	await process_frame


func _mesh_count(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _mesh_count(child)
	return count


func _finish() -> void:
	if failures.is_empty():
		print("ASSET 3D TESTS PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("ASSET 3D TESTS FAIL: %d failure(s)" % failures.size())
	quit(1)


func _ok(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

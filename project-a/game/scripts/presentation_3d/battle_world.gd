class_name BattleWorld
extends Node3D

signal battle_finished(result: Dictionary)

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const ToiletUnitViewScript := preload("res://game/scripts/presentation_3d/toilet_unit_view.gd")
const TICK_SECONDS: float = 0.2

var _session: RefCounted
var _unit_views: Dictionary = {}
var _structure_views: Dictionary = {}
var _units_root: Node3D
var _structures_root: Node3D
var _vfx_root: Node3D
var _camera: Camera3D
var _accumulator: float = 0.0
var _battle_paused: bool = false
var _finish_emitted: bool = false
var _camera_progress: float = 0.0


func _ready() -> void:
	_build_world_once()
	set_process(false)


func start_battle(hero_snapshots: Array) -> void:
	_build_world_once()
	_clear_runtime_views()
	_session = BattleSessionScript.new()
	_session.start(hero_snapshots)
	_accumulator = 0.0
	_battle_paused = false
	_finish_emitted = false
	_camera_progress = 0.0
	_sync_views(_session.snapshot())
	set_process(true)


func request_skill(unit_id: StringName) -> bool:
	return false if _session == null else _session.request_skill(unit_id)


func set_auto_skill(unit_id: StringName, enabled: bool) -> bool:
	return false if _session == null else _session.set_auto_skill(unit_id, enabled)


func snapshot() -> Dictionary:
	return {} if _session == null else _session.snapshot()


func get_battle_snapshot() -> Dictionary:
	return snapshot()


func set_paused(value: bool) -> void:
	_battle_paused = value


func _process(delta: float) -> void:
	if _session == null:
		return
	_update_camera(delta)
	if _battle_paused or _session.is_finished:
		return
	_accumulator += minf(delta, 0.5)
	var safety_ticks := 0
	while _accumulator >= TICK_SECONDS and safety_ticks < 5:
		_accumulator -= TICK_SECONDS
		safety_ticks += 1
		var events: Array[Dictionary] = _session.advance_tick()
		_apply_events(events)
		_sync_views(_session.snapshot())
		if _session.is_finished:
			set_process(true)
			if not _finish_emitted:
				_finish_emitted = true
				battle_finished.emit(_session.result.duplicate(true))
			break


func _build_world_once() -> void:
	if _units_root != null:
		return
	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#151d29")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#a9bdd0")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "OvercastSun"
	sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	sun.light_color = Color("#e5dfd2")
	sun.light_energy = 1.0
	sun.shadow_enabled = false
	add_child(sun)

	_camera = Camera3D.new()
	_camera.name = "BattleCamera"
	_camera.fov = 48.0
	_camera.current = true
	add_child(_camera)

	var stage := Node3D.new()
	stage.name = "CityAvenue"
	add_child(stage)
	_build_stage(stage)

	_structures_root = Node3D.new()
	_structures_root.name = "AllianceBaseModules"
	add_child(_structures_root)
	_units_root = Node3D.new()
	_units_root.name = "AttackingArmy"
	add_child(_units_root)
	_vfx_root = Node3D.new()
	_vfx_root.name = "LightweightVFX"
	add_child(_vfx_root)


func _build_stage(stage: Node3D) -> void:
	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()
	road_mesh.size = Vector3(12.0, 0.18, 38.0)
	road.mesh = road_mesh
	road.position = Vector3(0.0, -0.12, -3.0)
	road.material_override = _material(Color("#303943"), 0.96)
	stage.add_child(road)
	for side in [-1.0, 1.0]:
		var sidewalk := MeshInstance3D.new()
		var sidewalk_mesh := BoxMesh.new()
		sidewalk_mesh.size = Vector3(3.2, 0.28, 38.0)
		sidewalk.mesh = sidewalk_mesh
		sidewalk.position = Vector3(side * 7.55, -0.04, -3.0)
		sidewalk.material_override = _material(Color("#59616a"), 0.94)
		stage.add_child(sidewalk)
	for marker in range(11):
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(0.16, 0.03, 1.45)
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(0.0, 0.0, 12.0 - float(marker) * 3.0)
		stripe.material_override = _material(Color("#cabd82"), 0.85)
		stage.add_child(stripe)
	for index in range(12):
		var building := MeshInstance3D.new()
		var building_mesh := BoxMesh.new()
		building_mesh.size = Vector3(2.3, 3.0 + float(index % 4), 2.5)
		building.mesh = building_mesh
		var side := -1.0 if index % 2 == 0 else 1.0
		building.position = Vector3(side * 8.2, building_mesh.size.y * 0.5, 11.0 - float(index / 2) * 5.5)
		building.material_override = _material(Color("#414c58"), 0.9)
		stage.add_child(building)


func _sync_views(battle_snapshot: Dictionary) -> void:
	for structure_value in battle_snapshot.get("structures", []):
		var structure := structure_value as Dictionary
		var structure_id: StringName = structure["structure_id"]
		var structure_view: Node3D = _structure_views.get(structure_id)
		if structure_view == null:
			structure_view = _create_structure_view(structure)
			_structures_root.add_child(structure_view)
			_structure_views[structure_id] = structure_view
		_apply_structure_snapshot(structure_view, structure)

	for unit_value in battle_snapshot.get("units", []):
		var unit := unit_value as Dictionary
		_sync_unit_view(unit)
	for enemy_value in battle_snapshot.get("enemies", []):
		var enemy := enemy_value as Dictionary
		_sync_unit_view(enemy)


func _apply_events(events: Array[Dictionary]) -> void:
	for event in events:
		var event_type: StringName = event.get("type", &"")
		if event_type in [&"attack_started", &"attack_hit", &"unit_damaged", &"enemy_damaged", &"skill_used", &"unit_healed", &"unit_shielded", &"unit_revived"]:
			var unit: Node = _unit_views.get(event.get("unit_id", &""))
			if unit != null:
				unit.play_battle_event(event)
			var target_unit: Node = _unit_views.get(event.get("target_id", &""))
			if target_unit != null:
				target_unit.play_battle_event(event)
			var enemy_unit: Node = _unit_views.get(event.get("enemy_id", &""))
			if enemy_unit != null:
				enemy_unit.play_battle_event(event)
		if event_type == &"structure_damaged":
			var structure: Node3D = _structure_views.get(event.get("structure_id", &""))
			if structure != null:
				_pulse_structure(structure)
		elif event_type == &"explosion":
			_spawn_explosion(int(event.get("road_position", 500)), int(event.get("lane", 1)))
		elif event_type == &"artillery_warning":
			_spawn_warning(int(event.get("lane", 1)))


func _sync_unit_view(unit: Dictionary) -> void:
	var unit_id: StringName = unit["unit_id"]
	var view: Node3D = _unit_views.get(unit_id)
	if view == null:
		view = ToiletUnitViewScript.new()
		_units_root.add_child(view)
		view.setup(unit)
		_unit_views[unit_id] = view
	view.apply_snapshot(unit)


func _create_structure_view(data: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Structure_%s" % String(data["structure_id"])
	root.position = _world_position(int(data["road_position"]), int(data["lane"]))
	var kind := String(data["kind"])
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := BoxMesh.new()
	if kind == "core":
		mesh.size = Vector3(7.0, 4.8, 3.4)
	elif kind in ["turret", "battery"]:
		mesh.size = Vector3(2.0, 3.2, 2.0)
	else:
		mesh.size = Vector3(7.5, 2.8 if kind == "armored" else 1.5, 1.4)
	body.mesh = mesh
	body.position.y = mesh.size.y * 0.5
	body.material_override = _material(
		Color("#6f7780") if kind != "core" else Color("#4b5969"),
		0.78
	)
	root.add_child(body)
	if kind in ["turret", "battery", "core"]:
		var barrel := MeshInstance3D.new()
		var barrel_mesh := CylinderMesh.new()
		barrel_mesh.height = 3.8 if kind == "core" else 2.0
		barrel_mesh.top_radius = 0.28 if kind == "core" else 0.16
		barrel_mesh.bottom_radius = barrel_mesh.top_radius
		barrel_mesh.radial_segments = 8
		barrel.mesh = barrel_mesh
		barrel.rotation_degrees.x = 90.0
		barrel.position = Vector3(0.0, mesh.size.y + 0.15, 0.7)
		barrel.material_override = _material(Color("#bd5548"), 0.55)
		root.add_child(barrel)
	var label := Label3D.new()
	label.name = "Status"
	label.text = String(data["display_name"])
	label.position = Vector3(0.0, mesh.size.y + 1.0, 0.0)
	label.font_size = 28
	label.outline_size = 7
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)
	return root


func _apply_structure_snapshot(view: Node3D, data: Dictionary) -> void:
	var label := view.get_node("Status") as Label3D
	label.text = "%s  %d/%d" % [data["display_name"], data["hp"], data["max_hp"]]
	if not bool(data["alive"]):
		view.scale.y = 0.18
		view.rotation_degrees.z = 8.0
		label.text = "%s · 已摧毁" % data["display_name"]
		label.modulate = Color("#ff865f")
	elif int(data.get("damage_stage", 0)) >= 2:
		label.text += " · 危急"
		label.modulate = Color("#ff775f")
		(view.get_node("Body") as MeshInstance3D).rotation_degrees.z = 4.0
	elif int(data.get("damage_stage", 0)) == 1:
		label.text += " · 受损"
		label.modulate = Color("#ffc05f")


func _pulse_structure(view: Node3D) -> void:
	var tween := view.create_tween()
	tween.tween_property(view, "scale", Vector3(1.08, 0.92, 1.08), 0.06)
	tween.tween_property(view, "scale", Vector3.ONE, 0.12)


func _spawn_explosion(road_position: int, lane: int) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	sphere.radial_segments = 8
	sphere.rings = 4
	flash.mesh = sphere
	flash.position = _world_position(road_position, lane) + Vector3(0.0, 1.2, 0.0)
	var material := _material(Color("#ff9b36"), 0.25)
	material.emission_enabled = true
	material.emission = Color("#ff6a24")
	material.emission_energy_multiplier = 2.3
	flash.material_override = material
	_vfx_root.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3(4.0, 4.0, 4.0), 0.22)
	tween.parallel().tween_property(flash, "transparency", 1.0, 0.22)
	tween.tween_callback(flash.queue_free)


func _spawn_warning(lane: int) -> void:
	var marker := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.15
	cylinder.bottom_radius = 1.15
	cylinder.height = 0.025
	cylinder.radial_segments = 16
	marker.mesh = cylinder
	marker.position = _world_position(865, lane) + Vector3(0.0, 0.05, 0.0)
	var material := _material(Color("#ff3e35"), 0.4)
	material.emission_enabled = true
	material.emission = Color("#ff3328")
	material.emission_energy_multiplier = 1.4
	marker.material_override = material
	_vfx_root.add_child(marker)
	var tween := marker.create_tween()
	tween.set_loops(3)
	tween.tween_property(marker, "scale", Vector3(1.5, 1.0, 1.5), 0.22)
	tween.tween_property(marker, "scale", Vector3(0.8, 1.0, 0.8), 0.22)
	tween.finished.connect(marker.queue_free)


func _update_camera(delta: float) -> void:
	var desired_progress := 0.0
	if _session != null:
		desired_progress = float(_session.snapshot().get("road_progress", 0))
	_camera_progress = lerpf(_camera_progress, desired_progress, minf(1.0, delta * 2.0))
	var focus := _world_position(int(_camera_progress + 95.0), 1)
	_camera.look_at_from_position(focus + Vector3(10.5, 8.5, 11.5), focus + Vector3(0.0, 1.0, -3.5))


func _world_position(road_position: int, lane: int) -> Vector3:
	return Vector3((float(lane) - 1.0) * 2.15, 0.0, 12.0 - float(road_position) * 0.03)


func _clear_runtime_views() -> void:
	for root in [_units_root, _structures_root, _vfx_root]:
		for child in root.get_children():
			root.remove_child(child)
			child.queue_free()
	_unit_views.clear()
	_structure_views.clear()


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

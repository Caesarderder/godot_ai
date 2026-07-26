class_name BattleWorld
extends Node3D

signal battle_finished(result: Dictionary)
signal battle_snapshot_updated(snapshot: Dictionary)

const BattleSessionScript := preload("res://game/scripts/domain/battle/battle_session.gd")
const ToiletUnitViewScript := preload("res://game/scripts/presentation_3d/toilet_unit_view.gd")
const AudioDirectorScript := preload("res://game/scripts/presentation/audio_director.gd")
const CJK_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const TICK_SECONDS: float = 0.2

var _session: RefCounted
var _unit_views: Dictionary = {}
var _structure_views: Dictionary = {}
var _units_root: Node3D
var _structures_root: Node3D
var _vfx_root: Node3D
var _atmosphere_root: Node3D
var _audio: AudioDirector
var _camera: Camera3D
var _accumulator: float = 0.0
var _battle_paused: bool = false
var _finish_emitted: bool = false
var _camera_progress: float = 0.0
var _shake_time: float = 0.0
var _shake_intensity: float = 0.0
var _active_high_vfx: int = 0
var _active_smoke_nodes: int = 0
var _effects_quality: String = "medium"
var _reduced_motion: bool = false
var _max_high_vfx: int = 6
var _max_smoke_nodes: int = 12
var _fragment_count: int = 10
var _spark_count: int = 6
var _smoke_puffs: int = 3
var _shake_scale: float = 1.0
var _flash_scale: float = 1.0
var _motion_scale: float = 1.0
var _presentation_records: Array[Dictionary] = []


func _ready() -> void:
	_build_world_once()
	set_process(false)


func start_battle(hero_snapshots: Array, stage_id: String = "", stage_config: Dictionary = {}) -> void:
	_build_world_once()
	_clear_runtime_views()
	_session = BattleSessionScript.new()
	if stage_id.is_empty():
		_session.start(hero_snapshots)
	else:
		_session.start(hero_snapshots, stage_id, stage_config)
	_accumulator = 0.0
	_battle_paused = false
	_finish_emitted = false
	_camera_progress = 0.0
	_apply_stage_atmosphere(stage_config)
	var initial_snapshot := _session.call("snapshot") as Dictionary
	_sync_views(initial_snapshot)
	battle_snapshot_updated.emit(initial_snapshot)
	set_process(true)


func configure_presentation(effects_quality: String = "medium", reduced_motion: bool = false) -> void:
	_effects_quality = _normalized_effects_quality(effects_quality)
	_reduced_motion = reduced_motion
	match _effects_quality:
		"low":
			_max_high_vfx = 2
			_max_smoke_nodes = 4
			_fragment_count = 3
			_spark_count = 3
			_smoke_puffs = 1
			_shake_scale = 0.45
			_flash_scale = 0.68
			_motion_scale = 0.72
		"high":
			_max_high_vfx = 8
			_max_smoke_nodes = 16
			_fragment_count = 14
			_spark_count = 8
			_smoke_puffs = 4
			_shake_scale = 1.15
			_flash_scale = 1.15
			_motion_scale = 1.0
		_:
			_max_high_vfx = 6
			_max_smoke_nodes = 12
			_fragment_count = 10
			_spark_count = 6
			_smoke_puffs = 3
			_shake_scale = 1.0
			_flash_scale = 1.0
			_motion_scale = 1.0
	if _reduced_motion:
		_max_high_vfx = mini(_max_high_vfx, 3)
		_max_smoke_nodes = mini(_max_smoke_nodes, 6)
		_fragment_count = mini(_fragment_count, 4)
		_spark_count = mini(_spark_count, 3)
		_smoke_puffs = mini(_smoke_puffs, 2)
		_shake_scale = 0.0
		_flash_scale = minf(_flash_scale, 0.55)
		_motion_scale = minf(_motion_scale, 0.45)
		_shake_time = 0.0
		_shake_intensity = 0.0
	for view_value in _unit_views.values():
		var view := view_value as Node
		if view != null and view.has_method("set_reduced_motion"):
			view.call("set_reduced_motion", _reduced_motion)


func request_skill(unit_id: StringName) -> bool:
	return false if _session == null else _session.request_skill(unit_id)


func set_auto_skill(unit_id: StringName, enabled: bool) -> bool:
	return false if _session == null else _session.set_auto_skill(unit_id, enabled)


func request_retreat() -> bool:
	if _session == null or not _session.retreat():
		return false
	var current_snapshot := _session.call("snapshot") as Dictionary
	_sync_views(current_snapshot)
	battle_snapshot_updated.emit(current_snapshot)
	if not _finish_emitted:
		_finish_emitted = true
		battle_finished.emit(_session.result.duplicate(true))
	return true


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
		var current_snapshot := _session.call("snapshot") as Dictionary
		_sync_views(current_snapshot)
		battle_snapshot_updated.emit(current_snapshot)
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
	environment.background_color = Color("#111827")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8a9caf")
	environment.ambient_light_energy = 0.58
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("#5b6470")
	environment.fog_light_energy = 0.26
	environment.fog_density = 0.01
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "OvercastSun"
	sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	sun.light_color = Color("#d2c2a8")
	sun.light_energy = 0.82
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

	_atmosphere_root = Node3D.new()
	_atmosphere_root.name = "WarAtmosphere"
	add_child(_atmosphere_root)
	_build_distant_base(_atmosphere_root)
	_build_far_war_markers(_atmosphere_root)

	_structures_root = Node3D.new()
	_structures_root.name = "AllianceBaseModules"
	add_child(_structures_root)
	_units_root = Node3D.new()
	_units_root.name = "AttackingArmy"
	add_child(_units_root)
	_vfx_root = Node3D.new()
	_vfx_root.name = "LightweightVFX"
	add_child(_vfx_root)

	_audio = AudioDirectorScript.new()
	_audio.name = "AudioDirector"
	add_child(_audio)


func _build_stage(stage: Node3D) -> void:
	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()
	road_mesh.size = Vector3(12.0, 0.18, 38.0)
	road.mesh = road_mesh
	road.position = Vector3(0.0, -0.12, -3.0)
	road.material_override = _material(Color("#28323d"), 0.96)
	stage.add_child(road)
	for side in [-1.0, 1.0]:
		var sidewalk := MeshInstance3D.new()
		var sidewalk_mesh := BoxMesh.new()
		sidewalk_mesh.size = Vector3(3.2, 0.28, 38.0)
		sidewalk.mesh = sidewalk_mesh
		sidewalk.position = Vector3(side * 7.55, -0.04, -3.0)
		sidewalk.material_override = _material(Color("#48515b"), 0.94)
		stage.add_child(sidewalk)
	for marker in range(11):
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(0.16, 0.03, 1.45)
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(0.0, 0.0, 12.0 - float(marker) * 3.0)
		stripe.material_override = _material(Color("#a79554"), 0.85)
		stage.add_child(stripe)
	for crater_index in range(9):
		var crater := MeshInstance3D.new()
		var crater_mesh := CylinderMesh.new()
		crater_mesh.top_radius = 0.42 + float(crater_index % 3) * 0.16
		crater_mesh.bottom_radius = crater_mesh.top_radius
		crater_mesh.height = 0.035
		crater_mesh.radial_segments = 12
		crater.mesh = crater_mesh
		crater.position = Vector3(
			float((crater_index % 3) - 1) * 2.6 + (0.35 if crater_index % 2 == 0 else -0.25),
			0.025,
			10.5 - float(crater_index) * 3.8
		)
		crater.scale.z = 0.58
		crater.rotation_degrees.y = float(crater_index * 31)
		crater.material_override = _material(Color("#171b20"), 1.0)
		stage.add_child(crater)
	for index in range(12):
		var building := MeshInstance3D.new()
		var building_mesh := BoxMesh.new()
		building_mesh.size = Vector3(2.3, 3.0 + float(index % 4), 2.5)
		building.mesh = building_mesh
		var side := -1.0 if index % 2 == 0 else 1.0
		building.position = Vector3(side * 8.2, building_mesh.size.y * 0.5, 11.0 - float(index / 2) * 5.5)
		building.rotation_degrees.z = float((index % 3) - 1) * 1.8
		building.material_override = _material(Color("#34414d").lightened(float(index % 4) * 0.035), 0.9)
		stage.add_child(building)
		if index % 3 == 0:
			_add_fire_window(stage, building.position + Vector3(side * -0.08, building_mesh.size.y * 0.28, -1.28))
	for rubble_index in range(18):
		var rubble := MeshInstance3D.new()
		var rubble_mesh := BoxMesh.new()
		rubble_mesh.size = Vector3(0.25 + float(rubble_index % 4) * 0.08, 0.12, 0.22 + float(rubble_index % 5) * 0.05)
		rubble.mesh = rubble_mesh
		var side := -1.0 if rubble_index % 2 == 0 else 1.0
		rubble.position = Vector3(side * (4.2 + float(rubble_index % 3) * 0.75), 0.08, 10.5 - float(rubble_index) * 1.85)
		rubble.rotation_degrees = Vector3(0.0, float(rubble_index * 37), float((rubble_index % 5) - 2) * 5.0)
		rubble.material_override = _material(Color("#5f6467").darkened(float(rubble_index % 3) * 0.06), 0.98)
		stage.add_child(rubble)
	for lamp_index in range(8):
		var side := -1.0 if lamp_index % 2 == 0 else 1.0
		_add_street_lamp(stage, Vector3(side * 5.7, 0.0, 10.0 - float(lamp_index) * 4.3), side, lamp_index)


func _build_distant_base(root: Node3D) -> void:
	var base_z := -18.2
	var base_body := _box_node("DistantAllianceBase", Vector3(11.0, 5.2, 2.2), Color("#2d3642"), 0.78)
	base_body.position = Vector3(0.0, 2.6, base_z)
	root.add_child(base_body)
	for side in [-1.0, 1.0]:
		var tower := _box_node("DistantBattery", Vector3(2.0, 4.0, 2.0), Color("#3a4350"), 0.7)
		tower.position = Vector3(side * 4.2, 2.0, base_z + 0.3)
		root.add_child(tower)
	var cannon := MeshInstance3D.new()
	var cannon_mesh := CylinderMesh.new()
	cannon_mesh.height = 5.6
	cannon_mesh.top_radius = 0.34
	cannon_mesh.bottom_radius = 0.42
	cannon_mesh.radial_segments = 10
	cannon.mesh = cannon_mesh
	cannon.rotation_degrees.x = 88.0
	cannon.position = Vector3(0.0, 4.15, base_z + 1.45)
	cannon.material_override = _emissive_material(Color("#6c3430"), Color("#ff5a30"), 0.8, 0.62)
	root.add_child(cannon)
	var beacon := MeshInstance3D.new()
	var beacon_mesh := SphereMesh.new()
	beacon_mesh.radius = 0.28
	beacon_mesh.height = 0.42
	beacon_mesh.radial_segments = 8
	beacon_mesh.rings = 4
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.0, 5.45, base_z + 1.0)
	beacon.material_override = _emissive_material(Color("#ff6f3c"), Color("#ff4c24"), 2.0, 0.35)
	root.add_child(beacon)
	if not _reduced_motion:
		var pulse := beacon.create_tween()
		pulse.set_loops()
		pulse.tween_property(beacon, "scale", Vector3(1.35, 1.35, 1.35), 0.55)
		pulse.tween_property(beacon, "scale", Vector3.ONE, 0.55)


func _build_far_war_markers(root: Node3D) -> void:
	for index in range(5):
		var smoke := _smoke_column(2.0 + float(index % 3) * 0.7)
		smoke.position = Vector3(-9.5 + float(index) * 4.7, 0.0, -15.0 - float(index % 2) * 2.8)
		root.add_child(smoke)


func _apply_stage_atmosphere(stage_config: Dictionary) -> void:
	var environment_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if environment_node == null or environment_node.environment == null:
		return
	var chapter := int(stage_config.get("chapter", 1))
	var heat := clampf(float(chapter - 1) / 4.0, 0.0, 1.0)
	var environment := environment_node.environment
	environment.background_color = Color("#111827").lerp(Color("#2a1f20"), heat)
	environment.ambient_light_color = Color("#8a9caf").lerp(Color("#b38662"), heat * 0.72)
	environment.ambient_light_energy = lerpf(0.58, 0.46, heat)
	environment.fog_light_color = Color("#5b6470").lerp(Color("#7c5142"), heat)
	for child in get_children():
		if child is DirectionalLight3D and child.name == "OvercastSun":
			var sun := child as DirectionalLight3D
			sun.light_color = Color("#d2c2a8").lerp(Color("#ffb066"), heat)
			sun.light_energy = lerpf(0.82, 0.66, heat)


func _add_fire_window(root: Node3D, at_position: Vector3) -> void:
	var fire := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.42, 0.28, 0.04)
	fire.mesh = mesh
	fire.position = at_position
	fire.material_override = _emissive_material(Color("#d85b2a"), Color("#ff8b36"), 1.25, 0.45)
	root.add_child(fire)
	if not _reduced_motion:
		var tween := fire.create_tween()
		tween.set_loops()
		tween.tween_property(fire, "scale", Vector3(1.15, 0.88, 1.0), 0.28)
		tween.tween_property(fire, "scale", Vector3(0.86, 1.12, 1.0), 0.34)


func _add_street_lamp(root: Node3D, at_position: Vector3, side: float, index: int) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.035
	pole_mesh.bottom_radius = 0.045
	pole_mesh.height = 2.2
	pole_mesh.radial_segments = 6
	pole.mesh = pole_mesh
	pole.position = at_position + Vector3(0.0, 1.1, 0.0)
	pole.rotation_degrees.z = side * float(index % 3) * 4.0
	pole.material_override = _material(Color("#252b31"), 0.86)
	root.add_child(pole)
	var head := _box_node("LampHead", Vector3(0.5, 0.08, 0.18), Color("#ff9b4a"), 0.5, Color("#ff7026"), 0.85)
	head.position = at_position + Vector3(side * -0.28, 2.1, -0.06)
	root.add_child(head)


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
		if event_type == &"skill_used":
			_spawn_skill_vfx(event)
			_play_audio(&"skill", -12.0, 0.92 + float(int(event.get("skill_tier", 1))) * 0.08)
			_add_camera_shake(0.08, 0.06)
		elif event_type in [&"unit_healed", &"unit_revived"]:
			_play_audio(&"heal", -13.0, 1.0)
		elif event_type == &"unit_shielded":
			_play_audio(&"shield", -13.0, 0.92)
		elif event_type in [&"attack_hit", &"enemy_damaged"]:
			_play_audio(&"hit", -18.0, 0.9 + randf() * 0.25)
		if event_type == &"structure_damaged":
			var structure: Node3D = _structure_views.get(event.get("structure_id", &""))
			if structure != null:
				_pulse_structure(structure)
				if bool(event.get("is_skill", false)):
					_spawn_sparks(structure.global_position + Vector3(0.0, 1.2, 0.0), Color("#ffcf7a"))
		elif event_type == &"explosion":
			_spawn_explosion(int(event.get("road_position", 500)), int(event.get("lane", 1)))
		elif event_type == &"artillery_warning":
			_spawn_warning(int(event.get("lane", 1)), int(event.get("impact_tick", 0)))
		elif event_type == &"cannon_suppressed":
			_spawn_cannon_suppressed(event)
		elif event_type == &"cannon_guard_counter":
			_spawn_cannon_guard_counter(event)
		elif event_type == &"structure_destroyed":
			_play_audio(&"collapse", -8.0, 0.82)
			_add_camera_shake(0.34, 0.22)
			_spawn_structure_breakthrough(event)


func _sync_unit_view(unit: Dictionary) -> void:
	var unit_id: StringName = unit["unit_id"]
	var view: Node3D = _unit_views.get(unit_id)
	if view == null:
		view = ToiletUnitViewScript.new()
		_units_root.add_child(view)
		view.setup(unit)
		_unit_views[unit_id] = view
	if view.has_method("set_reduced_motion"):
		view.call("set_reduced_motion", _reduced_motion)
	view.apply_snapshot(unit)


func _create_structure_view(data: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Structure_%s" % String(data["structure_id"])
	root.position = _world_position(int(data["road_position"]), int(data["lane"]))
	var kind := String(data["kind"])
	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := BoxMesh.new()
	if kind == "city":
		mesh.size = Vector3(9.0, 5.2, 4.8)
	elif kind == "core":
		mesh.size = Vector3(7.0, 4.8, 3.4)
	elif kind in ["turret", "battery"]:
		mesh.size = Vector3(2.0, 3.2, 2.0)
	else:
		mesh.size = Vector3(7.5, 2.8 if kind == "armored" else 1.5, 1.4)
	body.mesh = mesh
	body.position.y = mesh.size.y * 0.5
	body.material_override = _material(
		Color("#7b858d") if kind == "city" else (Color("#6f7780") if kind != "core" else Color("#4b5969")),
		0.78
	)
	root.add_child(body)
	if kind == "city":
		for tower_index in range(3):
			var tower := _box_node(
				"CityTower_%d" % tower_index,
				Vector3(1.7, 2.4 + float(tower_index) * 0.7, 1.6),
				Color("#59636d"),
				0.82
			)
			tower.position = Vector3(float(tower_index - 1) * 2.5, mesh.size.y + tower.scale.y, 0.0)
			root.add_child(tower)
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
	var damage_group := Node3D.new()
	damage_group.name = "DamageState"
	root.add_child(damage_group)
	for index in range(5):
		var fragment := _box_node("DamageFragment_%d" % index, Vector3(0.34, 0.16, 0.24), Color("#2f3439"), 0.96)
		fragment.position = Vector3(float(index - 2) * 0.58, 0.16 + float(index % 2) * 0.1, 0.78 + float(index % 3) * 0.18)
		fragment.rotation_degrees = Vector3(0.0, float(index * 31), float(index * 13))
		damage_group.add_child(fragment)
	var fire := MeshInstance3D.new()
	fire.name = "DamageFire"
	var fire_mesh := SphereMesh.new()
	fire_mesh.radius = 0.22
	fire_mesh.height = 0.36
	fire_mesh.radial_segments = 8
	fire_mesh.rings = 4
	fire.mesh = fire_mesh
	fire.position = Vector3(0.0, mesh.size.y + 0.4, 0.4)
	fire.material_override = _emissive_material(Color("#e15f29"), Color("#ff7a2b"), 1.6, 0.4)
	damage_group.add_child(fire)
	damage_group.hide()
	var label := Label3D.new()
	label.name = "Status"
	label.text = String(data["display_name"])
	label.position = Vector3(0.0, mesh.size.y + 1.0, 0.0)
	label.font_size = 60
	label.pixel_size = 0.00235
	label.outline_size = 12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)
	return root


func _apply_structure_snapshot(view: Node3D, data: Dictionary) -> void:
	var label := view.get_node("Status") as Label3D
	label.text = "%s  %d/%d" % [data["display_name"], data["hp"], data["max_hp"]]
	var body := view.get_node("Body") as MeshInstance3D
	var damage_group := view.get_node_or_null("DamageState") as Node3D
	if damage_group != null:
		damage_group.visible = int(data.get("damage_stage", 0)) >= 1 or not bool(data["alive"])
	if not bool(data["alive"]):
		view.scale.y = lerpf(view.scale.y, 0.2, 0.55)
		view.rotation_degrees.z = 8.0
		label.text = "%s · 已摧毁" % data["display_name"]
		label.modulate = Color("#ff865f")
		body.rotation_degrees.z = 10.0
		body.material_override = _material(Color("#24282d"), 0.96)
	elif int(data.get("damage_stage", 0)) >= 2:
		label.text += " · 危急"
		label.modulate = Color("#ff775f")
		body.rotation_degrees.z = 4.0
		body.material_override = _material(Color("#51433f"), 0.9, Color("#ff6633"), 0.25)
	elif int(data.get("damage_stage", 0)) == 1:
		label.text += " · 受损"
		label.modulate = Color("#ffc05f")
		body.rotation_degrees.z = 1.5


func _pulse_structure(view: Node3D) -> void:
	if _reduced_motion:
		view.scale = Vector3.ONE
		return
	var tween := view.create_tween()
	tween.tween_property(view, "scale", Vector3(1.08, 0.92, 1.08), 0.06)
	tween.tween_property(view, "scale", Vector3.ONE, 0.12)


func _spawn_explosion(road_position: int, lane: int) -> void:
	if _active_high_vfx >= _max_high_vfx:
		return
	_active_high_vfx += 1
	_play_audio(&"explosion", -7.0, 0.82 + randf() * 0.16)
	_add_camera_shake(0.24, 0.18)
	var origin := _world_position(road_position, lane) + Vector3(0.0, 0.18, 0.0)
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	sphere.radial_segments = 8
	sphere.rings = 4
	flash.mesh = sphere
	flash.position = origin + Vector3(0.0, 1.0, 0.0)
	var material := _emissive_material(Color("#ffb348"), Color("#ff6924"), 2.9 * _flash_scale, 0.25)
	flash.material_override = material
	_vfx_root.add_child(flash)
	var shockwave := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.62
	ring.outer_radius = 0.72
	ring.rings = 18
	ring.ring_segments = 4
	shockwave.mesh = ring
	shockwave.position = origin + Vector3(0.0, 0.16, 0.0)
	shockwave.material_override = _emissive_material(Color("#ffdc99"), Color("#ff8138"), 1.15 * _flash_scale, 0.34)
	_vfx_root.add_child(shockwave)
	for index in range(_fragment_count):
		var fragment := _box_node("BlastFragment_%d" % index, Vector3(0.11, 0.08, 0.16), Color("#604334"), 0.9)
		fragment.position = origin + Vector3(0.0, 0.4, 0.0)
		_vfx_root.add_child(fragment)
		var spread_count := maxi(1, _fragment_count)
		var direction := Vector3(cos(float(index) * TAU / float(spread_count)), 0.55 + float(index % 3) * 0.16, sin(float(index) * TAU / float(spread_count))).normalized()
		var fragment_tween := fragment.create_tween()
		fragment_tween.tween_property(fragment, "position", fragment.position + direction * (1.2 + float(index % 4) * 0.28) * _motion_scale, 0.28)
		fragment_tween.parallel().tween_property(fragment, "rotation_degrees", Vector3(index * 29, index * 41, index * 53) * _motion_scale, 0.28)
		fragment_tween.tween_callback(fragment.queue_free)
	_spawn_smoke(origin + Vector3(0.0, 0.55, 0.0), 1.1)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3(3.3, 2.3, 3.3) * _flash_scale, 0.18)
	tween.parallel().tween_property(flash, "transparency", 1.0, 0.16 if _reduced_motion else 0.22)
	tween.tween_callback(flash.queue_free)
	var wave_tween := shockwave.create_tween()
	wave_tween.tween_property(shockwave, "scale", Vector3(3.8, 0.15, 3.8) * _flash_scale, 0.18 if _reduced_motion else 0.22)
	wave_tween.parallel().tween_property(shockwave, "transparency", 1.0, 0.16 if _reduced_motion else 0.22)
	wave_tween.tween_callback(shockwave.queue_free)
	tween.finished.connect(func() -> void: _active_high_vfx = maxi(0, _active_high_vfx - 1))


func _spawn_structure_breakthrough(event: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "StructureBreakthroughFeedback"
	root.position = _world_position(
		int(event.get("road_position", 500)),
		int(event.get("lane", 1))
	) + Vector3(0.0, 4.0, 0.0)
	_vfx_root.add_child(root)
	var kind := String(event.get("kind", "structure"))
	var headline := "防线突破"
	if kind == "city":
		headline = "城市攻陷"
	elif kind == "core":
		headline = "核心摧毁"
	var label := Label3D.new()
	label.name = "BreakthroughLabel"
	label.text = "%s · %s" % [
		headline,
		String(event.get("display_name", "防御结构")),
	]
	label.font = CJK_FONT
	label.font_size = 54
	label.pixel_size = 0.012
	label.outline_size = 14
	label.modulate = Color("#ffd37a")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)
	if not _reduced_motion and _effects_quality != "low":
		var ring_node := MeshInstance3D.new()
		ring_node.name = "BreakthroughRing"
		var ring := TorusMesh.new()
		ring.inner_radius = 0.72
		ring.outer_radius = 0.82
		ring.rings = 18
		ring.ring_segments = 4
		ring_node.mesh = ring
		ring_node.rotation_degrees.x = 90.0
		ring_node.position.y = -1.5
		ring_node.material_override = _emissive_material(
			Color("#ffd37a"),
			Color("#ff9f43"),
			1.3 * _flash_scale,
			0.3
		)
		root.add_child(ring_node)
	var record := {
		"type": "structure_breakthrough",
		"structure_id": String(event.get("structure_id", "")),
		"headline": headline,
		"display_name": String(event.get("display_name", "")),
	}
	_presentation_records.append(record)
	var duration := 0.55 if _reduced_motion else 0.9
	var tween := root.create_tween()
	if not _reduced_motion:
		tween.tween_property(root, "position:y", root.position.y + 0.65, duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	var active_ring := root.get_node_or_null("BreakthroughRing") as MeshInstance3D
	if active_ring != null:
		tween.parallel().tween_property(active_ring, "scale", Vector3(2.8, 2.8, 2.8), duration)
		tween.parallel().tween_property(active_ring, "transparency", 1.0, duration)
	tween.tween_callback(root.queue_free)


func _spawn_warning(lane: int, impact_tick: int = 0) -> void:
	_play_audio(&"warning", -12.0, 0.82)
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
	material.emission_energy_multiplier = 1.4 * _flash_scale
	marker.material_override = material
	_vfx_root.add_child(marker)
	var tween := marker.create_tween()
	tween.set_loops(1 if _reduced_motion else (2 if _effects_quality == "low" else 3))
	var warning_scale := lerpf(1.0, 1.5, _motion_scale)
	tween.tween_property(marker, "scale", Vector3(warning_scale, 1.0, warning_scale), 0.22)
	tween.tween_property(marker, "scale", Vector3(0.9, 1.0, 0.9), 0.22)
	tween.finished.connect(marker.queue_free)
	_spawn_shell_trail(marker.position, impact_tick)


func _spawn_cannon_suppressed(event: Dictionary) -> void:
	_presentation_records.append({
		"type": "cannon_suppressed",
		"warning_id": String(event.get("warning_id", "")),
		"effects_quality": _effects_quality,
		"reduced_motion": _reduced_motion,
	})
	_play_audio(&"cannon_suppressed", -11.0, 1.0)
	if _active_high_vfx >= _max_high_vfx:
		return
	_active_high_vfx += 1
	_add_camera_shake(0.12, 0.07)
	var root := Node3D.new()
	root.name = "CannonSuppressedFeedback"
	root.position = Vector3(0.0, 4.25, -17.15)
	_vfx_root.add_child(root)

	var ring_node := MeshInstance3D.new()
	ring_node.name = "CyanSuppressionRing"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.72
	ring.outer_radius = 0.84
	ring.rings = 18 if _effects_quality != "low" else 12
	ring.ring_segments = 5 if _effects_quality != "low" else 4
	ring_node.mesh = ring
	ring_node.rotation_degrees.x = 90.0
	ring_node.material_override = _emissive_material(Color("#bff7ff"), Color("#75efff"), 1.65 * _flash_scale, 0.28)
	root.add_child(ring_node)

	var flash: MeshInstance3D = null
	if _effects_quality != "low":
		flash = MeshInstance3D.new()
		flash.name = "PowerCutFlash"
		var flash_mesh := SphereMesh.new()
		flash_mesh.radius = 0.42
		flash_mesh.height = 0.7
		flash_mesh.radial_segments = 8
		flash_mesh.rings = 4
		flash.mesh = flash_mesh
		flash.position = Vector3(0.0, 0.18, 0.0)
		flash.material_override = _emissive_material(Color("#e8fdff"), Color("#8ff7ff"), 2.2 * _flash_scale, 0.2)
		root.add_child(flash)

	var spark_total := 0 if _effects_quality == "low" else mini(_spark_count, 4)
	for index in range(spark_total):
		var spark := _box_node("SuppressionArc_%d" % index, Vector3(0.05, 0.05, 0.46), Color("#d6fbff"), 0.32, Color("#8ff7ff"), 1.1 * _flash_scale)
		var angle := float(index) * TAU / float(maxi(1, spark_total))
		spark.position = Vector3(cos(angle) * 0.38, 0.08, sin(angle) * 0.38)
		spark.rotation_degrees = Vector3(0.0, rad_to_deg(angle), 18.0)
		root.add_child(spark)
		if not _reduced_motion:
			var spark_tween := spark.create_tween()
			spark_tween.tween_property(spark, "position", spark.position * 2.0, 0.18)
			spark_tween.parallel().tween_property(spark, "transparency", 1.0, 0.18)

	var duration := 0.18 if _reduced_motion else 0.28
	var final_scale := Vector3.ONE * lerpf(1.25, 2.6, _motion_scale)
	var tween := root.create_tween()
	tween.tween_property(root, "scale", final_scale, duration)
	tween.parallel().tween_property(ring_node, "transparency", 1.0, duration)
	if flash != null:
		tween.parallel().tween_property(flash, "transparency", 1.0, duration)
	tween.tween_callback(root.queue_free)
	tween.finished.connect(func() -> void: _active_high_vfx = maxi(0, _active_high_vfx - 1))


func _spawn_cannon_guard_counter(event: Dictionary) -> void:
	_presentation_records.append({
		"type": "cannon_guard_counter",
		"warning_id": String(event.get("warning_id", "")),
		"damage": int(event.get("damage", 0)),
		"effects_quality": _effects_quality,
		"reduced_motion": _reduced_motion,
	})
	_play_audio(&"cannon_guard_counter", -9.0, 1.18)
	if _active_high_vfx >= _max_high_vfx:
		return
	_active_high_vfx += 1
	_add_camera_shake(0.16, 0.1)
	var root := Node3D.new()
	root.name = "CannonGuardCounterFeedback"
	# Critical confirmation sits above the dense base silhouette so mobile
	# players can read their successful timing without losing the action lane.
	root.position = _world_position(865, int(event.get("lane", 1))) + Vector3(0.0, 3.2, 0.0)
	_vfx_root.add_child(root)

	var guard_ring := MeshInstance3D.new()
	guard_ring.name = "CyanGuardRing"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.78
	ring.outer_radius = 0.94
	ring.rings = 14 if _effects_quality == "low" else 20
	ring.ring_segments = 4 if _effects_quality == "low" else 6
	guard_ring.mesh = ring
	guard_ring.rotation_degrees.x = 90.0
	guard_ring.material_override = _emissive_material(
		Color("#d9fbff"), Color("#64e8ff"), 1.8 * _flash_scale, 0.24
	)
	root.add_child(guard_ring)

	var result_label := Label3D.new()
	result_label.name = "GuardCounterLabel"
	result_label.text = "格挡 · 反震 %d" % int(event.get("damage", 0))
	result_label.position = Vector3(0.0, -1.15, 0.0)
	result_label.font = CJK_FONT
	result_label.font_size = 72
	result_label.pixel_size = 0.013
	result_label.outline_size = 14
	result_label.modulate = Color("#d9fbff")
	result_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	result_label.no_depth_test = true
	root.add_child(result_label)

	var counter_flash: MeshInstance3D = null
	if _effects_quality != "low":
		counter_flash = MeshInstance3D.new()
		counter_flash.name = "CounterImpactFlash"
		var flash_mesh := SphereMesh.new()
		flash_mesh.radius = 0.34
		flash_mesh.height = 0.58
		flash_mesh.radial_segments = 8
		flash_mesh.rings = 4
		counter_flash.mesh = flash_mesh
		counter_flash.position = Vector3(0.0, 0.0, -1.0)
		counter_flash.material_override = _emissive_material(
			Color("#fff0bd"), Color("#ffb44f"), 2.1 * _flash_scale, 0.22
		)
		root.add_child(counter_flash)

	var duration := 0.24 if _reduced_motion else 0.42
	var final_scale := Vector3.ONE * lerpf(1.15, 2.15, _motion_scale)
	var tween := root.create_tween()
	tween.tween_property(root, "scale", final_scale, duration)
	tween.parallel().tween_property(guard_ring, "transparency", 1.0, duration)
	if counter_flash != null:
		tween.parallel().tween_property(counter_flash, "transparency", 1.0, duration)
	tween.tween_interval(0.22)
	tween.tween_property(result_label, "modulate:a", 0.0, 0.15)
	tween.tween_callback(root.queue_free)
	tween.finished.connect(func() -> void: _active_high_vfx = maxi(0, _active_high_vfx - 1))


func _spawn_shell_trail(target_position: Vector3, impact_tick: int) -> void:
	var shell := MeshInstance3D.new()
	var shell_mesh := SphereMesh.new()
	shell_mesh.radius = 0.11
	shell_mesh.height = 0.2
	shell_mesh.radial_segments = 8
	shell_mesh.rings = 4
	shell.mesh = shell_mesh
	shell.position = Vector3(0.0, 5.6, -17.0)
	shell.material_override = _emissive_material(Color("#ffb45c"), Color("#ff6f2d"), 2.1, 0.28)
	_vfx_root.add_child(shell)
	var trail := MeshInstance3D.new()
	var trail_mesh := CylinderMesh.new()
	trail_mesh.height = 1.7
	trail_mesh.top_radius = 0.035
	trail_mesh.bottom_radius = 0.08
	trail_mesh.radial_segments = 6
	trail.mesh = trail_mesh
	trail.rotation_degrees.x = 90.0
	trail.position = shell.position + Vector3(0.0, -0.2, 0.65)
	trail.material_override = _emissive_material(Color("#d96535"), Color("#ff7d38"), 0.9 * _flash_scale, 0.42)
	_vfx_root.add_child(trail)
	var flight_time := 1.25
	if _session != null and impact_tick > 0:
		flight_time = clampf(float(impact_tick - int(_session.snapshot().get("tick", 0))) * TICK_SECONDS, 0.65, 1.6)
	if _reduced_motion:
		flight_time = minf(flight_time, 0.75)
	var tween := shell.create_tween()
	tween.tween_property(shell, "position", target_position + Vector3(0.0, 1.4, 0.0), flight_time)
	tween.tween_callback(shell.queue_free)
	var trail_tween := trail.create_tween()
	trail_tween.tween_property(trail, "position", target_position + Vector3(0.0, 1.2, 0.0), flight_time)
	trail_tween.parallel().tween_property(trail, "transparency", 1.0, flight_time)
	trail_tween.tween_callback(trail.queue_free)


func _spawn_skill_vfx(event: Dictionary) -> void:
	var unit := _unit_views.get(event.get("unit_id", &"")) as Node3D
	if unit == null:
		return
	var skill_id := String(event.get("skill_id", ""))
	var origin := unit.global_position + Vector3(0.0, 1.55, 0.0)
	match skill_id:
		"plunger_charge":
			_spawn_dash_streak(origin, Color("#71dfff"))
		"sonic_disruptor":
			_spawn_pulse_ring(origin, Color("#7ee2ff"), 2.2)
		"rocket_salvo":
			_spawn_projectile_arc(origin, origin + Vector3(0.0, 1.2, -4.0), Color("#ff9d48"))
		"suicide_dive":
			_spawn_dash_streak(origin, Color("#ff784e"))
			_add_camera_shake(0.14, 0.12)
		"siege_shield":
			_spawn_pulse_ring(origin, Color("#8df5bd"), 1.4)
		"saw_rush":
			_spawn_sparks(origin, Color("#f5d575"))
		"field_repair":
			_spawn_pulse_ring(origin, Color("#77f2a2"), 1.2)
		"parasite_swarm":
			_spawn_pulse_ring(origin, Color("#b489ff"), 1.7)
		_:
			_spawn_pulse_ring(origin, Color("#ffffff"), 1.0)


func _spawn_dash_streak(origin: Vector3, color: Color) -> void:
	var streak := _box_node("SkillStreak", Vector3(0.18, 0.08, 2.0), color, 0.35, color, 1.4)
	streak.position = origin + Vector3(0.0, -0.25, -0.7)
	_vfx_root.add_child(streak)
	var tween := streak.create_tween()
	tween.tween_property(streak, "position:z", streak.position.z - 1.5 * _motion_scale, 0.16)
	tween.parallel().tween_property(streak, "transparency", 1.0, 0.16)
	tween.tween_callback(streak.queue_free)


func _spawn_pulse_ring(origin: Vector3, color: Color, final_scale: float) -> void:
	var pulse := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.5
	ring.rings = 16
	ring.ring_segments = 5
	pulse.mesh = ring
	pulse.position = origin
	pulse.material_override = _emissive_material(color, color, 1.2 * _flash_scale, 0.35)
	_vfx_root.add_child(pulse)
	var tween := pulse.create_tween()
	var scaled_final := lerpf(1.0, final_scale, _motion_scale)
	tween.tween_property(pulse, "scale", Vector3(scaled_final, scaled_final, scaled_final), 0.18 if _reduced_motion else 0.26)
	tween.parallel().tween_property(pulse, "transparency", 1.0, 0.18 if _reduced_motion else 0.26)
	tween.tween_callback(pulse.queue_free)


func _spawn_projectile_arc(origin: Vector3, target: Vector3, color: Color) -> void:
	var projectile := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.radial_segments = 8
	mesh.rings = 4
	projectile.mesh = mesh
	projectile.position = origin
	projectile.material_override = _emissive_material(color, color, 1.8 * _flash_scale, 0.32)
	_vfx_root.add_child(projectile)
	var tween := projectile.create_tween()
	tween.tween_property(projectile, "position", (origin + target) * 0.5 + Vector3(0.0, 2.0 * _motion_scale, 0.0), 0.14)
	tween.tween_property(projectile, "position", origin.lerp(target, _motion_scale), 0.16)
	tween.tween_callback(projectile.queue_free)


func _spawn_sparks(origin: Vector3, color: Color) -> void:
	for index in range(_spark_count):
		var spark := _box_node("Spark_%d" % index, Vector3(0.06, 0.06, 0.34), color, 0.38, color, 1.2)
		spark.position = origin
		_vfx_root.add_child(spark)
		var spread_count := maxi(1, _spark_count)
		var dir := Vector3(cos(float(index) * TAU / float(spread_count)), 0.2 + float(index % 2) * 0.24, sin(float(index) * TAU / float(spread_count))).normalized()
		var tween := spark.create_tween()
		tween.tween_property(spark, "position", origin + dir * 0.95 * _motion_scale, 0.18)
		tween.parallel().tween_property(spark, "transparency", 1.0, 0.18)
		tween.tween_callback(spark.queue_free)


func _spawn_smoke(origin: Vector3, scale_factor: float) -> void:
	if _active_smoke_nodes >= _max_smoke_nodes:
		return
	_active_smoke_nodes += 1
	var smoke := _smoke_column(scale_factor)
	smoke.position = origin
	_vfx_root.add_child(smoke)
	var tween := smoke.create_tween()
	smoke.scale = Vector3(0.2, 0.2, 0.2)
	tween.tween_property(smoke, "scale", Vector3.ONE * _motion_scale, 0.22 if _reduced_motion else 0.35)
	tween.tween_interval(0.8 if _reduced_motion else (1.2 if _effects_quality == "low" else 1.8))
	tween.tween_callback(smoke.queue_free)
	tween.finished.connect(func() -> void: _active_smoke_nodes = maxi(0, _active_smoke_nodes - 1))


func _smoke_column(scale_factor: float) -> Node3D:
	var root := Node3D.new()
	root.name = "SmokeColumn"
	for index in range(_smoke_puffs):
		var puff := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = (0.38 + float(index) * 0.18) * scale_factor
		mesh.height = (0.58 + float(index) * 0.22) * scale_factor
		mesh.radial_segments = 8
		mesh.rings = 4
		puff.mesh = mesh
		puff.position = Vector3(float(index - 1) * 0.22 * scale_factor, 0.4 + float(index) * 0.55 * scale_factor, 0.0)
		puff.material_override = _transparent_material(Color(0.08, 0.085, 0.09, 0.5), 1.0)
		root.add_child(puff)
	return root


func _update_camera(delta: float) -> void:
	var desired_progress := 0.0
	if _session != null:
		desired_progress = float(_session.snapshot().get("road_progress", 0))
	_camera_progress = lerpf(_camera_progress, desired_progress, minf(1.0, delta * 2.0))
	var focus := _world_position(int(_camera_progress + 95.0), 1)
	var camera_position := focus + Vector3(10.5, 8.5, 11.5)
	if _shake_time > 0.0:
		_shake_time = maxf(0.0, _shake_time - delta)
		var amount := _shake_intensity * (_shake_time + 0.05)
		camera_position += Vector3(
			sin(Time.get_ticks_msec() * 0.039) * amount,
			cos(Time.get_ticks_msec() * 0.047) * amount * 0.55,
			sin(Time.get_ticks_msec() * 0.033) * amount
		)
	else:
		_shake_intensity = 0.0
	_camera.look_at_from_position(camera_position, focus + Vector3(0.0, 1.0, -3.5))


func _world_position(road_position: int, lane: int) -> Vector3:
	return Vector3((float(lane) - 1.0) * 2.15, 0.0, 12.0 - float(road_position) * 0.03)


func _clear_runtime_views() -> void:
	for root in [_units_root, _structures_root, _vfx_root]:
		for child in root.get_children():
			root.remove_child(child)
			child.queue_free()
	_unit_views.clear()
	_structure_views.clear()
	_presentation_records.clear()
	_active_high_vfx = 0
	_active_smoke_nodes = 0


func _add_camera_shake(duration: float, intensity: float) -> void:
	if _reduced_motion or _shake_scale <= 0.0:
		_shake_time = 0.0
		_shake_intensity = 0.0
		return
	_shake_time = maxf(_shake_time, duration * _shake_scale)
	_shake_intensity = maxf(_shake_intensity, intensity * _shake_scale)


func _play_audio(cue_id: StringName, volume_db: float, pitch_scale: float = 1.0) -> void:
	if _audio != null:
		_audio.play_cue(cue_id, volume_db, pitch_scale)


func _box_node(node_name: String, size: Vector3, color: Color, roughness: float, emission: Color = Color.TRANSPARENT, emission_energy: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _material(color, roughness, emission, emission_energy)
	return node


func _material(color: Color, roughness: float, emission: Color = Color.TRANSPARENT, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


func _emissive_material(color: Color, emission: Color, energy: float, roughness: float) -> StandardMaterial3D:
	return _material(color, roughness, emission, energy)


func _transparent_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := _material(color, roughness)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _normalized_effects_quality(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	if normalized in ["low", "medium", "high"]:
		return normalized
	return "medium"

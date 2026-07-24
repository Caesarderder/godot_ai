class_name ToiletUnitView
extends Node3D

const TEAM_ALLY: int = 0

static var _shared_meshes: Dictionary = {}
static var _shared_materials: Dictionary = {}

var unit_id: StringName = &""
var team: int = TEAM_ALLY
var slot: int = 0

var _body_pivot: Node3D
var _name_label: Label3D
var _hp_label: Label3D
var _anim_time: float = 0.0
var _attack_pulse: float = 0.0
var _hit_pulse: float = 0.0
var _is_alive: bool = true
var _target_position: Vector3 = Vector3.ZERO


func setup(unit_snapshot: Dictionary) -> void:
	unit_id = unit_snapshot.get("unit_id", &"")
	team = int(unit_snapshot.get("team", TEAM_ALLY))
	slot = int(unit_snapshot.get("slot", 0))
	name = "Unit_%s" % String(unit_id)
	_ensure_shared_resources()
	_build_model(unit_snapshot)
	apply_snapshot(unit_snapshot)
	set_process(true)


func apply_snapshot(unit_snapshot: Dictionary) -> void:
	if _hp_label == null:
		return
	var hp := int(unit_snapshot.get("hp", 0))
	var max_hp := maxi(1, int(unit_snapshot.get("max_hp", 1)))
	_hp_label.text = "%d / %d" % [hp, max_hp]
	_hp_label.modulate = Color("#75e69b") if hp * 2 > max_hp else Color("#ffb15c")
	var lane := int(unit_snapshot.get("lane", slot % 3))
	var road_position := int(unit_snapshot.get("road_position", 0))
	_target_position = Vector3((float(lane) - 1.0) * 2.15, 0.0, 12.0 - float(road_position) * 0.03)
	if position == Vector3.ZERO:
		position = _target_position
	var shield := int(unit_snapshot.get("shield", 0))
	_hp_label.text += "  ◆%d" % shield if shield > 0 else ""
	_is_alive = bool(unit_snapshot.get("alive", true))
	if not _is_alive:
		_body_pivot.rotation_degrees.z = -78.0 if team == TEAM_ALLY else 78.0
		_body_pivot.position.y = 0.12
		set_process(false)
		show()
	else:
		show()


func play_battle_event(event: Dictionary) -> void:
	var event_type: StringName = event.get("type", &"")
	if event_type == &"attack_started" and event.get("unit_id", &"") == unit_id:
		_attack_pulse = 1.0
	elif event_type in [&"attack_hit", &"unit_damaged"] and event.get("unit_id", &"") == unit_id:
		_hit_pulse = 1.0
	elif event_type == &"enemy_damaged" and event.get("enemy_id", &"") == unit_id:
		_hit_pulse = 1.0
	elif event_type == &"skill_used" and event.get("unit_id", &"") == unit_id:
		_attack_pulse = 1.6
	elif event_type in [&"unit_healed", &"unit_shielded", &"unit_revived"] and event.get("unit_id", &"") == unit_id:
		_hit_pulse = 0.65


func _process(delta: float) -> void:
	if not _is_alive or _body_pivot == null:
		return
	_anim_time += delta
	position = position.lerp(_target_position, minf(1.0, delta * 7.0))
	_attack_pulse = maxf(0.0, _attack_pulse - delta * 4.5)
	_hit_pulse = maxf(0.0, _hit_pulse - delta * 6.0)
	var facing := -1.0 if team == TEAM_ALLY else 1.0
	_body_pivot.position = Vector3(
		sin(_anim_time * 2.2 + float(slot)) * 0.012,
		sin(_anim_time * 3.0 + float(slot)) * 0.025,
		facing * sin(_attack_pulse * PI) * 0.38
	)
	var squash := sin(_hit_pulse * PI) * 0.16
	_body_pivot.scale = Vector3(1.0 + squash, 1.0 - squash, 1.0 + squash)


func _build_model(unit_snapshot: Dictionary) -> void:
	_body_pivot = Node3D.new()
	_body_pivot.name = "BodyPivot"
	add_child(_body_pivot)
	if team != TEAM_ALLY:
		_body_pivot.rotation_degrees.y = 180.0

	var class_id := String(unit_snapshot.get("class_id", "fighter"))
	var archetype_id := String(unit_snapshot.get("archetype_id", class_id))
	var elite := bool(unit_snapshot.get("elite", false))
	var porcelain_key := "ally_porcelain" if team == TEAM_ALLY else "enemy_porcelain"
	var accent_key := "ally_accent" if team == TEAM_ALLY else "enemy_accent"
	_add_part("Base", "base", porcelain_key, Vector3(0.0, 0.34, 0.0))
	_add_part("Bowl", "bowl", porcelain_key, Vector3(0.0, 0.67, -0.04))
	_add_part("Rim", "rim", accent_key, Vector3(0.0, 0.91, -0.05))
	_add_part("Tank", "tank", porcelain_key, Vector3(0.0, 0.86, 0.43))
	_add_part("Lid", "lid", accent_key, Vector3(0.0, 1.27, 0.43))
	_add_part("Neck", "neck", "skin", Vector3(0.0, 1.10, -0.04))
	_add_part("Head", "head", "skin", Vector3(0.0, 1.48, -0.04))
	_add_part("LeftEye", "eye", "dark", Vector3(-0.105, 1.54, -0.29))
	_add_part("RightEye", "eye", "dark", Vector3(0.105, 1.54, -0.29))
	_add_part("Mouth", "mouth", "dark", Vector3(0.0, 1.38, -0.305))
	_add_limb("LeftArm", -1.0, accent_key)
	_add_limb("RightArm", 1.0, accent_key)

	if class_id == "guardian" or archetype_id == "armored":
		_add_part("Armor", "armor", accent_key, Vector3(0.0, 0.77, -0.43))
	if class_id == "ranger" or archetype_id in ["rocket", "bomber"]:
		_add_part("Sight", "sight", accent_key, Vector3(0.0, 1.78, -0.02))
	if class_id == "arcanist" or archetype_id in ["sonic", "parasite", "repair"]:
		_add_part("Antenna", "antenna", accent_key, Vector3(0.0, 1.88, 0.0))
	if archetype_id == "saw":
		_add_part("LeftSaw", "saw", accent_key, Vector3(-0.76, 0.74, -0.04))
		_add_part("RightSaw", "saw", accent_key, Vector3(0.76, 0.74, -0.04))
	if archetype_id == "bomber":
		_add_part("BombPack", "bomb", "danger", Vector3(0.0, 1.02, 0.72))
	if elite:
		_add_part("EliteCrest", "crest", "danger", Vector3(0.0, 1.95, -0.03))
		_body_pivot.scale = Vector3(1.18, 1.18, 1.18)

	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.text = String(unit_id)
	_name_label.position = Vector3(0.0, 2.17, 0.0)
	_name_label.font_size = 30
	_name_label.outline_size = 7
	_name_label.modulate = Color("#7fd7ff") if team == TEAM_ALLY else Color("#ff8d82")
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_body_pivot.add_child(_name_label)

	_hp_label = Label3D.new()
	_hp_label.name = "HealthLabel"
	_hp_label.position = Vector3(0.0, 1.94, 0.0)
	_hp_label.font_size = 26
	_hp_label.outline_size = 6
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_body_pivot.add_child(_hp_label)


func _add_limb(part_name: String, side: float, material_key: String) -> void:
	var arm := _add_part(
		part_name,
		"arm",
		material_key,
		Vector3(side * 0.55, 1.08, -0.02)
	)
	arm.rotation_degrees.z = side * 24.0
	_add_part(
		"%sFist" % part_name,
		"fist",
		"skin",
		Vector3(side * 0.69, 0.82, -0.02)
	)


func _add_part(
	part_name: String,
	mesh_key: String,
	material_key: String,
	part_position: Vector3
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = _shared_meshes[mesh_key]
	part.material_override = _shared_materials[material_key]
	part.position = part_position
	_body_pivot.add_child(part)
	return part


static func _ensure_shared_resources() -> void:
	if not _shared_meshes.is_empty():
		return

	var base := CylinderMesh.new()
	base.top_radius = 0.36
	base.bottom_radius = 0.27
	base.height = 0.58
	base.radial_segments = 10
	_shared_meshes["base"] = base

	var bowl := SphereMesh.new()
	bowl.radius = 0.54
	bowl.height = 0.72
	bowl.radial_segments = 12
	bowl.rings = 6
	_shared_meshes["bowl"] = bowl

	var rim := TorusMesh.new()
	rim.inner_radius = 0.31
	rim.outer_radius = 0.55
	rim.rings = 12
	rim.ring_segments = 6
	_shared_meshes["rim"] = rim

	_shared_meshes["tank"] = _box(Vector3(0.72, 0.76, 0.34))
	_shared_meshes["lid"] = _box(Vector3(0.76, 0.08, 0.38))

	var neck := CylinderMesh.new()
	neck.top_radius = 0.15
	neck.bottom_radius = 0.17
	neck.height = 0.42
	neck.radial_segments = 10
	_shared_meshes["neck"] = neck

	var head := SphereMesh.new()
	head.radius = 0.29
	head.height = 0.56
	head.radial_segments = 12
	head.rings = 6
	_shared_meshes["head"] = head

	var eye := SphereMesh.new()
	eye.radius = 0.045
	eye.height = 0.085
	eye.radial_segments = 8
	eye.rings = 4
	_shared_meshes["eye"] = eye
	_shared_meshes["mouth"] = _box(Vector3(0.22, 0.045, 0.035))

	var arm := CylinderMesh.new()
	arm.top_radius = 0.075
	arm.bottom_radius = 0.09
	arm.height = 0.56
	arm.radial_segments = 8
	_shared_meshes["arm"] = arm

	var fist := SphereMesh.new()
	fist.radius = 0.115
	fist.height = 0.21
	fist.radial_segments = 8
	fist.rings = 4
	_shared_meshes["fist"] = fist
	_shared_meshes["armor"] = _box(Vector3(0.74, 0.42, 0.12))
	_shared_meshes["sight"] = _box(Vector3(0.24, 0.12, 0.18))
	_shared_meshes["saw"] = _box(Vector3(0.1, 0.38, 0.16))
	_shared_meshes["bomb"] = _box(Vector3(0.46, 0.36, 0.24))
	_shared_meshes["crest"] = _box(Vector3(0.5, 0.16, 0.08))

	var antenna := CylinderMesh.new()
	antenna.top_radius = 0.025
	antenna.bottom_radius = 0.04
	antenna.height = 0.48
	antenna.radial_segments = 6
	_shared_meshes["antenna"] = antenna

	_shared_materials["ally_porcelain"] = _material(Color("#dcecf2"), 0.78)
	_shared_materials["enemy_porcelain"] = _material(Color("#c8b79b"), 0.88)
	_shared_materials["ally_accent"] = _material(Color("#28aee8"), 0.48)
	_shared_materials["enemy_accent"] = _material(Color("#d65345"), 0.58)
	_shared_materials["skin"] = _material(Color("#d9a178"), 0.86)
	_shared_materials["dark"] = _material(Color("#17202a"), 0.72)
	_shared_materials["danger"] = _material(Color("#ff694d"), 0.48)


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

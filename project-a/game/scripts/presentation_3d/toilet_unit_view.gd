class_name ToiletUnitView
extends Node3D

const TEAM_ALLY: int = 0
const EXTERNAL_ALLY_MODELS: Dictionary = {
	"assault": preload("res://game/scenes/actors/ally_models/assault_model.tscn"),
	"sonic": preload("res://game/scenes/actors/ally_models/sonic_model.tscn"),
	"rocket": preload("res://game/scenes/actors/ally_models/rocket_model.tscn"),
	"bomber": preload("res://game/scenes/actors/ally_models/bomber_model.tscn"),
	"armored": preload("res://game/scenes/actors/ally_models/armored_model.tscn"),
	"saw": preload("res://game/scenes/actors/ally_models/saw_model.tscn"),
	"repair": preload("res://game/scenes/actors/ally_models/repair_model.tscn"),
	"parasite": preload("res://game/scenes/actors/ally_models/parasite_model.tscn"),
}

static var _shared_meshes: Dictionary = {}
static var _shared_materials: Dictionary = {}

var unit_id: StringName = &""
var team: int = TEAM_ALLY
var slot: int = 0

var _body_pivot: Node3D
var _name_label: Label3D
var _hp_label: Label3D
var _hp_bar_root: Node3D
var _hp_bar_fill: MeshInstance3D
var _hp_bar_fill_material: StandardMaterial3D
var _anim_time: float = 0.0
var _attack_pulse: float = 0.0
var _hit_pulse: float = 0.0
var _skill_pulse: float = 0.0
var _status_tint: Color = Color.WHITE
var _is_alive: bool = true
var _reduced_motion: bool = false
var _target_position: Vector3 = Vector3.ZERO
var _use_external_model: bool = false


func setup(unit_snapshot: Dictionary) -> void:
	unit_id = unit_snapshot.get("unit_id", &"")
	team = int(unit_snapshot.get("team", TEAM_ALLY))
	slot = int(unit_snapshot.get("slot", 0))
	name = "Unit_%s" % String(unit_id)
	scale = Vector3.ONE * (1.3 if team == TEAM_ALLY else 1.0)
	_ensure_shared_resources()
	_build_model(unit_snapshot)
	apply_snapshot(unit_snapshot)
	set_process(true)


func apply_snapshot(unit_snapshot: Dictionary) -> void:
	if _hp_label == null:
		return
	var hp := int(unit_snapshot.get("hp", 0))
	var max_hp := maxi(1, int(unit_snapshot.get("max_hp", 1)))
	var hp_ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	if team == TEAM_ALLY:
		_hp_label.text = ""
	elif _hp_bar_fill != null:
		_hp_bar_fill.scale.x = maxf(0.001, hp_ratio)
		_hp_bar_fill.position.x = -(1.0 - hp_ratio) * 0.58
		_hp_bar_fill_material.albedo_color = Color("#ffab45") if hp_ratio <= 0.3 else Color("#e24f4b")
	var lane := int(unit_snapshot.get("lane", slot % 3))
	var road_position := int(unit_snapshot.get("road_position", 0))
	_target_position = Vector3((float(lane) - 1.0) * 2.15, 0.0, 12.0 - float(road_position) * 0.03)
	if position == Vector3.ZERO:
		position = _target_position
	var shield := int(unit_snapshot.get("shield", 0))
	if team != TEAM_ALLY:
		_hp_label.text = "◆%d" % shield if shield > 0 else ""
	_is_alive = bool(unit_snapshot.get("alive", true))
	if _hp_bar_root != null:
		_hp_bar_root.visible = _is_alive and team != TEAM_ALLY
	if not _is_alive:
		_body_pivot.rotation_degrees.z = -78.0 if team == TEAM_ALLY else 78.0
		_body_pivot.position.y = 0.12
		set_process(false)
		show()
	else:
		show()


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if _reduced_motion and _body_pivot != null:
		_attack_pulse = 0.0
		_hit_pulse = 0.0
		_skill_pulse = 0.0
		_body_pivot.position = Vector3.ZERO
		_body_pivot.scale = Vector3.ONE


func play_battle_event(event: Dictionary) -> void:
	var event_type: StringName = event.get("type", &"")
	if _reduced_motion:
		if event_type == &"skill_used" and event.get("unit_id", &"") == unit_id:
			_status_tint = _skill_color(String(event.get("skill_id", "")))
		elif event_type in [&"unit_healed", &"unit_shielded", &"unit_revived"] and event.get("unit_id", &"") == unit_id:
			_status_tint = Color("#77f2a2")
		return
	if event_type == &"attack_started" and event.get("unit_id", &"") == unit_id:
		_attack_pulse = 1.0
	elif event_type in [&"attack_hit", &"unit_damaged"] and event.get("unit_id", &"") == unit_id:
		_hit_pulse = 1.0
	elif event_type == &"enemy_damaged" and event.get("enemy_id", &"") == unit_id:
		_hit_pulse = 1.0
	elif event_type == &"skill_used" and event.get("unit_id", &"") == unit_id:
		_attack_pulse = 1.6
		_skill_pulse = 1.0
		_status_tint = _skill_color(String(event.get("skill_id", "")))
	elif event_type in [&"unit_healed", &"unit_shielded", &"unit_revived"] and event.get("unit_id", &"") == unit_id:
		_hit_pulse = 0.65
		_skill_pulse = 0.55
		_status_tint = Color("#77f2a2")


func _process(delta: float) -> void:
	if not _is_alive or _body_pivot == null:
		return
	_anim_time += delta
	position = position.lerp(_target_position, minf(1.0, delta * 7.0))
	if _reduced_motion:
		_body_pivot.position = Vector3.ZERO
		_body_pivot.scale = Vector3.ONE
		_name_label.modulate = _status_tint
		return
	_attack_pulse = maxf(0.0, _attack_pulse - delta * 4.5)
	_hit_pulse = maxf(0.0, _hit_pulse - delta * 6.0)
	_skill_pulse = maxf(0.0, _skill_pulse - delta * 2.8)
	var facing := -1.0 if team == TEAM_ALLY else 1.0
	_body_pivot.position = Vector3(
		sin(_anim_time * 2.2 + float(slot)) * 0.012,
		sin(_anim_time * 3.0 + float(slot)) * 0.025 + sin(_skill_pulse * PI) * 0.08,
		facing * sin(_attack_pulse * PI) * 0.38
	)
	var squash := sin(_hit_pulse * PI) * 0.16
	var skill_scale := sin(_skill_pulse * PI) * 0.14
	_body_pivot.scale = Vector3(1.0 + squash + skill_scale, 1.0 - squash + skill_scale * 0.35, 1.0 + squash + skill_scale)
	_name_label.modulate = _status_tint.lerp(Color("#7fd7ff") if team == TEAM_ALLY else Color("#ff8d82"), 1.0 - _skill_pulse)


func _build_model(unit_snapshot: Dictionary) -> void:
	_body_pivot = Node3D.new()
	_body_pivot.name = "BodyPivot"
	add_child(_body_pivot)
	if team != TEAM_ALLY:
		_body_pivot.rotation_degrees.y = 180.0

	var class_id := String(unit_snapshot.get("class_id", "fighter"))
	var archetype_id := String(unit_snapshot.get("archetype_id", class_id))
	var display_name := String(unit_snapshot.get("display_name", ""))
	var elite := bool(unit_snapshot.get("elite", false))
	_use_external_model = _add_external_ally_model(archetype_id)
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
	if team != TEAM_ALLY:
		_add_alliance_headgear(display_name, class_id, accent_key)
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
	_name_label.text = ("我方 · %s" if team == TEAM_ALLY else "%s") % display_name
	_name_label.position = Vector3(0.0, 2.17, 0.0)
	_name_label.font_size = 72 if team == TEAM_ALLY else 64
	_name_label.pixel_size = 0.00265 if team == TEAM_ALLY else 0.00235
	_name_label.outline_size = 12
	_name_label.modulate = Color("#7fd7ff") if team == TEAM_ALLY else Color("#ff8d82")
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_body_pivot.add_child(_name_label)

	_hp_label = Label3D.new()
	_hp_label.name = "HealthLabel"
	_hp_label.position = Vector3(0.0, 1.94, 0.0)
	_hp_label.font_size = 56
	_hp_label.pixel_size = 0.0023
	_hp_label.outline_size = 10
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.no_depth_test = true
	_body_pivot.add_child(_hp_label)
	if team != TEAM_ALLY:
		_build_enemy_health_bar()


func _build_enemy_health_bar() -> void:
	_hp_bar_root = Node3D.new()
	_hp_bar_root.name = "EnemyHealthBar"
	_hp_bar_root.position = Vector3(0.0, 1.96, 0.0)
	_body_pivot.add_child(_hp_bar_root)

	var background := MeshInstance3D.new()
	background.name = "Background"
	background.mesh = _health_quad(Vector2(1.28, 0.13))
	background.material_override = _health_bar_material(Color("#140d12e8"))
	background.position.z = 0.006
	_hp_bar_root.add_child(background)

	_hp_bar_fill = MeshInstance3D.new()
	_hp_bar_fill.name = "Fill"
	_hp_bar_fill.mesh = _health_quad(Vector2(1.16, 0.075))
	_hp_bar_fill_material = _health_bar_material(Color("#e24f4b"))
	_hp_bar_fill.material_override = _hp_bar_fill_material
	_hp_bar_fill.position.z = -0.006
	_hp_bar_root.add_child(_hp_bar_fill)


func _health_quad(quad_size: Vector2) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = quad_size
	return mesh


func _health_bar_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	material.render_priority = 1
	return material


func _add_external_ally_model(archetype_id: String) -> bool:
	if team != TEAM_ALLY:
		return false
	var packed_scene := EXTERNAL_ALLY_MODELS.get(archetype_id) as PackedScene
	if packed_scene == null:
		return false
	var model := packed_scene.instantiate() as Node3D
	if model == null:
		return false
	model.name = "ExternalModel_%s" % archetype_id
	_body_pivot.add_child(model)
	return true


func _add_alliance_headgear(display_name: String, class_id: String, material_key: String) -> void:
	if display_name.contains("电视") or display_name.contains("TV"):
		var screen := _add_part("TVScreen", "tv_screen", material_key, Vector3(0.0, 1.55, -0.34))
		screen.rotation_degrees.x = -4.0
		_add_part("TVGlow", "tv_glow", "enemy_screen", Vector3(0.0, 1.55, -0.37))
	elif display_name.contains("音箱") or display_name.contains("Speaker") or class_id == "arcanist":
		_add_part("SpeakerLeft", "speaker_cone", material_key, Vector3(-0.27, 1.52, -0.31))
		_add_part("SpeakerRight", "speaker_cone", material_key, Vector3(0.27, 1.52, -0.31))
	else:
		_add_part("CameraBody", "camera_box", material_key, Vector3(0.0, 1.58, -0.31))
		_add_part("CameraLens", "camera_lens", "dark", Vector3(0.0, 1.58, -0.47))


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
	part.visible = not _use_external_model
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
	_shared_meshes["camera_box"] = _box(Vector3(0.42, 0.28, 0.24))
	var camera_lens := CylinderMesh.new()
	camera_lens.top_radius = 0.105
	camera_lens.bottom_radius = 0.13
	camera_lens.height = 0.12
	camera_lens.radial_segments = 10
	_shared_meshes["camera_lens"] = camera_lens
	var speaker_cone := CylinderMesh.new()
	speaker_cone.top_radius = 0.02
	speaker_cone.bottom_radius = 0.16
	speaker_cone.height = 0.16
	speaker_cone.radial_segments = 10
	_shared_meshes["speaker_cone"] = speaker_cone
	_shared_meshes["tv_screen"] = _box(Vector3(0.58, 0.36, 0.08))
	_shared_meshes["tv_glow"] = _box(Vector3(0.46, 0.24, 0.025))

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
	_shared_materials["enemy_screen"] = _material(Color("#38465a"), 0.4, Color("#8fd5ff"), 0.9)


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _material(color: Color, roughness: float, emission: Color = Color.TRANSPARENT, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


static func _skill_color(skill_id: String) -> Color:
	return {
		"plunger_charge": Color("#75ddff"),
		"sonic_disruptor": Color("#8ee9ff"),
		"rocket_salvo": Color("#ff9d48"),
		"suicide_dive": Color("#ff7048"),
		"siege_shield": Color("#8df5bd"),
		"saw_rush": Color("#f7d56d"),
		"field_repair": Color("#77f2a2"),
		"parasite_swarm": Color("#b489ff"),
	}.get(skill_id, Color.WHITE)

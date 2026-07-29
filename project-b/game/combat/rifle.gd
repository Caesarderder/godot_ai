class_name RifleController
extends Node3D

signal shot_fired(ammo: int, reserve: int)
signal ammo_changed(ammo: int, reserve: int, reloading: bool)
signal hit_confirmed(target_id: StringName, damage: int, lethal: bool)

@export var config: RifleConfig

@onready var muzzle_flash: MeshInstance3D = %MuzzleFlash
@onready var weapon_body: Node3D = %WeaponBody

var ammo: int = 0
var reserve: int = 0
var _enabled: bool = true
var _shot_cooldown: float = 0.0
var _reload_remaining: float = 0.0
var _flash_remaining: float = 0.0
var _attack_sequence: int = 0
var _rest_position: Vector3


func _ready() -> void:
	if config == null:
		config = preload("res://game/combat/rifle_default.tres")
	_rest_position = weapon_body.position
	reset_weapon()


func _process(delta: float) -> void:
	_shot_cooldown = maxf(0.0, _shot_cooldown - delta)
	if _reload_remaining > 0.0:
		_reload_remaining = maxf(0.0, _reload_remaining - delta)
		if _reload_remaining == 0.0:
			_finish_reload()
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	muzzle_flash.visible = _flash_remaining > 0.0
	var target_position := _rest_position
	if is_reloading():
		target_position += Vector3(0.08, -0.18, 0.09)
		weapon_body.rotation.z = lerpf(weapon_body.rotation.z, deg_to_rad(-13.0), minf(1.0, delta * 9.0))
	else:
		weapon_body.rotation.z = lerpf(weapon_body.rotation.z, 0.0, minf(1.0, delta * 12.0))
	weapon_body.position = weapon_body.position.lerp(target_position, minf(1.0, delta * 18.0))


func reset_weapon() -> void:
	if config == null:
		return
	ammo = config.magazine_size
	reserve = config.starting_reserve
	_shot_cooldown = 0.0
	_reload_remaining = 0.0
	_flash_remaining = 0.0
	_attack_sequence = 0
	_enabled = true
	if is_node_ready():
		muzzle_flash.visible = false
		weapon_body.position = _rest_position
	ammo_changed.emit(ammo, reserve, false)


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_reload_remaining = 0.0
	ammo_changed.emit(ammo, reserve, is_reloading())


func is_reloading() -> bool:
	return _reload_remaining > 0.0


func reload() -> bool:
	if not _enabled or is_reloading() or ammo >= config.magazine_size or reserve <= 0:
		return false
	_reload_remaining = config.reload_seconds
	ammo_changed.emit(ammo, reserve, true)
	return true


func fire_from(camera: Camera3D) -> Dictionary:
	if not _enabled or camera == null or is_reloading() or _shot_cooldown > 0.0:
		return {"accepted": false}
	if ammo <= 0:
		reload()
		return {"accepted": false, "empty": true}

	ammo -= 1
	_attack_sequence += 1
	_shot_cooldown = config.seconds_per_shot
	_flash_remaining = 0.055
	weapon_body.position = _rest_position + Vector3(0.0, -0.012, 0.055)
	shot_fired.emit(ammo, reserve)
	ammo_changed.emit(ammo, reserve, false)

	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * config.range_meters,
		0b101
	)
	var player_body := _find_player_body()
	if player_body != null:
		query.exclude = [player_body.get_rid()]
	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return {"accepted": true, "hit": false}

	var collider := result.get("collider") as Object
	var hit_position: Vector3 = result.get("position", origin)
	_spawn_impact(hit_position)
	if collider != null and collider.has_method("apply_damage"):
		var attack_id := StringName("rifle_%06d" % _attack_sequence)
		var data := DamageData.new(
			&"player",
			attack_id,
			config.damage,
			hit_position,
			direction * 4.0,
			[&"ballistic", &"hitscan"]
		)
		var damage_result: Dictionary = collider.call("apply_damage", data)
		if bool(damage_result.get("accepted", false)):
			hit_confirmed.emit(
				StringName(damage_result.get("target_id", &"unknown")),
				int(damage_result.get("applied", 0)),
				bool(damage_result.get("lethal", false))
			)
			return {
				"accepted": true,
				"hit": true,
				"lethal": bool(damage_result.get("lethal", false)),
				"position": hit_position,
			}
	return {"accepted": true, "hit": false, "position": hit_position}


func _finish_reload() -> void:
	var needed := config.magazine_size - ammo
	var loaded := mini(needed, reserve)
	ammo += loaded
	reserve -= loaded
	ammo_changed.emit(ammo, reserve, false)


func _find_player_body() -> CollisionObject3D:
	var cursor: Node = self
	while cursor != null:
		if cursor is CharacterBody3D:
			return cursor as CollisionObject3D
		cursor = cursor.get_parent()
	return null


func _spawn_impact(hit_position: Vector3) -> void:
	var impact := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.085
	mesh.height = 0.17
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.82, 0.94, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.32, 0.78, 1.0)
	material.emission_energy_multiplier = 4.0
	mesh.material = material
	impact.mesh = mesh
	var impact_parent := get_tree().current_scene
	if impact_parent == null:
		impact_parent = get_tree().root
	impact_parent.add_child(impact)
	impact.global_position = hit_position
	var tween := impact.create_tween()
	tween.tween_property(impact, "scale", Vector3.ONE * 0.12, 0.18)
	tween.tween_callback(impact.queue_free)

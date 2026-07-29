class_name BlacksiteSentry
extends CharacterBody3D

signal enemy_attack_requested(data: DamageData)
signal health_changed(actor_id: StringName, current: int, maximum: int)
signal actor_died(actor_id: StringName)

@export var actor_id: StringName = &"sentry"
@export_range(1, 1000, 1) var maximum_health: int = 100
@export_range(1, 100, 1) var attack_damage: int = 12
@export_range(1.0, 100.0, 0.5) var attack_range: float = 28.0
@export_range(0.1, 5.0, 0.05) var attack_interval: float = 0.85
@export_range(0.0, 10.0, 0.1) var strafe_speed: float = 2.1

@onready var collision_shape: CollisionShape3D = %CollisionShape3D
@onready var body_mesh: MeshInstance3D = %BodyMesh
@onready var visor_mesh: MeshInstance3D = %VisorMesh
@onready var muzzle_flash: MeshInstance3D = %EnemyMuzzleFlash

var current_health: int = 0
var _target: Node3D
var _spawn_transform: Transform3D
var _active: bool = true
var _accepted_attacks: Dictionary = {}
var _attack_cooldown: float = 0.0
var _attack_sequence: int = 0
var _strafe_sign: float = 1.0
var _muzzle_time: float = 0.0
var _hit_tween: Tween
var _death_tween: Tween


func _ready() -> void:
	_spawn_transform = global_transform
	reset_actor()


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_muzzle_time = maxf(0.0, _muzzle_time - delta)
	muzzle_flash.visible = _muzzle_time > 0.0
	if not _active or _target == null or current_health <= 0:
		velocity = Vector3.ZERO
		return

	var offset := _target.global_position - global_position
	var flat_offset := Vector3(offset.x, 0.0, offset.z)
	var distance := flat_offset.length()
	if distance > 0.1:
		look_at(global_position + flat_offset.normalized(), Vector3.UP, true)
	var side := transform.basis.x * _strafe_sign
	velocity.x = side.x * strafe_speed
	velocity.z = side.z * strafe_speed
	move_and_slide()
	if is_on_wall():
		_strafe_sign *= -1.0

	if distance <= attack_range and _attack_cooldown <= 0.0 and _has_line_of_sight():
		_attack_sequence += 1
		_attack_cooldown = attack_interval
		_muzzle_time = 0.07
		var attack_id := StringName("%s_%06d" % [String(actor_id), _attack_sequence])
		var direction := (_target.global_position - global_position).normalized()
		enemy_attack_requested.emit(DamageData.new(
			actor_id,
			attack_id,
			attack_damage,
			_target.global_position,
			direction * 2.0,
			[&"enemy_ballistic"]
		))


func setup(target: Node3D) -> void:
	_target = target


func set_actor_id(value: StringName) -> void:
	actor_id = value


func reset_actor() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	current_health = maximum_health
	_accepted_attacks.clear()
	_attack_cooldown = attack_interval * 0.45
	_attack_sequence = 0
	_active = true
	velocity = Vector3.ZERO
	if _spawn_transform != Transform3D():
		global_transform = _spawn_transform
	rotation.z = 0.0
	body_mesh.scale = Vector3.ONE
	visor_mesh.scale = Vector3.ONE
	visible = true
	if is_node_ready():
		collision_shape.disabled = false
		muzzle_flash.visible = false
	health_changed.emit(actor_id, current_health, maximum_health)


func set_spawn_transform(value: Transform3D) -> void:
	_spawn_transform = value
	global_transform = value


func set_active(value: bool) -> void:
	_active = value


func apply_damage(data: DamageData) -> Dictionary:
	if data == null or not _active or current_health <= 0 or data.amount <= 0:
		return {"accepted": false, "target_id": actor_id}
	if _accepted_attacks.has(data.attack_instance_id):
		return {"accepted": false, "duplicate": true, "target_id": actor_id}
	_accepted_attacks[data.attack_instance_id] = true
	var before := current_health
	current_health = maxi(0, current_health - data.amount)
	var applied := before - current_health
	body_mesh.scale = Vector3(1.08, 0.94, 1.08)
	visor_mesh.scale = Vector3(1.22, 1.35, 1.22)
	_hit_tween = create_tween()
	_hit_tween.tween_property(body_mesh, "scale", Vector3.ONE, 0.12)
	_hit_tween.parallel().tween_property(visor_mesh, "scale", Vector3.ONE, 0.12)
	health_changed.emit(actor_id, current_health, maximum_health)
	var lethal := current_health == 0
	if lethal:
		_active = false
		velocity = Vector3.ZERO
		collision_shape.set_deferred("disabled", true)
		actor_died.emit(actor_id)
		_death_tween = create_tween()
		_death_tween.tween_property(self, "rotation:z", deg_to_rad(76.0), 0.28)
		_death_tween.parallel().tween_property(self, "position:y", position.y - 0.45, 0.28)
	return {
		"accepted": true,
		"target_id": actor_id,
		"applied": applied,
		"lethal": lethal,
	}


func _has_line_of_sight() -> bool:
	if _target == null:
		return false
	var origin := global_position + Vector3.UP * 1.35
	var target_position := _target.global_position + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(origin, target_position, 0b011)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return true
	return result.get("collider") == _target

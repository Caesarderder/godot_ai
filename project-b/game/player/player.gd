class_name FpsPlayer
extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal actor_died(actor_id: StringName)

@export_range(1, 1000, 1) var maximum_health: int = 100
@export_range(1.0, 20.0, 0.1) var walk_speed: float = 6.8
@export_range(1.0, 30.0, 0.1) var sprint_speed: float = 10.2
@export_range(1.0, 50.0, 0.1) var acceleration: float = 25.0
@export_range(1.0, 50.0, 0.1) var deceleration: float = 20.0
@export_range(1.0, 15.0, 0.1) var jump_velocity: float = 6.4
@export_range(0.0001, 0.02, 0.0001) var mouse_sensitivity: float = 0.0017

@onready var head: Node3D = %Head
@onready var camera: Camera3D = %Camera3D
@onready var rifle: RifleController = %Rifle

var current_health: int = 0
var _input_enabled: bool = true
var _spawn_transform: Transform3D
var _accepted_attacks: Dictionary = {}
var _gravity: float = 18.0


func _ready() -> void:
	_spawn_transform = global_transform
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	reset_actor()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if not _input_enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * mouse_sensitivity)
		head.rotate_x(-motion.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-86.0), deg_to_rad(86.0))


func _physics_process(delta: float) -> void:
	var target_fov := 64.0 if _input_enabled and Input.is_action_pressed("aim") else 76.0
	camera.fov = lerpf(camera.fov, target_fov, minf(1.0, delta * 12.0))
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif _input_enabled and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_vector := Vector2.ZERO
	if _input_enabled:
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var desired_direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_velocity := desired_direction * target_speed
	var rate := acceleration if desired_direction != Vector3.ZERO else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)
	move_and_slide()

	if not _input_enabled:
		return
	if Input.is_action_pressed("fire"):
		rifle.fire_from(camera)
	if Input.is_action_just_pressed("reload"):
		rifle.reload()


func reset_actor() -> void:
	current_health = maximum_health
	_accepted_attacks.clear()
	velocity = Vector3.ZERO
	if _spawn_transform != Transform3D():
		global_transform = _spawn_transform
	head.rotation = Vector3.ZERO
	_input_enabled = true
	if is_node_ready():
		rifle.reset_weapon()
	health_changed.emit(current_health, maximum_health)


func set_spawn_transform(value: Transform3D) -> void:
	_spawn_transform = value
	global_transform = value


func set_input_enabled(value: bool) -> void:
	_input_enabled = value
	rifle.set_enabled(value)


func get_camera() -> Camera3D:
	return camera


func apply_damage(data: DamageData) -> Dictionary:
	if data == null or current_health <= 0 or data.amount <= 0:
		return {"accepted": false, "target_id": &"player"}
	if _accepted_attacks.has(data.attack_instance_id):
		return {"accepted": false, "duplicate": true, "target_id": &"player"}
	_accepted_attacks[data.attack_instance_id] = true
	var before := current_health
	current_health = maxi(0, current_health - data.amount)
	var applied := before - current_health
	health_changed.emit(current_health, maximum_health)
	var lethal := current_health == 0
	if lethal:
		_input_enabled = false
		actor_died.emit(&"player")
	return {
		"accepted": true,
		"target_id": &"player",
		"applied": applied,
		"lethal": lethal,
	}

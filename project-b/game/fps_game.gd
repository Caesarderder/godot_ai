class_name FpsGame
extends Node3D

signal run_finished(victory: bool, summary: Dictionary)

@onready var blacksite: Node3D = %Blacksite
@onready var player: FpsPlayer = %Player
@onready var enemies_root: Node3D = %Enemies
@onready var hud: CombatHud = %CombatHud

var run_state := FpsRunState.new()
var _enemies: Array[BlacksiteSentry] = []
var _connections_ready: bool = false
var _core_tween: Tween


func _ready() -> void:
	_collect_and_place_actors()
	_connect_once()
	restart_run()


func _process(delta: float) -> void:
	if run_state.outcome == FpsRunState.Outcome.RUNNING:
		run_state.elapsed_seconds += delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_run") and run_state.outcome != FpsRunState.Outcome.RUNNING:
		restart_run()


func restart_run() -> void:
	if _core_tween != null and _core_tween.is_valid():
		_core_tween.kill()
	run_state.reset(_enemies.size())
	player.reset_actor()
	player.set_input_enabled(true)
	for enemy in _enemies:
		enemy.reset_actor()
		enemy.set_active(true)
	hud.reset_hud()
	hud.set_player_health(player.current_health, player.maximum_health)
	hud.set_ammo(player.rifle.ammo, player.rifle.reserve, false)
	hud.set_objective(run_state.enemies_remaining, run_state.total_enemies)
	var core := blacksite.find_child("SignalCore", true, false) as Node3D
	if core != null:
		core.scale = Vector3.ONE
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func debug_eliminate_all() -> void:
	for enemy in _enemies:
		if enemy.current_health > 0:
			var data := DamageData.new(
				&"debug",
				StringName("debug_kill_%s" % String(enemy.actor_id)),
				enemy.maximum_health
			)
			enemy.apply_damage(data)


func debug_defeat_player() -> void:
	player.apply_damage(DamageData.new(
		&"debug_enemy",
		&"debug_player_lethal",
		player.maximum_health
	))


func debug_set_low_health_reload() -> void:
	player.apply_damage(DamageData.new(
		&"debug_enemy",
		&"debug_player_pressure",
		82
	))
	player.rifle.ammo = 3
	player.rifle.reserve = 57
	player.rifle.ammo_changed.emit(3, 57, false)
	player.rifle.reload()


func debug_combat_peak() -> void:
	player.apply_damage(DamageData.new(
		&"debug_enemy",
		&"debug_player_peak",
		28
	))
	hud.show_hit(false)
	player.rifle.set("_flash_remaining", 0.35)
	if not _enemies.is_empty():
		_enemies[0].apply_damage(DamageData.new(
			&"debug_player",
			&"debug_peak_target_hit",
			26
		))
		_enemies[0].body_mesh.scale = Vector3(1.14, 0.9, 1.14)
		_enemies[0].visor_mesh.scale = Vector3.ONE * 1.45
	for index in mini(2, _enemies.size()):
		_enemies[index].set("_muzzle_time", 0.35)
		_enemies[index].set_active(false)


func get_enemies() -> Array[BlacksiteSentry]:
	return _enemies


func _collect_and_place_actors() -> void:
	var player_spawn := blacksite.find_child("PlayerSpawn", true, false) as Marker3D
	if player_spawn != null:
		player.set_spawn_transform(player_spawn.global_transform)
	_enemies.clear()
	for index in enemies_root.get_child_count():
		var enemy := enemies_root.get_child(index) as BlacksiteSentry
		if enemy == null:
			continue
		enemy.set_actor_id(StringName("sentry_%d" % (index + 1)))
		var spawn := blacksite.find_child("EnemySpawn%d" % (index + 1), true, false) as Marker3D
		if spawn != null:
			enemy.set_spawn_transform(spawn.global_transform)
		enemy.setup(player)
		_enemies.append(enemy)


func _connect_once() -> void:
	if _connections_ready:
		return
	_connections_ready = true
	player.health_changed.connect(_on_player_health_changed)
	player.actor_died.connect(_on_actor_died)
	player.rifle.shot_fired.connect(_on_shot_fired)
	player.rifle.ammo_changed.connect(_on_ammo_changed)
	player.rifle.hit_confirmed.connect(_on_hit_confirmed)
	for enemy in _enemies:
		enemy.enemy_attack_requested.connect(_on_enemy_attack_requested)
		enemy.health_changed.connect(_on_enemy_health_changed)
		enemy.actor_died.connect(_on_actor_died)


func _on_player_health_changed(current: int, maximum: int) -> void:
	hud.set_player_health(current, maximum)


func _on_shot_fired(_ammo: int, _reserve: int) -> void:
	run_state.register_shot()


func _on_ammo_changed(ammo: int, reserve: int, reloading: bool) -> void:
	hud.set_ammo(ammo, reserve, reloading)


func _on_hit_confirmed(_target_id: StringName, _damage: int, lethal: bool) -> void:
	run_state.register_hit()
	hud.show_hit(lethal)


func _on_enemy_attack_requested(data: DamageData) -> void:
	if run_state.outcome != FpsRunState.Outcome.RUNNING:
		return
	var result := player.apply_damage(data)
	if bool(result.get("accepted", false)):
		hud.show_damage()


func _on_enemy_health_changed(
	actor_id: StringName,
	current: int,
	maximum: int
) -> void:
	hud.set_target_health(actor_id, current, maximum)


func _on_actor_died(actor_id: StringName) -> void:
	if actor_id == &"player":
		if run_state.register_defeat():
			_finish_run(false)
		return
	if run_state.register_enemy_down():
		hud.set_objective(0, run_state.total_enemies)
		_finish_run(true)
	else:
		hud.set_objective(run_state.enemies_remaining, run_state.total_enemies)


func _finish_run(victory: bool) -> void:
	player.set_input_enabled(false)
	for enemy in _enemies:
		enemy.set_active(false)
	var report := run_state.summary()
	if victory:
		var core := blacksite.find_child("SignalCore", true, false) as Node3D
		if core != null:
			_core_tween = create_tween()
			_core_tween.tween_property(core, "scale", Vector3.ONE * 1.12, 0.28)
	else:
		report["cause"] = "SENTRY CROSSFIRE"
	hud.show_outcome(victory, report)
	run_finished.emit(victory, report)

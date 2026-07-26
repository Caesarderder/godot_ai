extends Node

signal services_initialized(status: String)

var initialization_status := "not_started"
var initialized := false


func _ready() -> void:
	var game_service := get_node_or_null("/root/Game")
	var save_service := get_node_or_null("/root/SaveManager")
	initialize_with_services(
		game_service,
		save_service,
		20260723,
		int(Time.get_unix_time_from_system())
	)


func initialize_with_services(
	game_service: Object,
	save_service: Object,
	run_seed: int,
	now_unix: int
) -> String:
	if initialized:
		return initialization_status
	initialized = true
	if game_service == null or not game_service.has_method("bootstrap_with_manager"):
		initialization_status = "game_service_unavailable"
		services_initialized.emit(initialization_status)
		return initialization_status
	if save_service == null:
		initialization_status = "save_service_unavailable"
		services_initialized.emit(initialization_status)
		return initialization_status
	initialization_status = String(
		game_service.bootstrap_with_manager(save_service, run_seed, now_unix)
	)
	services_initialized.emit(initialization_status)
	return initialization_status

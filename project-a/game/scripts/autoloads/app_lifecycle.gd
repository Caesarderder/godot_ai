extends Node

signal application_paused
signal application_resumed
signal application_close_requested
signal back_navigation_requested

const EDGE_DEBOUNCE_MSEC := 250
const HEARTBEAT_INTERVAL_MSEC := 60_000

var _executor: Object
var _clock: Object
var _last_pause_edge_msec := -1
var _last_resume_edge_msec := -1
var _last_heartbeat_msec := 0


func configure(executor: Object, clock: Object) -> void:
	_executor = executor
	_clock = clock
	_last_pause_edge_msec = -1
	_last_resume_edge_msec = -1
	_last_heartbeat_msec = _monotonic_msec()
	set_process(true)


func poll_heartbeat() -> bool:
	if _executor == null or _clock == null:
		return false
	var current_msec := _monotonic_msec()
	var elapsed_msec := current_msec - _last_heartbeat_msec
	if elapsed_msec < HEARTBEAT_INTERVAL_MSEC and elapsed_msec >= 0:
		return false
	var succeeded := _execute_internal(&"__lifecycle_heartbeat_anchor")
	if succeeded:
		_last_heartbeat_msec = current_msec
	return succeeded


func _process(_delta: float) -> void:
	poll_heartbeat()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			if _accept_edge(true):
				_execute_internal(&"__lifecycle_pause_anchor")
				application_paused.emit()
		NOTIFICATION_APPLICATION_RESUMED:
			if _accept_edge(false):
				_execute_internal(&"__lifecycle_resume_settle")
				_last_heartbeat_msec = _monotonic_msec()
				application_resumed.emit()
		NOTIFICATION_WM_CLOSE_REQUEST:
			application_close_requested.emit()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back_navigation_requested.emit()


func _accept_edge(is_pause: bool) -> bool:
	if _clock == null:
		return true
	var current_msec := _monotonic_msec()
	var previous_msec := _last_pause_edge_msec if is_pause else _last_resume_edge_msec
	if (
		previous_msec >= 0
		and current_msec >= previous_msec
		and current_msec - previous_msec < EDGE_DEBOUNCE_MSEC
	):
		return false
	if is_pause:
		_last_pause_edge_msec = current_msec
	else:
		_last_resume_edge_msec = current_msec
	return true


func _execute_internal(command_type: StringName) -> bool:
	if _executor == null or _clock == null:
		return false
	var now_unix := int(_clock.call("unix_time_seconds"))
	var business_key := "lifecycle:%s:%d" % [String(command_type), now_unix]
	var raw_result: Variant = _executor.call(
		"execute_internal", command_type, {"now_unix": now_unix}, business_key
	)
	if not raw_result is Dictionary:
		return false
	var result: Dictionary = raw_result
	return bool(result.get("ok", false))


func _monotonic_msec() -> int:
	return int(_clock.call("monotonic_msec"))

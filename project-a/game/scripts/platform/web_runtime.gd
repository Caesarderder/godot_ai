class_name WebRuntime
extends Node

signal focus_changed(has_focus: bool)
signal visibility_changed(is_visible: bool)
signal runtime_state_changed(state: Dictionary)

var is_visible: bool = true
var has_focus: bool = true


func platform_capabilities() -> Dictionary:
	var is_web := OS.has_feature("web")
	return {
		"is_web": is_web,
		"platform_name": OS.get_name(),
		"userfs_persistent": OS.is_userfs_persistent() if OS.has_method("is_userfs_persistent") else false,
		"safe_area_supported": DisplayServer.has_method("get_display_safe_area"),
		"visibility_events": true,
		"focus_events": true,
		"javascript_bridge": is_web,
		"threaded_runtime": false,
	}


func is_web() -> bool:
	return bool(platform_capabilities()["is_web"])


func runtime_state() -> Dictionary:
	return {
		"is_web": is_web(),
		"is_visible": is_visible,
		"has_focus": has_focus,
		"is_interactive": is_visible and has_focus,
	}


func set_visibility_state(next_visible: bool) -> void:
	if is_visible == next_visible:
		return
	is_visible = next_visible
	visibility_changed.emit(is_visible)
	runtime_state_changed.emit(runtime_state())


func set_focus_state(next_focus: bool) -> void:
	if has_focus == next_focus:
		return
	has_focus = next_focus
	focus_changed.emit(has_focus)
	runtime_state_changed.emit(runtime_state())


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			set_focus_state(true)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			set_focus_state(false)
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			set_focus_state(true)
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			set_focus_state(false)
		NOTIFICATION_WM_CLOSE_REQUEST:
			set_visibility_state(false)
		_:
			pass

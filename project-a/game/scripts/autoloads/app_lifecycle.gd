extends Node

signal application_paused
signal application_resumed
signal application_close_requested
signal back_navigation_requested


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			application_paused.emit()
		NOTIFICATION_APPLICATION_RESUMED:
			application_resumed.emit()
		NOTIFICATION_WM_CLOSE_REQUEST:
			application_close_requested.emit()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back_navigation_requested.emit()

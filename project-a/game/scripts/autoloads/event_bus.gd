extends Node

signal domain_event_emitted(event: Dictionary)
signal toast_requested(message: String)


func emit_domain_event(event: Dictionary) -> void:
	domain_event_emitted.emit(event)


func request_toast(message: String) -> void:
	toast_requested.emit(message)

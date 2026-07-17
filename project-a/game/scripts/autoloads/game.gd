extends Node

signal boot_completed

var has_booted := false


func _ready() -> void:
	has_booted = true
	boot_completed.emit()

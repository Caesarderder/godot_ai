extends Node

signal catalog_ready

var is_ready := false


func _ready() -> void:
	is_ready = true
	catalog_ready.emit()

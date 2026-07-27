class_name TemplateSignalMediator
extends Node

signal committed(total: int)

@onready var source: TemplateSignalSource = $Source

var total: int = 0


func _ready() -> void:
    source.requested.connect(_on_requested)


func _on_requested(amount: int) -> void:
    total += amount
    committed.emit(total)

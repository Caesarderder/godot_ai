class_name TemplateHealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(data: TemplateDamageData)
signal depleted

@export_range(1, 100000, 1) var maximum: int = 10

var current: int


func _ready() -> void:
    current = maximum


func apply_damage(data: TemplateDamageData) -> int:
    if data == null or data.amount <= 0 or current <= 0:
        return current
    current = maxi(current - data.amount, 0)
    damaged.emit(data)
    health_changed.emit(current, maximum)
    if current == 0:
        depleted.emit()
    return current

class_name TemplateMeterRuntime
extends RefCounted

signal changed(current: int, maximum: int)

var definition: TemplateMeterDefinition
var current: int


func _init(source: TemplateMeterDefinition) -> void:
    assert(source != null, "TemplateMeterRuntime requires a definition")
    definition = source
    current = clampi(source.initial, 0, source.maximum)


func spend(amount: int) -> bool:
    var cost := maxi(amount, 0)
    if cost > current:
        return false
    current -= cost
    changed.emit(current, definition.maximum)
    return true


func restore(amount: int) -> int:
    current = mini(current + maxi(amount, 0), definition.maximum)
    changed.emit(current, definition.maximum)
    return current

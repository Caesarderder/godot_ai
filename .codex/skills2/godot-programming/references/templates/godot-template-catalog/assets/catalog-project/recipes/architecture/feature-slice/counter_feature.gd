class_name TemplateCounterFeature
extends Node

signal value_changed(value: int)
signal limit_reached(value: int)

@export var config: TemplateCounterConfig

var value: int = 0


func increment(amount: int = 1) -> int:
    assert(config != null, "TemplateCounterFeature requires a config Resource")
    value = clampi(value + maxi(amount, 0), 0, config.maximum)
    value_changed.emit(value)
    if value == config.maximum:
        limit_reached.emit(value)
    return value


func reset() -> void:
    value = 0
    value_changed.emit(value)

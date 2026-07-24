extends Node

@export var definition: TemplateMeterDefinition

var runtime: TemplateMeterRuntime


func _ready() -> void:
    runtime = TemplateMeterRuntime.new(definition)

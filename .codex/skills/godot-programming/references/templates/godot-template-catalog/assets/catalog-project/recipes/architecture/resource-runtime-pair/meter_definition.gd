class_name TemplateMeterDefinition
extends Resource

@export var id: StringName = &"energy"
@export_range(1, 100000, 1) var maximum: int = 100
@export_range(0, 100000, 1) var initial: int = 100

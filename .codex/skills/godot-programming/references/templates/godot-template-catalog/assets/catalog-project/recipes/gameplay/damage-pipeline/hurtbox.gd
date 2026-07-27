class_name TemplateHurtbox
extends Area2D

@export var health_path: NodePath

@onready var health: TemplateHealthComponent = get_node(health_path)


func receive(data: TemplateDamageData) -> int:
    return health.apply_damage(data)

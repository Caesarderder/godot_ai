class_name TemplateHitbox
extends Area2D

@export var damage: TemplateDamageData


func _ready() -> void:
    area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
    if damage == null or not area is TemplateHurtbox:
        return
    var hurtbox := area as TemplateHurtbox
    hurtbox.receive(damage)

class_name TemplateInteractable
extends Node

signal interacted

@export var offer: TemplateInteractionOffer

var execution_count: int = 0


func execute() -> void:
    execution_count += 1
    interacted.emit()

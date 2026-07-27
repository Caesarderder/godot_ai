class_name TemplateState
extends Node

var machine: TemplateStateMachine


func enter(_previous: TemplateState) -> void:
    pass


func exit(_next: TemplateState) -> void:
    pass


func can_enter_from(_previous: TemplateState) -> bool:
    return true

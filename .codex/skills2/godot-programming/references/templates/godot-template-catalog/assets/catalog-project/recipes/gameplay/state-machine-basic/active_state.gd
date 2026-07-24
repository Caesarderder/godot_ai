class_name TemplateActiveState
extends TemplateState

var entered_count: int = 0


func enter(_previous: TemplateState) -> void:
    entered_count += 1

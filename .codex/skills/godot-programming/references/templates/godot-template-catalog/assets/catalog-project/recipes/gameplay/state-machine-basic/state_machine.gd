class_name TemplateStateMachine
extends Node

signal transitioned(previous: TemplateState, current: TemplateState)

@export var initial_state_path: NodePath

var current_state: TemplateState


func _ready() -> void:
    var initial := get_node_or_null(initial_state_path) as TemplateState
    assert(initial != null, "TemplateStateMachine requires a valid initial state")
    transition_to(initial)


func transition_to(next_state: TemplateState) -> bool:
    if next_state == null or next_state.get_parent() != self:
        return false
    if next_state == current_state:
        return true
    if not next_state.can_enter_from(current_state):
        return false

    var previous := current_state
    if previous != null:
        previous.exit(next_state)
    current_state = next_state
    current_state.machine = self
    current_state.enter(previous)
    transitioned.emit(previous, current_state)
    return true

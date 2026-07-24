---
name: state-machine
description: Use when implementing or repairing finite state machines in Godot 4.6 GDScript, including enum, node, Resource-driven, hierarchical, and parallel state patterns; covers lifecycle-safe startup, transitions, input/update routing, and inactive nested machines.
---

# State Machines in Godot 4.6

Choose the smallest FSM that makes transitions and ownership explicit. Target typed GDScript and the single-threaded Web runtime.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

## Choose a shape

| Shape | Use when |
| --- | --- |
| Enum in one script | A few states, little enter/exit behavior |
| Node states | States own distinct behavior, signals, or child nodes |
| Resource definitions plus runner | Designers configure data while one node owns runtime state |
| Hierarchical | A parent mode owns mutually exclusive substates |
| Parallel | Independent concerns must update together |

Do not select a pattern from a numeric threshold alone. Split when one machine mixes unrelated transition graphs or state lifecycle becomes hard to follow.

## Minimal enum FSM

Keep transition side effects in one function:

```gdscript
extends CharacterBody2D

enum State { IDLE, CHASE }

var state := State.IDLE


func _physics_process(_delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.CHASE:
			_update_chase()
	move_and_slide()


func transition_to(next: State) -> void:
	if next == state:
		return
	state = next
```

Upgrade to node states when transition hooks or state-local dependencies start accumulating.

## Lifecycle-safe node FSM

Each machine owns exactly one active state. It validates its initial state before enabling callbacks and guards every route against a missing current state.

```gdscript
# state.gd
class_name State
extends Node

var actor: Node


func enter(_previous: State) -> void:
	pass


func exit(_next: State) -> void:
	pass


func update(_delta: float) -> StringName:
	return &""


func physics_update(_delta: float) -> StringName:
	return &""


func handle_input(_event: InputEvent) -> StringName:
	return &""
```

```gdscript
# state_machine.gd
class_name StateMachine
extends Node

signal transitioned(previous: StringName, current: StringName)

@export var actor: Node
@export var initial_state: State
@export var start_active := true

var current_state: State
var _states: Dictionary[StringName, State] = {}
var _active := false


func _ready() -> void:
	for child in get_children():
		if child is State:
			var state := child as State
			_states[state.name] = state
			state.actor = actor

	set_active(false)
	if start_active:
		if initial_state == null or not _states.values().has(initial_state):
			push_error("StateMachine requires an initial child State")
			return
		start(initial_state.name)


func start(state_name: StringName) -> bool:
	if not _states.has(state_name):
		push_error("Unknown initial state: %s" % state_name)
		return false
	if current_state != null:
		push_error("Stop the active machine before starting it again")
		return false
	current_state = _states[state_name]
	set_active(true)
	current_state.enter(null)
	transitioned.emit(&"", current_state.name)
	return true


func stop() -> void:
	if current_state != null:
		current_state.exit(null)
	current_state = null
	set_active(false)


func set_active(value: bool) -> void:
	_active = value
	set_process(value)
	set_physics_process(value)
	set_process_unhandled_input(value)


func transition_to(state_name: StringName) -> bool:
	if not _active or current_state == null:
		return false
	if not _states.has(state_name):
		push_error("Unknown state: %s" % state_name)
		return false
	var next: State = _states[state_name]
	if next == current_state:
		return false
	var previous := current_state
	previous.exit(next)
	current_state = next
	current_state.enter(previous)
	transitioned.emit(previous.name, current_state.name)
	return true


func _process(delta: float) -> void:
	_route(current_state.update(delta))


func _physics_process(delta: float) -> void:
	_route(current_state.physics_update(delta))


func _unhandled_input(event: InputEvent) -> void:
	_route(current_state.handle_input(event))


func _route(next: StringName) -> void:
	if next != &"":
		transition_to(next)
```

Assign `actor` explicitly in the scene. Do not assume `owner` is a particular body type. `set_active(false)` disables process, physics, and unhandled-input callbacks together, preventing an inactive nested machine from running in the background.

## Complete Resource-driven FSM

Resources define transition data; a node still owns mutable runtime state and behavior. Do not mutate shared definition Resources.

```gdscript
# state_definition.gd
class_name StateDefinition
extends Resource

@export var id: StringName
@export var animation: StringName
@export var allowed_targets: Array[StringName] = []
```

```gdscript
# resource_state_machine.gd
class_name ResourceStateMachine
extends Node

signal transitioned(previous: StringName, current: StringName)

@export var definitions: Array[StateDefinition] = []
@export var initial_state: StringName

var current: StateDefinition
var _by_id: Dictionary[StringName, StateDefinition] = {}


func _ready() -> void:
	for definition in definitions:
		if definition == null or definition.id == &"" or _by_id.has(definition.id):
			push_error("State definitions require unique non-empty IDs")
			return
		_by_id[definition.id] = definition
	if not transition_to(initial_state, true):
		push_error("Resource FSM has an invalid initial state")


func transition_to(target: StringName, force := false) -> bool:
	if not _by_id.has(target):
		return false
	if current != null and not force and target not in current.allowed_targets:
		return false
	var previous: StringName = current.id if current != null else &""
	current = _by_id[target]
	transitioned.emit(previous, current.id)
	return true
```

Let an owning controller map `current.id` to behavior or pair definitions with explicit strategy nodes. The Resource alone is configuration, not a functioning FSM.

## Hierarchical and parallel machines

Read [references/hierarchical-and-parallel.md](references/hierarchical-and-parallel.md) before nesting machines. The key invariant is one lifecycle owner: only `start()` enters a nested machine and only `stop()` exits it. Never manually call both the nested machine and its current state's hooks.

For parallel machines, keep write ownership disjoint. For example, movement may write velocity while combat writes attack availability; do not let both overwrite velocity or animation in the same tick. Put conflict resolution in their common owner.

## Checklist

- [ ] Initial state is present, belongs to the machine, and is validated before callbacks run.
- [ ] `_process`, `_physics_process`, and input routes cannot dereference a null current state.
- [ ] A transition exits once and enters once; self-transition behavior is explicit.
- [ ] Inactive nested machines disable all callbacks and have no current state.
- [ ] Resource definitions are immutable shared data; the runner owns mutable state.
- [ ] Transition IDs are unique and unknown targets fail visibly.
- [ ] Parallel machines do not write the same property without an owner resolving precedence.
- [ ] Scripts use Godot 4.6 GDScript and require no threads.

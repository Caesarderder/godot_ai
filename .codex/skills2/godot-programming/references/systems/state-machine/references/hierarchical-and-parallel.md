# Hierarchical and parallel state machines

Use these patterns only after a flat machine has shown a real ownership problem.

## Hierarchical lifecycle

A parent state owns a nested machine. Configure the nested machine with `start_active = false`; otherwise its `_ready()` would start it before the parent state becomes active.

```text
Player
└── StateMachine
    ├── OnGround
    │   └── GroundMachine (start_active = false)
    │       ├── Idle
    │       └── Run
    └── InAir
```

```gdscript
class_name HierarchicalState
extends State

@export var nested_machine: StateMachine


func enter(_previous: State) -> void:
	assert(nested_machine != null)
	assert(nested_machine.initial_state != null)
	nested_machine.start(nested_machine.initial_state.name)


func exit(_next: State) -> void:
	nested_machine.stop()
```

Do not call `nested_machine.current_state.enter()` or `.exit()` here. `start()` and `stop()` own those hooks. This prevents double entry and makes re-entry deterministic.

`stop()` clears the current state and disables process, physics, and unhandled-input callbacks. The nested machine therefore cannot update or consume input while its parent state is inactive.

When a nested transition must cause an outer transition, emit a typed signal or let the parent state inspect a narrow result. Do not let the child reach through ancestors to mutate the outer machine.

## Parallel ownership

Parallel machines are siblings with distinct write responsibilities:

```text
Player
├── MovementMachine   <- chooses desired movement
├── CombatMachine     <- controls attack availability
└── PlayerController  <- resolves both and writes velocity/animation
```

Both machines may update during one physics tick, but the controller should be the sole writer of shared outputs. If ordering changes correctness, the concerns are not truly independent; move their coordination into one owner or one transition graph.

## Selection guide

- Use a flat machine when one transition graph remains readable.
- Use hierarchy when one active mode exclusively owns a nested mode.
- Use parallel machines when concerns are independent and have disjoint outputs.
- Use neither when a boolean, cooldown, or small data table expresses the behavior more directly.

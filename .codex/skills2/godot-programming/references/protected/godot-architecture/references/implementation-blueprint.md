# Pre-implementation Blueprint

Write this blueprint before adding non-trivial gameplay implementation. It is required for a new
feature, first playable, or vertical slice whose runtime has multiple owners. A small isolated fix
with an already-clear boundary may record only the affected owner and contract.

The blueprint is a target for the current milestone, not empty scaffolding. Inspect the existing
project first, preserve coherent public scene paths, and list only files the milestone needs.

## 1. Target file tree

Show the planned project-relative tree and annotate each file with its owner and role.

```text
features/star_taxi/
├── star_taxi_game.tscn
├── star_taxi_game.gd          # feature composition root
├── world/
│   └── star_taxi_world.tscn
├── actors/
│   ├── taxi/
│   │   ├── taxi.tscn
│   │   └── taxi.gd
│   └── traffic_drone/
│       ├── traffic_drone.tscn
│       └── traffic_drone.gd
├── run/
│   ├── star_taxi_run_controller.gd
│   ├── star_taxi_run_state.gd
│   └── star_taxi_run_rules.gd
├── camera/
│   └── chase_camera_rig.tscn
├── ui/
│   ├── star_taxi_hud.tscn
│   └── star_taxi_hud.gd
└── data/
    ├── star_taxi_config.gd
    ├── star_taxi_default_config.tres
    ├── station_definition.gd
    ├── stations/
    │   └── downtown_station.tres
    ├── passenger_definition.gd
    └── passengers/
        └── commuter_passenger.tres
```

Use `.tscn` plus a root `.gd` when a meaningful runtime owner has both a stable, editor-maintained
node subtree and root behavior or orchestration. A distinct lifecycle or useful isolated preview/test
boundary is additional evidence for extraction, but behavior or signals alone do not require a scene.
Keep stable, editor-visible node structure in `.tscn`; do not replace the whole authored scene with a
long `_ready()` that constructs every node programmatically.

Do not pair files mechanically:

- a structural scene with no behavior may be `.tscn` only;
- pure rules, runtime state, and value objects may be `.gd` only;
- typed configuration or definitions use a `.gd` Resource class plus milestone-owned `.tres`
  instances when concrete data is needed;
- genuinely data-driven repeated runtime objects may be instantiated from a `PackedScene`;
- a small one-off leaf can remain in its owner's scene when extraction adds no ownership, reuse, or
  test value.

## 2. Scene tree and ownership

Show the planned scene tree and then record each boundary:

| Owner | Scene root or object | Creates and tears down | Lifetime | Public contract |
| --- | --- | --- | --- | --- |
| Feature root | `StarTaxiGame` | World, taxi, run controller, camera, HUD, FX | Feature run | Start/restart and top-level wiring |
| Taxi | `Taxi` | Input/physics/presentation children | Spawned actor | Typed commands and local occurrences |
| Run controller | `StarTaxiRunController` | Run rules and state | Feature run | Receives intent, applies rules, changes state |
| HUD | `StarTaxiHud` | HUD widgets | Feature run | Renders state snapshots |

The composition root connects siblings. A reusable child must not discover required siblings through
fragile paths or decide which UI, FX, save, or analytics response should occur.

## 3. Signal contract

For every signal, specify the emitter, connector, receiver, typed payload, emission meaning, and
lifetime/reset behavior.

```text
Taxi/Input --drive_intent_changed(intent)--> RunController --sample/apply rules--> RunState
                                                          |
                                            run_state_changed(snapshot)
                                                 |                 |
                                                HUD               FX
```

This flow means:

- input translates devices into semantic intent and emits only a discrete request or a semantic value
  change after deadzone/quantization, without mutating run state;
- the feature composition root connects that request to the run controller;
- the run controller caches or receives that intent, applies run rules at the correct tick, and
  mutates `RunState` through an explicit method;
- after a valid mutation, the controller or state owner emits one factual typed state-change signal;
- HUD and FX react to the fact independently and never write authoritative run state.

Record the contract as a table:

| Signal | Emitter | Connected by | Receiver(s) | Typed payload | Lifetime rule |
| --- | --- | --- | --- | --- | --- |
| `drive_intent_changed(intent: TaxiDriveIntent)` | Taxi input | Feature root | Run controller | Immutable, deadzone/quantized value data | Emit on semantic change; connect once for the taxi lifetime |
| `run_state_changed(snapshot: StarTaxiRunSnapshot)` | Run controller | Feature root | HUD, FX | Immutable/duplicate-safe snapshot | No duplicate connections after restart |

A signal is an occurrence boundary, not a substitute for every method call. Use a direct typed method
for a known owner commanding its child. Avoid generic `EventBus` channels, per-frame signals, signal
cycles, and long synchronous signal chains. Continuous steering/throttle must be sampled from
owner-held input state during the physics tick or passed through an explicit owned method; do not make
the run controller a per-frame vehicle-motion message relay. For restartable scenes, state who
connects, whether nodes are recreated or reset in place, and how duplicate or stale connections are
prevented.

## 4. Resource and runtime-state plan

Separate authored/shared data from live mutable state:

| Type | Godot form | Ownership and mutation |
| --- | --- | --- |
| `StarTaxiConfig` | typed `Resource` class plus `.tres` | Authored tuning; read-only at runtime unless explicitly duplicated |
| `StationDefinition` | typed `Resource` class plus `.tres` instances | Stable station identity and presentation data |
| `PassengerDefinition` | typed `Resource` class plus `.tres` instances | Stable passenger content data |
| `StarTaxiRunState` | typed runtime object, not persisted config | Owned and mutated by the run controller |
| `StarTaxiRunSnapshot` | immutable or duplicate-safe value object | Passed to read-only consumers such as HUD and FX |

Remember that loaded Resources are shared by default. Duplicate per-instance mutable Resource state
deliberately, or keep it in a Node/RefCounted runtime state object. Persistent Resources must not hold
live Node references, scene-local callbacks, or per-frame orchestration.

## 5. Gate before code

Implementation may start when the current milestone has:

1. a target file tree with explicit `.tscn`, `.gd`, and `.tres` decisions;
2. a scene tree plus ownership and lifetime boundaries;
3. command, signal, connector, payload, and restart contracts;
4. Resource definitions separated from authoritative mutable runtime state;
5. an implementation order that first creates the composition root and one end-to-end ownership
   spine, then adds presentation consumers.

Revise the blueprint when implementation evidence disproves a boundary. Do not preserve a diagram at
the expense of a simpler, working ownership model.

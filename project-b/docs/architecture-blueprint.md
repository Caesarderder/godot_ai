# Project B FPS first-playable blueprint

## Slice card

- Player promise being tested: become a fast, precise near-future operator clearing a hostile blacksite under pressure.
- Immediate goal: eliminate four sentry units and secure the signal core before the player is downed.
- Primary input: mouse look, WASD movement, sprint, jump, aim, fire, reload, and restart.
- Meaningful skill: control sight picture and exposure while choosing when to fire, reload, and reposition.
- World response: movement uses `CharacterBody3D`; the rifle performs an authoritative camera-ray query; enemies track, strafe, fire, take damage, stagger, and die.
- Critical feedback: muzzle flash, tracer/impact, hit marker, damage direction/vignette, health/ammo/objective HUD, enemy health silhouette, and outcome overlay.
- Success: all hostile sentries are eliminated.
- Failure: player health reaches zero.
- Restart: semantic `restart_run` resets player, rifle, enemies, objective, effects, and HUD without reconnecting signals.
- Reason to retry: short time-to-action, readable enemy pressure, and a mastery-facing clear time/accuracy summary.
- Explicitly deferred: networking, campaign, progression, save data, licensed media, photogrammetry, cinematic narrative, vehicles, destructible buildings, and claims of AAA parity.

## Target file tree

```text
project-b/
├── project.godot
├── game/
│   ├── fps_game.tscn
│   ├── fps_game.gd                    # run composition root and restart owner
│   ├── run/
│   │   └── run_state.gd               # mutable run state, no Node references
│   ├── player/
│   │   ├── player.tscn                # authored CharacterBody3D/camera/collider
│   │   └── player.gd                  # semantic input, locomotion, health
│   ├── combat/
│   │   ├── damage_data.gd             # immutable hit intent value
│   │   ├── rifle_config.gd            # typed authored Resource schema
│   │   ├── rifle_default.tres         # read-only tuning instance
│   │   ├── rifle.tscn                 # viewmodel, muzzle, weapon feedback
│   │   └── rifle.gd                   # cadence, ammo, reload, ray query
│   ├── enemies/
│   │   ├── sentry.tscn                # authored enemy/collider/visuals
│   │   └── sentry.gd                  # target tracking, fire, damage/death
│   └── ui/
│       ├── combat_hud.tscn            # stable HUD layout
│       └── combat_hud.gd              # read-only projection and transitions
├── levels/
│   └── blacksite.tscn                 # static arena, lighting, cover, spawn markers
├── tests/
│   └── run_fps_vertical_slice_tests.gd
├── tools/
│   └── capture_fps_review.gd
├── docs/
│   ├── architecture-blueprint.md
│   ├── visual-direction.md
│   └── verification-plan.md
└── artifacts/
```

## Scene tree and ownership

```text
FpsGame (Node3D, fps_game.gd)
├── WorldEnvironment
├── Blacksite (instanced level)
├── Player (instanced CharacterBody3D)
│   ├── CollisionShape3D
│   └── Head
│       └── Camera3D
│           └── Rifle (instanced)
├── Enemies
│   └── Sentry × 4
└── CombatHud (CanvasLayer)
```

| Owner | Creates/owns | Lifetime | Public contract |
|---|---|---|---|
| `FpsGame` | level, player, enemies, HUD, run state | application run | `restart_run()`, run outcome orchestration |
| `Player` | body motion, camera intent, local health | run | `reset_actor()`, `apply_damage(data)`, health/death signals |
| `Rifle` | cadence, ammo, reload, hitscan query, weapon FX | player/run | `reset_weapon()`, weapon state and accepted-hit signals |
| `Sentry` | target tracking, fire cadence, health/death | run | `setup(target)`, `reset_actor()`, damage/death signals |
| `CombatHud` | HUD widgets and outcome transition | run | render methods only; no gameplay mutation |
| `RunState` | outcome, kills, shots, hits, elapsed time | run | mutation only through `FpsGame`; duplicate-safe snapshots |

## Command and signal contracts

| Contract | Sender | Connected by | Receiver | Payload/meaning | Restart rule |
|---|---|---|---|---|---|
| `shot_fired(ammo, reserve)` | Rifle | FpsGame | HUD/run state | one accepted trigger pull | connections made once in `_ready()` |
| `hit_confirmed(target_id, damage, lethal)` | Rifle | FpsGame | HUD/run state | authoritative accepted damage | no stale target references in payload |
| `health_changed(current, maximum)` | Player/Sentry | FpsGame | HUD | post-mutation fact | reset emits a new full value |
| `actor_died(actor_id)` | Player/Sentry | FpsGame | outcome owner | idempotent terminal transition | dead actor ignores later hits |
| `enemy_attack_requested(damage_data)` | Sentry | FpsGame | Player | immutable attack intent | ignored after non-running outcome |
| `run_finished(victory, summary)` | FpsGame | FpsGame | HUD | one terminal run result | guarded by run-state outcome |

The composition root wires siblings. Continuous motion remains owned by the player physics tick. UI never calls damage, grants ammo, or decides victory.

## Resource and runtime-state plan

| Data | Godot form | Mutation |
|---|---|---|
| Rifle cadence, magazine, damage, range, reload time | typed `Resource` plus `rifle_default.tres` | read-only at runtime |
| Damage intent | typed `RefCounted` value | constructed per accepted attack; no Node ownership |
| Player/enemy health and position | node runtime state | reset by actor methods |
| Kills, accuracy, elapsed time, outcome | `RunState` runtime object | owned only by `FpsGame` |
| HUD display | derived projection | never authoritative |

## Implementation order

1. Create a bootable Compatibility project and authored `fps_game.tscn`.
2. Implement player locomotion and camera ownership.
3. Add the rifle Resource, hitscan transaction, ammo, reload, and feedback.
4. Add one sentry and complete damage/death ownership end-to-end.
5. Expand to four authored spawn positions and objective state.
6. Add failure, success, summary, and clean restart.
7. Add HUD, environment, lighting, cover readability, and presentation polish.
8. Add deterministic real-scene lifecycle test and screenshot capture tool.
9. Import, bounded start, test, capture, independent visual review, then iterate.

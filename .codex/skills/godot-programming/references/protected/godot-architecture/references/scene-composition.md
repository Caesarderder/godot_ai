# Scene composition recipes

Use these recipes after identifying the scene that owns creation and teardown.

## Entity scene

Keep orchestration at the root and reusable behavior below it:

```text
Enemy (CharacterBody2D)       <- composition root and movement coordination
├── Visuals (Node2D)
│   ├── Sprite2D
│   └── AnimationPlayer
├── CollisionShape2D
├── HealthComponent (Node)
├── DamageReceiver (Area2D)
└── NavigationAgent2D
```

The root may call child methods and connect child signals. `DamageReceiver` receives an explicitly assigned `HealthComponent`; it does not search for a sibling by name. Extract `HealthComponent` as a scene only if it owns reusable child nodes such as timers or effects. Otherwise a script-backed `Node` is sufficient.

## Level as composition root

```text
Level (Node2D)
├── World
├── PlayerSpawn
├── Actors
├── LevelServices
│   ├── SpawnDirector
│   └── ObjectiveTracker
└── HUD (CanvasLayer)
```

Let `Level` instantiate actors, inject session-scoped services, and connect completion signals. Keep `SpawnDirector` scene-owned unless it must persist across levels. A global singleton is not required merely because several actors use the service.

## UI composition

```text
HUD (CanvasLayer)
└── SafeArea (MarginContainer)
    ├── StatusBar
    └── ActionBar
```

Let the HUD root adapt gameplay state into view-specific calls. A reusable status widget should receive display values or a narrow view model; it should not reach into the player scene or global state.

## Decide whether to split

Split when at least one concrete benefit exists:

- The subtree is reused or instantiated independently.
- It owns a distinct lifecycle, state machine, or configuration surface.
- It can be tested or previewed meaningfully in isolation.
- It changes for a different reason or by a different feature owner.
- Extracting it removes duplicated behavior or fragile cross-tree paths.

Keep together when the nodes form one small, one-off implementation detail and extraction would expose many internal signals or properties. Node count alone is not a decision criterion.

## Decide between composition and inheritance

Prefer composition when variants combine independent capabilities: damageable, targetable, collectible, or controllable. Consider scene inheritance when variants retain the same root contract, child structure, and lifecycle while changing art or a small set of exported values.

Stop using inheritance when child scenes repeatedly replace inherited children, override most behavior, or depend on undocumented base paths. Convert the stable behaviors to components and let a scene root compose them.


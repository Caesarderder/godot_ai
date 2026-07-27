# Second-pass Architecture Hardening

Run this pass after the first gameplay ownership spine is implemented and exercised. Its purpose is
to extract proven cross-scene responsibilities, not to predict every future system.

Do not start from a desired list of singletons. Start from current code, runtime evidence, and
repeated lifecycle problems. A single-scene prototype may need no Autoload beyond existing platform
requirements.

## Entry gate

The pass may start when:

- the current input-to-outcome loop runs and restart reaches a valid initial state;
- scene, runtime-state, and signal ownership from the implementation blueprint can be inspected;
- at least one real cross-scene, persistence, settings, audio-continuity, routing, or scale pressure
  exists;
- current parse, focused tests, and startup smoke results are recorded.

If these conditions are absent, finish or repair the gameplay spine first. Do not hide incomplete
gameplay behind service infrastructure.

## 1. Produce the current-system audit

Trace and record:

- all `[autoload]` entries in `project.godot`, their initialization order, public API, dependencies,
  mutable state, and shutdown behavior;
- every scene transition, `user://` read/write, audio bus/player owner, global signal, shared mutable
  Resource, and direct `/root/<Singleton>` access;
- which scene owns restart, which state survives it, and which references become stale after it;
- duplicated policies, stringly typed paths/keys, per-frame global work, and unbounded collections;
- current tests and the runtime path that proves each system is needed.

Draw a dependency DAG. Any Autoload cycle or correctness dependency on sibling `_ready()` order is a
blocking design issue.

## 2. Decide service scope from evidence

Promote a responsibility to an Autoload only when it must survive scene replacement or serve
independently owned scenes for the application lifetime.

| Candidate | Evidence required for application scope | Narrow contract | Keep out |
| --- | --- | --- | --- |
| Settings service | Multiple screens/systems need one validated preference state across routes | load defaults, validate/update settings, emit an immutable snapshot | save slots, UI widgets, arbitrary `String` key/value API |
| Save service | More than one scene/checkpoint participates in versioned player progress | build/validate/publish a slot snapshot, restore only after full validation | live Node references, authored balance data, partial scene mutation while parsing |
| Audio service | Music, bus mix, or browser unlock state must persist across routes | apply mix, play/stop persistent music, bounded global UI/SFX | every positional/local SFX player, gameplay timing authority |
| Scene router | More than one route needs centralized transition, failure, or loading policy | navigate by allowlisted route ID, publish transition facts | gameplay rules, save mutation, arbitrary caller-provided paths |

Keep a service scene-owned when one session/level can create and tear it down. Keep local audio,
effects, and actor state with their feature. An Autoload is a lifetime decision, not a naming style.

## 3. Separate Resources, persisted data, and runtime state

Use typed Resources for authored, Inspector-editable definitions:

- settings defaults and allowed ranges;
- route definitions or a route catalog with stable IDs and `PackedScene` references;
- audio catalogs/mix defaults;
- gameplay definitions and tuning.

Loaded Resources are shared by default and should be treated as immutable definitions. Duplicate only
when a service explicitly needs a mutable runtime copy.

Do not use `.tres` as the write target for user settings or save slots. Persist user settings through
a validated `ConfigFile` under `user://`; persist player progress through a bounded, versioned,
recoverable save format. Keep authoritative live run/session state in an owned Node or RefCounted
model until a Save service asks for a detached snapshot.

## 4. Define commands and factual signals

Commands with one receiver are typed methods. Signals report completed facts or semantic state
changes.

```text
Settings UI --update_audio_mix(value)--> SettingsService
AppBootstrap <--settings_changed(snapshot)-- SettingsService
AppBootstrap --apply_settings(snapshot)--> AudioService

Feature root --request_save(slot_id)--> SaveService
SaveService --save_completed(slot_id) / save_failed(slot_id, code)--> UI coordinator

Feature root --navigate(route_id, payload)--> SceneRouter
SceneRouter --transition_started/finished/failed(route_id, code)--> loading UI / telemetry
```

The application composition root wires cross-service reactions so services do not discover or call
peer Autoloads in `_ready()`. Payloads use immutable or duplicate-safe value data and stable IDs, not
scene Nodes. Do not introduce a generic EventBus for these contracts, emit per-frame global signals,
or make signal handler order part of correctness.

## 5. Make startup explicit

Autoload registration order controls scene-tree insertion and startup order. Treat it as a documented
bootstrap prerequisite, but never as a hidden business dependency or the whole initialization
algorithm.

Choose one explicit topology:

- `app_services.tscn` plus `app_services.gd` as one application-lifetime Autoload scene, with
  Settings/Save/Audio/SceneRouter as owned child services; or
- several narrow Autoloads plus an application composition root registered/created after them that
  receives and wires typed references.

Prefer the Autoload scene when the services share one application lifetime and should expose only one
global composition boundary. Prefer independent Autoloads when their lifecycles and public contracts
are genuinely independent. Do not add five global names merely because five system names exist.

This is a classification example, not fixed scaffolding:

```text
app/
├── app_services.tscn
├── app_services.gd              # application service composition root
└── services/
    ├── settings/
    │   ├── settings_service.gd
    │   ├── settings_defaults.gd
    │   └── default_settings.tres
    ├── save/
    │   └── save_service.gd
    ├── audio/
    │   ├── audio_service.tscn   # stable persistent player subtree
    │   └── audio_service.gd
    └── routing/
        ├── scene_router.gd
        ├── route_catalog.gd
        └── default_routes.tres
```

Create only proven services. A behavior-only service does not need its own scene. Audio earns a
`.tscn` when persistent players form a stable authored subtree. Preserve well-bounded existing
independent Autoloads instead of migrating them to `AppServices` solely to match the example.

```text
AppBootstrap (application composition root)
├── initialize SettingsService
├── apply SettingsSnapshot -> AudioService
├── initialize SaveService metadata
└── initialize route catalog -> SceneRouter initial route
```

Services expose narrow lifecycle methods and state; they do not call one another.

1. Autoload `_ready()` performs only self-contained construction and safe local validation.
2. The application composition root calls idempotent `initialize()` methods in an explicit order.
3. Load and validate settings, then apply the resulting snapshot to audio and other consumers.
4. Initialize save metadata without loading a slot or mutating the current scene.
5. Register/validate the route catalog, then request the initial route.
6. Mark the application ready only after required stages succeed; optional failures degrade through an
   explicit product-approved path.

Do not use `await get_tree().process_frame` to guess when a sibling Autoload is ready. Do not add a
service locator or dependency-injection container merely to hide global dependencies.

Do not emit a one-shot `ready` signal from an Autoload `_ready()` before the main scene can subscribe.
Expose queryable readiness/current snapshots or a connect-and-replay method, then let AppBootstrap
initialize after wiring consumers. Shutdown reverses the declared dependency order, cancels pending
transitions/tweens, flushes explicitly approved dirty settings/checkpoints, disconnects temporary
subscriptions, and releases scene references.

## 6. System-specific failure rules

### Settings

- Validate types and ranges before publishing a new snapshot.
- Separate defaults, current validated values, and persistence.
- Coalesce slider changes or save on confirmation; do not rewrite storage every input frame.
- A corrupt file falls back to validated defaults with an observable warning/state.

### Save

- Use stable slot IDs, schema versions, byte/collection bounds, temporary publication, and a validated
  backup.
- Build a detached snapshot first; loading applies nothing until validation and migration succeed.
- Do not serialize scene paths as authority. Reconstruct from stable content IDs.
- Saving and settings persistence may share small codecs/helpers, but not one giant mutable manager.

### Audio

- Keep persistent music/bus ownership global only when continuity requires it; feature SFX stays local.
- Apply settings through a typed snapshot, validate every bus index, and bound voice pools.
- Model browser audio unlock, hidden-tab resume, and Sample-versus-Stream choice explicitly.
- A missing stream or bus fails locally; it must not block scene routing or corrupt settings.

### Scene router

- Resolve only allowlisted route IDs to typed route definitions; never accept arbitrary external
  `res://` paths.
- Serialize transition requests or use a generation token so stale loads cannot replace a newer route.
- Define loading, transition failure, cancellation, and repeated-current-route behavior.
- Do not use custom `Thread` or `WorkerThreadPool`; verify any loading strategy in the single-threaded
  Web export.
- SceneRouter owns navigation lifecycle, not game rules or authoritative run state.

## 7. Migrate one boundary at a time

1. Capture current behavior with a focused test or scene-level driver.
2. Introduce the typed data/snapshot contract.
3. Extract one service behind a narrow API while keeping a temporary caller adapter if necessary.
4. Move callers and composition-root wiring.
5. Exercise restart, route replacement, corruption/failure, and duplicate-signal paths.
6. Remove the old global access only after searches show no remaining callers.
7. Repeat for the next proven system.

Do not combine Save, Settings, Audio, routing, analytics, and game state into `GameManager`. Do not
rewrite every scene merely to adopt a pattern.

## Completion gate

- [ ] Current and target service maps identify owner, lifetime, state, commands, signals, persistence,
      dependencies, initialization, failure, and shutdown.
- [ ] Every Autoload has evidence for application lifetime; rejected candidates remain scene-owned.
- [ ] The Autoload dependency graph is acyclic and no sibling `_ready()` ordering is required.
- [ ] Startup readiness cannot be missed by the main scene; shutdown unwinds dependencies in reverse.
- [ ] Resources are immutable authored definitions; user data and mutable runtime state have separate
      owners.
- [ ] Save, Settings, Audio, and SceneRouter contracts use typed methods and factual signals without a
      generic bus.
- [ ] Scene replacement and restart do not retain stale Nodes, duplicate subscriptions, tweens, timers,
      or async generations.
- [ ] Focused tests cover service contracts and failures; a scene-level path covers transition and
      restart.
- [ ] Web checks separately cover storage retention, audio unlock/resume, loading behavior, and browser
      lifecycle where those systems are in scope.
- [ ] Performance work cites profiler/scale evidence and does not introduce unsupported threads or
      renderer features.

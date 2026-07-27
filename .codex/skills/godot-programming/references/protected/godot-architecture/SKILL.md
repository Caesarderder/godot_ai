---
name: godot-architecture
description: Plan, harden, or refactor Godot 4.6 GDScript architecture for Builda Web projects. Use before implementing a non-trivial gameplay feature and for a second architecture pass after the gameplay spine works, especially when deciding .tscn/.gd boundaries, typed Resources and signals, Save/Settings/Audio services, SceneRouter and Autoload scope, ownership and lifecycle, dependency injection, or cross-scene events; also use when untangling deep node paths, global singleton coupling, global signal-bus overuse, or inheritance-heavy gameplay code.
---

# Godot Architecture

Design the smallest architecture that makes ownership, dependencies, and event flow obvious. Target Godot 4.6.x, typed GDScript, and Builda's single-threaded Web runtime.

## Pre-implementation blueprint gate

Before writing non-trivial gameplay implementation, read
[references/implementation-blueprint.md](references/implementation-blueprint.md) and record the
current milestone's:

1. target file tree, including deliberate `.tscn`, root `.gd`, pure `.gd`, and `.tres` choices;
2. scene tree, composition root, owner, lifetime, and isolated preview/test boundaries;
3. typed command and signal contracts, including who connects them and how restart avoids duplicates;
4. typed Resource definitions and instances, separated from authoritative mutable runtime state;
5. smallest implementation order that proves one end-to-end ownership spine.

Use `.tscn` plus a root `.gd` for a meaningful runtime owner with stable authored structure and
behavior. Keep editor-authored node hierarchy in scenes instead of constructing the entire stable
tree from one script. Do not force a pair for pure rules/state, behavior-free structural scenes, or
small one-off leaves. Preserve a coherent existing project and waive the full blueprint only for a
small isolated fix whose boundary is already explicit.

## Second-pass architecture hardening

After the first gameplay spine is implemented and exercised, read
[references/architecture-hardening-pass.md](references/architecture-hardening-pass.md) when the
project has proven cross-scene, persistence, settings, audio-continuity, routing, or scale pressure.
Produce a current/target service map, an acyclic dependency and initialization graph, narrow typed
contracts, a one-boundary-at-a-time migration plan, and regression evidence.

Do not treat `Save`, `Settings`, `Audio`, `SceneRouter`, or an event channel as mandatory scaffolding.
Promote each one to an Autoload only when its responsibility must survive scene replacement or serve
independently owned scenes for the application lifetime. Route detailed implementation to
`resource-pattern`, `save-load`, `audio-system`, and `godot-optimization` only when the audited project
needs that domain.

## Start from the current project

1. Inspect `project.godot`, the relevant `.tscn` files, scripts, Autoloads, and tests before proposing a pattern.
2. Identify the feature's composition root: the scene that creates, owns, and tears down the participating nodes.
3. Write down each dependency and event with its sender, receiver, lifetime, and direction.
4. Choose the least indirect communication pattern from the decision tree below.
5. Preserve existing public scene paths and signals unless the task explicitly authorizes a migration.
6. Validate edited scripts and scenes with the project's Godot 4.6 binary and existing tests. Treat Web export or browser checks as separate evidence.

## Communication decision tree

Use this order for each interaction:

```text
Does an owner need to command a node it owns?
  YES -> Call a typed method directly, usually parent -> child.
  NO  -> Continue.

Does a child need to announce a local occurrence without choosing the reaction?
  YES -> Emit a local typed signal; let the nearest owner connect it.
  NO  -> Continue.

Is a required collaborator known when the scene is composed?
  YES -> Inject it explicitly with a typed @export property or setup method.
  NO  -> Continue.

Must an occurrence cross unrelated scene branches or survive scene replacement?
  YES -> Consider a narrow, typed Autoload event channel.
  NO  -> Put orchestration in the nearest common owner.
```

Prefer direct relationships when one node already owns or constructs the other. Indirection is useful only when it removes a real lifetime or reuse dependency.

### Parent to child: direct typed method

Use a method call for commands and queries inside one ownership boundary.

```gdscript
extends Node2D

@onready var health: HealthComponent = %HealthComponent


func apply_hazard_damage(amount: int) -> void:
	health.take_damage(amount)
```

Keep the child's public API small. Avoid reaching through multiple descendants such as `get_node("../../OtherBranch")`.

### Child to owner: local typed signal

Use a signal for facts that may have zero or several local reactions.

```gdscript
class_name HealthComponent
extends Node

signal depleted
signal changed(current: int, maximum: int)

@export_range(1, 100000, 1) var maximum: int = 100
var current: int


func _ready() -> void:
	current = maximum


func take_damage(amount: int) -> void:
	if amount <= 0 or current == 0:
		return
	current = maxi(0, current - amount)
	changed.emit(current, maximum)
	if current == 0:
		depleted.emit()
```

Connect at the composition root so the reusable child does not know scene-specific reactions:

```gdscript
func _ready() -> void:
	health.depleted.connect(_on_health_depleted)
```

### Known collaborator: explicit injection

Use a typed exported node reference for editor-authored scenes. Use a setup method when the parent creates or chooses the collaborator at runtime.

```gdscript
class_name DamageReceiver
extends Area2D

@export var health: HealthComponent

var _ready_to_receive := false

func _ready() -> void:
	if health == null:
		push_error("DamageReceiver requires a HealthComponent")
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	_ready_to_receive = true


func receive_damage(amount: int) -> void:
	if not _ready_to_receive:
		return
	health.take_damage(amount)
```

Treat `assert()` as an additional development diagnostic, not the runtime guard:
release exports can omit assertion checks. A missing required dependency must also
take a safe release path. Disabling processing only stops callbacks; it does not
block public method calls or already-connected signals. Guard every public entry,
connect signals only after successful validation (or disconnect them on failure),
and return before touching the missing collaborator.

Do not silently search arbitrary ancestors or sibling names to hide a required dependency. Optional dependencies may be nullable, but their fallback behavior must be explicit.

### Unrelated lifetimes: narrow global event

Use a global event only when sender and receiver have no useful ownership relationship, such as gameplay publishing a run result while independently owned HUD and analytics scenes react.

```gdscript
# run_events.gd, registered as the RunEvents Autoload
extends Node

signal run_finished(score: int, elapsed_seconds: float)
```

Keep global events factual, typed, and domain-specific. Do not use them for synchronous queries, per-frame data, or commands whose single owner should be explicit. Read [references/global-events.md](references/global-events.md) before adding an event Autoload.

## Shape scenes around ownership

- Let a scene root own creation, wiring, and cleanup for its subtree.
- Split a child into a reusable scene when it has a stable purpose, meaningful configuration, or benefits from isolated preview/testing.
- Keep a small one-off cluster together when splitting would add wiring without creating reuse or clarity.
- Prefer composition for mix-and-match behavior. Use inheritance only for genuine variants that share stable structure and lifecycle.
- Treat plain grouping nodes as editor organization, not automatically as architectural layers.
- Store reusable configuration in typed `Resource` data when multiple instances share a schema; keep live node references out of persistent data.

Do not enforce arbitrary limits such as one scene per concept or a maximum node count. Complexity, ownership, reuse, and change frequency are better split signals. Read [references/scene-composition.md](references/scene-composition.md) for concrete layouts and extraction criteria.

## Keep composition roots thin

`main.gd` is an application composition root, not the game implementation. It may instantiate
top-level scenes and services, wire their contracts, coordinate scene replacement, and own
application startup/shutdown. It may preload fixed `PackedScene` dependencies used only for
top-level routing. It must not implement gameplay rules, input mapping or polling, physics, UI
widget behavior, save formats, audio behavior, arbitrary asset paths, directory scanning, import
configuration, or reusable loading policy.

Before adding logic to `main.gd`, ask which feature, component, screen, or service owns the behavior
and its lifecycle. Extract when a responsibility has its own state, changes for a different reason,
is reused, can be exercised independently, or belongs below the application lifetime. Do not use an
arbitrary line-count threshold; a short composition root can still hide the wrong responsibility.

The same rule applies to level roots, screen roots, and feature roots at their respective scope:
compose and coordinate owned children, but move reusable or independently changing implementation
behind explicit typed contracts. Read
[references/thin-composition-roots.md](references/thin-composition-roots.md) before adding a second
responsibility to a composition root.

## Choose dependency scope deliberately

Use dependencies at the narrowest lifetime that fits:

| Scope | Default technique | Typical examples |
| --- | --- | --- |
| One node and its child | Typed method/property | Health, weapon, animation driver |
| One composed scene | Owner wiring plus local signals | Player controller, enemy coordinator, HUD |
| One level/session | Scene-owned service injected downward | Spawn director, objective tracker |
| Whole application | Small Autoload service | Settings, save boundary, audio routing |
| Cross-scene occurrence | Typed event Autoload | Run finished, profile changed |

Autoloads are long-lived roots, not a default dependency container. Avoid a generic service locator unless runtime substitution is a demonstrated requirement and ownership cannot express it more clearly. If one is unavoidable, expose a narrow typed access layer, fail clearly for missing required services, and keep registration in one composition root.

Read [references/wiring-recipes.md](references/wiring-recipes.md) for editor wiring, runtime construction, optional collaborators, and test seams.

## Component boundaries

Extract a component when behavior has a coherent API and can operate without knowing a particular parent scene. A component may be a script on a node or an instanced scene; it does not need its own `.tscn` file when it has no reusable child structure.

Use these checks:

- Can its responsibility be described without naming its current owner?
- Are required collaborators explicit?
- Does it expose commands as methods and occurrences as signals?
- Can it be exercised in a minimal scene?
- Would extraction reduce duplication or change coupling?

Do not prohibit every sibling reference. A composition root may wire siblings directly because coordinating them is its job. The problem is a reusable child discovering siblings through fragile paths or parent assumptions.

## Guardrails for Builda Web

- Use Godot 4.6.x APIs and GDScript only.
- Keep runtime logic compatible with the single-threaded Web export. Do not introduce `Thread`, `WorkerThreadPool`, or assumptions about `SharedArrayBuffer`.
- Keep game runtime architecture independent of editor-only tooling.
- Avoid global events carrying nodes across scene changes unless receivers validate instance lifetime. Prefer stable IDs or immutable value data for delayed handling.
- Avoid deeply chained synchronous signal cascades. Put multi-step sequencing in an explicit owner method.
- Avoid event buses for high-frequency position, physics, animation, or input updates; use owned references or local state.
- Never encode required initialization order as an undocumented Autoload side effect.

## Review checklist

- [ ] Non-trivial implementation started from a target file/scene, signal, and Resource blueprint.
- [ ] Meaningful runtime owners use an explicit scene boundary and root script, or record why one side
      of the `.tscn`/`.gd` pair is unnecessary.
- [ ] Every participating node has an identifiable owner and lifetime.
- [ ] Commands go to an explicit receiver; facts are emitted as typed signals.
- [ ] Signal contracts identify the emitter, connector, typed payload, receiver, and restart lifetime.
- [ ] Authored/shared Resources are separated from authoritative mutable runtime state.
- [ ] Required dependencies are visible in declarations or setup calls.
- [ ] Missing required dependencies fail safely in release exports; correctness does not depend on `assert()`.
- [ ] Global events are reserved for genuinely unrelated scene branches/lifetimes.
- [ ] Scene splits improve reuse, isolation, or clarity rather than satisfying a numeric rule.
- [ ] `main.gd` contains only top-level composition, scene switching, and application lifecycle.
- [ ] Gameplay, input, physics, UI, save, audio, and asset implementation live under their actual
      owner rather than a composition root.
- [ ] Components do not discover required collaborators through fragile ancestor/sibling paths.
- [ ] Autoloads have narrow responsibilities and no hidden initialization-order dependency.
- [ ] A second-pass service map proves the application lifetime of every Save, Settings, Audio,
      SceneRouter, or event Autoload instead of assuming it.
- [ ] Autoload dependencies are acyclic; cross-service reactions are wired by the application
      composition root rather than sibling `_ready()` calls.
- [ ] Signal handlers cannot create accidental cycles or uncontrolled cascades.
- [ ] Code stays within Godot 4.6.x, typed GDScript, runtime APIs, and single-threaded Web constraints.
- [ ] Godot 4.6 parse/headless checks pass; Web behavior is reported only if exported and exercised.

# Global event recipes

Add a global event channel only after ruling out direct owner wiring and a scene-owned service.

## Good fit

A typed event Autoload is useful when:

- sender and receivers live in unrelated scene branches;
- receivers may appear or disappear independently;
- the event is a completed fact, not a request for work or state;
- no natural scene owner can connect both sides without becoming global itself.

Examples include profile settings changing, a run finishing, or a language selection changing across independently owned UI scenes.

## Poor fit

Avoid global events for:

- synchronous queries such as requesting the player's position;
- commands with one clear receiver;
- per-frame position, physics, input, or animation updates;
- event chains where handler order affects correctness;
- local child-to-parent communication;
- authoritative state that should live in a service or model.

## Narrow Autoload

Prefer a domain channel instead of one application-wide catch-all bus:

```gdscript
# profile_events.gd, registered as ProfileEvents
extends Node

signal locale_changed(locale: StringName)
signal accessibility_changed(reduce_motion: bool)
```

Emit immutable values or stable identifiers when delivery may outlive a scene. Passing a `Node` is acceptable only for immediate events whose listeners validate `is_instance_valid()` and do not retain the reference.

## Subscribe and disconnect

In GDScript, a connection to a bound object is normally removed when that object is freed. Explicit disconnection is still useful when a node temporarily subscribes while remaining alive:

```gdscript
func _enter_tree() -> void:
	if not ProfileEvents.locale_changed.is_connected(_on_locale_changed):
		ProfileEvents.locale_changed.connect(_on_locale_changed)


func _exit_tree() -> void:
	if ProfileEvents.locale_changed.is_connected(_on_locale_changed):
		ProfileEvents.locale_changed.disconnect(_on_locale_changed)
```

Avoid duplicate connections when a node can re-enter the tree.

## Prevent event cascades

Let one owner coordinate multi-step reactions. A handler should not re-emit the event it is currently handling. When one fact must cause several ordered effects, connect one coordinator and call those effects explicitly so ordering and failures remain visible.

## Test

Test the event contract separately from scene behavior:

1. Connect a recorder callable to the real channel or an isolated channel instance.
2. Emit one typed event.
3. Assert the payload and emission count.
4. For a consumer, emit the event and assert only its observable reaction.
5. Exercise tree exit/re-entry when subscriptions are conditional.


# Runtime pitfalls and measured optimization

## Contents

1. Shared Resources
2. Static lifetime
3. Callable and deferred work
4. Dynamic dispatch
5. Profiler-guided changes

## Shared Resources

Loaded Resource assets are cached and shared by reference. Treat exported Resources as definitions unless shared mutation is intentional.

```gdscript
@export var definition: ItemDefinition
var durability: int

func _ready() -> void:
    durability = definition.max_durability
```

If an instance truly needs a mutable Resource copy, duplicate it deliberately and decide whether nested subresources must also be duplicated.

## Static lifetime

Static variables are associated with the script rather than a scene instance. Scene reload does not mean a static gameplay value resets.

Use static functions for stateless helpers or state whose lifetime is intentionally process-wide. Use a scene owner or explicit service for session state.

## Callable and deferred work

A long-lived Array or Dictionary of Callables may retain captured objects. Remove registrations when their ownership ends.

`call_deferred()` schedules work for an idle step. Use it to postpone operations that cannot safely occur during the current callback, such as some scene-tree mutations. It does not create a worker thread, make heavy computation cheaper, or guarantee the target will still be valid.

## Dynamic dispatch

Direct typed calls are easier to validate and faster than reflective calls. When dynamic dispatch is required:

1. Convert external strings to the smallest accepted `StringName` domain.
2. Reject names outside an allowlist.
3. Check `has_method()`.
4. Validate argument shapes before `callv()`.

Never call a method name from save, network, or mod content without an allowlist.

## Profiler-guided changes

Change code only after identifying a real hot path.

Common evidence-backed transformations:

- Cache stable node references when repeated path lookup appears in a hot callback.
- Update UI from state-change signals instead of formatting the same text every frame.
- Reuse a member buffer when repeated temporary collection allocation is visible in a hot path.
- Use `Packed*Array` for large homogeneous data passed to engine APIs.
- Reduce signal frequency only when profiling and product behavior show a signal storm.

After changing a hot path, measure the same scenario again. Preserve readability when the gain is unmeasurable.

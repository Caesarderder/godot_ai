# Async and lifecycle patterns

## Contents

1. Classify each await
2. Revalidate dependencies
3. Suppress stale completions
4. Model timeout or cancellation
5. Avoid initialization races

## Classify each await

Before an `await`, identify:

- which object owns the operation;
- what signal or coroutine completes it;
- whether completion is guaranteed;
- what can be freed, leave the tree, or be replaced while waiting;
- whether more than one invocation can overlap.

Do not assume a signal will eventually fire. Check an already-complete state before waiting.

```gdscript
func wait_until_open() -> void:
    if is_open:
        return
    await opened
```

## Revalidate dependencies

Validate engine `Object` references with `is_instance_valid()` after a delay if another owner can free them. Validate `Node.is_inside_tree()` when scene membership matters. Plain `!= null` does not detect a freed non-`RefCounted` object.

```gdscript
func animate_target(target: CanvasItem) -> void:
    await get_tree().create_timer(0.2).timeout
    if not is_instance_valid(target) or not target.is_inside_tree():
        return
    target.visible = false
```

Do not rely on a post-await `is_instance_valid(self)` check as a cancellation mechanism. Store cancellation or generation state on a longer-lived owner when work must be invalidated explicitly.

## Suppress stale completions

Use a monotonically increasing generation for latest-request-wins UI and loading flows.

```gdscript
var _generation: int = 0

func refresh(query: String) -> void:
    _generation += 1
    var expected := _generation
    var result: Dictionary = await service.search(query)
    if expected != _generation or not is_inside_tree():
        return
    _render(result)

func cancel_refresh() -> void:
    _generation += 1
```

This prevents stale writes; it does not cancel underlying network or engine side effects. Use the dependency's real cancellation API when one exists.

## Model timeout or cancellation

Godot 4.6 does not provide `Signal.any()`. Do not wait independently on two signals and let both mutate final state. Give one operation object or owner responsibility for emitting exactly one typed completion result.

```gdscript
signal completed(result: Dictionary)

var _finished: bool = false

func succeed(value: Dictionary) -> void:
    if _finished:
        return
    _finished = true
    completed.emit({"ok": true, "value": value})

func time_out() -> void:
    if _finished:
        return
    _finished = true
    completed.emit({"ok": false, "error": "timeout"})
```

Connect the underlying success signal and a timer to these guarded methods, then await `completed`. Disconnect or stop remaining sources when practical.

## Avoid initialization races

Keep `_ready()` synchronous long enough to establish invariants and connect required signals. Launch longer work from a separate method.

Remember that child `_ready()` callbacks run before the parent callback. If children need parent-owned data, let the parent call `child.configure(...)` after its own synchronous setup.

Test at least:

- owner exits the tree during the wait;
- referenced target is freed;
- a second request completes before the first;
- completion state is already true before waiting;
- timeout and success arrive in the same frame.

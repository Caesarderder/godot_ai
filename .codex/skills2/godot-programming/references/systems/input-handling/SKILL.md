---
name: input-handling
description: Use when implementing Godot 4.6 GDScript input actions, propagation, keyboard, mouse, gamepad, touch, buffering, and rebinding for Web projects
---

# Input Handling for Godot 4.6 Web

Builda defaults to Godot 4.6.x and GDScript. Define gameplay intent in the Input Map and keep device-specific events at the input boundary.

## 1. Input Flow

```text
hardware event
  → _input()
  → _shortcut_input()
  → Control UI handling
  → _unhandled_key_input()
  → _unhandled_input()
```

Use `_unhandled_input()` for discrete gameplay actions so focused UI can consume them first. Poll held actions in `_physics_process()` for continuous movement. Reserve `_input()` for cases that must run before UI, such as captured mouse look.

## 2. Input Map First

Define semantic actions such as `move_left`, `jump`, `attack`, `interact`, and `pause` in **Project Settings → Input Map**. Do not branch gameplay on raw keycodes.

Add actions in code only for a deliberate rebinding/mod workflow and guard creation with `InputMap.has_action()`. Full persistence patterns are in [references/action-rebinding.md](references/action-rebinding.md).

## 3. Discrete and Continuous Input

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        jump_requested = true
        get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector(
        "move_left",
        "move_right",
        "move_up",
        "move_down"
    )
    velocity = direction * speed

    if jump_requested:
        jump_requested = false
        _jump()

    move_and_slide()
```

When a short press must survive until a physics rule can consume it, buffer the intent with a bounded timer. See [references/input-buffering.md](references/input-buffering.md).

## 4. Mouse and UI Focus

Use `InputEventMouseMotion.relative` for captured look and guard it with the active mouse mode:

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_camera(event.relative)
```

Menus should release the mouse and consume their own actions. Decorative Controls should use `MOUSE_FILTER_IGNORE` when they must not block gameplay clicks. See [references/mouse.md](references/mouse.md) and [references/event-propagation.md](references/event-propagation.md).

## 5. Gamepad

Use Input Map actions for buttons and axes. Detect connection changes to update prompts, but keep gameplay bound to actions:

```gdscript
func _ready() -> void:
    Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
    print_debug("joypad device=%d connected=%s" % [device, connected])
```

Configure deadzones per action and validate them on representative controllers. Vibration is optional and must degrade safely when the browser/controller does not support it. Browser focus, user interaction, and platform mappings can affect Web gamepad availability, so test the exported Web build rather than inferring support from desktop runs.

See [references/gamepad.md](references/gamepad.md) for Godot 4.6-compatible detection, axes, vibration, and prompt switching.

## 6. Touch

Use `InputEventScreenTouch` for press/release and `InputEventScreenDrag` for drag, tracking fingers by `event.index`.

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_started(event.index, event.position)
        else:
            _touch_ended(event.index, event.position)
    elif event is InputEventScreenDrag:
        _touch_dragged(event.index, event.position, event.relative)
```

If a project needs an on-screen stick in Godot 4.6, implement it as an explicit project UI component that converts touch drag into the same semantic Input Map actions, or reuse an addon only when that addon already exists and is approved.

See [references/touch.md](references/touch.md).

## 7. Rebinding

Rebinding has three explicit phases:

1. enter capture mode and accept one allowed `InputEvent`;
2. replace the selected action's events through `InputMap`;
3. serialize the supported event fields to `user://` and restore them on launch.

Filter modifier-only presses and preserve a cancel path. Do not serialize arbitrary Variant/object graphs. See [references/action-rebinding.md](references/action-rebinding.md).

## 8. Pause and Propagation

After consuming an event, call `get_viewport().set_input_as_handled()` when it must not reach later handlers. Pause-menu input nodes need `process_mode = PROCESS_MODE_ALWAYS`; gameplay nodes should normally pause with the tree.

Own the pause action in a dedicated UI/controller node, not in the player body.
That owner must keep processing while the tree is paused so the same action can
resume gameplay:

```gdscript
# pause_controller.gd — attach under the UI layer, outside gameplay ownership.
extends Node

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("pause"):
        return
    get_tree().paused = not get_tree().paused
    get_viewport().set_input_as_handled()
```

Keep movement, attack, and interaction handlers on pausable gameplay nodes. When
opening a pause menu, move focus into that menu so its Controls consume navigation
before gameplay handlers.

Avoid handling the same action in both `_input()` and `_unhandled_input()`, which commonly produces duplicate triggers.

## Common Pitfalls

| Symptom | Check |
|---|---|
| Action is never recognized | Action exists in Input Map and spelling matches |
| Gameplay fires through UI | Move discrete action to `_unhandled_input()` and inspect Control focus/filter |
| Mouse look continues in menus | Require `MOUSE_MODE_CAPTURED` |
| Stick drifts | Tune action deadzones on real devices |
| Controller prompt never changes | Handle `joy_connection_changed` and last-used device events |
| Touch test differs from device | Desktop emulation is only a smoke check; test exported Web touch |
| Action fires twice | One action is handled in multiple propagation stages |
| Pause menu ignores input | Menu process mode is not `PROCESS_MODE_ALWAYS` |

## Checklist

- [ ] Gameplay uses semantic Input Map actions rather than raw keycodes.
- [ ] Discrete actions flow through `_unhandled_input()` unless a documented reason requires earlier handling.
- [ ] Continuous movement uses action polling in `_physics_process()`.
- [ ] Consumed events are marked handled where propagation must stop.
- [ ] Mouse look requires captured mouse mode.
- [ ] Gamepad deadzones and exported-Web behavior are tested on representative devices.
- [ ] Touch tracks finger indices and does not depend on unavailable engine nodes.
- [ ] Rebindings are validated and persisted as bounded supported fields.
- [ ] Pause UI processes always while gameplay remains paused.

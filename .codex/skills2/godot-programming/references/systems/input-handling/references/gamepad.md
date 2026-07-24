# Gamepad Support in Godot 4.6

## Detect Controllers

```gdscript
func _ready() -> void:
    Input.joy_connection_changed.connect(_on_joy_connection_changed)
    for device in Input.get_connected_joypads():
        print_debug("joypad device=%d name=%s" % [device, Input.get_joy_name(device)])


func _on_joy_connection_changed(device: int, connected: bool) -> void:
    print_debug("joypad device=%d connected=%s" % [device, connected])
```

Use the Input Map for gameplay buttons and axes. Direct `get_joy_axis()` polling is appropriate only for diagnostics or device-specific UI; it couples code to a physical axis mapping.

## Analog Input

```gdscript
var movement := Input.get_vector(
    "move_left",
    "move_right",
    "move_up",
    "move_down"
)
```

Set deadzones per Input Map action and test on real devices. Avoid adding a second manual deadzone unless the gameplay contract explicitly needs a different response curve.

## Vibration

Godot 4.6 can request vibration, but browsers and controllers may ignore it:

```gdscript
Input.start_joy_vibration(device, 0.5, 0.3, 0.2)
Input.stop_joy_vibration(device)
```

Treat vibration as optional feedback and never gate gameplay on its availability.

## Last-Used Device for Prompts

Track event classes instead of assuming a numeric device ID:

```gdscript
signal prompt_device_changed(kind: StringName)

var _last_kind: StringName = &"keyboard_mouse"


func _input(event: InputEvent) -> void:
    var kind := _last_kind
    if event is InputEventJoypadButton or event is InputEventJoypadMotion:
        kind = &"gamepad"
    elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
        kind = &"keyboard_mouse"

    if kind != _last_kind:
        _last_kind = kind
        prompt_device_changed.emit(kind)
```

Validate gamepad connection, focus, and prompt switching in the exported Web build.

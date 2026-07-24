# Action Rebinding at Runtime

Reference for `skills/input-handling/SKILL.md` — adding actions in code, plus a safe
GDScript rebinding flow: capture a supported event, validate it, replace the action,
and persist only an explicit field allowlist.

> ← Back to [SKILL.md](../SKILL.md)

---
## 2. Input Map Setup — Adding Actions in Code

```gdscript
# Typically done in an autoload _ready(), not every frame
func _ready() -> void:
    if not InputMap.has_action("move_left"):
        InputMap.add_action("move_left")
        var event := InputEventKey.new()
        event.physical_keycode = KEY_A
        InputMap.action_add_event("move_left", event)
```


> **Best practice:** Define actions in the editor Input Map. Only add actions in code for dynamically generated bindings or mod support.

---
## 7. Action Rebinding at Runtime

Allow players to change their key bindings in-game.

### GDScript

```gdscript
# rebind_button.gd — attach to a Button in a settings menu
extends Button

@export var action_name: String = "jump"

var _is_listening: bool = false


func _ready() -> void:
    _update_label()


func _pressed() -> void:
    _is_listening = true
    text = "Press a key..."


func _unhandled_input(event: InputEvent) -> void:
    if not _is_listening:
        return

    if not InputMap.has_action(action_name):
        push_error("Unknown input action: %s" % action_name)
        _is_listening = false
        return

    # Accept keyboard, mouse button, and gamepad button events
    if not (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
        return

    # Ignore modifier-only presses (Shift, Ctrl, Alt alone)
    if event is InputEventKey and event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
        return

    # Replace all existing events for this action
    InputMap.action_erase_events(action_name)
    InputMap.action_add_event(action_name, event)

    _is_listening = false
    _update_label()
    get_viewport().set_input_as_handled()


func _update_label() -> void:
    var events := InputMap.action_get_events(action_name)
    if events.size() > 0:
        text = "%s: %s" % [action_name, events[0].as_text()]
    else:
        text = "%s: (unbound)" % action_name
```

### Saving & Loading Bindings

```gdscript
# Only these event families and fields are persisted. Never deserialize an
# arbitrary Variant or Object from a user-writable ConfigFile.
func _encode_event(event: InputEvent) -> Dictionary:
    if event is InputEventKey:
        var key := event as InputEventKey
        return {
            "type": "key",
            "physical_keycode": key.physical_keycode,
            "keycode": key.keycode,
            "shift": key.shift_pressed,
            "alt": key.alt_pressed,
            "ctrl": key.ctrl_pressed,
            "meta": key.meta_pressed,
        }
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        return {"type": "mouse_button", "button_index": mouse.button_index}
    if event is InputEventJoypadButton:
        var joy := event as InputEventJoypadButton
        return {
            "type": "joypad_button",
            "button_index": joy.button_index,
            "device": joy.device,
        }
    return {}


func _decode_event(data: Variant) -> InputEvent:
    if not data is Dictionary or not data.has("type"):
        return null
    match data["type"]:
        "key":
            if not data.has_all(["physical_keycode", "keycode", "shift", "alt", "ctrl", "meta"]):
                return null
            if typeof(data["physical_keycode"]) != TYPE_INT or typeof(data["keycode"]) != TYPE_INT:
                return null
            for field in ["shift", "alt", "ctrl", "meta"]:
                if typeof(data[field]) != TYPE_BOOL:
                    return null
            if data["physical_keycode"] < 0 or data["keycode"] < 0:
                return null
            if data["physical_keycode"] == 0 and data["keycode"] == 0:
                return null
            var key := InputEventKey.new()
            key.physical_keycode = int(data["physical_keycode"])
            key.keycode = int(data["keycode"])
            key.shift_pressed = bool(data["shift"])
            key.alt_pressed = bool(data["alt"])
            key.ctrl_pressed = bool(data["ctrl"])
            key.meta_pressed = bool(data["meta"])
            return key
        "mouse_button":
            if not data.has("button_index") or typeof(data["button_index"]) != TYPE_INT:
                return null
            if data["button_index"] < MOUSE_BUTTON_LEFT or data["button_index"] > MOUSE_BUTTON_XBUTTON2:
                return null
            var mouse := InputEventMouseButton.new()
            mouse.button_index = int(data["button_index"])
            return mouse
        "joypad_button":
            if not data.has_all(["button_index", "device"]):
                return null
            if typeof(data["button_index"]) != TYPE_INT or typeof(data["device"]) != TYPE_INT:
                return null
            if data["button_index"] < 0 or data["button_index"] >= JOY_BUTTON_MAX:
                return null
            if data["device"] < -1:
                return null
            var joy := InputEventJoypadButton.new()
            joy.button_index = int(data["button_index"])
            joy.device = int(data["device"])
            return joy
    return null


func save_bindings(config: ConfigFile) -> void:
    for action in InputMap.get_actions():
        if action.begins_with("ui_"):
            continue
        var event_data: Array[Dictionary] = []
        for event in InputMap.action_get_events(action):
            var encoded := _encode_event(event)
            if not encoded.is_empty():
                event_data.append(encoded)
        config.set_value("input", action, event_data)
    config.save("user://input_bindings.cfg")


# Load saved bindings
func load_bindings() -> void:
    var config := ConfigFile.new()
    if config.load("user://input_bindings.cfg") != OK:
        return
    for action in config.get_section_keys("input"):
        var action_name := StringName(action)
        if action.begins_with("ui_") or not InputMap.has_action(action_name):
            continue
        var raw_event_data: Variant = config.get_value("input", action_name, [])
        if typeof(raw_event_data) != TYPE_ARRAY:
            continue
        var event_data: Array = raw_event_data
        var validated: Array[InputEvent] = []
        for entry in event_data:
            var event := _decode_event(entry)
            if event != null:
                validated.append(event)
        # Do not erase a working binding when the persisted value is malformed.
        if validated.is_empty():
            continue
        InputMap.action_erase_events(action_name)
        for event in validated:
            InputMap.action_add_event(action_name, event)
```


---

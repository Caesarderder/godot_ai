---
name: hud-system
description: Use when building health bars, score displays, minimaps, notifications, and damage numbers in Godot 4.6 GDScript Web projects
---

# HUD Systems in Godot 4.6

Use Godot 4.6.x GDScript APIs that work in Builda's single-threaded Web export.

> **Related skills:** **godot-ui** for Control node layout and themes, **godot-architecture** for health ownership and local signal boundaries, **inventory-system** for inventory UI patterns, and **2d-essentials** for CanvasLayer setup and draw order.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

---

## 1. HUD Architecture

### Why CanvasLayer

A `CanvasLayer` renders its children in a fixed screen-space layer that is completely independent of any `Camera2D` or `Camera3D` transform. Without it, HUD nodes attached to the scene root still move with the camera when you pan or zoom. Wrapping all HUD nodes in a `CanvasLayer` (layer `≥ 1`) ensures the HUD always stays in place regardless of camera movement.

### Scene Tree

```
World (Node2D / Node3D)
├── TileMapLayer          ← game world
├── Player (CharacterBody2D)
│   ├── Camera2D
│   ├── HealthComponent
│   └── HurtboxComponent
├── Enemies
└── HUD (CanvasLayer — layer: 1)
    ├── MarginContainer (anchor: Full Rect — provides edge padding)
    │   ├── TopBar (HBoxContainer)
    │   │   ├── HealthBarPanel (PanelContainer)
    │   │   │   └── HealthBar (TextureProgressBar or ProgressBar)
    │   │   └── ScoreLabel (Label)
    │   └── BottomBar (HBoxContainer)
    │       └── InteractionPrompt (Label — hidden by default)
    ├── DamageNumbersLayer (Node2D — world-space spawning point)
    ├── MinimapContainer (SubViewportContainer)
    │   └── MinimapViewport (SubViewport)
    │       ├── MinimapCamera (Camera2D)
    │       └── MinimapWorld (mirrors or references world nodes)
    └── NotificationStack (VBoxContainer — anchored top-right)
```

**Key rules:**
- Keep all HUD scenes under a single `CanvasLayer`. Do not mix HUD nodes into the game world tree.
- Use `layer = 1` for the main HUD. Use higher values (e.g. `10`) for overlays or pause menus that must appear above the HUD.
- Damage numbers are an exception — they can live in a `Node2D` child of an identity-transform `CanvasLayer`. Convert world coordinates to HUD/viewport canvas coordinates with `get_viewport().get_canvas_transform()`; do not use OS screen coordinates for a CanvasLayer child.

---

## 2. Health Bar

### ProgressBar vs TextureProgressBar

| Node | When to use |
|---|---|
| `ProgressBar` | Prototyping, plain-colour bars |
| `TextureProgressBar` | Pixel-art or stylised bars using sprite sheets |

Both expose `min_value`, `max_value`, and `value`. Set `step = 0` so tweening produces a smooth animation rather than snapping to integer steps.

### GDScript

```gdscript
## health_bar.gd — attach to a ProgressBar or TextureProgressBar
class_name HealthBar
extends ProgressBar

## Reference to the HealthComponent this bar tracks.
## Assign in the Inspector or connect programmatically from the HUD root.
@export var health_component: HealthComponent

## Duration (seconds) for the smooth tween on health change.
@export var tween_duration: float = 0.25

var _tween: Tween


func _ready() -> void:
    step = 0.0  # allow fractional values for smooth animation
    if health_component:
        _connect_component(health_component)


## Call this if the HealthComponent is not available at _ready time
## (e.g. the player spawns after the HUD).
func bind(component: HealthComponent) -> void:
    if health_component:
        health_component.health_changed.disconnect(_on_health_changed)
    health_component = component
    _connect_component(component)


func _connect_component(component: HealthComponent) -> void:
    max_value = component.max_health
    value     = component.current_health
    component.health_changed.connect(_on_health_changed)


func _on_health_changed(current: int, maximum: int) -> void:
    max_value = maximum
    _animate_to(current)


func _animate_to(target_value: float) -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.set_ease(Tween.EASE_OUT)
    _tween.set_trans(Tween.TRANS_QUAD)
    _tween.tween_property(self, "value", target_value, tween_duration)
```

**Tip:** If you use `TextureProgressBar`, set `fill_mode` to `FILL_LEFT_TO_RIGHT` and assign your bar texture to `texture_progress`. The `value` / `max_value` ratio drives how much of the texture is revealed.

---

## 3. Score / Label Display

### GDScript

```gdscript
## score_display.gd — attach to a Label
class_name ScoreDisplay
extends Label

## Duration (seconds) to count from old to new score value.
@export var count_duration: float = 0.4

var _displayed_score: int = 0
var _tween: Tween


func _ready() -> void:
    EventBus.score_changed.connect(_on_score_changed)
    text = "0"


func _on_score_changed(new_score: int) -> void:
    _animate_counter(_displayed_score, new_score)


func _animate_counter(from: int, to: int) -> void:
    if _tween:
        _tween.kill()

    _tween = create_tween()
    _tween.set_ease(Tween.EASE_OUT)
    _tween.set_trans(Tween.TRANS_QUAD)
    # Tween an intermediate float; update the label text each step.
    _tween.tween_method(_set_counter_value, float(from), float(to), count_duration)


func _set_counter_value(value: float) -> void:
    _displayed_score = int(value)
    text = str(_displayed_score)
```

**EventBus signals needed:**

```gdscript
# autoloads/event_bus.gd
signal score_changed(new_score: int)
```

Emit from wherever points are awarded:

```gdscript
# Inside a collectible or enemy death handler
EventBus.score_changed.emit(GameState.score)
```

---

## 4. Damage Numbers

Floating "−25" labels that rise and fade above the hit point. Pooled in a HUD-side spawner; world position is converted to viewport/HUD canvas coordinates via `get_viewport().get_canvas_transform()`. Optional crit colorization before spawn.

> See [references/damage-numbers.md](references/damage-numbers.md) for the GDScript DamageNumber scene and pooled spawner.

---

## 5. Notification System

Toast / notification stack — a `VBoxContainer` anchored top-right with `max_visible` clamping and queue-driven dismissal. New toasts wait for an old one to expire before showing.

> See [references/notifications.md](references/notifications.md) for the GDScript stack with auto-dismiss timers.

---

## 6. Minimap Concept

Render a top-down view via a dedicated `SubViewport` + `Camera2D` that follows the player. Display the SubViewport texture in a `TextureRect` inside the HUD. Optional circular mask via `ColorRect` shader. Set `render_target_update_mode = UPDATE_ALWAYS`.

> See [references/minimap.md](references/minimap.md) for the SubViewport setup, GDScript MinimapCamera, and circular-mask shader.

---

## 7. Interaction Prompts

HUD-space "Press [E] to interact" prompt — a `Label` inside an identity-transform HUD `CanvasLayer` that follows an interactable's viewport position each frame. Driven by `body_entered` / `body_exited` on the interactable's `Area2D`. Use `InputMap.action_get_events(name)` to display the correct key for the player's current binding.

> See [references/interaction-prompts.md](references/interaction-prompts.md) for the GDScript prompt and Interactable Area2D pair.

---

## 8. Checklist

- [ ] All HUD nodes are children of a `CanvasLayer` with `layer >= 1` so they are unaffected by camera transforms
- [ ] `ProgressBar.step` is set to `0.0` for smooth tween animation rather than integer snapping
- [ ] Health bar binds to `HealthComponent.health_changed` signal — does not poll in `_process`
- [ ] Tween is killed (`_tween.kill()`) before starting a new one so rapid damage does not stack animations
- [ ] Score counter uses `tween_method` to interpolate the displayed integer — not a jump cut
- [ ] World-following HUD positions are converted to viewport/HUD canvas space with `get_viewport().get_canvas_transform()`; OS screen transforms are not assigned to CanvasLayer children
- [ ] Damage number pool size is large enough that labels are not recycled before their tween completes
- [ ] Notification stack enforces `max_visible` and re-checks the queue after each dismissal
- [ ] Toast auto-dismiss uses a `Timer` node — not `await get_tree().create_timer()`
- [ ] `SubViewport` for minimap has `render_target_update_mode = UPDATE_ALWAYS`
- [ ] Minimap `Camera2D` zoom and cull mask are configured so only the intended layers are visible
- [ ] Interaction prompt converts the interactable's world position each frame — not cached at spawn time
- [ ] `InputMap.action_get_events()` is used to display the correct key for the player's current binding
- [ ] HUD nodes that do not need input set `mouse_filter = MOUSE_FILTER_IGNORE` to avoid blocking game clicks

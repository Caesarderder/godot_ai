---
name: godot-ui
description: Use when building Control-node interfaces, themes, anchors, containers, and layout patterns in Godot 4.6 GDScript Web projects
---

# Godot UI — Control Nodes, Themes & Layout

Use Godot 4.6.x GDScript APIs that work in Builda's single-threaded Web export.

> **Related skills:** **responsive-ui** for multi-resolution scaling, **hud-system** for in-game HUD patterns, and **tween-animation** for UI transition and animation effects. Build dialogue presentation from the current project's Control and state contracts.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

---

## 1. Control Node Hierarchy

### How Control Differs from Node2D

`Control` is the base class for all UI nodes. It lives in a separate branch of the scene tree from `Node2D`/`Node3D` and has a fundamentally different layout model.

| Feature | `Node2D` | `Control` |
|---|---|---|
| Position model | World-space `position` (pixels from parent) | Anchor + offset relative to parent rect |
| Size | No intrinsic size | Has `size`, `minimum_size`, `custom_minimum_size` |
| Theme | None | Inherits and overrides `Theme` resources |
| Focus | Not applicable | Built-in focus system (`focus_mode`, `grab_focus()`) |
| Mouse events | Manual via `_input` | `gui_input`, `mouse_entered`, `mouse_exited` |
| Layout helpers | None | `Container` subclasses auto-arrange children |

### Control as Base Class

Every UI widget (`Button`, `Label`, `LineEdit`, etc.) extends `Control`. The key properties defined on `Control` itself are:

- `anchor_left`, `anchor_top`, `anchor_right`, `anchor_bottom` — fractional values (0.0–1.0) relative to the parent's rect
- `offset_left`, `offset_top`, `offset_right`, `offset_bottom` — pixel offsets applied after the anchor is resolved
- `size_flags_horizontal`, `size_flags_vertical` — how the node participates in `Container` layout
- `theme` — a `Theme` resource; if `null` the node walks up the tree to find the nearest ancestor with one
- `focus_mode` — controls whether the node can receive keyboard/gamepad focus

Place UI nodes inside a `CanvasLayer` (or directly under the scene root's built-in canvas) so they always render on top of the 3D/2D world and are not affected by `Camera` transforms.

---

## 2. Common Container Nodes

| Container | Purpose | When to Use |
|---|---|---|
| `VBoxContainer` | Stacks children vertically, top to bottom | Lists, option rows, vertical menus |
| `HBoxContainer` | Stacks children horizontally, left to right | Toolbars, stat rows, horizontal nav |
| `GridContainer` | Arranges children in a fixed-column grid | Inventory grids, key-binding tables |
| `MarginContainer` | Adds padding around a single child | Wrapping any node to give it breathing room |
| `PanelContainer` | Draws a `StyleBox` background, then lays out children | Card UI, dialog boxes, HUD panels |
| `ScrollContainer` | Makes its single child scrollable; clips overflow | Long lists, logs, scrollable settings |
| `TabContainer` | Stacks children as named tabs; shows one at a time | Settings screens, multi-section panels |

**Sizing tips:**
- Set `size_flags_horizontal = SIZE_EXPAND_FILL` on children that should fill available space.
- Use `custom_minimum_size` to prevent a child from collapsing to zero.
- `MarginContainer` reads margin from the theme property `margin_*`; override at runtime with `add_theme_constant_override("margin_left", 16)`.

---

## 3. Anchors & Margins

### How Anchor Presets Work

An anchor is a point on the **parent** rect expressed as a fraction (0 = top/left edge, 1 = bottom/right edge). Godot resolves the final pixel position of each edge as:

```
final_left   = parent_width  * anchor_left   + offset_left
final_top    = parent_height * anchor_top    + offset_top
final_right  = parent_width  * anchor_right  + offset_right
final_bottom = parent_height * anchor_bottom + offset_bottom
```

The editor exposes built-in presets:

| Preset | Anchor values | Use case |
|---|---|---|
| Full Rect | L=0, T=0, R=1, B=1 | Overlay / fill parent — most common for root UI |
| Center | L=0.5, T=0.5, R=0.5, B=0.5 | Fixed-size widget centred in parent |
| Top Left | L=0, T=0, R=0, B=0 | Fixed-size widget pinned to top-left corner |
| Top Right | L=1, T=0, R=1, B=0 | Fixed-size widget pinned to top-right corner |
| Bottom Center | L=0.5, T=1, R=0.5, B=1 | HUD element anchored to bottom centre |

### Setting Anchors in Code

**GDScript:**

```gdscript
# Fill parent completely (equivalent to "Full Rect" preset)
$Panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# Anchor to top-right corner, fixed 200x60 size
$HUDLabel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
$HUDLabel.size = Vector2(200.0, 60.0)
# Fine-tune with a 16 px margin from the right and top edges
$HUDLabel.offset_right  = -16.0
$HUDLabel.offset_top    =  16.0

# Custom responsive anchor: right half of screen, full height
$SidePanel.anchor_left   = 0.5
$SidePanel.anchor_top    = 0.0
$SidePanel.anchor_right  = 1.0
$SidePanel.anchor_bottom = 1.0
$SidePanel.offset_left   = 0.0
$SidePanel.offset_top    = 0.0
$SidePanel.offset_right  = 0.0
$SidePanel.offset_bottom = 0.0
```

### Anchor vs Offset

- **Anchor** determines *where on the parent* the node's edges track. It is resolution-independent.
- **Offset** is a *fixed pixel value* added after the anchor. It does not scale with the parent.

For fully responsive layout, keep offsets at 0 and let anchors do the work. Add small fixed offsets only for cosmetic margins (e.g., a 16 px gutter from an edge).

---

## 4. Theme System

A `Theme` resource centralizes fonts, colors, and `StyleBox`es. Apply at the root and let inheritance do the work; use `theme_override_*` only for one-off tweaks. `StyleBoxFlat` covers most flat-design needs (`bg_color`, `border_color`, `corner_radius`, `border_width`); `StyleBoxTexture` for textured backgrounds.

> See [references/theme-system.md](references/theme-system.md) for the full Theme resource creation walk-through, StyleBoxFlat properties, font overrides, theme inheritance rules, and per-node `theme_override_*` methods.

---

## 5. Focus & Navigation

Focus modes (`FOCUS_NONE`, `FOCUS_CLICK`, `FOCUS_ALL`) gate keyboard/gamepad navigation. Use `focus_neighbor_top` / `_bottom` / `_left` / `_right` to wire navigation chains, or rely on automatic spatial detection. Call `grab_focus()` on the first interactive element when a menu opens.

> See [references/focus-and-navigation.md](references/focus-and-navigation.md) for focus mode details, `focus_neighbor` chain examples, gamepad/keyboard input handling, and grab_focus patterns.

---

## 6. Common UI Patterns

Three canonical scenes: a **main menu** (centered VBoxContainer with title + button list), a **settings screen with tabs** (`TabContainer` + child panels per category), and a **pause menu overlay** (full-rect `ColorRect` background + centered options panel, paused via `get_tree().paused = true`).

> See [references/ui-patterns.md](references/ui-patterns.md) for the full scene-tree fragments and GDScript wiring for each pattern.

---

## 7. Signals

`Button.pressed` for clicks, `Control.gui_input` for raw events on a node, `Control.mouse_entered` / `mouse_exited` for hover. Connect in `_ready()` or via the Inspector's Node panel.

> See [references/signals.md](references/signals.md) for the complete signal catalog and signal-driven UI update patterns.

---

## 8. FoldableContainer in Godot 4.6

Godot 4.6 provides `FoldableContainer`, a built-in accordion-style `Container` with a toggle header.

### Basic Usage

```gdscript
# In a script that builds UI dynamically:
func _ready() -> void:
    var foldable := FoldableContainer.new()
    foldable.title = "Advanced Settings"
    foldable.folded = false  # start expanded

    var label := Label.new()
    label.text = "This content can be collapsed."
    foldable.add_child(label)

    var slider := HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.value = 0.5
    foldable.add_child(slider)

    add_child(foldable)
    foldable.folding_changed.connect(_on_section_toggled)

func _on_section_toggled(is_folded: bool) -> void:
    print("Section is now: ", "folded" if is_folded else "expanded")
```

### Key Properties

| Property | Type | Purpose |
|----------|------|---------|
| `title` | `String` | Text shown in the toggle header |
| `folded` | `bool` | `true` = content hidden, `false` = content visible |
| `title_alignment` | `HorizontalAlignment` | Align the title text within the header |

### Signal

| Signal | Signature | When emitted |
|--------|-----------|--------------|
| `folding_changed` | `(folded: bool)` | Emitted whenever the fold state toggles |

`FoldableContainer` owns the toggle and collapsed-content layout; do not duplicate that behavior with a separate button and container.

---

## 9. Label Outline and Shadow

In Godot 4.6, a `Label` supports one theme outline plus one shadow. These are two distinct effects, not an arbitrary stack of multiple outlines. If the design truly needs two outline rings, use a custom shader or deliberately layered labels; theme overrides with the same key replace the previous value.

```gdscript
func apply_outline_and_shadow(label: Label) -> void:
    # One outline
    label.add_theme_constant_override("outline_size", 6)
    label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))

    # One shadow
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
```

Use the same theme properties on `RichTextLabel`. Do not invent an `[outline]` BBCode tag or try to stack repeated `add_theme_*_override()` calls: each call updates the single override identified by that key.

---

## 10. Checklist

- [ ] Root UI `Control` has anchor preset **Full Rect** (or appropriate preset for the layout)
- [ ] All interactive widgets (`Button`, `LineEdit`, `Slider`) have `focus_mode = FOCUS_ALL`
- [ ] Decorative nodes (`Label`, `TextureRect`) have `focus_mode = FOCUS_NONE`
- [ ] Focus neighbours are wired for non-linear layouts so gamepad navigation wraps correctly
- [ ] `grab_focus()` called on the first interactive widget in `_ready()` for each screen
- [ ] Pause menu root `Control` has `process_mode = PROCESS_MODE_ALWAYS`
- [ ] One `Theme` resource assigned at the screen root — not duplicated on every child
- [ ] `StyleBoxFlat` used instead of image assets for simple solid-colour panels
- [ ] `add_theme_*_override()` used for per-node overrides rather than assigning a whole new `Theme`
- [ ] Containers (`VBoxContainer`, `HBoxContainer`, etc.) used for layout instead of manual `position` values
- [ ] `custom_minimum_size` set on widgets that must not collapse to zero
- [ ] Slider and volume code uses `linear_to_db` / `db_to_linear` — not raw linear values mapped to audio bus
- [ ] Signals connected in `_ready()` (or via the editor); no polling of UI state in `_process`
- [ ] Tab order in `TabContainer` matches logical reading / navigation order
- [ ] Accordion-style collapsible panels use the Godot 4.6 `FoldableContainer` instead of manual Button + VBoxContainer wiring
- [ ] Labels use the supported single outline plus shadow; multi-ring text uses an intentional shader or layered-label design

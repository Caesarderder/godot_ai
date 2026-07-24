---
name: responsive-ui
description: Use when handling stretch modes, aspect ratios, DPI scaling, safe areas, and pointer or touch adaptation in Godot 4.6 GDScript Web projects
---

# Responsive UI in Godot 4.6

Use Godot 4.6.x GDScript APIs for responsive layouts in Builda's single-threaded Web export.

> **Related skills:** **godot-ui** for Control node layout and themes, **godot-project-setup** for initial project resolution settings, **input-handling** for pointer and touch input adaptation, **localization** for layout adjustments per locale.

> Linked references are a legacy archive. Load and use only their Godot 4.6-compatible GDScript sections.

---

## 1. Project Settings for Resolution

Configure base resolution and stretch behaviour in `Project > Project Settings > Display > Window`.

Key settings and their `.godot/project.godot` keys:

| Setting | project.godot key | Recommended value |
|---|---|---|
| Viewport width | `display/window/size/viewport_width` | `1920` (or your base design width) |
| Viewport height | `display/window/size/viewport_height` | `1080` (or your base design height) |
| Stretch mode | `display/window/stretch/mode` | `canvas_items` (most games) |
| Stretch aspect | `display/window/stretch/aspect` | `expand` (fill screen) or `keep` (letterbox) |
| Scale factor | `display/window/stretch/scale` | `1` (adjust for pixel art integer scaling) |
| Scale mode | `display/window/stretch/scale_mode` | `fractional` normally; `integer` for pixel art |

These can also be set at runtime:

**GDScript:**

```gdscript
# Read current viewport size
var viewport_size: Vector2 = get_viewport().get_visible_rect().size

# Runtime equivalents take effect immediately. ProjectSettings values may only
# be read at startup and should not be used as live Window state.
get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
```

---

## 2. Stretch Mode Comparison

| Mode | `project.godot` value | Rendering | Best For |
|---|---|---|---|
| `canvas_items` | `"canvas_items"` | Viewport rendered at design resolution, then upscaled — UI and 2D nodes scale smoothly | Most 2D and UI-heavy games |
| `viewport` | `"viewport"` | Entire viewport is rendered at design resolution and stretched; no sub-pixel blending | Pixel art games needing pixel-perfect output |
| `disabled` | `"disabled"` | No automatic scaling; every Control node must handle its own layout | Complex custom scaling, 3D games with a Control HUD |

**When to choose each:**

- **`canvas_items`** — Default recommendation. Smooth scaling at any resolution. UI built with `Control` nodes and anchors responds naturally. Text and icons stay crisp at high DPI when combined with `content_scale_factor`.
- **`viewport`** — Locks rendering to the design resolution. Combined with integer scaling and nearest-neighbour filtering it gives a classic pixel-perfect look. Avoid for high-DPI displays unless you intentionally want chunky pixels.
- **`disabled`** — Use when you need full manual control, e.g. a 3D game where the UI must adapt to safe areas or unusual aspect ratios without Godot scaling it.

---

## 3. Aspect Ratio Handling

Set via `Project > Project Settings > Display > Window > Stretch > Aspect` or the `display/window/stretch/aspect` key.

| Mode | Visual Result | When to Use |
|---|---|---|
| `keep` | Letterbox (black bars top/bottom) or pillarbox (bars left/right) — design rect is preserved exactly | Games with a fixed layout that must not be cropped (e.g. score-based arcade, puzzle) |
| `expand` | Screen is fully filled; the visible game area grows on wider or taller displays | Action games, platformers — more visible play area is a bonus, not a problem |
| `keep_width` | Width is fixed; height expands on taller screens (mobile portrait) | Portrait mobile games where horizontal alignment is strict |
| `keep_height` | Height is fixed; width expands on wider screens (landscape) | Landscape games where vertical alignment is strict (e.g. side-scroller HUD) |

**`expand` with adaptive UI** is the most versatile choice for games targeting both desktop and mobile. Anchor your HUD elements to screen edges so they follow the expanded visible area.

---

## 4. Pixel Art Setup

For crisp pixel-art games: set `Mode = viewport`, `Scale Mode = integer`, and a native base resolution such as 320×180. `Window Size Override` only changes editor preview size. Let Godot floor the stretch factor; do not derive `content_scale_factor` from monitor dimensions.

> See [references/pixel-art-setup.md](references/pixel-art-setup.md) for full project settings, integer-scaling script, nearest-neighbour filter overrides.

---

## 5. DPI Scaling

For native retina / high-DPI displays, `content_scale_factor` can scale the entire UI proportionally. Builda Web projects should use the browser canvas/viewport layout and must not infer CSS/device-pixel scaling from `DisplayServer.screen_get_dpi()`.

> See [references/dpi-scaling.md](references/dpi-scaling.md) for the `content_scale_factor` recipe and DPI-querying patterns.

---

## 6. Mobile Considerations

Four mobile-specific concerns: **touch input** (tap, swipe, multi-touch), **safe-area insets** (notch / dynamic island avoidance), **orientation lock** (portrait/landscape pinning), **virtual keyboard** (handle show/hide to avoid covering UI).

> See [references/mobile.md](references/mobile.md) for full GDScript on each concern, plus iOS / Android nuances.

---

## 7. Adaptive Layouts

Anchor presets + Container nodes do most of the work. Use `size_flags_horizontal`/`vertical` (`FILL`, `EXPAND`, `SHRINK_CENTER`, `SHRINK_END`) to control how children consume container space. Detect runtime resolution changes via `get_viewport().size_changed`.

> See [references/adaptive-layouts.md](references/adaptive-layouts.md) for the anchor + container strategy, resolution-change detection, and the full `size_flags` reference.

---

## 8. Testing Multiple Resolutions

### Editor Preview Sizes

In the editor viewport, use **Editor > Editor Settings > Run > Window Placement** to start the game at specific sizes, or use the viewport size selector in the 2D editor toolbar.

Add common test sizes under **Project > Project Settings > Display > Window > Size > Test Width/Height** to preview in the editor.

### `--resolution` CLI Flag

Launch from the command line with an override resolution:

```bash
# Windows
godot.exe --path "C:/projects/mygame" --resolution 1280x720

# Linux / macOS
godot --path /projects/mygame --resolution 1280x720

# Run an exported binary at a specific size
./mygame.x86_64 --resolution 375x812
```

### Common Test Resolutions

| Resolution | Aspect | Common Use |
|---|---|---|
| `1920×1080` | 16:9 | Standard 1080p desktop / TV |
| `2560×1440` | 16:9 | 1440p high-DPI desktop |
| `1280×720` | 16:9 | Low-end desktop / minimum target |
| `640×360` | 16:9 | Pixel art base resolution (2× of 320×180) |
| `2732×2048` | 4:3 | iPad Pro — tests non-16:9 aspect ratios |
| `390×844` | ~19.5:9 | iPhone 14 portrait |
| `844×390` | ~19.5:9 | iPhone 14 landscape |
| `1080×2400` | 20:9 | Android tall portrait |
| `360×800` | ~20:9 | Android low-end portrait |

> **Strategy:** Always test at your base design resolution, one resolution wider than 16:9 (e.g. 21:9 ultrawide), and one taller (e.g. mobile portrait). These three cases catch the most layout bugs.

---

## 9. Checklist

- [ ] Base viewport size (`viewport_width` / `viewport_height`) matches the design canvas in the editor
- [ ] Stretch mode chosen deliberately: `canvas_items` for most games, `viewport` for pixel art
- [ ] Aspect ratio mode chosen: `expand` unless fixed-layout content requires `keep`
- [ ] Pixel art games use `viewport` stretch + `Nearest` texture filter + `display/window/stretch/scale_mode = "integer"`
- [ ] All HUD `Control` nodes use anchors anchored to the nearest edge, not fixed `position` values
- [ ] `custom_minimum_size` set on buttons and interactive elements to prevent collapse below tap target size (minimum 44×44 px recommended for mobile)
- [ ] `size_flags_horizontal` / `size_flags_vertical` set to `SIZE_EXPAND_FILL` on elements that should fill space
- [ ] `get_viewport().size_changed` signal connected where layout must respond to window resize
- [ ] Native-only safe-area values are converted from screen pixels into UI canvas units before applying margins; Web projects rely on the host canvas safe area
- [ ] Native-only DPI scaling is tested on target devices; Web projects do not rely on `DisplayServer.screen_get_dpi()`
- [ ] Touch input handled via `InputEventScreenTouch` / `InputEventScreenDrag`, not mouse events alone
- [ ] Orientation locked to the correct mode (`SCREEN_LANDSCAPE` / `SCREEN_PORTRAIT`) or `SCREEN_SENSOR` where rotation is intended
- [ ] Virtual keyboard height queried after show and used to shift UI content upward on mobile
- [ ] Tested at minimum: design resolution, one ultra-wide (21:9), and one mobile portrait resolution
- [ ] `--resolution` flag used in CI or playtest scripts to automate multi-resolution smoke tests

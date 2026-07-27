---
name: gd-agentic-ui-ux
description: "Use for Godot 4.6 Web UI and UX: input mapping, Control composition, responsive containers, RichTextLabel, seasonal presentation, and theme resources"
---

# GD-Agentic UI and UX

Route interface work to the smallest relevant reference. Do not load every reference by default.

## Route

| Need | Read |
| --- | --- |
| InputMap, rebinding, and input buffering | [input handling](references/gd-agentic-input-handling.md) |
| Control-heavy application and tool composition | [application composition](references/gd-agentic-composition-apps.md) |
| Responsive Control layouts | [UI containers](references/gd-agentic-ui-containers.md) |
| BBCode and rich text effects | [rich text](references/gd-agentic-ui-rich-text.md) |
| Seasonal themes and playful UI motion | [theme easter](references/gd-agentic-theme-easter.md) |
| Theme resources and style inheritance | [UI theming](references/gd-agentic-ui-theming.md) |

## Script prototypes

After selecting a reference, inspect only its matching `scripts/<gd-agentic-capability>/` directory when a code prototype is useful. These upstream scripts are preserved for adaptation, not pre-approved for direct execution or bulk copying. Keep only behavior compatible with the current Control tree, input model, viewport, and Builda Web preview.

## Apply

1. Inspect current Control hierarchy, focus flow, input actions, and target viewport sizes.
2. Read only the references needed for the requested interface.
3. Preserve existing interaction semantics and accessible visual hierarchy.
4. Keep layouts responsive and renderer-safe for the Web preview.
5. Verify keyboard/pointer flow, narrow viewport behavior, and the real Web runtime.

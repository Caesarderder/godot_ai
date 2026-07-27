# UI recipes

| Need | Recipe | Canonical owner |
| --- | --- | --- |
| Semantic colors, spacing, corners, and reusable Theme generation | [theme tokens](../assets/catalog-project/recipes/ui/theme-tokens/README.md) | `$godot-ui` |
| Container-first narrow/wide layout with a stable shell contract | [responsive screen shell](../assets/catalog-project/recipes/ui/responsive-screen-shell/README.md) | `$responsive-ui` |
| Inspect normal, focused, disabled, progress, and dialog states | [component gallery](../assets/catalog-project/recipes/ui/component-gallery-core/README.md) | `$godot-ui` |

Keep component logic independent from skins. Prefer Theme items and type variations over scattered
per-node overrides. The included scenes are structural evidence; use the real Builda Web Preview for
visual acceptance.

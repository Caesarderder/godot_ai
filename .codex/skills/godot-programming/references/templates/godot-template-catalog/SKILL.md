---
name: godot-template-catalog
description: Use when AI needs a small, verified Godot 4.6 Web micro-recipe with real GDScript, scenes, resources, manifests, demos, and focused tests instead of a complete game starter kit
---

# Godot Template Catalog

Use this catalog to select one or a few self-contained implementation recipes. It owns the packaging,
manifest, demo, and verification contract. Existing Builda skills remain the canonical owners of
architecture, gameplay, UI, persistence, and testing semantics.

## Route

| Need | Read |
| --- | --- |
| Browse the real `.gd`, `.tscn`, and `.tres` assets before choosing a recipe | [code asset index](references/code-assets.md) |
| Feature slices, Resource/runtime separation, signal boundaries, scene transitions, or save envelopes | [architecture recipes](references/architecture-recipes.md) |
| A minimal state machine, interaction flow, or damage pipeline | [gameplay recipes](references/gameplay-recipes.md) |
| Theme tokens, responsive shells, or a component state gallery | [UI recipes](references/ui-recipes.md) |
| Required-node, signal, Resource, and InputMap contract checks | [testing recipe](references/testing-recipes.md) |
| Decide whether a project should adopt a known optional plugin | [optional integrations](references/optional-integrations.md) |
| Source decisions and third-party boundaries | [provenance](references/provenance.md) |

## Apply

1. Inspect the tenant project and select the smallest matching recipe.
2. Read that recipe's `README.md` and `manifest.json` before copying files.
3. Read the manifest's `canonical_owner` skill for semantic rules; the recipe does not replace it.
4. Copy only the declared files into a feature-owned project directory and rename the `Template*`
   classes immediately.
5. Declare any new InputMap action, Autoload, plugin, or cross-recipe dependency explicitly. The
   included recipes have no hidden Autoload or plugin dependency.
6. Adapt scene paths and node names without weakening the recipe's public signals, failure semantics,
   or focused test.
7. Run the copied focused test, parse/import the affected project, and verify the real Web runtime
   when behavior or UI is user-visible.

## Catalog contract

- Target: Godot 4.6.x, GDScript, Web, Compatibility renderer, single-thread runtime.
- Every recipe has one manifest, one README, real source artifacts, one runnable demo scene, and one
  focused test script.
- Recipes are examples to adapt, not an application framework and not a mandatory orchestration flow.
- No recipe installs a plugin, writes outside the tenant project, or mutates platform configuration.
- Visual demos prove structure and states only. Final layout and appearance still require browser
  evidence from the Builda Web Preview.

## Validate this installed catalog

From this skill directory:

```bash
node scripts/validate-catalog.mjs
godot --headless --path assets/catalog-project --import
godot --headless --path assets/catalog-project --script res://tests/run_all.gd
```

Use the Godot binary already supplied by the Builda runtime. Do not download another engine.

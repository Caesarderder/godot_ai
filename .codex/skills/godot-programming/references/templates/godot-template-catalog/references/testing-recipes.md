# Testing recipe

Use [scene contract](../assets/catalog-project/recipes/testing/scene-contract/README.md) when a
reusable scene requires named nodes, signals, Resource properties, or InputMap actions.

`$godot-testing` remains the canonical owner for framework detection, test layout, headless commands,
and project-specific GUT or gdUnit4 integration. The recipe is dependency-free so it can validate a
scene before a project chooses a testing plugin.

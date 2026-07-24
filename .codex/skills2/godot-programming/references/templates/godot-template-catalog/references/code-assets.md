# Code asset index

These are real Godot 4.6 assets bundled with this skill, not Markdown-only snippets. Start with the
smallest matching recipe, then read its `manifest.json` and `README.md`. Copy the complete declared
bundle so its scene paths, Resources, collaborators, demo, and focused test stay together.

| Need | Representative code | Scene or Resource | Complete bundle |
| --- | --- | --- | --- |
| Feature-owned configuration and state | [counter_feature.gd](../assets/catalog-project/recipes/architecture/feature-slice/counter_feature.gd) | [counter_feature.tscn](../assets/catalog-project/recipes/architecture/feature-slice/counter_feature.tscn) | [manifest](../assets/catalog-project/recipes/architecture/feature-slice/manifest.json) |
| Immutable Resource plus mutable runtime | [meter_runtime.gd](../assets/catalog-project/recipes/architecture/resource-runtime-pair/meter_runtime.gd) | [meter_definition.tres](../assets/catalog-project/recipes/architecture/resource-runtime-pair/meter_definition.tres) | [manifest](../assets/catalog-project/recipes/architecture/resource-runtime-pair/manifest.json) |
| Typed signal boundary | [signal_mediator.gd](../assets/catalog-project/recipes/architecture/signal-boundary/signal_mediator.gd) | [demo.tscn](../assets/catalog-project/recipes/architecture/signal-boundary/demo.tscn) | [manifest](../assets/catalog-project/recipes/architecture/signal-boundary/manifest.json) |
| Explicit scene replacement | [scene_router.gd](../assets/catalog-project/recipes/architecture/scene-transition/scene_router.gd) | [demo.tscn](../assets/catalog-project/recipes/architecture/scene-transition/demo.tscn) | [manifest](../assets/catalog-project/recipes/architecture/scene-transition/manifest.json) |
| Versioned persistence envelope | [save_envelope.gd](../assets/catalog-project/recipes/architecture/save-envelope/save_envelope.gd) | [demo.tscn](../assets/catalog-project/recipes/architecture/save-envelope/demo.tscn) | [manifest](../assets/catalog-project/recipes/architecture/save-envelope/manifest.json) |
| Lifecycle-safe finite state machine | [state_machine.gd](../assets/catalog-project/recipes/gameplay/state-machine-basic/state_machine.gd) | [demo.tscn](../assets/catalog-project/recipes/gameplay/state-machine-basic/demo.tscn) | [manifest](../assets/catalog-project/recipes/gameplay/state-machine-basic/manifest.json) |
| Ranked interaction candidates | [interactor.gd](../assets/catalog-project/recipes/gameplay/interaction/interactor.gd) | [demo.tscn](../assets/catalog-project/recipes/gameplay/interaction/demo.tscn) | [manifest](../assets/catalog-project/recipes/gameplay/interaction/manifest.json) |
| Hitbox to Hurtbox damage flow | [hitbox.gd](../assets/catalog-project/recipes/gameplay/damage-pipeline/hitbox.gd) | [demo.tscn](../assets/catalog-project/recipes/gameplay/damage-pipeline/demo.tscn) | [manifest](../assets/catalog-project/recipes/gameplay/damage-pipeline/manifest.json) |
| Semantic UI theme tokens | [theme_factory.gd](../assets/catalog-project/recipes/ui/theme-tokens/theme_factory.gd) | [theme_tokens.tres](../assets/catalog-project/recipes/ui/theme-tokens/theme_tokens.tres) | [manifest](../assets/catalog-project/recipes/ui/theme-tokens/manifest.json) |
| Responsive narrow/wide shell | [responsive_shell.gd](../assets/catalog-project/recipes/ui/responsive-screen-shell/responsive_shell.gd) | [demo.tscn](../assets/catalog-project/recipes/ui/responsive-screen-shell/demo.tscn) | [manifest](../assets/catalog-project/recipes/ui/responsive-screen-shell/manifest.json) |
| UI state gallery | [gallery.gd](../assets/catalog-project/recipes/ui/component-gallery-core/gallery.gd) | [demo.tscn](../assets/catalog-project/recipes/ui/component-gallery-core/demo.tscn) | [manifest](../assets/catalog-project/recipes/ui/component-gallery-core/manifest.json) |
| Scene, signal, Resource, and InputMap contract checks | [scene_contract.gd](../assets/catalog-project/recipes/testing/scene-contract/scene_contract.gd) | [demo.tscn](../assets/catalog-project/recipes/testing/scene-contract/demo.tscn) | [manifest](../assets/catalog-project/recipes/testing/scene-contract/manifest.json) |

Use these assets as adaptation references. Rename `Template*` classes and paths after copying, retain
the public failure semantics, and run the included focused test before integrating the recipe into a
larger feature.

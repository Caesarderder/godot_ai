# Gameplay recipes

| Need | Recipe | Canonical owner |
| --- | --- | --- |
| Small explicit state lifecycle with guarded transitions | [basic state machine](../assets/catalog-project/recipes/gameplay/state-machine-basic/README.md) | `$state-machine` |
| Candidate ranking, prompt selection, execute, and cancel | [interaction](../assets/catalog-project/recipes/gameplay/interaction/README.md) | `$godot-architecture` |
| Typed damage data, hitbox, hurtbox, health, and depletion | [damage pipeline](../assets/catalog-project/recipes/gameplay/damage-pipeline/README.md) | `$combat-system` |

Use these as focused feature slices. Do not introduce a global gameplay framework, universal event
bus, or plugin dependency just to consume one recipe.

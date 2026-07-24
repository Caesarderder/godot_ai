# Architecture recipes

Select one recipe, then read its manifest and README. The artifact package supplies a runnable
example; semantic ownership stays with the listed Builda skill.

| Need | Recipe | Canonical owner |
| --- | --- | --- |
| Organize a feature-owned scene, script, data Resource, and test | [feature slice](../assets/catalog-project/recipes/architecture/feature-slice/README.md) | `$godot-project-setup` |
| Separate immutable configuration from mutable runtime state | [Resource/runtime pair](../assets/catalog-project/recipes/architecture/resource-runtime-pair/README.md) | `$resource-pattern` |
| Report child events through a parent-owned mediator | [signal boundary](../assets/catalog-project/recipes/architecture/signal-boundary/README.md) | `$godot-architecture` |
| Replace a hosted child scene with explicit success/failure signals | [scene transition](../assets/catalog-project/recipes/architecture/scene-transition/README.md) | `$godot-architecture` |
| Wrap persisted payloads with version and validation results | [save envelope](../assets/catalog-project/recipes/architecture/save-envelope/README.md) | `$save-load` |

These recipes do not authorize changes to Builda's protected project-layout, Resource, persistence,
or application-lifetime owners. Adapt the artifact inside the tenant project and keep the canonical
owner's rules authoritative.

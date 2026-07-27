---
name: gd-agentic-foundations
description: "Use for Godot 4.6 Web project foundations: autoloads, composition, GDScript structure, project conventions, Resources, signals, scene flow, and debugging"
---

# GD-Agentic Foundations

Route architecture and foundation work to the smallest relevant reference. Do not load every reference by default.

## Route

| Need | Read |
| --- | --- |
| Application-lifetime singleton state | [autoload architecture](references/gd-agentic-autoload-architecture.md) |
| Entity and feature composition | [composition](references/gd-agentic-composition.md) |
| Debugging and profiling | [debugging and profiling](references/gd-agentic-debugging-profiling.md) |
| Typed GDScript and script organization | [GDScript mastery](references/gd-agentic-gdscript-mastery.md) |
| Feature-driven project structure | [project foundations](references/gd-agentic-project-foundations.md) |
| Project baseline and input/export defaults | [project templates](references/gd-agentic-project-templates.md) |
| Resource-backed data | [resource data patterns](references/gd-agentic-resource-data-patterns.md) |
| Scene loading and transitions | [scene management](references/gd-agentic-scene-management.md) |
| Decoupled signals | [signal architecture](references/gd-agentic-signal-architecture.md) |

## Script prototypes

After selecting a reference, inspect only its matching `scripts/<gd-agentic-capability>/` directory when a code prototype is useful. These upstream scripts are preserved for adaptation, not pre-approved for direct execution or bulk copying. Reject or rewrite APIs that violate Godot 4.6 Web, Compatibility, single-thread, project ownership, or protected-core rules.

## Apply

1. Inspect the current project before choosing a reference.
2. Read only the references required by the task.
3. Defer protected project layout, file identity, `res://`/`user://`, asset provenance, persistence, and review rules to their canonical Builda owners.
4. Keep implementation within Godot 4.6.x, GDScript, Web, Compatibility rendering, and a single-thread runtime.
5. Verify parsing/import, focused behavior, and Web runtime evidence before claiming completion.

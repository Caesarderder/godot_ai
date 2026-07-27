> ← Back to [SKILL.md](../SKILL.md)

# Script organization

## Naming

| Item | Convention | Examples |
| --- | --- | --- |
| Directory | `snake_case` | `game/features/player/` |
| Script, scene, resource file | `snake_case` | `health_component.gd`, `player.tscn` |
| Scene node | `PascalCase` | `HealthComponent`, `PauseMenu` |
| Global `class_name` | `PascalCase` | `HealthComponent`, `ItemDefinition` |
| Signal/method/property | `snake_case` | `health_changed`, `take_damage` |
| Constant | `SCREAMING_SNAKE_CASE` | `MAX_HEALTH` |

Use role suffixes only when they clarify the contract:

- `*_component.gd`: reusable node behavior owned by a scene;
- `*_service.gd`: a bounded capability with an explicit lifetime;
- `*_controller.gd`: translates input/intent into commands for one owned feature;
- `*_view.gd` or `*_screen.gd`: presentation and UI interaction;
- `*_definition.gd` / `*_data.gd`: typed Resource schema, not live scene state.

Avoid generic `manager`, `utils`, `helpers`, `common`, or `base` names unless the narrower
responsibility is present in the complete name.

## File shape

Keep declarations predictable:

1. `@tool`, `@icon`, or `@static_unload` when required;
2. `class_name`, then `extends`, then the class documentation comment;
3. signals, enums, constants, static variables;
4. exported properties, then remaining public and private state;
5. `@onready` references;
6. `_static_init()` and remaining static methods;
7. built-in virtual callbacks in lifecycle order;
8. overridden custom methods, then remaining public and private methods;
9. inner classes.

Match a coherent local convention when editing an existing file. Do not reorder an unrelated script
solely for style.

## Split decisions

Split a script when a section has distinct ownership or lifetime, changes for a different reason,
is reusable, needs independent tests/preview, or hides a meaningful typed contract. Do not split
tiny cohesive behavior just to reduce line count, and do not keep unrelated behavior together just
because the file is short.

Common boundaries:

- input interpretation → feature controller;
- movement/collision → body or movement component;
- rules/progression → session-owned rules object;
- HUD interaction → view/screen script;
- serialization → save repository/service;
- audio requests → audio-facing component or application service;
- dynamic resource choice → allowlisted asset catalog/loader.

`main.gd` and other composition roots only instantiate, inject, connect, switch scenes, and coordinate
their scope's lifecycle.

## Dependency hygiene

- Prefer typed node references, typed Resources, and explicit setup methods.
- Do not hide required dependencies behind ancestor searches or global lookups.
- Do not introduce a global class solely to avoid a local preload.
- Keep reusable scripts independent of a particular parent path.
- Keep private helper methods private with a leading underscore; expose only the contract callers
  need.

## Upstream basis

Naming and declaration order follow the Godot 4.6
[GDScript style guide](https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/gdscript_styleguide.html).
Responsibility splits remain an architectural decision and must preserve the current project's
coherent local conventions.

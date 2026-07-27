---
name: godot-project-setup
description: Set up or repair the minimal structure and project settings for a Builda Godot 4.6 GDScript Web project. Use when creating a playable prototype, choosing a directory layout, defining input actions, or validating project.godot before implementation.
---

# Godot Project Setup

Create the smallest project structure that supports the current playable scope. Target Godot 4.6,
GDScript, the Compatibility renderer, and Builda's single-threaded Web export. Do not add other language bindings,
native-platform plugins, threaded rendering, speculative managers, or unrelated gameplay systems.

## Workflow

1. Inspect the existing `project.godot`, scenes, scripts, assets, and addons before creating files.
2. Preserve an existing coherent layout. Do not reorganize a working project merely to match this guide.
3. Before creating non-trivial gameplay files, use `godot-architecture` to record the current
   milestone's target file tree, scene/owner boundaries, typed signal contracts, and Resource versus
   runtime-state plan. Annotate why each planned file is `.tscn`, `.gd`, or `.tres`.
4. Prefer a feature-first hybrid layout: co-locate each feature's scene, script, and feature-owned
   resources while keeping truly shared code, UI, levels, and governed assets in explicit roots.
5. Add only settings and autoloads required by the current playable feature.
6. Validate with the repository's Godot binary and existing tests.

## Directory layout

Use this as the target shape, creating only directories needed by the current scope:

```text
res://
├── assets/
│   ├── generated/
│   ├── uploads/        # reserved source-label prefix; current chat uploads do not auto-persist
│   ├── licenses/
│   └── asset_manifest.md
├── game/
│   ├── main.tscn
│   ├── main.gd
│   └── features/
│       └── player/
│           ├── player.tscn
│           ├── player.gd
│           ├── player_stats.tres
│           └── assets/
├── levels/
├── ui/
├── shared/
│   ├── components/
│   ├── resources/
│   ├── services/
│   └── assets/
├── tests/
└── project.godot
```

The main scene and `main.gd` are a thin composition root. They may create top-level systems, connect
their signals, coordinate application lifecycle, replace top-level scenes, and preload fixed
`PackedScene` dependencies used only for top-level routing. They must not implement gameplay rules,
input handling, physics, screen widgets, save serialization, audio behavior, arbitrary asset paths,
directory scanning, import configuration, or reusable loading policy. Put those responsibilities in
the owning feature, component, screen, or narrow service.

Do not move a coherent existing project merely to match this target. Migrate only files touched by
an authorized feature or refactor, preserve public `res://` paths when possible, and verify every
moved dependency. Do not create empty category trees. Read
[references/project-layout.md](references/project-layout.md) before creating a new structure or
reorganizing an existing one.

## Builda-compatible project settings

Keep the renderer and Web constraints explicit:

```ini
[application]
config/name="Builda Game"
run/main_scene="res://game/main.tscn"

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

Choose the viewport size from the game's composition needs. Do not treat `1280x720` as a universal
requirement. Coordinate responsive layout decisions with the `responsive-ui` skill.

## Input actions

Define semantic Input Map actions before writing controller code. Keep physical keys and buttons out
of gameplay logic.

```ini
[input]

move_left={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":65)]
}
move_right={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":68)]
}
```

Treat the snippet as a shape example. Prefer editing existing project settings through Godot-aware
tools or carefully patching the current file; never replace an existing `[input]` section blindly.

## Autoload policy

An autoload is a project-wide lifetime and coupling decision, not default scaffolding.

- Add one only when a system truly must survive scene changes or coordinate unrelated scenes.
- Prefer direct parent-child calls or local signals inside one scene.
- Do not pre-create `GameManager`, `EventBus`, `AudioManager`, or `SaveManager` without a current use.
- Use `godot-architecture` to choose between direct references, signals, injection, and a global bus.

## Version control baseline

Add only project-generated and local build artifacts to `.gitignore`:

```gitignore
.godot/
export/
*.pck
*.wasm
*.zip
.DS_Store
```

Do not create branches, commits, or remotes unless the user explicitly requests publication work.

## Validation

Use the configured Godot 4.6 binary rather than downloading another editor or template.

```bash
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 2
```

Adapt the executable name to the repository environment. The import/parse check is not a gameplay,
browser, or device test. Run project-specific headless tests and Builda's Web build when available.

## Completion checklist

- The structure follows the current project scale and contains no speculative empty systems.
- Non-trivial gameplay work has a target file tree, scene ownership map, signal contract, and Resource
  plan before implementation starts.
- Feature-owned scenes, scripts, and resources are co-located; shared roots contain only genuinely
  cross-feature owners.
- `main.gd` is limited to top-level composition, scene switching, and application lifecycle.
- `project.godot` targets Godot 4.6 Compatibility rendering and single-threaded Web delivery.
- The main scene exists and loads.
- Input actions are semantic and match the implemented controls.
- Every autoload has a demonstrated project-wide responsibility.
- No non-GDScript binding, future-version API, native mobile plugin, threaded Web setting, or platform-specific agent file was added.
- Headless import/parse and the smallest relevant runtime test pass.

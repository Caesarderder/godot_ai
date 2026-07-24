> ← Back to [SKILL.md](../SKILL.md)

# Feature-first project layout

## Contents

- [Rules](#rules)
- [Recommended target](#recommended-target)
- [Ownership test](#ownership-test)
- [Builda Web asset-panel contract](#builda-web-asset-panel-contract)
- [Godot and version-control boundaries](#godot-and-version-control-boundaries)
- [Existing projects](#existing-projects)
- [Upstream basis](#upstream-basis)

## Rules

- Use `snake_case` for directories and filenames. Use `PascalCase` for scene node names and
  globally registered `class_name` types.
- Co-locate a feature's `.tscn`, `.gd`, `.tres`, and small feature-owned media so changing or
  removing the feature has one obvious boundary.
- Put a file in `shared/` only after at least two features need the same stable contract. Name the
  shared subdirectory by responsibility (`components`, `resources`, `services`), never `utils`,
  `common`, or `misc`.
- Keep UI screens and reusable UI controls under `ui/`; keep world/level composition under
  `levels/`. A feature-specific HUD fragment may remain with its feature when it has no independent
  owner.
- Keep feature-private imported media beside its owning scene under a local `assets/` directory.
  Promote media to `shared/assets/` only after real cross-feature reuse. Keep the central provenance
  manifest, license texts, truly project-wide foundation media, and Builda-generated images under
  the governed top-level `assets/`; generated images must remain under `assets/generated/`.
- Preserve `assets/uploads/` as Builda's `uploaded` source-label prefix. Current chat attachments
  are temporary and do not automatically persist there; ordinary project assets must not claim it.
- Mirror meaningful feature boundaries under `tests/` when the project has automated tests.
- Do not create empty directories to advertise future architecture.

## Recommended target

```text
res://
├── assets/
│   ├── fonts/                   # optional project-wide baseline font
│   ├── generated/
│   ├── uploads/                 # reserved source label; not an automatic chat-upload destination
│   ├── licenses/
│   └── asset_manifest.md
├── game/
│   ├── main.tscn
│   ├── main.gd
│   └── features/
│       ├── player/
│       │   ├── player.tscn
│       │   ├── player.gd
│       │   ├── components/
│       │   ├── data/
│       │   └── assets/
│       ├── enemies/
│       └── combat/
├── levels/
│   └── forest/
│       ├── forest.tscn
│       └── assets/
├── ui/
│   ├── screens/
│   ├── components/
│   └── themes/
├── shared/
│   ├── components/
│   ├── resources/
│   ├── services/
│   └── assets/
├── autoload/
├── localization/
├── addons/
├── tests/
├── source_assets/
│   └── .gdignore
└── project.godot
```

This is a classification map, not scaffolding. Create only the branches used by the current game.
Prefer another descriptive feature name over generic numbered folders. `source_assets/` is optional
and remains inside the project: use it only for DCC masters such as `.blend`, `.kra`, or layered
source art that Godot must not import. Its `.gdignore` must be empty. Runtime-loadable source media
must not be hidden there. Builda's asset scanner does not honor `.gdignore`: a supported image,
audio, font, or 3D extension in `source_assets/`, `tests/`, or `addons/` still appears in the Web
asset panel.

## Ownership test

Place each new file by answering in order:

1. Does one feature own its lifecycle and changes? Put it in that feature.
2. Is it an independently navigated screen or reusable visual control? Put it under `ui/`.
3. Is it level/world composition? Put it under `levels/`.
4. Is it stable, reused behavior or data with more than one consumer? Put it in the narrowest
   `shared/` category.
5. Is it feature-private imported media? Put it beside that feature under its local `assets/`.
6. Is it reused media? Put it under `shared/assets/`. Put provenance, license texts, genuinely
   project-wide foundation media, and Builda-generated images in the required top-level `assets/`
   locations.

If none applies, refine the responsibility before inventing a generic folder.

## Builda Web asset-panel contract

The ownership layout above does not create Web UI groups. Builda recursively scans the entire
project and produces one flat catalog. The complete project-relative path is searchable and appears
in the selected asset inspector:

- image: `.png`, `.jpg`, `.jpeg`, `.webp`, `.svg`;
- audio: `.ogg`, `.wav`, `.mp3`;
- font: `.ttf`, `.otf`, `.woff`, `.woff2`;
- 3D: `.glb`, `.gltf`, `.obj`.

Feature-local, level-local, UI, and `shared/assets/` files therefore remain visible. Only the exact
`assets/generated/` prefix receives the `AI generated` source label, and only
`assets/uploads/` receives the `uploaded` label if a file is explicitly persisted there. Current
chat attachments remain temporary and do not automatically enter this path. Other supported files
are `project` assets. Markdown manifests and license text are not catalog assets.

The scanner skips symlinks and `.git`, `.godot`, `.builda-runtime`, `build`, `dist`, and `tmp`
directories, rejects files over 64 MiB, and stops beyond 10,000 candidates. The current Web client
loads only the first 200 relative-path-sorted assets and does not page `nextCursor`; do not promise
that every asset is visible in projects above that boundary. Use refresh after path or content
changes, and remember that renaming changes the path-derived asset identity.

## Godot and version-control boundaries

- Commit source files, `.import` sidecars, and Godot 4.4+ `.uid` files. When moving a script or
  shader outside the editor, move its `.uid` sidecar atomically.
- Ignore `.godot/` and generated `*.translation` files. Do not edit `.godot/imported/`.
- Prefer text `.tscn` and `.tres` resources for reviewable diffs. Consider Git LFS before the first
  commit of large binary media.
- Use `res://` for packaged project content and `user://` for runtime-writable saves, settings,
  captures, and caches.
- A UID does not repair a stale hard-coded or dynamically assembled `res://` string. Search old
  paths, reimport, resave dependencies, and run affected scenes plus export checks after moves.

## Existing projects

Do not perform a whole-project layout migration during unrelated work. For an authorized migration:

1. Inventory `res://` references, preload/load paths, scene inheritance, Autoloads, tests, and export
   filters.
2. Move one ownership boundary at a time using the editor when possible.
3. Update and verify dependencies, filename case, and imports.
4. Parse and run the smallest affected scene before proceeding.
5. Keep compatibility shims only when an external path contract requires them, and document their
   removal condition.

## Upstream basis

This policy targets Godot 4.6 and adapts the official
[project organization](https://docs.godotengine.org/en/4.6/tutorials/best_practices/project_organization.html),
[version control](https://docs.godotengine.org/en/4.6/tutorials/best_practices/version_control_systems.html),
and [Godot 4.4 UID](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
guidance to Builda's project-local, GDScript, Web-export constraints.

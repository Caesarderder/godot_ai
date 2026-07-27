> ← Back to [SKILL.md](../SKILL.md)

# Asset governance

## Contents

- [Feature-first taxonomy](#feature-first-taxonomy)
- [Builda Web display contract](#builda-web-display-contract)
- [Provenance manifest](#provenance-manifest)
- [Lifecycle](#lifecycle)
- [Version control and runtime writes](#version-control-and-runtime-writes)
- [Upstream basis](#upstream-basis)

## Feature-first taxonomy

```text
res://
├── game/features/player/
│   ├── player.tscn
│   └── assets/                  # used only by this feature
│       ├── textures/
│       ├── audio/
│       └── animations/
├── levels/forest/assets/        # used only by this level
├── ui/themes/                   # UI-owned fonts, icons, StyleBoxes, themes
├── shared/assets/               # promoted only after real cross-feature reuse
│   ├── textures/
│   ├── models/
│   ├── audio/
│   ├── fonts/
│   └── vfx/
├── assets/
│   ├── fonts/                   # optional project-wide baseline font
│   ├── generated/              # fixed Builda image-generation destination
│   ├── uploads/                # reserved uploaded-source prefix; not automatic chat persistence
│   ├── licenses/
│   └── asset_manifest.md       # central provenance index for every location
└── source_assets/
    └── .gdignore               # optional DCC masters; empty file
```

This is a classification map, not mandatory scaffolding. Create only categories the project uses.
Keep feature-owned media beside its feature so ownership and removal remain obvious. Promote it to
`shared/assets/` only after multiple features use one stable asset. Record every location in the
central manifest. Use `snake_case` for directories and filenames. Add meaningful variants such as
`goblin_attack_01.ogg`, not `final_v2_new.wav`.

`assets/generated/` is reserved for Builda AI image-generation results. The Server labels every
supported file under that prefix as `AI generated`, so other generated runtime media must use its
real feature/shared owner path. Do not rename the imagegen platform path. Derived files that Godot
can reproduce belong in `.godot/imported`, not beside source assets.

The top-level `assets/` root may also contain a genuinely project-wide foundation asset, such as the
template's default UI font. Do not use that exception to recreate global art/audio type buckets for
feature-owned media.

`source_assets/` is optional and must stay inside the project. Use it only for authoring masters
that Godot must not import, and place an empty `.gdignore` in it. Exported PNG, SVG, OGG, GLB, and
other runtime source media belong beside their owning scenes, not under the ignored directory.

## Builda Web display contract

Builda Web does not turn this directory taxonomy into groups. The Agent recursively scans the whole
project and the Web renders a flat, searchable catalog using the full project-relative path.

| Web type | Displayed extensions | Preview |
| --- | --- | --- |
| image | `.png`, `.jpg`, `.jpeg`, `.webp`, `.svg` | signed thumbnail |
| audio | `.ogg`, `.wav`, `.mp3` | type icon and download |
| font | `.ttf`, `.otf`, `.woff`, `.woff2` | type icon and download |
| 3D | `.glb`, `.gltf`, `.obj` | type icon and download |

- Feature-local, level-local, UI, `shared/assets/`, and top-level asset files all remain visible.
- `assets/generated/` and `assets/uploads/` are platform-reserved source-label prefixes. Do not
  place ordinary project files under either prefix. Current chat attachments are temporary and do
  not automatically persist to `assets/uploads/`.
- `.gdignore` affects Godot import only. It does not hide a supported extension from Builda Web.
  Reference art, test fixtures, addon media, and DCC exports with supported extensions will appear.
- `.md`, license text, `.tres`, `.res`, shaders, animation resources, and unsupported DCC masters
  are not current Web catalog types.
- Empty files, symlinks, and excluded build/cache directories are skipped; each visible file must
  be at most 64 MiB. The scanner caps candidates at 10,000.
- The current Web client requests only the first 200 assets sorted by relative path and does not
  follow `nextCursor`. Above that count, catalog completeness is a known product limitation—not a
  reason to distort project ownership folders. Verify the required asset appears after refresh.

## Provenance manifest

Maintain one row per asset or inseparable logical batch:

```markdown
| path | kind | source_or_creator | license_or_rights | acquired_or_generated | ai_tool_model | modified_by | status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ui/icons/pause_icon.svg | third_party | https://example.test/pack | CC0-1.0 | 2026-07-23 | n/a | Studio | active |
| assets/generated/forest_gate.png | ai_generated | Builda imagegen | project use approved | 2026-07-23 | provider/model | Artist | active |
```

- `kind`: `original`, `commissioned`, `third_party`, `ai_generated`, or `derived`.
- `source_or_creator`: stable source URL, vendor/package name, or responsible creator—not an
  absolute machine path.
- `license_or_rights`: SPDX identifier when applicable, or a concise contract/usage-rights
  reference. Store required license text under `assets/licenses/`.
- `ai_tool_model`: record the known tool/model for generated media; use `n/a` for non-AI assets.
- `status`: `active`, `placeholder`, `replaced`, or `retired`.

Do not record access tokens, private prompts, user PII, or credentials. If source or rights are
unknown, mark the asset unresolved and do not approve release.

## Lifecycle

### Acquire

- Confirm the asset fits the game's intended distribution, modification, attribution, and
  commercial-use scope.
- Check trademarks, identifiable people, voice rights, and restricted model/output terms when
  applicable.
- Prefer an original-resolution source; do not overwrite it with a runtime-optimized derivative.

### Import and transform

- Keep original authored media and deterministic transformation notes.
- Configure import settings per asset class; never edit `.godot/imported` by hand.
- Keep 3D gameplay wrappers separate from reimported model scenes.
- Review filename case and all `res://` dependencies after a move.

### Verify

- Inspect the representative scene, target-language glyphs, audio loops, animation tracks, and
  material assignments.
- Measure Web payload and runtime behavior in the exported target browser.
- Verify required attribution appears in the product or bundled notices.

### Replace or retire

1. Identify all scene, script, Resource, theme, animation, and export references.
2. Add/import the replacement and update provenance.
3. Update references and verify representative scenes plus Web export.
4. Mark the old row `replaced` or `retired` with the replacement path when useful.
5. Remove the old source only after reference checks pass; let Godot regenerate import cache.

Do not silently delete an asset merely because no text reference is found: Resources can be embedded
or referenced through scenes, themes, animations, and import metadata.

## Version control and runtime writes

- Commit runtime source media and its `.import` sidecars. Commit Godot 4.4+ `.uid` sidecars; move a
  script or shader together with its `.uid` when working outside the editor.
- Ignore `.godot/` and generated `*.translation` files.
- Prefer text `.tscn` and `.tres` files. Decide on Git LFS before first committing large textures,
  audio, video, or models.
- Imported resources are loaded through `preload()`, `load()`, or `ResourceLoader`, never by
  reading `.godot/imported` with `FileAccess`.
- Write saves, settings, screenshots, and runtime caches to `user://`; packaged `res://` content is
  not a runtime persistence location.
- Before deleting or moving media, scan `.tscn`, `.tres`, `.gd`, themes, animations,
  `project.godot`, import dependencies, UID references, and dynamic path catalogs. Text grep alone
  is not proof that an asset is unused.

## Upstream basis

The import, cache, and sidecar rules target Godot 4.6's
[import process](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/import_process.html),
[project organization](https://docs.godotengine.org/en/4.6/tutorials/best_practices/project_organization.html),
and [version-control guidance](https://docs.godotengine.org/en/4.6/tutorials/best_practices/version_control_systems.html).
Builda's fixed `assets/generated/` destination is a platform contract. The provenance manifest is
this Agent's governance policy; after a tool imports generated media, the implementing Agent must
add or update its manifest entry.

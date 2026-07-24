---
name: assets-pipeline
description: Import, organize, load, and validate project assets for Builda's Godot 4.6.x GDScript single-threaded Web runtime. Use for texture, audio, font, model, animation, and Resource import settings; preload/load decisions; dependency paths; Web payload size; and reimport-safe workflows.
---

# Assets Pipeline

Target Godot 4.6.x, GDScript, single-threaded Web export, and the Compatibility renderer.

## Govern the complete lifecycle

1. **Acquire**: confirm source, creator, license or usage rights, and project scope before import.
2. **Record**: add the file or logical batch to `assets/asset_manifest.md`; copy required license
   text into `assets/licenses/`.
3. **Classify and name**: use `snake_case` paths beside the owning feature, level, or UI; promote
   media to `shared/assets/` only for real reuse. Keep Builda-generated images in
   `assets/generated/`. Do not create empty category trees.
4. **Import**: preserve source files, configure Godot import settings, and keep `.godot/imported`
   generated data separate.
5. **Use**: reference stable `res://` paths; allowlist and type-check any data-driven runtime choice.
6. **Verify**: inspect representative scenes and the exported Web build for fidelity, payload,
   caching, and target-language/audio behavior.
7. **Replace or retire**: update all references and manifest status, verify dependencies, then remove
   the old source and generated import state through Godot's normal reimport flow.

Builda Web discovers supported image, audio, font, and 3D extensions by recursively scanning the
whole project, not only `assets/`. Feature-local and `shared/assets/` files remain visible in the
flat catalog; relative paths are searchable and appear in the selected asset inspector. Preserve
the platform source prefixes `assets/generated/` and `assets/uploads/`; current chat attachments do
not automatically persist to `uploads`. `.gdignore` does not hide supported files from the Builda
asset panel. Read the display contract in
[references/asset-governance.md](references/asset-governance.md) before choosing where reference,
fixture, addon, or authoring media lives.

For AI-generated media, record the generation tool/model, generation date, human editor, and known
rights or restrictions. Image-generation results imported by Builda must stay under
`assets/generated/` as required by the platform contract. After the import tool finishes, the
implementing Agent must add or update the governance manifest entry. Do not store credentials,
private prompts, or external absolute paths in provenance records. Read
[references/asset-governance.md](references/asset-governance.md) before adding, moving, replacing, or
removing project media.

## Source and generated boundaries

- Keep editable source files outside generated `.godot/imported` data.
- Never hand-edit imported cache artifacts.
- Commit source assets, `.import` metadata represented by project files, and required generated resources according to repository policy.
- Use stable `res://` paths and update references through the editor or verified text changes when moving assets.
- Treat filename case as significant; Web hosting commonly runs on case-sensitive filesystems.
- Do not treat downloaded, commissioned, bundled, or AI-generated media as rights-free. Unknown
  provenance is a release blocker until the owner resolves or replaces it.

## Import by asset class

### Textures

- Set a size limit for oversized source art; target broad Web devices with textures no larger than 4096 pixels per dimension unless measured otherwise.
- Choose lossless/compressed import according to visual content and target browsers.
- Disable filtering for pixel art; enable mipmaps for scaled or 3D textures.
- Use power-of-two dimensions when repeat compatibility matters.
- Verify VRAM compression settings for every intended Web device family.

### Audio

- Use WAV for short, latency-sensitive effects when size allows.
- Use Ogg Vorbis or MP3 for longer music/ambience based on measured decode, size, and loop requirements.
- Coordinate playback type with the Web limitations documented by `audio-system`.

### Fonts

- Include the actual font asset; do not rely on host system fonts.
- Limit glyph ranges or use fallbacks deliberately when download size matters.
- Verify target-language glyphs and browser rendering in the exported build.

### Models and animation

- Prefer glTF/GLB for 3D interchange.
- Fix scale, axes, materials, skeleton naming, and clip slicing in source/import settings.
- Use inherited scenes or separate gameplay wrappers so reimport does not overwrite authored gameplay nodes.
- Recheck animation track paths and material overrides after source updates.

## Runtime loading

Use `preload()` for fixed dependencies known when the script parses. Use `load()` for bounded data-driven paths whose existence and type are validated.

```gdscript
const ICON: Texture2D = preload("res://ui/icons/pause_icon.png")
const LEVEL_PATHS: Dictionary[StringName, String] = {
    &"tutorial": "res://levels/tutorial/tutorial.tscn",
    &"forest": "res://levels/forest/forest.tscn",
}

func load_level(level_id: StringName) -> PackedScene:
    if not LEVEL_PATHS.has(level_id):
        push_error("Rejected level id: %s" % level_id)
        return null
    var path: String = LEVEL_PATHS[level_id]
    if not ResourceLoader.exists(path, "PackedScene"):
        push_error("Missing level scene: %s" % path)
        return null
    var resource := ResourceLoader.load(path, "PackedScene")
    if resource is not PackedScene:
        push_error("Level is not a PackedScene: %s" % path)
        return null
    return resource
```

Do not accept arbitrary paths from save, network, or user-controlled data. Map stable IDs to allowlisted project paths.
Read [references/runtime-resource-loading.md](references/runtime-resource-loading.md) for an
ID-to-path catalog that validates both containment and the loaded resource type.

For large content, prefer smaller scenes/resources and staged main-loop loading with visible progress. The Builda Web target does not use worker-based loading patterns.

## Web payload and cache

- Measure initial `.pck` size and first-load time on realistic networks.
- Defer optional content by product boundary rather than hiding all assets behind one startup load.
- Remove unused source duplicates from exported resources.
- Test cache invalidation after replacing assets; browsers and service workers can retain older payloads.
- Verify MIME types and server compression for exported Web artifacts outside the project asset pipeline.

## Reimport-safe workflow

1. Change the source asset or import settings.
2. Reimport using the pinned Godot editor.
3. Inspect changed project files and dependency warnings.
4. Open representative scenes.
5. Run the exported Web preview and compare visuals/audio/animation.

## Checklist

- [ ] Every third-party, commissioned, bundled, or AI-generated asset has source, creator, rights,
      and status recorded in `assets/asset_manifest.md`.
- [ ] Source files and generated import cache remain separate.
- [ ] Asset directories and filenames use `snake_case`; Builda-generated images stay under
      `assets/generated/`.
- [ ] `assets/uploads/` is reserved for the platform `uploaded` source label; no claim assumes that
      current chat attachments automatically persist there.
- [ ] Supported media in `source_assets/`, tests, or addons is intentionally visible in Builda Web;
      `.gdignore` is not treated as an asset-panel exclusion.
- [ ] Asset paths and filename case are stable.
- [ ] Texture size, filtering, mipmaps, and compression match use.
- [ ] Font glyph coverage is verified.
- [ ] Model wrappers survive reimport.
- [ ] Runtime paths are allowlisted and type-checked.
- [ ] Large content is staged without worker-dependent APIs.
- [ ] Initial payload and target-browser behavior are measured.

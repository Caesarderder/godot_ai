---
name: asset-finder
description: Find visual game assets from Builda's reviewed source registry, verify usage rights, safely download selected files into the current Godot project, record provenance, and validate import. Use when a user asks to find, download, or add 2D, 3D, UI, icon, texture, animation, or other art assets.
---

# Asset Finder

This is an internal `godot-art` workflow, not a seventh public Builda skill. Use it through
`$godot-art -> system -> asset-finder`.

## Scope

Use this workflow for visual game assets:

- 2D sprites, tilesets, backgrounds, maps, UI, icons, fonts, and VFX textures;
- 3D models, environments, props, characters, animations, materials, and skyboxes.

Route music and sound effects to `godot-audio`. Route runtime systems, TileMap code, import plugins,
or resource-loading code to `godot-programming`. Asset Finder may download visual files and arrange
them for import, but it does not invent gameplay or silently rewrite existing scenes.

## Activation

Activate contextually for requests such as:

- “找一些免费的 2D 农场地图素材。”
- “找一套可以商用的低多边形城市场景并下载到工程。”
- “给这个 Godot 项目补一套 UI 图标。”
- “从素材网站下载这套 tileset 并导入。”

If the user asks only for recommendations or links, stop after the shortlist. Otherwise, a request
to find and add assets authorizes downloading the smallest suitable free package into the current
project without an extra confirmation round. Never make a payment, create an account, accept a
subscription, or use credentials on the user's behalf.

## Workflow

### 1. Inspect the project and turn the request into a search brief

Before searching, inspect `project.godot`, the relevant feature/level/UI directory, existing asset
style, viewport or tile scale, and the dirty worktree. Do not overwrite or relocate existing files.

Write a compact internal brief containing:

- asset class: sprite, tileset, map, UI, icon, model, material, animation, or another visual type;
- dimension and perspective: 2D/3D, top-down, side view, isometric, first person, and so on;
- theme and style: for example farm, pixel art, hand-painted, or low-poly;
- technical needs: tile size, animation states, transparency, texture resolution, rig, file format;
- license needs: commercial/non-commercial, attribution allowed or disallowed;
- project destination and whether the content is feature-local or genuinely shared.

Distinguish a ready-made map from a tileset that can be used to build a map. Do not claim a pack
contains a complete map unless its official page or downloaded contents demonstrate that.

### 2. Read the source registry

Open [references/sources.md](references/sources.md). Search only the enabled sources recorded there.
Do not silently broaden to a generic search result, mirror, repost, marketplace seller, or another
asset website. If no registered source has a suitable result, report that outcome and propose
adding another source to the registry as a separate change.

### 3. Search official pages and build a small candidate set

Search the registered domain using the user's nouns plus useful synonyms. For a 2D farm request,
examples include `farm`, `farming`, `top-down`, `tiles`, `terrain`, `nature`, `crops`, and
`buildings`.

Open the exact official pack pages and compare at most five strong candidates. Record:

- pack name and official asset-page URL;
- creator or publisher;
- visual match and missing pieces;
- actual contents and formats stated by the page;
- license shown on the pack page;
- download size when visible.

Prefer one coherent pack over a large mixture of inconsistent packs. Do not bulk-download the
whole website.

### 4. Verify rights before downloading

“Free”, “name your own price”, and “royalty free” are not licenses. For the chosen pack:

1. Read the official pack page and the source's current license statement.
2. Confirm the intended project use is allowed, including commercial use when requested or when
   the project may later be commercial.
3. Record whether attribution, share-alike, redistribution, trademark, or other conditions apply.
4. After download, prefer the license or notice included inside the archive when it is more
   specific. If it conflicts with the website, stop and report the conflict.

Unknown or conflicting rights are a blocker. Do not import those files. Availability on a reviewed
source does not waive per-pack review.

### 5. Download without trusting the archive

Download only from the official domain or the exact download URL reached from the official asset
page. Use the runtime's private temporary directory for the archive and inspection; do not leave
archives or partial downloads in the game tree.

Before extraction:

- verify the response is a plausible archive or expected media file rather than HTML;
- apply any size limit stated by the current runtime or user;
- list archive entries first;
- reject absolute paths, `..` traversal, symbolic links, hard links, devices, duplicate normalized
  destinations, or paths that escape the staging directory;
- do not execute bundled programs, scripts, installers, macros, or editor plugins.

If the free download is hidden behind an optional donation prompt, choose the official free
continuation only. Do not initiate a payment.

### 6. Select and place only the required files

Inspect the extracted tree and copy only the files needed for the request. Preserve the original
license and notice files. Prefer Godot-friendly formats:

- PNG or WebP for raster visual assets, SVG only when the source is trusted and the project needs it;
- glTF or GLB for 3D interchange;
- supported font formats already accepted by the project.

Use lowercase `snake_case` names. Put assets beside the owning feature, level, or UI. Use
`shared/assets/` only for real cross-feature reuse. Do not use the platform-reserved
`assets/generated/` or `assets/uploads/` prefixes for downloaded third-party assets.

If any destination already exists, compare content hashes. Reuse identical files; otherwise choose
a non-colliding name or stop if changing references would be required. Never silently overwrite.

### 7. Record provenance and license evidence

Follow the canonical `assets-pipeline` owner. Create or update `assets/asset_manifest.md` and store
required license text under `assets/licenses/`. Record at least:

- source registry ID and official site;
- pack name, creator, asset-page URL, and download date;
- license name, license URL, attribution text, and commercial-use status;
- destination files or directory and SHA-256 of imported source files;
- modifications, selected subset, and intended project scope;
- verification status and any unresolved restriction.

Do not store cookies, tokens, private prompts, temporary absolute paths, or download-session URLs.

### 8. Import and verify in Godot

Let the pinned Godot version import the new source files. Check:

- import errors and missing dependencies;
- tile dimensions, filtering, transparency, texture seams, axes, scale, materials, rigs, and clips
  as applicable;
- representative scenes that use the assets;
- project-relative paths and filename case;
- Web payload impact for large packs.

Static import success does not prove visual quality. When a browser preview is available, inspect
the target scene there; otherwise report visual verification as not run.

### 9. Report the result

Return:

- selected pack and why it matched;
- official source and license;
- exact project-relative destination;
- files retained and files intentionally omitted;
- manifest/license records changed;
- import checks run and their results;
- any visual, browser, attribution, or runtime gap still unverified.

## Stop conditions

Stop without downloading or importing when:

- no enabled source matches the request;
- commercial or modification rights are unclear;
- the download requires payment, an account, credentials, or accepting unexpected terms;
- the archive is unsafe, unexpectedly large, corrupt, or not the advertised content;
- importing would overwrite project files or materially change the requested scope.

# Release asset and license inventory

Candidate scope: Project A Godot Web export, Earth Skibidi versus Alliance playable slice.

This inventory covers the assets currently intended to ship from `project-a/`.

## Runtime and code

| Item | Source | License / permission | Distribution status |
|---|---|---|---|
| Project GDScript, scenes, and generated gameplay/UI geometry | Created in this repository | Project-owner controlled | OK for internal test and controlled Web export |
| Godot Engine Web runtime and export shell | Godot Engine 4.6.3 export template | Godot Engine license applies | Must ship with Godot license notice in final store package |

## Fonts

| Item | Source | License / permission | Distribution status |
|---|---|---|---|
| `assets/fonts/NotoSansCJKsc-Regular.otf` | Noto Sans CJK Simplified Chinese Regular; upstream `notofonts/noto-cjk`, `Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf` | SIL Open Font License 1.1 | Upstream font identity and license path recorded |
| `assets/fonts/OFL.txt` | Exact SIL OFL 1.1 license text distributed by `notofonts/noto-cjk` at `Sans/LICENSE` | SIL Open Font License 1.1 | Present; placeholder template header removed |

## Generated visual assets

| Item | Source | License / permission | Distribution status |
|---|---|---|---|
| `release/web-icon.svg` | Program-generated original “porcelain fortress + factory core + breakthrough arrow” mark; created in this repository without third-party artwork | Project-owner controlled | Approved candidate PWA/application icon; safe SVG profile validated at 32/512 px |
| Runtime 3D primitives, UI panels, generated effects, and export splash/icon derivatives | Program-generated from project code or Godot export | Project-owner controlled / Godot export generated | OK as prototype-generated assets |
| `assets/3d/porcelain-raider-kit/` | Original low-poly models generated with the project Asset Vault Blender pipeline; no third-party mesh or texture incorporated | Project-owner controlled | OK for internal test and controlled Web export; fan-content premise still requires review |

## Audio

| Item | Source | License / permission | Distribution status |
|---|---|---|---|
| `assets/audio/ui/` | Kenney UI Audio, selected `click1.ogg` and `switch3.ogg` | Creative Commons CC0 | Commercial use and redistribution permitted; official notice retained |
| `assets/audio/sfx/` | Kenney Impact Sounds, selected light/heavy metal impact OGG files | Creative Commons CC0 | Commercial use and redistribution permitted; official notice retained |
| `assets/audio/jingles/` | Kenney Music Jingles, selected HIT00 and NES03 OGG files | Creative Commons CC0 | Commercial use and redistribution permitted; official notice retained |

Exact upstream filenames, official asset pages, SHA-256 hashes, and omitted files are recorded in
`assets/audio/asset_manifest.md`; official pack notices are retained in `assets/audio/licenses/`.

## Explicitly not yet cleared for public store release

- Any third-party images, music, SFX, models, brand marks, or external fan assets not listed above.
- Any copyrighted Skibidi Toilet screenshots, episode audio, extracted meshes, logos, or ripped character assets.
- Any marketplace/store capsule art not produced and licensed for this project.

Upstream references:

- `https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE`
- `https://github.com/notofonts/noto-cjk/blob/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf`
- `https://kenney.nl/assets/ui-audio`
- `https://kenney.nl/assets/impact-sounds`
- `https://kenney.nl/assets/music-jingles`

Public release remains blocked until the final shipped artifact has a complete asset manifest with exact upstream sources, license texts, attribution obligations, and distribution permission for every asset, plus an independent legal/IP review of the fan-content premise.

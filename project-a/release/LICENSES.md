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
| `release/web-icon.svg` | Program-generated placeholder release icon | Project-owner controlled | OK as temporary package icon; final art direction may replace it |
| Runtime 3D primitives, UI panels, generated effects, and export splash/icon derivatives | Program-generated from project code or Godot export | Project-owner controlled / Godot export generated | OK as prototype-generated assets |

## Explicitly not yet cleared for public store release

- Any third-party images, music, SFX, models, brand marks, or external fan assets not listed above.
- Any copyrighted Skibidi Toilet screenshots, episode audio, extracted meshes, logos, or ripped character assets.
- Any marketplace/store capsule art not produced and licensed for this project.

Upstream references:

- `https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE`
- `https://github.com/notofonts/noto-cjk/blob/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf`

Public release remains blocked until the final shipped artifact has a complete asset manifest with exact upstream sources, license texts, attribution obligations, and distribution permission for every asset, plus an independent legal/IP review of the fan-content premise.

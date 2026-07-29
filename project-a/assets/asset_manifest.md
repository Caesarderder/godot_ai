# Visual Asset Manifest

本文件是视觉素材的来源、许可和验证清单。状态定义与引入流程见
[ASSET_MANAGEMENT.md](ASSET_MANAGEMENT.md)。

## Project-owned and pre-existing batches

### `porcelain_raider_kit_v001`

| Field | Value |
|---|---|
| Status | `approved` |
| Asset class | 3D character models |
| Location | `assets/3d/porcelain-raider-kit/models/` |
| Contents | 8 GLB files: armored, assault, bomber, parasite, repair, rocket, saw, sonic |
| Existing metadata | `assets/3d/porcelain-raider-kit/asset_manifest.json` records all 8 hashes, 1,296–1,656 triangles per model, Blender/Godot versions and test commands |
| Intended scope | Eight named allied character variants: assault, sonic, rocket, bomber, armored, saw, repair and parasite |
| Rights status | Project Asset Vault source `project-a-porcelain-raider-kit`, marked usable with no attribution; release inventory identifies it as an original project Blender-pipeline batch |
| Release gate | Independent legal/IP review of the fan-content premise still applies to the product as a whole |
| Notes | Files are referenced only through game-owned wrapper scenes. Hash, triangle and Godot import evidence already exists in the batch JSON. This batch does not cover the complete playable roster. |

### Playable-roster visual coverage

The roster catalog currently contains more archetypes than the dedicated model batch. The runtime deliberately
keeps a procedural body as a prototype fail-safe, but that body is not evidence that every character has a
finished visual identity.

| Coverage | Archetypes | Release meaning |
|---|---|---|
| `unique` | `assault`, `sonic`, `rocket`, `bomber`, `armored`, `saw`, `repair`, `parasite` | Dedicated imported model and wrapper scene |
| `variant-placeholder` | `gman`, `signal_purifier`, `anchor_bastion`, `magnetic_conductor`, `phase_tunneler`, `protocol_weaver`, `ram_breaker`, `smoke_screen`, `mortar`, `interceptor`, `bulwark`, `crusher`, `echo_mimic`, `drain_engine`, `swarm_beacon`, `chronolock` | Procedural body with role parts; acceptable for prototype readability only |

Before any uncovered archetype is called visually complete, give it an asset contract, a dedicated silhouette
or approved reusable variant, manifest provenance, import verification, and a representative 844×390 battle
capture. The procedural fail-safe must remain visibly classified as a placeholder in production tracking.

## Third-party visual batches

### `kenney_ui_sci_fi_v2`

| Field | Value |
|---|---|
| Status | `approved` |
| Registry source | `kenney` |
| Pack / creator | UI Pack - Sci-Fi 2.0 / Kenney |
| Official asset page | https://kenney.nl/assets/ui-pack-sci-fi |
| Download date | 2026-07-30 |
| Upstream archive | 768,505 bytes; SHA-256 `4ae5a4949b71ba6c08bfb4d4708b3880915782f7deae7bc5872e1d56f0a668af` |
| License | Creative Commons Zero (CC0 1.0) |
| License file | `assets/licenses/kenney_ui_sci_fi_cc0.txt` |
| Commercial use | Allowed |
| Attribution | Not required; optional credit: `Kenney` |
| Imported subset | Four 2× PNG sources under `assets/ui/frames/kenney_ui_sci_fi/`: neutral button, primary button, panel frame and cyan progress fill |
| Original subset path | `PNG/Grey/Double/`, `PNG/Yellow/Double/`, `PNG/Extra/Double/`, `PNG/Blue/Double/` |
| Modifications | Semantic `snake_case` renames only; pixels unchanged. Runtime tint and 9-slice margins are owned by `game/scripts/ui/ui_art_direction.gd` |
| Intended scope | Shared App Shell headers, primary/secondary actions, navigation dock and compact progress carriers |
| Omitted | 1,113 unused files including duplicate colors/scales, cursors, fonts, previews, SVG sources and unrelated controls |
| Source size retained | 4 PNG files totaling under 6 KiB compressed, plus the 1 KiB license text |
| Style review | Selected angular header blade, corner screws and restrained cyan/yellow state family match the accepted dark industrial command-console thesis; red/green variants are reserved for semantic danger/success and were not imported |
| Godot import | Godot 4.6.3 imports all four retained PNGs successfully; UI smoke, factory, legion and battle HUD tests pass; representative 844×390 captures were reviewed for a consistent frame language, active-state gold and cyan status semantics |
| Web verification | Reproducible measurement export passes local artifact checks except the dirty-source release-candidate gate; `index.pck` is 20,475,788 bytes versus 20,381,628 bytes previously (+94,160 bytes), and the gzip initial payload remains below the 30 MiB hard limit. This measurement is not labeled a release candidate because regenerated screenshot evidence remained dirty |

SHA-256:

```text
a66013bdbdfa50e24e1bf5bb89e584e2218b995890df4076d9c1786153ba4e31  button_frame_neutral.png
28aae0671d5f036228b5835ab9452ab80071cb70e6c89dc8195d9c31c5a70752  button_frame_primary.png
596c7fc0e44f6f719aaf59dcfa936d6b02a2d2f19dfabe4ba4d492ae08e14bb2  panel_frame.png
af13ccda23a736cdf18049cbe05586178e7cde8fddb5617bcf19cd5b10fcc3b9  progress_fill_cyan.png
```

### `kenney_game_icons_v1`

| Field | Value |
|---|---|
| Status | `approved` |
| Registry source | `kenney` |
| Pack / creator | Game Icons 1.0 / Kenney |
| Official asset page | https://kenney.nl/assets/game-icons |
| Download date | 2026-07-27 |
| License | Creative Commons Zero (CC0 1.0) |
| License evidence | Asset page and https://kenney.nl/support; the archive does not include a separate `License.txt` |
| Commercial use | Allowed |
| Attribution | Not required; optional credit: `Kenney` |
| Imported subset | 13 white 2× PNG icons under `assets/ui/icons/kenney_game_icons/` |
| Original subset path | `PNG/White/2x/` |
| Modifications | `exitRight.png` → `exit_right.png`; `signal3.png` → `signal_3.png`; no pixel edits |
| Intended scope | Battle controls and future navigation/status icon mapping |
| Omitted | Black variants, 1× duplicates, device prompts, media controls not in the requirements brief |
| Godot import | Godot 4.6.3 texture import succeeds; battle HUD uses pause, target and exit-right at max width 18 px |
| Web verification | 844×390 Compatibility screenshot checked; Web export succeeds; Chrome 150 browser smoke passes at 568×320, 844×390, 1024×768, portrait gate and 1280×540; combined selected visual batches add 160,140 bytes to `index.pck` versus the preceding local build |

SHA-256:

```text
00e3025322ddb4948598b7fb8d385762073de7b2b534d2cfd44372072608a92a  checkmark.png
1ecb1247f22644952fb032461cb0b40ef601de9eee5f88bd49bf7015260470a8  exit_right.png
50b313ffe97db1733e529d5b0f5ac91eed5c0c8ffee1034bbb7766508e4f720c  gear.png
1f6d39df47cb8849feb8f01aad329583f5f014c449c622b39aa154a3eca55160  home.png
b83e9f3d17e94a054fa0add775e89eb6973052dca9185a4b5fface1d14cf9cd1  locked.png
e9c3199ee5c296f438598bf3ee959ecc476ee07ea24463702c72ce2a5356f11b  multiplayer.png
5c940ad60dd46b3252d4f991f24e9c21865722fe401947830228629baed28774  pause.png
04305c07a1af5ee3782a96c6bbe027e6d90eb11f892ae1a4e1a3b645c7421a62  signal_3.png
8e10578b82d6d46aff27a9939f4c1adccd1be6dc93c8302c9e28d281e126aae2  star.png
afd40325569fa91bfc690856dc4c70901bbd7c2e27dedc9fe3847258c61bbc81  target.png
9525a3a01eb4ffddbb1c6dd9444ffa20876d18843d7ddd44e6c80d28744e8714  trophy.png
dcd64b5bbf8073c222581e7da1ce74ad29d64762345ff5825300b823b3fba8f5  warning.png
024ffc10111b23b5f3fcf820cbb1959942cbfe54a4466141d7d6a8df1fa21db2  wrench.png
```

### `kenney_city_industrial_v1`

| Field | Value |
|---|---|
| Status | `approved` |
| Registry source | `kenney` |
| Pack / creator | City Kit (Industrial) 1.0 / Kenney |
| Official asset page | https://kenney.nl/assets/city-kit-industrial |
| Download date | 2026-07-27 |
| License | Creative Commons Zero (CC0 1.0) |
| License file | `assets/licenses/kenney_city_industrial_cc0.txt` |
| Commercial use | Allowed |
| Attribution | Not required; optional credit: `Kenney` |
| Imported subset | Buildings A, D, H, P; large chimney; shared GLB colormap |
| Original subset path | `Models/GLB format/` |
| Modifications | Hyphens changed to underscores; geometry and texture pixels unchanged |
| Intended scope | Four side-street silhouettes and one distant chimney in the 3D battle avenue |
| Omitted | 16 other buildings, 3 chimney variants, FBX/OBJ duplicates, previews, samples and unused texture variations |
| Dependency exception | Upstream GLB files reference `Textures/colormap.png`; original directory case is preserved for reimport |
| Godot import | Godot 4.6.3 GLB import succeeds after retaining the shared colormap |
| Web verification | 844×390 Compatibility screenshot checked for action-area obstruction; Web export and Chrome 150 browser smoke pass; combined selected visual batches add 160,140 bytes to `index.pck` |

SHA-256:

```text
62b0b9ffbcea8dd914a899cacd10b54629bf7013db7bd221f2708c7ba8b054ea  building_a.glb
32874b4da6aac35ae04f1f033a99c9f0533268919486471654847601692b12d1  building_d.glb
78ab08340e3e8c26a2c58ad9fe1699cfbb13dee7cac2102ec41fa3cd1347dfed  building_h.glb
ee14bb109a92c71eaf5c869a2da47aca8ac5e5ddaa629a079023b02e521dd504  building_p.glb
c9929b82a913d0372ee8849440ee9ecd79a9609aac46fb091074fdeafb731126  chimney_large.glb
4a912ef8e95fbec4ac0cacc295b9221a4b66c482d4f90bec4e2277689c21a623  Textures/colormap.png
```

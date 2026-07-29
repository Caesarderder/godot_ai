# Project B visual direction — “Nightglass Blacksite”

## Visual proposition

Original near-future covert assault: dense charcoal concrete and gunmetal silhouettes cut by cold cyan navigation light, sodium-orange threat lighting, rain-slick reflections, restrained fog, and sharp white weapon feedback. The scene should feel authored and tactical without copying any proprietary military-shooter branding, assets, maps, characters, or UI.

## Player fantasy and loop

- Fantasy: a highly trained operator entering a fortified signal facility alone.
- Loop: scan lanes → choose cover → acquire target → fire controlled bursts → read confirmation → reposition/reload → secure the core.
- Pressure: exposed sightlines, crossfire, limited magazine, and enemy attack cadence.
- Inputs: desktop keyboard and mouse for this slice.

## Information hierarchy

- T0 world action: enemy silhouettes, muzzle direction, cover edges, sight picture, hit surfaces.
- T1 survival/timing: health, incoming-damage vignette, low-ammo warning, objective remaining.
- T2 strategy: magazine/reserve, crosshair spread, reload progress, clear time/accuracy.
- T3 recap: outcome and compact after-action summary only.

## HUD map

```text
┌ objective / remaining ───────────────────────── status line ┐
│                                                             │
│                     protected sight picture                 │
│                            +                                │
│                                                             │
│ health / armor                                     ammo     │
└ compact prompt ───────────────────────────── weapon / mode ─┘
```

The center stays clear except for a thin reticle and event-limited hit marker. No minimap, quest panel, or decorative lower-third is added to this slice.

## Shape, material, color, and lighting language

- Architecture: long horizontal concrete masses, beveled steel frames, vertical signal pylons, and readable waist-high cover.
- Player weapon: compact angular bullpup silhouette built from a few clean primitives; dark metal body, matte polymer, cyan status strip, white muzzle energy.
- Enemies: tall armored silhouettes with a bright orange visor and shoulder emitter; body shape, not color alone, distinguishes them from cover.
- Materials: rough concrete, satin dark metal, limited emissive strips; no noisy texture collage.
- Palette:
  - void charcoal `#071018`
  - concrete blue-gray `#182631`
  - tactical cyan `#36D7FF`
  - threat amber `#FF9E3D`
  - lethal red `#FF3D55`
  - readable white `#EAF6FF`
- Lighting: one cool directional/moon source, bounded cyan practical lights, orange threat pools, soft environment fog. Shadowed local lights remain rare.
- Camera: 75–82° horizontal-feeling field of view, weapon low-right, modest recoil and bob. No constant shake.

## Component states

| Component | Normal | Warning | Critical/reward |
|---|---|---|---|
| Reticle | thin cyan-white | expands on movement/recoil | brief white hit X; amber lethal diamond |
| Health | compact white/cyan bar | amber under 45% | red pulse under 20%, no strobing |
| Ammo | white numerals | amber under 25% magazine | red `RELOAD`, progress line during reload |
| Objective | white title + cyan count | orange when one target remains | cyan secure banner on victory |
| Enemy | orange visor/shoulder light | muzzle preflash before attack | emission collapses and silhouette drops on death |
| Outcome | hidden | — | darkened scene, concise result and restart CTA |

## Feedback contract

| Event | Primary channel | Secondary channel | Budget |
|---|---|---|---|
| Shot | muzzle flash + viewmodel recoil | short reticle kick | under 90 ms |
| Accepted hit | world impact + hit marker | target flash | 100–160 ms |
| Lethal hit | enemy silhouette collapse | amber lethal marker | under 300 ms |
| Player damage | directional red edge/vignette | restrained camera impulse | 180 ms |
| Low ammo | ammo color/state change | reload prompt | persistent until resolved |
| Reload | weapon dip/return | progress line | authored duration |
| Victory/failure | world desaturation/dim | summary panel | transition under 450 ms |

## Asset and geometry plan

The first slice uses only Godot-authored primitive meshes, `StandardMaterial3D`, gradients/colors, and procedural placement. This is legally clean and ensures style consistency, but it is not photorealistic final art. Unique assets are the weapon silhouette, enemy silhouette, signal core, and cover language. Repeated architecture uses instanced primitive modules. No third-party asset is accepted without provenance and license records.

## Performance budget

- Compatibility/WebGL 2 only; no SSR, volumetric fog, decals, TAA, compute shaders, or advanced GI.
- One shadowed directional light; local lights unshadowed unless a measured exception is justified.
- Target under 150 visible primitive mesh instances, under 24 distinct materials, and under 12 active local lights.
- Opaque materials by default; emission replaces transparency where possible.
- FX are short-lived and pooled or bounded.

## Runtime screenshot acceptance states

At 1280×720 capture:

1. `quiet_entry`: player weapon, goal, signal core, and first lane are readable within two seconds.
2. `combat_peak`: at least two enemies, a muzzle event, hit marker, and damage pressure remain readable without HUD obstruction.
3. `low_health_reload`: critical survival and reload action dominate without hiding the sight picture.
4. `victory`: secured core and after-action summary read as a single payoff.
5. `failure`: cause, state, and restart action are obvious.

“Presentable” requires coherent silhouette, deliberate lighting, readable cover, consistent materials, and complete feedback in actual runtime captures. Primitive grayboxes, default Godot controls, flat lighting, arbitrary neon, or screenshots without combat pressure remain prototype evidence only and cannot be called AAA.

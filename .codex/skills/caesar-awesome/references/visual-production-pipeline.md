# Visual production pipeline

Use this reference when a Caesar Loop task must produce a credible game image,
not merely functioning mechanics. Adapt it to the current engine, renderer,
platform, and asset policy; do not treat any particular API or post stack as a
requirement.

## Outcome and ownership

Start with a player-facing image, not a list of effects. For each named shot,
record:

| Shot | Player question | Focal hierarchy | Acceptance evidence |
|---|---|---|---|
| Establishing/gameplay | Where am I, what matters, where is danger? | objective/threat → route → spatial depth | fixed gameplay capture and blind critique |
| Close form/material | Does this object have believable scale, construction, and surface response? | silhouette → joints/bevels → material separation → microdetail | fixed close capture at intended viewing distance |
| UI under action | Can I act and recover without losing the scene? | immediate feedback → resource/health → navigation/status | scripted action capture plus unreadability report |
| Interior or stress, when relevant | Does the look survive a different light/load condition? | navigation → value separation → stable effects | capture plus representative performance profile |

Give the following one sequential owner: sun/key and practical lights,
environment/IBL, exposure, tone map, grade, camera response, and post effects.
They form one look; independently "improving" any one of them invalidates the
same screenshot. Give models, one material family, set dressing, VFX, audio, and
HUD separate owners only after their input/output contracts and named shots exist.

## Production order

### 1. Establish form and spatial composition

Build the playable route and primary silhouettes first. Use real-world scale,
negative space, wall thickness/doorways where relevant, foreground/midground/
background depth, and a constrained palette of repeated modular parts. Make the
hero camera face a readable action or route; a detailed scene with no hierarchy
will still look synthetic.

For props and weapons, prioritize in this order:

1. recognisable silhouette and proportions;
2. construction logic: separate pieces, seams, joints, recesses, apertures;
3. bevels/curvature that catch light at gameplay distance;
4. deliberate variation in rotation, scale, placement, damage, and clutter;
5. only then fine engraved or micro geometry.

For procedural geometry, generate a small reusable kit and instance it. Keep
collision proxies separate from render meshes. For imported assets, retain the
same design record plus source, licence, import settings, material assignment,
and LOD/culling policy.

### 2. Make surfaces respond to light

A material is a response model, not a colour. Define a PBR surface contract:

| Channel/property | Job | Typical failure |
|---|---|---|
| Base colour | broad pigment/value and restrained staining | uniform paint or crushed/dirt-only colour |
| Normal or height | visible relief that catches light at intended distance | flat plastic or noisy, aliased grit |
| Roughness | separates coated, worn, wet, brushed, fabric, and dusty areas | one glossy/plastic response everywhere |
| Metalness | distinguishes conductors from dielectrics | grey-metal shortcut or coloured metallic plaster |
| AO/cavity | supports creases and recesses, never replaces lighting | black outlines and muddy albedo |
| Macro/detail variation | prevents tiling across metres and flatness within centimetres | periodic noise or salt-and-pepper shimmer |

Author three spatial frequency bands deliberately: macro variation for metres,
meso wear/assembly for centimetres, and micro grain for millimetres. Ensure the
micro band survives filtering and mip levels; detail below the sampling limit is
not texture richness. Drive wear from meaningful structure where possible
(curvature, exposed edges, cavities, water/dirt accumulation), and vary albedo,
roughness, and relief together only when the material calls for it.

For a no-art pipeline, generate packed PBR maps on GPU or at build time and use
normal-from-height only when the height field has a plausible scale. Use
triplanar/world-space projection for large generated surfaces where UV seams or
repeated tiles would be visible.

### 3. Light in linear HDR before grading

Set the lighting hierarchy before polish: key direction, sky/environment fill,
plausible indirect/bounce approximation, practical sources, and contact cues.
Check exterior, interior, transition, and combat-flash conditions separately.
Require clear subject/background value separation and contact grounding, but do
not paint AO or vignette over an incoherent lighting model.

Keep the render pipeline conceptually ordered as:

`linear HDR scene → shadows/depth/contact/ambient effects → temporal or screen-space effects → exposure → bloom → tone mapping → display grade → UI composite`

The exact passes vary by engine. The rules do not: perform light transport and
optical effects in linear space; tone-map once; use exposure as a photographic
control rather than arbitrary per-material brightness; and test temporal effects
in motion, not only in a still. Separate first-person viewmodels from the world
when their depth, fog, animation, or temporal requirements differ.

Use effects for a stated visual job:

| Effect family | Legitimate job | Do not use it to |
|---|---|---|
| Shadow/contact/AO | ground objects and clarify depth | create black decals around every edge |
| Temporal AA / motion blur | stabilise sub-pixel detail or express motion | hide bad animation or smear UI/viewmodels |
| Bloom | communicate bright highlights | make an otherwise flat scene cinematic |
| Fog/volumetrics | express atmosphere and depth | obscure broken composition |
| SSR/reflection | add conditional surface context | promise accurate global reflection |
| LUT/grade/grain/vignette | unify display response and focus | compensate for wrong lighting or material values |

### 4. Compose the camera and action feedback

Review the actual player camera. Do not approve an asset only from an editor
viewport. Preserve readable horizon, travel route, threat silhouette, and enough
quiet space for HUD. First-person actions need a synchronized response chain:
input → pose/recoil/camera impulse → muzzle/projectile/impact → audio transient
→ hit/damage feedback → resulting game state. Give every link an observable
scenario. Camera shake, particles, and sound reinforce a legible cause; they do
not create one.

### 5. Design HUD as a scene layer

Treat HUD as its own typography and interaction system. Establish hierarchy for
immediate action feedback, survivability/resources, navigation/status, and
optional social/diagnostic information. Test at target resolution, ultrawide or
safe-area variants where supported, bright and dark scenes, damage/action peaks,
and accessibility scaling. Use opacity, blur, contrast, outline, placement, and
motion sparingly; each must preserve scene visibility and reaction time.

The HUD is successful only if a player can answer the relevant gameplay question
without searching. A visually matching font or "military" colour palette is not
enough.

## Evidence loop and gates

Capture the baseline checkpoints as one focused scenario bundle before each
coupled look pass. Every candidate must retain:

`shot/scenario → seed/state/frame budget → before/after artifact → direct observation → metric or critic result → decision → next largest gap`

Use an isolated process/session for strict visual comparison when exposure,
particles, decals, animation, or temporal history can leak between shots. Drive
simulation time and RNG from the capture harness, not wall-clock completion.
Use pixel diffs only for pixel-neutral claims; a better-looking claim needs
before/after shots plus a fresh critic's comparative verdict.

Prefer one launch that advances through the declared shot/state/viewpoint matrix
and emits an indexed contact sheet or sequence. Do not relaunch the main scene
for each shot or angle; use it only through the named integration checkpoint.

Profile representative moving gameplay at target resolution. Report frame-time
percentiles, worst hitches, shader/asset compilation or streaming events, and
memory/resource growth. Average FPS and static camera captures cannot validate
playable visual quality.

## Critic order and repair routing

Ask the critic to choose one largest player-visible gap, then route it by cause:

| Observation | Likely repair lane |
|---|---|
| Subject blends into background | composition plus lighting/exposure owner |
| Object reads as a toy or grey blob | silhouette/construction, then material response |
| Detail turns into repeating noise | material-frequency/UV/projection owner |
| Scene looks cinematic only in one still | coupled look owner; inspect motion and alternate shots |
| HUD competes with action or disappears | UI hierarchy/contrast owner |
| Visual improvement introduces stutter | render/performance owner; profile before reducing quality blindly |
| Individual parts look good but clash | integrator; reconcile scale, palette, lighting, camera, and FX |

Never accept "more effects", "more polygons", or "more texture noise" as a
diagnosis. Preserve the rejected candidate and its evidence so the next loop does
not repeat it.

---
name: 3d-essentials
description: Build or review core 3D scenes for Builda's Godot 4.6.x GDScript Web runtime using the Compatibility renderer. Use for Node3D transforms, meshes, materials, basic lights, environment, baked lighting, visibility ranges, occlusion, and MultiMesh. Exclude renderer-specific advanced pipelines and desktop-only rendering features.
---

# 3D Essentials

Target Godot 4.6.x, GDScript, single-threaded Web export, and the Compatibility renderer. Web export uses WebGL 2; design and test against that renderer from the start.

## Boundary

- Use core 3D nodes and renderer features confirmed in Compatibility.
- Do not design around RenderingDevice, compute shaders, custom render passes, decals, particle trails, screen-space reflections, screen-space ambient effects, real-time voxel or signed-distance-field GI, volumetric fog, depth-of-field, temporal antialiasing, or other advanced renderer features.
- Treat desktop editor appearance as provisional until the scene runs in the exported Web preview.
- Keep textures at practical Web sizes; prefer at most 4096 pixels per dimension for broad device support.

## Coordinate and scene basics

Godot uses a right-handed coordinate system. `+Y` is up; cameras and most directional nodes face `-Z` by convention. One unit normally represents one meter.

```text
World (Node3D)
├── Camera3D
├── DirectionalLight3D
├── WorldEnvironment
├── MeshInstance3D
└── GameplayRoot (Node3D)
```

Keep gameplay roots at uniform scale. Apply non-uniform scale to visual children when possible; scaled physics and inherited transforms are harder to reason about.

## Materials

Use `StandardMaterial3D` or `ORMMaterial3D` for most assets. Use `ShaderMaterial` only when a Compatibility-tested spatial shader is necessary.

Core properties:

- albedo texture/color;
- roughness and metallic;
- normal map;
- ambient occlusion texture;
- emission for unlit-looking accents.

Duplicate a shared material before per-instance mutation:

```gdscript
func make_material_unique(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
    var source := mesh_instance.get_active_material(0) as StandardMaterial3D
    if source == null:
        source = StandardMaterial3D.new()
    var unique := source.duplicate() as StandardMaterial3D
    mesh_instance.material_override = unique
    return unique
```

Prefer opaque materials. For foliage and hard cutouts, prefer alpha scissor or alpha hash over fully blended transparency, then verify sorting and shadows in Web.

## Lighting and environment

Start with one `DirectionalLight3D`, environment ambient light, and a restrained number of local `OmniLight3D` or `SpotLight3D` nodes. Compatibility has low base cost but local-light cost scales quickly.

Keep shadowed lights rare. Reduce shadow distance and range to the smallest product requirement. Check shadow bias on target content rather than copying fixed values.

Use `WorldEnvironment` for background/sky, ambient light, tonemapping, color adjustment, basic fog, and supported glow. Avoid configuring unsupported effects merely because their properties appear in the editor.

For mostly static scenes, prefer baked lightmaps created with the native editor and verify the baked result in Web. Use reflection probes only where their visual value justifies the capture and memory cost.

## Visibility and batching

- Configure mesh import LOD and visibility ranges for large scenes.
- Use occlusion culling for scenes with meaningful occluders, then bake and test it.
- Use `MultiMeshInstance3D` for many identical meshes with simple per-instance transforms/colors.
- Split huge worlds into independently loaded regions; avoid placing every asset in one persistent scene.
- Keep draw-call and material variety visible in profiling; one mesh with many surfaces can still be expensive.

## Compatibility validation

Check these in an exported Web preview:

- material fallback and shader compilation;
- transparency sorting;
- light count and shadow cost;
- texture memory and first-load time;
- banding in smooth gradients, since Compatibility uses lower color precision;
- depth precision and z-fighting; increase camera near distance when feasible;
- Safari and at least one Chromium- or Firefox-based browser when those are supported targets.

## References boundary

No bundled reference is required for the default workflow. Existing files under `references/` are optional legacy material and may describe other renderers, languages, or engine versions. Do not load or follow them unless the developer explicitly requests non-default archival comparison; never copy those paths into a Builda Web implementation without current verification.

## Checklist

- [ ] Project renderer and Web export use Compatibility.
- [ ] Scene uses core 3D features available in WebGL 2.
- [ ] Materials are unique only when runtime mutation requires it.
- [ ] Local lights and shadows are bounded.
- [ ] Advanced renderer-only effects are absent.
- [ ] LOD, culling, and batching match the actual scene shape.
- [ ] Texture size and initial download budget are measured.
- [ ] Exported Web rendering is visually checked on target browsers.

---
name: godot-code-review
description: Review changes to a Builda Godot 4.6 GDScript Web project for correctness, lifecycle, scene ownership, security, performance, and verification gaps. Use for diffs, merge requests, regressions, or pre-release audits; report only actionable findings grounded in the reviewed code.
---

# Godot Code Review

Review the real merge-base diff and the affected runtime paths. Target Godot 4.6.x, GDScript,
Compatibility rendering, and Builda's single-threaded Web export. Do not review against other language bindings, future Godot releases,
native-only, threaded, or editor-plugin assumptions unless the repository explicitly opts into them.

## Review sequence

1. Read repository instructions and identify the correct merge base or requested files.
2. Inspect the changed scripts, scenes, resources, project settings, tests, and direct callers.
3. Trace runtime ownership and lifecycle before judging a local pattern.
4. Check each suspected issue against Godot 4.6 behavior and the actual Builda platform boundary.
5. Run the smallest relevant static or headless checks when allowed.
6. Report actionable findings first. Do not fill the response with generic praise or style preferences.

## Finding threshold

Report a finding only when all are true:

- The reviewed change introduced or exposes a concrete failure, regression, security problem, or material maintenance hazard.
- A normal supported input or lifecycle can reach it.
- The affected behavior and repair boundary are specific enough for the author to act on.
- The claim is supported by repository evidence or a verified Godot 4.6 contract.

Separate:

- **Evidence**: what code, scene, config, test, or runtime output directly shows.
- **Inference**: the failure that follows from that evidence.
- **Unknown**: behavior that needs a browser, device, server, addon, or scene run to establish.

## Review checklist

### GDScript and data contracts

- Public parameters, returns, signals, node references, and collections have useful types.
- Empty arrays/dictionaries do not rely on accidental `Variant` inference where a contract matters.
- External dictionaries, JSON, save data, and network data are validated before indexing or casting.
- Dynamic method names and resource paths from untrusted data are allowlisted.
- Shared `Resource` definitions are not mutated as accidental per-instance state.
- `await` paths re-check external objects, scene membership, and stale request generations.

Use `gdscript-patterns` for detailed language rules. Do not duplicate its examples in review comments.
Use `gdscript-patterns/references/script-organization.md` when file naming, script responsibility, or
split boundaries are part of the change.

### Scene ownership and lifecycle

- The scene that creates a node also owns its wiring and teardown, or the alternative owner is explicit.
- `main.gd` remains a thin composition root limited to top-level assembly, scene switching, and
  application lifecycle; gameplay, input, physics, UI, save, audio, and asset implementation live
  under their actual owners.
- Feature-owned scenes, scripts, and resources are co-located where practical; `shared/` contains
  stable cross-feature contracts rather than generic `utils`, `common`, or `misc` buckets.
- Child `_ready()` running before parent `_ready()` cannot observe missing runtime injection.
- Required nodes are not discovered through fragile ancestor/sibling paths.
- Signal connections cannot accumulate across repeated `_enter_tree()`/`_exit_tree()` cycles.
- Timers, tweens, deferred calls, and async work cannot mutate a freed or replaced scene.
- Autoloads hold only application-lifetime responsibilities and do not retain stale scene nodes.

Use `godot-architecture` when communication or dependency boundaries are the issue.
Use `godot-architecture/references/thin-composition-roots.md` and
`godot-project-setup/references/project-layout.md` for structural findings.

### Physics and input

- Character motion belongs in `_physics_process()` and uses the correct delta semantics.
- `move_and_slide()` is not multiplied by delta; explicit acceleration/deceleration is frame-rate independent.
- Collision layer/mask changes use the intended one-based layer API or correct bit positions.
- Area and body callbacks handle nodes leaving the tree during deferred work.
- Input actions are semantic and event consumption matches UI/gameplay ownership.
- Touch, gamepad, and browser focus behavior are not inferred from desktop keyboard smoke tests.

### UI and Web coordinates

- Anchors, offsets, containers, and theme sizing are not mixed accidentally.
- Screen, window, viewport, canvas, CanvasLayer, and local coordinates are converted explicitly.
- Safe-area values are converted into the layout's coordinate space before becoming margins.
- Browser resizing, iframe canvas sizing, focus, and input capture have explicit behavior.
- UI updates are event-driven unless per-frame work is demonstrated to be necessary.

### Rendering, assets, and audio

- Rendering features are supported by Godot Web's Compatibility renderer.
- The change does not assume Forward+, Mobile renderer, Compositor, native threads, or WebGPU.
- Resource paths use `res://`/`user://` correctly and do not escape intended roots.
- Large or optional assets do not block a hot gameplay frame without evidence that loading is acceptable.
- Web audio limitations and browser autoplay are handled when the feature depends on sound at startup.
- New, moved, replaced, or removed media follows
  `assets-pipeline/references/asset-governance.md`: `snake_case` classification, stable `res://`
  references, provenance, creator/source, license or usage rights, and status are recorded.
- AI-generated media records its tool/model and rights restrictions without credentials or private
  prompts; Builda image-generation results remain under `assets/generated/`.
- Data-driven resource loading maps stable IDs to allowlisted paths and verifies the expected
  `Resource` type before use.
- Builda-visible image, audio, font, and 3D files may live under feature or shared owners because the
  catalog scans recursively; `assets/generated/` and `assets/uploads/` retain their platform source
  meanings.
- `.gdignore` is not used to hide supported media from Builda Web. A supported reference file,
  fixture, or addon asset inside the project cannot be hidden by directory policy; accept its
  visibility, keep only an unsupported DCC master, or remove the unneeded file.

### Persistence and security

- Save-slot names and user-controlled path fragments are normalized or allowlisted.
- Writes are atomic or recoverable; corrupted/partial data has an explicit failure path.
- Save schemas are versioned and bounded before allocation or instantiation.
- User-provided scene/resource paths, RPCs, and dynamic actions are authorized on the owning side.
- Logs and errors do not expose credentials, host paths, prompts, or private project content.

### Performance

- A performance finding has profiler, trace, scale, or obviously unbounded-work evidence.
- Per-frame allocations, node searches, signal storms, and draw/physics work are assessed in context.
- Fixed draw-call, node-count, or timing thresholds are not treated as universal acceptance criteria.
- Optimization does not introduce threads or unsupported renderer features into the Builda Web target.

## Validation boundaries

Use the strongest affordable check that matches the change:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 2
```

Then run repository-defined unit/headless tests and Web export checks when available. State what each
check does not prove. A parse check does not prove scene wiring; a desktop headless run does not prove
browser rendering, persistence, focus, audio, weak-network, or lifecycle behavior.

## Output

Order findings by severity. Keep line ranges tight.

```text
[P1] Short actionable title
Evidence: path:line and the concrete contract or state transition.
Impact: the supported scenario that fails and how.
Repair boundary: the smallest ownership or behavior boundary that must change.
Validation: the check that would close the finding.
```

Severity:

- `P0`: release-blocking data loss, security compromise, or broadly catastrophic failure.
- `P1`: supported core flow is broken or unsafe.
- `P2`: narrower correctness or material maintainability problem.
- `P3`: minor but actionable issue; omit pure preference.

If no finding meets the threshold, say so and list only meaningful residual validation gaps.

## Completion checklist

- [ ] The real diff and affected callers/scenes were inspected.
- [ ] Thin composition roots, feature-first ownership, script naming, and asset provenance were
      checked where the diff touches structure or media.
- [ ] Findings distinguish evidence, inference, and unknowns.
- [ ] Every finding is reachable, actionable, and scoped to the reviewed change.
- [ ] Godot claims match 4.6.x and the Builda GDScript single-threaded Web target.
- [ ] Validation commands and their limits are explicit.
- [ ] No non-GDScript, future-version, native-only, threaded, or editor-plugin rule was imposed on the default path.

---
name: animation-system
description: Implement or review Godot 4.6.x runtime animation in GDScript for Builda Web projects. Use for AnimationPlayer, AnimationTree, blend spaces, animation state machines, sprite animation, root motion, retargeting, SkeletonModifier3D, and stable 4.6 inverse-kinematics nodes. Use tween-animation for short procedural property motion.
---

# Animation System

Target Godot 4.6.x, GDScript, and the single-threaded Web runtime.

## Choose the smallest animation tool

| Need | Tool |
|---|---|
| One clip, property track, method track, or audio track | `AnimationPlayer` |
| Blending, layered motion, or transition graph | `AnimationTree` |
| Frame-based sprite clips | `AnimatedSprite2D` / `SpriteFrames` |
| Short procedural UI or effect motion | Tween workflow |
| Runtime skeletal correction | `SkeletonModifier3D` stack or a stable 4.6 IK modifier |

Start with `AnimationPlayer`. Add `AnimationTree` only when the product needs blending or graph-controlled transitions.

## AnimationPlayer

Avoid replaying the same clip every frame when it should continue uninterrupted:

```gdscript
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play_if_changed(animation_name: StringName) -> void:
    if animation_player.current_animation != animation_name:
        animation_player.play(animation_name)
```

Await a one-shot only when its lifecycle is owned:

```gdscript
func play_attack() -> void:
    animation_player.play(&"attack")
    await animation_player.animation_finished
    if not is_inside_tree():
        return
    attack_finished.emit()
```

If another action can interrupt the clip, use explicit state/generation checks instead of assuming `animation_finished` proves the original action is still current.

Keep gameplay authority outside animation method tracks. A track may request a visual or bounded gameplay event, but animation timing should not become the only source of critical persistent state.

## AnimationTree

Assign the `AnimationPlayer`, activate the tree, and drive documented parameter paths.

```gdscript
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = (
    animation_tree.get(&"parameters/playback") as AnimationNodeStateMachinePlayback
)

func set_move_blend(direction: Vector2) -> void:
    animation_tree.set(&"parameters/Locomotion/blend_position", direction)

func travel(state_name: StringName) -> void:
    playback.travel(state_name)
```

Use gameplay state to request animation state. Do not maintain two independent state machines that can disagree about authoritative gameplay transitions.

## Imported clips and retargeting

- Keep source skeleton and bone naming stable.
- Use import settings for clip slicing, looping, root motion, and retargeting rather than patching imported scenes directly.
- Verify track paths after reimport; renamed nodes and bones can silently break animation targets.
- Keep imported animation data separate from runtime state.
- Test compressed clips for visible loss on the actual character and browser.

## Skeletal modifiers and IK

Godot 4.6 provides the stable `SkeletonModifier3D` stack and IK modifiers such as `TwoBoneIK3D`, `FABRIK3D`, `CCDIK3D`, and `JacobianIK3D`.

Choose by chain shape:

- `TwoBoneIK3D` for a simple arm or leg;
- `FABRIK3D` for longer reaching chains;
- `CCDIK3D` for iterative chains such as tails or tentacles;
- `JacobianIK3D` only when its more general solve is justified.

Author the modifier beneath the relevant `Skeleton3D`, verify bone names and target paths, then blend influence rather than snapping between solved and keyed poses. Keep per-frame raycasts and solvers bounded for Web; disable distant or invisible corrections when the visual result allows it.

## Sprite animation

Use `AnimatedSprite2D` for sprite-frame clips and `AnimationPlayer` when the clip also changes transforms, hitboxes, effects, or other nodes. Keep sprite frame resources shared only when runtime mutation is intentional.

## Web runtime checks

- Profile skeletal modifiers with the same visible character count as the first playable.
- Avoid allocation-heavy parameter construction in `_process()`.
- Verify imported animation and root motion in an exported Web build.
- Confirm scene exit, action interruption, pause, and time-scale behavior.
- Do not offload animation logic to background workers.

## References boundary

No bundled reference is required by default. Existing `references/` files are optional legacy detail and may include other languages or version-era notes. Do not load them automatically. If an explicit request needs one, extract only target-version GDScript behavior and verify it against the current project before use.

## Checklist

- [ ] Tool choice matches clip playback, blending, sprite frames, or procedural motion.
- [ ] The same clip is not restarted every frame.
- [ ] Gameplay state remains authoritative over animation state.
- [ ] Awaited clips handle interruption and scene exit.
- [ ] Imported track paths survive reimport.
- [ ] IK uses stable Godot 4.6 modifiers and measured Web budgets.
- [ ] Exported Web playback, pause, and time scale are verified.

---
name: combat-system
description: Use when implementing or reviewing deterministic combat resolution, damage, health, hitboxes, hurtboxes, attacks, combos, hit stop, knockback, and combat feedback in Godot 4.6 GDScript Web games
---

# Combat System for Godot 4.6 Web

Own the combat transaction from an attack becoming active through one accepted hit and its visible result. Reuse **physics-system** for collision/query mechanics, **state-machine** for actor transitions, **animation-system** for animation playback, **audio-system** and **particles-vfx** for presentation, and **game-balance** for tuning. Do not replace their ownership.

## Contract

Model one hit as immutable intent:

`attacker -> attack instance -> contact candidate -> validation -> DamageData -> defender result -> feedback`

Give every attack activation a stable instance ID. A hurtbox accepts that instance at most once unless the attack explicitly supports repeat ticks. Validate team/faction, invulnerability, active windows, target lifetime, and current round/session before mutating health.

Keep `DamageData` as a typed `RefCounted` value or project-owned data shape. Include only values required to resolve the hit: source ID, attack instance ID, base amount, damage tags, impulse, hit position, and optional status payload. Never put scene-node ownership or save authority inside the value.

## Runtime boundaries

- Hitboxes and hurtboxes may use `Area2D`/`Area3D`; collision layers and masks remain owned by **physics-system**.
- The defender owns health mutation, clamping, invulnerability, death transition, and the result returned to presentation.
- The attacker owns activation windows, cooldown consumption, combo intent, and cancellation.
- Presentation observes the accepted result. It must not decide whether damage occurred.
- Use `_physics_process()` for physics-coupled windows. Keep single-frame hit stop bounded; pausing the whole tree requires an explicit pause-mode audit.
- Avoid thread workers, native plugins, remote authority, or editor-only helpers in the default Web path.

## Implementation sequence

1. Locate the current actor state, collision layers, health owner, and animation events.
2. Define the attack instance lifecycle and duplicate-hit rule.
3. Implement pure validation before mutation.
4. Return a result containing accepted/rejected, applied amount, terminal state, and feedback tags.
5. Drive animation, camera, audio, and VFX from that result.
6. Test duplicate contacts, simultaneous lethal hits, cancellation, invulnerability boundaries, freed nodes, and restart/session rollover.

## Acceptance

- One activation cannot damage the same target twice accidentally.
- Rejected hits do not consume defender state or emit success feedback.
- Health is clamped and the death transition is idempotent.
- Combat logic remains deterministic under a fixed input/event sequence.
- Automated tests cover transaction rules; a runtime playtest still verifies readability, timing, and feel.

---
name: ai-perception
description: Use when implementing Godot 4.6 GDScript AI vision, hearing, suspicion, alert state, target evidence, memory decay, and encounter-director pacing for Web games
---

# AI Perception for Godot 4.6 Web

Own how an AI turns observations into evidence. Reuse **ai-navigation** for movement/path following, **state-machine** for behavior transitions, **physics-system** for overlap/raycast mechanics, **audio-system** for sound playback, and **game-balance** for tuning.

## Evidence model

An observation contains source identity, kind, world position, strength, timestamp/tick, and optional target identity. Perception validates it, updates bounded memory, and emits structured evidence changes. It does not directly move or attack the actor.

Vision should combine broad candidate acquisition, range/angle checks, and an occlusion query. Hearing consumes explicit gameplay noise events; do not infer audibility from the rendered audio mix. Suspicion integrates accepted evidence with documented rise, hold, and decay rules.

Use hysteresis for thresholds:

`unaware -> suspicious -> alerted -> searching -> unaware`

Separate enter and exit thresholds so noisy measurements do not oscillate states. The **state-machine** owner decides transitions using perception outputs.

## Runtime limits

- Stagger expensive queries across actors and measure them in the Web runtime.
- Bound remembered targets and evidence history.
- Drop stale source/session identities before use.
- Avoid editor helpers, background threads, network authority, and global scene scans.
- A director may aggregate pressure and emit pacing recommendations; it must not secretly spawn, reward, save, or rewrite objectives.

## Verification

Test field-of-view edges, occlusion, lost/freed targets, duplicate noise, stale observations, threshold hysteresis, decay with pause rules, memory bounds, session reset, and many-actor budgets. Runtime play verifies fairness: players need understandable cues before alert consequences.

# Compatibility-safe particle interaction

> Back to [SKILL.md](../SKILL.md)

Do not route the default Builda Web target to GPU particle attractors, GPU collision volumes, signed-distance-field collision, or turbulence recipes. Their renderer/backend support does not match the Compatibility contract.

Prefer deterministic gameplay-owned effects:

- compute a small capped set of CPU particle or sprite velocities in GDScript;
- raycast or query gameplay collisions before spawning an impact effect;
- stop, bounce, or recycle the effect from that gameplay result;
- fake turbulence with a bounded sine/noise offset on a small number of sprites.

Particles remain visual feedback. Damage, hit detection, and authoritative movement belong to gameplay/physics code, not a particle collision result.

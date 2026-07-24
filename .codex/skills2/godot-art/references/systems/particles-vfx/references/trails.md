# Compatibility-safe trail alternatives

> Back to [SKILL.md](../SKILL.md)

Godot's built-in 3D particle trails are not part of Builda's Compatibility-renderer Web target. Do not enable particle trails or use `RibbonTrailMesh`/`TubeTrailMesh` in the default path.

Use a bounded alternative:

- animate a short `Line2D` history for 2D motion;
- stretch and fade a small `Sprite2D` behind fast objects;
- use an authored transparent quad or mesh segment for a short 3D streak;
- spawn a capped number of ordinary particles and verify Web overdraw.

Keep the history length and spawned effect count fixed. Test resize, hidden-tab resume, and cleanup after the owning scene exits.

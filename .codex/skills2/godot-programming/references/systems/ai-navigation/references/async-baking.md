# Runtime Navigation Baking on Builda Web

Builda's default Godot 4.6 Web export is single-threaded. Background-thread baking examples are therefore not a safe default.

Prefer editor-baked navigation data. When runtime geometry requires a rebake, coalesce changes and invoke `bake_navigation_polygon()` or `bake_navigation_mesh()` synchronously during a loading transition or another controlled pause. Gate dependent agents until the bake completes, then assign their targets again.

Do not pass threaded bake flags or assume worker-thread progress in the default Web profile.

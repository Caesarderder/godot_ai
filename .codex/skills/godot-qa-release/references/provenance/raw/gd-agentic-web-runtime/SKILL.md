---
name: gd-agentic-web-runtime
description: "Use for Godot 4.6 Web runtime quality: browser export constraints, Builda preview evidence, audio, performance profiling, export configuration, and test strategy"
---

# GD-Agentic Web Runtime

Route runtime, preview, quality, and release work to the smallest relevant reference. Builda controls the final Web export and preview boundary.

## Route

| Need | Read |
| --- | --- |
| Audio buses, music, spatial sound, and pooling | [audio systems](references/gd-agentic-audio-systems.md) |
| Export presets and headless export concerns | [export builds](references/gd-agentic-export-builds.md) |
| Profiling, batching, MultiMesh, and LOD | [performance optimization](references/gd-agentic-performance-optimization.md) |
| Browser limitations and JavaScript bridge | [Web platform](references/gd-agentic-platform-web.md) |
| Unit, integration, and runtime test selection | [testing patterns](references/gd-agentic-testing-patterns.md) |

## Script prototypes

After selecting a reference, inspect only its matching `scripts/<gd-agentic-capability>/` directory when a code prototype is useful. These upstream scripts are preserved for adaptation, not pre-approved for direct execution or bulk copying. Native signing, Steam/macOS/Android publishing, external CI, credentials, and threaded export scripts must remain reference-only; Builda owns the supported no-thread Web export and preview path.

## Apply

1. Inspect the project and distinguish implementation checks from Builda-controlled export and preview evidence.
2. Read only the references needed for the current runtime concern.
3. Keep Godot 4.6.x, GDScript, Compatibility rendering, and no-thread Web export as hard defaults.
4. Do not assume CI/CD authority, native signing, platform credentials, or arbitrary browser APIs.
5. Verify static checks, a controlled Web export, preview diagnostics, and observable runtime behavior as appropriate.

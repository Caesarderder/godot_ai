# Web release checklist

State labels:

- `SOURCE_HARDENED`: source has release materials and local checks.
- `ARTIFACT_VERIFIED`: a Web artifact was exported from the frozen candidate and passed local artifact inspection.
- `DEVICE_VERIFIED`: claimed desktop/mobile browsers passed runtime smoke on named devices.
- `HOSTING_VERIFIED`: the final HTTPS URL passed production-origin checks, monitoring, and rollback evidence.

## Local source gate

- [ ] Candidate revision is frozen and dirty state is recorded.
- [ ] `project-a/project.godot` has no conflict markers and uses Godot 4.6.3 Compatibility/Web-safe settings.
- [ ] `project-a/export_presets.cfg` has Web preset, single-thread export, release material include filter, PWA metadata, and no GDExtension support.
- [ ] `project-a/release/LICENSES.md` reflects every shipped asset.
- [ ] `project-a/release/PRIVACY.md` reflects actual runtime data behavior.
- [ ] `project-a/release/FAN-CONTENT-NOTICE.md` is reviewed for store/legal risk.
- [ ] Headless tests pass:
  - `godot --headless --path project-a -s tools/run_meta_tests.gd`
  - `godot --headless --path project-a -s tools/run_battle_tests.gd`
  - `godot --headless --path project-a -s tools/run_lifecycle_tests.gd`
  - `godot --headless --path project-a -s tools/run_ui_smoke_tests.gd`

## Local artifact gate

- [ ] Export command is recorded:
  - `godot --headless --path project-a --export-release Web build/web/index.html`
- [ ] Artifact files exist: `index.html`, `index.js`, `index.wasm`, `index.pck`.
- [ ] Artifact sizes and SHA256 hashes are recorded.
- [ ] No unexpected threaded runtime `.worker.js` file exists; a Godot PWA `index.service.worker.js` is expected when PWA is enabled.
- [ ] `index.html` declares `GODOT_THREADS_ENABLED = false`.
- [ ] PWA manifest/service worker output is either present and inspected or explicitly marked unsupported for this candidate.
- [ ] `python tools/release_audit.py --artifact-dir build/web` passes.

## External evidence still required before public release

- [ ] Exact Builda-controlled runtime/template identity or approved replacement release path.
- [ ] Final HTTPS URL and deployment/version id.
- [ ] Correct production MIME types, especially `application/wasm`.
- [ ] Compression/cache/security headers.
- [ ] Fresh-cache and warm-cache startup timings.
- [x] Google Chrome desktop HTTP smoke, including touch input, online reload, server shutdown,
  offline PWA restart, and IndexedDB save identity (`node tools/run_web_browser_smoke.mjs`).
- [ ] Firefox desktop smoke.
- [ ] Chrome Android real-device smoke.
- [ ] Safari iOS real-device smoke.
- [ ] Browser reload/restart persistence proof on the final production origin (local HTTP proof passes).
- [ ] Private/blocked storage degraded behavior proof.
- [ ] Accessibility review: focus visibility, readable/scalable text, non-color cues, reduced motion where needed, critical-audio alternatives.
- [ ] Final legal review for font notice, fan-content/IP risk, store copy, and every asset license.
- [ ] Monitoring, incident owner, rollback artifact, rollback trigger, and rollback rehearsal.

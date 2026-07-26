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
- [ ] `run_font_coverage_tests.gd` proves every runtime ASCII/CJK/symbol codepoint exists in the shipped font.
- [ ] `python3 tools/build_runtime_font_subset.py --inspect` matches the reviewed runtime character inventory;
  any generated subset is built from the recorded upstream font with official `fonttools`, never by overwriting it.
- [ ] `project-a/release/PRIVACY.md` reflects actual runtime data behavior.
- [ ] `project-a/release/FAN-CONTENT-NOTICE.md` is reviewed for store/legal risk.
- [ ] Headless tests pass:
  - `godot --headless --path project-a -s tools/run_meta_tests.gd`
  - `godot --headless --path project-a -s tools/run_battle_tests.gd`
  - `godot --headless --path project-a -s tools/run_lifecycle_tests.gd`
  - `godot --headless --path project-a -s tools/run_ui_smoke_tests.gd`

## Local artifact gate

- [ ] Candidate build command is recorded:
  - `python3 project-a/tools/build_web_candidate.py`
- [ ] Artifact files exist: `index.html`, `index.js`, `index.wasm`, `index.pck`.
- [ ] Artifact sizes and SHA256 hashes are recorded.
- [ ] `release-candidate.json` binds the clean source revision, Godot version, thread mode, full payload hashes, and matching second export.
- [ ] No Godot editor/source sidecar such as `.import`, `.gd`, `.tscn`, `.tres`, or `.uid` ships.
- [ ] The unused legacy `scripts/main.gd` App Shell remains available in source history but is excluded from the player Web package.
- [ ] No unexpected threaded runtime `.worker.js` file exists; a Godot PWA `index.service.worker.js` is expected when PWA is enabled.
- [ ] `index.html` declares `GODOT_THREADS_ENABLED = false`.
- [ ] PWA manifest/service worker output is either present and inspected or explicitly marked unsupported for this candidate.
- [ ] `python tools/release_audit.py --artifact-dir build/web` passes.

## External evidence still required before public release

- [ ] Exact Builda-controlled runtime/template identity or approved replacement release path.
- [ ] Final HTTPS URL and deployment/version id.
- [ ] Correct production MIME types, especially `application/wasm`.
- [ ] Compression/cache/security headers.
- [x] Local Chrome fresh-profile, Service Worker warm-reload, and offline engine-ready timings are recorded against explicit local ceilings.
- [ ] Production-origin fresh-cache and warm-cache transfer/startup timings pass on the minimum target device.
- [x] Candidate audit records raw and deterministic gzip-9 bytes for the initial HTML/JS/WASM/PCK payload and enforces the 30 MiB hard limit.
- [ ] Initial compressed payload reaches the 20 MiB target; the current full CJK font keeps the candidate above target.
- [x] PWA/application icon is an original project-owned mark, passes the safe SVG profile, and remains legible at 32/144/180/512 px.
- [x] Google Chrome desktop HTTP smoke, including touch input, online reload, server shutdown,
  offline PWA restart, and IndexedDB save identity (`node tools/run_web_browser_smoke.mjs`).
- [ ] Firefox desktop smoke.
- [ ] Chrome Android real-device smoke.
- [ ] Safari iOS real-device smoke.
- [ ] Browser reload/restart persistence proof on the final production origin (local HTTP proof passes).
- [x] Chrome private-context proof: reload within one context preserves the save, closing it discards that
  save, and a new private context starts with distinct local data (`node tools/run_web_private_storage_smoke.mjs`).
- [x] Fully blocked-storage local Chrome proof: IndexedDB throws `SecurityError` before Godot boot,
  the title remains usable and warns before play that refresh will lose progress
  (`GODOT_WEB_SMOKE_BLOCK_INDEXEDDB=1 node tools/run_web_private_storage_smoke.mjs`);
  domain commands separately reject synchronous save failures atomically.
- [x] Web UI treats engine persistence capability conservatively and directs players to download a backup
  instead of presenting a private/session-only IndexedDB write as guaranteed retention.
- [ ] Accessibility review: focus visibility, readable/scalable text, non-color cues, reduced motion where needed, critical-audio alternatives.
- [ ] `run_ui_focus_tests.gd` proves every authored and dynamic screen action is focusable and has a non-empty visible focus style.
- [ ] Final legal review for font notice, fan-content/IP risk, store copy, and every asset license.
- [ ] Monitoring, incident owner, rollback artifact, rollback trigger, and rollback rehearsal.

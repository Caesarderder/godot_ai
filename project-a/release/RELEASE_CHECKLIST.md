# Web release checklist

State labels:

- `SOURCE_HARDENED`: source has release materials and local checks.
- `ARTIFACT_VERIFIED`: a Web artifact was exported from the frozen candidate and passed local artifact inspection.
- `DEVICE_VERIFIED`: claimed desktop/mobile browsers passed runtime smoke on named devices.
- `HOSTING_VERIFIED`: the final HTTPS URL passed production-origin checks, monitoring, and rollback evidence.

## Local source gate

- [x] Candidate revision is frozen and dirty state is recorded.
- [x] `project-a/project.godot` has no conflict markers and uses Godot 4.6.3 Compatibility/Web-safe settings.
- [x] `project-a/export_presets.cfg` has Web preset, single-thread export, release material include filter, PWA metadata, and no GDExtension support.
- [ ] `project-a/release/LICENSES.md` reflects every shipped asset.
- [x] `run_font_coverage_tests.gd` proves every runtime ASCII/CJK/symbol codepoint exists in the shipped font.
- [x] `python3 tools/build_runtime_font_subset.py --inspect` matches the reviewed runtime character inventory;
  any generated subset is built from the recorded upstream font with official `fonttools`, never by overwriting it.
- [x] `project-a/release/PRIVACY.md` reflects actual local runtime data behavior; final hosting/provider behavior remains external.
- [ ] `project-a/release/FAN-CONTENT-NOTICE.md` is reviewed for store/legal risk.
- [x] Headless tests pass:
  - `godot --headless --path project-a -s tools/run_meta_tests.gd`
  - `godot --headless --path project-a -s tools/run_battle_tests.gd`
  - `godot --headless --path project-a -s tools/run_lifecycle_tests.gd`
  - `godot --headless --path project-a -s tools/run_ui_smoke_tests.gd`

## Local artifact gate

- [x] Candidate build command is recorded:
  - `python3 project-a/tools/build_web_candidate.py`
- [x] Artifact files exist: `index.html`, `index.js`, `index.wasm`, `index.pck`.
- [x] Artifact sizes and SHA256 hashes are recorded.
- [x] `release-candidate.json` binds the clean source revision, Godot version, thread mode, full payload hashes, and matching second export.
- [x] No Godot editor/source sidecar such as `.import`, `.gd`, `.tscn`, `.tres`, or `.uid` ships.
- [x] The unused legacy `scripts/main.gd` App Shell remains available in source history but is excluded from the player Web package.
- [x] No unexpected threaded runtime `.worker.js` file exists; a Godot PWA `index.service.worker.js` is expected when PWA is enabled.
- [x] `index.html` declares `GODOT_THREADS_ENABLED = false`.
- [x] PWA manifest/service worker output is present and inspected.
- [x] `python tools/release_audit.py --artifact-dir build/web` passes.

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
- [x] Google Chrome desktop HTTP smoke, including keyboard `Enter` on the focused title CTA, touch input,
  online reload, server shutdown, offline PWA restart, and IndexedDB save identity
  (`node tools/run_web_browser_smoke.mjs`).
- [x] Chrome fresh-profile reinforcement smoke uses only exported Canvas input to clear 1-1/1-2/1-3, reach the
  authored 1-4 defeat, place/wait/claim the research lab, resolve the free ten-pull, and assign both guaranteed
  reinforcements, then clicks the rendered counterattack CTA and operates all three hero cards until the second
  1-4 attempt wins. The same journey chooses and commissions a resource facility, claims its first real output,
  compares both verified growth routes, commits an assault two-star choice, defeats 1-5, records the role and
  cannon-suppression contribution, and opens chapter-two reconnaissance without auto-starting 2-1. It then claims
  the faction ten-pull, chooses one of two equal-rarity cores, completes that core's timed research, deploys the
  permanent hero, clears 2-1/2-2/2-3, and reaches a real one-star pressure result at 2-4 or 2-5. The visible
  recovery objective focuses the exact roster card and spends only that archetype's fragments to reach two stars.
  Candidate `43f3e1d` selected Sonic, recorded 60 fragments before a 20-fragment upgrade, and finished with the
  same permanent hero at two stars after 715.266 seconds, with no runtime, console, or network failures
  (`node tools/run_web_first_battle_smoke.mjs`).
- [ ] Firefox desktop smoke.
- [ ] Optional desktop Safari `WEBKIT_PREFLIGHT` against the frozen candidate; record the exact Safari version.
  This requires the device owner to enable Safari “Allow remote automation” and never replaces iOS evidence.
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
- [x] Local accessibility review: focus visibility, runtime font coverage, 48 CSS-pixel target scaling,
  non-color combat/status copy, reduced-motion semantics, and silent alternatives for critical audio all
  have independent automated evidence; screen-reader/assistive-technology behavior remains a real-device gate.
- [x] `run_ui_focus_tests.gd` audits 12 authored screens plus `StageDetailPanel`, dynamic actions and every
  `BaseButton / Slider / LineEdit / TextEdit`; `ui-settings-slider-focus-844x390.png` proves the Slider
  keyboard/gamepad highlight in a Compatibility render.
- [ ] Final legal review for font notice, fan-content/IP risk, store copy, and every asset license.
- [x] A deterministic local rollback artifact is bound to the clean candidate and passes isolated restore,
  full-file SHA256 comparison, and `release_audit.py`.
- [ ] Production monitoring thresholds, named incident owner, hosting/CDN rollback operation, and production-origin
  rollback rehearsal.
